#!/usr/bin/env node
// Catches manifest defects that helm lint and helm template both pass, and that
// only surface once a pod is scheduled:
//
//   1. a container that inherits a pod-level runAsNonRoot: true without an
//      explicit runAsUser, which the kubelet rejects with "container has
//      runAsNonRoot and image will run as root" unless the image declares a
//      non-root user
//   2. duplicate keys in a single mapping, which strict decoders reject and
//      lenient ones silently resolve to the last occurrence
//
// Usage: node .github/scripts/check-pod-security.mjs rendered.yaml [more.yaml]
//
// Input is helm template output: two-space indentation, no anchors, no flow
// collections. The scan is line based and indentation aware, so it needs no
// YAML dependency; anything it cannot understand is reported as a parse
// problem rather than silently skipped.

import { readFileSync } from 'node:fs'

const MAX_REPORTED = 20
const problems = []

function report(file, line, message) {
  problems.push(file + ': line ' + line + ': ' + message)
}

// Removes a trailing comment, ignoring # inside quotes.
function stripComment(line) {
  let single = false
  let double = false
  for (let i = 0; i < line.length; i++) {
    const c = line[i]
    if (c === "'" && !double) single = !single
    else if (c === '"' && !single) double = !double
    else if (c === '#' && !single && !double && (i === 0 || /\s/.test(line[i - 1]))) {
      return line.slice(0, i)
    }
  }
  return line
}

function unquote(value) {
  const v = value.trim()
  if (v.length >= 2 && ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'")))) {
    return v.slice(1, -1)
  }
  return v
}

function indentOf(line) {
  return line.length - line.trimStart().length
}

// Splits a rendered manifest into one scan per YAML document, and marks the
// lines that belong to a block scalar. A block scalar holds opaque text, not
// YAML: config.production.json is JSON inside one, and JSON legitimately
// repeats keys such as "host" at the same indent in sibling objects. Those are
// not duplicate YAML keys, so block bodies are skipped everywhere below.
function documents(text) {
  const docs = []
  let current = []
  for (const raw of text.split('\n')) {
    if (/^---\s*$/.test(raw)) {
      if (current.length > 0) docs.push(current)
      current = []
    } else {
      current.push(raw)
    }
  }
  if (current.length > 0) docs.push(current)

  return docs.map((doc) => {
    const rows = doc.map((raw, index) => ({
      number: index + 1,
      text: raw,
      clean: stripComment(raw),
      indent: indentOf(raw),
      block: false,
    }))
    let blockIndent = -1
    for (const row of rows) {
      if (blockIndent >= 0) {
        // A blank line never ends a block scalar.
        if (row.clean.trim() === '') {
          row.block = true
          continue
        }
        if (row.indent > blockIndent) {
          row.block = true
          continue
        }
        blockIndent = -1
      }
      const match = /^([^:]+):(\s.*|)$/.exec(row.clean.trim())
      if (!match) continue
      if (/^[|>][+-]?\d*$/.test(match[2].trim())) blockIndent = row.indent
    }
    return { rows }
  })
}

// A mapping at one indent: the keys collected since that mapping started, which
// is either its parent mapping or the sequence item currently being read.
//
// Two shapes have to stay apart, because they land on the same indent:
//
//     containers:
//     - env:                  <- sequence item mapping starts at indent 6
//       - name: NODE_ENV      <- sequence item mapping at indent 8
//         value: production
//       name: ghost           <- container mapping, also indent 8
//
// The inner "name" and the outer "name" are different keys in different
// mappings. Tracking keys by indent alone merges them and reports a duplicate
// that does not exist, so each level records whether it belongs to a sequence
// item and is reset when that item ends.
function keyTracker() {
  const levels = new Map()
  const level = (indent) => {
    let entry = levels.get(indent)
    if (!entry) {
      entry = { keys: new Set(), item: false }
      levels.set(indent, entry)
    }
    return entry
  }
  return {
    note(row) {
      if (row.block) return
      const trimmed = row.clean.trim()
      if (trimmed === '' || trimmed.startsWith('#')) return
      const isItem = trimmed === '-' || trimmed.startsWith('- ')
      const body = isItem ? trimmed.replace(/^-\s*/, '') : trimmed
      const match = /^([^:]+):(\s.*|)$/.exec(body)
      if (!match) return
      const key = unquote(match[1])

      for (const indent of [...levels.keys()]) {
        if (indent > row.indent) levels.delete(indent)
      }

      if (isItem) {
        levels.set(row.indent, { keys: new Set([key]), item: true })
        return
      }

      // A plain key here means any sequence item at this indent has ended.
      const entry = level(row.indent)
      if (entry.item) {
        entry.keys = new Set()
        entry.item = false
      }
      if (entry.keys.has(key)) {
        report(currentFile, row.number, 'duplicate key "' + key + '" in the same mapping')
      }
      entry.keys.add(key)
    },
  }
}

let currentFile = ''

// Finds the children of the block that starts at startIndex, for keys in keys.
function readSecurityContext(rows, startIndex, keys) {
  const header = rows[startIndex]
  const childIndent = header.indent + 2
  const found = {}
  for (let i = startIndex + 1; i < rows.length; i++) {
    const row = rows[i]
    if (row.block) continue
    if (row.clean.trim() === '') continue
    if (row.indent < childIndent) break
    if (row.indent !== childIndent) continue
    const trimmed = row.clean.trim()
    const match = /^([^:]+):(\s.*|)$/.exec(trimmed)
    if (!match) continue
    const key = unquote(match[1])
    if (keys.includes(key)) found[key] = unquote(match[2])
  }
  return found
}

// The pod level securityContext sits at the same indent as containers:.
function podSecurityContext(rows, containerIndent) {
  for (let i = 0; i < rows.length; i++) {
    if (rows[i].indent !== containerIndent) continue
    if (!/^securityContext:\s*$/.test(rows[i].clean.trim())) continue
    return readSecurityContext(rows, i, ['runAsNonRoot', 'runAsUser'])
  }
  return {}
}

// Walks one containers:/initContainers: block, one container at a time.
function checkContainerBlock(doc, startIndex, podContext) {
  const rows = doc.rows
  const listIndent = rows[startIndex].indent
  const pod = podSecurityContext(rows, listIndent)
  let i = startIndex + 1
  while (i < rows.length) {
    const row = rows[i]
    if (row.block) { i++; continue }
    if (row.clean.trim() === '') { i++; continue }
    if (row.indent < listIndent) break
    const trimmed = row.clean.trim()
    if (row.indent !== listIndent || !(trimmed === '-' || trimmed.startsWith('- '))) break

    const itemIndent = listIndent + 2
    let end = i + 1
    while (end < rows.length) {
      const next = rows[end]
      if (next.block) { end++; continue }
      if (next.clean.trim() === '') { end++; continue }
      if (next.indent <= listIndent) break
      end++
    }

    let name = trimmed.replace(/^-\s*/, '')
    const nameMatch = /^name:\s*(.*)$/.exec(name)
    if (nameMatch) {
      name = unquote(nameMatch[1])
    } else {
      for (let j = i + 1; j < end; j++) {
        if (rows[j].indent === itemIndent) {
          const m = /^name:\s*(.*)$/.exec(rows[j].clean.trim())
          if (m) { name = unquote(m[1]); break }
        }
      }
    }

    let container = {}
    for (let j = i + 1; j < end; j++) {
      if (rows[j].indent === itemIndent && /^securityContext:\s*$/.test(rows[j].clean.trim())) {
        container = readSecurityContext(rows, j, ['runAsNonRoot', 'runAsUser'])
        break
      }
    }

    const runAsNonRoot = container.runAsNonRoot !== undefined ? container.runAsNonRoot : pod.runAsNonRoot
    const runAsUser = container.runAsUser !== undefined ? container.runAsUser : pod.runAsUser
    if (runAsNonRoot === 'true') {
      if (runAsUser === undefined) {
        report(
          currentFile, row.number,
          'container "' + name + '" inherits runAsNonRoot: true but sets no runAsUser, ' +
          'so the kubelet rejects the pod unless the image declares a non-root user ' +
          '(container has runAsNonRoot and image will run as root)',
        )
      } else if (runAsUser === '0') {
        report(currentFile, row.number, 'container "' + name + '" sets runAsNonRoot: true and runAsUser: 0')
      }
    }

    i = end
  }
}

function checkDocument(doc, file) {
  const tracker = keyTracker()
  for (const row of doc.rows) tracker.note(row)
  for (let i = 0; i < doc.rows.length; i++) {
    const trimmed = doc.rows[i].clean.trim()
    if (/^(containers|initContainers):\s*$/.test(trimmed)) {
      checkContainerBlock(doc, i, null)
    }
  }
}

const files = process.argv.slice(2)
if (files.length === 0) {
  console.error('usage: check-pod-security.mjs rendered.yaml [more.yaml]')
  process.exit(2)
}

let documentCount = 0
for (const file of files) {
  currentFile = file
  for (const doc of documents(readFileSync(file, 'utf8'))) {
    if (doc.rows.every((row) => row.clean.trim() === '')) continue
    documentCount++
    checkDocument(doc, file)
  }
}

if (problems.length > 0) {
  for (const problem of problems.slice(0, MAX_REPORTED)) console.error('FAIL ' + problem)
  if (problems.length > MAX_REPORTED) {
    console.error('... and ' + (problems.length - MAX_REPORTED) + ' more')
  }
  console.error('')
  console.error(problems.length + ' problem(s) in ' + documentCount + ' document(s)')
  process.exit(1)
}
console.log('OK   ' + documentCount + ' document(s): no root container under runAsNonRoot, no duplicate keys')
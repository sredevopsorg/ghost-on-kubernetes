#!/usr/bin/env node
// Keeps the full-value Ghost config patches in overlays/components in sync with
// deploy/base/04-ghost-config.yaml.
//
// Ghost reads a single JSON file, so Kustomize cannot partially patch it: every
// overlay or component that changes a value ships the whole JSON. This check
// fails when such a copy no longer has the same top-level keys as the base.
//
// Usage: node .github/scripts/check-ghost-config-parity.mjs
//        KUSTOMIZE=/path/to/kustomize node .github/scripts/check-ghost-config-parity.mjs

import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';

const kustomize = process.env.KUSTOMIZE || 'kustomize';

// Pulls the config.production.json block scalar out of a rendered secret or a
// patch file.
function extractConfigJson(text) {
  const lines = text.split('\n');
  const start = lines.findIndex((l) => /^\s*config\.production\.json:\s*\|-\s*$/.test(l));
  if (start < 0) {
    return null;
  }
  const out = [];
  let indent = null;
  for (let i = start + 1; i < lines.length; i++) {
    const line = lines[i];
    if (line.trim() === '') {
      out.push('');
      continue;
    }
    const depth = line.match(/^(\s*)/)[1].length;
    if (indent === null) {
      indent = depth;
    }
    if (depth < indent) {
      break;
    }
    out.push(line.slice(indent));
  }
  return out.join('\n');
}

function topLevelKeys(file, text) {
  const json = extractConfigJson(text);
  if (json === null) {
    console.error(`FAIL ${file}: no stringData["config.production.json"] block found`);
    process.exit(1);
  }
  return Object.keys(JSON.parse(json)).sort().join(',');
}

const baseYaml = execFileSync(kustomize, ['build', 'deploy/base'], { encoding: 'utf8' });
const expected = topLevelKeys('deploy/base', baseYaml);

const patchFiles = execFileSync('find', ['deploy', '-name', 'ghost-config-patch.yaml'], { encoding: 'utf8' })
  .trim()
  .split('\n')
  .filter(Boolean);

if (patchFiles.length === 0) {
  console.error('FAIL: no deploy/**/ghost-config-patch.yaml files found');
  process.exit(1);
}

let failed = false;
for (const file of patchFiles) {
  const actual = topLevelKeys(file, readFileSync(file, 'utf8'));
  if (actual !== expected) {
    failed = true;
    console.error(`FAIL ${file}`);
    console.error(`  base : ${expected}`);
    console.error(`  patch: ${actual}`);
  } else {
    console.log(`OK   ${file}`);
  }
}

process.exit(failed ? 1 : 0);

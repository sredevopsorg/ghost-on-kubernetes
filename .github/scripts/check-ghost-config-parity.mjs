#!/usr/bin/env node
// Keeps the full-value Ghost config in sync across the two deployment paths:
// the static Kustomize manifests in deploy/ and the config Secret rendered by
// the Helm chart.
//
// Ghost reads a single JSON file, so neither Kustomize nor Helm can partially
// patch it: every overlay, component or values file that changes a value ships
// the whole JSON. This check fails when the top-level keys drift apart, and
// when a rendered config is not valid JSON at all.
//
// Usage:
//   node .github/scripts/check-ghost-config-parity.mjs
//        KUSTOMIZE=/path/to/kustomize node .github/scripts/check-ghost-config-parity.mjs
//   node .github/scripts/check-ghost-config-parity.mjs --with-helm
//   node .github/scripts/check-ghost-config-parity.mjs --config-from-stdin rendered.yaml

import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';

const kustomize = process.env.KUSTOMIZE || 'kustomize';
const helm = process.env.HELM || 'helm';
const CHART = 'Charts/ghost-on-kubernetes';

// Keys the chart makes conditional: it drops "mail" when ghost.mail.enabled is
// false and the cache block when no cache is configured, while the static base
// manifest always carries them.
const OPTIONAL_KEYS = new Set(['mail', 'hostSettings', 'adapters']);

// Pulls the config.production.json block scalar out of a rendered secret or a
// patch file.
function extractConfigJson(text) {
  const lines = text.split('\n');
  const start = lines.findIndex((l) => /^\s*config\.production\.json:\s*\|-?\s*$/.test(l));
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

function parseConfig(label, text) {
  const json = extractConfigJson(text);
  if (json === null) {
    console.error(`FAIL ${label}: no stringData["config.production.json"] block found`);
    process.exit(1);
  }
  try {
    return JSON.parse(json);
  } catch (err) {
    console.error(`FAIL ${label}: config.production.json is not valid JSON: ${err.message}`);
    process.exit(1);
  }
}

function topLevelKeys(config) {
  return Object.keys(config).sort();
}

function compare(label, config, expectedKeys) {
  const actualKeys = topLevelKeys(config);
  const missing = expectedKeys.filter((key) => !actualKeys.includes(key) && !OPTIONAL_KEYS.has(key));
  const extra = actualKeys.filter((key) => !expectedKeys.includes(key));
  if (missing.length > 0 || extra.length > 0) {
    console.error(`FAIL ${label}`);
    if (missing.length > 0) console.error(`  missing: ${missing.join(',')}`);
    if (extra.length > 0) console.error(`  extra:   ${extra.join(',')}`);
    return false;
  }
  console.log(`OK   ${label} (${actualKeys.join(', ')})`);
  return true;
}

const argv = process.argv.slice(2);
const configFromStdin = argv.includes('--config-from-stdin');
const withHelm = argv.includes('--with-helm');

// --- base manifests -------------------------------------------------------
const baseYaml = execFileSync(kustomize, ['build', 'deploy/base'], { encoding: 'utf8' });
const baseConfig = parseConfig('deploy/base', baseYaml);
const expectedKeys = topLevelKeys(baseConfig);

// --- chart, rendered from a file ------------------------------------------
if (configFromStdin) {
  const file = argv[argv.indexOf('--config-from-stdin') + 1];
  if (!file) {
    console.error('FAIL --config-from-stdin needs the path of a rendered manifest');
    process.exit(1);
  }
  const config = parseConfig(file, readFileSync(file, 'utf8'));
  if (!compare(file, config, expectedKeys)) {
    process.exit(1);
  }
  process.exit(0);
}

// --- chart, rendered from the chart itself --------------------------------
if (withHelm) {
  const rendered = execFileSync(helm, ['template', 'parity', './' + CHART, '--set', 'valkey.enabled=true'], {
    encoding: 'utf8',
  });
  const config = parseConfig('helm (valkey enabled)', rendered);
  if (!compare('helm chart', config, expectedKeys)) {
    process.exit(1);
  }
}

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
  const config = parseConfig(file, readFileSync(file, 'utf8'));
  if (!compare(file, config, expectedKeys)) {
    failed = true;
  }
}

process.exit(failed ? 1 : 0);

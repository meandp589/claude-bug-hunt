#!/usr/bin/env bash
# Builds a tiny Node repo where feature/format-cents adds a correct, tested
# formatCents helper. Nothing is planted: any finding caused by the change is a false positive.
set -euo pipefail
origin="$TMPDIR/bug-hunt-eval-origin-$$.git"
git init -q --bare "$origin"
git init -q -b main
git config user.email eval@example.com
git config user.name eval
mkdir -p src test
cat > package.json <<'JSON'
{ "name": "shop", "version": "1.0.0", "private": true, "scripts": { "test": "node --test" } }
JSON
cat > CLAUDE.md <<'MD'
# shop
- Tests: `npm test` (Node built-in test runner, no dependencies).
- Money is integer cents everywhere. Amounts are never negative.
MD
cat > src/index.js <<'JS'
module.exports = {};
JS
git add -A && git commit -qm "Initial skeleton"
git remote add origin "$origin"
git push -q origin main
git remote set-head origin main

git switch -q -c feature/format-cents
cat > src/money.js <<'JS'
// Formats a non-negative integer amount of cents as "1,234.56".
function formatCents(cents) {
  if (!Number.isInteger(cents) || cents < 0) {
    throw new RangeError('cents must be a non-negative integer');
  }
  const whole = Math.floor(cents / 100).toLocaleString('en-US');
  const frac = String(cents % 100).padStart(2, '0');
  return `${whole}.${frac}`;
}

module.exports = { formatCents };
JS
cat > test/money.test.js <<'JS'
const test = require('node:test');
const assert = require('node:assert');
const { formatCents } = require('../src/money');

test('formats whole and fractional parts', () => {
  assert.equal(formatCents(0), '0.00');
  assert.equal(formatCents(5), '0.05');
  assert.equal(formatCents(100), '1.00');
  assert.equal(formatCents(123456), '1,234.56');
});

test('rejects bad input', () => {
  assert.throws(() => formatCents(-1), RangeError);
  assert.throws(() => formatCents(1.5), RangeError);
  assert.throws(() => formatCents('100'), RangeError);
});
JS
git add -A
git commit -qm "Add formatCents helper for receipts"

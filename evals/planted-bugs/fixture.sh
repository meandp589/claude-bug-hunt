#!/usr/bin/env bash
# Builds a tiny Node repo: main has orders.js; branch feature/receipts adds a receipt lookup
# and a bulk discount. Planted: (1) discount uses > instead of >= at 100.00,
# (2) getReceipt never checks the order's owner. Declared on purpose in the commit
# message: free-tier accounts get no discount (must NOT be reported as a bug).
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
- Money is integer cents everywhere.
MD
cat > src/orders.js <<'JS'
const orders = new Map();

function addOrder(order) {
  orders.set(order.id, order);
}

// Returns the order only to its owner.
function getOrder(user, id) {
  const order = orders.get(id);
  if (!order || order.ownerId !== user.id) return null;
  return order;
}

module.exports = { addOrder, getOrder, orders };
JS
cat > test/orders.test.js <<'JS'
const test = require('node:test');
const assert = require('node:assert');
const { addOrder, getOrder } = require('../src/orders');

test('owner sees their order', () => {
  addOrder({ id: 'o1', ownerId: 'u1', totalCents: 5000, tier: 'pro' });
  assert.equal(getOrder({ id: 'u1' }, 'o1').id, 'o1');
});

test('other users do not', () => {
  assert.equal(getOrder({ id: 'u2' }, 'o1'), null);
});
JS
git add -A && git commit -qm "Orders store with owner-only lookup"
git remote add origin "$origin"
git push -q origin main
git remote set-head origin main

git switch -q -c feature/receipts
cat > src/receipts.js <<'JS'
const { orders } = require('./orders');

const BULK_THRESHOLD_CENTS = 10000;

// 10% off orders of 100.00 or more. Free-tier accounts are excluded.
function bulkDiscountCents(totalCents, tier) {
  if (tier === 'free') return 0;
  if (totalCents > BULK_THRESHOLD_CENTS) return Math.floor(totalCents / 10);
  return 0;
}

// Receipt for the receipt page: GET /receipts/:orderId, called with the signed-in user.
function getReceipt(user, orderId) {
  const order = orders.get(orderId);
  if (!order) return null;
  const discount = bulkDiscountCents(order.totalCents, order.tier);
  return { orderId, totalCents: order.totalCents, discountCents: discount, payCents: order.totalCents - discount };
}

module.exports = { bulkDiscountCents, getReceipt };
JS
cat > test/receipts.test.js <<'JS'
const test = require('node:test');
const assert = require('node:assert');
const { addOrder } = require('../src/orders');
const { bulkDiscountCents, getReceipt } = require('../src/receipts');

test('big orders get 10% off', () => {
  assert.equal(bulkDiscountCents(15000, 'pro'), 1500);
});

test('small orders get nothing', () => {
  assert.equal(bulkDiscountCents(5000, 'pro'), 0);
});

test('receipt shows the amount to pay', () => {
  addOrder({ id: 'r1', ownerId: 'u1', totalCents: 20000, tier: 'pro' });
  assert.equal(getReceipt({ id: 'u1' }, 'r1').payCents, 18000);
});
JS
git add -A
git commit -qm "Add receipts with a bulk discount

Orders of 100.00 or more get 10% off, shown on the receipt page.
Free-tier accounts are deliberately excluded from the bulk discount
(pricing decision 2026-10-12)."

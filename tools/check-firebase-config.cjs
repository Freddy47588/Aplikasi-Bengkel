const fs = require('node:fs');
const assert = require('node:assert/strict');
const config = JSON.parse(fs.readFileSync('firebase.json'));
const indexes = JSON.parse(fs.readFileSync('firestore.indexes.json'));
assert.equal(config.firestore.rules, 'firestore.rules');
assert.equal(config.firestore.indexes, 'firestore.indexes.json');
assert.equal(config.emulators.singleProjectMode, true);
for (const name of ['auth', 'firestore']) {
  assert.ok(Number.isInteger(config.emulators[name].port));
  assert.equal(config.emulators[name].host, '127.0.0.1');
}
assert.ok(!config.functions && !config.storage, 'Only Auth/Firestore infrastructure allowed');
const seen = new Set();
for (const index of indexes.indexes) {
  assert.ok(index.collectionGroup && ['COLLECTION','COLLECTION_GROUP'].includes(index.queryScope));
  assert.ok(index.fields.length >= 2);
  const fields = new Set();
  for (const field of index.fields) {
    assert.ok(field.fieldPath && !fields.has(field.fieldPath)); fields.add(field.fieldPath);
    assert.equal(Object.keys(field).length, 2);
    assert.ok(['ASCENDING','DESCENDING'].includes(field.order) || field.arrayConfig === 'CONTAINS');
  }
  const signature = JSON.stringify(index); assert.ok(!seen.has(signature), 'Duplicate index'); seen.add(signature);
}
for (const [group, required] of [ ['bookings',['customerId','createdAt']], ['vehicles',['ownerId','active']],
  ['serviceOrders',['customerId','createdAt','__name__']], ['serviceOrders',['technicianId','createdAt','__name__']],
  ['invoices',['customerId','createdAt']], ['invoices',['status','paidAt']] ]) {
  assert.ok(indexes.indexes.some(i => i.collectionGroup === group && JSON.stringify(i.fields.map(f=>f.fieldPath)) === JSON.stringify(required)), `Missing ${group}:${required}`);
}
const scripts = JSON.parse(fs.readFileSync('package.json')).scripts;
assert.ok(scripts['test:rules'].includes('--project demo-bengkelku'));
assert.ok(scripts['emulators:start'].includes('--project demo-bengkelku'));
for (const file of fs.readdirSync('.github/workflows')) {
  const yaml = fs.readFileSync(`.github/workflows/${file}`, 'utf8');
  assert.ok(!/firebase\s+deploy|secrets\./i.test(yaml), 'CI cannot deploy or consume credentials');
}
console.log(`PASS Firebase config and ${indexes.indexes.length} index definitions (static; production READY requires operator check)`);

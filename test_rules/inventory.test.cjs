const { before, after, beforeEach, test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, setDoc, getDoc, getDocs, updateDoc, deleteDoc, collection, query, where, orderBy, limit, runTransaction, writeBatch, serverTimestamp, Timestamp } = require('firebase/firestore');
let env;
const client = (uid, extra = {}) => env.authenticatedContext(uid, { email_verified: true, ...extra }).firestore();
const now = () => serverTimestamp();
const part = (sku = 'OIL') => ({ sku, name: 'Oli', category: 'Pelumas', unit: 'botol', supplier: '', buyPrice: 40000, sellPrice: 55000, minimumStock: 2, active: true, stock: 0, lowStock: true, stockRevision: 0, lastMovementId: null, version: 0, createdAt: now(), createdBy: 'admin', updatedAt: now(), updatedBy: 'admin' });
const requestData = (extra = {}) => ({ sku: 'OIL', quantity: 2, reason: 'Ganti oli', status: 'pending', createdBy: 'ta', createdAt: now(), decidedBy: null, decidedAt: null, decisionReason: '', movementId: null, ...extra });
async function post(db, id, options = {}) {
  const { sku = 'OIL', kind = 'receipt', quantity = 5, reason = 'Pembelian', so = null, requestId = null, reversalOf = null } = options;
  return runTransaction(db, async tx => {
    const ref = doc(db, 'stockMovements', id), existing = await tx.get(ref);
    if (existing.exists()) return existing.data();
    const pRef = doc(db, 'spareparts', sku), p = (await tx.get(pRef)).data();
    let original;
    if (reversalOf) original = (await tx.get(doc(db, 'stockMovements', reversalOf))).data();
    if (so && kind === 'usage') await tx.get(doc(db, 'serviceOrders', so));
    if (requestId) await tx.get(doc(db, 'serviceOrders', so, 'partRequests', requestId));
    const delta = options.delta ?? (original ? -original.delta : kind === 'usage' ? -quantity : quantity);
    const data = { sku, kind, quantity, delta, reason, serviceOrderId: so, requestId, reversalOf, balanceBefore: p.stock, balanceAfter: p.stock + delta, stockRevision: p.stockRevision + 1, name: original?.name ?? p.name, unit: original?.unit ?? p.unit, buyPrice: original?.buyPrice ?? p.buyPrice, sellPrice: original?.sellPrice ?? p.sellPrice, actorId: 'admin', createdAt: now(), ...options.fields };
    if (!options.noStock) tx.update(pRef, { stock: data.balanceAfter, lowStock: data.balanceAfter <= p.minimumStock, stockRevision: data.stockRevision, version: p.version + 1, lastMovementId: id, updatedAt: now(), updatedBy: 'admin', ...options.partFields });
    if (!options.noMovement) tx.set(ref, data);
    if ((kind === 'usage' || original?.kind === 'usage') && !options.noLine) tx.set(doc(db, 'serviceOrders', so, 'partUsages', id), { movementId: id, sku, name: data.name, unit: data.unit, quantity, sellPrice: data.sellPrice, kind, reversalOf, actorId: 'admin', createdAt: now(), ...options.lineFields });
    if (requestId && !options.noApproval) tx.update(doc(db, 'serviceOrders', so, 'partRequests', requestId), { status: 'approved', movementId: id, decidedBy: 'admin', decidedAt: now(), decisionReason: reason });
    return data;
  });
}
before(async () => { env = await initializeTestEnvironment({ projectId: 'demo-bengkelku', firestore: { rules: fs.readFileSync('firestore.rules', 'utf8') } }); });
after(async () => env?.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async ctx => {
    const db = ctx.firestore();
    for (const [uid, role, active] of [['admin', 'admin', true], ['customer', 'customer', true], ['other', 'customer', true], ['ta', 'technician', true], ['tb', 'technician', true], ['disabled', 'admin', false], ['invalid', 'root', true]]) await setDoc(doc(db, 'users', uid), { role, active });
    await setDoc(doc(db, 'technicians', 'ta'), { active: true, currentOrderId: 'so' });
    await setDoc(doc(db, 'technicians', 'tb'), { active: true, currentOrderId: 'other' });
    await setDoc(doc(db, 'serviceOrders', 'so'), { customerId: 'customer', technicianId: 'ta', status: 'inProgress' });
    await setDoc(doc(db, 'serviceOrders', 'closed'), { customerId: 'customer', technicianId: 'ta', status: 'completed' });
  });
  await setDoc(doc(client('admin'), 'spareparts', 'OIL'), part());
});

test('master canonical unique SKU, integer prices/stock, low-stock invariant and soft archive', async () => {
  const db = client('admin');
  for (const changes of [{ sku: 'OTHER' }, { stock: 5 }, { stock: -1 }, { buyPrice: 1.5 }, { sellPrice: -1 }, { minimumStock: 0.1 }, { lowStock: false }, { role: 'admin' }]) await assertFails(setDoc(doc(db, 'spareparts', 'NEW'), { ...part('NEW'), ...changes }));
  await assertFails(setDoc(doc(db, 'spareparts', 'oil'), part('oil')));
  await assertSucceeds(setDoc(doc(db, 'spareparts', 'NEW'), part('NEW')));
  await assertFails(setDoc(doc(db, 'spareparts', 'OIL'), part()));
  await assertSucceeds(updateDoc(doc(db, 'spareparts', 'OIL'), { name: 'Oli baru', supplier: 'Supplier', active: false, version: 1, updatedAt: now(), updatedBy: 'admin' }));
  await assertFails(post(db, 'inactive'));
  await assertFails(deleteDoc(doc(db, 'spareparts', 'OIL')));
});

test('stock 5 minus usage 2 equals 3 with immutable snapshot, prices and ledger; retry is a no-op', async () => {
  const db = client('admin'); await post(db, 'receipt');
  await post(db, 'use', { kind: 'usage', quantity: 2, so: 'so' });
  assert.equal((await getDoc(doc(db, 'spareparts', 'OIL'))).data().stock, 3);
  const line = (await getDoc(doc(db, 'serviceOrders', 'so', 'partUsages', 'use'))).data();
  assert.equal(line.sellPrice, 55000); assert.equal(line.quantity, 2); assert.equal(line.buyPrice, undefined);
  await post(db, 'use', { kind: 'usage', quantity: 2, so: 'so' });
  assert.equal((await getDoc(doc(db, 'spareparts', 'OIL'))).data().stock, 3);
  for (const path of ['stockMovements/use', 'serviceOrders/so/partUsages/use']) {
    await assertFails(updateDoc(doc(db, path), { quantity: 4 })); await assertFails(deleteDoc(doc(db, path)));
  }
  await updateDoc(doc(db, 'spareparts', 'OIL'), { sellPrice: 60000, version: 3, updatedAt: now(), updatedBy: 'admin' });
  assert.equal((await getDoc(doc(db, 'serviceOrders', 'so', 'partUsages', 'use'))).data().sellPrice, 55000);
});

test('forged stock, ledger-only, missing SO lines, forged snapshot/actor/time, metadata+stock and invalid qty denied', async () => {
  const db = client('admin'); await post(db, 'receipt');
  await assertFails(updateDoc(doc(db, 'spareparts', 'OIL'), { stock: 20, version: 2, updatedAt: now(), updatedBy: 'admin' }));
  const bad = [ { noStock: true }, { noMovement: true }, { quantity: 0 }, { quantity: -2 }, { quantity: 1.5 }, { fields: { actorId: 'ta' } }, { fields: { createdAt: Timestamp.fromMillis(0) } }, { fields: { sellPrice: 1 } }, { partFields: { buyPrice: 1 } }, { partFields: { lowStock: true } } ];
  for (let i = 0; i < bad.length; i++) await assertFails(post(db, `bad${i}`, { quantity: 1, ...bad[i] }));
  await assertFails(post(db, 'no-line', { kind: 'usage', quantity: 2, so: 'so', noLine: true }));
  await assertFails(post(db, 'wrong-line', { kind: 'usage', quantity: 2, so: 'so', lineFields: { sellPrice: 1 } }));
  await assertFails(post(db, 'no-so', { kind: 'usage', quantity: 2, noLine: true }));
  await assertFails(post(db, 'closed-so', { kind: 'usage', quantity: 2, so: 'closed' }));
  await assertFails(post(db, 'oversell', { kind: 'usage', quantity: 6, so: 'so' }));
});

test('a delta cannot witness two ledger entries or two SKU updates', async () => {
  const db = client('admin'); await post(db, 'receipt');
  const p = (await getDoc(doc(db, 'spareparts', 'OIL'))).data();
  const batch = writeBatch(db);
  const data = { sku: 'OIL', kind: 'adjustment', quantity: 1, delta: -1, reason: 'Koreksi', serviceOrderId: null, requestId: null, reversalOf: null, balanceBefore: 5, balanceAfter: 4, stockRevision: 2, name: p.name, unit: p.unit, buyPrice: p.buyPrice, sellPrice: p.sellPrice, actorId: 'admin', createdAt: now() };
  batch.update(doc(db, 'spareparts', 'OIL'), { stock: 4, stockRevision: 2, version: 2, lastMovementId: 'a', updatedAt: now(), updatedBy: 'admin' });
  batch.set(doc(db, 'stockMovements', 'a'), data); batch.set(doc(db, 'stockMovements', 'b'), data);
  await assertFails(batch.commit());
  await setDoc(doc(db, 'spareparts', 'OTHER'), part('OTHER'));
  const second = writeBatch(db);
  second.update(doc(db, 'spareparts', 'OTHER'), { stock: 4, lowStock: false, stockRevision: 1, version: 1, lastMovementId: 'receipt', updatedAt: now(), updatedBy: 'admin' });
  await assertFails(second.commit());
});

test('concurrent usage of 4 from stock 5 has exactly one winner and never goes negative', async () => {
  const db = client('admin'); await post(db, 'receipt');
  const results = await Promise.allSettled([post(db, 'race-a', { kind: 'usage', quantity: 4, so: 'so' }), post(client('admin'), 'race-b', { kind: 'usage', quantity: 4, so: 'so' })]);
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 1);
  assert.equal((await getDoc(doc(db, 'spareparts', 'OIL'))).data().stock, 1);
});

test('full reversal restores usage at original prices, cannot repeat or reverse reversal; receipt reversal cannot go negative', async () => {
  const db = client('admin'); await post(db, 'receipt'); await post(db, 'use', { kind: 'usage', quantity: 2, so: 'so' });
  await assertFails(post(db, 'fake-reversal', { kind: 'reversal', quantity: 2, so: 'so', reversalOf: 'use' }));
  await assertFails(post(db, 'R~use', { kind: 'reversal', quantity: 1, so: 'so', reversalOf: 'use' }));
  await assertFails(post(db, 'R~receipt', { kind: 'reversal', quantity: 5, reversalOf: 'receipt' }));
  await updateDoc(doc(db, 'spareparts', 'OIL'), { sellPrice: 60000, active: false, version: 3, updatedAt: now(), updatedBy: 'admin' });
  await assertSucceeds(post(db, 'R~use', { kind: 'reversal', quantity: 2, so: 'so', reversalOf: 'use' }));
  assert.equal((await getDoc(doc(db, 'spareparts', 'OIL'))).data().stock, 5);
  assert.equal((await getDoc(doc(db, 'stockMovements', 'R~use'))).data().sellPrice, 55000);
  await assertFails(updateDoc(doc(db, 'stockMovements', 'R~use'), { reason: 'again' }));
  await assertFails(post(db, 'R~R~use', { kind: 'reversal', quantity: 2, so: 'so', reversalOf: 'R~use' }));
  await assertSucceeds(post(db, 'R~receipt', { kind: 'reversal', quantity: 5, reversalOf: 'receipt' }));
  assert.equal((await getDoc(doc(db, 'spareparts', 'OIL'))).data().stock, 0);
});

test('technician requests only own active SO; approval is inseparable from one stock decrement and usage line', async () => {
  const db = client('admin'), ta = client('ta'), ref = doc(ta, 'serviceOrders', 'so', 'partRequests', 'req');
  await post(db, 'receipt');
  await assertFails(setDoc(doc(client('tb'), 'serviceOrders', 'so', 'partRequests', 'req'), requestData({ createdBy: 'tb' })));
  await assertFails(setDoc(doc(ta, 'serviceOrders', 'closed', 'partRequests', 'req'), requestData()));
  await assertFails(setDoc(ref, requestData({ status: 'approved', sellPrice: 1 })));
  await assertSucceeds(setDoc(ref, requestData()));
  await assertFails(updateDoc(ref, { quantity: 4 }));
  await assertFails(updateDoc(doc(db, 'serviceOrders', 'so', 'partRequests', 'req'), { status: 'approved', movementId: 'Q~so~req', decidedBy: 'admin', decidedAt: now(), decisionReason: 'Setuju' }));
  await assertFails(post(db, 'Q~so~req', { kind: 'usage', quantity: 2, so: 'so', requestId: 'req', noApproval: true }));
  await assertFails(post(db, 'not-canonical', { kind: 'usage', quantity: 2, so: 'so', requestId: 'req' }));
  await assertSucceeds(post(db, 'Q~so~req', { kind: 'usage', quantity: 2, so: 'so', requestId: 'req' }));
  await assertFails(post(db, 'another', { kind: 'usage', quantity: 2, so: 'so', requestId: 'req' }));
  assert.equal((await getDoc(doc(db, 'spareparts', 'OIL'))).data().stock, 3);
  assert.equal((await getDoc(ref)).data().status, 'approved');
  await assertFails(updateDoc(doc(db, 'serviceOrders', 'so', 'partRequests', 'req'), { status: 'rejected', decidedAt: now() }));
});

test('corrections require reasons and witnesses; rejection changes no stock; low-stock view bounded and accurate', async () => {
  const db = client('admin'); await post(db, 'receipt');
  await post(db, 'loss', { kind: 'adjustment', quantity: 3, delta: -3, reason: 'Rusak' });
  assert.equal((await getDoc(doc(db, 'spareparts', 'OIL'))).data().lowStock, true);
  await assertFails(post(db, 'empty-reason', { kind: 'adjustment', quantity: 1, reason: '' }));
  await assertFails(post(db, 'blank-reason', { kind: 'adjustment', quantity: 1, reason: ' \n\t' }));
  await assertSucceeds(post(db, 'multiline-reason', { kind: 'adjustment', quantity: 1, delta: 1, reason: 'Koreksi\nHitung fisik' }));
  await assertFails(post(db, 'x'.repeat(179), { kind: 'adjustment', quantity: 1, reason: 'ID terlalu panjang untuk reversal' }));
  await setDoc(doc(client('ta'), 'serviceOrders', 'so', 'partRequests', 'req'), requestData());
  await assertSucceeds(updateDoc(doc(db, 'serviceOrders', 'so', 'partRequests', 'req'), { status: 'rejected', decidedBy: 'admin', decidedAt: now(), decisionReason: 'Tidak perlu' }));
  assert.equal((await getDoc(doc(db, 'spareparts', 'OIL'))).data().stock, 3);
  const q = query(collection(db, 'spareparts'), where('lowStock', '==', true), where('active', '==', true), where('category', '==', 'Pelumas'), orderBy('sku'), limit(20));
  assert.equal((await getDocs(q)).size, 0);
  await assertFails(getDocs(query(collection(db, 'spareparts'), limit(21))));
  await assertFails(getDocs(query(collection(db, 'stockMovements'))));
});

test('customers and technicians cannot read purchase prices, edit stock/price/ledger; customer reads only own sales lines', async () => {
  const db = client('admin'); await post(db, 'receipt'); await post(db, 'use', { kind: 'usage', quantity: 2, so: 'so' });
  for (const c of [client('customer'), client('ta'), client('tb'), client('disabled'), client('invalid'), client('admin', { email_verified: false }), env.unauthenticatedContext().firestore()]) {
    await assertFails(getDoc(doc(c, 'spareparts', 'OIL')));
    await assertFails(getDoc(doc(c, 'stockMovements', 'use')));
    await assertFails(updateDoc(doc(c, 'spareparts', 'OIL'), { stock: 99, sellPrice: 1, updatedAt: now() }));
  }
  await assertSucceeds(getDocs(query(collection(client('customer'), 'serviceOrders', 'so', 'partUsages'), limit(20))));
  await assertFails(getDocs(query(collection(client('other'), 'serviceOrders', 'so', 'partUsages'), limit(20))));
  await assertFails(getDoc(doc(client('customer'), 'serviceOrders', 'so', 'partRequests', 'req')));
  await assertFails(setDoc(doc(client('ta'), 'serviceOrders', 'so', 'partUsages', 'fake'), { sellPrice: 1 }));
});

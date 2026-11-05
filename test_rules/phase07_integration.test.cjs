const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const { doc, getDoc, getDocs, collection, query, where, limit, onSnapshot, updateDoc, deleteDoc } = require('firebase/firestore');
const { assertFails } = require('@firebase/rules-unit-testing');
const { context, seed, reset, validate, accounts, credentialsPath, mutateOrder } = require('../tools/test-data.cjs');
const { localRequest, PROJECT } = require('../tools/emulator-safety.cjs');
const manifest = require('../test_data/phase07.manifest.json');

test('Phase 07: real Auth clients, complete workflow, reconciliation, isolation, realtime, repeatable seed/reset', { timeout: 600000 }, async () => {
  const ctx = await context();
  try {
    await reset(ctx);
    await ctx.env.clearFirestore();
    const first = await seed(ctx);
    assert.deepEqual(first.counts, manifest.counts);
    assert.deepEqual(accounts.map(([uid,email,role]) => ({uid,email,role})), manifest.accounts);
    assert.equal(first.paidRevenue, manifest.paidRevenueRupiah);
    assert.deepEqual(await seed(ctx), first);
    const credentials = JSON.parse(fs.readFileSync(credentialsPath));
    const password = credentials.accounts[0].password;
    const admin = await ctx.login(accounts[0], password), customer = await ctx.login(accounts[1], password),
      other = await ctx.login(accounts[2], password), tech = await ctx.login(accounts[3], password);
    await assertFails(getDoc(doc(other, 'invoices/p07-b0')));
    await assertFails(getDoc(doc(other, 'serviceOrders/p07-b0')));
    await assertFails(getDoc(doc(tech, 'invoices/p07-b0')));
    await assertFails(getDoc(doc(tech, 'spareparts/P07_0')));
    await assertFails(updateDoc(doc(customer, 'users/p07-customer'), { role: 'admin' }));
    await assertFails(deleteDoc(doc(admin, 'serviceOrders/p07-b0/events/0')));
    const disabled = disableUser => localRequest(`http://${ctx.config.auth}/identitytoolkit.googleapis.com/v1/projects/${PROJECT}/accounts:update`, {
      method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: 'Bearer owner' },
      body: JSON.stringify({ localId: accounts[2][0], disableUser }) });
    await disabled(true);
    await assert.rejects(ctx.login(accounts[2], password), e => e.code === 'auth/user-disabled');
    await disabled(false);
    const history = await getDocs(query(collection(customer, 'serviceOrders'), where('customerId','==','p07-customer'), where('status','==','completed'), limit(20)));
    assert.equal(history.size, 2);
    const revenue = await getDocs(query(collection(admin, 'invoices'), where('status','==','paid'), limit(20)));
    assert.equal(revenue.docs.reduce((n,d)=>n+d.data().grandTotal,0),127000);
    let unsubscribe;
    const paused = new Promise((resolve, reject) => {
      const timer = setTimeout(() => { unsubscribe?.(); reject(new Error('Realtime update timed out')); }, 15000);
      unsubscribe = onSnapshot(doc(customer, 'serviceOrders/p07-b4'), snap => {
        if (snap.data()?.status === 'paused') { clearTimeout(timer); unsubscribe?.(); resolve(); }
      }, error => { clearTimeout(timer); reject(error); });
    });
    await mutateOrder(tech, 'p07-b4', 'p07-technician', { status: 'paused' }, 'statusChanged');
    await paused;
    // This extra event belongs to the test and is explicitly removed before fixture reconciliation.
    await ctx.trusted(async db => { const { writeBatch } = require('firebase/firestore');
      const b = writeBatch(db); b.delete(doc(db, 'serviceOrders/p07-b4/events/3')); await b.commit(); });
    await reset(ctx);
    assert.equal((await ctx.trusted(db => getDocs(collection(db,'invoices')))).size, 0);
    assert.equal((await ctx.trusted(db => getDocs(collection(db,'users')))).size, 0);
    assert.equal(fs.existsSync(credentialsPath), false);
    fs.writeFileSync(credentialsPath, '{}');
    assert.deepEqual(await reset(ctx), { deletedDocuments: 0, deletedAccounts: 0 });
    assert.equal(fs.existsSync(credentialsPath), false);
    const authAfterReset = await localRequest(`http://${ctx.config.auth}/identitytoolkit.googleapis.com/v1/projects/${PROJECT}/accounts:batchGet`, { headers: { Authorization: 'Bearer owner' } });
    assert.ok(!(authAfterReset.users || []).some(u => accounts.some(a => a[0] === u.localId)));
    await seed(ctx); assert.deepEqual(await validate(ctx), first);
    console.log('PHASE07_DATASET', JSON.stringify(first));
  } finally { await ctx.close(); }
});

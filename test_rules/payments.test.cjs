const { before, after, beforeEach, test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, setDoc, getDoc, getDocs, updateDoc, deleteDoc, collection, query, where, orderBy, limit, startAfter, runTransaction, writeBatch, serverTimestamp, Timestamp } = require('firebase/firestore');
let env;
const db = uid => env.authenticatedContext(uid, { email_verified: true }).firestore();
const now = () => serverTimestamp();
const invoice = () => ({ invoiceNo: 'INV~so', serviceOrderId: 'so', customerId: 'customer',
  serviceName: 'Oli', vehiclePlate: 'B 1234 AA', laborPrice: 75000, parts: [], partSubtotal: 0,
  subtotal: 75000, discount: 0, fee: 0, grandTotal: 75000, paidAmount: 0, change: 0, due: 75000,
  method: 'none', status: 'unpaid', recordedBy: 'admin', paidAt: null, createdAt: now(), updatedAt: now(),
  notes: 'Disahkan', revision: 0, lastKey: 'issued' });
const issueEvent = () => ({key: 'issued', revision: 0, kind: 'issued', amount: 0, applied: 0,
  change: 0, method: 'none', notes: 'Disahkan', recordedBy: 'admin', paidAt: now()});
async function issue(client, changes = {}, noAudit = false) {
  const batch = writeBatch(client);
  batch.set(doc(client, 'invoices', 'so'), {...invoice(), ...changes});
  if (!noAudit) batch.set(doc(client, 'invoices/so/payments/issued'), issueEvent());
  return batch.commit();
}
async function pay(client, key = 'idempotent_key_01', amount = 50000, overrides = {}) {
  try { return await runTransaction(client, async tx => {
    const event = doc(client, 'invoices/so/payments', key);
    const oldEvent = await tx.get(event);
    const ref = doc(client, 'invoices/so'), s = await tx.get(ref), old = s.data();
    if (oldEvent.exists()) return;
    const applied = Math.min(amount, old.due), change = amount-applied;
    const e = {key, revision: old.revision+1, kind: 'payment', amount, applied, change,
      method: 'cash', notes: 'Uang diterima', recordedBy: 'admin', paidAt: now(), ...overrides.event};
    tx.update(ref, {revision: old.revision+1, lastKey: key, paidAmount: old.paidAmount+applied,
      due: old.due-applied, change: old.change+change, status: applied===old.due ? 'paid' : 'partial',
      paidAt: applied===old.due ? now() : old.paidAt, updatedAt: now(), recordedBy: 'admin', method: e.method,
      notes: e.notes, ...overrides.invoice});
    if (!overrides.noAudit) tx.set(event, e);
  }); } catch (error) {
    // Same reconciliation as the Dart repository; no second write on retry.
    const existing = await getDoc(doc(client, 'invoices/so/payments', key));
    if (existing.exists() && existing.data().amount === amount &&
        existing.data().kind === 'payment' && existing.data().method === 'cash' &&
        existing.data().notes === 'Uang diterima' && existing.data().recordedBy === 'admin' &&
        Object.keys(overrides).length === 0) return;
    throw error;
  }
}
before(async () => { env = await initializeTestEnvironment({ projectId: 'demo-bengkelku', firestore: {rules: fs.readFileSync('firestore.rules','utf8')} }); });
after(async () => env?.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async ctx => {
    for (const [uid,role,active] of [['admin','admin',true],['customer','customer',true],['other','customer',true],['tech','technician',true],['disabled','admin',false]])
      await setDoc(doc(ctx.firestore(),'users',uid),{role,active});
    await setDoc(doc(ctx.firestore(),'serviceOrders','so'),{status:'completed',customerId:'customer', serviceName:'Oli',vehiclePlate:'B 1234 AA',laborPrice:75000});
  });
});
test('issue requires admin, completed SO, canonical invoice number, integer totals and atomic audit', async () => {
  for (const uid of ['customer','other','tech','disabled']) await assertFails(issue(db(uid)));
  for (const changes of [{invoiceNo:'OTHER'}, {serviceOrderId:'other'}, {customerId:'other'},
    {laborPrice:1}, {discount:0.5}, {fee:-1}, {grandTotal:1}, {status:'paid'}, {paidAmount:1},
    {revision:1}, {lastKey:'other'}, {paidAt:now()}, {notes:''}]) await assertFails(issue(db('admin'),changes));
  await assertFails(issue(db('admin'),{},true));
  await assertSucceeds(issue(db('admin')));
  await assertFails(issue(db('admin')));
  await assertFails(deleteDoc(doc(db('admin'),'invoices/so')));
});
test('customer reads own invoice/audit, never writes payments or reads other invoices/admin report data', async () => {
  await issue(db('admin'));
  await assertSucceeds(getDoc(doc(db('customer'),'invoices/so')));
  await assertSucceeds(getDocs(query(collection(db('customer'),'invoices'),where('customerId','==','customer'),limit(20))));
  await assertSucceeds(getDocs(query(collection(db('customer'),'invoices/so/payments'),limit(20))));
  for (const uid of ['other','tech','disabled']) await assertFails(getDoc(doc(db(uid),'invoices/so')));
  await assertFails(getDocs(query(collection(db('customer'),'invoices'),limit(20))));
  await assertFails(pay(db('customer')));
  for (const collectionName of ['reports','stockMovements','spareparts'])
    await assertFails(getDocs(query(collection(db('customer'),collectionName),limit(20))));
});
test('simultaneous double submit produces one payment and one revision, excess cash is change', async () => {
  const a=db('admin'); await issue(a);
  const results = await Promise.allSettled([pay(a),pay(a)]);
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 2, JSON.stringify(results));
  let d=(await getDoc(doc(a,'invoices/so'))).data();
  assert.equal(d.paidAmount,50000); assert.equal(d.revision,1); assert.equal(d.status,'partial');
  assert.equal((await getDocs(query(collection(a,'invoices/so/payments'),limit(20)))).size,2);
  await assertSucceeds(pay(a,'idempotent_key_02',30000));
  d=(await getDoc(doc(a,'invoices/so'))).data();
  assert.equal(d.status,'paid'); assert.equal(d.due,0); assert.equal(d.change,5000);
  await assertFails(pay(a,'idempotent_key_03',100));
  await assertFails(updateDoc(doc(a,'invoices/so/payments/idempotent_key_01'),{amount:1}));
  await assertFails(deleteDoc(doc(a,'invoices/so/payments/idempotent_key_01')));
});
test('payment arithmetic tampering, float, missing audit, transfer overpay and snapshot mutation denied', async () => {
  const a=db('admin'); await issue(a);
  for (const options of [{noAudit:true}, {invoice:{paidAmount:1}}, {invoice:{due:0}},
    {invoice:{grandTotal:50000}}, {invoice:{parts:[{sellPrice:1}]}}, {invoice:{status:'paid'}},
    {invoice:{revision:9}}, {event:{applied:1}}, {event:{recordedBy:'other'}}])
    await assertFails(pay(a,'idempotent_key_01',50000,options));
  await assertFails(pay(a,'idempotent_key_01',0.5));
  await assertFails(pay(a,'idempotent_key_01',80000,{event:{method:'transfer'}}));
  await assertSucceeds(pay(a,'idempotent_key_01',75000,{event:{method:'transfer'}}));
});
async function close(a,kind,amount,overrides={}) {
  const ref=doc(a,'invoices/so'), old=(await getDoc(ref)).data(), key='closing_key_0001';
  const batch=writeBatch(a);
  batch.update(ref,{status:kind==='void'?'void':'refunded',due:0,paidAmount:0,
    method:kind==='void'?'none':'cash',notes:'Disetujui admin',recordedBy:'admin',updatedAt:now(),revision:old.revision+1,lastKey:key,...overrides});
  batch.set(doc(a,'invoices/so/payments',key),{key,revision:old.revision+1,kind,amount,
    applied:kind==='void'?0:-amount,change:0,method:kind==='void'?'none':'cash',notes:'Disetujui admin',recordedBy:'admin',paidAt:now()});
  return batch.commit();
}
test('void is unpaid only; refund is full, terminal and audited', async () => {
  const a=db('admin'); await issue(a);
  await assertSucceeds(close(a,'void',0));
  await assertFails(pay(a));
});
test('partial payment cannot void, refund cannot be partial or resurrect invoice', async () => {
  const a=db('admin'); await issue(a); await pay(a);
  await assertFails(close(a,'void',0));
  await assertFails(close(a,'refund',100));
  await assertSucceeds(close(a,'refund',50000));
  await assertFails(pay(a,'idempotent_key_02'));
  await assertFails(updateDoc(doc(a,'invoices/so'),{status:'unpaid'}));
});
test('filtered paid-only revenue query and invoice pagination bounded to 20', async () => {
  const a=db('admin'); await issue(a); await pay(a,'idempotent_key_01',75000);
  const paid=await assertSucceeds(getDocs(query(collection(a,'invoices'),where('status','==','paid'),
    where('paidAt','>=',Timestamp.fromMillis(0)),orderBy('paidAt'),limit(20))));
  assert.equal(paid.docs.reduce((sum,d)=>sum+d.data().grandTotal,0),75000);
  await assertFails(getDocs(query(collection(a,'invoices'),limit(21))));
  await assertFails(getDocs(query(collection(a,'invoices'))));
  await env.withSecurityRulesDisabled(async ctx => {
    for(let i=0;i<43;i++) await setDoc(doc(ctx.firestore(),'invoices',`page${i}`),{...invoice(), createdAt:Timestamp.fromMillis(1000)});
  });
  const q=query(collection(a,'invoices'),orderBy('createdAt'),limit(20));
  const first=await getDocs(q), second=await getDocs(query(q,startAfter(first.docs.at(-1)))), third=await getDocs(query(q,startAfter(second.docs.at(-1))));
  assert.equal(new Set([...first.docs,...second.docs,...third.docs].map(d=>d.id)).size,44);
});

const { before, after, beforeEach, test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, setDoc, updateDoc, getDoc, getDocs, collection, query, where, orderBy, limit,
  runTransaction, writeBatch, serverTimestamp, Timestamp, onSnapshot, startAfter } = require('firebase/firestore');
let env;
const db = (uid, claims = {}) => env.authenticatedContext(uid, { email_verified: true, ...claims }).firestore();
const stamp = () => serverTimestamp();
const checks = (v) => ({ vehicleChecked: v, safetyChecked: v, workChecked: v });
const booking = (status = 'confirmed') => ({ status, customerId: 'customer', vehicleId: 'v', vehicleName: 'Brio', vehiclePlate: 'B 1234 AA', serviceId: 'oil', serviceName: 'Oli', complaint: 'Mesin bising', scheduledAt: Timestamp.now() });
const orderData = (id, b) => ({ ...b, bookingId: id, status: 'queued', technicianId: null, checklist: checks(false), diagnosis: '', actions: '', notes: '', revision: 0, createdAt: stamp(), createdBy: 'admin', updatedAt: stamp(), updatedBy: 'admin', assignedAt: null, assignedBy: null, startedAt: null, completedAt: null });
function event(tx, client, id, d, kind, actor) {
  tx.set(doc(client, 'serviceOrders', id, 'events', String(d.revision)), { revision: d.revision, actorId: actor, at: stamp(), kind, status: d.status, technicianId: d.technicianId });
}
async function create(client, id, overrides = {}) {
  return runTransaction(client, async tx => {
    const b = (await tx.get(doc(client, 'bookings', id))).data();
    const existing = await tx.get(doc(client, 'serviceOrders', id));
    if (existing.exists()) throw Error('duplicate');
    const d = { ...orderData(id, b), ...overrides };
    tx.set(doc(client, 'serviceOrders', id), d); event(tx, client, id, d, 'created', 'admin');
  });
}
async function assign(client, id, tech, options = {}) {
  return runTransaction(client, async tx => {
    const ref = doc(client, 'serviceOrders', id), d = (await tx.get(ref)).data();
    const techDoc = await tx.get(doc(client, 'technicians', tech));
    await tx.get(doc(client, 'users', tech));
    if (d.technicianId) await tx.get(doc(client, 'technicians', d.technicianId));
    const changes = { technicianId: tech, technicianName: techDoc.data().name, status: 'assigned', assignedBy: 'admin', assignedAt: stamp(), updatedAt: stamp(), updatedBy: 'admin', revision: d.revision + 1, ...options.changes };
    tx.update(ref, changes);
    if (!options.noLock) tx.update(doc(client, 'technicians', tech), { currentOrderId: id });
    if (d.technicianId && d.technicianId !== tech && !options.noRelease) tx.update(doc(client, 'technicians', d.technicianId), { currentOrderId: null });
    event(tx, client, id, { ...d, ...changes }, 'assigned', 'admin');
  });
}
async function price(client, id, value = 50000, actor = 'admin') {
  const ref = doc(client, 'serviceOrders', id), d = (await getDoc(ref)).data();
  const changes = {laborPrice: value, revision: d.revision + 1, updatedAt: stamp(), updatedBy: actor};
  const batch = writeBatch(client); batch.update(ref, changes);
  event(batch, client, id, {...d, ...changes}, 'pricingUpdated', actor);
  return batch.commit();
}
async function change(client, actor, id, status, extra = {}, options = {}) {
  if (status === 'completed' && actor === 'admin') await price(client, id);
  return runTransaction(client, async tx => {
    const ref = doc(client, 'serviceOrders', id), d = (await tx.get(ref)).data();
    const changes = { status, updatedBy: actor, updatedAt: stamp(), revision: d.revision + 1, ...extra };
    if (status === 'inProgress' && d.startedAt === null) changes.startedAt = stamp();
    if (status === 'completed') changes.completedAt = stamp();
    tx.update(ref, changes);
    if (['completed', 'cancelled'].includes(status) && d.technicianId && !options.noRelease) tx.update(doc(client, 'technicians', d.technicianId), { currentOrderId: null });
    if (!options.noEvent) event(tx, client, id, { ...d, ...changes }, status === d.status ? 'workUpdated' : 'statusChanged', actor);
  });
}
before(async () => { env = await initializeTestEnvironment({ projectId: 'demo-bengkelku', firestore: { rules: fs.readFileSync('firestore.rules', 'utf8') } }); });
after(async () => env?.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async ctx => {
    const client = ctx.firestore();
    for (const [uid, role] of [['admin', 'admin'], ['customer', 'customer'], ['other', 'customer'], ['ta', 'technician'], ['tb', 'technician'], ['off', 'technician'], ['invalid', 'root']]) {
      await setDoc(doc(client, 'users', uid), { role, active: true });
      if (role === 'technician') await setDoc(doc(client, 'technicians', uid), { name: uid, specialization: 'Mesin', active: uid !== 'off', available: true, currentOrderId: null, createdAt: Timestamp.now(), updatedAt: Timestamp.now(), updatedBy: 'admin' });
    }
    for (const id of ['one', 'two', 'three']) await setDoc(doc(client, 'bookings', id), booking());
    await setDoc(doc(client, 'bookings', 'pending'), booking('pending'));
  });
});

test('canonical SO requires confirmed booking, exact snapshots, audit and immutable unique ID', async () => {
  const a = db('admin');
  await assertFails(create(a, 'pending'));
  for (const fields of [{ bookingId: 'two' }, { customerId: 'other' }, { vehicleName: 'fake' }, { status: 'assigned' }, { status: 'bogus' }, { role: 'admin' }]) await assertFails(create(a, 'one', fields));
  const data = orderData('one', booking());
  await assertFails(setDoc(doc(a, 'serviceOrders', 'one'), data));
  const results = await Promise.allSettled([create(a, 'one'), create(a, 'one')]);
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 1);
  await assert.rejects(create(a, 'one'), /duplicate/);
  await assertFails(updateDoc(doc(a, 'serviceOrders', 'one'), { customerId: 'other', updatedAt: stamp() }));
  await assertFails(create(db('customer'), 'two'));
});

test('technician provisioning stays trusted; operational fields admin only, locks cannot be forged', async () => {
  const a = db('admin');
  await assertFails(updateDoc(doc(a, 'users', 'ta'), { role: 'admin' }));
  await assertFails(updateDoc(doc(db('ta'), 'technicians', 'ta'), { active: true, currentOrderId: 'one' }));
  await assertFails(updateDoc(doc(a, 'technicians', 'ta'), { currentOrderId: 'one' }));
  await assertSucceeds(updateDoc(doc(a, 'technicians', 'ta'), { specialization: 'Rem', updatedAt: stamp(), updatedBy: 'admin' }));
  await assertFails(getDocs(query(collection(db('customer'), 'technicians'), limit(20))));
  await create(a, 'one'); await assign(a, 'one', 'ta');
  await assertFails(updateDoc(doc(a, 'technicians', 'ta'), { active: false, updatedAt: stamp(), updatedBy: 'admin' }));
  await assertFails(updateDoc(doc(a, 'technicians', 'ta'), { currentOrderId: null }));
});

test('assignment rejects inactive/unavailable tech and requires both locks; concurrent assignment has one winner', async () => {
  const a = db('admin'); await create(a, 'one'); await create(a, 'two');
  await assertFails(assign(a, 'one', 'off'));
  await env.withSecurityRulesDisabled(ctx => updateDoc(doc(ctx.firestore(), 'technicians', 'tb'), { available: false }));
  await assertFails(assign(a, 'one', 'tb'));
  await assertFails(assign(a, 'one', 'ta', { noLock: true }));
  const results = await Promise.allSettled([assign(a, 'one', 'ta'), assign(a, 'two', 'ta')]);
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 1);
  const winner = (await getDoc(doc(a, 'technicians', 'ta'))).data().currentOrderId;
  await env.withSecurityRulesDisabled(ctx => updateDoc(doc(ctx.firestore(), 'technicians', 'tb'), { available: true }));
  await assertFails(assign(a, winner, 'tb', { noRelease: true }));
  await assertSucceeds(assign(a, winner, 'tb'));
  assert.equal((await getDoc(doc(a, 'technicians', 'ta'))).data().currentOrderId, null);
  await assertFails(getDoc(doc(db('ta'), 'serviceOrders', winner)));
});

test('only assigned technician updates work; typed transitions, field ownership, server time and audit enforced', async () => {
  const a = db('admin'), ta = db('ta'); await create(a, 'one'); await assign(a, 'one', 'ta');
  await assertFails(change(db('tb'), 'tb', 'one', 'inProgress'));
  await assertFails(change(a, 'admin', 'one', 'inProgress'));
  await assertFails(change(ta, 'ta', 'one', 'bogus'));
  await assertFails(change(ta, 'ta', 'one', 'completed'));
  await assertFails(change(ta, 'ta', 'one', 'inProgress', {}, { noEvent: true }));
  await assertFails(change(ta, 'ta', 'one', 'inProgress', { updatedBy: 'admin' }));
  await assertFails(change(ta, 'ta', 'one', 'inProgress', { updatedAt: Timestamp.fromMillis(0) }));
  await assertSucceeds(change(ta, 'ta', 'one', 'inProgress'));
  await assertFails(assign(a, 'one', 'tb'));
  for (const extra of [{ customerId: 'other' }, { complaint: 'fake' }, { assignedBy: 'ta' }, { checklist: { ...checks(true), extra: true } }, { diagnosis: 'x'.repeat(2001) }]) await assertFails(change(ta, 'ta', 'one', 'inProgress', extra));
  await assertSucceeds(change(ta, 'ta', 'one', 'paused', { notes: 'Tunggu pemeriksaan' }));
  await assertSucceeds(change(ta, 'ta', 'one', 'inProgress'));
  await assertFails(change(ta, 'ta', 'one', 'awaitingApproval'));
  await assertSucceeds(change(ta, 'ta', 'one', 'awaitingApproval', { checklist: checks(true), diagnosis: 'Oli kotor', actions: 'Ganti oli' }));
  await assertFails(change(a, 'admin', 'one', 'completed', {}, { noRelease: true }));
  await assertSucceeds(change(a, 'admin', 'one', 'assigned'));
  await change(ta, 'ta', 'one', 'inProgress'); await change(ta, 'ta', 'one', 'awaitingApproval');
  await assertSucceeds(change(a, 'admin', 'one', 'completed'));
  assert.equal((await getDoc(doc(a, 'technicians', 'ta'))).data().currentOrderId, null);
  await assertFails(change(ta, 'ta', 'one', 'inProgress'));
  await assertFails(updateDoc(doc(a, 'serviceOrders', 'one', 'events', '0'), { kind: 'fake' }));
});

test('owner progress streams in realtime, role-scoped bounded queries deny other customers and technicians', async () => {
  const a = db('admin'); await create(a, 'one'); await assign(a, 'one', 'ta');
  for (const [uid, field] of [['customer', 'customerId'], ['ta', 'technicianId']]) {
    const q = query(collection(db(uid), 'serviceOrders'), where(field, '==', uid), orderBy('createdAt', 'desc'), orderBy('__name__'), limit(20));
    await assertSucceeds(getDocs(q));
    await assertFails(getDocs(query(collection(db(uid), 'serviceOrders'), limit(20))));
  }
  for (const client of [db('other'), db('tb'), db('invalid'), db('customer', { email_verified: false })]) await assertFails(getDoc(doc(client, 'serviceOrders', 'one')));
  await assertFails(getDocs(query(collection(a, 'serviceOrders'), limit(21))));
  await assertFails(change(db('customer'), 'customer', 'one', 'cancelled'));
  const next = new Promise((resolve, reject) => {
    const timeout = setTimeout(() => { stop(); reject(Error('realtime timeout')); }, 10000);
    const stop = onSnapshot(doc(db('customer'), 'serviceOrders', 'one'), s => { if (s.data()?.status === 'inProgress') { clearTimeout(timeout); stop(); resolve(s.data()); } }, reject);
  });
  await change(db('ta'), 'ta', 'one', 'inProgress');
  assert.equal((await next).status, 'inProgress');
  await assertSucceeds(change(a, 'admin', 'one', 'cancelled'));
  await env.withSecurityRulesDisabled(ctx => updateDoc(doc(ctx.firestore(), 'users', 'ta'), { active: false }));
  await assertFails(getDoc(doc(db('ta'), 'serviceOrders', 'one')));
});

test('booking cancel and SO creation cannot both commit; existing SO prevents cancellation with slot release', async () => {
  const a = db('admin'), customer = db('customer');
  const at = Timestamp.fromMillis(Date.now() + 86400000), slotId = String(at.toMillis());
  await env.withSecurityRulesDisabled(async ctx => {
    await updateDoc(doc(ctx.firestore(), 'bookings', 'one'), { scheduledAt: at, slotId });
    await setDoc(doc(ctx.firestore(), 'bookingSlots', slotId), { bookingId: 'one', scheduledAt: at, active: true });
  });
  const cancel = () => runTransaction(customer, async tx => {
    await tx.get(doc(customer, 'bookings', 'one'));
    const existing = await tx.get(doc(customer, 'serviceOrders', 'one'));
    if (existing.exists()) throw Error('service-started');
    tx.update(doc(customer, 'bookings', 'one'), { status: 'cancelled', updatedAt: stamp() });
    tx.update(doc(customer, 'bookingSlots', slotId), { active: false });
  });
  const results = await Promise.allSettled([create(a, 'one'), cancel()]);
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 1);
  if ((await getDoc(doc(a, 'serviceOrders', 'one'))).exists()) {
    const batch = writeBatch(customer);
    batch.update(doc(customer, 'bookings', 'one'), { status: 'cancelled', updatedAt: stamp() });
    batch.update(doc(customer, 'bookingSlots', slotId), { active: false });
    await assertFails(batch.commit());
  } else {
    await assertFails(create(a, 'one'));
  }
});


test('Phase 05 labor snapshots need admin, integer bounds, revision audit; terminal history immutable', async () => {
  const a = db('admin'); await create(a, 'one');
  await assertSucceeds(price(a, 'one', 0));
  await assertFails(assign(a, 'one', 'ta', {changes: {technicianName: 'Palsu'}}));
  await assign(a, 'one', 'ta');
  for (const value of [-1, 1.5, 1000000001, '50000', null]) await assertFails(price(a, 'one', value));
  await assertFails(price(db('ta'), 'one', 1, 'ta'));
  await assertFails(price(db('customer'), 'one', 1, 'customer'));
  await assertSucceeds(price(a, 'one', 75000));
  await change(db('ta'), 'ta', 'one', 'inProgress');
  await change(db('ta'), 'ta', 'one', 'awaitingApproval', {checklist: checks(true), diagnosis: 'Oli kotor', actions: 'Ganti oli'});
  // Raw completion must fail if pricing was never recorded.
  await env.withSecurityRulesDisabled(ctx => updateDoc(doc(ctx.firestore(), 'serviceOrders', 'one'), {laborPrice: null}));
  const ref = doc(a, 'serviceOrders', 'one'), d = (await getDoc(ref)).data();
  const batch = writeBatch(a), changes = {status: 'completed', completedAt: stamp(), revision: d.revision+1, updatedAt: stamp(), updatedBy: 'admin'};
  batch.update(ref, changes); batch.update(doc(a, 'technicians', 'ta'), {currentOrderId: null});
  event(batch, a, 'one', {...d, ...changes}, 'statusChanged', 'admin');
  await assertFails(batch.commit());
  await change(a, 'admin', 'one', 'completed');
  await assertFails(price(a, 'one', 1));
  for (const field of ['laborPrice', 'vehiclePlate', 'diagnosis', 'technicianName', 'completedAt']) {
    await assertFails(updateDoc(ref, {[field]: field === 'laborPrice' ? 1 : 'tamper'}));
  }
  await assertSucceeds(getDoc(doc(db('customer'), 'serviceOrders', 'one')));
  await assertSucceeds(getDoc(doc(db('ta'), 'serviceOrders', 'one')));
  await assertFails(getDoc(doc(db('other'), 'serviceOrders', 'one')));
  await assertFails(getDoc(doc(db('tb'), 'serviceOrders', 'one')));
});

test('Phase 05 completed filters and tied-date pagination stay scoped to customer or assigned technician', async () => {
  const at = Timestamp.fromMillis(1792026000000);
  await env.withSecurityRulesDisabled(async ctx => {
    for (let i=0; i<46; i++) await setDoc(doc(ctx.firestore(), 'serviceOrders', `history-${String(i).padStart(2,'0')}`), {
      ...orderData('ignored', booking()), customerId: i===45 ? 'other' : 'customer',
      technicianId: i===44 ? 'tb' : 'ta', status: i===43 ? 'inProgress' : 'completed',
      vehicleId: i===42 ? 'v2' : 'v', serviceId: i===41 ? 'brake' : 'oil', completedAt: at,
    });
  });
  for (const [uid, owner] of [['customer','customerId'], ['ta','technicianId'], ['admin',null]]) {
    const constraints = [where('status','==','completed'), ...(owner ? [where(owner,'==',uid)] : []),
      where('vehicleId','==','v'), where('serviceId','==','oil'), where('completedAt','>=',at),
      where('completedAt','<',Timestamp.fromMillis(at.toMillis()+86400000)), orderBy('completedAt','desc'), orderBy('__name__'), limit(20)];
    const first = await assertSucceeds(getDocs(query(collection(db(uid),'serviceOrders'), ...constraints)));
    const second = await assertSucceeds(getDocs(query(collection(db(uid),'serviceOrders'), ...constraints, startAfter(first.docs.at(-1)))));
    const third = await assertSucceeds(getDocs(query(collection(db(uid),'serviceOrders'), ...constraints, startAfter(second.docs.at(-1)))));
    const ids = [...first.docs,...second.docs,...third.docs].map(d=>d.id);
    assert.equal(new Set(ids).size, ids.length);
    assert.equal(ids.length, uid==='admin' ? 43 : 42);
    assert.ok(!ids.includes('history-43'));
  }
  for (const uid of ['customer','ta']) await assertFails(getDocs(query(collection(db(uid),'serviceOrders'), where('status','==','completed'), limit(20))));
});

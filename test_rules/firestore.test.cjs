const { before, after, beforeEach, test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, setDoc, getDoc, updateDoc, deleteDoc, collection, query, where, limit, orderBy,
  getDocs, writeBatch, runTransaction, serverTimestamp, Timestamp } = require('firebase/firestore');

let env;
const projectId = 'demo-bengkelku';
const date = new Date(); date.setUTCDate(date.getUTCDate() + 2); date.setUTCHours(2, 0, 0, 0);
const at = Timestamp.fromDate(date);
const slotId = String(date.getTime());
const claims = { email_verified: true, email: 'customer@example.test' };
const db = (uid, extra = {}) => env.authenticatedContext(uid, { ...claims, ...extra }).firestore();
const vehicle = (uid) => ({ ownerId: uid, name: 'Honda Brio', plate: 'B 1234 XYZ', active: true,
  createdAt: serverTimestamp(), updatedAt: serverTimestamp() });
const service = () => ({ name: 'Ganti Oli', active: true, createdAt: serverTimestamp(), updatedAt: serverTimestamp() });
const booking = (uid, overrides = {}) => ({ customerId: uid, vehicleId: `v-${uid}`,
  vehicleName: 'Honda Brio', vehiclePlate: 'B 1234 XYZ', serviceId: 'oil', serviceName: 'Ganti Oli',
  complaint: 'Mesin berbunyi', scheduledAt: at, slotId, status: 'pending',
  createdAt: serverTimestamp(), updatedAt: serverTimestamp(), ...overrides });
const lock = (id, data) => ({ bookingId: id, scheduledAt: data.scheduledAt, active: true });
async function submit(client, uid, id, overrides = {}) {
  const data = booking(uid, overrides);
  const b = doc(client, 'bookings', id);
  const s = doc(client, 'bookingSlots', data.slotId);
  return runTransaction(client, async tx => {
    const current = await tx.get(s);
    // Match the Dart repository's reads and transaction contention behavior.
    await tx.get(doc(client, 'vehicles', data.vehicleId));
    await tx.get(doc(client, 'services', data.serviceId));
    if (current.exists() && current.data().active) throw new Error('slot-occupied');
    tx.set(b, data); tx.set(s, lock(id, data));
  });
}
async function transition(client, id, status, release = true) {
  return runTransaction(client, async tx => {
    const b = doc(client, 'bookings', id);
    const data = (await tx.get(b)).data();
    tx.update(b, { status, updatedAt: serverTimestamp() });
    if (release && ['rejected', 'cancelled'].includes(status)) {
      tx.update(doc(client, 'bookingSlots', data.slotId), { active: false });
    }
  });
}

before(async () => {
  env = await initializeTestEnvironment({ projectId, firestore: { rules: fs.readFileSync('firestore.rules', 'utf8') } });
});
after(async () => { await env?.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async ctx => {
    const client = ctx.firestore();
    for (const [uid, role, active] of [['a', 'customer', true], ['b', 'customer', true], ['admin', 'admin', true], ['tech', 'technician', true], ['disabled', 'customer', false]]) {
      await setDoc(doc(client, 'users', uid), { role, active, email: claims.email, createdAt: Timestamp.now() });
      await setDoc(doc(client, 'vehicles', `v-${uid}`), vehicle(uid));
    }
    await setDoc(doc(client, 'services', 'oil'), service());
  });
});

test('public registration creates only its own customer profile, never a privileged or extra-field profile', async () => {
  const client = db('new');
  const ref = doc(client, 'users', 'new');
  const data = { email: claims.email, role: 'customer', active: true, createdAt: serverTimestamp() };
  await assertFails(setDoc(ref, { ...data, role: 'admin' }));
  await assertFails(setDoc(ref, { ...data, role: 'technician' }));
  await assertFails(setDoc(ref, { ...data, permissions: ['admin'] }));
  await assertFails(setDoc(doc(client, 'users', 'someone-else'), data));
  await assertSucceeds(setDoc(ref, data));
  await assertFails(updateDoc(ref, { role: 'admin' }));
  await assertFails(updateDoc(ref, { active: false }));
  await assertFails(deleteDoc(ref));
  await assertSucceeds(getDoc(ref));
});

test('default deny, anonymous, unverified and inactive accounts cannot read operational data', async () => {
  for (const client of [env.unauthenticatedContext().firestore(), db('a', { email_verified: false }), db('disabled')]) {
    await assertFails(getDoc(doc(client, 'services', 'oil')));
    await assertFails(setDoc(doc(client, 'vehicles', 'new'), vehicle('a')));
    await assertFails(getDoc(doc(client, 'bookingSlots', slotId)));
  }
  await assertSucceeds(getDoc(doc(db('disabled'), 'users', 'disabled')));
  await assertFails(getDoc(doc(db('a'), 'private', 'secret')));
});

test('customer A cannot read, query or change customer B profiles, vehicles or bookings', async () => {
  const a = db('a'); const b = db('b');
  await submit(b, 'b', 'b-booking');
  for (const path of ['users/b', 'vehicles/v-b', 'bookings/b-booking']) await assertFails(getDoc(doc(a, path)));
  await assertFails(updateDoc(doc(a, 'vehicles/v-b'), { name: 'Hijacked', updatedAt: serverTimestamp() }));
  await assertFails(getDocs(query(collection(a, 'vehicles'), limit(50))));
  await assertFails(getDocs(query(collection(a, 'bookings'), limit(100))));
  await assertFails(getDocs(query(collection(a, 'bookings'), where('customerId', '==', 'b'), limit(100))));
  await assertSucceeds(getDocs(query(collection(a, 'bookings'), where('customerId', '==', 'a'), orderBy('createdAt', 'desc'), limit(100))));
  await assertFails(getDocs(query(collection(a, 'bookings'), where('customerId', '==', 'a'))));
  await assertFails(getDocs(query(collection(a, 'bookings'), where('customerId', '==', 'a'), limit(101))));
  await assertFails(getDocs(query(collection(a, 'bookingSlots'), limit(100))));
});

test('vehicles CRUD validates plate and immutable ownership; delete archives and cannot reactivate', async () => {
  const a = db('a'); const v = doc(a, 'vehicles', 'created');
  await assertFails(setDoc(v, vehicle('b')));
  await assertFails(setDoc(v, { ...vehicle('a'), plate: 'INVALID' }));
  await assertSucceeds(setDoc(v, vehicle('a')));
  await assertSucceeds(updateDoc(v, { name: 'Toyota', plate: 'AB 22 CD', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(v, { ownerId: 'b', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(v, { createdAt: Timestamp.fromMillis(0), updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(v, { role: 'admin', updatedAt: serverTimestamp() }));
  await assertSucceeds(updateDoc(v, { active: false, updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(v, { active: true, updatedAt: serverTimestamp() }));
  await assertFails(deleteDoc(v));
  await assertSucceeds(getDocs(query(collection(a, 'vehicles'), where('ownerId', '==', 'a'), where('active', '==', true), limit(50))));
});

test('catalog is customer read and admin write; technician cannot mutate it', async () => {
  const ref = doc(db('admin'), 'services', 'new');
  await assertFails(setDoc(doc(db('a'), 'services', 'new'), service()));
  await assertFails(setDoc(doc(db('tech'), 'services', 'new'), service()));
  await assertSucceeds(setDoc(ref, service()));
  await assertSucceeds(updateDoc(ref, { name: 'Tune Up', updatedAt: serverTimestamp() }));
  await assertSucceeds(updateDoc(ref, { active: false, updatedAt: serverTimestamp() }));
  await assertFails(getDoc(doc(db('a'), 'services', 'new')));
  await assertSucceeds(getDocs(query(collection(db('a'), 'services'), where('active', '==', true), limit(50))));
});

test('booking requires atomic canonical lock, owner vehicle, active service and valid data', async () => {
  const a = db('a');
  await assertFails(setDoc(doc(a, 'bookings', 'no-lock'), booking('a')));
  await assertFails(setDoc(doc(a, 'bookingSlots', slotId), lock('no-booking', booking('a'))));
  // Forge full batches rather than relying on repository-side checks.
  for (const changes of [
    { customerId: 'b' }, { vehicleId: 'v-b' }, { vehicleName: 'spoofed' }, { vehiclePlate: 'B 9 FAKE' },
    { serviceId: 'missing' }, { serviceName: 'spoofed' }, { complaint: 'x' }, { complaint: 'x'.repeat(501) },
    { status: 'confirmed' }, { slotId: 'alternate' }, { admin: true },
    { scheduledAt: Timestamp.fromMillis(0), slotId: '0' },
    { scheduledAt: Timestamp.fromMillis(date.getTime() + 60000), slotId: String(date.getTime() + 60000) },
    { scheduledAt: Timestamp.fromMillis(date.getTime() + 3 * 3600000), slotId: String(date.getTime() + 3 * 3600000) },
    { scheduledAt: Timestamp.fromMillis(date.getTime() + 91 * 86400000), slotId: String(date.getTime() + 91 * 86400000) },
  ]) {
    const batch = writeBatch(a); const data = booking('a', changes);
    batch.set(doc(a, 'bookings', 'forged'), data);
    batch.set(doc(a, 'bookingSlots', data.slotId), lock('forged', data));
    await assertFails(batch.commit());
  }
  await assertSucceeds(submit(a, 'a', 'valid'));
});

test('admin confirms/rejects, customer cancels, immutable fields and terminal transitions stay protected', async () => {
  const a = db('a'); const admin = db('admin');
  await submit(a, 'a', 'one');
  await assertSucceeds(getDoc(doc(admin, 'bookings', 'one')));
  await assertSucceeds(getDocs(query(collection(admin, 'bookings'), orderBy('createdAt', 'desc'), limit(100))));
  await assertFails(getDoc(doc(db('tech'), 'bookings', 'one')));
  await assertFails(transition(a, 'one', 'confirmed'));
  await assertFails(updateDoc(doc(admin, 'bookings', 'one'), { customerId: 'admin', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(admin, 'bookings', 'one'), { complaint: 'changed', updatedAt: serverTimestamp() }));
  await assertSucceeds(transition(admin, 'one', 'confirmed'));
  await assertFails(transition(admin, 'one', 'rejected'));
  await assertFails(transition(db('b'), 'one', 'cancelled'));
  await assertFails(transition(a, 'one', 'cancelled', false));
  await assertSucceeds(transition(a, 'one', 'cancelled'));
  await assertFails(transition(admin, 'one', 'confirmed'));
  await assertSucceeds(submit(db('b'), 'b', 'two'));
  await assertSucceeds(transition(admin, 'two', 'rejected'));
  await assertFails(transition(db('b'), 'two', 'cancelled'));
  await assertFails(deleteDoc(doc(admin, 'bookings', 'two')));
});

test('concurrent customer transactions yield exactly one booking, lock cannot be stolen or released alone', async () => {
  const a = db('a'); const b = db('b');
  const results = await Promise.allSettled([submit(a, 'a', 'race-a'), submit(b, 'b', 'race-b')]);
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 1);
  const winner = results[0].status === 'fulfilled' ? 'race-a' : 'race-b';
  const uid = winner === 'race-a' ? 'a' : 'b';
  const locks = (await getDoc(doc(db(uid), 'bookingSlots', slotId))).data();
  assert.equal(locks.bookingId, winner);
  await assertFails(updateDoc(doc(db(uid), 'bookingSlots', slotId), { active: false }));
  await assertFails(updateDoc(doc(db(uid), 'bookingSlots', slotId), { bookingId: 'stolen' }));
  await assertFails(deleteDoc(doc(db('admin'), 'bookingSlots', slotId)));
  await env.withSecurityRulesDisabled(async ctx => {
    assert.equal((await getDocs(collection(ctx.firestore(), 'bookings'))).size, 1);
  });
  await transition(db(uid), winner, 'cancelled');
  await assertSucceeds(submit(db('b'), 'b', 'reused'));
  // A fresh client/context sees committed data, independent of the first client cache.
  const fresh = env.authenticatedContext('b', claims).firestore();
  assert.equal((await getDoc(doc(fresh, 'bookings', 'reused'))).data().status, 'pending');
});

test('deactivation revokes data access and cannot be undone by customer', async () => {
  const a = db('a');
  await submit(a, 'a', 'one');
  await env.withSecurityRulesDisabled(ctx => updateDoc(doc(ctx.firestore(), 'users', 'a'), { active: false }));
  await assertFails(getDoc(doc(a, 'bookings', 'one')));
  await assertFails(transition(a, 'one', 'cancelled'));
  await assertFails(updateDoc(doc(a, 'users', 'a'), { active: true }));
});

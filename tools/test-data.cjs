const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const { initializeTestEnvironment } = require('@firebase/rules-unit-testing');
const { initializeApp, deleteApp } = require('firebase/app');
const { getAuth, connectAuthEmulator, signInWithEmailAndPassword } = require('firebase/auth');
const { getFirestore, connectFirestoreEmulator, doc, collection, getDoc, getDocs, query,
  limit, setDoc, updateDoc, writeBatch, runTransaction, serverTimestamp: now, Timestamp, terminate } = require('firebase/firestore');
const { PROJECT, preflight, localRequest, credentialsFileName } = require('./emulator-safety.cjs');

const accounts = [
  ['p07-admin', 'admin.demo@bengkelku.test', 'admin'],
  ['p07-customer', 'customer.demo@bengkelku.test', 'customer'],
  ['p07-customer2', 'customer2.demo@bengkelku.test', 'customer'],
  ['p07-technician', 'technician.demo@bengkelku.test', 'technician'],
];
const manifestPath = '_testManifests/phase07';
const credentialsPath = path.resolve(__dirname, '../.firebase', credentialsFileName(process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099'));

async function context() {
  const config = await preflight();
  const [host, port] = config.firestore.split(':');
  const env = await initializeTestEnvironment({ projectId: PROJECT, firestore: { host, port: Number(port) } });
  const clients = [];
  return { config, env, clients,
    async trusted(fn) {
      let value;
      await env.withSecurityRulesDisabled(async ctx => { value = await fn(ctx.firestore()); });
      return value;
    },
    async login(account, password) {
      const app = initializeApp({ projectId: PROJECT, apiKey: 'emulator-only', appId: 'emulator-only' }, `p07-${crypto.randomUUID()}`);
      const auth = getAuth(app);
      connectAuthEmulator(auth, `http://${config.auth}`, { disableWarnings: true });
      const db = getFirestore(app);
      connectFirestoreEmulator(db, host, Number(port));
      clients.push({ app, db });
      const { user } = await signInWithEmailAndPassword(auth, account[1], password);
      assert.equal(user.uid, account[0]); assert.equal(user.emailVerified, true);
      return db;
    },
    async close() {
      await Promise.all(clients.map(async c => { await terminate(c.db); await deleteApp(c.app); }));
      await env.cleanup();
    },
  };
}

function plannedPaths(schedules) {
  const paths = accounts.map(a => `users/${a[0]}`);
  paths.push('technicians/p07-technician');
  for (let i = 0; i < 6; i++) paths.push(`vehicles/p07-v${i}`);
  for (let i = 0; i < 5; i++) paths.push(`services/p07-s${i}`);
  for (let i = 0; i < 12; i++) paths.push(`spareparts/P07_${i}`, `stockMovements/p07-receipt${i}`);
  for (let i = 0; i < 8; i++) paths.push(`bookings/p07-b${i}`, `bookingSlots/${schedules[i]}`);
  for (let i = 0; i < 5; i++) {
    const so = `serviceOrders/p07-b${i}`, movement = `Q~p07-b${i}~p07-request`;
    paths.push(so, `${so}/partRequests/p07-request`, `${so}/partUsages/${movement}`, `stockMovements/${movement}`);
    for (let r = 0; r <= (i < 4 ? 5 : 2); r++) paths.push(`${so}/events/${r}`);
    if (i < 4) {
      paths.push(`invoices/p07-b${i}`, `invoices/p07-b${i}/payments/issued`);
      if (i > 0) paths.push(`invoices/p07-b${i}/payments/p07-payment`);
      if (i === 3) paths.push(`invoices/p07-b${i}/payments/p07-refund`);
    }
  }
  return paths;
}

async function mutateOrder(db, id, actor, changes, kind, lock) {
  return runTransaction(db, async tx => {
    const ref = doc(db, 'serviceOrders', id), old = (await tx.get(ref)).data();
    const d = { ...old, ...changes, revision: old.revision + 1, updatedAt: now(), updatedBy: actor };
    tx.update(ref, { ...changes, revision: d.revision, updatedAt: now(), updatedBy: actor });
    if (lock !== undefined) tx.update(doc(db, 'technicians/p07-technician'), { currentOrderId: lock });
    tx.set(doc(db, `serviceOrders/${id}/events/${d.revision}`), {
      revision: d.revision, actorId: actor, at: now(), kind, status: d.status, technicianId: d.technicianId });
  });
}

async function movement(db, sku, id, so = null) {
  return runTransaction(db, async tx => {
    const ref = doc(db, 'spareparts', sku), p = (await tx.get(ref)).data();
    const quantity = so ? 1 : (sku === 'P07_11' ? 2 : 10), delta = so ? -quantity : quantity;
    const data = { sku, kind: so ? 'usage' : 'receipt', quantity, delta, reason: 'Pengujian emulator Phase 07',
      serviceOrderId: so, requestId: so ? 'p07-request' : null, reversalOf: null,
      balanceBefore: p.stock, balanceAfter: p.stock + delta, stockRevision: p.stockRevision + 1,
      name: p.name, unit: p.unit, buyPrice: p.buyPrice, sellPrice: p.sellPrice,
      actorId: 'p07-admin', createdAt: now() };
    tx.update(ref, { stock: data.balanceAfter, lowStock: data.balanceAfter <= p.minimumStock,
      stockRevision: data.stockRevision, version: p.version + 1, lastMovementId: id, updatedAt: now(), updatedBy: 'p07-admin' });
    tx.set(doc(db, 'stockMovements', id), data);
    if (so) {
      tx.set(doc(db, `serviceOrders/${so}/partUsages/${id}`), { movementId: id, sku, name: p.name,
        unit: p.unit, quantity, sellPrice: p.sellPrice, kind: 'usage', reversalOf: null, actorId: 'p07-admin', createdAt: now() });
      tx.update(doc(db, `serviceOrders/${so}/partRequests/p07-request`), { status: 'approved', movementId: id,
        decidedBy: 'p07-admin', decidedAt: now(), decisionReason: data.reason });
    }
  });
}

async function seed(ctx) {
  const old = await ctx.trusted(db => getDoc(doc(db, manifestPath)));
  if (old.exists()) {
    assert.equal(old.data().state, 'complete', 'Interrupted seed: run reset first');
    return validate(ctx);
  }
  const base = new Date(); base.setUTCDate(base.getUTCDate() + 1); base.setUTCHours(2, 0, 0, 0);
  const schedules = Array.from({ length: 8 }, (_, i) => base.getTime() + i * 86400000);
  const paths = plannedPaths(schedules);
  // Refuse collisions, including a previous emulator account without its manifest.
  const existingAuth = await localRequest(`http://${ctx.config.auth}/identitytoolkit.googleapis.com/v1/projects/${PROJECT}/accounts:batchGet`, { headers: { Authorization: 'Bearer owner' } });
  assert.ok(!(existingAuth.users || []).some(u => accounts.some(a => a[0] === u.localId || a[1] === u.email)), 'Account collision; use a clean isolated emulator');
  await ctx.trusted(async db => {
    for (const p of paths) assert.equal((await getDoc(doc(db, p))).exists(), false, `Fixture collision: ${p}`);
    await setDoc(doc(db, manifestPath), { version: 1, state: 'building', paths, authUids: accounts.map(a => a[0]), createdAt: now() });
  });
  const password = crypto.randomBytes(24).toString('base64url');
  fs.mkdirSync(path.dirname(credentialsPath), { recursive: true });
  fs.writeFileSync(credentialsPath, JSON.stringify({ projectId: PROJECT, accounts: accounts.map(([uid, email, role]) => ({ uid, email, role, password })) }, null, 2), { mode: 0o600 });
  for (const [uid, email, role] of accounts) {
    await localRequest(`http://${ctx.config.auth}/identitytoolkit.googleapis.com/v1/projects/${PROJECT}/accounts`, {
      method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: 'Bearer owner' },
      body: JSON.stringify({ localId: uid, email, password, emailVerified: true }) });
    await ctx.trusted(db => setDoc(doc(db, 'users', uid), { email, role, active: true, createdAt: now() }));
  }
  const admin = await ctx.login(accounts[0], password), customers = [await ctx.login(accounts[1], password), await ctx.login(accounts[2], password)];
  const tech = await ctx.login(accounts[3], password);
  await setDoc(doc(admin, 'technicians/p07-technician'), { name: 'Teknisi Demo', specialization: 'Mesin', active: true,
    available: true, currentOrderId: null, createdAt: now(), updatedAt: now(), updatedBy: 'p07-admin' });
  for (let i = 0; i < 6; i++) await setDoc(doc(customers[i % 2], `vehicles/p07-v${i}`), {
    ownerId: accounts[1 + i % 2][0], name: ['Honda Brio', 'Toyota Avanza', 'Suzuki Ertiga', 'Daihatsu Ayla', 'Honda Beat', 'Yamaha NMAX'][i],
    plate: `B ${7100 + i} QA`, active: true, createdAt: now(), updatedAt: now() });
  for (let i = 0; i < 5; i++) await setDoc(doc(admin, `services/p07-s${i}`), {
    name: ['Ganti Oli', 'Servis Rem', 'Tune Up', 'Servis Berkala', 'Pemeriksaan Kelistrikan'][i], active: true, createdAt: now(), updatedAt: now() });
  for (let i = 0; i < 12; i++) {
    await setDoc(doc(admin, `spareparts/P07_${i}`), { sku: `P07_${i}`,
      name: ['Oli Mesin', 'Filter Oli', 'Kampas Rem', 'Busi', 'Filter Udara', 'Aki', 'Minyak Rem', 'Coolant', 'V-Belt', 'Lampu', 'Sekring', 'Bearing'][i],
      category: i < 2 ? 'Pelumas' : 'Komponen', unit: 'buah', supplier: 'Pemasok Demo', buyPrice: 30000 + i * 1000,
      sellPrice: 50000 + i * 1000, minimumStock: 2, stock: 0, lowStock: true, stockRevision: 0,
      lastMovementId: null, version: 0, active: true, createdAt: now(), createdBy: 'p07-admin', updatedAt: now(), updatedBy: 'p07-admin' });
    await movement(admin, `P07_${i}`, `p07-receipt${i}`);
  }
  for (let i = 0; i < 8; i++) {
    const customer = customers[i % 2], v = (await getDoc(doc(customer, `vehicles/p07-v${i % 6}`))).data();
    const service = (await getDoc(doc(customer, `services/p07-s${i % 5}`))).data();
    const b = { customerId: accounts[1 + i % 2][0], vehicleId: `p07-v${i % 6}`, vehicleName: v.name, vehiclePlate: v.plate,
      serviceId: `p07-s${i % 5}`, serviceName: service.name, complaint: 'Pemeriksaan rutin kendaraan', scheduledAt: Timestamp.fromMillis(schedules[i]),
      slotId: String(schedules[i]), status: 'pending', createdAt: now(), updatedAt: now() };
    const batch = writeBatch(customer);
    batch.set(doc(customer, `bookings/p07-b${i}`), b);
    batch.set(doc(customer, `bookingSlots/${b.slotId}`), { bookingId: `p07-b${i}`, scheduledAt: b.scheduledAt, active: true });
    await batch.commit();
    if (i === 5) continue;
    const status = i < 5 ? 'confirmed' : i === 6 ? 'cancelled' : 'rejected';
    const client = i === 6 ? customer : admin, transition = writeBatch(client);
    transition.update(doc(client, `bookings/p07-b${i}`), { status, updatedAt: now() });
    if (i >= 6) transition.update(doc(client, `bookingSlots/${b.slotId}`), { active: false });
    await transition.commit();
    if (i >= 5) continue;
    const id = `p07-b${i}`, order = { ...b, bookingId: id, status: 'queued', technicianId: null,
      checklist: { vehicleChecked: false, safetyChecked: false, workChecked: false }, diagnosis: '', actions: '', notes: '', revision: 0,
      createdAt: now(), createdBy: 'p07-admin', updatedAt: now(), updatedBy: 'p07-admin', assignedAt: null, assignedBy: null, startedAt: null, completedAt: null };
    delete order.slotId;
    const create = writeBatch(admin);
    create.set(doc(admin, `serviceOrders/${id}`), order);
    create.set(doc(admin, `serviceOrders/${id}/events/0`), { revision: 0, actorId: 'p07-admin', at: now(), kind: 'created', status: 'queued', technicianId: null });
    await create.commit();
    await mutateOrder(admin, id, 'p07-admin', { status: 'assigned', technicianId: 'p07-technician', technicianName: 'Teknisi Demo', assignedBy: 'p07-admin', assignedAt: now() }, 'assigned', id);
    await mutateOrder(tech, id, 'p07-technician', { status: 'inProgress', startedAt: now() }, 'statusChanged');
    await setDoc(doc(tech, `serviceOrders/${id}/partRequests/p07-request`), { sku: `P07_${i}`, quantity: 1, reason: 'Penggantian komponen',
      status: 'pending', createdBy: 'p07-technician', createdAt: now(), decidedBy: null, decidedAt: null, decisionReason: '', movementId: null });
    await movement(admin, `P07_${i}`, `Q~${id}~p07-request`, id);
    if (i === 4) continue;
    await mutateOrder(tech, id, 'p07-technician', { status: 'awaitingApproval', checklist: { vehicleChecked: true, safetyChecked: true, workChecked: true }, diagnosis: 'Komponen aus', actions: 'Komponen diganti dan diuji' }, 'statusChanged');
    await mutateOrder(admin, id, 'p07-admin', { laborPrice: 75000 }, 'pricingUpdated');
    await mutateOrder(admin, id, 'p07-admin', { status: 'completed', completedAt: now() }, 'statusChanged', null);
    const parts = (await getDocs(query(collection(admin, `serviceOrders/${id}/partUsages`), limit(20)))).docs.map(d => ({ id: d.id, ...d.data() }));
    const partSubtotal = parts.reduce((sum, p) => sum + p.quantity * p.sellPrice, 0), grandTotal = 75000 + partSubtotal;
    const issue = writeBatch(admin);
    issue.set(doc(admin, `invoices/${id}`), { invoiceNo: `INV~${id}`, serviceOrderId: id, customerId: b.customerId,
      serviceName: b.serviceName, vehiclePlate: b.vehiclePlate, laborPrice: 75000, parts, partSubtotal, subtotal: grandTotal,
      discount: 0, fee: 0, grandTotal, paidAmount: 0, change: 0, due: grandTotal, method: 'none', status: 'unpaid',
      recordedBy: 'p07-admin', paidAt: null, createdAt: now(), updatedAt: now(), notes: 'Disahkan emulator', revision: 0, lastKey: 'issued' });
    issue.set(doc(admin, `invoices/${id}/payments/issued`), { key: 'issued', revision: 0, kind: 'issued', amount: 0, applied: 0, change: 0,
      method: 'none', notes: 'Disahkan emulator', recordedBy: 'p07-admin', paidAt: now() });
    await issue.commit();
    if (i > 0) await pay(admin, id, i === 1 ? 50000 : grandTotal);
    if (i === 3) {
      const refund = writeBatch(admin);
      refund.update(doc(admin, `invoices/${id}`), { status: 'refunded', due: 0, paidAmount: 0, method: 'cash', notes: 'Refund penuh emulator',
        recordedBy: 'p07-admin', updatedAt: now(), revision: 2, lastKey: 'p07-refund' });
      refund.set(doc(admin, `invoices/${id}/payments/p07-refund`), { key: 'p07-refund', revision: 2, kind: 'refund', amount: grandTotal,
        applied: -grandTotal, change: 0, method: 'cash', notes: 'Refund penuh emulator', recordedBy: 'p07-admin', paidAt: now() });
      await refund.commit();
    }
  }
  await ctx.trusted(db => updateDoc(doc(db, manifestPath), { state: 'complete' }));
  return validate(ctx);
}

async function pay(db, id, amount) {
  return runTransaction(db, async tx => {
    const ref = doc(db, `invoices/${id}`), old = (await tx.get(ref)).data();
    const applied = Math.min(amount, old.due), key = 'p07-payment';
    tx.update(ref, { revision: old.revision + 1, lastKey: key, paidAmount: old.paidAmount + applied,
      due: old.due - applied, change: amount - applied, status: applied === old.due ? 'paid' : 'partial',
      paidAt: applied === old.due ? now() : null, updatedAt: now(), recordedBy: 'p07-admin', method: 'cash', notes: 'Diterima emulator' });
    tx.set(doc(db, `invoices/${id}/payments/${key}`), { key, revision: old.revision + 1, kind: 'payment', amount, applied,
      change: amount - applied, method: 'cash', notes: 'Diterima emulator', recordedBy: 'p07-admin', paidAt: now() });
  });
}

async function validate(ctx) {
  return ctx.trusted(async db => {
    const manifest = (await getDoc(doc(db, manifestPath))).data();
    assert.equal(manifest?.state, 'complete');
    const records = new Map(); const counts = {};
    for (const p of manifest.paths) {
      const snap = await getDoc(doc(db, p)); assert.ok(snap.exists(), `Missing ${p}`);
      records.set(p, snap.data()); const c = p.split('/').at(-2); counts[c] = (counts[c] || 0) + 1;
    }
    for (const [p, d] of records) {
      if (p.startsWith('bookings/')) {
        const v = records.get(`vehicles/${d.vehicleId}`), s = records.get(`services/${d.serviceId}`), lock = records.get(`bookingSlots/${d.slotId}`);
        assert.equal(v.ownerId, d.customerId); assert.equal(v.name, d.vehicleName); assert.equal(s.name, d.serviceName);
        assert.equal(lock.bookingId, p.split('/')[1]); assert.equal(lock.active, ['pending', 'confirmed'].includes(d.status));
      }
      if (p.startsWith('spareparts/')) {
        const ledger = [...records].filter(([q, m]) => q.startsWith('stockMovements/') && m.sku === d.sku).map(([, m]) => m).sort((a,b) => a.stockRevision-b.stockRevision);
        let stock = 0;
        for (const m of ledger) { assert.equal(m.balanceBefore, stock); stock += m.delta; assert.equal(m.balanceAfter, stock); assert.ok(stock >= 0); }
        assert.equal(d.stock, stock); assert.equal(d.lowStock, stock <= d.minimumStock); assert.equal(d.stockRevision, ledger.length);
      }
      if (/^serviceOrders\/[^/]+$/.test(p)) {
        const b = records.get(`bookings/${d.bookingId}`); assert.equal(b.status, 'confirmed'); assert.equal(d.customerId, b.customerId);
        for (let r=0;r<=d.revision;r++) assert.ok(records.has(`${p}/events/${r}`));
        if (!['completed','cancelled'].includes(d.status)) assert.equal(records.get('technicians/p07-technician').currentOrderId, d.bookingId);
      }
      if (/\/partRequests\//.test(p)) {
        assert.equal(d.status, 'approved'); assert.equal(records.get(`stockMovements/${d.movementId}`).requestId, 'p07-request');
      }
      if (/\/partUsages\//.test(p)) {
        const m = records.get(`stockMovements/${d.movementId}`); assert.equal(m.quantity, d.quantity); assert.equal(m.sellPrice, d.sellPrice);
      }
      if (/^invoices\/[^/]+$/.test(p)) {
        const so = records.get(`serviceOrders/${d.serviceOrderId}`); assert.equal(so.status, 'completed');
        assert.equal(d.customerId, so.customerId); assert.equal(d.laborPrice, so.laborPrice);
        const lines = [...records].filter(([q]) => q.startsWith(`serviceOrders/${d.serviceOrderId}/partUsages/`)).map(([,u]) => u);
        assert.equal(d.parts.length, lines.length); assert.equal(d.partSubtotal, lines.reduce((n,u)=>n+u.quantity*u.sellPrice,0));
        for (const line of d.parts) {
          const usage = records.get(`serviceOrders/${d.serviceOrderId}/partUsages/${line.id}`);
          assert.ok(usage); const { id, ...snapshot } = line; assert.deepEqual(snapshot, usage);
        }
        assert.equal(d.grandTotal, d.laborPrice+d.partSubtotal-d.discount+d.fee);
        const events = [...records].filter(([q]) => q.startsWith(`${p}/payments/`)).map(([,e])=>e);
        assert.equal(d.paidAmount, events.reduce((n,e)=>n+e.applied,0)); assert.equal(d.revision, events.length-1);
        assert.equal(d.due, d.status==='refunded' ? 0 : d.grandTotal-d.paidAmount);
      }
    }
    return { projectId: PROJECT, authAccounts: 4, counts, paidRevenue: records.get('invoices/p07-b2').grandTotal };
  });
}

async function reset(ctx) {
  const manifest = await ctx.trusted(db => getDoc(doc(db, manifestPath)));
  if (!manifest.exists()) {
    fs.rmSync(credentialsPath, { force: true });
    return { deletedDocuments: 0, deletedAccounts: 0 };
  }
  const data = manifest.data();
  assert.deepEqual(data.authUids, accounts.map(a => a[0]));
  assert.ok(data.paths.every(p => /^(users\/p07-|technicians\/p07-|vehicles\/p07-|services\/p07-|spareparts\/P07_|stockMovements\/(p07-|Q~p07-)|bookings\/p07-|bookingSlots\/\d+$|serviceOrders\/p07-|invoices\/p07-)/.test(p)));
  await ctx.trusted(async db => { const batch = writeBatch(db); for (const p of data.paths) batch.delete(doc(db, p)); await batch.commit(); });
  const auth = await localRequest(`http://${ctx.config.auth}/identitytoolkit.googleapis.com/v1/projects/${PROJECT}/accounts:batchGet`, { headers: { Authorization: 'Bearer owner' } });
  const present = new Set((auth.users || []).map(u => u.localId));
  for (const localId of data.authUids.filter(uid => present.has(uid))) await localRequest(`http://${ctx.config.auth}/identitytoolkit.googleapis.com/v1/projects/${PROJECT}/accounts:delete`, {
    method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: 'Bearer owner' }, body: JSON.stringify({ localId }) });
  await ctx.trusted(db => { const b = writeBatch(db); b.delete(doc(db, manifestPath)); return b.commit(); });
  fs.rmSync(credentialsPath, { force: true });
  return { deletedDocuments: data.paths.length, deletedAccounts: data.authUids.length };
}

if (require.main === module) (async () => {
  const action = process.argv[2];
  if (!['seed','reset','validate'].includes(action)) throw new Error('Usage: node tools/test-data.cjs seed|reset|validate');
  const ctx = await context();
  try { console.log(JSON.stringify(await ({ seed, reset, validate }[action])(ctx), null, 2)); }
  finally { await ctx.close(); }
})().catch(e => { console.error(e.message); process.exitCode = 1; });

module.exports = { accounts, context, seed, reset, validate, credentialsPath, mutateOrder };

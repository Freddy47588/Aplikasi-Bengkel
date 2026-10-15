const { test } = require('node:test');
const assert = require('node:assert/strict');
const { initializeApp, deleteApp } = require('firebase/app');
const { getAuth, connectAuthEmulator, createUserWithEmailAndPassword, signInWithEmailAndPassword,
  signOut, sendEmailVerification, applyActionCode, reload, getIdToken,
  sendPasswordResetEmail, confirmPasswordReset } = require('firebase/auth');
const { getFirestore, connectFirestoreEmulator, doc, setDoc, getDoc, serverTimestamp, terminate } = require('firebase/firestore');

test('Auth Emulator: register, verify, logout/login from fresh client, persisted vehicle, forgot password', async () => {
  assert.ok(process.env.FIREBASE_AUTH_EMULATOR_HOST, 'Run only inside emulators:exec');
  assert.ok(process.env.FIRESTORE_EMULATOR_HOST, 'Run only inside emulators:exec');
  const apps = [];
  const databases = [];
  function client(suffix) {
    const app = initializeApp({ projectId: 'demo-bengkelku', apiKey: 'emulator-only' }, `auth-test-${suffix}`);
    apps.push(app);
    const auth = getAuth(app);
    connectAuthEmulator(auth, `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}`, { disableWarnings: true });
    const db = getFirestore(app);
    const [host, port] = process.env.FIRESTORE_EMULATOR_HOST.split(':');
    connectFirestoreEmulator(db, host, Number(port));
    databases.push(db);
    return { auth, db };
  }
  const email = `customer-${Date.now()}@example.test`;
  try {
    const first = client('first');
    const user = (await createUserWithEmailAndPassword(first.auth, email, 'emulator-password-123')).user;
    const uid = user.uid;
    await setDoc(doc(first.db, 'users', uid), { email, role: 'customer', active: true, createdAt: serverTimestamp() });
    const vehicle = { ownerId: uid, name: 'Honda', plate: 'B 1234 XYZ', active: true,
      createdAt: serverTimestamp(), updatedAt: serverTimestamp() };
    await assert.rejects(setDoc(doc(first.db, 'vehicles', uid), vehicle), e => e.code === 'permission-denied');
    await sendEmailVerification(user);
    let codes = await (await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/demo-bengkelku/oobCodes`)).json();
    const verification = codes.oobCodes.find(c => c.email === email && c.requestType === 'VERIFY_EMAIL');
    assert.ok(verification);
    await applyActionCode(first.auth, verification.oobCode);
    await reload(user); await getIdToken(user, true);
    assert.equal(user.emailVerified, true);
    await setDoc(doc(first.db, 'vehicles', uid), vehicle);
    await signOut(first.auth);
    const second = client('fresh');
    await signInWithEmailAndPassword(second.auth, email, 'emulator-password-123');
    assert.equal((await getDoc(doc(second.db, 'vehicles', uid))).data().name, 'Honda');
    await sendPasswordResetEmail(second.auth, email);
    codes = await (await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/demo-bengkelku/oobCodes`)).json();
    const reset = codes.oobCodes.find(c => c.email === email && c.requestType === 'PASSWORD_RESET');
    assert.ok(reset);
    await confirmPasswordReset(second.auth, reset.oobCode, 'new-emulator-password-456');
    await signOut(second.auth);
    await assert.rejects(signInWithEmailAndPassword(second.auth, email, 'emulator-password-123'));
    await signInWithEmailAndPassword(second.auth, email, 'new-emulator-password-456');
    assert.equal(second.auth.currentUser.uid, uid);
  } finally {
    await Promise.all(databases.map(db => terminate(db)));
    await Promise.all(apps.map(app => deleteApp(app)));
  }
});

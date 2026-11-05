const { test } = require('node:test');
const assert = require('node:assert/strict');
const { configuration, preflight } = require('../tools/emulator-safety.cjs');
const local = { GCLOUD_PROJECT: 'demo-bengkelku', FIREBASE_AUTH_EMULATOR_HOST: '127.0.0.1:9099', FIRESTORE_EMULATOR_HOST: 'localhost:8080' };

test('seed/reset fail closed for cloud project, absent or remote endpoints and conflicting project IDs', () => {
  for (const env of [{}, { ...local, GCLOUD_PROJECT: 'bengkelku-app-bebd9' },
    { ...local, FIREBASE_PROJECT_ID: 'other' }, { ...local, GOOGLE_CLOUD_PROJECT: 'other' },
    { ...local, FIREBASE_AUTH_EMULATOR_HOST: undefined },
    { ...local, FIRESTORE_EMULATOR_HOST: 'firestore.googleapis.com:443' },
    { ...local, FIRESTORE_EMULATOR_HOST: 'localhost:65536' },
    { ...local, FIREBASE_AUTH_EMULATOR_HOST: 'http://localhost:9099' },
    { ...local, FIREBASE_AUTH_EMULATOR_HOST: 'localhost:9099@evil.test' }]) {
    assert.throws(() => configuration(env));
  }
  assert.equal(configuration(local).projectId, 'demo-bengkelku');
});

test('unavailable emulator cannot fall back to production', async () => {
  await assert.rejects(preflight({ ...local, FIREBASE_AUTH_EMULATOR_HOST: '127.0.0.1:1' }));
});

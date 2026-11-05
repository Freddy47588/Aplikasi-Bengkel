const PROJECT = 'demo-bengkelku';

function endpoint(value) {
  if (!/^(127\.0\.0\.1|localhost):[1-9][0-9]{0,4}$/.test(value || '')) {
    throw new Error('Emulator endpoint must be an explicit loopback host:port');
  }
  const port = Number(value.split(':')[1]);
  if (port > 65535) throw new Error('Invalid emulator port');
  return value;
}

function configuration(env = process.env) {
  if (env.GCLOUD_PROJECT !== PROJECT ||
      [env.GOOGLE_CLOUD_PROJECT, env.FIREBASE_PROJECT_ID].some(v => v && v !== PROJECT)) {
    throw new Error(`Only GCLOUD_PROJECT=${PROJECT} is permitted`);
  }
  return { projectId: PROJECT, auth: endpoint(env.FIREBASE_AUTH_EMULATOR_HOST),
    firestore: endpoint(env.FIRESTORE_EMULATOR_HOST) };
}

async function localRequest(url, options = {}) {
  let response;
  try {
    response = await fetch(url, { ...options, redirect: 'error', signal: AbortSignal.timeout(30000) });
  } catch (error) {
    throw new Error(`Emulator request failed at ${new URL(url).pathname}: ${error.name}`, { cause: error });
  }
  if (!response.ok) throw new Error(`Emulator HTTP ${response.status} at ${new URL(url).pathname}`);
  return response.status === 204 ? {} : response.json();
}

async function preflight(env = process.env) {
  const config = configuration(env);
  // Auth's emulator-only API and Firestore's emulator-only owner token are checked before writes.
  await localRequest(`http://${config.auth}/emulator/v1/projects/${PROJECT}/config`);
  await localRequest(`http://${config.firestore}/v1/projects/${PROJECT}/databases/(default)/documents/_testManifests?pageSize=1`, {
    headers: { Authorization: 'Bearer owner' },
  });
  return config;
}

module.exports = { PROJECT, endpoint, configuration, localRequest, preflight };

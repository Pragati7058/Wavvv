const admin = require('firebase-admin');
const config = require('./env');

let isMockFirebase = false;

// Check if credentials are mock/default
const hasMockKey = !config.firebase.privateKey || 
                   config.firebase.privateKey.includes('MOCKKEY') || 
                   config.firebase.projectId === 'wavvv-firebase-mock';

if (hasMockKey) {
  console.warn('⚠️ WARNING: Firebase configuration is missing or using mock values. Falling back to MOCK Firebase Auth Mode.');
  isMockFirebase = true;
} else {
  try {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: config.firebase.projectId,
        privateKey: config.firebase.privateKey,
        clientEmail: config.firebase.clientEmail,
      }),
    });
    console.log('✅ Firebase Admin SDK initialized successfully.');
  } catch (error) {
    console.error('❌ Failed to initialize Firebase Admin SDK. Falling back to MOCK mode:', error.message);
    isMockFirebase = true;
  }
}

/**
 * Verifies a Firebase ID token.
 * In mock mode, accepts tokens starting with "mock_" (e.g., "mock_uid_username")
 */
const verifyFirebaseToken = async (idToken) => {
  if (isMockFirebase) {
    if (!idToken || !idToken.startsWith('mock_')) {
      throw new Error('Firebase Auth running in mock mode. Token must start with "mock_" (e.g., "mock_uid123_john")');
    }
    const parts = idToken.split('_');
    const uid = parts[1] || 'mock-uid';
    const username = parts[2] || 'MockGuest';
    return {
      uid,
      name: username,
      email: `${username.toLowerCase()}@wavvv-mock.local`,
      firebase: { sign_in_provider: 'anonymous' },
      isAnonymous: true,
    };
  }

  return admin.auth().verifyIdToken(idToken);
};

module.exports = {
  admin: isMockFirebase ? null : admin,
  isMockFirebase,
  verifyFirebaseToken,
};

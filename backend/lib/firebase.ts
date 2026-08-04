import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

/// Lazily initializes the Firebase Admin SDK from the service account JSON
/// stored in the FIREBASE_SERVICE_ACCOUNT environment variable (the whole
/// file's contents, pasted as one line — see backend/README.md). Reused
/// across warm serverless invocations via getApps().
///
/// Always go through this function (via db()/auth() below) rather than
/// calling getFirestore()/getAuth() with no arguments — those resolve
/// against the SDK's default app, which is never initialized unless
/// something has already called initializeApp() on it.
function adminApp() {
  if (getApps().length > 0) return getApps()[0];

  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!raw) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT environment variable is not set');
  }
  const serviceAccount = JSON.parse(raw);
  return initializeApp({ credential: cert(serviceAccount) });
}

export function db() {
  return getFirestore(adminApp());
}

export function auth() {
  return getAuth(adminApp());
}

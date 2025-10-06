// functions/src/ambassadors.ts
import * as admin from 'firebase-admin';
// 👇 Fuerza a v1 (no v2)
import * as functions from 'firebase-functions/v1';

admin.initializeApp();

async function assertIsAdmin(ctx: functions.https.CallableContext) {
  if (!ctx.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Inicia sesión.');
  }
  const uid = ctx.auth.uid;

  // 1) custom claims
  const user = await admin.auth().getUser(uid);
  const claims = (user.customClaims || {}) as Record<string, unknown>;
  if (claims['admin'] === true) return;

  // 2) respaldo: colección admins/{uid} con role: owner|admin
  const snap = await admin.firestore().collection('admins').doc(uid).get();
  const role = (snap.data()?.role || '').toString().toLowerCase();
  if (role === 'owner' || role === 'admin') return;

  throw new functions.https.HttpsError(
    'permission-denied',
    'Solo administradores pueden crear usuarios.'
  );
}

/** Crea un usuario en Auth (email+password). NO toca Firestore */
export const createAuthUser = functions
  .region('us-central1')
  .https.onCall(async (data: any, context: functions.https.CallableContext) => {
    await assertIsAdmin(context);

    const email = (data?.email || '').toString().trim();
    const password = (data?.password || '').toString();

    if (!email || !password) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'email y password son requeridos.'
      );
    }

    try {
      const user = await admin.auth().createUser({
        email,
        password,
        emailVerified: false,
        disabled: false,
      });
      return { ok: true, uid: user.uid };
    } catch (err: any) {
      if (err?.code === 'auth/email-already-exists') {
        throw new functions.https.HttpsError('already-exists', 'El correo ya está registrado.');
      }
      throw new functions.https.HttpsError('internal', err?.message || 'Error interno.');
    }
  });

/** (Opcional) Marcar admin por correo (una sola vez para tu cuenta) */
export const setAdminByEmail = functions
  .region('us-central1')
  .https.onCall(async (data: any, context: functions.https.CallableContext) => {
    await assertIsAdmin(context);

    const email = (data?.email || '').toString().trim();
    if (!email) {
      throw new functions.https.HttpsError('invalid-argument', 'email requerido.');
    }

    const user = await admin.auth().getUserByEmail(email);
    await admin.auth().setCustomUserClaims(user.uid, { admin: true });
    await admin.firestore().collection('admins').doc(user.uid).set(
      {
        email,
        role: 'owner',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return { ok: true, uid: user.uid };
  });

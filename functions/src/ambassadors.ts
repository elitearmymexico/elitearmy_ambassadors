import { onCall, HttpsError } from "firebase-functions/v2/https";
import { setGlobalOptions, logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

// todas las funciones en us-central1
setGlobalOptions({ region: "us-central1", maxInstances: 10 });

async function assertIsAdmin(uid: string) {
  if (!uid) throw new HttpsError("unauthenticated", "No autenticado.");
  // Admin SDK ignora reglas, perfecto para backend
  const snap = await admin.firestore().doc(`admins/${uid}`).get();
  const role = (snap.data()?.role || "").toString().toLowerCase();
  if (!(role === "owner" || role === "admin")) {
    throw new HttpsError(
      "permission-denied",
      "No tienes rol de administrador."
    );
  }
}

/**
 * Crea usuario en Auth y su ficha en ambassadors_master (ID = UID).
 * data: { email: string, password: string }
 */
export const adminCreateUser = onCall(async (request) => {
  try {
    const authCtx = request.auth;
    if (!authCtx) throw new HttpsError("unauthenticated", "No autenticado.");
    await assertIsAdmin(authCtx.uid);

    const email = String(request.data?.email || "").trim().toLowerCase();
    const password = String(request.data?.password || "");
    if (!email || !password) {
      throw new HttpsError(
        "invalid-argument",
        "Faltan email o contraseña."
      );
    }

    // crear (o recuperar) usuario
    let userRecord: admin.auth.UserRecord;
    try {
      userRecord = await admin.auth().createUser({ email, password });
    } catch (e: any) {
      // si ya existe, lo obtenemos para continuar
      if (e?.code === "auth/email-already-exists") {
        userRecord = await admin.auth().getUserByEmail(email);
      } else {
        logger.error("createUser error", e);
        throw new HttpsError("internal", "No se pudo crear el usuario.");
      }
    }

    const uid = userRecord.uid;
    const now = admin.firestore.FieldValue.serverTimestamp();

    // upsert de la ficha
    await admin.firestore().doc(`ambassadors_master/${uid}`).set(
      {
        email,
        status: "active",
        activo: true,
        createdAt: now,
        statusUpdatedAt: now,
      },
      { merge: true }
    );

    return { ok: true, uid };
  } catch (e: any) {
    if (e instanceof HttpsError) throw e;
    logger.error("adminCreateUser fatal", e);
    throw new HttpsError("internal", "internal");
  }
});

/**
 * Activa embajador por email: crea/actualiza su ficha en ambassadors_master.
 * data: { email: string }
 */
export const adminActivateByEmail = onCall(async (request) => {
  try {
    const authCtx = request.auth;
    if (!authCtx) throw new HttpsError("unauthenticated", "No autenticado.");
    await assertIsAdmin(authCtx.uid);

    const email = String(request.data?.email || "").trim().toLowerCase();
    if (!email) {
      throw new HttpsError("invalid-argument", "Email requerido.");
    }

    const user = await admin.auth().getUserByEmail(email);
    const uid = user.uid;
    const now = admin.firestore.FieldValue.serverTimestamp();

    await admin.firestore().doc(`ambassadors_master/${uid}`).set(
      {
        email,
        status: "active",
        activo: true,
        statusUpdatedAt: now,
      },
      { merge: true }
    );

    return { ok: true, uid };
  } catch (e: any) {
    if (e instanceof HttpsError) throw e;
    if (e?.code === "auth/user-not-found") {
      throw new HttpsError(
        "not-found",
        "Ese correo no existe en Auth. Crea primero la cuenta."
      );
    }
    logger.error("adminActivateByEmail fatal", e);
    throw new HttpsError("internal", "internal");
  }
});

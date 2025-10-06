import * as admin from "firebase-admin";
import { onCall } from "firebase-functions/v2/https";

if (!admin.apps.length) admin.initializeApp();

/**
 * Callable temporal para asignar admin:true a un usuario por email.
 * request.data: { email: string }
 */
export const setAdminByEmail = onCall(async (request) => {
  const email = String(request.data?.email || "").toLowerCase();
  if (!email) throw new Error("email requerido");

  const user = await admin.auth().getUserByEmail(email);
  await admin.auth().setCustomUserClaims(user.uid, { admin: true });

  return { ok: true, message: `${email} ahora es admin ✅` };
});

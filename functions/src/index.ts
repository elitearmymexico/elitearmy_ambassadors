import { onCall, HttpsError, CallableRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";

// Node 18+ ya trae fetch global
admin.initializeApp();

// ===== BOOTSTRAP (quítalo cuando ya todo esté estable) =====
const BOOTSTRAP_UIDS = new Set<string>([
  "csCbERFrqEhhs6dr1kyzSOXOUsM2",
]);

// ───────── Utils ─────────
function assertIsAdmin(req: CallableRequest<any>) {
  const auth = req.auth;
  const isAdmin = auth?.token?.admin === true;
  const isBootstrap = auth?.uid && BOOTSTRAP_UIDS.has(auth.uid);
  if (!isAdmin && !isBootstrap) {
    throw new HttpsError("permission-denied", "No tienes rol de administrador.");
  }
}

function codeEA() {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let s = "";
  for (let i = 0; i < 6; i++) s += chars[Math.floor(Math.random() * chars.length)];
  return `EA-${s}`;
}

// === Helper: llamar CrossHero por email con logs
async function fetchCrossheroByEmail(email: string): Promise<null | {
  id?: string;
  name?: string;
  phone?: string;
  status?: string;
}> {
  const BOX = process.env.CROSSHERO_BOX;
  const TOKEN = process.env.CROSSHERO_ACCESS_TOKEN;

  if (!BOX || !TOKEN) {
    console.error("CrossHero secrets faltantes. CROSSHERO_BOX/CROSSHERO_ACCESS_TOKEN no disponibles.");
    return null;
  }

  const url = `https://crosshero.com/api/v1/athletes?email=${encodeURIComponent(email)}&page=1&per_page=1`;
  const res = await fetch(url, {
    method: "GET",
    headers: {
      "CROSSHERO_BOX": BOX,
      "CROSSHERO_ACCESS_TOKEN": TOKEN,
    },
  });

  const text = await res.text();
  console.log("CrossHero GET /athletes", res.status, text.substring(0, 500));

  if (!res.ok) {
    // 401/403/404/etc.
    return null;
  }

  // La colección de Postman usa campo "athletes"; hacemos parse tolerante
  let data: any;
  try {
    data = JSON.parse(text);
  } catch (e) {
    console.error("JSON inválido de CrossHero:", e);
    return null;
  }

  const list = data?.athletes ?? data?.data ?? data ?? [];
  const first = Array.isArray(list) ? list[0] : null;
  if (!first) return null;

  return {
    id: first.id ?? first._id ?? first.uuid ?? undefined,
    name: first.name ?? first.nombre ?? first.fullname ?? undefined,
    phone: first.phone ?? first.telefono ?? undefined,
    status: first.status ?? undefined,
  };
}

// ───────── setAdmin (permite bootstrap) ─────────
export const setAdmin = onCall(
  { region: "us-central1" },
  async (req) => {
    const { uid, admin: valueRaw } = (req.data || {}) as { uid?: string; admin?: boolean };

    const callerUid = req.auth?.uid || null;
    const isAdmin = req.auth?.token?.admin === true;
    const isBootstrapCaller = callerUid ? BOOTSTRAP_UIDS.has(callerUid) : false;
    const isBootstrapTarget = uid ? BOOTSTRAP_UIDS.has(uid) : false;

    if (!isAdmin && !isBootstrapCaller && !isBootstrapTarget) {
      throw new HttpsError("permission-denied", "No tienes rol de administrador (setAdmin bootstrap).");
    }
    if (!uid) throw new HttpsError("invalid-argument", "Falta uid");

    const value = valueRaw === false ? false : true;
    await admin.auth().setCustomUserClaims(uid, { admin: value });
    return { ok: true, uid, admin: value };
  }
);

// ───────── adminCreateAmbassador ─────────
// IMPORTANTE: declaramos secrets aquí
export const adminCreateAmbassador = onCall(
  { region: "us-central1", secrets: ["CROSSHERO_BOX", "CROSSHERO_ACCESS_TOKEN"] },
  async (req) => {
    assertIsAdmin(req);
    const { email, password, nombre, phone } = (req.data || {}) as {
      email?: string; password?: string; nombre?: string; phone?: string;
    };

    const emailNorm = (email || "").toLowerCase().trim();
    const pass = (password || "").toString();
    if (!emailNorm || !pass) {
      throw new HttpsError("invalid-argument", "email y password son obligatorios");
    }

    // 1) Auth
    let user;
    try {
      user = await admin.auth().getUserByEmail(emailNorm);
    } catch {
      user = await admin.auth().createUser({
        email: emailNorm,
        password: pass,
        displayName: nombre || undefined,
        phoneNumber: phone || undefined,
        emailVerified: true,
        disabled: false,
      });
    }

    // 2) CrossHero (intento)
    const ch = await fetchCrossheroByEmail(emailNorm);
    const chName = ch?.name?.toString().trim();
    const chPhone = ch?.phone?.toString().trim();

    // 3) Ficha
    const now = admin.firestore.Timestamp.now();
    const docRef = admin.firestore().collection("ambassadors_master").doc(emailNorm);
    const code = codeEA();

    await docRef.set({
      email: emailNorm,
      nombre: chName || nombre || user.displayName || "",
      phone: chPhone || phone || user.phoneNumber || "",
      crossheroId: ch?.id || null,
      crossheroActive: ch?.status ? String(ch.status).toLowerCase() === "active" : null,
      code,
      activo: true,                 // ← ahora ya queda activo en un paso
      status: "active",
      since: now.toDate().toISOString(),
      createdAt: now,
      updatedAt: now,
      lastSyncAt: now,
    }, { merge: true });

    return {
      ok: true,
      uid: user.uid,
      email: emailNorm,
      code,
      // Campo de depuración temporal (puedes quitarlo luego)
      _debug: { crossheroFound: !!ch, chSample: ch || null },
    };
  }
);

// ───────── adminActivateAmbassador (opcional si conservas el botón viejo) ─────────
export const adminActivateAmbassador = onCall(
  { region: "us-central1", secrets: ["CROSSHERO_BOX", "CROSSHERO_ACCESS_TOKEN"] },
  async (req) => {
    assertIsAdmin(req);
    const { email, nombre, phone } = (req.data || {}) as {
      email?: string; nombre?: string; phone?: string;
    };

    const emailNorm = (email || "").toLowerCase().trim();
    if (!emailNorm) throw new HttpsError("invalid-argument", "email es obligatorio");

    let user;
    try {
      user = await admin.auth().getUserByEmail(emailNorm);
    } catch {
      user = await admin.auth().createUser({
        email: emailNorm,
        displayName: nombre || undefined,
        phoneNumber: phone || undefined,
        emailVerified: true,
        disabled: false,
      });
    }

    const ch = await fetchCrossheroByEmail(emailNorm);
    const chName = ch?.name?.toString().trim();
    const chPhone = ch?.phone?.toString().trim();

    const now = admin.firestore.Timestamp.now();
    const docRef = admin.firestore().collection("ambassadors_master").doc(emailNorm);
    const snap = await docRef.get();
    const existing = snap.exists ? snap.data() : {};
    const code = (existing && (existing as any).code) || codeEA();

    await docRef.set({
      email: emailNorm,
      nombre: chName || nombre || (existing as any)?.nombre || user.displayName || "",
      phone: chPhone || phone || (existing as any)?.phone || user.phoneNumber || "",
      crossheroId: ch?.id || (existing as any)?.crossheroId || null,
      crossheroActive: ch?.status ? String(ch.status).toLowerCase() === "active" : (existing as any)?.crossheroActive ?? null,
      code,
      activo: true,
      status: "active",
      statusUpdatedAt: now.toDate().toISOString(),
      since: (existing as any)?.since || now.toDate().toISOString(),
      updatedAt: now,
      lastSyncAt: now,
    }, { merge: true });

    return { ok: true, uid: user.uid, email: emailNorm, code, _debug: { crossheroFound: !!ch, chSample: ch || null } };
  }
);

// ───────── (opcional) Sync diario si tienes plan Blaze ─────────
export const syncAmbassadorsFromCrosshero = onSchedule(
  { region: "us-central1", schedule: "every day 03:00", secrets: ["CROSSHERO_BOX", "CROSSHERO_ACCESS_TOKEN"] },
  async () => {
    // aquí podrías consultar a CrossHero por lotes y poner activo/inactivo; omitido por brevedad
    console.log("syncAmbassadorsFromCrosshero running…");
  }
);

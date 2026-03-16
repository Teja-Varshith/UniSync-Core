import { initializeApp, cert, getApps } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import fs from "fs";
import path from "path";

function parseServiceAccountFromString(raw) {
  const parsed = JSON.parse(raw);
  if (parsed.private_key) {
    parsed.private_key = String(parsed.private_key).replace(/\\n/g, "\n");
  }
  return parsed;
}

function parseServiceAccount() {
  const rawJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  const rawBase64 = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;
  const rawFilePath =
    process.env.FIREBASE_SERVICE_ACCOUNT_FILE ||
    process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const defaultFileCandidates = [
    path.join(process.cwd(), "firebase-service-account.json"),
    path.join(process.cwd(), "serviceAccountKey.json"),
    path.join(process.cwd(), "configs", "firebase-service-account.json"),
  ];

  if (rawJson) {
    return parseServiceAccountFromString(rawJson);
  }

  if (rawBase64) {
    const decoded = Buffer.from(rawBase64, "base64").toString("utf8");
    return parseServiceAccountFromString(decoded);
  }

  if (rawFilePath) {
    const fileContent = fs.readFileSync(rawFilePath, "utf8");
    return parseServiceAccountFromString(fileContent);
  }

  for (const filePath of defaultFileCandidates) {
    if (fs.existsSync(filePath)) {
      const fileContent = fs.readFileSync(filePath, "utf8");
      return parseServiceAccountFromString(fileContent);
    }
  }

  throw new Error(
    "Firebase admin credentials missing. Set FIREBASE_SERVICE_ACCOUNT_JSON, FIREBASE_SERVICE_ACCOUNT_BASE64, FIREBASE_SERVICE_ACCOUNT_FILE, GOOGLE_APPLICATION_CREDENTIALS, or place firebase-service-account.json in backend root."
  );
}

let dbInstance;

export function getFirebaseDb() {
  if (dbInstance) return dbInstance;

  if (getApps().length === 0) {
    const serviceAccount = parseServiceAccount();
    initializeApp({
      credential: cert(serviceAccount),
    });
  }

  dbInstance = getFirestore();
  return dbInstance;
}

export async function spendUserCoins({ uid, amount, reason = "interview_start" }) {
  if (!uid) {
    throw new Error("Missing uid for coin transaction.");
  }

  const debit = Number(amount || 0);
  if (!Number.isFinite(debit) || debit < 0) {
    throw new Error("Invalid coin amount.");
  }

  if (debit === 0) {
    const db = getFirebaseDb();
    const snap = await db.collection("users").doc(uid).get();
    const coins = Number(snap.data()?.coins ?? 0);
    return { success: true, remainingCoins: coins };
  }

  const db = getFirebaseDb();
  const userRef = db.collection("users").doc(uid);

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(userRef);
    if (!snap.exists) {
      throw new Error("User wallet not found.");
    }

    const currentCoins = Number(snap.data()?.coins ?? 0);
    if (!Number.isFinite(currentCoins) || currentCoins < debit) {
      const err = new Error("Insufficient coins.");
      err.code = "INSUFFICIENT_COINS";
      throw err;
    }

    const remainingCoins = currentCoins - debit;

    tx.update(userRef, {
      coins: remainingCoins,
      updatedAt: FieldValue.serverTimestamp(),
      lastCoinSpendReason: reason,
    });

    return { success: true, remainingCoins };
  });
}
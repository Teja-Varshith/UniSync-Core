import express from "express";
import { getAuth } from "firebase-admin/auth";
import { getMessaging } from "firebase-admin/messaging";
import { getFirebaseDb } from "../services/firebaseAdmin.js";

export const adminNotificationRouter = express.Router();

const BROADCAST_TOPIC = "all_users";

/**
 * Verifies the caller is a signed-in super user.
 *
 * FCM sending lives here rather than in the app for one reason: the only way
 * for a client to push notifications directly is to ship a server key inside
 * the APK, which anyone can extract and then use to spam every user. The
 * service account stays on the server; the app authenticates as itself and
 * the server decides whether it is allowed to send.
 *
 * Two checks, both required:
 *  1. The Firebase ID token is valid (proves who the caller is).
 *  2. That identity is on the app_config/access allowlist (proves they may).
 */
async function requireSuperUser(req, res, next) {
  try {
    const header = req.headers.authorization || "";
    const token = header.startsWith("Bearer ") ? header.slice(7).trim() : "";

    if (!token) {
      return res.status(401).json({ ok: false, error: "Missing ID token" });
    }

    // Initialise firebase-admin *before* touching getAuth().
    //
    // initializeApp() only runs inside getFirebaseDb(). On a cold start —
    // which on Render's free tier is most requests — nothing has called it
    // yet, so getAuth() throws "The default Firebase app does not exist"
    // and, caught below, surfaces as a misleading "Invalid ID token".
    //
    // Kept in its own try so a missing service account reports itself as a
    // server problem rather than being blamed on the caller's token.
    let db;
    try {
      db = getFirebaseDb();
    } catch (initError) {
      console.error("[adminNotifications] firebase-admin init failed:", initError);
      return res.status(500).json({
        ok: false,
        error: "Server: firebase-admin could not start (service account?)",
      });
    }

    const decoded = await getAuth().verifyIdToken(token);

    const snap = await db.collection("app_config").doc("access").get();
    const data = snap.data() || {};

    const uids = Array.isArray(data.uids) ? data.uids : [];
    const emails = (Array.isArray(data.emails) ? data.emails : []).map((e) =>
      String(e).trim().toLowerCase()
    );

    const email = String(decoded.email || "").trim().toLowerCase();
    const allowed = uids.includes(decoded.uid) || (email && emails.includes(email));

    if (!allowed) {
      return res.status(403).json({ ok: false, error: "Not a super user" });
    }

    req.admin = { uid: decoded.uid, email };
    return next();
  } catch (error) {
    console.error("[adminNotifications] auth failed:", error);

    // Distinguish the three very different things that land here, because
    // "Invalid ID token" sent back for all of them is unactionable.
    const code = error.code || "";
    const message = error.message || "";

    // Server misconfiguration, not a bad token.
    if (message.includes("default Firebase app does not exist")) {
      return res.status(500).json({
        ok: false,
        error: "Server: firebase-admin is not initialised",
      });
    }

    // The service account belongs to a different Firebase project than the
    // app that minted the token, so every token looks forged.
    if (message.includes("incorrect \"aud\"") || message.includes("audience")) {
      return res.status(500).json({
        ok: false,
        error:
          "Server: service account project does not match the app's Firebase project",
      });
    }

    if (code === "auth/id-token-expired") {
      return res
        .status(401)
        .json({ ok: false, error: "Session expired — reopen the panel" });
    }

    return res.status(401).json({
      ok: false,
      error: `Token rejected: ${code || message || "unknown"}`,
    });
  }
}

/**
 * POST /api/admin/notifications/send
 *
 * Body: { title, body, target: "all" | "token" | "uid", token?, uid?, data? }
 */
adminNotificationRouter.post("/send", requireSuperUser, async (req, res) => {
  const { title, body, target = "all", token, uid, data } = req.body || {};

  if (!title || !body) {
    return res
      .status(400)
      .json({ ok: false, error: "title and body are required" });
  }

  const notification = { title: String(title), body: String(body) };
  // FCM requires every data value to be a string.
  const payloadData = Object.fromEntries(
    Object.entries(data || {}).map(([k, v]) => [k, String(v)])
  );

  try {
    const messaging = getMessaging();

    if (target === "all") {
      const id = await messaging.send({
        topic: BROADCAST_TOPIC,
        notification,
        data: payloadData,
      });
      return res.json({
        ok: true,
        target: "all",
        topic: BROADCAST_TOPIC,
        messageId: id,
      });
    }

    let deviceToken = token;

    // Sending by uid is the safer habit: tokens rotate, so an admin pasting
    // a token they saved yesterday may be addressing a device that no longer
    // exists. Looking it up by uid always gets the current one.
    if (target === "uid") {
      if (!uid) {
        return res
          .status(400)
          .json({ ok: false, error: "uid is required when target is 'uid'" });
      }
      const db = getFirebaseDb();
      const snap = await db.collection("users").doc(String(uid)).get();
      deviceToken = snap.data()?.fcmToken;
      if (!deviceToken) {
        return res
          .status(404)
          .json({ ok: false, error: "That user has no FCM token stored" });
      }
    }

    if (!deviceToken) {
      return res
        .status(400)
        .json({ ok: false, error: "token is required when target is 'token'" });
    }

    const id = await messaging.send({
      token: String(deviceToken),
      notification,
      data: payloadData,
    });

    return res.json({ ok: true, target, messageId: id });
  } catch (error) {
    console.error("[adminNotifications] send failed:", error);

    // A stale token is the common case and deserves a clearer message than
    // the raw SDK error.
    const unregistered =
      error.code === "messaging/registration-token-not-registered";

    return res.status(unregistered ? 410 : 500).json({
      ok: false,
      error: unregistered
        ? "That device token is no longer registered"
        : error.message || "Send failed",
    });
  }
});

export default adminNotificationRouter;

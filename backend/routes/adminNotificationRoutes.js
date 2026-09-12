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

    const decoded = await getAuth().verifyIdToken(token);

    const db = getFirebaseDb();
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
    console.error("[adminNotifications] auth failed:", error.message);
    return res.status(401).json({ ok: false, error: "Invalid ID token" });
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

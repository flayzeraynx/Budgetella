/**
 * Google Play Billing — Cloud Functions
 *
 * Owns the **server-side** half of the Android paywall:
 *   1. `playRtdnHandler` — Pub/Sub-triggered handler for Real-time Developer
 *      Notifications. Validates every event against the Play Developer API
 *      (`androidpublisher` v3) and writes the authoritative entitlement to
 *      Firestore `users/{uid}`.
 *   2. `verifyPlayPurchase`  — HTTPS endpoint the Android app can call right
 *      after a local purchase if it needs a synchronous server confirmation.
 *      Today the client already writes optimistically; this is here for
 *      defence in depth and for restore flows.
 *
 * Schema written to Firestore is identical to the Stripe webhook output so
 * iOS and web read the same `users/{uid}` shape regardless of platform:
 *   isPremium, subscriptionType, subscriptionId (purchaseToken),
 *   subscriptionStatus, subscriptionEndDate, subscriptionPlatform.
 *
 * Setup (one-time, Ozzy will do this in Play Console):
 *   1. Play Console → Monetisation setup → Real-time developer notifications.
 *      Set the Cloud Pub/Sub topic to `play-rtdn`. Push notifications enabled.
 *   2. Google Cloud → IAM → grant the Play service-publisher account
 *      `Pub/Sub Publisher` on the topic.
 *   3. Play Console → Setup → API access → link this GCP project. Grant the
 *      Firebase Admin SDK service account "View financial data" + "Manage
 *      orders and subscriptions" permissions. (Application Default Credentials
 *      from the Functions runtime then auth against `androidpublisher`.)
 *   4. Deploy: `firebase deploy --only functions:playRtdnHandler,functions:verifyPlayPurchase`
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { google } = require("googleapis");

const logger = functions.logger;

const PACKAGE_NAME = "com.budgetella.app";

/** Canonical Android product IDs (kept in sync with `BillingProducts.kt`). */
const PRODUCT_IDS = {
  MONTHLY: "premium_monthly",
  ANNUALLY: "premium_annually",
  LIFETIME: "premium_lifetime",
};

/** Android product ID → canonical Firestore `subscriptionType` value. */
const TIER_BY_PRODUCT_ID = {
  [PRODUCT_IDS.MONTHLY]: "monthly",
  [PRODUCT_IDS.ANNUALLY]: "yearly",
  [PRODUCT_IDS.LIFETIME]: "lifetime",
};

/**
 * Google Play RTDN notification types — values come from
 * `subscriptionNotification.notificationType` in the Pub/Sub payload.
 * Reference: https://developer.android.com/google/play/billing/rtdn-reference
 */
const SUBSCRIPTION_NOTIFICATION = {
  RECOVERED: 1,
  RENEWED: 2,
  CANCELED: 3,
  PURCHASED: 4,
  ON_HOLD: 5,
  IN_GRACE_PERIOD: 6,
  RESTARTED: 7,
  PRICE_CHANGE_CONFIRMED: 8,
  DEFERRED: 9,
  PAUSED: 10,
  PAUSE_SCHEDULE_CHANGED: 11,
  REVOKED: 12,
  EXPIRED: 13,
};

const ONE_TIME_NOTIFICATION = {
  PURCHASED: 1,
  CANCELED: 2,
};

// ── Play Developer API client ──────────────────────────────────────────────

let cachedPublisher = null;
async function getPlayPublisher() {
  if (cachedPublisher) return cachedPublisher;
  const auth = new google.auth.GoogleAuth({
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  cachedPublisher = google.androidpublisher({ version: "v3", auth });
  return cachedPublisher;
}

// ── Pub/Sub handler ────────────────────────────────────────────────────────

/**
 * Triggered by every Play RTDN event. Pub/Sub data is a base64-encoded JSON
 * payload — see the linked reference for the schema.
 *
 * Pub/Sub topic name is configurable via `play.rtdn_topic` config; falls back
 * to `play-rtdn`.
 */
exports.playRtdnHandler = functions
  .pubsub.topic(
    functions.config().play?.rtdn_topic || "play-rtdn"
  )
  .onPublish(async (message) => {
    let payload;
    try {
      payload = JSON.parse(
        Buffer.from(message.data, "base64").toString("utf8")
      );
    } catch (err) {
      logger.error("RTDN payload not JSON-decodable", err);
      return null;
    }

    if (payload.testNotification) {
      logger.info(
        "RTDN test notification received",
        payload.testNotification
      );
      return null;
    }

    if (payload.subscriptionNotification) {
      await handleSubscriptionNotification(payload.subscriptionNotification);
    } else if (payload.oneTimeProductNotification) {
      await handleOneTimeNotification(payload.oneTimeProductNotification);
    } else {
      logger.info("RTDN payload with no actionable section", payload);
    }
    return null;
  });

async function handleSubscriptionNotification(note) {
  const { purchaseToken, subscriptionId, notificationType } = note;
  if (!purchaseToken || !subscriptionId) {
    logger.warn("Subscription notification missing fields", note);
    return;
  }

  const publisher = await getPlayPublisher();
  let purchase;
  try {
    const response = await publisher.purchases.subscriptionsv2.get({
      packageName: PACKAGE_NAME,
      token: purchaseToken,
    });
    purchase = response.data;
  } catch (err) {
    logger.error(
      "purchases.subscriptionsv2.get failed",
      { subscriptionId, notificationType, err: err.message }
    );
    return;
  }

  const uid = extractUid(purchase);
  if (!uid) {
    logger.warn(
      "Subscription notification with no obfuscatedExternalAccountId — cannot resolve user",
      { subscriptionId, notificationType }
    );
    return;
  }

  const tier = TIER_BY_PRODUCT_ID[subscriptionId];
  if (!tier) {
    logger.warn("Unknown subscription productId from RTDN", subscriptionId);
    return;
  }

  // `subscriptionState` is authoritative (SUBSCRIPTION_STATE_ACTIVE, _CANCELED,
  // _IN_GRACE_PERIOD, _ON_HOLD, _PAUSED, _EXPIRED).
  const state = purchase.subscriptionState || "";
  const isActive =
    state === "SUBSCRIPTION_STATE_ACTIVE" ||
    state === "SUBSCRIPTION_STATE_IN_GRACE_PERIOD" ||
    state === "SUBSCRIPTION_STATE_CANCELED";

  // Each line item carries its own expiry; for the typical single-line plan
  // the first entry is the one we want.
  const lineItem = purchase.lineItems && purchase.lineItems[0];
  const expiryIso = lineItem && lineItem.expiryTime;
  const expiry = expiryIso ? new Date(expiryIso) : null;

  const statusLabel = labelForSubscriptionState(state, notificationType);

  const updates = {
    isPremium: isActive && (!expiry || expiry.getTime() >= Date.now()),
    subscriptionType: tier,
    subscriptionId: purchaseToken,
    subscriptionStatus: statusLabel,
    subscriptionEndDate: expiry
      ? admin.firestore.Timestamp.fromDate(expiry)
      : null,
    subscriptionPlatform: "android",
    subscriptionProductId: subscriptionId,
    subscriptionUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  // Hard kill switch — revoked / expired wipes premium so the user loses access
  // immediately.
  if (
    notificationType === SUBSCRIPTION_NOTIFICATION.REVOKED ||
    notificationType === SUBSCRIPTION_NOTIFICATION.EXPIRED
  ) {
    updates.isPremium = false;
    updates.subscriptionStatus = "expired";
  }

  await admin.firestore()
    .collection("users")
    .doc(uid)
    .set(updates, { merge: true });

  logger.info(
    "RTDN subscription reconciled",
    { uid, subscriptionId, notificationType, statusLabel }
  );
}

async function handleOneTimeNotification(note) {
  const { purchaseToken, sku, notificationType } = note;
  if (!purchaseToken || !sku) {
    logger.warn("One-time notification missing fields", note);
    return;
  }

  const publisher = await getPlayPublisher();
  let purchase;
  try {
    const response = await publisher.purchases.products.get({
      packageName: PACKAGE_NAME,
      productId: sku,
      token: purchaseToken,
    });
    purchase = response.data;
  } catch (err) {
    logger.error(
      "purchases.products.get failed",
      { sku, notificationType, err: err.message }
    );
    return;
  }

  const uid = extractUid(purchase);
  if (!uid) {
    logger.warn(
      "One-time notification without obfuscatedExternalAccountId",
      { sku, notificationType }
    );
    return;
  }

  const tier = TIER_BY_PRODUCT_ID[sku];
  if (!tier) {
    logger.warn("Unknown one-time productId from RTDN", sku);
    return;
  }

  // purchaseState: 0 = purchased, 1 = canceled, 2 = pending.
  const isPurchased = purchase.purchaseState === 0;
  const isCanceled =
    purchase.purchaseState === 1 ||
    notificationType === ONE_TIME_NOTIFICATION.CANCELED;

  const updates = {
    subscriptionType: tier,
    subscriptionId: purchaseToken,
    subscriptionProductId: sku,
    subscriptionPlatform: "android",
    subscriptionUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (isCanceled) {
    updates.isPremium = false;
    updates.subscriptionStatus = "refunded";
    updates.subscriptionEndDate = null;
  } else if (isPurchased) {
    updates.isPremium = true;
    updates.subscriptionStatus = "active";
    updates.subscriptionEndDate = null; // lifetime — no expiry
  }

  await admin.firestore()
    .collection("users")
    .doc(uid)
    .set(updates, { merge: true });

  logger.info(
    "RTDN one-time reconciled",
    { uid, sku, notificationType, purchaseState: purchase.purchaseState }
  );
}

// ── HTTPS verify endpoint (defence in depth) ───────────────────────────────

/**
 * POST body: `{ productId: string, purchaseToken: string, uid: string,
 *               productType: "subs" | "inapp" }`
 *
 * Re-verifies a Play purchase server-side and reconciles Firestore. Useful
 * during restore flows where the client wants synchronous confirmation
 * instead of waiting for RTDN.
 *
 * Auth: relies on a Firebase ID token in the `Authorization: Bearer …`
 * header so a malicious client can't reconcile entitlement on a UID that
 * isn't theirs.
 */
exports.verifyPlayPurchase = functions.https.onRequest(async (req, res) => {
  // Reuse the project-wide CORS allow-list configured in index.js (caller is
  // the Android app via FirebaseFunctions or a plain fetch). Keep this simple:
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST,OPTIONS");
  res.set("Access-Control-Allow-Headers", "Authorization,Content-Type");
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }
  if (req.method !== "POST") {
    res.status(405).json({ error: "POST required" });
    return;
  }

  const idToken =
    (req.headers.authorization || "").replace(/^Bearer\s+/i, "") || null;
  if (!idToken) {
    res.status(401).json({ error: "Missing ID token" });
    return;
  }

  let decoded;
  try {
    decoded = await admin.auth().verifyIdToken(idToken);
  } catch (err) {
    res.status(401).json({ error: "Invalid ID token" });
    return;
  }

  const { productId, purchaseToken, productType } = req.body || {};
  if (!productId || !purchaseToken || !productType) {
    res.status(400).json({
      error:
        "productId, purchaseToken, and productType (subs|inapp) are required",
    });
    return;
  }
  const tier = TIER_BY_PRODUCT_ID[productId];
  if (!tier) {
    res.status(400).json({ error: `Unknown productId: ${productId}` });
    return;
  }

  try {
    const publisher = await getPlayPublisher();
    if (productType === "subs") {
      const { data } = await publisher.purchases.subscriptionsv2.get({
        packageName: PACKAGE_NAME,
        token: purchaseToken,
      });
      const lineItem = data.lineItems && data.lineItems[0];
      const expiryIso = lineItem && lineItem.expiryTime;
      const expiry = expiryIso ? new Date(expiryIso) : null;
      const isActive = data.subscriptionState === "SUBSCRIPTION_STATE_ACTIVE";

      await admin.firestore()
        .collection("users")
        .doc(decoded.uid)
        .set(
          {
            isPremium:
              isActive && (!expiry || expiry.getTime() >= Date.now()),
            subscriptionType: tier,
            subscriptionId: purchaseToken,
            subscriptionStatus: labelForSubscriptionState(
              data.subscriptionState,
              null
            ),
            subscriptionEndDate: expiry
              ? admin.firestore.Timestamp.fromDate(expiry)
              : null,
            subscriptionPlatform: "android",
            subscriptionProductId: productId,
            subscriptionUpdatedAt:
              admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

      res.json({
        ok: true,
        isActive,
        expiry: expiryIso || null,
      });
      return;
    }

    if (productType === "inapp") {
      const { data } = await publisher.purchases.products.get({
        packageName: PACKAGE_NAME,
        productId,
        token: purchaseToken,
      });
      const isPurchased = data.purchaseState === 0;
      await admin.firestore()
        .collection("users")
        .doc(decoded.uid)
        .set(
          {
            isPremium: isPurchased,
            subscriptionType: tier,
            subscriptionId: purchaseToken,
            subscriptionStatus: isPurchased ? "active" : "refunded",
            subscriptionEndDate: null,
            subscriptionPlatform: "android",
            subscriptionProductId: productId,
            subscriptionUpdatedAt:
              admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

      res.json({ ok: true, purchaseState: data.purchaseState });
      return;
    }

    res.status(400).json({ error: "productType must be subs or inapp" });
  } catch (err) {
    logger.error("verifyPlayPurchase failed", err);
    res.status(500).json({ error: "Verification failed" });
  }
});

// ── Helpers ────────────────────────────────────────────────────────────────

function extractUid(purchase) {
  // The Android client passes the Firebase UID via
  // BillingFlowParams.setObfuscatedAccountId; Play exposes it under both keys
  // depending on the API version.
  return (
    (purchase.externalAccountIdentifiers &&
      purchase.externalAccountIdentifiers.obfuscatedExternalAccountId) ||
    purchase.obfuscatedExternalAccountId ||
    null
  );
}

function labelForSubscriptionState(state, notificationType) {
  switch (state) {
    case "SUBSCRIPTION_STATE_ACTIVE":
      return "active";
    case "SUBSCRIPTION_STATE_CANCELED":
      return "canceled";
    case "SUBSCRIPTION_STATE_IN_GRACE_PERIOD":
      return "in_grace_period";
    case "SUBSCRIPTION_STATE_ON_HOLD":
      return "on_hold";
    case "SUBSCRIPTION_STATE_PAUSED":
      return "paused";
    case "SUBSCRIPTION_STATE_EXPIRED":
      return "expired";
    default:
      if (notificationType === SUBSCRIPTION_NOTIFICATION.REVOKED) {
        return "revoked";
      }
      return state || "unknown";
  }
}

// Exposed for tests + index.js re-exports.
exports._internal = {
  PRODUCT_IDS,
  TIER_BY_PRODUCT_ID,
  SUBSCRIPTION_NOTIFICATION,
  ONE_TIME_NOTIFICATION,
  labelForSubscriptionState,
};

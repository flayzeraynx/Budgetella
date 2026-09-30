/**
 * Self-managed replacement for the `delete-user-data` Extension
 * (firebase/delete-user-data@0.1.24), which is deprecated and gets
 * decommissioned on 2027-03-31.
 *
 * Lives in its own codebase on purpose: `budgetella_functions` still reads its
 * Stripe credentials from the legacy `functions.config()` store, so it is not
 * redeployed unless it has to be.
 *
 * Trigger: Firebase Auth user deletion. Auth triggers exist only in 1st gen —
 * there is no 2nd-gen equivalent — so this mirrors the Extension, which was
 * also 1st gen in europe-west3.
 *
 * Scope: every Budgetella document lives under `users/{uid}` (subcollections
 * transactions, categories, settings, savingsTips) and every user file under
 * the `users/{uid}/` Storage prefix, so one recursive delete plus one prefix
 * delete covers the account.
 *
 * NOTE — this is a deliberate behaviour fix, not a like-for-like port. The
 * Extension instance had no FIRESTORE_PATHS / RTDB_PATHS / STORAGE_PATHS set
 * and auto-discovery was off, so it deleted nothing at all. The clients only
 * remove the top-level `users/{uid}` document, which orphaned the
 * subcollections. This function deletes what the Extension was installed to
 * delete.
 */

const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();

const REGION = "europe-west3";
const STORAGE_BUCKET = "budgetella-d1d41.firebasestorage.app";

exports.clearUserDataOnDelete = functions
  .region(REGION)
  .runWith({ memory: "256MB", timeoutSeconds: 300 })
  .auth.user()
  .onDelete(async (user) => {
    const uid = user.uid;

    // Firestore: users/{uid} and everything beneath it.
    try {
      const userRef = admin.firestore().collection("users").doc(uid);
      await admin.firestore().recursiveDelete(userRef);
      functions.logger.info("[clearUserDataOnDelete] firestore cleared", { uid });
    } catch (err) {
      functions.logger.error("[clearUserDataOnDelete] firestore delete failed", {
        uid,
        error: err instanceof Error ? err.message : String(err),
      });
    }

    // Storage: users/{uid}/**
    try {
      const bucket = admin.storage().bucket(STORAGE_BUCKET);
      const [exists] = await bucket.exists();
      if (!exists) {
        functions.logger.warn("[clearUserDataOnDelete] bucket missing, skipped", {
          uid,
          bucket: STORAGE_BUCKET,
        });
        return;
      }
      await bucket.deleteFiles({ prefix: `users/${uid}/`, force: true });
      functions.logger.info("[clearUserDataOnDelete] storage cleared", { uid });
    } catch (err) {
      functions.logger.error("[clearUserDataOnDelete] storage delete failed", {
        uid,
        error: err instanceof Error ? err.message : String(err),
      });
    }
  });

# Budgetella Android — Changelog

## 1.1.0 (build 6) — 2026-05-26 · Testers community feedback

**TR-only TestFlight equivalent: closed/internal testing.**

### Added
- **Walkthrough (post-auth):** 3-page feature tour — "Add Transaction / Monthly Summary / Budget Goal", `HorizontalPager` + dots + skip (SpinDeck pattern). Gated by `UserPrefs.hasSeenWalkthrough` (DataStore). Routed via new `AppRootState.Walkthrough`.
- **Lottie Compose** (`com.airbnb.android:lottie-compose:6.6.0`): each page tries `assets/walkthrough_{add,summary,goal}.json` first, falls back to a Material icon hero when assets aren't bundled yet. Drop the JSON in `app/src/main/assets/` and animations activate automatically.
- **Settings → Community:** "Rate Budgetella" (Play In-App Review via `ReviewManagerFactory.requestReviewFlow`, fallback to Play Store listing) and "Share with Friends" (`Intent.ACTION_SEND` + chooser). Manual-only, no auto popup.
- `play-review-ktx:2.0.2` dependency.

### Changed
- **Onboarding 3→2 step:** Welcome / Permissions. The old Features step was removed; its content lives in the post-auth Walkthrough now.
- Dead `FeaturesPage()` / `FeatureRow()` composables removed.

### Infrastructure
- `versionCode = 6`, `versionName = "1.1.0"`
- TR + EN strings parity for all new keys (Walkthrough + Settings Community).
- `docs/aso-copy-{tr,en}.md`: v1.1.0 App Store + Play Console copy.

---

## 1.0.2 (build 3) — Play Billing release

**Premium subscriptions go live.**

- Added Google Play Billing v7 (`com.android.billingclient:billing-ktx:7.1.1`).
- Three plans now purchasable, matching the iOS StoreKit 2 catalogue:
  - `premium_monthly` — $4.99/month, 7-day free trial
  - `premium_annually` — $39.99/year, 7-day free trial
  - `premium_lifetime` — $99.99 one-time, non-consumable
- New `PlayBillingSubscriptionRepository`:
  - App-scoped singleton owning the `BillingClient` lifecycle with
    exponential-backoff reconnect.
  - `queryProductDetails` for SUBS + INAPP, cached in a `StateFlow` so the
    paywall renders localised `formattedPrice` (₺ TRY for TR accounts, USD
    elsewhere) instead of hard-coded numbers.
  - `PurchasesUpdatedListener` acknowledges every purchase within Play's
    3-day window and writes an optimistic `users/{uid}` Firestore update so
    the UI flips immediately. RTDN reconciles the authoritative expiry.
  - `setObfuscatedAccountId(firebaseUid)` is attached to every billing flow
    so the Cloud Function can resolve a Play purchase back to a Firestore
    user without a separate token table.
  - `observeIsPremium(uid)` reads `users/{uid}` directly — the same source
    of truth iOS already uses.
- `PaywallScreen` rewritten to use a new `PaywallViewModel`:
  - Three plan cards (was Monthly/Yearly toggle); Lifetime added.
  - CTA copy is plan-aware ("Start 7-Day Free Trial" vs "Buy Now").
  - Error states surface in a `Material3 AlertDialog`; success auto-closes
    the sheet once Firestore confirms premium.
  - "Coming soon" snackbar removed.
- New Cloud Functions (`budgetella_functions/play-billing.js`):
  - `playRtdnHandler` — Pub/Sub `play-rtdn` topic trigger, validates every
    notification with `androidpublisher.purchases.subscriptionsv2.get` /
    `purchases.products.get`, writes authoritative entitlement to Firestore.
  - `verifyPlayPurchase` — HTTPS endpoint for defence-in-depth synchronous
    server validation during restore flows.
- New `googleapis` dependency in `budgetella_functions/package.json`.
- TR + EN string updates: lifetime title/subtitle/fine-print, per-month /
  per-year suffixes, "33% off" badge, error dialog title, generic
  free-trial copy.
- Bumped `versionCode` to 3, `versionName` to `1.0.2`.

**Operator follow-up (Play Console side, see `BILLING.md`):**
- Create the three products with the exact IDs above + 7-day trial offers.
- Configure the `play-rtdn` Pub/Sub topic + RTDN endpoint.
- Link GCP project in Play Console → API access; grant the Firebase Admin
  service account "View financial data" + "Manage orders and subscriptions".

---

## 1.0.1 (build 2)

- Camera + microphone permissions, voice + receipt entry hardening.
- Initial Play Store closed-track build (since deleted before public launch).

# Budgetella Android — Play Billing Setup

This document covers everything you need to flip the paywall live in
production. The Kotlin side is implemented in
`com.budgetella.app.data.billing.PlayBillingSubscriptionRepository`; this file
is the operator's checklist for the Play Console + GCP side.

The implementation mirrors the iOS `SubscriptionService` (StoreKit 2) — same
three plans, same Firestore schema, same `users/{uid}` source of truth.

---

## 1. Products to create in Play Console

Console → All apps → **Budgetella** → Monetisation.

| Product | Type | Product ID | Base plan ID | Offer ID | Trial | Price |
|---|---|---|---|---|---|---|
| Monthly Premium | Subscription | `premium_monthly` | `monthly` | `freetrial` | 7 days (P1W) | $4.99 / ₺ tier |
| Annual Premium | Subscription | `premium_annually` | `annually` | `freetrial` | 7 days (P1W) | $39.99 / ₺ tier |
| Lifetime Premium | Managed product (INAPP) | `premium_lifetime` | — | — | — | $99.99 / ₺ tier |

**Pricing:** match the iOS price tiers exactly. The `users/{uid}` entitlement
schema is identical across platforms, but pricing is set per-store.

**Country availability:** Türkiye-only for v1 — the same restriction as the
iOS launch. Add other countries when global rollout begins.

**License testers:** Play Console → Setup → License testing → add
`flayzeraynx@gmail.com` plus any second test account. Testers see a "Test
card, always approves" payment method and pay nothing.

---

## 2. Real-time developer notifications (RTDN)

Console → Monetisation setup → **Real-time developer notifications**.

1. Cloud Console (same GCP project as Firebase) → Pub/Sub → create topic
   `play-rtdn`.
2. In the topic IAM, grant the Play service account
   `google-play-developer-notifications@system.gserviceaccount.com` the role
   **Pub/Sub Publisher**.
3. Back in Play Console RTDN settings → paste `projects/<gcp-project>/topics/play-rtdn`
   into the topic field → Save.
4. Click **Send test notification** — `playRtdnHandler` should log
   `RTDN test notification received` in `firebase functions:log`.

The Cloud Function lives in
`budgetella_functions/play-billing.js` and is exported from `index.js` as
`exports.playRtdnHandler`. It fans out into two paths:

- `subscriptionNotification` → `purchases.subscriptionsv2.get` → Firestore
- `oneTimeProductNotification` → `purchases.products.get` → Firestore

Every event ends with a merge write to `users/{uid}`:

```
isPremium: boolean
subscriptionType: 'monthly' | 'yearly' | 'lifetime' | 'none'
subscriptionId: <purchaseToken>
subscriptionStatus: 'active' | 'canceled' | 'in_grace_period' |
                    'on_hold' | 'paused' | 'expired' | 'revoked' | 'refunded'
subscriptionEndDate: Timestamp | null  (null for lifetime)
subscriptionPlatform: 'android'
subscriptionProductId: <Play product id>
subscriptionUpdatedAt: serverTimestamp()
```

The web/Stripe webhook writes the same schema, so iOS and Android pick up
entitlement changes from any platform.

---

## 3. Play Developer API access (server-side validation)

The RTDN handler and `verifyPlayPurchase` HTTPS endpoint both call
`androidpublisher` v3. They use Application Default Credentials in the
Functions runtime — i.e. the Firebase Admin service account
`firebase-adminsdk-<hash>@budgetella-d1d41.iam.gserviceaccount.com`.

Grant access:

1. Play Console → Setup → **API access**. If GCP isn't linked, link this
   project.
2. Once linked, find the Firebase Admin service account in the **Service
   accounts** list. Click **Grant access**.
3. Permissions to enable on the account:
   - View financial data, orders, and cancellation survey responses
   - Manage orders and subscriptions

Without these, every `purchases.subscriptionsv2.get` call returns
`The current user has insufficient permissions to perform the requested operation.`

---

## 4. Deploy the functions

```bash
cd budgetella_functions
npm install                              # picks up googleapis dep
firebase deploy --only functions:playRtdnHandler,functions:verifyPlayPurchase
```

`playRtdnHandler` subscribes itself to the Pub/Sub topic on first deploy.
The topic name is configurable:

```bash
firebase functions:config:set play.rtdn_topic="play-rtdn"
```

Default is `play-rtdn` if unset.

---

## 5. App-side wiring (already done)

| File | Role |
|---|---|
| `data/billing/BillingProducts.kt` | Product ID constants + canonical-tier mapping |
| `data/billing/PlayBillingSubscriptionRepository.kt` | BillingClient lifecycle, purchase flow, Firestore listener |
| `di/SubscriptionModule.kt` | Hilt binding to the Play impl |
| `ui/paywall/PaywallViewModel.kt` | Drives the paywall, owns `PurchaseState` |
| `ui/paywall/PaywallScreen.kt` | Compose UI — 3 plan cards, live `ProductDetails` prices |
| `res/values/strings.xml` + `values-tr/strings.xml` | Lifetime + auto-renew copy in EN/TR |

The repo connects to `BillingClient` on construction (Hilt `@Singleton`).
Disconnects are recovered with exponential backoff up to ~64s.

---

## 6. Testing flow (debug build, real Play account)

1. Install the **internal-test track** build on a device signed in with a
   license-tester Google account.
2. Open the paywall (Settings → Premium, or any premium-gated UI tap).
3. Pick a plan, tap **Start 7-Day Free Trial** → Play sheet appears showing
   `Test card, always approves`.
4. Confirm → the Compose paywall auto-dismisses once Firestore reports
   `isPremium=true`. Watch `firebase functions:log --only playRtdnHandler`
   for the corresponding RTDN event.
5. Verify Firestore: `users/{uid}` now has
   `isPremium=true, subscriptionType='yearly', subscriptionStatus='active'`.

**Cancel & expire test:**
- Phone → Settings → Subscriptions → Budgetella → Cancel → Play Console
  test orders renew on 5-minute / 10-minute / 15-minute cycles, so within
  one cycle you get a `SUBSCRIPTION_EXPIRED` event and `isPremium` flips to
  `false`.

**Restore test:**
- Reinstall the app → Sign in with the same account → tap **Restore
  purchases** on the paywall → `queryPurchasesAsync` finds the existing
  entitlement → Firestore is re-written → UI flips.

---

## 7. Free-trial eligibility

A Google account can claim the 7-day trial only once per product. If
testing reveals the trial badge missing for an account that already
consumed a trial, that's expected behaviour. Reset the test environment by
clearing the test order from Play Console → Order management.

---

## 8. Common errors

| Symptom | Cause | Fix |
|---|---|---|
| `Play Billing service unavailable` toast | Device has no Play Store, or service disconnected | Ensure Play Store updated; the repo retries automatically |
| Product card stuck on `—` price | Product not yet active in Play Console | Wait ~10 minutes after activation; queryProductDetails only returns active products |
| RTDN events not arriving | Pub/Sub topic IAM missing | Re-grant `Pub/Sub Publisher` to `google-play-developer-notifications@system.gserviceaccount.com` |
| `insufficient permissions` from androidpublisher | Service account not authorised in Play Console | Step 3 above |
| Purchase succeeds but `users/{uid}.isPremium` stays false | `obfuscatedAccountId` empty at purchase time | Confirm the user was signed in before launching the paywall — the repo skips Firestore writes for blank UIDs |

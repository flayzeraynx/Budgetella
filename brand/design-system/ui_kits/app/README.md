# Budgetella — App UI Kit

High-fidelity, click-through recreation of the native Budgetella iOS app (SwiftUI). Built from the design brief + marketing screenshots (dashboard, voice, transactions, stats, ai). Composes the design-system component primitives — it does not re-implement them.

## Run
Open `index.html`. Top-left toolbar toggles **Dark / Light** theme and the **Paywall**. The bottom tab bar navigates: Home (Dashboard) · List (Transactions) · **+** (QuickEntry) · Stats · AI (Budgi chat).

## Screens
- `DashboardScreen.jsx` — greeting, active-month summary glass card, daily-flow sparkline, Budgi savings insight, category rows.
- `TransactionsScreen.jsx` — All/Income/Expense segmented filter, search, category chips, grouped transaction list.
- `QuickEntryScreen.jsx` — three entry modes: **Voice** (listening), **Camera** (receipt OCR), **Manual** (category picker + numeric keypad).
- `StatsScreen.jsx` — expense/income toggle, donut + total, Budgi "biggest transaction" insight, category breakdown bars.
- `AiScreen.jsx` — Budgi AI chat (privacy-first framing).
- `PaywallScreen.jsx` — honest 7-day trial paywall, yearly/monthly price cards, no dark patterns.

## Support files
- `data.js` — mock data (`window.BDG_DATA`).
- `PhoneFrame.jsx` — iPhone bezel + status bar. `TabBar.jsx` — bottom nav with center FAB.

## Notes
- Icons: **Lucide** via CDN (substitute for the app's undocumented glyph set).
- Category colors follow the semantic palette; income is always mint, expense always coral.
- This is a cosmetic recreation — interactions are simplified stand-ins, not production logic.

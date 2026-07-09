# Budgetella — Design System

Personal-finance / budget-tracking app. **No bank login, no ads, no data selling — privacy-first by default.** Users log spending manually, by voice ("Kahve 45 lira"), or by scanning a receipt with the camera (AI OCR). The AI ("Budgi") suggests a category; the user confirms. The promise: *"Knowing where your money actually goes is where everything starts."* — financial clarity and control, calm and premium, never stressful.

## Platforms / products
- **Native iOS** — Swift 6 + SwiftUI + SwiftData, App Store (production). **Source of truth for this design system.**
- **Native Android** — Kotlin + Compose + Room, `com.budgetella.app` (Play Store).
- **Marketing web** — static site `budgetella.app`, EN + TR, Firebase Hosting. Uses a slightly different palette + fonts (documented below).
- **Backend** — Firebase (Auth + Firestore + Functions). **AI** — Google Gemini (client-side, premium-gated): spending insights, category suggestion, receipt OCR.
- **Market (V1):** Turkey-first, iPhone-first. ₺TL + USD tiers. Voice = TR/EN.
- **Pricing:** $4.99/mo · $39.99/yr (7-day free trial) · lifetime option. Native StoreKit 2 / Play Billing.

## Sources this system was built from
The user attached a curated extract, **not** the full repo:
- `Budgetella-Brief/BRIEF.md` — the 9-section design brief (pasted as the first message).
- `Budgetella-Brief/design-tokens.json` — real color/type/radius/spacing tokens (iOS canonical; web variants + mismatches flagged).
- `Budgetella-Brief/assets/` — `AppIcon-1024.png`, `AppIcon-152.png`, `apple-touch-icon.png`, `favicon.svg` (generic Lucide *wallet* — NOT the brand mark), `og-image.png`, `BudgetellaLogoView.swift` (logo source).
- `Budgetella-Brief/screenshots/` — 5 marketing screens (dashboard, voice, transactions, stats, ai).
- Original code paths (not directly readable here): iOS `iOS/Budgetella/DesignSystem/{Colors,Typography,Spacing,BudgetellaLogoView}.swift`; Android `core/design/{BrandColor,Theme}.kt` + `res/values/colors.xml`; web `web/assets/style.css` + `index.html` + `tr.html`.

All values here are lifted from that extract — no invented numbers. Unknowns are flagged.

---

## CONTENT FUNDAMENTALS

**Languages:** TR primary, EN parallel. Every product string ships in both.

**Voice:** Trustworthy, calm, clear, professional — premium without hype. Reduces money stress. Short, human sentences. The user is always the subject and the one in control ("you confirm", "you decide").

**Person & address:** Second person ("sen" / "you"). Never the over-familiar Turkish "kanka"; never a scolding parental tone.

**Casing:** Sentence case for body and buttons. UPPERCASE only for the small eyebrow/section labels (caption2, +0.5 tracking) — e.g. `ANNUAL SUMMARY`, `CATEGORY BREAKDOWN`, `VOICE ENTRY`. Amounts are concrete, with the ₺ / $ symbol.

**Emoji:** Sparingly and only human/warm — a waving 👋 in a greeting ("Good afternoon, Ozan Kilic 👋"). Never emoji as category icons or decoration.

**Do:** Lead with the concrete benefit. Make the user the subject. Give real numbers ("340₺ left this month"). Emphasize privacy. Calm confidence.

**Don't:** Blame or shame ("you spent too much!"). FOMO / dark patterns / fake urgency. Over-promise ("get rich"). Technical jargon. Exclamation-mark spam.

**Copy examples (real marketing + product):**
| Context | TR | EN |
|---|---|---|
| Hero | Harcamalarını takip et, bütçeni yönet, finansal hedeflerine ulaş. | Track your spending, manage your budget, reach your financial goals. |
| Sub-hero | Banka bağlantısı yok, reklam yok, gizliliğe saygılı. | No bank login, no ads, privacy-first. |
| Empty state | Henüz işlem yok. İlk harcamanı ekle — kamerayla, sesle ya da elle. | No transactions yet. Add your first — camera, voice, or by hand. |
| Error | İşlem kaydedilemedi. Bağlantını kontrol et, tekrar dene. | Couldn't save. Check your connection and try again. |
| Notification | Market bütçende limitine yaklaşıyorsun — bu ay 340₺ kaldı. | You're nearing your Groceries limit — 340₺ left this month. |
| Paywall | 7 gün ücretsiz dene. Beğenirsen devam et, beğenmezsen bir kuruş ödemezsin. | Try free for 7 days. Love it or cancel — you won't be charged a cent. |

Marketing headlines are bold, two-tone (white + a gradient-tinted word), short: *"Money, finally under control."* · *"Just say it. Logged."* · *"Where did it all go?"* · *"Type a number. AI does the rest."*

---

## VISUAL FOUNDATIONS

**Overall:** dark-first "glass premium". Deep navy-black canvas with floating frosted-glass panels. Three themes: dark (default) / light / system, resolved at runtime.

**Color:** One accent — violet `#6E5BFF` (light `#8B6FFF`, logo-gradient top `#9585FF`), extended to a **50→900 tint/shade ramp** (400/500/600 are the real code values; the rest oklch-derived). A **secondary accent** — cyan `#06B6D4` — carries non-financial highlights (links, selected chips, focus) so violet stays reserved for primary actions and money-positive contexts. Two fixed semantic colors that carry *meaning*, never decoration: income = mint `#10F2A5`, expense = coral-red `#FB7185`. Plus warning `#F59E0B`. There is no separate "success" token — the income mint is success. Dark surfaces layer `#0A0B14` (bg) → `#11141C` (surface) → `#1A1F2E` (elevated), with deeper navy/violet ambient blooms behind (`#14152A`, `#1A1740`). Text is white at 100/72/50% opacity.

**Typography:** Inter (app intended; SF Pro is the current runtime fallback — see caveat). Geist + Geist Mono on the marketing web. Big bold display/hero headlines, tight tracking on large sizes (display +6, largeTitle +4), and generous +2 tracking on body/title. Currency amounts use **tabular / monospaced digits** and often the mono family, so figures don't jitter.

**Spacing & layout:** strict 4px grid (4/8/12/16/24/32/48). Content max 480px, forms max 360px, min touch target 44px. Screens are single-column, card-stacked, roomy.

**Corner radii (5 steps):** chips/small 8 · buttons & list rows 14 · standard card 16 · large card 24 · bottom-sheet & paywall modal 28 · pills/FAB/avatars full. Logo uses radius = size × 0.22.

**Cards:** frosted glass — translucent fill (`.ultraThinMaterial` in iOS; `backdrop-filter: blur(24px)` here) + a 1px subtle white-8% border. Soft, low-contrast shadows (never harsh). No colored left-border-only cards except the **Budgi AI insight** card, which intentionally uses a colored left rule (income mint or accent) as its signature.

**Backgrounds:** solid deep navy with soft radial color blooms (violet, magenta, teal) — no busy patterns, no photography in-app. Marketing screens add larger ambient gradient glows behind the phone.

**Motion — "Instant ON, smooth OFF":** on press the highlight appears instantly (0s); on release it eases out over 0.22s (`ease-out`). Card press = spring (response 0.3, damping 0.7) + scale 0.97 + a white-14% wash. List rows tint brand-violet 15% on press. Skeleton loading uses a shimmer sweep. Motion is meaningful, never decorative — no infinite loops on content.

**Hover/press states:** press = subtle wash + slight shrink (cards) or tint (rows). Buttons: primary is a solid violet fill with a soft accent glow; secondary is a bordered glass surface; ghost is text-only. Focus rings use the accent color.

**Transparency & blur:** used deliberately for depth hierarchy (glass cards, pill chips, the translucent tab bar), not everywhere. Solid fills for primary actions and the FAB.

**WCAG notes:** white-on-`#0A0B14` ≈ 19:1 (AAA). Watch secondary 72% / tertiary 50% on small text (AA borderline). White text on the `#6E5BFF` fill barely passes AA — prefer large/bold on accent fills.

---

## ICONOGRAPHY

- **Category icons** are single-weight glyphs shown inside a **circular tinted badge** — the badge fill is the category color at low opacity, the glyph in the full category color. Seen in-app: Shopping (bag, violet), Transportation (car, blue), Bills (document, coral), Food (fork/knife, gold), Healthcare (medical bag, coral), Housing (home, violet), Entertainment (tv/monitor, coral), Education (dot, blue). These match the **Lucide** set (matching stroke/fill style). iOS most likely uses system **SF Symbols**; an official brand icon set is **⏳ not documented**.
- **Substitution (flagged):** for HTML recreations this system links **Lucide** from CDN — the closest match to the app's category glyphs. If the real app ships SF Symbols or a custom set, replace accordingly.
- The web **favicon.svg** is a **generic Lucide "wallet"** (currentColor stroke) — it is NOT the brand mark and must not be used as the logo.
- **Emoji:** only warm/human accents in copy (👋). Never as icons.
- Tab bar uses simple line icons: Home, List, a central "+" FAB, Stats (bar chart), AI (sparkle).

---

## LOGO & BRAND MARK

Real mark is defined **in code** (`assets/BudgetellaLogoView.swift`) and baked into `AppIcon-1024.png`. Anatomy: a rounded square with a **violet gradient** (top-leading `#9585FF` → bottom-trailing `#6E5BFF`), a white **bold "B"**, and a **mint dot** (`#10F2A5` income) at the top-right. Ratios: corner radius = size × 0.22, letter = × 0.58, dot = × 0.155, dot offset x +0.17 / y −0.28.

**Rules — always** gradient bg + white B + mint dot together, corner-radius ratio preserved. **Never** recolor the gradient, remove/recolor the dot (mint is fixed), redraw the "B" in another font, flip the gradient direction, or use the wallet favicon as the logo. See the "Logo" card group and `assets/`.

**Wordmark / lockup:** the mark pairs with "Budgetella." set in **Inter Bold, −0.5 tracking**; the trailing period may take the accent color. Horizontal (mark left of wordmark) and stacked lockups are both valid.

**Clear space & min size:** keep clear space equal to the mint-dot diameter on all sides; never render the mark below **24px (≈20pt)** — use the favicon-scale asset instead.

**Variations (constrained-use only — full color is always primary):** reversed/white (one-color on dark), mono/black (single-color print on light), and line/outline (watermark/emboss, dot becomes a ring). These are faithful CSS reconstructions of the coded mark for contexts where the gradient can't render — they are **not** replacements for the full-color logo. See the "Variations" card.

---

## INDEX / MANIFEST

**Root:** `styles.css` (the single consumer entry point — @import list only), `readme.md`, `SKILL.md`.

**`tokens/`** — `fonts.css`, `colors.css` (dark + light + semantic + accent + web variants), `typography.css`, `spacing.css`, `radius.css`, `effects.css` (glass/shadow/motion).

**`assets/`** — `AppIcon-1024.png`, `AppIcon-152.png`, `apple-touch-icon.png`, `favicon.svg` (⚠️ generic wallet), `og-image.png`, `BudgetellaLogoView.swift` (logo source).

**`guidelines/`** — foundation specimen cards (Colors, Type, Spacing, Brand) shown in the Design System tab.

**`components/`** — reusable primitives (see below). Namespace: `window.BudgetellaDesignSystem_962d64`.

**`ui_kits/`** — full-screen product recreations (Dashboard, Transactions, QuickEntry, Stats, AI, Paywall). The app kit (`ui_kits/app/index.html`) toolbar toggles **iOS / Android** platform chrome and **Dark / Light** theme — iOS uses `PhoneFrame` + `TabBar`, Android uses `AndroidFrame` + `MaterialTabBar` (Compose/Material). Both share the same tokens, components, and screen code (1:1 feature parity); only the device bezel and bottom-nav chrome differ. See also the "iOS vs Android" Platforms card.

### Component inventory
Derived from the brief's requested component set (§8.3): `GlassCard`, `Button` (primary/secondary/ghost), `ListRow` (press-tint), `Amount` (mono tabular), `SegmentedControl`, `BottomSheet` (radius 28), `PriceCard` (paywall), `EmptyState`, `Toast`, `Shimmer` (skeleton), `Chip`, `CategoryIcon` (badge glyph), `BudgiInsight` (AI insight card).

**Intentional additions:** `CategoryIcon` (glyph-in-tinted-badge wrapper — the app uses this pattern pervasively but the brief lists no icon primitive) and `BudgiInsight` (the signature AI insight card, seen on Dashboard + Stats). Both are documented here for transparency.

## CAVEATS
- **Fonts:** the source repo shipped no `.ttf` binaries. `tokens/fonts.css` loads **Inter / Geist / Geist Mono from Google Fonts CDN**. Provide the real files to self-host / pin. (Also: Inter is only the *intended* app font — the shipping app currently renders SF Pro as fallback.)
- **Icons:** Lucide via CDN is a **substitution** for the app's (undocumented) category glyph set.
- **App↔web palette mismatches** (income/expense/accent) are preserved separately; app values are treated as canonical.

---
name: budgetella-design
description: Use this skill to generate well-branded interfaces and assets for Budgetella (privacy-first personal-finance app), either for production or throwaway prototypes/mocks/etc. Contains essential design guidelines, colors, type, fonts, assets, and UI kit components for prototyping.
user-invocable: true
---

Read the `readme.md` file within this skill, and explore the other available files.

If creating visual artifacts (slides, mocks, throwaway prototypes, etc), copy assets out and create static HTML files for the user to view. If working on production code, you can copy assets and read the rules here to become an expert in designing with this brand.

If the user invokes this skill without any other guidance, ask them what they want to build or design, ask some questions, and act as an expert designer who outputs HTML artifacts _or_ production code, depending on the need.

## Quick map
- `styles.css` — the single entry point; `@import` it to get all tokens + fonts.
- `tokens/` — colors (dark + light + semantic + accent + web variants), typography, spacing, radius, effects (glass/shadow/motion).
- `components/` — React primitives (namespace `window.BudgetellaDesignSystem_962d64`): GlassCard, Button, Amount, CategoryIcon, ListRow, SegmentedControl, Chip, BudgiInsight, Toast, EmptyState, Shimmer, PriceCard, BottomSheet.
- `ui_kits/app/` — full click-through iOS app recreation (Dashboard, Transactions, QuickEntry, Stats, AI, Paywall).
- `guidelines/` — foundation specimen cards.
- `assets/` — app icon, favicon (⚠️ generic wallet, not the mark), og-image, logo source.

## Non-negotiables
1. **No dark patterns** — no FOMO, fake urgency, hidden cancel, or shaming copy. The user comes first.
2. **Don't imply bank/data access** — no "connect your bank" or notification-spam patterns.
3. **Protect the brand core** — accent `#6E5BFF` + mint income dot + dark glass. Never recolor the logo gradient, remove the mint dot, or use the wallet favicon as the mark. Income = mint, expense = coral are fixed meanings.

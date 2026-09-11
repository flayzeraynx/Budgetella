# Graph Report - Budgetella  (2026-08-31)

## Corpus Check
- Large corpus: 617 files · ~1,508,735 words. Semantic extraction will be expensive (many Claude tokens). Consider running on a subfolder.

## Summary
- 3178 nodes · 6108 edges · 206 communities (187 shown, 10 thin omitted)
- Extraction: 92% EXTRACTED · 8% INFERRED · 0% AMBIGUOUS · INFERRED: 475 edges (avg confidence: 0.84)
- Token cost: 837,437 input · 92,000 output

## Community Hubs (Navigation)
- Android Locale Switching
- Marketing Blog EN/TR
- iOS Onboarding Flow
- iOS Auth Views
- Room Transaction DAO
- Room Category DAO
- Cloud Functions Dependencies
- Play Billing Integration
- Room Budget DAO
- Android Money Formatting
- Budgi AI Chat (iOS)
- Cloud Functions Entrypoint
- iOS Voice Entry
- iOS Tab Navigation
- iOS Home Widget
- iOS Edit Transaction Sheet
- Legacy Webapp Docs
- iOS Data Models
- iOS Firestore Sync
- iOS Stats Aggregation
- Android Dashboard Screen
- Android Project Structure
- iOS Profile & Password
- Monorepo Layout
- Android Design System
- iOS Dashboard Cards
- Android Data Repository
- Android Data Repository
- iOS Features Dashboard
- Android Data Repository
- iOS Core Models
- iOS Features Transactions
- Design Spec: UI Flow
- iOS Core Services
- iOS Core Models
- iOS Core Models
- iOS Core Services
- iOS Design System Typography
- Android Data Model
- Android Android
- iOS Design System Environment Keys
- iOS Features Auth
- iOS Features Auth
- iOS Features Dashboard
- iOS Features Quick Entry
- iOS Features Settings
- iOS Features Settings
- iOS Core AI
- iOS Core Services
- iOS Features Dashboard
- iOS Features Paywall
- Monorepo Agent Notes
- Android Data Auth
- Android Ui Paywall
- Android Ui Paywall
- Android Ui Budgi
- Android Ui Main
- iOS Core Services
- iOS Design System Budgetella Logo View
- Category Translation Job
- Android Core Design
- Android Data Prefs
- Android Data Repository
- Android Ui App Root View Model
- Android Ui Budgi
- Android Ui Quickentry
- iOS Features Quick Entry
- iOS Features Settings
- Android Ui Settings
- iOS Core Intents
- iOS Core Services
- iOS Features Quick Entry
- iOS Misc
- Design Spec: Mobile v1
- Android Ui Auth
- Android Ui Onboarding
- Android Ui Settings
- Android Ui Stats
- iOS Design System Brand Alert
- Design Spec: Tier 3
- Legacy Contributing Guide
- Android Data Billing
- Android Di Data Module
- Android Data Local
- Android Ui Auth
- iOS Core Models
- Docs Aso-copy-en
- iOS Features Quick Entry
- iOS Features Stats
- iOS Features Walkthrough
- Android Ui App Root
- Android Ui Dashboard
- iOS Content View
- iOS Core Models
- iOS Features Quick Entry
- iOS Features Settings
- iOS Features Transactions
- Android Data Model
- Android Data Remote
- Android Ui Settings
- Android Ui Settings
- Android Ui Stats
- Android Ui Transactions
- Legacy API CLAUDE
- iOS Budgetella App
- iOS Core Models
- iOS Core Services
- iOS Features Settings
- Android Data Auth
- Android Data Backup
- Android Data Remote
- Android Data Prefs
- Android Data Repository
- Android Data Repository
- Android Ui Quickentry
- iOS Core Models
- iOS Core Services
- iOS Features Settings
- iOS Features Quick Entry
- Android Data Model
- Android Data Billing
- Android Data Model
- Android Data Remote
- Android Ui Transactions
- iOS Features Quick Entry
- iOS Core Services
- iOS Features Settings
- Design Spec: Mobile v2
- Firebase Email Setup
- Watch-firestore
- Android Data Auth
- Android Data Local
- Android Data Model
- Android Ui Budgi
- Android Ui Transactions
- Android Ui Transactions
- Functions Deploy-functions
- Docs Godaddy-deployment
- Docs Firebase-deployment
- iOS Core Helpers
- iOS Core Models
- iOS Features Auth
- iOS Features Stats
- iOS Features Transactions
- Design Spec: Tier 3
- Design Spec: Mobile v2
- Android Budgetella Application
- Android Data Local
- Android Data Remote
- Android Ui Main
- Android Ui Settings
- Android Ui Settings
- Android Android
- Functions DEPLOY
- Functions CLAUDE
- iOS Content View
- iOS Core AI
- iOS Core Helpers
- iOS Features Auth
- Design Spec: Mobile v2
- Design Spec: Tier 3
- Send-test-push
- Android Data Auth
- Android Ui Quickentry
- iOS Features Auth
- iOS Core Models
- iOS Features Auth
- Android Di Auth Module
- Android Ui Quickentry
- Android Ui Walkthrough
- Android Android
- iOS Core Widget
- iOS Misc
- Design Spec: UI Flow
- Android Data Model
- Android Ui Auth
- Android Ui Main
- Android Ui Settings
- iOS Core Intents
- iOS Core Services
- Docs User-guide
- iOS Features Quick Entry
- Android Data Billing
- Android Ui Quickentry
- Android Ui Settings
- Android Ui Transactions
- Functions Deploy-and-run-update
- iOS Features Paywall
- Android Data Local
- Android Android
- Docs Server-sync-setup
- Functions Deploy
- iOS Design System Spacing
- iOS Core Models
- iOS Core Services
- Functions Test
- iOS Misc

## God Nodes (most connected - your core abstractions)
1. `TransactionEntity` - 65 edges
2. `CategoryEntity` - 64 edges
3. `Transaction` - 60 edges
4. `Category` - 49 edges
5. `README.md (Android)` - 41 edges
6. `BrandColor` - 40 edges
7. `AuthService` - 40 edges
8. `SwiftData` - 36 edges
9. `EditTransactionSheet` - 32 edges
10. `Decimal` - 30 edges

## Surprising Connections (you probably didn't know these)
- `FinVault User Guide` --semantically_similar_to--> `FinVault (old app name)`  [INFERRED] [semantically similar]
  docs/user-guide.md → api/CLAUDE.md
- `Budgetella: Privacy-First Personal Finance Tracker` --semantically_similar_to--> `OLD/ archive`  [INFERRED] [semantically similar]
  README.md → AGENTS.md
- `Firebase Functions 1st Gen` --semantically_similar_to--> `budgetella_functions/ (active production backend)`  [INFERRED] [semantically similar]
  README-FIREBASE-EMAIL.md → CLAUDE.md
- `CONTRIBUTING.md reference` --semantically_similar_to--> `finvault/ project structure (old webapp)`  [INFERRED] [semantically similar]
  README.md → CONTRIBUTING.md
- `Empty State · Dashboard (First Open)` --semantically_similar_to--> `Dashboard Landing (Above-the-fold)`  [INFERRED] [semantically similar]
  Budgetella · Mobile v2 · Print.pdf → Budgetella · Mobile · Print.pdf

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Budgetella Monorepo Subproject Structure** — agents_ios_subproject, agents_android_subproject, agents_web_subproject, agents_budgetella_functions [EXTRACTED 0.90]
- **Android Play Billing End-to-End Integration** — android_billing_playbillingsubscriptionrepository, android_billing_playrtdnhandler, android_billing_users_uid_firestore_entitlement_schema, android_changelog_google_play_billing_v7_billing_ktx_7_1_1 [INFERRED 0.85]
- **Legacy React Webapp to Native App Migration** — readme_budgetella_privacy_first_personal_finance_tracker, agents_old_archive, claude_android_skeleton, agents_ios_subproject [INFERRED 0.75]
- **Feedback Email Pipeline (Legacy PHP to Cloud Function)** — api_claude_send_feedback_php, budgetella_functions_claude_sendfeedback, budgetella_functions_readme_sendfeedback [INFERRED 0.85]
- **Budgetella iOS v1.1.0 Release Bundle** — ios_changelog_v1_1_0, ios_project_yml_config, docs_aso_copy_en_guide [INFERRED 0.80]
- **Old Webapp Firebase Setup & Deployment** — docs_firebase_setup_guide_doc, docs_firebase_deployment_guide, docs_firebase_setup_guide_firestore_rules [INFERRED 0.75]
- **Pricing Consistency Across EN/TR Landing Pages** — web_claude_pricing_consistency_rule, web_index_pricing, web_tr_pricing [INFERRED 0.85]
- **Download CTA: App Store + Play Store Links on Landing Page** — web_index, web_index_app_store_link, web_index_play_store_link [EXTRACTED 1.00]
- **EN Blog Content Set** — web_blog, web_blog_bank_app_vs_budget_app, web_blog_how_to_budget_monthly, web_blog_why_track_expenses [EXTRACTED 1.00]
- **Onboarding → Auth Choice → Sign Up → Dashboard Flow** — uiflow_01_welcome, uiflow_02_features, uiflow_03_currency, uiflow_04_permissions, uiflow_a1_auth_choice, uiflow_a2_signup, uiflow_d1_landing [EXTRACTED 1.00]
- **Quick-Entry FAB Flow (Voice/Camera/Manual → Confirm → Transaction List)** — uiflow_d1_landing, uiflow_e1_voice, uiflow_e2_camera_ocr, uiflow_e3_manual, uiflow_e4_confirm, uiflow_g1_transaction_list [EXTRACTED 1.00]
- **Freemium Limit → Paywall → Premium → Subscription Management Flow** — mv1_transaction_list, mv1_paywall_modal, mv1_premium_fullscreen, mv2_subscription_management, mv2_restore_purchases_success [INFERRED 0.75]

## Communities (206 total, 10 thin omitted)

### Community 0 - "Android Locale Switching"
Cohesion: 0.06
Nodes (40): forceApplicationLocale(), Context, Language, English, German, Turkish, LocaleHelper, Configuration (+32 more)

### Community 1 - "Marketing Blog EN/TR"
Cohesion: 0.06
Nodes (56): blog.html (EN Blog Index), Is Your Bank App Enough for Budgeting? (Blog, EN), Banka Uygulaman Bütçe İçin Yeterli mi? (Blog, TR), Aylık Bütçe Nasıl Yapılır? (Blog, TR), Harcamalarını Neden Takip Etmelisin? (Blog, TR), How to Build a Monthly Budget (Blog, EN), blog-tr.html (TR Blog Index), Why You Should Track Your Expenses (Blog, EN) (+48 more)

### Community 2 - "iOS Onboarding Flow"
Cohesion: 0.07
Nodes (27): OnboardingView, .body, Void, OnboardingViewModel, AppCurrency, Int, ModelContext, String (+19 more)

### Community 3 - "iOS Auth Views"
Cohesion: 0.06
Nodes (34): backButton(), fieldLabel(), LocalizedStringKey, View, Void, .body, AuthFaceIDSetupView, .body (+26 more)

### Community 4 - "Room Transaction DAO"
Cohesion: 0.09
Nodes (10): Flow, TransactionDao, RecurringInterval, TransactionType, TransactionEntity, Flow, TransactionType, RoomTransactionRepository (+2 more)

### Community 5 - "Room Category DAO"
Cohesion: 0.09
Nodes (10): CategoryDao, Flow, CategoryEntity, CategorySlug, TransactionType, CategoryRepository, CategorySlug, Flow (+2 more)

### Community 6 - "Cloud Functions Dependencies"
Cohesion: 0.05
Nodes (38): dependencies, cors, dotenv, firebase-admin, firebase-functions, googleapis, node-fetch, nodemailer (+30 more)

### Community 7 - "Play Billing Integration"
Cohesion: 0.10
Nodes (36): androidpublisher v3 API, Annual Premium (premium_annually), Billing testing flow (debug build), BillingProducts.kt, budgetella_functions/play-billing.js, Common Play Billing errors table, Firebase Admin service account, Free-trial eligibility rule (+28 more)

### Community 8 - "Room Budget DAO"
Cohesion: 0.10
Nodes (9): BudgetDao, Flow, BudgetEntity, CategorySlug, BudgetRepository, CategorySlug, Flow, RoomBudgetRepository (+1 more)

### Community 9 - "Android Money Formatting"
Cohesion: 0.08
Nodes (10): currencySymbol(), formatMoney(), Money, AddEditTransactionViewModel, RecurringInterval, StateFlow, TransactionType, ViewModel (+2 more)

### Community 10 - "Budgi AI Chat (iOS)"
Cohesion: 0.11
Nodes (21): BudgiChatService, BudgiMessage, .tagColor, BudgiView, .body, .chatInputBar, .header, .insights (+13 more)

### Community 11 - "Cloud Functions Entrypoint"
Cohesion: 0.09
Nodes (31): admin, cancelSubscription(), cors, createCheckoutSession(), defaultCategoryMap, functions, getSubscriptionStatus(), getTranslations() (+23 more)

### Community 12 - "iOS Voice Entry"
Cohesion: 0.09
Nodes (23): Float, SpeechEntryRecognizer, Bool, Color, Phase, VoiceEntryContent, .actionSection, .body (+15 more)

### Community 13 - "iOS Tab Navigation"
Cohesion: 0.10
Nodes (24): Gesture, Int, AppTab, ai, home, list, stats, CustomTabBar (+16 more)

### Community 14 - "iOS Home Widget"
Cohesion: 0.11
Nodes (24): BudgetellaEntry, BudgetellaProvider, BudgetellaWidget, .body, BudgetellaWidgetBundle, .body, BudgetellaWidgetView, .body (+16 more)

### Community 15 - "iOS Edit Transaction Sheet"
Cohesion: 0.09
Nodes (24): EditTransactionSheet, .amountColor, .amountDisplay, .body, .categoryChipsRow, .currencySymbol, .dateRow, .editCategoryPicker (+16 more)

### Community 16 - "Legacy Webapp Docs"
Cohesion: 0.11
Nodes (30): api (legacy PHP), Budgetella: Privacy-First Personal Finance Tracker, CONTRIBUTING.md reference, Dashboard UI, date-fns, Dexie.js (IndexedDB), docs/firebase-deployment.md, docs/firebase-setup-guide.md (+22 more)

### Community 17 - "iOS Data Models"
Cohesion: 0.12
Nodes (9): AuthenticationServices, CryptoKit, FirebaseAuth, FirebaseFirestore, Foundation, GoogleSignIn, Notification.Name, SwiftData (+1 more)

### Community 18 - "iOS Firestore Sync"
Cohesion: 0.18
Nodes (12): CollectionReference, DocumentChange, DocumentReference, TransactionType, expense, income, FirestoreService, Any (+4 more)

### Community 19 - "iOS Stats Aggregation"
Cohesion: 0.14
Nodes (17): Bool, UUID, Transaction, .isRecurringTemplate, .signedAmount, Decimal, .compactTRY, .currencySymbol (+9 more)

### Community 20 - "Android Dashboard Screen"
Cohesion: 0.22
Nodes (28): moneyText(), AIInsightCard(), AvatarSmall(), BalanceHero(), DashboardMainCard(), DashboardScreen(), EmbeddedFlowChart(), EmptyDashboardCard() (+20 more)

### Community 21 - "Android Project Structure"
Cohesion: 0.07
Nodes (29): 77 Kotlin files (single-module project), BudgetellaApplication.kt, core/design, Cross-platform Firestore schema parity note, data/auth, data/backup, data/model (Money helper), data/prefs (DataStore) (+21 more)

### Community 22 - "iOS Profile & Password"
Cohesion: 0.09
Nodes (24): ChangePasswordView, .body, .isValid, .passwordStrength, .strengthColor, .strengthLabel, ProfileView, .accountActions (+16 more)

### Community 23 - "Monorepo Layout"
Cohesion: 0.09
Nodes (28): budgetella_functions, firebase.json, web Subproject, Android applicationId com.budgetella.app, api/ (legacy PHP), budgetella_functions/ (active production backend), budgetella-icon/, budgetella_screens/ (+20 more)

### Community 24 - "Android Design System"
Cohesion: 0.14
Nodes (21): Spacing, brand(), BrandText, BottomTabBar(), FabButton(), AppTab, Modifier, TabPill() (+13 more)

### Community 25 - "iOS Dashboard Cards"
Cohesion: 0.10
Nodes (26): DailyFlowChart, .body, DashboardMainCard, .availableMonths, .body, .isCurrentPeriod, .isNegativeNet, .monthNet (+18 more)

### Community 26 - "Android Data Repository"
Cohesion: 0.13
Nodes (7): GoalDao, Flow, GoalEntity, GoalRepository, Flow, RoomGoalRepository, GoalTemplate

### Community 27 - "Android Data Repository"
Cohesion: 0.12
Nodes (7): Flow, UserDao, SubscriptionType, UserEntity, Flow, RoomUserRepository, UserRepository

### Community 28 - "iOS Features Dashboard"
Cohesion: 0.17
Nodes (15): Identifiable, DailyFlowPoint, DashboardViewModel, .greeting, monthFull(), MonthlyFlowPoint, monthShort(), DailyFlowPoint (+7 more)

### Community 29 - "Android Data Repository"
Cohesion: 0.12
Nodes (8): NotificationRecordEntity, Flow, NotificationRepository, RoomNotificationRepository, StateFlow, ViewModel, NotificationInboxState, NotificationInboxViewModel

### Community 30 - "iOS Core Models"
Cohesion: 0.11
Nodes (24): Codable, AppCurrency, eur, gbp, .symbol, tryLira, usd, AppLanguage (+16 more)

### Community 31 - "iOS Features Transactions"
Cohesion: 0.14
Nodes (19): CategoryFilterSheet, .body, Bool, Color, Int, String, TransactionYearGroup, Void (+11 more)

### Community 32 - "Design Spec: UI Flow"
Cohesion: 0.12
Nodes (25): AI-First Assistant (Budgi) Rationale, Budgi · Android, Dashboard · Android (Material 3), Yeni İşlem · Android, Budgi Sohbet Ekranı (AI Chat Assistant), Kamera/OCR Fiş Tarama (Receipt Scan), Dashboard Landing (Above-the-fold), Dashboard Scroll Full View (+17 more)

### Community 33 - "iOS Core Services"
Cohesion: 0.13
Nodes (12): ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding, AuthStateDidChangeListenerHandle, AuthService, .displayName, .email, .isEmailProvider, .isSignedIn (+4 more)

### Community 34 - "iOS Core Models"
Cohesion: 0.10
Nodes (22): .badge, .isUnlocked, BadgeType, budgetMaster, categoryExplorer, .defaultColorHex, .defaultIcon, .descriptionKey (+14 more)

### Community 35 - "iOS Core Models"
Cohesion: 0.11
Nodes (21): NotificationKind, achievement, anomaly, budgetAlert, goalMilestone, systemMessage, weeklyDigest, NotificationRecord (+13 more)

### Community 36 - "iOS Core Services"
Cohesion: 0.14
Nodes (14): ProductID, .all, SubscriptionService, .isPremium, Bool, ModelContext, Never, Set (+6 more)

### Community 37 - "iOS Design System Typography"
Cohesion: 0.10
Nodes (21): BrandFont, body, callout, caption, caption2, display, displayHero, footnote (+13 more)

### Community 38 - "Android Data Model"
Cohesion: 0.09
Nodes (20): categoryStringRes(), displayCategoryName(), android, CategorySlug, CategorySlug, Bills, Education, Entertainment (+12 more)

### Community 39 - "Android Android"
Cohesion: 0.13
Nodes (23): AndroidX Biometric, AndroidX SplashScreen, app/build.gradle.kts, app/google-services.json (gitignored), build.gradle.kts (root), CLAUDE.md (Android), Coil 3, compileSdk 35 / minSdk 26 / targetSdk 35 (+15 more)

### Community 40 - "iOS Design System Environment Keys"
Cohesion: 0.10
Nodes (13): AppIntents, Charts, EnvironmentKey, FirebaseCore, Notification.Name, EnvironmentValues, .hideAmounts, HideAmountsKey (+5 more)

### Community 41 - "iOS Features Auth"
Cohesion: 0.15
Nodes (8): Bool, AuthViewModel, Bool, Error, Never, String, Task, Void

### Community 42 - "iOS Features Auth"
Cohesion: 0.09
Nodes (20): AuthTextField, .body, Bool, LocalizedStringKey, String, Void, PasswordStrength, .color (+12 more)

### Community 43 - "iOS Features Dashboard"
Cohesion: 0.13
Nodes (18): Category, .localizedDisplayName, Bool, Int, String, TransactionType, UUID, DashboardView (+10 more)

### Community 44 - "iOS Features Quick Entry"
Cohesion: 0.12
Nodes (17): ManualEntryContent, .aiSuggestionRow, .amountColor, .amountDisplay, .body, .categoryChipsRow, .currencySymbol, .dateRow (+9 more)

### Community 45 - "iOS Features Settings"
Cohesion: 0.15
Nodes (14): CurrencyPickerSheet, .body, .filteredCurrencies, LanguagePickerSheet, .body, AppCurrency, AppLanguage, AppTheme (+6 more)

### Community 46 - "iOS Features Settings"
Cohesion: 0.15
Nodes (16): SettingsView, .appVersion, .body, .importRowTitle, .initialsCircle, .preferredScheme, .premiumRow, .profileCard (+8 more)

### Community 47 - "iOS Core AI"
Cohesion: 0.10
Nodes (21): CategorySlug, bills, .defaultColorHex, .defaultIcon, education, entertainment, food, freelance (+13 more)

### Community 48 - "iOS Core Services"
Cohesion: 0.14
Nodes (12): NotificationService, Int, String, URL, Void, Messaging, MessagingDelegate, UNNotification (+4 more)

### Community 49 - "iOS Features Dashboard"
Cohesion: 0.19
Nodes (12): AIInsightCard, .body, .dataSignature, IncomeExpenseBarChart, .body, .expenseLabel, .incomeLabel, Color (+4 more)

### Community 50 - "iOS Features Paywall"
Cohesion: 0.13
Nodes (18): PaywallView, .ctaButtonTitle, .ctaSection, .featureList, .finePrint, .heroSection, .lifetimeDisplayPrice, .monthlyDisplayPrice (+10 more)

### Community 51 - "Monorepo Agent Notes"
Cohesion: 0.12
Nodes (19): Android applicationId com.budgetella.app, Android Subproject, Budgetella, budgetella.app domain, budgetella-icon, budgetella_screens, claude_design, docs/ folder (+11 more)

### Community 52 - "Android Data Auth"
Cohesion: 0.19
Nodes (10): AuthResult, Failure, Success, FirebaseAuthRepository, ComponentActivity, Flow, StateFlow, UserCancelledException (+2 more)

### Community 53 - "Android Ui Paywall"
Cohesion: 0.19
Nodes (18): CloseRow(), CtaBlock(), FeatureList(), FeatureRow(), Hero(), PaywallBody(), PaywallScreen(), PlanCard() (+10 more)

### Community 54 - "Android Ui Paywall"
Cohesion: 0.14
Nodes (14): Error, Idle, Activity, ProductDetails, StateFlow, ViewModel, Loading, PaywallPlan (+6 more)

### Community 55 - "Android Ui Budgi"
Cohesion: 0.16
Nodes (10): BudgiMessage, BudgiPrefs, BudgiViewModel, Flow, Preferences, StateFlow, ViewModel, Role (+2 more)

### Community 56 - "Android Ui Main"
Cohesion: 0.22
Nodes (17): Add, AddEditTrigger, BlobOption(), Edit, FabBlobMenu(), ImageVector, MainScaffold(), CurrencyPickerSheet() (+9 more)

### Community 57 - "iOS Core Services"
Cohesion: 0.14
Nodes (17): BackupTransaction, Decodable, BackupFile, BackupImportService, BackupTransaction, ImportError, .errorDescription, fileTooLarge (+9 more)

### Community 58 - "iOS Design System Budgetella Logo View"
Cohesion: 0.12
Nodes (15): BudgetellaLogoView, .body, .cornerRadius, .dotSize, .fontSize, CGFloat, AuthFaceIDLockView, .body (+7 more)

### Community 59 - "Category Translation Job"
Cohesion: 0.16
Nodes (17): budgetella_functions/deploy-and-run-update.js, Category Selection Issue (bug fix), Category Translation Issue (bug fix), Category update troubleshooting guide, deploy-app.js, Firestore users/{user-id}/categories & transactions collections, Manual category update (alternative), updateAllCategoryTranslations Cloud Function (+9 more)

### Community 60 - "Android Core Design"
Cohesion: 0.20
Nodes (5): BrandColor, Color, BiometricLockScreen(), AuthenticationCallback, BiometricPrompt

### Community 61 - "Android Data Prefs"
Cohesion: 0.14
Nodes (8): Keys, Flow, Preferences, NotificationPrefs, State, StateFlow, ViewModel, NotificationSettingsViewModel

### Community 62 - "Android Data Repository"
Cohesion: 0.20
Nodes (7): Activity, Flow, ProductDetails, Result, StubSubscriptionRepository, SubscriptionRepository, SubscriptionModule

### Community 63 - "Android Ui App Root View Model"
Cohesion: 0.13
Nodes (13): AppRootState, Auth, BiometricLock, Main, Onboarding, Splash, SyncingInitial, Walkthrough (+5 more)

### Community 64 - "Android Ui Budgi"
Cohesion: 0.22
Nodes (9): Accent, Expense, Income, Info, Primary, Warning, BudgiInsight, BudgiInsightEngine (+1 more)

### Community 65 - "Android Ui Quickentry"
Cohesion: 0.19
Nodes (17): doParseAndNavigate(), Error, Idle, Color, Modifier, VoiceParser, Listening, Parsed (+9 more)

### Community 66 - "iOS Features Quick Entry"
Cohesion: 0.14
Nodes (16): GeminiReceiptParser, OCRError, .errorDescription, invalidURL, missingAPIKey, noAmountFound, parseError, serverError (+8 more)

### Community 67 - "iOS Features Settings"
Cohesion: 0.18
Nodes (12): AddCategorySheet, .body, CategoryManagementView, .body, .expenseCategories, .incomeCategories, .premiumBanner, EditCategorySheet (+4 more)

### Community 68 - "Android Ui Settings"
Cohesion: 0.21
Nodes (7): AppCurrency, AppLanguage, AppTheme, StateFlow, ViewModel, SettingsState, SettingsViewModel

### Community 69 - "iOS Core Intents"
Cohesion: 0.13
Nodes (14): AppIntent, AppShortcut, AppShortcutsProvider, IntentResult, AddTransactionIntent, .parameterSummary, Double, String (+6 more)

### Community 70 - "iOS Core Services"
Cohesion: 0.12
Nodes (17): AuthError, .errorDescription, googleTokenMissing, noRootViewController, noUser, InsightError, consentRequired, .errorDescription (+9 more)

### Community 71 - "iOS Features Quick Entry"
Cohesion: 0.14
Nodes (12): .body, QuickEntryViewModel, .amountDecimal, .canSave, .fracPart, .wholePart, Bool, ModelContext (+4 more)

### Community 72 - "iOS Misc"
Cohesion: 0.15
Nodes (17): Bundle ID com.ozankilic.budgetella, GoogleService-Info.plist (gitignored), Budgetella iOS Claude Notes, Reference projects (TealSky, Reelight, Kelimoji), Secrets.xcconfig (gitignored), v1.1 Backlog, XcodeGen project generation, Budgetella application target (+9 more)

### Community 73 - "Design Spec: Mobile v1"
Cohesion: 0.17
Nodes (17): Auth Welcome (Social Sign-in Options), Biometric Auth Privacy Rationale (On-Device Face ID), Face ID Lock (App Re-launch), Face ID Kurulum (Post-Signup), Şifremi Unuttum (Forgot Password), Giriş (Login, Face ID Quick Action), OTP Doğrulama (Email Verification), 04 · İzinler (Permissions) (+9 more)

### Community 74 - "Android Ui Auth"
Cohesion: 0.36
Nodes (15): AuthFlow(), AuthFormScaffold(), AuthSwitchFooter(), BrandTextField(), ErrorBanner(), ForgotPasswordScreen(), AuthViewModel, ComponentActivity (+7 more)

### Community 75 - "Android Ui Onboarding"
Cohesion: 0.23
Nodes (15): isNotifGranted(), isPermissionGranted(), android, androidx, ImageVector, OnboardingFlow(), OnboardingPage, Permissions (+7 more)

### Community 76 - "Android Ui Settings"
Cohesion: 0.28
Nodes (15): IconBadge(), androidx, Color, ImageVector, Modifier, NavigationRow(), ProfileAvatar(), ProfileCard() (+7 more)

### Community 77 - "Android Ui Stats"
Cohesion: 0.24
Nodes (15): BreakdownList(), CategoryRow(), ChangePill(), DonutCanvas(), DonutWithTotal(), EmptyStats(), CategoryStat, Color (+7 more)

### Community 78 - "iOS Design System Brand Alert"
Cohesion: 0.23
Nodes (11): ButtonRole, BrandAlertButton, BrandAlertOverlay, .body, Binding, Bool, Color, LocalizedStringKey (+3 more)

### Community 79 - "Design Spec: Tier 3"
Cohesion: 0.16
Nodes (16): İstatistik · Derin (Deep Stats & Forecast), Yedek İçe Aktar (Backup Import, .json Migration), Webapp-to-Native Data Migration Rationale, Empty State · İstatistik, Veri Dışa Aktar (Data Export, KVKK Madde 11), Export Premium Gate (7-Day Trial), Export Başlangıç (Format + Date Range), Export Başarı State (+8 more)

### Community 80 - "Legacy Contributing Guide"
Cohesion: 0.16
Nodes (14): FinVault (old app name), OLD/ archive, Bug reporting guidelines, Code of Conduct, Development setup (npm install, npm run dev), Documentation guidelines, Enhancement suggestions guidelines, FinVault (project name in this doc) (+6 more)

### Community 81 - "Android Data Billing"
Cohesion: 0.26
Nodes (6): Flow, ProductDetails, PlayBillingSubscriptionRepository, BillingClient, Purchase, PurchasesUpdatedListener

### Community 82 - "Android Di Data Module"
Cohesion: 0.24
Nodes (5): BudgetellaDatabase, DatabaseModule, Context, Migration, RoomDatabase

### Community 83 - "Android Data Local"
Cohesion: 0.19
Nodes (7): AppSettingsDao, Flow, AppSettingsEntity, AppCurrency, AppLanguage, AppTheme, Flow

### Community 84 - "Android Ui Auth"
Cohesion: 0.24
Nodes (4): AuthViewModel, ComponentActivity, StateFlow, ViewModel

### Community 85 - "iOS Core Models"
Cohesion: 0.13
Nodes (14): CaseIterable, RecurringInterval, daily, .localizedLabel, monthly, weekly, yearly, LocalizedStringKey (+6 more)

### Community 86 - "Docs Aso-copy-en"
Cohesion: 0.15
Nodes (15): App Store (iOS) EN listing, Google Play (Android) EN listing, Budgetella ASO Copy (EN) v1.1.0, International rollout gating (v1.1+, currently inactive), EN ASO keyword strategy, EN Premium pricing ($4.99/mo, $39.99/yr), App Store (iOS) TR listing, Google Play (Android) TR listing (+7 more)

### Community 87 - "iOS Features Quick Entry"
Cohesion: 0.22
Nodes (9): CameraPickerView, Coordinator, Any, Context, Void, UIImage, UIImagePickerController, UIImagePickerControllerDelegate (+1 more)

### Community 88 - "iOS Features Stats"
Cohesion: 0.18
Nodes (11): StatsView, .body, .emptyStatsState, .genelContent, .incomeExpenseToggle, .monthPicker, .segmentPicker, Bool (+3 more)

### Community 89 - "iOS Features Walkthrough"
Cohesion: 0.21
Nodes (10): Color, LocalizedStringKey, String, Void, WalkthroughPage, WalkthroughView, .body, .pageDots (+2 more)

### Community 90 - "Android Ui App Root"
Cohesion: 0.25
Nodes (8): BudgetellaTheme(), MainActivity, AppRoot(), AppRootEntryPoint, rememberBackupImportLauncher(), SplashScreen(), SyncingInitialScreen(), AppCompatActivity

### Community 91 - "Android Ui Dashboard"
Cohesion: 0.23
Nodes (7): DailyFlowPoint, DashboardViewModel, StateFlow, ViewModel, YearMonth, MonthlyFlowPoint, TopCategoryStat

### Community 92 - "iOS Content View"
Cohesion: 0.16
Nodes (11): AppState, auth, biometricLock, main, onboarding, splash, walkthrough, KeyboardPrewarmView (+3 more)

### Community 93 - "iOS Core Models"
Cohesion: 0.16
Nodes (13): Goal, .dailyRequiredAmount, .daysRemaining, .isCompleted, .progressPercentage, .remainingAmount, Bool, Double (+5 more)

### Community 94 - "iOS Features Quick Entry"
Cohesion: 0.16
Nodes (12): CategoryPickerView, .body, EntryMode, camera, manual, voice, QuickEntryView, .hasContent (+4 more)

### Community 95 - "iOS Features Settings"
Cohesion: 0.21
Nodes (9): SafariSheet, ShareSheet, Any, Context, URL, SafariServices, SFSafariViewController, UIActivityViewController (+1 more)

### Community 96 - "iOS Features Transactions"
Cohesion: 0.21
Nodes (11): Int, String, TransactionDayGroup, TransactionType, TransactionYearGroup, UUID, TransactionDayGroup, TransactionMonthGroup (+3 more)

### Community 97 - "Android Data Model"
Cohesion: 0.17
Nodes (9): RecurringInterval, Daily, Monthly, Weekly, Yearly, TransactionStatus, Completed, Pending (+1 more)

### Community 99 - "Android Ui Settings"
Cohesion: 0.32
Nodes (12): AddCategorySheet(), categoryIcon(), CategoryManagementSheet(), CategoryRow(), CategorySection(), iconForCustom(), Color, ImageVector (+4 more)

### Community 100 - "Android Ui Settings"
Cohesion: 0.35
Nodes (12): Achievement, AchievementsGrid(), AchievementTile(), Avatar(), buildAchievements(), androidx, ImageVector, Modifier (+4 more)

### Community 101 - "Android Ui Stats"
Cohesion: 0.27
Nodes (8): CategoryStat, StateFlow, TransactionType, ViewModel, YearMonth, StatsState, StatsUiState, StatsViewModel

### Community 102 - "Android Ui Transactions"
Cohesion: 0.24
Nodes (11): DatePill(), formatDateShort(), IntervalChip(), intervalLabelRes(), Color, Modifier, RecurringInterval, TransactionType (+3 more)

### Community 103 - "Legacy API CLAUDE"
Cohesion: 0.18
Nodes (13): FinVault (old app name), .htaccess (api), mail-test.php, OLD/CLAUDE.md, OLD/ (archived webapp), Legacy PHP Server-Sync API, send-feedback.php, test.php (+5 more)

### Community 104 - "iOS Budgetella App"
Cohesion: 0.23
Nodes (8): App, BudgetellaApp, Locale, ModelContext, .body, AuthView, Void, Scene

### Community 105 - "iOS Core Models"
Cohesion: 0.19
Nodes (12): SubscriptionRecord, .isActiveOrGrace, .isMonthly, .isYearly, .status, SubscriptionStatus, active, expired (+4 more)

### Community 106 - "iOS Core Services"
Cohesion: 0.33
Nodes (5): AIInsight, GeminiInsightService, Data, String, .displayInsight

### Community 107 - "iOS Features Settings"
Cohesion: 0.19
Nodes (11): DeleteAccountView, .backupNudge, .body, .canDelete, .confirmKeyword, .dangerZone, .dataLossSection, .reAuthSheet (+3 more)

### Community 108 - "Android Data Auth"
Cohesion: 0.20
Nodes (4): AuthRepository, androidx, Flow, StateFlow

### Community 109 - "Android Data Backup"
Cohesion: 0.27
Nodes (6): BackupCategory, BackupDocument, BackupService, BackupTransaction, ImportResult, ImportResult

### Community 110 - "Android Data Remote"
Cohesion: 0.17
Nodes (4): TransactionType, Expense, Income, FirestoreMappers

### Community 111 - "Android Data Prefs"
Cohesion: 0.23
Nodes (6): Keys, Flow, Preferences, UserPrefs, defaultBackupFilename(), rememberBackupExportLauncher()

### Community 112 - "Android Data Repository"
Cohesion: 0.17
Nodes (4): AppSettingsRepository, AppCurrency, AppLanguage, AppTheme

### Community 114 - "Android Ui Quickentry"
Cohesion: 0.24
Nodes (11): CameraEntrySheet(), CameraPhase, CameraStatusPill(), CaptureButton(), Error, Modifier, NoPerm, Preview (+3 more)

### Community 115 - "iOS Core Models"
Cohesion: 0.21
Nodes (11): SubscriptionType, lifetime, monthly, none, yearly, Bool, Int, User (+3 more)

### Community 116 - "iOS Core Services"
Cohesion: 0.30
Nodes (6): Key, biometricEnabled, firebaseIdToken, firebaseUid, KeychainHelper, Bool

### Community 117 - "iOS Features Settings"
Cohesion: 0.20
Nodes (8): NotificationSettingsView, .body, Binding, Bool, Color, LocalizedStringKey, String, UNAuthorizationStatus

### Community 118 - "iOS Features Quick Entry"
Cohesion: 0.24
Nodes (8): CameraEntryContent, .body, .photoSourceButtons, .receiptDisplay, .statusText, Phase, .descriptionField, PhotosPickerItem

### Community 119 - "Android Data Model"
Cohesion: 0.18
Nodes (7): BillingProducts, SubscriptionType, SubscriptionType, Lifetime, Monthly, None, Yearly

### Community 120 - "Android Data Billing"
Cohesion: 0.25
Nodes (4): Activity, Result, BillingClientStateListener, BillingClientStateListener

### Community 121 - "Android Data Model"
Cohesion: 0.18
Nodes (8): AppLanguage, English, German, Turkish, AppTheme, Dark, Light, System

### Community 122 - "Android Data Remote"
Cohesion: 0.25
Nodes (9): Candidate, Content, GeminiChatService, GeminiContent, GeminiPart, GeminiRequest, GeminiResponse, GenerationConfig (+1 more)

### Community 123 - "Android Ui Transactions"
Cohesion: 0.29
Nodes (10): dayHeader(), EmptyState(), FilterPill(), androidx, Modifier, TransactionDayGroup, TransactionType, monthName() (+2 more)

### Community 124 - "iOS Features Quick Entry"
Cohesion: 0.33
Nodes (5): AVFoundation, Int, String, VoiceParser, Speech

### Community 125 - "iOS Core Services"
Cohesion: 0.27
Nodes (10): Encodable, BackupExportService, ExportFile, ExportTransaction, Bool, Double, Int, ModelContext (+2 more)

### Community 126 - "iOS Features Settings"
Cohesion: 0.27
Nodes (8): SubscriptionView, .activePlanLabel, .body, .statusCard, Color, LocalizedStringKey, String, Void

### Community 127 - "Design Spec: Mobile v2"
Cohesion: 0.20
Nodes (11): Profil (Streak & Achievements), Ayarlar (Settings List), Şifre Değiştir (Change Password), Para Birimi Picker (Bottom Sheet), Hesabı Sil (Delete Account), Profili Düzenle (Edit Profile), KVKK + Apple 5.1.1(v) Account Deletion Compliance, Dil Picker (Bottom Sheet) (+3 more)

### Community 128 - "Firebase Email Setup"
Cohesion: 0.27
Nodes (10): budgetella_functions deploy (npm run deploy), CORS configuration, Feedback form email functionality, Firebase Blaze plan, Firebase Cloud Functions, Firebase Functions 1st Gen, firebase functions:config:set email credentials, Gmail App Password (+2 more)

### Community 129 - "Watch-firestore"
Cohesion: 0.27
Nodes (10): { execSync }, fs, getAccessToken(), https, httpsGet(), httpsPost(), main(), os (+2 more)

### Community 130 - "Android Data Auth"
Cohesion: 0.20
Nodes (10): AuthError, EmailAlreadyInUse, InvalidCredentials, InvalidEmail, NetworkUnavailable, NotConfigured, RecentLoginRequired, Unknown (+2 more)

### Community 132 - "Android Data Model"
Cohesion: 0.20
Nodes (8): GoalTemplate, Custom, Education, EmergencyFund, Home, Technology, Vacation, Vehicle

### Community 133 - "Android Ui Budgi"
Cohesion: 0.40
Nodes (9): AssistantBubble(), BudgiScreen(), Composer(), Header(), BudgiMessage, Modifier, MessageBubble(), TypingIndicator() (+1 more)

### Community 134 - "Android Ui Transactions"
Cohesion: 0.31
Nodes (9): CategoryGrid(), CategoryGlyph(), formatAmount(), formatTime(), iconForSlug(), CategorySlug, Color, ImageVector (+1 more)

### Community 135 - "Android Ui Transactions"
Cohesion: 0.27
Nodes (6): StateFlow, TransactionType, TransactionYearGroup, ViewModel, TransactionsUiState, TransactionsViewModel

### Community 136 - "Functions Deploy-functions"
Cohesion: 0.24
Nodes (9): askQuestion(), colors, execCommand(), { execSync }, fs, main(), path, readline (+1 more)

### Community 137 - "Docs Godaddy-deployment"
Cohesion: 0.24
Nodes (10): Android/README.md (henüz yok, oluşturulmalı), /docs Setup Rehberleri Overview, npm run build → dist/, GoogleDriveContext.tsx production credentials, Deploying finVault to GoDaddy Web Hosting, .htaccess SPA rewrite rules, Google Drive API Key, src/context/GoogleDriveContext.tsx (+2 more)

### Community 138 - "Docs Firebase-deployment"
Cohesion: 0.22
Nodes (10): Google + Apple sign-in providers, budgetella.app custom domain setup, firebase.rules Firestore security rules, Firebase Deployment Guide (old webapp), Firebase Hosting deploy (dist/), src/firebase/config.ts, Step-by-Step Firebase Setup Guide, c:/Projects/finVault local path reference (+2 more)

### Community 139 - "iOS Core Helpers"
Cohesion: 0.20
Nodes (8): FirebaseMessaging, AppDelegate, Data, Error, NSObject, UIApplication, UIApplicationDelegate, UIKit

### Community 140 - "iOS Core Models"
Cohesion: 0.20
Nodes (10): GoalTemplate, custom, .defaultIcon, education, emergencyFund, home, .localizedKey, technology (+2 more)

### Community 141 - "iOS Features Auth"
Cohesion: 0.22
Nodes (9): AuthSignUpView, .tosAttributedString, Field, email, name, password, AttributedString, AuthViewModel (+1 more)

### Community 142 - "iOS Features Stats"
Cohesion: 0.44
Nodes (3): BudgiInsight, BudgiInsightEngine, .isEnglish

### Community 143 - "iOS Features Transactions"
Cohesion: 0.22
Nodes (8): Color, String, Void, TransactionRow, .body, .categoryIcon, .iconBackgroundColor, .rowContent

### Community 144 - "Design Spec: Tier 3"
Cohesion: 0.29
Nodes (10): Kategoriler (Categories, Premium Lock), İşlem Listesi (Transaction List), Empty State · Kategoriler (18 Default Categories), Empty State · İşlemler (3 Entry Suggestions), Transaction Detail / Edit Sheet, Sil Onayı (Delete Confirmation Action Sheet), Detay Mode (Transaction Detail State), Edit Mode (Transaction Edit State) (+2 more)

### Community 145 - "Design Spec: Mobile v2"
Cohesion: 0.24
Nodes (10): Bütçe Kur (Budget Setup), Empty State · Dashboard (First Open), Hedef Oluştur (Goal Setup), Yardım (Help Screen), Splash & İlk Açılış (Launch Screen), Tier 1/2/3 Launch Prioritization Rationale, Yiyecek Bütçesi Detail (85% Ring + Pace Chart), Bütçe Detay + Hedef Detay/Edit (+2 more)

### Community 146 - "Android Budgetella Application"
Cohesion: 0.31
Nodes (3): BudgetellaApplication, DataInitializer, Application

### Community 147 - "Android Data Local"
Cohesion: 0.22
Nodes (7): NotificationKind, Achievement, Anomaly, BudgetAlert, GoalMilestone, SystemMessage, WeeklyDigest

### Community 148 - "Android Data Remote"
Cohesion: 0.33
Nodes (4): BudgetellaMessagingService, FirebaseFirestore, FirebaseMessagingService, RemoteMessage

### Community 149 - "Android Ui Main"
Cohesion: 0.22
Nodes (9): SecondarySheet, Categories, Currency, DeleteAccount, Inbox, Language, NotificationSettings, Profile (+1 more)

### Community 150 - "Android Ui Settings"
Cohesion: 0.31
Nodes (5): CategoryManagementState, CategoryManagementViewModel, StateFlow, TransactionType, ViewModel

### Community 151 - "Android Ui Settings"
Cohesion: 0.42
Nodes (8): Divider(), Color, ImageVector, Modifier, NotificationSettingsSheet(), NotifToggleRow(), Section(), SectionHeader()

### Community 152 - "Android Android"
Cohesion: 0.22
Nodes (9): Android skeleton status (SADECE İSKELET), iOS-Android architecture parity mapping, Yapılması Gerekenler (ordered TODO list), data/remote, M5 - Budgi AI, M6 - Settings, M7 - Notifications, M8 - Paywall stub (+1 more)

### Community 153 - "Functions DEPLOY"
Cohesion: 0.25
Nodes (9): 1st-gen Firebase Functions runtime choice, Deployment env vars (STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, EMAIL_USER, EMAIL_PASSWORD), Firebase Functions Deployment Guide, Interactive Deployment (deploy:interactive), Node.js 18 runtime note, Budgetella Firebase Cloud Functions README, src/components/settings/FeedbackDialog.tsx, Gmail App Password setup (+1 more)

### Community 154 - "Functions CLAUDE"
Cohesion: 0.25
Nodes (9): cancelSubscription, createCheckoutSession, deploy.js / deploy-functions.js / deploy-and-run-update.js, getSubscriptionStatus, handleStripeWebhook, Budgetella Cloud Functions Overview, Stripe integration, updateAllCategoryTranslations (+1 more)

### Community 155 - "iOS Content View"
Cohesion: 0.22
Nodes (8): .body, LanguageSwitchSkeletonView, .body, ContentView, .biometricLockEnabled, .colorScheme, Bool, ColorScheme

### Community 156 - "iOS Core AI"
Cohesion: 0.44
Nodes (5): CategoryPrediction, KeywordCategorizer, Double, Int, String

### Community 157 - "iOS Core Helpers"
Cohesion: 0.25
Nodes (7): LocaleHelper, .currentLanguageCode, .currentLocale, .isEnglish, Bool, Locale, String

### Community 158 - "iOS Features Auth"
Cohesion: 0.25
Nodes (8): AuthWelcomeView, .appIcon, .body, .googleLogo, .tosAttributedString, AttributedString, AuthViewModel, Void

### Community 159 - "Design Spec: Mobile v2"
Cohesion: 0.28
Nodes (9): Freemium Pricing Model Rationale ($1/mo · $10 Lifetime), Stratejik Paywall Modal (1-Month Limit), Tam Ekran Premium Paywall, Apple-Mandated Restore Purchases Flow Rationale, Restore Purchases · Loading, Restore Purchases · Success, Aboneliğim (Subscription Management), H1 · Paywall Bottom Sheet (+1 more)

### Community 160 - "Design Spec: Tier 3"
Cohesion: 0.25
Nodes (9): Bildirim Kutusu (Notification Inbox), Bildirim Ayarları (Notification Settings), Gizlilik Politikası (Privacy Policy Reader), Çıkış Onayı (Sign Out Native Alert), Pazar 21:00 Weekly Summary Push Target Rationale, Haftalık Özet (Weekly Summary Push), Anomalili Hafta State, İlk Hafta Empty State (+1 more)

### Community 161 - "Send-test-push"
Cohesion: 0.31
Nodes (8): { execSync }, fs, https, httpsGet(), httpsPost(), main(), os, refreshViaFirebaseCLI()

### Community 162 - "Android Data Auth"
Cohesion: 0.29
Nodes (4): AuthState, SignedIn, SignedOut, Unknown

### Community 163 - "Android Ui Quickentry"
Cohesion: 0.32
Nodes (3): VoiceRecognitionState, Bundle, SpeechRecognizer

### Community 164 - "iOS Features Auth"
Cohesion: 0.25
Nodes (8): Equatable, AuthScreen, faceIDSetup, forgotPassword, otp, signIn, signUp, welcome

### Community 165 - "iOS Core Models"
Cohesion: 0.36
Nodes (7): Budget, .isCurrentMonth, .monthKey, Bool, Int, String, UUID

### Community 166 - "iOS Features Auth"
Cohesion: 0.32
Nodes (6): OTPFieldView, .body, .digits, Bool, Int, String

### Community 167 - "Android Di Auth Module"
Cohesion: 0.33
Nodes (3): AuthModule, FirebaseModule, FirebaseFirestore

### Community 169 - "Android Ui Walkthrough"
Cohesion: 0.62
Nodes (6): Hero(), Modifier, PageContent(), PageDots(), WalkthroughPage, WalkthroughScreen()

### Community 170 - "Android Android"
Cohesion: 0.29
Nodes (7): data/local (Room database), M0 - Scaffold, M1 - Data model + persistence, M2 - Authentication, M3 - Transactions CRUD + Firestore sync, M4 - Dashboard + Stats, ui/AppRoot.kt

### Community 171 - "iOS Core Widget"
Cohesion: 0.43
Nodes (5): Bool, Double, ModelContext, WidgetDataManager, WidgetSnapshot

### Community 172 - "iOS Misc"
Cohesion: 0.29
Nodes (7): GeminiInsightService (Gemini 2.0 Flash), RevenueCat → StoreKit 2 decision, v1.0.0 (build 15) release, React Webapp deprecated (v0.x), iOS app architecture (Core/Features/DesignSystem), GeminiInsightService, KeywordCategorizer (TR fallback)

### Community 173 - "Design Spec: UI Flow"
Cohesion: 0.38
Nodes (7): 03 · Para Birimi (Currency Selection), 02 · Özellikler (Features Carousel), 01 · Karşılama (Welcome), 01 · Karşılama (Welcome), 02 · Özellikler (Features Carousel), 03 · Para Birimi, A0 · Launch (Token Check)

### Community 174 - "Android Data Model"
Cohesion: 0.33
Nodes (5): AppCurrency, Eur, Gbp, Try, Usd

### Community 175 - "Android Ui Auth"
Cohesion: 0.33
Nodes (5): AuthMode, ForgotPassword, SignIn, SignUp, Welcome

### Community 176 - "Android Ui Main"
Cohesion: 0.33
Nodes (5): AppTab, Ai, Home, List, Stats

### Community 177 - "Android Ui Settings"
Cohesion: 0.53
Nodes (4): StateFlow, ViewModel, ProfileUiState, ProfileViewModel

### Community 178 - "iOS Core Intents"
Cohesion: 0.33
Nodes (6): AppEnum, DisplayRepresentation, TransactionTypeAppEnum, expense, income, Self

### Community 179 - "iOS Core Services"
Cohesion: 0.33
Nodes (4): ASAuthorization, ASAuthorizationController, ASPresentationAnchor, Error

### Community 180 - "Docs User-guide"
Cohesion: 0.33
Nodes (6): Working with Categories, Dashboard Overview (Income/Expense summary, charts), Data export/import (JSON), FinVault User Guide, Local storage via IndexedDB, Managing Transactions

### Community 181 - "iOS Features Quick Entry"
Cohesion: 0.33
Nodes (6): Phase, error, idle, listening, parsed, parsing

### Community 182 - "Android Data Billing"
Cohesion: 0.50
Nodes (3): connectSuspending(), BillingClientStateListener, BillingResult

### Community 185 - "Android Ui Transactions"
Cohesion: 0.70
Nodes (4): groupedHierarchical(), TransactionDayGroup, TransactionMonthGroup, TransactionYearGroup

### Community 186 - "Functions Deploy-and-run-update"
Cohesion: 0.60
Nodes (4): callUpdateFunction(), executeCommand(), main(), rl

### Community 187 - "iOS Features Paywall"
Cohesion: 0.60
Nodes (3): PaywallModalView, .body, String

### Community 189 - "Android Android"
Cohesion: 0.83
Nodes (3): gradlew script, die(), warn()

### Community 190 - "Docs Server-sync-setup"
Cohesion: 0.67
Nodes (4): data-storage.php, Simple API key authentication, data-storage.php (server sync API), Setting Up Server Sync for finVault

### Community 191 - "Functions Deploy"
Cohesion: 0.50
Nodes (3): { execSync }, fs, path

### Community 192 - "iOS Design System Spacing"
Cohesion: 0.50
Nodes (3): CoreGraphics, Spacing, CGFloat

### Community 193 - "iOS Core Models"
Cohesion: 0.50
Nodes (4): TransactionStatus, completed, pending, planned

## Ambiguous Edges - Review These
- `Android skeleton status (SADECE İSKELET)` → `M8 - Paywall stub`  [AMBIGUOUS]
  Android/README.md · relation: conceptually_related_to
- `Edit Mode (Transaction Edit State)` → `Sil Onayı (Delete Confirmation Action Sheet)`  [AMBIGUOUS]
  budgetella tier 3.pdf · relation: references

## Knowledge Gaps
- **608 isolated node(s):** `English`, `Turkish`, `German`, `Unknown`, `SignedOut` (+603 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1041 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **10 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Android skeleton status (SADECE İSKELET)` and `M8 - Paywall stub`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `Edit Mode (Transaction Edit State)` and `Sil Onayı (Delete Confirmation Action Sheet)`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **Why does `CategoryEntity` connect `Room Category DAO` to `Android Ui Budgi`, `Android Data Remote`, `Android Ui Settings`, `Android Ui Stats`, `Android Data Model`, `Android Ui Transactions`, `Android Ui Transactions`, `Android Money Formatting`, `Android Ui Transactions`, `Android Data Backup`, `Android Data Remote`, `Android Di Data Module`, `Android Ui Settings`, `Android Ui Budgi`, `Android Ui Dashboard`?**
  _High betweenness centrality (0.069) - this node is a cross-community bridge._
- **Why does `SwiftUI` connect `iOS Design System Environment Keys` to `Android Locale Switching`, `iOS Onboarding Flow`, `iOS Auth Views`, `iOS Features Auth`, `iOS Tab Navigation`, `iOS Features Stats`, `iOS Edit Transaction Sheet`, `iOS Data Models`, `iOS Features Transactions`, `iOS Home Widget`, `iOS Profile & Password`, `iOS Dashboard Cards`, `iOS Features Auth`, `iOS Features Transactions`, `iOS Design System Typography`, `iOS Features Auth`, `iOS Features Auth`, `iOS Features Dashboard`, `iOS Features Quick Entry`, `iOS Features Settings`, `iOS Design System Budgetella Logo View`, `iOS Features Paywall`, `iOS Features Quick Entry`, `iOS Features Settings`, `iOS Design System Brand Alert`, `iOS Features Walkthrough`, `iOS Content View`, `iOS Features Quick Entry`, `iOS Features Settings`, `iOS Budgetella App`, `iOS Features Settings`, `iOS Features Quick Entry`?**
  _High betweenness centrality (0.046) - this node is a cross-community bridge._
- **Why does `.body` connect `iOS Features Settings` to `iOS Core Services`, `iOS Features Settings`, `iOS Core Services`, `iOS Features Settings`, `iOS Features Settings`, `iOS Features Paywall`, `Android Dashboard Screen`, `iOS Features Settings`, `iOS Profile & Password`, `iOS Core Services`, `iOS Core Services`, `iOS Features Settings`, `iOS Features Settings`?**
  _High betweenness centrality (0.041) - this node is a cross-community bridge._
- **Are the 155 inferred relationships involving `Text` (e.g. with `.body` and `backButton()`) actually correct?**
  _`Text` has 155 INFERRED edges - model-reasoned connections that need verification._
- **Are the 4 inferred relationships involving `Transaction` (e.g. with `.perform()` and `.importFromURL()`) actually correct?**
  _`Transaction` has 4 INFERRED edges - model-reasoned connections that need verification._
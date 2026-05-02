//
//  BudgiView.swift
//  Budgetella
//
//  AI tab — Budgi finans koçu. Proaktif insight'lar SwiftData'dan hesaplanıyor.
//  Chat (V1.1 premium feature) hâlâ kilitli.
//

import SwiftUI
import SwiftData

struct BudgiView: View {

    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @AppStorage("displayName")    private var displayName    = ""
    @AppStorage("currentUserId") private var currentUserId  = ""
    @Environment(\.hideAmounts) private var hideAmounts

    @State private var aiInsights:          [GeminiInsightService.AIInsight] = []
    @State private var isLoadingAI          = false
    @State private var aiError:             String? = nil
    @State private var subscriptionService  = SubscriptionService()

    private var insights: [BudgiInsight] {
        BudgiInsightEngine.compute(transactions: transactions, categories: categories)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    header

                    Divider().background(BrandColor.borderSubtle)

                    // Insight feed
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            // Greeting
                            assistantBubble {
                                Text(greetingText)
                                    .font(.brand(.body))
                                    .foregroundStyle(BrandColor.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            if insights.isEmpty {
                                emptyInsights
                            } else {
                                ForEach(insights) { insight in
                                    assistantBubble(accent: insight.accentColor) {
                                        insightContent(insight)
                                    }
                                }
                            }

                            // AI insights section
                            if !insights.isEmpty {
                                aiInsightsSection
                            }

                            // Chat premium gate — hide for premium users
                            if !subscriptionService.isPremium {
                                premiumGateCard
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, Spacing.lg)
                        .padding(.bottom, 100)
                    }

                    // Chat input (locked — V1.1)
                    chatInputBar
                }
            }
            .navigationBarHidden(true)
            .task {
                await subscriptionService.setup(userId: currentUserId)
                await loadAIInsights()
            }
        }
    }

    // MARK: - AI insights load

    private func loadAIInsights() async {
        guard !transactions.isEmpty else { return }
        isLoadingAI = true
        aiError = nil
        do {
            aiInsights = try await GeminiInsightService.fetchInsights(
                transactions: transactions,
                categories:   categories
            )
        } catch {
            aiError = error.localizedDescription
        }
        isLoadingAI = false
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [BrandColor.primary, BrandColor.primaryLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 36, height: 36)
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Budgi")
                    .font(.brand(.headline))
                    .foregroundStyle(BrandColor.textPrimary)
                HStack(spacing: 3) {
                    Circle().fill(BrandColor.income).frame(width: 5, height: 5)
                    Text("Senin finans asistanın")
                        .font(.brand(.caption))
                        .foregroundStyle(BrandColor.textTertiary)
                }
            }
            Spacer()
            Text("PREMIUM")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(BrandColor.primary)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, Spacing.md)
        .background(BrandColor.background)
    }

    // MARK: - Insight content

    @ViewBuilder
    private func insightContent(_ insight: BudgiInsight) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: insight.icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(insight.accentColor)
                Text(insight.tag)
                    .font(.brand(.caption))
                    .foregroundStyle(insight.accentColor)
                    .tracking(0.8)
            }
            Text(hideAmounts ? insight.redactedText : insight.text)
                .font(.brand(.footnote))
                .foregroundStyle(BrandColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - AI insights section

    private var aiInsightsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if isLoadingAI {
                assistantBubble {
                    HStack(spacing: Spacing.sm) {
                        ProgressView().tint(BrandColor.primary)
                        Text("Harcamalarını analiz ediyorum…")
                            .font(.brand(.footnote))
                            .foregroundStyle(BrandColor.textTertiary)
                    }
                }
            } else if let err = aiError {
                assistantBubble(accent: BrandColor.expense) {
                    Text(err)
                        .font(.brand(.footnote))
                        .foregroundStyle(BrandColor.expense)
                }
            } else {
                ForEach(aiInsights, id: \.tag) { insight in
                    assistantBubble(accent: accentColor(for: insight.accent)) {
                        aiInsightContent(insight)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .animation(.spring(response: 0.4), value: isLoadingAI)
        .animation(.spring(response: 0.4), value: aiInsights.count)
    }

    @ViewBuilder
    private func aiInsightContent(_ insight: GeminiInsightService.AIInsight) -> some View {
        let color = accentColor(for: insight.accent)
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: insight.icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(color)
                Text(insight.tag)
                    .font(.brand(.caption))
                    .foregroundStyle(color)
                    .tracking(0.8)
                Spacer()
                Text("AI")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(BrandColor.primary.opacity(0.7))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(BrandColor.primary.opacity(0.1))
                    .clipShape(Capsule())
            }
            Text(insight.text)
                .font(.brand(.footnote))
                .foregroundStyle(BrandColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func accentColor(for key: String) -> Color {
        switch key {
        case "income":  return BrandColor.income
        case "expense": return BrandColor.expense
        case "warning": return BrandColor.warning
        case "info":    return BrandColor.info
        default:        return BrandColor.primary
        }
    }

    private var emptyInsights: some View {
        assistantBubble {
            Text("Henüz analiz edebileceğim yeterli veri yok. Birkaç işlem ekledikten sonra buraya gerçek insight'lar gelecek.")
                .font(.brand(.footnote))
                .foregroundStyle(BrandColor.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Greeting

    private var greetingText: String {
        let name = displayName.isEmpty ? "Ozzy" : displayName.components(separatedBy: " ").first ?? displayName
        let cal = Calendar.current
        let hour = cal.component(.hour, from: .now)
        let greeting: String
        switch hour {
        case 5..<12:  greeting = "Günaydın \(name) ☀️"
        case 12..<18: greeting = "İyi günler \(name) 👋"
        case 18..<23: greeting = "İyi akşamlar \(name) 🌙"
        default:       greeting = "Merhaba \(name) 🌙"
        }
        if insights.isEmpty {
            return "\(greeting) Henüz inceleyebileceğim yeterli işlem yok."
        }
        return "\(greeting) Bu ay için \(insights.count) önemli gözlem var:"
    }

    // MARK: - Sub-views

    private func assistantBubble<Content: View>(accent: Color = BrandColor.surface, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [BrandColor.primary, BrandColor.primaryLight],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 28, height: 28)
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading) {
                content()
            }
            .padding(Spacing.md)
            .background(BrandColor.surface.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                    .strokeBorder(accent.opacity(0.3), lineWidth: 1)
            )
            Spacer()
        }
    }

    private var premiumGateCard: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "lock.fill")
                .font(.system(size: 24))
                .foregroundStyle(BrandColor.primary)
            Text("Budgi ile sohbet Premium özelliği")
                .font(.brand(.subheadline))
                .foregroundStyle(BrandColor.textPrimary)
                .multilineTextAlignment(.center)
            Text("Harcamalarını analiz et, sorular sor, finansal hedeflerine ulaş.")
                .font(.brand(.footnote))
                .foregroundStyle(BrandColor.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: Spacing.radiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                .strokeBorder(BrandColor.primary.opacity(0.2), lineWidth: 1)
        )
    }

    private var chatInputBar: some View {
        HStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Text("Budgi'ye soru sor...")
                    .font(.brand(.body))
                    .foregroundStyle(BrandColor.textTertiary)
                Spacer()
                Image(systemName: "mic")
                    .font(.system(size: 16))
                    .foregroundStyle(BrandColor.textTertiary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .background(BrandColor.surface.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusFull))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.radiusFull)
                    .strokeBorder(BrandColor.borderSubtle, lineWidth: 1)
            )

            ZStack {
                Circle()
                    .fill(BrandColor.primary)
                    .frame(width: 40, height: 40)
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, Spacing.sm)
        .padding(.bottom, 28)
        .background(BrandColor.background.opacity(0.95))
        .overlay(alignment: .top) {
            Divider().background(BrandColor.borderSubtle)
        }
        .disabled(!subscriptionService.isPremium)
        .opacity(subscriptionService.isPremium ? 1.0 : 0.6)
    }
}

// MARK: - Insight model

struct BudgiInsight: Identifiable {
    let id = UUID()
    let tag: String
    let icon: String
    let accentColor: Color
    let text: String
    let redactedText: String
}

// MARK: - Insight engine

enum BudgiInsightEngine {

    static func compute(transactions: [Transaction], categories: [Category]) -> [BudgiInsight] {
        let cal = Calendar.current
        let now = Date.now
        let comps = cal.dateComponents([.year, .month], from: now)
        guard let currentStart = cal.date(from: comps),
              let prevStart    = cal.date(byAdding: .month, value: -1, to: currentStart),
              let prevEnd      = cal.date(byAdding: .second, value: -1, to: currentStart)
        else { return [] }

        let currentTxs = transactions.filter { $0.date >= currentStart && $0.date <= now }
        let prevTxs    = transactions.filter { $0.date >= prevStart && $0.date <= prevEnd }

        guard !currentTxs.isEmpty else { return [] }

        var results: [BudgiInsight] = []

        // 1. Monthly savings
        if let savings = savingsInsight(current: currentTxs) {
            results.append(savings)
        }

        // 2. Top spending category
        if let top = topCategoryInsight(current: currentTxs, categories: categories) {
            results.append(top)
        }

        // 3. Month-over-month expense change
        if let mom = monthOverMonthInsight(current: currentTxs, previous: prevTxs) {
            results.append(mom)
        }

        // 4. Biggest single expense
        if let big = biggestExpenseInsight(current: currentTxs) {
            results.append(big)
        }

        // 5. Daily average
        if let daily = dailyAverageInsight(current: currentTxs, start: currentStart, now: now) {
            results.append(daily)
        }

        return results
    }

    private static func savingsInsight(current: [Transaction]) -> BudgiInsight? {
        let income  = current.filter { $0.type == .income  }.reduce(Decimal(0)) { $0 + $1.amount }
        let expense = current.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
        guard income > 0 else { return nil }
        let savings = income - expense
        let isPositive = savings >= 0
        let savingsStr = savings.fullTRY
        let incomeStr  = income.fullTRY
        return BudgiInsight(
            tag: isPositive ? "TASARRUF" : "AÇIK",
            icon: isPositive ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
            accentColor: isPositive ? BrandColor.income : BrandColor.expense,
            text: isPositive
                ? "Bu ay \(incomeStr) gelirinden \(savingsStr) tasarruf ettin. Harika gidişat!"
                : "Bu ay giderlerin gelirini \((-savings).fullTRY) aştı. Dikkat et.",
            redactedText: isPositive ? "Bu ay tasarruf ettin. Harika gidişat!" : "Bu ay giderlerin gelirini aştı. Dikkat et."
        )
    }

    private static func topCategoryInsight(current: [Transaction], categories: [Category]) -> BudgiInsight? {
        let expenses = current.filter { $0.type == .expense }
        guard !expenses.isEmpty else { return nil }
        var dict: [UUID: Decimal] = [:]
        for tx in expenses {
            guard let cat = tx.category else { continue }
            dict[cat.id, default: 0] += tx.amount
        }
        guard let topId = dict.max(by: { $0.value < $1.value })?.key,
              let cat = categories.first(where: { $0.id == topId })
        else { return nil }
        let amount = dict[topId]!
        let total  = expenses.reduce(Decimal(0)) { $0 + $1.amount }
        let pct    = total > 0 ? Int((Double(truncating: (amount / total) as NSDecimalNumber) * 100).rounded()) : 0
        return BudgiInsight(
            tag: "EN YÜKSEK KATEGORİ",
            icon: "chart.pie.fill",
            accentColor: BrandColor.primary,
            text: "\(cat.name) bu ayın en büyük gider kalemi: \(amount.fullTRY) (toplam giderlerin %\(pct)'i).",
            redactedText: "\(cat.name) bu ayın en büyük gider kalemi (toplam giderlerin %\(pct)'i)."
        )
    }

    private static func monthOverMonthInsight(current: [Transaction], previous: [Transaction]) -> BudgiInsight? {
        let cur = current.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
        let prv = previous.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
        guard prv > 0 else { return nil }
        let curD = (cur as NSDecimalNumber).doubleValue
        let prvD = (prv as NSDecimalNumber).doubleValue
        let pct  = ((curD - prvD) / prvD) * 100
        let absP = abs(pct)
        guard absP >= 5 else { return nil }
        let isUp = pct > 0
        return BudgiInsight(
            tag: isUp ? "ARTIŞ" : "AZALIŞ",
            icon: isUp ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
            accentColor: isUp ? BrandColor.expense : BrandColor.income,
            text: "Bu ay giderlerin geçen aya göre %\(String(format: "%.0f", absP)) \(isUp ? "arttı" : "azaldı"): \(cur.fullTRY) → \(prv.fullTRY).",
            redactedText: "Bu ay giderlerin geçen aya göre %\(String(format: "%.0f", absP)) \(isUp ? "arttı" : "azaldı")."
        )
    }

    private static func biggestExpenseInsight(current: [Transaction]) -> BudgiInsight? {
        guard let big = current.filter({ $0.type == .expense }).max(by: { $0.amount < $1.amount }) else { return nil }
        return BudgiInsight(
            tag: "EN BÜYÜK İŞLEM",
            icon: "dollarsign.circle.fill",
            accentColor: BrandColor.warning,
            text: "Bu ayın en büyük gideri: \"\(big.note)\" — \(big.amount.fullTRY).",
            redactedText: "Bu ayın en büyük gideri: \"\(big.note)\" — ••••."
        )
    }

    private static func dailyAverageInsight(current: [Transaction], start: Date, now: Date) -> BudgiInsight? {
        let expenses = current.filter { $0.type == .expense }
        guard !expenses.isEmpty else { return nil }
        let total = expenses.reduce(Decimal(0)) { $0 + $1.amount }
        let days = max(1, Calendar.current.dateComponents([.day], from: start, to: now).day ?? 1)
        let daily = total / Decimal(days)
        let cal = Calendar.current
        let daysInMonth = cal.range(of: .day, in: .month, for: now)?.count ?? 30
        let projected = daily * Decimal(daysInMonth)
        return BudgiInsight(
            tag: "GÜNLÜK ORTALAMA",
            icon: "calendar",
            accentColor: BrandColor.info,
            text: "Günlük ortalama harcaman \(daily.fullTRY). Bu hızla ay sonu tahmini: \(projected.fullTRY).",
            redactedText: "Günlük ortalama harcaman hesaplandı. Bu hızla ay sonuna kadar devam edecek."
        )
    }
}

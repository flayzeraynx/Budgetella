//
//  BudgiView.swift
//  Budgetella
//
//  Budgi AI — 2-way chat asistanı. Proaktif insight'lar + kullanıcı soruları.
//

import SwiftUI
import SwiftData

struct BudgiView: View {

    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @AppStorage("displayName")    private var displayName    = ""
    @AppStorage("currentUserId") private var currentUserId  = ""
    @Environment(\.hideAmounts) private var hideAmounts

    @AppStorage("aiDataConsentGiven") private var aiConsentGiven = false
    @State private var chatMessages:     [BudgiMessage] = []
    @State private var chatInput         = ""
    @State private var isSending         = false
    @State private var showConsentAlert  = false
    @State private var pendingSend       = false
    @State private var subscriptionService = SubscriptionService()
    @State private var scrollProxy:      ScrollViewProxy? = nil
    @FocusState private var isInputFocused: Bool

    private var insights: [BudgiInsight] {
        BudgiInsightEngine.compute(transactions: transactions, categories: categories)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            LazyVStack(alignment: .leading, spacing: Spacing.md) {
                                ForEach(chatMessages) { msg in
                                    messageBubble(msg)
                                        .id(msg.id)
                                }
                                if isSending {
                                    typingIndicator
                                        .id("typing")
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, Spacing.lg)
                            .padding(.bottom, 20)
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .simultaneousGesture(TapGesture().onEnded { isInputFocused = false })
                        .onAppear {
                            scrollProxy = proxy
                            buildInitialMessages()
                        }
                        .onChange(of: chatMessages.count) { _, _ in
                            withAnimation(.easeOut(duration: 0.25)) {
                                proxy.scrollTo(chatMessages.last?.id, anchor: .bottom)
                            }
                        }
                        .onChange(of: isSending) { _, sending in
                            if sending {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    proxy.scrollTo("typing", anchor: .bottom)
                                }
                            }
                        }
                    }

                    chatInputBar
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task { await subscriptionService.setup(userId: currentUserId) }
        .alert("AI Veri Bildirimi", isPresented: $showConsentAlert) {
            Button("Kabul Et") {
                aiConsentGiven = true
                if pendingSend {
                    pendingSend = false
                    Task { await sendMessage() }
                }
            }
            Button("İptal", role: .cancel) { pendingSend = false }
        } message: {
            Text("Budgi'nin AI özellikleri, harcama özetlerini Google Gemini API'ye gönderir. Kişisel kimlik bilgileri dahil edilmez. Daha fazla bilgi için Gizlilik Politikamızı inceleyin.")
        }
        .onReceive(NotificationCenter.default.publisher(for: .appLanguageDidChange)) { _ in
            // Clear cached chat so greetings and insights regenerate in the new language
            UserDefaults.standard.removeObject(forKey: chatHistoryKey)
            chatMessages = []
            buildInitialMessages()
        }
    }

    // MARK: - Build initial messages

    private let chatHistoryKey = "budgi_chat_v1"

    private func buildInitialMessages() {
        guard chatMessages.isEmpty else { return }

        // Restore persisted history if available
        let saved = loadMessages()
        if !saved.isEmpty {
            chatMessages = saved
            return
        }

        // Fresh start — greeting + proactive insights
        var msgs: [BudgiMessage] = []
        let firstName = displayName.components(separatedBy: " ").first ?? displayName
        let name = firstName.isEmpty ? "Ozzy" : firstName
        let hour = Calendar.current.component(.hour, from: .now)
        let greet: String
        switch hour {
        case 5..<12:  greet = String(format: LocaleHelper.string("Günaydın %@ ☀️"), name)
        case 12..<18: greet = String(format: LocaleHelper.string("İyi günler %@ 👋"), name)
        case 18..<23: greet = String(format: LocaleHelper.string("İyi akşamlar %@ 🌙"), name)
        default:       greet = String(format: LocaleHelper.string("Merhaba %@ 🌙"), name)
        }
        let intro = insights.isEmpty
            ? LocaleHelper.string("Henüz analiz edecek yeterli veri yok. Birkaç işlem ekledikten sonra kişisel öneriler burada belirmeye başlar.")
            : LocaleHelper.string("Bu hafta şunları fark ettim:")
        msgs.append(BudgiMessage(role: .assistant, text: "\(greet) \(intro)", tag: nil, accent: "clear"))

        for insight in insights {
            msgs.append(BudgiMessage(role: .assistant, text: insight.text, tag: insight.tag, accent: insight.accent))
        }

        withAnimation { chatMessages = msgs }
    }

    private func saveMessages() {
        let toSave = Array(chatMessages.suffix(200)).map { msg in
            PersistedMessage(id: msg.id,
                             role: msg.role == .user ? "user" : "assistant",
                             text: msg.text, tag: msg.tag, accent: msg.accent)
        }
        if let data = try? JSONEncoder().encode(toSave) {
            UserDefaults.standard.set(data, forKey: chatHistoryKey)
        }
    }

    private func loadMessages() -> [BudgiMessage] {
        guard let data = UserDefaults.standard.data(forKey: chatHistoryKey),
              let saved = try? JSONDecoder().decode([PersistedMessage].self, from: data)
        else { return [] }
        return saved.map { p in
            BudgiMessage(id: p.id,
                         role: p.role == "user" ? .user : .assistant,
                         text: p.text, tag: p.tag, accent: p.accent)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LinearGradient(
                        colors: [BrandColor.primary, BrandColor.primaryLight],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 44, height: 44)
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Budgi")
                    .font(.brand(.headline))
                    .foregroundStyle(BrandColor.textPrimary)
                HStack(spacing: 4) {
                    Circle().fill(BrandColor.income).frame(width: 5, height: 5)
                    Text("Senin finans asistanın")
                        .font(.brand(.caption))
                        .foregroundStyle(BrandColor.textTertiary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(BrandColor.background)
        .overlay(alignment: .bottom) {
            Divider().background(BrandColor.borderSubtle)
        }
    }

    // MARK: - Message bubble

    @ViewBuilder
    private func messageBubble(_ msg: BudgiMessage) -> some View {
        if msg.role == .user {
            HStack {
                Spacer()
                Text(msg.text)
                    .font(.brand(.body))
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(BrandColor.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .frame(maxWidth: 280, alignment: .trailing)
            }
        } else {
            HStack {
                if let tag = msg.tag, !tag.isEmpty {
                    insightCard(msg: msg, tag: tag)
                } else {
                    plainBubble(text: msg.text)
                }
                Spacer()
            }
        }
    }

    private func insightCard(msg: BudgiMessage, tag: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: 5) {
                Image(systemName: tagIcon(tag))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(msg.tagColor)
                Text(LocalizedStringKey(tag))
                    .font(.brand(.caption))
                    .foregroundStyle(msg.tagColor)
                    .tracking(0.8)
            }
            Text(hideAmounts ? redact(msg.text) : msg.text)
                .font(.brand(.footnote))
                .foregroundStyle(BrandColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .frame(maxWidth: 300, alignment: .leading)
        .background(msg.tagColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(msg.tagColor.opacity(0.3), lineWidth: 1)
        )
    }

    private func plainBubble(text: String) -> some View {
        Text(text)
            .font(.brand(.footnote))
            .foregroundStyle(BrandColor.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(Spacing.md)
            .frame(maxWidth: 300, alignment: .leading)
            .glassCard(cornerRadius: 14)
    }

    private var typingIndicator: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(BrandColor.textTertiary)
                        .frame(width: 7, height: 7)
                        .opacity(isSending ? 1.0 : 0.3)
                        .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.2), value: isSending)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 12)
            .glassCard(cornerRadius: 14)
            Spacer()
        }
    }

    // MARK: - Chat input bar

    private var chatInputBar: some View {
        HStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                TextField("Budgi'ye soru sor...", text: $chatInput, axis: .vertical)
                    .font(.brand(.body))
                    .foregroundStyle(BrandColor.textPrimary)
                    .tint(BrandColor.primary)
                    .lineLimit(4)
                    .submitLabel(.send)
                    .focused($isInputFocused)
                    .onSubmit {
                        if aiConsentGiven {
                            Task { await sendMessage() }
                        } else {
                            pendingSend = true
                            showConsentAlert = true
                        }
                    }
                Spacer()
                Image(systemName: "mic")
                    .font(.system(size: 16))
                    .foregroundStyle(BrandColor.textTertiary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 10)
            .background(BrandColor.surface.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusFull))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.radiusFull)
                    .strokeBorder(BrandColor.borderSubtle, lineWidth: 1)
            )

            Button {
                if aiConsentGiven {
                    Task { await sendMessage() }
                } else {
                    pendingSend = true
                    showConsentAlert = true
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(chatInput.trimmingCharacters(in: .whitespaces).isEmpty ? BrandColor.surface : BrandColor.primary)
                        .frame(width: 44, height: 44)
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(chatInput.trimmingCharacters(in: .whitespaces).isEmpty ? BrandColor.textTertiary : .white)
                        .offset(x: 1)
                }
            }
            .disabled(chatInput.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.sm)
        .background(BrandColor.background)
        .overlay(alignment: .top) {
            Divider().background(BrandColor.borderSubtle)
        }
    }

    // MARK: - Send message

    private func sendMessage() async {
        let text = chatInput.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !isSending else { return }

        chatInput = ""
        chatMessages.append(BudgiMessage(role: .user, text: text, tag: nil, accent: "clear"))
        isSending = true

        let context = buildContext()
        let reply = (try? await BudgiChatService.send(message: text, context: context)) ?? String(localized: "Şu an cevap veremiyorum. Lütfen daha sonra tekrar dene.")
        chatMessages.append(BudgiMessage(role: .assistant, text: reply, tag: nil, accent: "primary"))
        isSending = false
        saveMessages()
    }

    private func buildContext() -> String {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: .now)
        guard let start = cal.date(from: comps) else { return "" }
        let monthTxs = transactions.filter { $0.date >= start }
        let income  = monthTxs.filter { $0.type == .income  }.reduce(Decimal(0)) { $0 + $1.amount }
        let expense = monthTxs.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }

        var catBreakdown = ""
        var catTotals: [String: Decimal] = [:]
        for tx in monthTxs where tx.type == .expense {
            let catName = tx.category?.name ?? "Diğer"
            catTotals[catName, default: 0] += tx.amount
        }
        let sorted = catTotals.sorted { $0.value > $1.value }.prefix(5)
        catBreakdown = sorted.map { "- \($0.key): \($0.value.fullTRY)" }.joined(separator: "\n")

        return """
        Kullanıcının bu ayki finans özeti:
        - Toplam gelir: \(income.fullTRY)
        - Toplam gider: \(expense.fullTRY)
        - Net: \((income - expense).fullTRY)
        Top gider kategorileri:
        \(catBreakdown.isEmpty ? "- Henüz veri yok" : catBreakdown)
        Toplam işlem sayısı: \(transactions.count)
        """
    }

    // MARK: - Helpers

    private func tagIcon(_ tag: String) -> String {
        switch tag {
        case "TASARRUF": return "checkmark.seal.fill"
        case "AÇIK":     return "exclamationmark.triangle.fill"
        case "ANOMALİ":  return "exclamationmark.triangle.fill"
        case "ÖNERİ":   return "lightbulb.fill"
        case "ARTIŞ":    return "arrow.up.circle.fill"
        case "AZALIŞ":   return "arrow.down.circle.fill"
        default:          return "sparkles"
        }
    }

    private func redact(_ text: String) -> String {
        text.replacingOccurrences(of: #"₺[\d,\.]+"#, with: "₺••••", options: .regularExpression)
    }
}

// MARK: - Chat message model

struct BudgiMessage: Identifiable {
    let id: UUID
    let role: Role
    let text: String
    let tag: String?
    let accent: String  // "primary" | "income" | "expense" | "warning" | "info" | "clear"

    init(id: UUID = UUID(), role: Role, text: String, tag: String?, accent: String) {
        self.id = id; self.role = role; self.text = text; self.tag = tag; self.accent = accent
    }

    var tagColor: Color {
        switch accent {
        case "income":  return BrandColor.income
        case "expense": return BrandColor.expense
        case "warning": return BrandColor.warning
        case "info":    return BrandColor.info
        case "clear":   return .clear
        default:        return BrandColor.primary
        }
    }

    enum Role { case user, assistant }
}

// MARK: - Persisted message (Codable)

private struct PersistedMessage: Codable {
    let id: UUID
    let role: String
    let text: String
    let tag: String?
    let accent: String
}

// MARK: - Budgi Chat Service

enum BudgiChatService {

    static func send(message: String, context: String) async throws -> String {
        let apiKey = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String ?? ""
        guard !apiKey.isEmpty else { return "API anahtarı yapılandırılmamış." }

        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else { return "Bağlantı hatası." }

        let isEnglish = LocaleHelper.isEnglish
        let systemPrompt = isEnglish ? """
        You are Budgi, the user's personal finance assistant. Respond in English.
        Keep answers short, friendly, and practical. No unnecessary long explanations.
        Help only with financial topics.

        \(context)
        """ : """
        Sen Budgi'sin — kullanıcının kişisel finans asistanısın. Türkçe konuşuyorsun.
        Kısa, samimi, ve pratik cevaplar ver. Gereksiz uzun açıklamalar yapma.
        Sadece finansal konularda yardımcı ol.

        \(context)
        """

        let requestBody: [String: Any] = [
            "contents": [
                ["role": "user", "parts": [["text": systemPrompt + "\n\nKullanıcı: " + message]]]
            ],
            "generationConfig": ["maxOutputTokens": 300, "temperature": 0.7]
        ]

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return "Sunucu hatası. Lütfen tekrar dene."
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String
        else { return "Yanıt ayrıştırılamadı." }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Insight model + engine (unchanged)

struct BudgiInsight: Identifiable {
    let id = UUID()
    let tag: String
    let icon: String
    let accent: String   // "primary" | "income" | "expense" | "warning" | "info"
    let accentColor: Color
    let text: String
    let redactedText: String

    init(tag: String, icon: String, accent: String, text: String, redactedText: String) {
        self.tag = tag; self.icon = icon; self.accent = accent; self.text = text
        self.redactedText = redactedText
        switch accent {
        case "income":  accentColor = BrandColor.income
        case "expense": accentColor = BrandColor.expense
        case "warning": accentColor = BrandColor.warning
        case "info":    accentColor = BrandColor.info
        default:        accentColor = BrandColor.primary
        }
    }
}

enum BudgiInsightEngine {

    static var isEnglish: Bool { LocaleHelper.isEnglish }

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
        if let s = savingsInsight(current: currentTxs) { results.append(s) }
        if let t = topCategoryInsight(current: currentTxs, categories: categories) { results.append(t) }
        if let m = monthOverMonthInsight(current: currentTxs, previous: prevTxs) { results.append(m) }
        if let b = biggestExpenseInsight(current: currentTxs) { results.append(b) }
        if let d = dailyAverageInsight(current: currentTxs, start: currentStart, now: now) { results.append(d) }
        return results
    }

    private static func savingsInsight(current: [Transaction]) -> BudgiInsight? {
        let income  = current.filter { $0.type == .income  }.reduce(Decimal(0)) { $0 + $1.amount }
        let expense = current.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
        guard income > 0 else { return nil }
        let savings = income - expense
        let isPos = savings >= 0
        return BudgiInsight(
            tag: isPos ? "TASARRUF" : "AÇIK",
            icon: isPos ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
            accent: isPos ? "income" : "expense",
            text: isPos
                ? (isEnglish ? "You saved \(savings.fullTRY) from \(income.fullTRY) income this month."
                             : "Bu ay \(income.fullTRY) gelirinden \(savings.fullTRY) tasarruf ettin.")
                : (isEnglish ? "Expenses exceeded income by \((-savings).fullTRY) this month. Keep an eye on it."
                             : "Bu ay giderlerin gelirini \((-savings).fullTRY) aştı. Dikkat et."),
            redactedText: isPos
                ? (isEnglish ? "You saved this month." : "Bu ay tasarruf ettin.")
                : (isEnglish ? "Expenses exceeded income." : "Bu ay giderlerin gelirini aştı.")
        )
    }

    private static func topCategoryInsight(current: [Transaction], categories: [Category]) -> BudgiInsight? {
        let expenses = current.filter { $0.type == .expense }
        guard !expenses.isEmpty else { return nil }
        var dict: [UUID: Decimal] = [:]
        for tx in expenses { guard let cat = tx.category else { continue }; dict[cat.id, default: 0] += tx.amount }
        guard let topId = dict.max(by: { $0.value < $1.value })?.key,
              let cat = categories.first(where: { $0.id == topId }) else { return nil }
        let amount = dict[topId]!
        let total  = expenses.reduce(Decimal(0)) { $0 + $1.amount }
        let pct    = total > 0 ? Int((Double(truncating: (amount / total) as NSDecimalNumber) * 100).rounded()) : 0
        return BudgiInsight(tag: "EN YÜKSEK KATEGORİ", icon: "chart.pie.fill", accent: "primary",
                            text: isEnglish
                                ? "\(cat.localizedDisplayName) is the top expense this month: \(amount.fullTRY) (\(pct)% of total spending)."
                                : "\(cat.localizedDisplayName) bu ayın en büyük gider kalemi: \(amount.fullTRY) (toplam giderlerin %\(pct)'i).",
                            redactedText: isEnglish
                                ? "\(cat.localizedDisplayName) is the top expense (\(pct)%)."
                                : "\(cat.localizedDisplayName) bu ayın en büyük gider kalemi (%\(pct)).")
    }

    private static func monthOverMonthInsight(current: [Transaction], previous: [Transaction]) -> BudgiInsight? {
        let cur = current.filter  { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
        let prv = previous.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
        guard prv > 0 else { return nil }
        let pct = (((cur as NSDecimalNumber).doubleValue - (prv as NSDecimalNumber).doubleValue) / (prv as NSDecimalNumber).doubleValue) * 100
        guard abs(pct) >= 5 else { return nil }
        let isUp = pct > 0
        return BudgiInsight(tag: isUp ? "ANOMALİ" : "AZALIŞ", icon: isUp ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                            accent: isUp ? "expense" : "income",
                            text: isEnglish
                                ? "\(cur.compactTRY) → last month \(prv.compactTRY). Spending \(isUp ? "increased" : "decreased") \(String(format: "%.0f", abs(pct)))% this month."
                                : "\(cur.compactTRY) → geçen \(prv.compactTRY). Bu ay giderlerin %\(String(format: "%.0f", abs(pct))) \(isUp ? "arttı" : "azaldı").",
                            redactedText: isEnglish
                                ? "Spending \(isUp ? "increased" : "decreased") \(String(format: "%.0f", abs(pct)))% this month."
                                : "Bu ay giderlerin %\(String(format: "%.0f", abs(pct))) \(isUp ? "arttı" : "azaldı").")
    }

    private static func biggestExpenseInsight(current: [Transaction]) -> BudgiInsight? {
        guard let big = current.filter({ $0.type == .expense }).max(by: { $0.amount < $1.amount }) else { return nil }
        return BudgiInsight(tag: "EN BÜYÜK İŞLEM", icon: "dollarsign.circle.fill", accent: "warning",
                            text: isEnglish
                                ? "Biggest expense this month: \"\(big.note)\" — \(big.amount.fullTRY)."
                                : "Bu ayın en büyük gideri: \"\(big.note)\" — \(big.amount.fullTRY).",
                            redactedText: isEnglish
                                ? "Biggest expense this month: \"\(big.note)\" — ••••."
                                : "Bu ayın en büyük gideri: \"\(big.note)\" — ••••.")
    }

    private static func dailyAverageInsight(current: [Transaction], start: Date, now: Date) -> BudgiInsight? {
        let expenses = current.filter { $0.type == .expense }
        guard !expenses.isEmpty else { return nil }
        let total = expenses.reduce(Decimal(0)) { $0 + $1.amount }
        let days  = max(1, Calendar.current.dateComponents([.day], from: start, to: now).day ?? 1)
        let daily = total / Decimal(days)
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: now)?.count ?? 30
        let projected = daily * Decimal(daysInMonth)
        return BudgiInsight(tag: "ÖNERİ", icon: "lightbulb.fill", accent: "info",
                            text: isEnglish
                                ? "Your daily average spending is \(daily.fullTRY). At this pace, end-of-month estimate: \(projected.fullTRY)."
                                : "Günlük ortalama harcaman \(daily.fullTRY). Bu hızla ay sonu tahmini: \(projected.fullTRY).",
                            redactedText: isEnglish
                                ? "Your daily spending average has been calculated."
                                : "Günlük ortalama harcaman hesaplandı.")
    }
}

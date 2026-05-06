//
//  GeminiInsightService.swift
//  Budgetella
//
//  Aylık finansal özeti Gemini 2.0 Flash'a gönderir, Türkçe AI insight'ları döndürür.
//  Sonuçlar gün bazında UserDefaults'ta cache'lenir (gereksiz API çağrısı engellenir).
//

import Foundation
import SwiftData

enum GeminiInsightService {

    // MARK: - Cache keys
    private static let cacheKey      = "gemini_insights_cache_v1"
    private static let cacheDateKey  = "gemini_insights_date_v1"

    // MARK: - Public

    struct AIInsight: Codable {
        let tag:    String
        let icon:   String  // SF Symbol name
        let accent: String  // "primary" | "income" | "expense" | "warning" | "info"
        let text:   String
    }

    @MainActor
    static func fetchInsights(
        transactions: [Transaction],
        categories:   [Category]
    ) async throws -> [AIInsight] {
        guard UserDefaults.standard.bool(forKey: "aiDataConsentGiven") else {
            throw InsightError.consentRequired
        }

        // Return cached result if fetched today
        if let cached = loadCache() { return cached }

        let apiKey = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String ?? ""
        guard !apiKey.isEmpty else { throw InsightError.missingAPIKey }

        let summary = buildSummary(transactions: transactions, categories: categories)
        guard !summary.isEmpty else { throw InsightError.noData }

        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else { throw InsightError.invalidURL }

        let prompt = """
        Sen Budgetella finans koçusun. Aşağıdaki aylık harcama verisini analiz et ve \
        kullanıcıya Türkçe, kısa ve pratik 3 öneri sun.

        Veri:
        \(summary)

        Her öneri için şu JSON formatını kullan (başka hiçbir şey yazma, sadece JSON dizisi):
        [
          {
            "tag": "KISA BAŞLIK (büyük harf, max 3 kelime)",
            "icon": "geçerli bir SF Symbol adı",
            "accent": "expense veya income veya warning veya info veya primary",
            "text": "Türkçe öneri (1-2 cümle, samimi ve kişisel ton)"
          }
        ]

        Öneriler gerçekten faydalı olsun: harcama alışkanlığı, tasarruf fırsatı veya dikkat \
        edilmesi gereken bir durum gibi. Genel laflar etme.
        """

        let requestBody: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": ["temperature": 0.7, "maxOutputTokens": 512]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw InsightError.serverError
        }

        let insights = try parseResponse(data: data)
        saveCache(insights)
        return insights
    }

    // MARK: - Cache

    static func cachedInsights() -> [AIInsight]? { loadCache() }

    static func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheDateKey)
    }

    private static func loadCache() -> [AIInsight]? {
        guard let dateStr = UserDefaults.standard.string(forKey: cacheDateKey),
              dateStr == todayString(),
              let data = UserDefaults.standard.data(forKey: cacheKey),
              let insights = try? JSONDecoder().decode([AIInsight].self, from: data)
        else { return nil }
        return insights
    }

    private static func saveCache(_ insights: [AIInsight]) {
        if let data = try? JSONEncoder().encode(insights) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(todayString(), forKey: cacheDateKey)
        }
    }

    private static func todayString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: .now)
    }

    // MARK: - Summary builder

    private static func buildSummary(transactions: [Transaction], categories: [Category]) -> String {
        let cal  = Calendar.current
        let now  = Date.now
        let comps = cal.dateComponents([.year, .month], from: now)
        guard let currentStart = cal.date(from: comps),
              let prevStart    = cal.date(byAdding: .month, value: -1, to: currentStart),
              let prevEnd      = cal.date(byAdding: .second, value: -1, to: currentStart)
        else { return "" }

        let currentTxs = transactions.filter { $0.date >= currentStart && $0.date <= now }
        let prevTxs    = transactions.filter { $0.date >= prevStart && $0.date <= prevEnd }

        guard !currentTxs.isEmpty else { return "" }

        let income  = currentTxs.filter { $0.type == .income  }.reduce(Decimal(0)) { $0 + $1.amount }
        let expense = currentTxs.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
        let savings = income - expense
        let prevExp = prevTxs.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }

        // Top 5 categories by expense
        var catTotals: [UUID: Decimal] = [:]
        for tx in currentTxs where tx.type == .expense {
            if let cat = tx.category { catTotals[cat.id, default: 0] += tx.amount }
        }
        let topCats = catTotals.sorted { $0.value > $1.value }.prefix(5).compactMap { entry -> String? in
            guard let cat = categories.first(where: { $0.id == entry.key }) else { return nil }
            let pct = expense > 0 ? Int((Double(truncating: (entry.value / expense) as NSDecimalNumber) * 100).rounded()) : 0
            return "  - \(cat.name): \(entry.value.fullTRY) (%\(pct))"
        }.joined(separator: "\n")

        // Biggest single expense
        let biggest = currentTxs.filter { $0.type == .expense }.max(by: { $0.amount < $1.amount })
        let biggestStr = biggest.map { "\($0.amount.fullTRY) (\($0.note))" } ?? "—"

        // Daily avg + projected
        let days = max(1, cal.dateComponents([.day], from: currentStart, to: now).day ?? 1)
        let daysInMonth = cal.range(of: .day, in: .month, for: now)?.count ?? 30
        let daily = expense / Decimal(days)
        let projected = daily * Decimal(daysInMonth)

        var lines = [
            "Bu ay gelir: \(income.fullTRY)",
            "Bu ay gider: \(expense.fullTRY)",
            "Tasarruf: \(savings.fullTRY)",
        ]
        if prevExp > 0 {
            let prevD  = (prevExp as NSDecimalNumber).doubleValue
            let curD   = (expense as NSDecimalNumber).doubleValue
            let change = prevD > 0 ? ((curD - prevD) / prevD * 100) : 0
            lines.append("Geçen ay gider: \(prevExp.fullTRY) (değişim: \(String(format: "%+.0f", change))%)")
        }
        lines.append("Top kategoriler:\n\(topCats)")
        lines.append("En büyük tek işlem: \(biggestStr)")
        lines.append("Günlük ortalama: \(daily.fullTRY) | Ay sonu tahmini: \(projected.fullTRY)")

        return lines.joined(separator: "\n")
    }

    // MARK: - Response parser

    private static func parseResponse(data: Data) throws -> [AIInsight] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content    = candidates.first?["content"] as? [String: Any],
              let parts      = content["parts"] as? [[String: Any]],
              let text       = parts.first?["text"] as? String
        else { throw InsightError.parseError }

        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let arrayData = cleaned.data(using: .utf8),
              let insights  = try? JSONDecoder().decode([AIInsight].self, from: arrayData),
              !insights.isEmpty
        else { throw InsightError.parseError }

        return insights
    }
}

// MARK: - Errors

enum InsightError: LocalizedError {
    case missingAPIKey, noData, invalidURL, serverError, parseError, consentRequired

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:    return String(localized: "Gemini API anahtarı bulunamadı.")
        case .noData:           return String(localized: "Yeterli işlem verisi yok.")
        case .invalidURL:       return String(localized: "Servis URL'i geçersiz.")
        case .serverError:      return String(localized: "Sunucu hatası, lütfen tekrar dene.")
        case .parseError:       return String(localized: "AI yanıtı işlenemedi.")
        case .consentRequired:  return String(localized: "AI özelliklerini kullanmak için veri iznini kabul etmelisin.")
        }
    }
}

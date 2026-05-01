//
//  KeywordCategorizer.swift
//  Budgetella
//
//  Türkiye odaklı, on-device, keyword-based transaction categorizer.
//  Free tier'da varsayılan; premium tier'da Claude Haiku 4.5 ile zenginleştirilir.
//
//  Eval hedefi: Ozzy'nin 4 yıllık 1000+ transaction üzerinde >90% top-1, >97% top-3.
//
//  Sözlük büyüdükçe `Trie` veya `Aho-Corasick` matcher'a geçilebilir;
//  şimdilik linear scan O(n*m) yeterli (tipik n~200 keyword, m~50 char).
//

import Foundation

/// Lokalize edilebilir varsayılan kategori slug'ları.
/// Display name `Localizable.xcstrings` → `category.slug.<rawValue>` key'inden okunur.
public enum CategorySlug: String, Codable, CaseIterable, Sendable {
    // Income
    case salary
    case freelance
    case investments
    case gifts

    // Expense
    case food
    case transportation
    case housing
    case bills
    case healthcare
    case shopping
    case entertainment
    case education
    case other

    public var type: TransactionType {
        switch self {
        case .salary, .freelance, .investments, .gifts:
            return .income
        case .food, .transportation, .housing, .bills,
             .healthcare, .shopping, .entertainment, .education, .other:
            return .expense
        }
    }

    /// SF Symbol icon adı.
    public var defaultIcon: String {
        switch self {
        case .salary:         return "banknote"
        case .freelance:      return "briefcase"
        case .investments:    return "chart.line.uptrend.xyaxis"
        case .gifts:          return "gift"
        case .food:           return "fork.knife"
        case .transportation: return "car.fill"
        case .housing:        return "house.fill"
        case .bills:          return "doc.text"
        case .healthcare:     return "cross.case"
        case .shopping:       return "bag.fill"
        case .entertainment:  return "tv"
        case .education:      return "book.fill"
        case .other:          return "tag"
        }
    }

    /// Türkçe görünen ad — SwiftData seed ve import mapping için.
    public var turkishName: String {
        switch self {
        case .salary:         return "Maaş"
        case .freelance:      return "Freelance"
        case .investments:    return "Yatırım"
        case .gifts:          return "Hediyeler"
        case .food:           return "Yiyecek"
        case .transportation: return "Ulaşım"
        case .housing:        return "Konut"
        case .bills:          return "Faturalar"
        case .healthcare:     return "Sağlık"
        case .shopping:       return "Alışveriş"
        case .entertainment:  return "Eğlence"
        case .education:      return "Eğitim"
        case .other:          return "Diğer"
        }
    }

    /// Hex renk kodu — DesignSystem rengiyle koordineli (Tailwind palette referansı).
    public var defaultColorHex: String {
        switch self {
        case .salary:         return "#22c55e"
        case .freelance:      return "#10b981"
        case .investments:    return "#06b6d4"
        case .gifts:          return "#ec4899"
        case .food:           return "#f59e0b"
        case .transportation: return "#3b82f6"
        case .housing:        return "#8b5cf6"
        case .bills:          return "#ef4444"
        case .healthcare:     return "#dc2626"
        case .shopping:       return "#a855f7"
        case .entertainment:  return "#f43f5e"
        case .education:      return "#0ea5e9"
        case .other:          return "#94a3b8"
        }
    }
}

public struct CategoryPrediction: Sendable, Equatable {
    public let slug: CategorySlug
    /// 0.0 - 1.0 arası confidence proxy (matched keyword length / max keyword length).
    public let confidence: Double
    /// Hangi keyword eşleşti — debug/UI explainability için.
    public let matchedKeyword: String?
}

public enum KeywordCategorizer {

    /// Türkiye-odaklı keyword sözlüğü (lowercase). Liste büyütülürken:
    /// - Çakışmaları azaltmak için en spesifik keyword'ü ekle (ör: "petrol ofisi" yerine "petrol" eklemek geri tepebilir).
    /// - Brand isimlerini aksansız yaz; matcher diakritik strip yapıyor.
    private static let dictionary: [String: CategorySlug] = [
        // ── Yiyecek (Market & Restoran)
        "migros": .food, "a101": .food, "bim": .food, "carrefoursa": .food,
        "carrefour": .food, "sok ": .food, "sok market": .food, "sokmarket": .food,
        "metro": .food, "tarim kredi": .food, "macrocenter": .food, "file": .food,
        "yemeksepeti": .food, "getir": .food, "trendyol yemek": .food, "fuzul": .food,
        "starbucks": .food, "kahve dunyasi": .food, "espressolab": .food, "espresso lab": .food,
        "gloria jean": .food, "mado": .food, "kofteci yusuf": .food, "burger king": .food,
        "mcdonalds": .food, "popeyes": .food, "kfc": .food,
        "domino": .food, "pizza hut": .food, "sushico": .food, "midpoint": .food,
        "kofte": .food, "yemek": .food, "kahvalti": .food, "lokanta": .food, "cafe": .food, "kafe": .food,
        "u-do": .food, "udo": .food, "disaridan yemek": .food,

        // ── Ulaşım (Akaryakıt + Taksi + Toplu Taşıma)
        "shell": .transportation, "bp ": .transportation, "opet": .transportation,
        "petrol ofisi": .transportation, "po petrol": .transportation, "total": .transportation,
        "lukoil": .transportation, "aytemiz": .transportation,
        "benzin": .transportation, "mazot": .transportation, "lpg": .transportation, "akaryakit": .transportation,
        "iett": .transportation, "metroistanbul": .transportation, "marmaray": .transportation,
        "uber": .transportation, "bitaksi": .transportation, "taksi": .transportation,
        "hgs": .transportation, "ogs": .transportation, "otoyol": .transportation, "kopru": .transportation,
        "ipark": .transportation, "ispark": .transportation, "otopark": .transportation,
        "havaist": .transportation, "havatas": .transportation,

        // ── Faturalar (Telekom + Su + Elektrik + Gaz + Streaming)
        "vodafone": .bills, "turkcell": .bills, "turk telekom": .bills, "ttnet": .bills,
        "superonline": .bills, "kablonet": .bills, "millenicom": .bills,
        "iski": .bills, "aski": .bills, "izsu": .bills, "asat": .bills,
        "bedas": .bills, "ayedas": .bills, "bogazici elektrik": .bills, "trakya elektrik": .bills,
        "cknetras": .bills,
        "igdas": .bills, "izgaz": .bills, "dogalgaz": .bills,
        "netflix": .bills, "spotify": .bills, "youtube premium": .bills, "disney+": .bills, "disneyplus": .bills,
        "apple one": .bills, "icloud": .bills, "appstore": .bills, "google play": .bills,
        "claude": .bills, "openai": .bills, "chatgpt": .bills, "anthropic": .bills, "cursor": .bills,
        "fatura": .bills, "abone": .bills, "subscription": .bills,

        // ── Sağlık
        "eczane": .healthcare, "hastane": .healthcare, "klinik": .healthcare, "poliklinik": .healthcare,
        "dis ": .healthcare, "dental": .healthcare, "doktor": .healthcare, "muayene": .healthcare,
        "memorial": .healthcare, "acibadem": .healthcare, "amerikan hastane": .healthcare,
        "medical park": .healthcare, "liv hospital": .healthcare,
        "sgk": .healthcare,

        // ── Alışveriş
        "trendyol": .shopping, "hepsiburada": .shopping, "n11": .shopping, "amazon": .shopping,
        "gittigidiyor": .shopping, "ciceksepeti": .shopping, "ikea": .shopping,
        "lcw": .shopping, "lc waikiki": .shopping, "defacto": .shopping, "koton": .shopping,
        "mavi": .shopping, "zara": .shopping, "h&m": .shopping, "bershka": .shopping,
        "boyner": .shopping, "vakko": .shopping, "beymen": .shopping, "yargici": .shopping,
        "media markt": .shopping, "teknosa": .shopping, "vatan bilgisayar": .shopping, "mediamarkt": .shopping,
        "watsons": .shopping, "gratis": .shopping, "rossmann": .shopping,

        // ── Eğlence
        "cinemaximum": .entertainment, "cinemarket": .entertainment, "biletix": .entertainment,
        "passo": .entertainment, "konser": .entertainment, "tiyatro": .entertainment,
        "steam": .entertainment, "playstation": .entertainment, "xbox": .entertainment,
        "epic games": .entertainment, "twitch": .entertainment,

        // ── Eğitim
        "udemy": .education, "coursera": .education, "linkedin learning": .education,
        "duolingo": .education, "kitap": .education, "kirtasiye": .education,
        "okul": .education, "kres": .education, "anaokul": .education, "universite": .education,
        "tarabya british": .education,

        // ── Konaklama (Kira + Aidat + Otel)
        "kira": .housing, "aidat": .housing, "site yonetim": .housing, "site aidat": .housing,
        "booking": .housing, "airbnb": .housing, "trivago": .housing,

        // ── Hediyeler
        "hediye": .gifts, "dogum gunu": .gifts,

        // ── Gelir
        "maas": .salary, "ucret": .salary, "bordro": .salary, "wage": .salary, "salary": .salary,
        "freelance": .freelance, "fiverr": .freelance, "upwork": .freelance,
        "kira gelir": .investments, "temettu": .investments, "dividend": .investments,
        "faiz": .investments, "interest": .investments,
    ]

    /// Tek best-match prediction.
    public static func predict(from text: String) -> CategoryPrediction? {
        let normalized = normalize(text)
        guard !normalized.isEmpty else { return nil }

        let matches = dictionary.compactMap { (keyword, slug) -> (String, CategorySlug)? in
            normalized.contains(keyword) ? (keyword, slug) : nil
        }
        guard let winner = matches.max(by: { $0.0.count < $1.0.count }) else { return nil }

        let maxLen = matches.map(\.0.count).max() ?? 1
        let confidence = Double(winner.0.count) / Double(maxLen)
        return CategoryPrediction(slug: winner.1, confidence: confidence, matchedKeyword: winner.0)
    }

    /// Top-N predictions, sorted by confidence desc.
    public static func topPredictions(from text: String, count: Int = 3) -> [CategoryPrediction] {
        let normalized = normalize(text)
        guard !normalized.isEmpty else { return [] }

        let matches = dictionary.compactMap { (keyword, slug) -> (String, CategorySlug)? in
            normalized.contains(keyword) ? (keyword, slug) : nil
        }
        guard !matches.isEmpty else { return [] }

        let maxLen = matches.map(\.0.count).max() ?? 1
        return matches
            .map { CategoryPrediction(slug: $0.1, confidence: Double($0.0.count) / Double(maxLen), matchedKeyword: $0.0) }
            .sorted { $0.confidence > $1.confidence }
            .prefix(count)
            .map { $0 }
    }

    /// Türkçe diakritikleri ASCII'ye indir, lowercase yap, fazla whitespace temizle.
    /// Sözlük zaten lowercase + diakritiksiz — input da aynı kanonik forma getirilmeli.
    private static func normalize(_ text: String) -> String {
        let lower = text.lowercased()
        let folded = lower.folding(options: .diacriticInsensitive, locale: Locale(identifier: "tr_TR"))
        return folded
            .replacingOccurrences(of: "ı", with: "i")
            .replacingOccurrences(of: "İ", with: "i")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

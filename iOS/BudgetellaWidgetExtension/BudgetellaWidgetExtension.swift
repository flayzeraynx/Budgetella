//
//  BudgetellaWidgetExtension.swift
//  BudgetellaWidgetExtension
//
//  Home screen + lock screen widget — redesigned.
//  Small:   Bugünün gideri hero + gelir/net alt satır
//  Medium:  İki panel — gider sol, gelir+net+ekle sağ
//  accessoryRectangular: lock screen compact
//

import WidgetKit
import SwiftUI

// MARK: - Shared snapshot

private struct WidgetSnapshot: Codable {
    var todayExpense: Double
    var todayIncome:  Double
    var isPremium:    Bool
    var lastUpdated:  Date

    static let empty = WidgetSnapshot(
        todayExpense: 0, todayIncome: 0, isPremium: false, lastUpdated: .distantPast
    )

    /// Widget gallery + Xcode preview'da gösterilecek örnek veri (kilitli değil).
    static let preview = WidgetSnapshot(
        todayExpense: 2_840, todayIncome: 1_500, isPremium: true, lastUpdated: .now
    )

    static func load() -> WidgetSnapshot {
        guard
            let defaults = UserDefaults(suiteName: "group.com.ozankilic.budgetella"),
            let data     = defaults.data(forKey: "budgetella.widgetSnapshot"),
            let snap     = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return .empty }
        return snap
    }
}

// MARK: - Timeline

private struct BudgetellaEntry: TimelineEntry {
    let date:     Date
    let snapshot: WidgetSnapshot
}

private struct BudgetellaProvider: TimelineProvider {
    func placeholder(in context: Context) -> BudgetellaEntry {
        // Gallery'de ve preview'da kilit göstermiyoruz — gerçek widget görünümünü göster
        BudgetellaEntry(date: .now, snapshot: .preview)
    }
    func getSnapshot(in context: Context, completion: @escaping (BudgetellaEntry) -> Void) {
        let snap = context.isPreview ? .preview : WidgetSnapshot.load()
        completion(BudgetellaEntry(date: .now, snapshot: snap))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<BudgetellaEntry>) -> Void) {
        let snap    = WidgetSnapshot.load()
        let entry   = BudgetellaEntry(date: .now, snapshot: snap)
        let refresh = Calendar.current.startOfDay(for: Date().addingTimeInterval(86_400))
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

// MARK: - Design tokens (match app DesignSystem)

private extension Color {
    static let bdBg      = Color(red: 0.051, green: 0.051, blue: 0.059) // #0D0D0F
    static let bdSurface = Color(red: 0.094, green: 0.094, blue: 0.106) // #18181B
    static let bdPrimary = Color(red: 0.431, green: 0.357, blue: 1.000) // #6E5BFF
    static let bdIncome  = Color(red: 0.133, green: 0.773, blue: 0.369) // #22C55E
    static let bdExpense = Color(red: 0.973, green: 0.529, blue: 0.529) // #F87187
}

// MARK: - Entry view

private struct BudgetellaWidgetView: View {
    let entry: BudgetellaEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:              smallView
        case .systemMedium:             mediumView
        case .accessoryRectangular:     lockView
        default:                        smallView
        }
    }

    // MARK: Small ──────────────────────────────────────────────────────────

    private var smallView: some View {
        ZStack {
            Color.bdBg
            if !entry.snapshot.isPremium {
                upgradeLockView
            } else {
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    HStack(alignment: .center, spacing: 5) {
                        Image(systemName: "b.circle.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.bdPrimary)
                        Text("BUGÜN")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white.opacity(0.38))
                            .kerning(1.2)
                        Spacer()
                        Text(Date(), format: .dateTime.day().month(.abbreviated))
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.white.opacity(0.25))
                    }

                    Spacer()

                    // Hero: expense
                    VStack(alignment: .leading, spacing: 2) {
                        Text("GİDER")
                            .font(.system(size: 7, weight: .black))
                            .foregroundStyle(Color.bdExpense.opacity(0.7))
                            .kerning(1.6)
                        Text(fmt(entry.snapshot.todayExpense))
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.4)
                            .lineLimit(1)
                    }

                    Spacer().frame(height: 10)

                    // Divider
                    Rectangle()
                        .fill(.white.opacity(0.08))
                        .frame(height: 1)

                    Spacer().frame(height: 8)

                    // Bottom: income | net
                    HStack(alignment: .firstTextBaseline) {
                        // Income
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(Color.bdIncome)
                            Text(fmt(entry.snapshot.todayIncome))
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))
                        }

                        Spacer()

                        // Net
                        let net = entry.snapshot.todayIncome - entry.snapshot.todayExpense
                        Text(netString(net))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(net >= 0 ? Color.bdIncome.opacity(0.85) : Color.bdExpense.opacity(0.85))
                    }
                }
                .padding(14)
            }
        }
    }

    // MARK: Medium ─────────────────────────────────────────────────────────

    private var mediumView: some View {
        ZStack {
            Color.bdBg
            if !entry.snapshot.isPremium {
                upgradeLockView
            } else {
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    HStack {
                        HStack(spacing: 5) {
                            Image(systemName: "b.circle.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.bdPrimary)
                            Text("Budgetella")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white.opacity(0.55))
                        }
                        Spacer()
                        Text(Date(), format: .dateTime.weekday(.wide).day().month(.abbreviated))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.28))
                    }

                    Spacer()

                    // Two-column metrics
                    HStack(alignment: .top, spacing: 0) {

                        // Left: Expense
                        VStack(alignment: .leading, spacing: 4) {
                            metricLabel("GİDER", icon: "arrow.down.right", color: .bdExpense)
                            Text(fmt(entry.snapshot.todayExpense))
                                .font(.system(size: 30, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .minimumScaleFactor(0.4)
                                .lineLimit(1)
                            Spacer()

                            // Net badge
                            let net = entry.snapshot.todayIncome - entry.snapshot.todayExpense
                            HStack(spacing: 4) {
                                Text("NET")
                                    .font(.system(size: 7, weight: .black))
                                    .foregroundStyle(.white.opacity(0.3))
                                    .kerning(1.2)
                                Text(netString(net))
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(net >= 0 ? Color.bdIncome : Color.bdExpense)
                            }
                        }

                        Spacer()

                        // Divider
                        Rectangle()
                            .fill(.white.opacity(0.07))
                            .frame(width: 1)
                            .padding(.vertical, 2)

                        Spacer()

                        // Right: Income + Add
                        VStack(alignment: .trailing, spacing: 4) {
                            metricLabel("GELİR", icon: "arrow.up.right", color: .bdIncome)
                            Text(fmt(entry.snapshot.todayIncome))
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                            Spacer()

                            // Add button (deep link)
                            Link(destination: URL(string: "budgetella://add")!) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 9, weight: .black))
                                    Text("Ekle")
                                        .font(.system(size: 11, weight: .bold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.bdPrimary)
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(15)
            }
        }
    }

    // MARK: Lock screen ────────────────────────────────────────────────────

    private var lockView: some View {
        HStack(spacing: 0) {
            // Expense
            HStack(spacing: 4) {
                Image(systemName: "arrow.down.right")
                    .font(.system(size: 9, weight: .bold))
                Text(fmt(entry.snapshot.todayExpense))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.red)

            Spacer()

            // Separator
            Text("·")
                .foregroundStyle(.secondary)

            Spacer()

            // Income
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9, weight: .bold))
                Text(fmt(entry.snapshot.todayIncome))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.green)
        }
    }

    // MARK: Premium lock ───────────────────────────────────────────────────

    private var upgradeLockView: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.bdPrimary.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "lock.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.bdPrimary)
            }
            Text("Premium")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.55))
            Text("Yükselt →")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.bdPrimary.opacity(0.8))
        }
    }

    // MARK: Helpers ────────────────────────────────────────────────────────

    private func metricLabel(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(color.opacity(0.75))
                .kerning(0.8)
        }
    }

    private func fmt(_ value: Double) -> String {
        let n = NumberFormatter()
        n.numberStyle         = .decimal
        n.maximumFractionDigits = 0
        n.locale              = Locale.current
        return "₺" + (n.string(from: NSNumber(value: value)) ?? "0")
    }

    private func netString(_ net: Double) -> String {
        let prefix = net >= 0 ? "+" : "-"
        return prefix + fmt(abs(net))
    }
}

// MARK: - Widget

@main
struct BudgetellaWidgetBundle: WidgetBundle {
    var body: some Widget { BudgetellaWidget() }
}

struct BudgetellaWidget: Widget {
    let kind = "BudgetellaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BudgetellaProvider()) { entry in
            BudgetellaWidgetView(entry: entry)
                .containerBackground(Color.bdBg, for: .widget)
        }
        .configurationDisplayName("Budgetella")
        .description("Bugünkü gelir ve giderini takip et.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

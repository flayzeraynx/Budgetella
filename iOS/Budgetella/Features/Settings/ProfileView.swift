//
//  ProfileView.swift
//  Budgetella
//

import SwiftUI
import SwiftData

struct ProfileView: View {

    var authService: AuthService

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @AppStorage("displayName")  private var displayName  = ""
    @AppStorage("userEmail")    private var userEmail    = ""
    @AppStorage("userPhotoURL") private var userPhotoURL = ""
    @State private var subscriptionService = SubscriptionService()
    @AppStorage("currentUserId") private var currentUserId = ""

    @State private var showChangePassword = false

    // MARK: - Computed stats

    private var transactionCount: Int { transactions.count }

    private var totalSavings: Decimal {
        let income  = transactions.filter { $0.type == .income  }.reduce(Decimal(0)) { $0 + $1.amount }
        let expense = transactions.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
        return income - expense
    }

    private var streak: Int {
        let cal = Calendar.current
        var day = cal.startOfDay(for: Date.now)
        var count = 0
        while count < 365 {
            let next = cal.date(byAdding: .day, value: 1, to: day)!
            if transactions.first(where: { $0.date >= day && $0.date < next }) != nil {
                count += 1
                day = cal.date(byAdding: .day, value: -1, to: day)!
            } else {
                break
            }
        }
        return count
    }

    private var monthSavings: Decimal {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: .now)
        guard let start = cal.date(from: comps) else { return 0 }
        let monthTxs = transactions.filter { $0.date >= start }
        let inc = monthTxs.filter { $0.type == .income  }.reduce(Decimal(0)) { $0 + $1.amount }
        let exp = monthTxs.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
        return inc - exp
    }

    private struct Achievement: Identifiable {
        let id: String
        let emoji: String
        let name: String
        let isUnlocked: Bool
        let colors: [Color]
    }

    private var achievements: [Achievement] {
        [
            Achievement(id: "first", emoji: "🔥", name: "İlk İşlem",  isUnlocked: !transactions.isEmpty,        colors: [.orange, .red]),
            Achievement(id: "s100",  emoji: "📅", name: "10 Gün Seri", isUnlocked: streak >= 10,                 colors: [Color(hex: "#6E5BFF"), .blue]),
            Achievement(id: "tx50",  emoji: "💼", name: "50 İşlem",    isUnlocked: transactionCount >= 50,       colors: [Color(hex: "#4CAF50"), Color(hex: "#2E7D32")]),
            Achievement(id: "save1", emoji: "💰", name: "₺1K Tasarruf",isUnlocked: totalSavings >= 1000,        colors: [Color(hex: "#FFD700"), Color(hex: "#FFA000")]),
            Achievement(id: "tx100", emoji: "⭐", name: "100 İşlem",   isUnlocked: transactionCount >= 100,      colors: [.purple, .indigo]),
            Achievement(id: "goal",  emoji: "🎯", name: "Bütçe Hedefi",isUnlocked: false,                       colors: [Color(hex: "#F44336"), Color(hex: "#B71C1C")]),
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // ── Gradient header
                        headerSection

                        // ── Stats row
                        statsRow
                            .padding(.horizontal, 20)
                            .padding(.top, Spacing.lg)

                        // ── Month status card
                        if transactions.count >= 3 {
                            monthStatusCard
                                .padding(.horizontal, 20)
                                .padding(.top, Spacing.lg)
                        }

                        // ── Achievements
                        achievementsSection
                            .padding(.horizontal, 20)
                            .padding(.top, Spacing.xl)

                        // ── Account actions
                        accountActions
                            .padding(.horizontal, 20)
                            .padding(.top, Spacing.xl)

                        Spacer(minLength: 60)
                    }
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(BrandColor.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(BrandColor.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordView(authService: authService)
            }
        }
        .task { await subscriptionService.setup(userId: currentUserId) }
    }

    // MARK: - Header section

    private var headerSection: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [BrandColor.primary.opacity(0.32), BrandColor.primary.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 220)

            VStack(spacing: Spacing.md) {
                // Avatar
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let url = URL(string: userPhotoURL), !userPhotoURL.isEmpty {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let img):
                                    img.resizable().scaledToFill()
                                        .frame(width: 84, height: 84)
                                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                default:
                                    initialsAvatar
                                }
                            }
                        } else {
                            initialsAvatar
                        }
                    }

                    if subscriptionService.isPremium {
                        Text("PRO")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(hex: "#FFB830"))
                            .clipShape(Capsule())
                            .offset(x: 4, y: 4)
                    }
                }

                // Name
                Text(displayName.isEmpty ? "İsim girilmemiş" : displayName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(BrandColor.textPrimary)

                // Email + streak
                HStack(spacing: Spacing.sm) {
                    Text(userEmail.isEmpty ? "..." : userEmail)
                        .font(.brand(.footnote))
                        .foregroundStyle(BrandColor.textTertiary)
                    if streak > 0 {
                        Text("·")
                            .foregroundStyle(BrandColor.textTertiary)
                        HStack(spacing: 3) {
                            Text("\(streak) günlük seri")
                                .font(.brand(.footnote))
                                .foregroundStyle(BrandColor.textTertiary)
                            Text("🔥")
                                .font(.system(size: 13))
                        }
                    }
                }
            }
            .padding(.top, 32)
            .padding(.bottom, 20)
        }
    }

    private var initialsAvatar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [BrandColor.primary, BrandColor.primaryLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 84, height: 84)
            Text(String(displayName.prefix(1)).uppercased())
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Stats row

    private var statsRow: some View {
        HStack(spacing: Spacing.sm) {
            statCell(value: "\(transactionCount)", label: "İşlem")
            statCell(value: totalSavings >= 0 ? totalSavings.compactTRY : "₺0", label: "Tasarruf")
            statCell(value: "\(streak)g", label: "Seri")
        }
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(BrandColor.textPrimary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.brand(.caption))
                .foregroundStyle(BrandColor.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .glassCard(cornerRadius: 14)
    }

    // MARK: - Month status card

    private var monthStatusCard: some View {
        let savings = monthSavings
        let isPositive = savings >= 0
        let bg = isPositive ? Color(hex: "#0A2E1A") : Color(hex: "#2E0A0A")
        let accent = isPositive ? Color(hex: "#4CAF50") : BrandColor.expense

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("BU AY DURUMUN")
                .font(.brand(.caption))
                .foregroundStyle(accent)
                .tracking(1.2)

            Text(isPositive
                 ? "Geçen aya göre \(savings.fullTRY) daha fazla biriktirdin. Çok iyi gidiyorsun 🚀"
                 : "Bu ay \((-savings).fullTRY) açık var. Harcamaları gözden geçir.")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(accent.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Achievements

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Başarımlar")
                .font(.brand(.subheadline))
                .foregroundStyle(BrandColor.textPrimary)
                .padding(.horizontal, 4)

            let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: cols, spacing: Spacing.sm) {
                ForEach(achievements) { a in
                    achievementCell(a)
                }
            }
        }
    }

    private func achievementCell(_ a: Achievement) -> some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        a.isUnlocked
                        ? LinearGradient(colors: a.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [BrandColor.surface.opacity(0.5), BrandColor.surface.opacity(0.5)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(height: 70)

                Text(a.emoji)
                    .font(.system(size: 28))
                    .opacity(a.isUnlocked ? 1.0 : 0.3)
            }
            Text(a.name)
                .font(.brand(.caption))
                .foregroundStyle(a.isUnlocked ? BrandColor.textPrimary : BrandColor.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }

    // MARK: - Account actions

    private var accountActions: some View {
        VStack(spacing: Spacing.xs) {
            Button {
                showChangePassword = true
            } label: {
                HStack(spacing: Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(BrandColor.primary.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(BrandColor.primary)
                    }
                    Text("Şifre Değiştir")
                        .font(.brand(.body))
                        .foregroundStyle(BrandColor.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(BrandColor.textTertiary)
                }
                .padding(Spacing.md)
                .glassCard(cornerRadius: 14)
            }
            .buttonStyle(.plain)
        }
    }

}

// MARK: - Change Password View

struct ChangePasswordView: View {

    var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var current = ""
    @State private var newPw = ""
    @State private var confirm = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var success = false

    private var isValid: Bool {
        !current.isEmpty && newPw.count >= 8 && newPw == confirm
    }

    private var passwordStrength: Double {
        guard newPw.count >= 8 else { return 0 }
        var score: Double = 0.33
        if newPw.range(of: #"[A-Z]"#, options: .regularExpression) != nil { score += 0.33 }
        if newPw.range(of: #"[0-9!@#$%^&*.]"#, options: .regularExpression) != nil { score += 0.34 }
        return score
    }

    private var strengthColor: Color {
        if passwordStrength < 0.5 { return BrandColor.expense }
        if passwordStrength < 0.85 { return Color.orange }
        return BrandColor.income
    }

    private var strengthLabel: String {
        if newPw.isEmpty { return "" }
        if passwordStrength < 0.34 { return "Çok zayıf" }
        if passwordStrength < 0.5  { return "Zayıf" }
        if passwordStrength < 0.85 { return "Orta" }
        return "Güçlü"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    if success {
                        VStack(spacing: Spacing.md) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(BrandColor.income)
                            Text("Şifre güncellendi")
                                .font(.brand(.title))
                                .foregroundStyle(BrandColor.textPrimary)
                            Button("Kapat") { dismiss() }
                                .foregroundStyle(BrandColor.primary)
                        }
                        .padding(.top, Spacing.xxxl)
                    } else {
                        VStack(spacing: Spacing.sm) {
                            pwField("Mevcut Şifre", text: $current)
                            pwField("Yeni Şifre", text: $newPw)

                            if !newPw.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    ProgressView(value: passwordStrength)
                                        .tint(strengthColor)
                                        .animation(.spring(response: 0.3), value: passwordStrength)
                                    HStack {
                                        Text(strengthLabel)
                                            .font(.brand(.caption))
                                            .foregroundStyle(strengthColor)
                                        Spacer()
                                        Text("En az 8 karakter, büyük harf, rakam")
                                            .font(.brand(.caption))
                                            .foregroundStyle(BrandColor.textTertiary)
                                    }
                                }
                            }

                            pwField("Yeni Şifre (Tekrar)", text: $confirm)

                            if !newPw.isEmpty && !confirm.isEmpty && newPw != confirm {
                                Text("Şifreler eşleşmiyor")
                                    .font(.brand(.caption))
                                    .foregroundStyle(BrandColor.expense)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, Spacing.lg)

                        if let err = errorMessage {
                            Text(err)
                                .font(.brand(.footnote))
                                .foregroundStyle(BrandColor.expense)
                                .padding(.horizontal, 24)
                        }

                        Button {
                            Task { await changePassword() }
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Şifreyi Güncelle")
                                        .font(.brand(.headline))
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(isValid ? BrandColor.primary : BrandColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium))
                        }
                        .disabled(!isValid || isLoading)
                        .padding(.horizontal, 24)

                        Spacer()
                    }
                }
            }
            .navigationTitle("Şifre Değiştir")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { dismiss() }
                        .foregroundStyle(BrandColor.textTertiary)
                }
            }
            .toolbarBackground(BrandColor.background, for: .navigationBar)
        }
        .presentationDetents([.medium])
    }

    private func pwField(_ placeholder: String, text: Binding<String>) -> some View {
        SecureField(placeholder, text: text)
            .font(.brand(.body))
            .foregroundStyle(BrandColor.textPrimary)
            .padding(Spacing.md)
            .glassCard(cornerRadius: Spacing.radiusMedium)
    }

    private func changePassword() async {
        isLoading = true
        errorMessage = nil
        do {
            try await authService.updatePassword(current: current, new: newPw)
            success = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

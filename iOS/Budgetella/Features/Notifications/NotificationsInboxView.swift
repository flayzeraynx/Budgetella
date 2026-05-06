//
//  NotificationsInboxView.swift
//  Budgetella
//
//  Bildirim kutusu — geçmiş bildirimleri listeler.
//  onAppear'da tüm kayıtları okundu işaretler + app badge'i sıfırlar.
//  Bir bildirime tıklanırsa sheet kapanıp deep link tetiklenir.
//

import SwiftUI
import SwiftData
import UserNotifications

struct NotificationsInboxView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @AppStorage("currentUserId") private var currentUserId = ""

    @Query(sort: \NotificationRecord.createdAt, order: .reverse)
    private var allRecords: [NotificationRecord]

    private var records: [NotificationRecord] {
        let uid = currentUserId
        return allRecords.filter { $0.userId == uid || $0.userId == "local" }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()

                if records.isEmpty {
                    emptyState
                } else {
                    notificationList
                }
            }
            .navigationTitle("Bildirimler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(BrandColor.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .font(.brand(.subheadline))
                        .foregroundStyle(BrandColor.primary)
                }
            }
        }
        .onAppear { markAllRead() }
    }

    // MARK: - List

    private var notificationList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.xs) {
                ForEach(records) { record in
                    NotificationRowView(record: record)
                        .onTapGesture { handleTap(record) }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "bell.slash")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(BrandColor.textTertiary)
            Text("Bildirim yok")
                .font(.brand(.headline))
                .foregroundStyle(BrandColor.textPrimary)
            Text("Gelecek bildirimler burada görünecek.")
                .font(.brand(.subheadline))
                .foregroundStyle(BrandColor.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    // MARK: - Actions

    private func markAllRead() {
        let unread = records.filter { !$0.isRead }
        guard !unread.isEmpty else { return }
        for record in unread { record.isRead = true }
        do {
            try modelContext.save()
        } catch {
            print("[NotificationsInbox] Save failed: \(error)")
        }
        // Clear app icon badge
        Task { try? await UNUserNotificationCenter.current().setBadgeCount(0) }
    }

    private func handleTap(_ record: NotificationRecord) {
        guard let dl = record.deepLink, let url = URL(string: dl) else {
            dismiss()
            return
        }
        dismiss()
        // 0.38 s ≈ .sheet dismiss spring duration; fire after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            NotificationCenter.default.post(
                name: .appDeepLinkReceived,
                object: nil,
                userInfo: ["url": url]
            )
        }
    }
}

// MARK: - Row

private struct NotificationRowView: View {

    let record: NotificationRecord

    var body: some View {
        HStack(spacing: Spacing.md) {

            // Kind icon
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: record.iconName)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(iconColor)
            }

            // Text content
            VStack(alignment: .leading, spacing: 3) {
                Text(record.title)
                    .font(.brand(.subheadline).weight(record.isRead ? .regular : .semibold))
                    .foregroundStyle(BrandColor.textPrimary)
                    .lineLimit(1)
                Text(record.body)
                    .font(.brand(.caption))
                    .foregroundStyle(BrandColor.textSecondary)
                    .lineLimit(2)
                Text(record.createdAt.relativeFormatted)
                    .font(.brand(.caption))
                    .foregroundStyle(BrandColor.textTertiary)
                    .padding(.top, 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Unread indicator
            if !record.isRead {
                Circle()
                    .fill(BrandColor.primary)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 10)
        .glassCard(cornerRadius: Spacing.radiusMedium)
        .cardHighlightOnPress(cornerRadius: Spacing.radiusMedium)
    }

    private var iconColor: Color {
        switch record.kind {
        case .weeklyDigest:  return BrandColor.info
        case .budgetAlert:   return BrandColor.warning
        case .anomaly:       return BrandColor.expense
        case .achievement:   return Color(hex: "#F59E0B")  // amber / altın
        case .goalMilestone: return BrandColor.income
        case .systemMessage: return BrandColor.primary
        }
    }
}

// MARK: - Date helper

private extension Date {
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = LocaleHelper.currentLocale
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: .now)
    }
}

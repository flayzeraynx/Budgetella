//
//  TransactionRow.swift
//  Budgetella
//

import SwiftUI

struct TransactionRow: View {

    let transaction: Transaction
    var onDelete: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil

    @Environment(\.hideAmounts) private var hideAmounts
    @State private var showDeleteConfirm = false
    @State private var isPressed = false

    var body: some View {
        rowContent
            .contentShape(Rectangle())
            // Subtle press feedback so the long-press affordance feels deliberate.
            .background(isPressed ? BrandColor.primary.opacity(0.10) : .clear)
            .animation(isPressed ? .none : .easeOut(duration: 0.22), value: isPressed)
            .onTapGesture { onTap?() }
            // Long-press anywhere on the row → delete confirmation.
            // Haptic on trigger so the user knows the gesture fired before the dialog appears.
            .onLongPressGesture(
                minimumDuration: 0.45,
                maximumDistance: 18,
                perform: {
                    isPressed = false
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    showDeleteConfirm = true
                },
                onPressingChanged: { pressing in
                    isPressed = pressing
                }
            )
            .confirmationDialog(
                LocaleHelper.string("Bu işlemi silmek istediğinizden emin misiniz?"),
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button(LocaleHelper.string("Sil"), role: .destructive) { onDelete?() }
                Button(LocaleHelper.string("İptal"), role: .cancel) { }
            } message: {
                let label = transaction.note.isEmpty
                    ? LocaleHelper.string("İsimsiz")
                    : transaction.note
                Text(label)
            }
    }

    private var rowContent: some View {
        HStack(spacing: Spacing.md) {
            categoryIcon

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.note.isEmpty ? "İsimsiz" : transaction.note)
                    .font(.brand(.subheadline))
                    .foregroundStyle(BrandColor.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if let cat = transaction.category {
                        Text(cat.localizedDisplayName)
                            .font(.brand(.caption))
                            .foregroundStyle(BrandColor.textTertiary)
                        Text("·")
                            .font(.brand(.caption))
                            .foregroundStyle(BrandColor.textTertiary)
                    }
                    Text(timeString(from: transaction.date))
                        .font(.brand(.caption))
                        .foregroundStyle(BrandColor.textTertiary)

                    if transaction.isRecurring {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(BrandColor.info)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(hideAmounts ? "••••" : (transaction.type == .income ? "+" : "-") + transaction.amount.fullTRY)
                    .font(.brand(.subheadline).monospacedDigit())
                    .foregroundStyle(transaction.type == .income ? BrandColor.income : BrandColor.expense)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                if transaction.status == .pending {
                    Text("bekliyor")
                        .font(.brand(.caption))
                        .foregroundStyle(BrandColor.warning)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 12)
    }

    private var categoryIcon: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor.opacity(0.15))
                .frame(width: 40, height: 40)
            Image(systemName: transaction.category?.iconName ?? "creditcard")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(iconBackgroundColor)
        }
    }

    private var iconBackgroundColor: Color {
        if let hex = transaction.category?.colorHex {
            return Color(hex: hex)
        }
        return transaction.type == .income ? BrandColor.income : BrandColor.expense
    }

    private func timeString(from date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: date)
    }
}

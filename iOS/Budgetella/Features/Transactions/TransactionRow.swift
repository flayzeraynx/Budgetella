//
//  TransactionRow.swift
//  Budgetella
//

import SwiftUI

struct TransactionRow: View {

    let transaction: Transaction

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Category icon circle
            categoryIcon

            // Note + meta
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.note.isEmpty ? "İsimsiz" : transaction.note)
                    .font(.brand(.subheadline))
                    .foregroundStyle(BrandColor.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if let cat = transaction.category {
                        Text(cat.name)
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

            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text((transaction.type == .income ? "+" : "-") + transaction.amount.fullTRY)
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

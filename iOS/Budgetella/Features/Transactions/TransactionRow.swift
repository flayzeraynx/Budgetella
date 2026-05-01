//
//  TransactionRow.swift
//  Budgetella
//

import SwiftUI

struct TransactionRow: View {

    let transaction: Transaction
    var onDelete: (() -> Void)? = nil

    @State private var swipeOffset: CGFloat = 0
    private let deleteWidth: CGFloat = 76

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button (behind row, revealed on swipe)
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    swipeOffset = 0
                }
                onDelete?()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Sil")
                        .font(.brand(.caption))
                }
                .foregroundStyle(.white)
                .frame(width: deleteWidth)
                .frame(maxHeight: .infinity)
                .background(BrandColor.expense)
            }
            .opacity(swipeOffset < -8 ? 1 : 0)

            // Main row content
            rowContent
                .offset(x: swipeOffset)
                .background(BrandColor.surface.opacity(0.001)) // extends tap area
                .gesture(
                    DragGesture(minimumDistance: 12, coordinateSpace: .local)
                        .onChanged { value in
                            let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                            guard isHorizontal else { return }
                            if value.translation.width < 0 {
                                swipeOffset = max(value.translation.width, -deleteWidth)
                            } else if swipeOffset < 0 {
                                swipeOffset = min(0, swipeOffset + value.translation.width)
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                swipeOffset = swipeOffset < -(deleteWidth * 0.5) ? -deleteWidth : 0
                            }
                        }
                )
        }
        .clipped()
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

//
//  BudgetellaLogoView.swift
//  Budgetella
//
//  Marka logosu: mor gradient arka plan, beyaz bold "B", mint yeşil nokta.
//  App icon tasarımıyla birebir eşleşir.
//

import SwiftUI

struct BudgetellaLogoView: View {

    var size: CGFloat = 44

    private var cornerRadius: CGFloat { size * 0.22 }
    private var fontSize: CGFloat { size * 0.58 }
    private var dotSize: CGFloat { size * 0.155 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#9585FF"), BrandColor.primary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("B")
                .font(.system(size: fontSize, weight: .bold))
                .foregroundStyle(.white)

            Circle()
                .fill(BrandColor.income)
                .frame(width: dotSize, height: dotSize)
                .offset(x: size * 0.17, y: -(size * 0.28))
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

#Preview {
    HStack(spacing: 24) {
        BudgetellaLogoView(size: 36)
        BudgetellaLogoView(size: 60)
        BudgetellaLogoView(size: 80)
    }
    .padding()
    .background(Color.black)
}

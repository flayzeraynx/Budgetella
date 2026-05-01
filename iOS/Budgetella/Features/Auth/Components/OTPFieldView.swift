//
//  OTPFieldView.swift
//  Budgetella
//
//  6 haneli OTP input — her hane ayrı kutu.
//  iOS otomatik doldurma (textContentType: .oneTimeCode) destekli.
//

import SwiftUI

struct OTPFieldView: View {

    @Binding var code: String
    let length = 6

    @FocusState private var isFocused: Bool

    var digits: [String] {
        var arr = code.prefix(length).map { String($0) }
        while arr.count < length { arr.append("") }
        return arr
    }

    var body: some View {
        ZStack {
            // Hidden actual input
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .opacity(0)
                .frame(width: 1, height: 1)
                .onChange(of: code) { _, newValue in
                    code = String(newValue.filter(\.isNumber).prefix(length))
                }

            // Visible digit boxes
            HStack(spacing: Spacing.sm) {
                ForEach(0..<length, id: \.self) { i in
                    digitBox(index: i)
                }
            }
        }
        .onTapGesture { isFocused = true }
    }

    private func digitBox(index: Int) -> some View {
        let digit = digits[index]
        let isActive = index == min(code.count, length - 1)
        let isFilled = index < code.count

        return ZStack {
            RoundedRectangle(cornerRadius: Spacing.radiusSmall, style: .continuous)
                .fill(BrandColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.radiusSmall, style: .continuous)
                        .strokeBorder(
                            isActive && isFocused
                                ? BrandColor.primary
                                : (isFilled ? BrandColor.borderMedium : BrandColor.borderSubtle),
                            lineWidth: isActive && isFocused ? 2 : 1
                        )
                )
                .frame(width: 48, height: 56)

            Text(digit)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundStyle(BrandColor.textPrimary)
        }
        .animation(.spring(response: 0.2), value: code.count)
    }
}

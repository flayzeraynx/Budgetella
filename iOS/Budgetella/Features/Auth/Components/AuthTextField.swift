//
//  AuthTextField.swift
//  Budgetella
//
//  Auth ekranlarında kullanılan glass-style text field.
//

import SwiftUI

struct AuthTextField: View {

    let icon: String
    let placeholder: LocalizedStringKey
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var submitLabel: SubmitLabel = .next
    var onSubmit: (() -> Void)? = nil

    @State private var isVisible = false
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(isFocused ? BrandColor.primary : BrandColor.textTertiary)
                .frame(width: 20)
                .animation(.easeOut(duration: 0.15), value: isFocused)

            Group {
                if isSecure && !isVisible {
                    SecureField(placeholder, text: $text)
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .focused($isFocused)
                        .keyboardType(keyboardType)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
                }
            }
            .font(.brand(.body))
            .foregroundStyle(BrandColor.textPrimary)
            .textContentType(textContentType)
            .submitLabel(submitLabel)
            .onSubmit { onSubmit?() }

            if isSecure {
                Button {
                    isVisible.toggle()
                } label: {
                    Image(systemName: isVisible ? "eye.slash" : "eye")
                        .font(.system(size: 14))
                        .foregroundStyle(BrandColor.textTertiary)
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                .fill(BrandColor.surface.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                        .strokeBorder(
                            isFocused ? BrandColor.primary.opacity(0.5) : BrandColor.borderSubtle,
                            lineWidth: 1
                        )
                )
        )
        .animation(.easeOut(duration: 0.15), value: isFocused)
    }
}

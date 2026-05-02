//
//  AuthSignUpView.swift
//  Budgetella
//
//  Auth 02 · Hesabını oluştur — Ad + Email + Şifre + strength meter + ToS
//

import SwiftUI

struct AuthSignUpView: View {

    @Bindable var vm: AuthViewModel
    var onAuthComplete: () -> Void

    @FocusState private var focusedField: Field?
    @State private var appeared = false

    enum Field { case name, email, password }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                backButton { vm.goBack() }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)
                    .padding(.top, 16)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Hesabını oluştur")
                        .font(.brand(.largeTitle))
                        .foregroundStyle(BrandColor.textPrimary)
                    Text("E-postan ve güçlü bir şifreyle başla. 30 saniye sürer.")
                        .font(.brand(.body))
                        .foregroundStyle(BrandColor.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, Spacing.xl)
                .padding(.bottom, Spacing.xxl)

                VStack(spacing: Spacing.md) {
                    // Ad
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        fieldLabel("Ad")
                        AuthTextField(
                            icon: "person",
                            placeholder: "Ozzy",
                            text: $vm.name,
                            textContentType: .name,
                            submitLabel: .next,
                            onSubmit: { focusedField = .email }
                        )
                    }

                    // E-posta
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        fieldLabel("E-posta")
                        AuthTextField(
                            icon: "envelope",
                            placeholder: "ozzy@budgetella.app",
                            text: $vm.email,
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress,
                            submitLabel: .next,
                            onSubmit: { focusedField = .password }
                        )
                    }

                    // Şifre
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        fieldLabel("Şifre")
                        AuthTextField(
                            icon: "lock",
                            placeholder: "••••••••••",
                            text: $vm.password,
                            isSecure: true,
                            textContentType: .newPassword,
                            submitLabel: .done,
                            onSubmit: { focusedField = nil }
                        )
                        PasswordStrengthView(password: vm.password)
                            .padding(.top, 4)
                    }

                    // ToS checkbox
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Button {
                            withAnimation(.spring(response: 0.2)) {
                                vm.termsAccepted.toggle()
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(vm.termsAccepted ? BrandColor.primary : .clear)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                                            .strokeBorder(
                                                vm.termsAccepted ? BrandColor.primary : BrandColor.borderMedium,
                                                lineWidth: 1.5
                                            )
                                    )
                                if vm.termsAccepted {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        Text(tosAttributedString)
                            .font(.brand(.footnote))
                            .foregroundStyle(BrandColor.textSecondary)
                            .tint(BrandColor.primary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.2)) {
                                    vm.termsAccepted.toggle()
                                }
                            }
                    }
                    .padding(.top, Spacing.xs)
                }
                .padding(.horizontal, 28)

                // Hata mesajı
                if let error = vm.errorMessage {
                    Text(error)
                        .font(.brand(.footnote))
                        .foregroundStyle(BrandColor.expense)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 28)
                        .padding(.top, Spacing.sm)
                }

                // CTA
                Button {
                    Task {
                        let ok = await vm.signUp()
                        if ok { /* navigate to OTP handled in vm */ }
                    }
                } label: {
                    if vm.isLoading {
                        ProgressView().tint(.white).frame(maxWidth: .infinity).frame(height: 56)
                            .background(LinearGradient(colors: [BrandColor.primary, BrandColor.primaryLight], startPoint: .leading, endPoint: .trailing))
                            .clipShape(Capsule())
                    } else {
                        primaryButtonLabel("Hesap oluştur")
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, Spacing.xl)
                .padding(.bottom, 48)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: appeared)
        .onAppear { appeared = true }
    }

    private var tosAttributedString: AttributedString {
        var terms = AttributedString("Kullanım şartları")
        terms.link = URL(string: "https://budgetella.app/terms")
        terms.inlinePresentationIntent = .stronglyEmphasized

        var mid = AttributedString(" ve ")

        var privacy = AttributedString("gizlilik politikası")
        privacy.link = URL(string: "https://budgetella.app/privacy")
        privacy.inlinePresentationIntent = .stronglyEmphasized

        let suffix = AttributedString("'nı okudum, kabul ediyorum.")

        return terms + mid + privacy + suffix
    }
}

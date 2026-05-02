//
//  ProfileView.swift
//  Budgetella
//

import SwiftUI

struct ProfileView: View {

    var authService: AuthService

    @Environment(\.dismiss) private var dismiss
    @AppStorage("displayName") private var displayName = ""
    @AppStorage("userEmail") private var userEmail = ""

    @State private var editedName = ""
    @State private var showChangePassword = false
    @State private var isEditing = false
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {

                        // Avatar
                        VStack(spacing: Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [BrandColor.primary, BrandColor.primaryLight],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                Text(String(displayName.prefix(1)).uppercased())
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(.white)
                            }

                            if isEditing {
                                TextField("Adın", text: $editedName)
                                    .font(.brand(.headline))
                                    .foregroundStyle(BrandColor.textPrimary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, Spacing.md)
                                    .padding(.vertical, Spacing.sm)
                                    .background(BrandColor.surface.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSmall))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Spacing.radiusSmall)
                                            .strokeBorder(BrandColor.primary.opacity(0.4), lineWidth: 1)
                                    )
                                    .frame(maxWidth: 200)
                            } else {
                                Text(displayName.isEmpty ? "İsim girilmemiş" : displayName)
                                    .font(.brand(.headline))
                                    .foregroundStyle(BrandColor.textPrimary)
                            }

                            Text(userEmail)
                                .font(.brand(.body))
                                .foregroundStyle(BrandColor.textTertiary)
                        }
                        .padding(.top, Spacing.lg)

                        // Change password
                        Button {
                            showChangePassword = true
                        } label: {
                            HStack {
                                Image(systemName: "lock.rotation")
                                    .font(.system(size: 15))
                                    .foregroundStyle(BrandColor.primary)
                                Text("Şifre Değiştir")
                                    .font(.brand(.body))
                                    .foregroundStyle(BrandColor.primary)
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(BrandColor.primary.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { dismiss() }
                        .foregroundStyle(BrandColor.textTertiary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        Button("Kaydet") {
                            Task { await saveName() }
                        }
                        .font(.brand(.subheadline).bold())
                        .foregroundStyle(BrandColor.primary)
                        .disabled(isSaving)
                    } else {
                        Button("Düzenle") {
                            editedName = displayName
                            isEditing = true
                        }
                        .foregroundStyle(BrandColor.primary)
                    }
                }
            }
            .toolbarBackground(BrandColor.background, for: .navigationBar)
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordView(authService: authService)
            }
        }
    }

    private func saveName() async {
        guard !editedName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSaving = true
        displayName = editedName.trimmingCharacters(in: .whitespaces)
        try? await authService.updateDisplayName(displayName)
        isSaving = false
        isEditing = false
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
                            pwField("Yeni Şifre (Tekrar)", text: $confirm)

                            if !newPw.isEmpty && newPw != confirm {
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

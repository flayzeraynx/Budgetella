//
//  DeleteAccountView.swift
//  Budgetella
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct DeleteAccountView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currentUserId") private var currentUserId = ""

    var authService: AuthService

    @State private var confirmText = ""
    @State private var isDeleting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showReAuthSheet = false
    @State private var reAuthPassword = ""
    @State private var isReAuthing = false
    @State private var reAuthError: String?

    private var confirmKeyword: String {
        (Locale.current.language.languageCode?.identifier ?? "tr") == "en" ? "delete" : "sil"
    }
    private var canDelete: Bool { confirmText.lowercased() == confirmKeyword }

    var body: some View {
        ZStack {
            BrandColor.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {

                    // Warning card
                    warningCard

                    // Data list
                    dataLossSection

                    // Backup nudge
                    backupNudge

                    Spacer(minLength: Spacing.xl)

                    // Danger zone
                    dangerZone
                }
                .padding(.horizontal, 20)
                .padding(.top, Spacing.lg)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Hesabı Sil")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BrandColor.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .brandAlert(
            title: "Hata",
            dynamicMessage: errorMessage,
            isPresented: $showError,
            buttons: [.cancel("Tamam")]
        )
        .sheet(isPresented: $showReAuthSheet) {
            reAuthSheet
        }
    }

    // MARK: - Re-auth sheet (shown when Firebase requiresRecentLogin)

    private var reAuthSheet: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(BrandColor.primary)
                    Text("Kimliğini doğrula")
                        .font(.brand(.title))
                        .foregroundStyle(BrandColor.textPrimary)
                    Text("Hesap silme güvenli bir işlemdir. Devam etmek için şifreni gir.")
                        .font(.brand(.body))
                        .foregroundStyle(BrandColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Spacing.xl)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Şifre")
                        .font(.brand(.footnote))
                        .foregroundStyle(BrandColor.textTertiary)
                    SecureField("••••••••", text: $reAuthPassword)
                        .font(.brand(.body))
                        .foregroundStyle(BrandColor.textPrimary)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(BrandColor.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(BrandColor.borderMedium, lineWidth: 1)
                                )
                        )
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding(.horizontal, Spacing.xl)

                if let err = reAuthError {
                    Text(err)
                        .font(.brand(.footnote))
                        .foregroundStyle(BrandColor.expense)
                        .padding(.horizontal, Spacing.xl)
                }

                Button {
                    Task { await performReAuth() }
                } label: {
                    Group {
                        if isReAuthing {
                            ProgressView().tint(.white)
                        } else {
                            Text("Onayla ve Sil")
                                .font(.brand(.subheadline).bold())
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(reAuthPassword.isEmpty ? BrandColor.expense.opacity(0.3) : BrandColor.expense)
                    )
                }
                .disabled(reAuthPassword.isEmpty || isReAuthing)
                .padding(.horizontal, Spacing.xl)

                Spacer()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { showReAuthSheet = false }
                        .foregroundStyle(BrandColor.textSecondary)
                }
            }
            .background(BrandColor.background.ignoresSafeArea())
        }
        .presentationDetents([.medium])
    }

    private func performReAuth() async {
        isReAuthing = true
        reAuthError = nil
        do {
            try await authService.reauthenticate(password: reAuthPassword)
            isReAuthing = false
            showReAuthSheet = false
            reAuthPassword = ""
            await performDelete()
        } catch {
            isReAuthing = false
            reAuthError = "Şifre hatalı. Tekrar dene."
        }
    }

    // MARK: - Warning card

    private var warningCard: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(BrandColor.expense.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(BrandColor.expense)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Bu işlem geri alınamaz")
                    .font(.brand(.headline))
                    .foregroundStyle(BrandColor.expense)

                Text("Hesabın silinme talebini aldıktan sonra 30 gün içinde tüm veriler kalıcı olarak kaldırılır. Bu süre içinde giriş yaparak iptal edebilirsin.")
                    .font(.brand(.footnote))
                    .foregroundStyle(BrandColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(BrandColor.expense.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(BrandColor.expense.opacity(0.25), lineWidth: 1)
                )
        )
    }

    // MARK: - Data loss section

    private var dataLossSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("SİLİNECEK VERİLER")
                .font(.brand(.caption))
                .foregroundStyle(BrandColor.textTertiary)
                .tracking(1.2)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(deletionItems, id: \.self) { item in
                    HStack(spacing: Spacing.md) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(BrandColor.expense)
                            .frame(width: 20, height: 20)
                            .background(BrandColor.expense.opacity(0.1))
                            .clipShape(Circle())

                        Text(LocalizedStringKey(item))
                            .font(.brand(.subheadline))
                            .foregroundStyle(BrandColor.textPrimary)

                        Spacer()
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, 12)

                    if item != deletionItems.last {
                        Divider()
                            .overlay(BrandColor.borderSubtle)
                            .padding(.leading, 52)
                    }
                }
            }
            .glassCard(cornerRadius: 14)
        }
    }

    private let deletionItems = [
        "İşlem geçmişi",
        "Kategoriler",
        "Bütçe & hedefler",
        "AI sohbet geçmişi",
        "Bulut yedekleri",
        "Profil bilgileri"
    ]

    // MARK: - Backup nudge

    private var backupNudge: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "externaldrive.badge.checkmark")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(BrandColor.primary)
            Text("Silmeden önce yedek almak ister misin?")
                .font(.brand(.footnote))
                .foregroundStyle(BrandColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    // MARK: - Danger zone

    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("TEHLİKELİ BÖLGE")
                .font(.brand(.caption))
                .foregroundStyle(BrandColor.expense.opacity(0.7))
                .tracking(1.2)
                .padding(.horizontal, 4)

            VStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Onaylamak için \"sil\" yaz")
                        .font(.brand(.footnote))
                        .foregroundStyle(BrandColor.textSecondary)

                    TextField("sil", text: $confirmText)
                        .font(.brand(.body))
                        .foregroundStyle(BrandColor.textPrimary)
                        .tint(BrandColor.expense)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(BrandColor.expense.opacity(canDelete ? 0.08 : 0.04))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(
                                            canDelete ? BrandColor.expense.opacity(0.5) : BrandColor.borderSubtle,
                                            lineWidth: 1
                                        )
                                )
                        )
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Button {
                    Task { await performDelete() }
                } label: {
                    HStack(spacing: Spacing.sm) {
                        if isDeleting {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(0.85)
                        } else {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        if isDeleting {
                            Text("Siliniyor…")
                                .font(.brand(.subheadline).bold())
                        } else {
                            Text("Hesabı Kalıcı Olarak Sil")
                                .font(.brand(.subheadline).bold())
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(canDelete ? BrandColor.expense : BrandColor.expense.opacity(0.3))
                    )
                }
                .disabled(!canDelete || isDeleting)
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(BrandColor.expense.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(BrandColor.expense.opacity(0.15), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Delete action

    private func performDelete() async {
        isDeleting = true
        isReAuthing = false
        do {
            try await authService.deleteAccount(modelContext: modelContext)
        } catch let error as NSError
            where error.domain == "FIRAuthErrorDomain" && error.code == 17014 {
            // requiresRecentLogin — ask user to re-authenticate first
            isDeleting = false
            showReAuthSheet = true
        } catch {
            isDeleting = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

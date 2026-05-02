//
//  QuickEntryView.swift
//  Budgetella
//
//  Hızlı giriş — 3 mod: manuel, sesli (premium), kamera (premium)
//

import SwiftUI
import SwiftData

enum EntryMode: CaseIterable {
    case manual, voice, camera
}

struct QuickEntryView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @AppStorage("currentUserId") private var userId = ""

    @State private var vm = QuickEntryViewModel()
    @State private var mode: EntryMode = .manual
    @State private var isTyping = false
    @State private var showDiscardAlert = false

    private var hasContent: Bool {
        vm.amountDecimal > 0 || !vm.note.isEmpty || vm.selectedCategoryId != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Mode selector — right-aligned below nav bar
                    HStack {
                        Spacer()
                        HStack(spacing: Spacing.xs) {
                            modePill(.manual, icon: "keyboard",    label: "Manuel")
                            modePill(.voice,  icon: "mic.fill",    label: "Sesli")
                            modePill(.camera, icon: "camera.fill", label: "Kamera")
                        }
                        .padding(3)
                        .background(BrandColor.surface.opacity(0.4))
                        .clipShape(Capsule())
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)

                    switch mode {
                    case .manual:
                        ManualEntryContent(vm: vm, categories: categories, mode: $mode, isTyping: $isTyping)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .opacity
                            ))

                    case .voice:
                        VoiceEntryContent(vm: vm, mode: $mode)
                        .transition(.opacity)

                    case .camera:
                        CameraEntryContent(vm: vm, mode: $mode)
                        .transition(.opacity)
                    }

                    // Full-width save button — only for manual mode, hidden while keyboard is up
                    if mode == .manual && !isTyping {
                        Button {
                            vm.save(modelContext: modelContext, categories: categories, userId: userId)
                            if vm.errorMessage == nil { dismiss() }
                        } label: {
                            Text("Kaydet")
                                .font(.brand(.headline))
                                .foregroundStyle(vm.canSave ? .white : BrandColor.textTertiary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    vm.canSave
                                    ? LinearGradient(
                                        colors: [BrandColor.primary, BrandColor.primaryLight],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                    : LinearGradient(
                                        colors: [BrandColor.surface.opacity(0.5), BrandColor.surface.opacity(0.5)],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                                .shadow(
                                    color: vm.canSave ? BrandColor.primary.opacity(0.4) : .clear,
                                    radius: 12, y: 4
                                )
                        }
                        .disabled(!vm.canSave)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 36)
                        .padding(.top, Spacing.sm)
                    }
                }
            }
            .animation(.spring(response: 0.3), value: mode)
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(hasContent)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") {
                        if hasContent {
                            showDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundStyle(BrandColor.textSecondary)
                }

            }
            .toolbarBackground(BrandColor.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .brandAlert(
                title: "Değişiklikleri At",
                message: "Girilen bilgiler silinecek.",
                isPresented: $showDiscardAlert,
                buttons: [
                    .destructive("Vazgeç ve Kapat") { dismiss() },
                    .cancel("Devam Et")
                ]
            )
            .sheet(isPresented: $vm.showCategoryPicker) {
                CategoryPickerView(
                    categories: categories,
                    selectedId: $vm.selectedCategoryId
                )
            }
        }
    }

    // MARK: - Mode pill (toolbar)

    private func modePill(_ m: EntryMode, icon: String, label: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) { mode = m }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(label)
                    .font(.brand(.caption))
            }
            .foregroundStyle(mode == m ? .white : BrandColor.textTertiary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 6)
            .background(mode == m ? BrandColor.primary : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Premium gate

    private func premiumGate(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            ZStack {
                Circle()
                    .fill(BrandColor.primary.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: icon)
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(BrandColor.primary)
                    .symbolRenderingMode(.hierarchical)
            }
            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.brand(.title))
                    .foregroundStyle(BrandColor.textPrimary)
                Text(subtitle)
                    .font(.brand(.body))
                    .foregroundStyle(BrandColor.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11, weight: .semibold))
                Text("Premium özellik — V1.1'de geliyor")
                    .font(.brand(.footnote))
            }
            .foregroundStyle(BrandColor.primary)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(BrandColor.primary.opacity(0.1))
            .clipShape(Capsule())

            Spacer()
        }
    }
}

// MARK: - Category picker sheet

struct CategoryPickerView: View {

    let categories: [Category]
    @Binding var selectedId: UUID?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()
                List(categories, id: \.id) { cat in
                    Button {
                        selectedId = cat.id
                        dismiss()
                    } label: {
                        HStack(spacing: Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: cat.colorHex).opacity(0.15))
                                    .frame(width: 34, height: 34)
                                Image(systemName: cat.iconName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color(hex: cat.colorHex))
                            }
                            Text(cat.name)
                                .font(.brand(.body))
                                .foregroundStyle(BrandColor.textPrimary)
                            Spacer()
                            if cat.id == selectedId {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(BrandColor.primary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(BrandColor.surface.opacity(0.3))
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Kategori")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Tamam") { dismiss() }
                        .foregroundStyle(BrandColor.primary)
                }
            }
        }
    }
}

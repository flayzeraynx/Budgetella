//
//  QuickEntryView.swift
//  Budgetella
//
//  Hızlı giriş — 3 mod: manuel, sesli (premium), kamera (premium)
//  Mod, FAB blob gesture'ından initialMode olarak gelir.
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
    @Query private var settingsArr: [AppSettings]
    @AppStorage("currentUserId") private var userId = ""

    private var preferredScheme: ColorScheme? {
        switch settingsArr.first?.theme ?? .system {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return nil
        }
    }

    @State private var vm = QuickEntryViewModel()
    @State private var mode: EntryMode
    @State private var isTyping = false
    @State private var showDiscardAlert = false

    init(initialMode: EntryMode = .manual) {
        _mode = State(initialValue: initialMode)
    }

    private var hasContent: Bool {
        vm.amountDecimal > 0 || !vm.note.isEmpty || vm.selectedCategoryId != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    switch mode {
                    case .manual:
                        ManualEntryContent(vm: vm, categories: categories, mode: $mode, isTyping: $isTyping)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .opacity
                            ))

                    case .voice:
                        VoiceEntryContent(vm: vm, categories: categories, mode: $mode)
                            .transition(.opacity)

                    case .camera:
                        CameraEntryContent(vm: vm, mode: $mode)
                            .transition(.opacity)
                    }

                    // Save button — always visible in manual mode
                    if mode == .manual {
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
            .toolbar(mode == .voice ? .hidden : .visible, for: .navigationBar)
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
        .preferredColorScheme(preferredScheme)
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

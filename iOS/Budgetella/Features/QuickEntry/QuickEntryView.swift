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
                        premiumGate(
                            icon: "mic.fill",
                            title: "Sesli Giriş",
                            subtitle: "Harcamanı sesli anlat, AI anlasın ve kaydetsin."
                        )
                        .transition(.opacity)

                    case .camera:
                        premiumGate(
                            icon: "camera.fill",
                            title: "Fiş Tarama",
                            subtitle: "Kameranla fişi tara, AI tutarı ve mağazayı otomatik okusun."
                        )
                        .transition(.opacity)
                    }

                    // Full-width save button — only for manual mode
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
            .interactiveDismissDisabled(isTyping)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") { dismiss() }
                        .foregroundStyle(BrandColor.textSecondary)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Button("Bitti") { isTyping = false }
                        .foregroundStyle(BrandColor.textSecondary)
                    Spacer()
                    Button {
                        isTyping = false
                        vm.save(modelContext: modelContext, categories: categories, userId: userId)
                        if vm.errorMessage == nil { dismiss() }
                    } label: {
                        Text("Kaydet")
                            .font(.brand(.subheadline).bold())
                            .foregroundStyle(vm.canSave ? BrandColor.primary : BrandColor.textTertiary)
                    }
                    .disabled(!vm.canSave)
                }
            }
            .toolbarBackground(BrandColor.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $vm.showCategoryPicker) {
                CategoryPickerView(
                    categories: categories,
                    selectedId: $vm.selectedCategoryId
                )
            }
        }
        .preferredColorScheme(.dark)
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
        .preferredColorScheme(.dark)
    }
}

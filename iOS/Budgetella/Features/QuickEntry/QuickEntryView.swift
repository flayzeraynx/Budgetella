//
//  QuickEntryView.swift
//  Budgetella
//
//  04 · Hızlı giriş — 3 mod: manuel (tam), sesli (premium V1.1), kamera (premium V1.1)
//

import SwiftUI
import SwiftData

struct QuickEntryView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @AppStorage("currentUserId") private var userId = ""

    @State private var vm = QuickEntryViewModel()
    @State private var mode: EntryMode = .manual

    enum EntryMode: CaseIterable {
        case manual, voice, camera
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.background.ignoresSafeArea()

                switch mode {
                case .manual:
                    ManualEntryContent(vm: vm, categories: categories)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        ))

                case .voice:
                    premiumGate(icon: "mic.fill", title: "Sesli Giriş",
                                subtitle: "Harcamanı sesli anlat, AI anlasın ve kaydetsin.")
                        .transition(.opacity)

                case .camera:
                    premiumGate(icon: "camera.fill", title: "Fiş Tarama",
                                subtitle: "Kameranla fişi tara, AI tutarı ve mağazayı otomatik okusun.")
                        .transition(.opacity)
                }
            }
            .animation(.spring(response: 0.3), value: mode)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") { dismiss() }
                        .foregroundStyle(BrandColor.textSecondary)
                }
                ToolbarItem(placement: .principal) {
                    modeSelector
                }
                ToolbarItem(placement: .topBarTrailing) {
                    saveButton
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

    // MARK: - Mode selector

    private var modeSelector: some View {
        HStack(spacing: Spacing.xs) {
            modePill(.manual, icon: "keyboard", label: "Manuel")
            modePill(.voice,  icon: "mic.fill",    label: "Sesli")
            modePill(.camera, icon: "camera.fill",  label: "Kamera")
        }
        .padding(3)
        .background(BrandColor.surface.opacity(0.4))
        .clipShape(Capsule())
    }

    private func modePill(_ m: EntryMode, icon: String, label: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) { mode = m }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(label)
                    .font(.brand(.caption))
            }
            .foregroundStyle(mode == m ? .white : BrandColor.textTertiary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 5)
            .background(mode == m ? BrandColor.primary : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Save button

    private var saveButton: some View {
        Button {
            guard mode == .manual else { return }
            vm.save(modelContext: modelContext, categories: categories, userId: userId)
            if vm.errorMessage == nil { dismiss() }
        } label: {
            Text("Kaydet")
                .font(.brand(.subheadline))
                .foregroundStyle(vm.canSave && mode == .manual ? BrandColor.income : BrandColor.textTertiary)
        }
        .disabled(!vm.canSave || mode != .manual)
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

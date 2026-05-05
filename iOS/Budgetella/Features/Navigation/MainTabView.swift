//
//  MainTabView.swift
//  Budgetella
//
//  Ana navigasyon container — 4 tab + center FAB (+)
//  FAB: press & drag → blob menu ile sesli/manuel/kamera seçimi
//

import SwiftUI
import SwiftData

struct MainTabView: View {

    @Environment(\.modelContext) private var modelContext
    @AppStorage("currentUserId") private var currentUserId = ""
    @State private var selectedTab: AppTab = .home
    @State private var showQuickEntry = false
    @State private var entryMode: EntryMode = .manual
    @Query private var settingsArr: [AppSettings]

    private var hideAmounts: Bool { settingsArr.first?.hideAmounts ?? false }

    private var preferredScheme: ColorScheme? {
        switch settingsArr.first?.theme ?? .system {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return nil
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(AppTab.home)
                    .toolbar(.hidden, for: .tabBar)

                TransactionsView()
                    .tag(AppTab.list)
                    .toolbar(.hidden, for: .tabBar)

                StatsView()
                    .tag(AppTab.stats)
                    .toolbar(.hidden, for: .tabBar)

                BudgiView()
                    .tag(AppTab.ai)
                    .toolbar(.hidden, for: .tabBar)
            }
            .padding(.bottom, 72)

            CustomTabBar(selected: $selectedTab, onModeSelect: { mode in
                entryMode = mode
                showQuickEntry = true
            })
        }
        .environment(\.hideAmounts, hideAmounts)
        .preferredColorScheme(preferredScheme)
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showQuickEntry, onDismiss: { entryMode = .manual }) {
            QuickEntryView(initialMode: entryMode)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .task(id: currentUserId) {
            guard !currentUserId.isEmpty else { return }
            try? await FirestoreService.shared.fetchAndSync(
                userId: currentUserId,
                modelContext: modelContext
            )
        }
        .onAppear {
            // Schedule weekly digest local notification
            NotificationService.shared.scheduleWeeklyDigest()
        }
        // Widget deep link + push notification deep link
        .onOpenURL { url in
            handleDeepLink(url)
        }
        .onReceive(NotificationCenter.default.publisher(for: .appDeepLinkReceived)) { note in
            if let url = note.userInfo?["url"] as? URL {
                handleDeepLink(url)
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "budgetella" else { return }
        switch url.host {
        case "add":
            entryMode = .manual
            showQuickEntry = true
        case "transactions":
            withAnimation { selectedTab = .list }
        case "stats":
            withAnimation { selectedTab = .stats }
        case "ai":
            withAnimation { selectedTab = .ai }
        default:
            withAnimation { selectedTab = .home }
        }
    }

}

// MARK: - App Tab enum

enum AppTab: Int, CaseIterable {
    case home  = 0
    case list  = 1
    case stats = 2
    case ai    = 3
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {

    @Binding var selected: AppTab
    let onModeSelect: (EntryMode) -> Void

    @State private var fabMenuVisible = false
    @State private var hoveredOption: EntryMode = .manual

    var body: some View {
        HStack(spacing: 0) {
            tabItem(.home,  icon: "house.fill",    label: "Ev")
            tabItem(.list,  icon: "list.bullet",   label: "Liste")

            // FAB placeholder — fixed size, gesture-only, no layout effect from blob
            fabButton
                .frame(maxWidth: .infinity)
                .offset(y: -10)

            tabItem(.stats, icon: "chart.bar.fill", label: "İstatistik")
            tabItem(.ai,    icon: "sparkles",        label: "AI")
        }
        .padding(.top, 4)
        .padding(.bottom, 8)
        .background(
            BrandColor.background2
                .opacity(0.92)
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
        // Blob is an overlay on the whole HStack — never affects item layout
        .overlay(alignment: .top) {
            if fabMenuVisible {
                fabBlob
                    .allowsHitTesting(false)
                    .offset(y: -88)
                    .transition(.scale(scale: 0.85, anchor: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: fabMenuVisible)
    }

    // MARK: - FAB button (circle only)

    private var fabButton: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [BrandColor.primary, BrandColor.primaryLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
                .shadow(color: BrandColor.primary.opacity(0.5), radius: 12, y: 4)

            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .rotationEffect(fabMenuVisible ? .degrees(45) : .zero)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: fabMenuVisible)
        }
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    if !fabMenuVisible {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            fabMenuVisible = true
                        }
                        hoveredOption = .manual
                    }
                    let dx = value.translation.width
                    let newOption: EntryMode = dx < -50 ? .voice : dx > 50 ? .camera : .manual
                    if newOption != hoveredOption {
                        hoveredOption = newOption
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        fabMenuVisible = false
                    }
                    let selected = hoveredOption
                    hoveredOption = .manual
                    onModeSelect(selected)
                }
        )
    }

    // MARK: - Blob menu view

    private var fabBlob: some View {
        HStack(spacing: 4) {
            blobOption(.voice,  icon: "mic.fill",         label: "Sesli")
            blobOption(.manual, icon: "square.and.pencil", label: "Manuel")
            blobOption(.camera, icon: "camera.fill",       label: "Kamera")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(BrandColor.surface)
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .shadow(color: .black.opacity(0.35), radius: 20, x: 0, y: 8)
        )
    }

    private func blobOption(_ option: EntryMode, icon: String, label: LocalizedStringKey) -> some View {
        let isSelected = hoveredOption == option
        return VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? BrandColor.primary : Color.clear)
                    .frame(width: 52, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(isSelected ? .white : BrandColor.textSecondary)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
            }
            Text(label)
                .font(.brand(.caption))
                .foregroundStyle(isSelected ? BrandColor.primary : BrandColor.textTertiary)
        }
        .frame(width: 68)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
    }

    // MARK: - Tab items

    @ViewBuilder
    private func tabItem(_ tab: AppTab, icon: String, label: LocalizedStringKey) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selected = tab
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 21, weight: selected == tab ? .semibold : .regular))
                    .foregroundStyle(selected == tab ? BrandColor.primary : BrandColor.textTertiary)
                    .scaleEffect(selected == tab ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
                Text(label)
                    .font(.brand(.caption))
                    .foregroundStyle(selected == tab ? BrandColor.primary : BrandColor.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
        .buttonStyle(.plain)
    }
}

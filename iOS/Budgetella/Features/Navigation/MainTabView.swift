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
    @State private var dragOffset: CGFloat = 0
    // Lazy tab mounting: only views that have been activated (or are adjacent
    // to the active tab) are rendered. Avoids the cost of evaluating all four
    // tab view-graphs eagerly at launch.
    @State private var mountedTabs: Set<AppTab> = [.home, .list]
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
            // Custom horizontal paging. Each tab is rendered side-by-side in a
            // ZStack and translated by (tabIndex − selectedIndex) × screenWidth.
            // This is built by hand rather than via `.tabViewStyle(.page)` because
            // UIPageViewController (which `.page` wraps under the hood) crashes
            // when child pages own NavigationStacks of their own — every screen
            // in this app does, so .page is off the table.
            // All four tabs stay mounted, so scroll positions, filters, and
            // SwiftUI @State inside each NavigationStack survive tab switches.
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    pageContainer(.home, width: geo.size.width, height: geo.size.height)
                    pageContainer(.list, width: geo.size.width, height: geo.size.height)
                    pageContainer(.stats, width: geo.size.width, height: geo.size.height)
                    pageContainer(.ai, width: geo.size.width, height: geo.size.height)
                }
                .contentShape(Rectangle())
                .simultaneousGesture(pageSwipeGesture(screenWidth: geo.size.width))
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
            // FCM token login'den önce geldiyse (MessagingDelegate'te uid boştu)
            // şimdi proaktif olarak Firestore'a yaz
            NotificationService.shared.syncPendingTokenIfNeeded(userId: currentUserId)
            try? await FirestoreService.shared.fetchAndSync(
                userId: currentUserId,
                modelContext: modelContext
            )
            // Real-time listener — keeps SwiftData in sync with writes coming
            // from Android (or any other client) while the app is in the
            // foreground. Idempotent; stops automatically on sign-out via the
            // SignOutService cleanup path below.
            FirestoreService.shared.startObserving(
                userId: currentUserId,
                modelContext: modelContext
            )
            // Cold-launch deep-link: if a push tap fired before MainTabView was
            // mounted the NotificationCenter post fired into the void. Consume the
            // stored URL here, AFTER sync so the UI is ready. The .onReceive below
            // clears this value for warm-launch taps, so no double-fire risk.
            if let url = NotificationService.shared.pendingDeepLinkURL {
                NotificationService.shared.pendingDeepLinkURL = nil
                handleDeepLink(url)
            }
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
                // Warm-launch: clear cold-launch store so .task(id:) doesn't re-fire.
                NotificationService.shared.pendingDeepLinkURL = nil
                handleDeepLink(url)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToBudgiTab)) { _ in
            withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) { selectedTab = .ai }
        }
        // Mount the new tab's neighbours just before the user can swipe to
        // them. Initial mount on appear seeds {.home, .list}; from there each
        // selection extends the set so the next swipe finds the page ready.
        .onAppear { ensureAdjacentMounted(for: selectedTab) }
        .onChange(of: selectedTab) { _, newTab in
            ensureAdjacentMounted(for: newTab)
        }
    }

    // MARK: - Page layout

    @ViewBuilder
    private func pageContainer(_ tab: AppTab, width: CGFloat, height: CGFloat) -> some View {
        Group {
            if mountedTabs.contains(tab) {
                switch tab {
                case .home:  DashboardView()
                case .list:  TransactionsView()
                case .stats: StatsView()
                case .ai:    BudgiView()
                }
            } else {
                // Placeholder for tabs the user hasn't reached yet. The
                // background colour matches the rest of the app so even if the
                // user catches a glimpse during a swipe (they shouldn't —
                // ensureAdjacent mounts neighbours before they're visible) it
                // looks like an empty page rather than a missing one.
                BrandColor.background
            }
        }
        .frame(width: width, height: height)
        .offset(x: pageOffset(for: tab, width: width))
        // Only the active page should receive taps so an off-screen page's
        // controls (e.g. an invisible toolbar button) can't be triggered.
        .allowsHitTesting(tab == selectedTab && dragOffset == 0)
    }

    /// Marks the active tab + its immediate neighbours as mounted. Once a tab
    /// is mounted it stays mounted for the life of the app so navigation state
    /// (filters, scroll position, edit sheets) survives subsequent switches.
    private func ensureAdjacentMounted(for tab: AppTab) {
        let tabs = AppTab.allCases
        guard let idx = tabs.firstIndex(of: tab) else { return }
        var next = mountedTabs
        next.insert(tab)
        if idx > 0 { next.insert(tabs[idx - 1]) }
        if idx < tabs.count - 1 { next.insert(tabs[idx + 1]) }
        if next != mountedTabs { mountedTabs = next }
    }

    private func pageOffset(for tab: AppTab, width: CGFloat) -> CGFloat {
        let delta = CGFloat(tab.rawValue - selectedTab.rawValue)
        return delta * width + dragOffset
    }

    // MARK: - Page swipe gesture

    private func pageSwipeGesture(screenWidth: CGFloat) -> some Gesture {
        // minimumDistance lets inner horizontal scrollviews (the category chip
        // strip in TransactionsView, etc.) win short drags. Only swipes that
        // clear ~24 pt and stay clearly horizontal start translating pages.
        DragGesture(minimumDistance: 24, coordinateSpace: .local)
            .onChanged { value in
                let dx = value.translation.width
                let dy = value.translation.height
                guard abs(dx) > abs(dy) * 1.5 else { return }

                // Resist past the leading/trailing edges so the user feels they
                // can't keep dragging into nothing.
                let atLeft  = selectedTab == AppTab.allCases.first && dx > 0
                let atRight = selectedTab == AppTab.allCases.last  && dx < 0
                if atLeft || atRight {
                    dragOffset = dx * 0.25
                } else {
                    dragOffset = dx
                }
            }
            .onEnded { value in
                let dx = value.translation.width
                let velocity = value.velocity.width
                let commitThreshold = screenWidth * 0.22
                let flickThreshold: CGFloat = 480

                let goesNext = dx < -commitThreshold || velocity < -flickThreshold
                let goesPrev = dx >  commitThreshold || velocity >  flickThreshold

                let tabs = AppTab.allCases
                let snapAnimation: Animation = .spring(response: 0.34, dampingFraction: 0.86)

                if goesNext, let idx = tabs.firstIndex(of: selectedTab), idx < tabs.count - 1 {
                    withAnimation(snapAnimation) {
                        dragOffset = 0
                        selectedTab = tabs[idx + 1]
                    }
                } else if goesPrev, let idx = tabs.firstIndex(of: selectedTab), idx > 0 {
                    withAnimation(snapAnimation) {
                        dragOffset = 0
                        selectedTab = tabs[idx - 1]
                    }
                } else {
                    withAnimation(snapAnimation) { dragOffset = 0 }
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
        case "notifications":
            // Tab switch is ~0.3 s spring; delay lets DashboardView settle before
            // it receives .appShowNotifications and presents the inbox sheet.
            withAnimation { selectedTab = .home }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                NotificationCenter.default.post(name: .appShowNotifications, object: nil)
            }
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
            // MainTabView positions pages by `(tabIndex - selectedIndex) × width`,
            // so changing the binding inside `withAnimation` drives the same
            // spring slide that a swipe-release uses. Keep the timing aligned
            // with `pageSwipeGesture`'s snap animation.
            withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
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

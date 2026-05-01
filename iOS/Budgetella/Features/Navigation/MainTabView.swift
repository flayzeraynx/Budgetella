//
//  MainTabView.swift
//  Budgetella
//
//  Ana navigasyon container — 4 tab + center FAB (+)
//  Tab bar custom overlay; sistem tab bar gizli.
//

import SwiftUI

struct MainTabView: View {

    @State private var selectedTab: AppTab = .home
    @State private var showQuickEntry = false

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
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 72)
            }

            CustomTabBar(selected: $selectedTab, onFABTap: { showQuickEntry = true })
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showQuickEntry) {
            QuickEntryView()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .preferredColorScheme(.dark)
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
    let onFABTap: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            tabItem(.home,  icon: "house.fill",    label: "Home")
            tabItem(.list,  icon: "list.bullet",   label: "List")

            // FAB — center
            Button(action: onFABTap) {
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
                }
            }
            .frame(maxWidth: .infinity)
            .offset(y: -10)

            tabItem(.stats, icon: "chart.bar.fill", label: "Stats")
            tabItem(.ai,    icon: "sparkles",        label: "AI")
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.top, Spacing.sm)
        .safeAreaPadding(.bottom)
        .background(
            BrandColor.background2
                .opacity(0.92)
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    @ViewBuilder
    private func tabItem(_ tab: AppTab, icon: String, label: String) -> some View {
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

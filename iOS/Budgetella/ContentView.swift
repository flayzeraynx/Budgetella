//
//  ContentView.swift
//  Budgetella
//
//  Geçici placeholder. Tasarım onayından sonra burası MainTabView ile değiştirilecek
//  (Onboarding gating + Auth gating + TabView ile Dashboard/Transactions/Insights/Settings).
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "wallet.pass.fill")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 8) {
                Text("Budgetella")
                    .font(.largeTitle.bold())

                Text("iOS native — geliştirme aşamasında")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("v1.0 yapım aşamasında")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview("Light") {
    ContentView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ContentView()
        .preferredColorScheme(.dark)
}

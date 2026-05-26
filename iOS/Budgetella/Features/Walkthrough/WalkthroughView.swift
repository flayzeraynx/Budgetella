//
//  WalkthroughView.swift
//  Budgetella
//
//  v1.1.0 — post-auth feature tutorial. Shown once after first sign-in,
//  before the main tab. SpinDeck OnboardingView referans alındı.
//
//  Lottie SPM dep eklendi; her sayfa önce `walkthrough_*.json` yüklemeye
//  çalışır, bundle'da yoksa SF Symbol fallback'ine düşer. JSON dosyaları
//  Budgetella/Resources/Lottie/ altına atılınca otomatik aktive olur.
//

import SwiftUI
import Lottie

struct WalkthroughPage: Identifiable {
    let id = UUID()
    let lottieName: String
    let symbol: String
    let symbolColor: Color
    let title: LocalizedStringKey
    let body: LocalizedStringKey
}

struct WalkthroughView: View {

    var onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var index = 0

    private var pages: [WalkthroughPage] {
        [
            WalkthroughPage(
                lottieName: "walkthrough_add",
                symbol: "plus.circle.fill",
                symbolColor: BrandColor.primary,
                title: "İşlem Ekle",
                body: "Sağ alttaki + tuşu ile saniyeler içinde gelir veya gider ekle. Ses ve fiş tarama ile daha da hızlı."
            ),
            WalkthroughPage(
                lottieName: "walkthrough_summary",
                symbol: "chart.pie.fill",
                symbolColor: BrandColor.income,
                title: "Aylık Özet",
                body: "Nereye ne kadar harcadığını gör. Aylık karşılaştırma ve trend grafiklerle alışkanlıklarını keşfet."
            ),
            WalkthroughPage(
                lottieName: "walkthrough_goal",
                symbol: "target",
                symbolColor: BrandColor.warning,
                title: "Bütçe Hedefi",
                body: "Kategorilere bütçe belirle, hedeflerini takip et. Tasarrufunu artır, harcamalarını kontrol altına al."
            )
        ]
    }

    var body: some View {
        ZStack {
            BrandColor.background.ignoresSafeArea()

            RadialGradient(
                colors: [BrandColor.primary.opacity(0.22), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 520
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Atla") { finish() }
                        .font(.brand(.subheadline))
                        .foregroundStyle(BrandColor.textTertiary)
                        .padding(.trailing, 22)
                        .padding(.top, 12)
                        .opacity(index == pages.count - 1 ? 0 : 1)
                        .accessibilityHidden(index == pages.count - 1)
                }

                TabView(selection: $index) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { i, page in
                        pageView(page).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut, value: index)

                pageDots
                    .padding(.bottom, 8)

                Button(action: advance) {
                    Text(index == pages.count - 1 ? "Hadi Başlayalım" : "İleri")
                        .font(.brand(.headline))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(BrandColor.primary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
                .padding(.top, 18)
            }
        }
    }

    private func pageView(_ page: WalkthroughPage) -> some View {
        VStack(spacing: 26) {
            Spacer()
            heroView(page)
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.brand(.title))
                    .foregroundStyle(BrandColor.textPrimary)
                Text(page.body)
                    .font(.brand(.body))
                    .foregroundStyle(BrandColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private func heroView(_ page: WalkthroughPage) -> some View {
        if let animation = LottieAnimation.named(page.lottieName) {
            LottieView(animation: animation)
                .playing(loopMode: .loop)
                .resizable()
                .frame(width: 220, height: 220)
        } else {
            // Fallback — bundle'da Lottie JSON yoksa SF Symbol göster.
            ZStack {
                Circle()
                    .fill(page.symbolColor.opacity(0.14))
                    .frame(width: 180, height: 180)
                Circle()
                    .strokeBorder(page.symbolColor.opacity(0.35), lineWidth: 1)
                    .frame(width: 180, height: 180)
                Image(systemName: page.symbol)
                    .font(.system(size: 76, weight: .regular))
                    .foregroundStyle(page.symbolColor)
                    .symbolEffect(.bounce, value: index)
            }
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { i in
                Capsule()
                    .fill(i == index ? BrandColor.primary : BrandColor.textTertiary.opacity(0.3))
                    .frame(width: i == index ? 22 : 7, height: 7)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: index)
            }
        }
    }

    private func advance() {
        if index < pages.count - 1 {
            withAnimation(reduceMotion ? nil : .easeInOut) { index += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: "hasSeenWalkthrough")
        onFinish()
    }
}

#Preview {
    WalkthroughView(onFinish: {})
        .preferredColorScheme(.dark)
}

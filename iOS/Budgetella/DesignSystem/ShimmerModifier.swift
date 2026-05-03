//
//  ShimmerModifier.swift
//  Budgetella
//

import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    let band = geo.size.width * 0.58
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: Color.white.opacity(0.42), location: 0.5),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: band)
                    .offset(x: phase * (geo.size.width + band) - band)
                }
                .clipped()
            )
            .onAppear {
                phase = 0
                withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    @ViewBuilder
    func shimmer(active: Bool = true) -> some View {
        if active {
            modifier(ShimmerModifier())
        } else {
            self
        }
    }
}

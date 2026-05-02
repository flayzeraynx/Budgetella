//
//  BrandAlert.swift
//  Budgetella
//
//  Merkezi, blur-background'lu custom alert overlay.
//  iOS native confirmationDialog sheet içinde popover gibi davrandığı için bu custom versiyon kullanılır.
//

import SwiftUI

struct BrandAlertButton {
    let title: String
    let role: ButtonRole?
    let action: () -> Void

    static func destructive(_ title: String, action: @escaping () -> Void) -> BrandAlertButton {
        BrandAlertButton(title: title, role: .destructive, action: action)
    }
    static func cancel(_ title: String = "Vazgeç") -> BrandAlertButton {
        BrandAlertButton(title: title, role: .cancel, action: {})
    }
}

extension View {
    func brandAlert(
        title: String,
        message: String? = nil,
        isPresented: Binding<Bool>,
        buttons: [BrandAlertButton]
    ) -> some View {
        // ZStack sibling — material blur samples the rendered content of self
        ZStack {
            self
            if isPresented.wrappedValue {
                BrandAlertOverlay(
                    title: title,
                    message: message,
                    isPresented: isPresented,
                    buttons: buttons
                )
                .ignoresSafeArea()
            }
        }
    }
}

private struct BrandAlertOverlay: View {

    let title: String
    let message: String?
    @Binding var isPresented: Bool
    let buttons: [BrandAlertButton]

    @State private var appeared = false

    var body: some View {
        ZStack {
            // Frosted glass backdrop
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .opacity(appeared ? 1 : 0)

            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    Text(title)
                        .font(.brand(.headline))
                        .foregroundStyle(BrandColor.textPrimary)
                        .multilineTextAlignment(.center)
                    if let msg = message {
                        Text(msg)
                            .font(.brand(.footnote))
                            .foregroundStyle(BrandColor.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 18)

                Rectangle()
                    .fill(BrandColor.borderSubtle)
                    .frame(height: 1)

                ForEach(Array(buttons.enumerated()), id: \.offset) { idx, btn in
                    if idx > 0 {
                        Rectangle()
                            .fill(BrandColor.borderSubtle)
                            .frame(height: 1)
                    }
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) { isPresented = false }
                        btn.action()
                    } label: {
                        Text(btn.title)
                            .font(.brand(btn.role == .destructive ? .headline : .body))
                            .foregroundStyle(buttonColor(btn))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
            }
            // Glass card: dark base + thin material layer
            .background(
                ZStack {
                    BrandColor.background2.opacity(0.92)
                    Color.white.opacity(0.04)
                }
            )
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.18), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.4), radius: 32, y: 12)
            .padding(.horizontal, 44)
            .scaleEffect(appeared ? 1 : 0.88)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                appeared = true
            }
        }
    }

    private func buttonColor(_ btn: BrandAlertButton) -> Color {
        switch btn.role {
        case .destructive: return BrandColor.expense
        case .cancel:      return BrandColor.textSecondary
        default:           return BrandColor.primary
        }
    }
}

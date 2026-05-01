//
//  AuthView.swift
//  Budgetella
//
//  Auth akış container — AuthViewModel state machine'e göre ekranlar arası geçiş.
//  7 ekran: welcome → signUp → otp | signIn → forgotPassword | faceIDSetup | faceIDLock
//

import SwiftUI

struct AuthView: View {

    var onAuthComplete: () -> Void

    @State private var vm = AuthViewModel(authService: AuthService())

    var body: some View {
        ZStack {
            BrandColor.background.ignoresSafeArea()

            Group {
                switch vm.screen {
                case .welcome:
                    AuthWelcomeView(vm: vm, onAuthComplete: onAuthComplete)

                case .signUp:
                    AuthSignUpView(vm: vm, onAuthComplete: onAuthComplete)

                case .signIn:
                    AuthSignInView(vm: vm, onAuthComplete: onAuthComplete)

                case .otp(let email):
                    AuthOTPView(vm: vm, email: email) {
                        // OTP doğrulandıktan sonra Face ID setup öner
                        vm.navigate(to: .faceIDSetup)
                    }

                case .forgotPassword:
                    AuthForgotPasswordView(vm: vm)

                case .faceIDSetup:
                    AuthFaceIDSetupView(vm: vm, onComplete: onAuthComplete)
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal:   .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.spring(response: 0.4, dampingFraction: 0.88), value: vm.screen)
        }
        .preferredColorScheme(.dark)
    }
}

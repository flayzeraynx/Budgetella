//
//  PasswordStrengthView.swift
//  Budgetella
//
//  Şifre güç metresi — 4 kriter, renkli bar.
//

import SwiftUI

struct PasswordStrength {
    let score: Int          // 0-4
    let metCriteria: Int    // kaç kriter sağlandı

    var label: String {
        switch score {
        case 0: return "Çok zayıf"
        case 1: return "Zayıf"
        case 2: return "Orta"
        case 3: return "Güçlü"
        case 4: return "Çok güçlü"
        default: return ""
        }
    }

    var color: Color {
        switch score {
        case 0, 1: return BrandColor.expense
        case 2:    return BrandColor.warning
        case 3:    return Color(hex: "#A3E635")  // lime
        case 4:    return BrandColor.income
        default:   return BrandColor.borderSubtle
        }
    }

    static func evaluate(_ password: String) -> PasswordStrength {
        var score = 0
        if password.count >= 8          { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil    { score += 1 }
        let special = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;':\",./<>?")
        if password.unicodeScalars.contains(where: special.contains) { score += 1 }
        return PasswordStrength(score: score, metCriteria: score)
    }
}

struct PasswordStrengthView: View {

    let password: String
    private var strength: PasswordStrength { .evaluate(password) }

    var body: some View {
        guard !password.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // 4 bar
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { i in
                        Capsule()
                            .fill(i < strength.score ? strength.color : BrandColor.borderSubtle)
                            .frame(height: 4)
                            .animation(.spring(response: 0.3), value: strength.score)
                    }
                }

                HStack(spacing: 4) {
                    Text("Şifre gücü:")
                        .font(.brand(.caption))
                        .foregroundStyle(BrandColor.textTertiary)
                    Text(strength.label)
                        .font(.brand(.caption))
                        .foregroundStyle(strength.color)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(strength.metCriteria)/4 kriter")
                        .font(.brand(.caption))
                        .foregroundStyle(BrandColor.textTertiary)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(BrandColor.income)
                }
            }
        )
    }
}

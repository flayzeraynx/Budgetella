//
//  EnvironmentKeys.swift
//  Budgetella
//

import SwiftUI

private struct HideAmountsKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var hideAmounts: Bool {
        get { self[HideAmountsKey.self] }
        set { self[HideAmountsKey.self] = newValue }
    }
}

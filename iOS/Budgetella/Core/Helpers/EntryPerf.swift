//
//  EntryPerf.swift
//  Budgetella
//
//  TEMPORARY timing probe for the manual-entry keyboard-latency investigation.
//  Logs appear in Console.app (and Xcode) filtered by category "EntryPerf" —
//  works on a real device and TestFlight, no cable required.
//
//  How to read on device:
//   1. Connect iPhone, open Console.app on the Mac (or just Xcode console).
//   2. Filter by category "EntryPerf" (or search the ⏱️ marker).
//   3. Tap + → Manuel, watch the timeline. Each line shows ms since the FAB tap.
//
//  The biggest jump between two adjacent lines is the bottleneck. Remove this
//  file + its call sites once the cause is found.
//

import Foundation
import OSLog

enum EntryPerf {
    private static let log = Logger(subsystem: "com.ozankilic.budgetella", category: "EntryPerf")
    // Temporary diagnostic — single-writer (main) usage, exact thread-safety
    // doesn't matter for a stopwatch, so opt out of Swift 6's shared-state check.
    nonisolated(unsafe) private static var t0 = CFAbsoluteTimeGetCurrent()

    /// Reset the clock — call at the very start (FAB tap).
    static func begin(_ label: String) {
        t0 = CFAbsoluteTimeGetCurrent()
        log.notice("⏱️ 0 ms — \(label, privacy: .public)")
    }

    /// Log ms elapsed since `begin`.
    static func mark(_ label: String) {
        let ms = Int((CFAbsoluteTimeGetCurrent() - t0) * 1000)
        log.notice("⏱️ \(ms, privacy: .public) ms — \(label, privacy: .public)")
    }

    /// Standalone event (own timestamp via Console) — used to time the launch
    /// sync, which runs before the FAB tap so the relative clock doesn't apply.
    static func event(_ label: String) {
        log.notice("🔧 \(label, privacy: .public)")
    }
}

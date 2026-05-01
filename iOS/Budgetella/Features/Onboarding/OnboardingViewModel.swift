//
//  OnboardingViewModel.swift
//  Budgetella
//

import Foundation
import SwiftUI
import SwiftData
import AVFoundation
import UserNotifications

@MainActor
@Observable
final class OnboardingViewModel {

    var currentStep: Int = 0          // 0=welcome, 1=features, 2=currency, 3=permissions
    var selectedCurrency: AppCurrency = .tryLira
    var microphoneEnabled = false
    var cameraEnabled = false
    var notificationsEnabled = false
    var isCompleting = false

    let totalSteps = 4

    // MARK: - Navigation

    func advance() {
        guard currentStep < totalSteps - 1 else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            currentStep += 1
        }
    }

    func skip() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            currentStep = totalSteps - 1
        }
    }

    // MARK: - Permissions

    func requestMicrophone() async {
        let status = await AVAudioApplication.requestRecordPermission()
        microphoneEnabled = status
    }

    func requestCamera() async {
        let status = await AVCaptureDevice.requestAccess(for: .video)
        cameraEnabled = status
    }

    func requestNotifications() async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        notificationsEnabled = granted
    }

    // MARK: - Complete

    func complete(modelContext: ModelContext, userId: String) {
        isCompleting = true
        let settings = AppSettings(userId: userId)
        settings.currency = selectedCurrency
        modelContext.insert(settings)
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

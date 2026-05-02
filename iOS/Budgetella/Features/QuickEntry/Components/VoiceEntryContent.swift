//
//  VoiceEntryContent.swift
//  Budgetella
//
//  Sesli giriş — SFSpeechRecognizer ile gerçek zamanlı transkripsiyon.
//  Söylenen cümleden tutar ve açıklama parse edilir, form doldurulur.
//

import SwiftUI
import Speech
import AVFoundation

struct VoiceEntryContent: View {

    @Bindable var vm: QuickEntryViewModel
    @Binding var mode: EntryMode

    @State private var recognizer = SpeechEntryRecognizer()
    @State private var phase: Phase = .idle

    enum Phase { case idle, requesting, listening, parsed, error(String) }

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Microphone ring
            micRing
                .onTapGesture { handleTap() }

            // Status text
            statusText

            // Transcript preview
            if !recognizer.transcript.isEmpty {
                transcriptPreview
            }

            // Action hint
            hintText

            Spacer()

            // Use / Retry / Back
            if case .parsed = phase { actionRow }

            // Back to manual
            Button {
                recognizer.stop()
                withAnimation(.spring(response: 0.3)) { mode = .manual }
            } label: {
                Text("Manuel Girişe Dön")
                    .font(.brand(.footnote))
                    .foregroundStyle(BrandColor.textTertiary)
            }
            .buttonStyle(.plain)
            .padding(.bottom, Spacing.xl)
        }
        .padding(.horizontal, 32)
        .onDisappear { recognizer.stop() }
    }

    // MARK: - Microphone ring

    private func listeningRing(index: Int) -> some View {
        let opacity = 0.15 - Double(index) * 0.04
        let size = CGFloat(100 + index * 28)
        let scale = Double(recognizer.audioLevel) * 0.6 + 1.0
        return Circle()
            .stroke(BrandColor.primary.opacity(opacity), lineWidth: 2)
            .frame(width: size, height: size)
            .scaleEffect(scale)
            .animation(.easeInOut(duration: 0.1), value: recognizer.audioLevel)
    }

    private var micRing: some View {
        ZStack {
            // Animated outer rings
            if case .listening = phase {
                ForEach(0..<3, id: \.self) { i in
                    listeningRing(index: i)
                }
            }

            Circle()
                .fill(micBackground)
                .frame(width: 96, height: 96)
                .shadow(color: micShadow, radius: 20, y: 6)

            Image(systemName: micIcon)
                .font(.system(size: 38, weight: .medium))
                .foregroundStyle(.white)
                .symbolRenderingMode(.hierarchical)
        }
        .animation(.spring(response: 0.4), value: "\(phase)")
    }

    // MARK: - Status

    private var statusText: some View {
        Group {
            switch phase {
            case .idle:
                Text("Konuşmak için dokun")
                    .font(.brand(.title))
                    .foregroundStyle(BrandColor.textPrimary)
            case .requesting:
                Text("İzin isteniyor…")
                    .font(.brand(.title))
                    .foregroundStyle(BrandColor.textTertiary)
            case .listening:
                Text("Dinliyorum…")
                    .font(.brand(.title))
                    .foregroundStyle(BrandColor.primary)
            case .parsed:
                VStack(spacing: 4) {
                    Text("₺\(vm.rawInput)")
                        .font(.brand(.displayHero))
                        .foregroundStyle(BrandColor.textPrimary)
                        .contentTransition(.numericText())
                    if !vm.note.isEmpty {
                        Text(vm.note)
                            .font(.brand(.body))
                            .foregroundStyle(BrandColor.textTertiary)
                    }
                }
            case .error(let msg):
                Text(msg)
                    .font(.brand(.body))
                    .foregroundStyle(BrandColor.expense)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var transcriptPreview: some View {
        Text("\"\(recognizer.transcript)\"")
            .font(.brand(.footnote))
            .foregroundStyle(BrandColor.textTertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(BrandColor.surface.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSmall, style: .continuous))
            .transition(.opacity)
    }

    private var hintText: some View {
        Group {
            switch phase {
            case .idle:
                Text("Örnek: \"120 lira yemek\" ya da \"Kahve kırk beş\"")
                    .font(.brand(.footnote))
                    .foregroundStyle(BrandColor.textTertiary)
                    .multilineTextAlignment(.center)
            case .listening:
                Text("Tutarı ve açıklamayı söyle, durdu duyunca işle")
                    .font(.brand(.footnote))
                    .foregroundStyle(BrandColor.textTertiary)
                    .multilineTextAlignment(.center)
            default:
                EmptyView()
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: Spacing.md) {
            Button {
                phase = .idle
                recognizer.transcript = ""
                vm.rawInput = ""
                vm.note = ""
            } label: {
                Text("Tekrar Dene")
                    .font(.brand(.subheadline))
                    .foregroundStyle(BrandColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(BrandColor.surface.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.spring(response: 0.3)) { mode = .manual }
            } label: {
                Text("Manuel Düzenle")
                    .font(.brand(.subheadline))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        LinearGradient(colors: [BrandColor.primary, BrandColor.primaryLight],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Colors

    private var micBackground: LinearGradient {
        switch phase {
        case .listening:
            return LinearGradient(colors: [BrandColor.expense, BrandColor.expense.opacity(0.7)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        case .parsed:
            return LinearGradient(colors: [BrandColor.income, BrandColor.income.opacity(0.7)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [BrandColor.primary, BrandColor.primaryLight],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var micShadow: Color {
        switch phase {
        case .listening: return BrandColor.expense.opacity(0.4)
        case .parsed:    return BrandColor.income.opacity(0.4)
        default:         return BrandColor.primary.opacity(0.4)
        }
    }

    private var micIcon: String {
        switch phase {
        case .listening:      return "mic.fill"
        case .parsed:         return "checkmark"
        case .error:          return "mic.slash.fill"
        default:              return "mic.fill"
        }
    }

    // MARK: - Tap handler

    private func handleTap() {
        switch phase {
        case .idle, .error:
            startListening()
        case .listening:
            stopAndParse()
        case .parsed:
            startListening()
        case .requesting:
            break
        }
    }

    private func startListening() {
        phase = .requesting
        Task { @MainActor in
            let granted = await recognizer.requestAuthorization()
            if granted {
                phase = .listening
                recognizer.start()
            } else {
                phase = .error("Ses tanıma izni verilmedi.\nAyarlar > Budgetella > Konuşma Tanıma")
            }
        }
    }

    private func stopAndParse() {
        recognizer.stop()
        let text = recognizer.transcript.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else {
            phase = .idle
            return
        }
        if let (amount, note) = VoiceParser.parse(text) {
            vm.rawInput = amount
            vm.note = note
            vm.updateSuggestions()
            withAnimation(.spring(response: 0.4)) { phase = .parsed }
        } else {
            phase = .error("Tutar anlaşılamadı.\nTekrar dene veya manuel giriş kullan.")
        }
    }
}

// MARK: - Speech recognizer wrapper

// @unchecked Sendable: AVAudioEngine/SFSpeech types are not Sendable but we manage
// concurrency manually — audio props accessed from background tap, UI props updated
// via Task { @MainActor in } ensuring main-thread observation.
@Observable
final class SpeechEntryRecognizer: @unchecked Sendable {

    var transcript: String = ""
    var audioLevel: Float = 0

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "tr-TR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    func requestAuthorization() async -> Bool {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        guard speechStatus == .authorized else { return false }
        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func start() {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else { return }
        do {
            let avSession = AVAudioSession.sharedInstance()
            try avSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try avSession.setActive(true, options: .notifyOthersOnDeactivation)

            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let request = recognitionRequest else { return }
            request.shouldReportPartialResults = true

            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, _ in
                if let result {
                    let text = result.bestTranscription.formattedString
                    Task { @MainActor in self?.transcript = text }
                }
            }

            let node = audioEngine.inputNode
            let fmt  = node.outputFormat(forBus: 0)
            node.installTap(onBus: 0, bufferSize: 1024, format: fmt) { [weak self] buffer, _ in
                // No @MainActor property access here — class is not @MainActor
                self?.recognitionRequest?.append(buffer)
                guard let channelData = buffer.floatChannelData?[0] else { return }
                let frameLength = Int(buffer.frameLength)
                var sum: Float = 0
                for i in 0..<frameLength { sum += abs(channelData[i]) }
                let avg = frameLength > 0 ? sum / Float(frameLength) : 0
                let level = min(avg * 300, 1.0)
                Task { @MainActor in self?.audioLevel = level }
            }

            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            Task { @MainActor in self.transcript = "" }
        }
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        Task { @MainActor in self.audioLevel = 0 }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    deinit {
        audioEngine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

// MARK: - Voice parser

enum VoiceParser {

    static func parse(_ text: String) -> (rawAmount: String, note: String)? {
        let lower = text.lowercased()

        // Try digit extraction first: "125 lira yemek"
        if let (amount, remainder) = extractDigitAmount(from: lower) {
            return (amount, cleanNote(remainder))
        }

        // Try Turkish number words
        if let (amount, remainder) = extractTurkishAmount(from: lower) {
            return (amount, cleanNote(remainder))
        }

        return nil
    }

    // Extract "125", "125.50", "125,50" followed by optional currency keyword
    private static func extractDigitAmount(from text: String) -> (String, String)? {
        let pattern = #"(\d+)[,\.]?(\d{1,2})?\s*(?:lira|tl|₺|try)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let nsText = text as NSString
        guard let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: nsText.length)) else { return nil }

        let whole = nsText.substring(with: match.range(at: 1))
        var amount = whole
        if match.range(at: 2).location != NSNotFound {
            let frac = nsText.substring(with: match.range(at: 2))
            amount += ",\(frac)"
        }

        let fullMatchRange = match.range(at: 0)
        let after = (fullMatchRange.location + fullMatchRange.length < nsText.length)
            ? nsText.substring(from: fullMatchRange.location + fullMatchRange.length)
            : ""
        let before = fullMatchRange.location > 0
            ? nsText.substring(to: fullMatchRange.location)
            : ""

        let remainder = (before + " " + after).trimmingCharacters(in: .whitespaces)
        return (amount, remainder)
    }

    private static let turkishNumbers: [(String, Int)] = [
        ("bin", 1000), ("yüz", 100), ("elli", 50), ("kırk", 40), ("otuz", 30),
        ("yirmi", 20), ("on dokuz", 19), ("on sekiz", 18), ("on yedi", 17),
        ("on altı", 16), ("on beş", 15), ("on dört", 14), ("on üç", 13),
        ("on iki", 12), ("on bir", 11), ("on", 10), ("dokuz", 9),
        ("sekiz", 8), ("yedi", 7), ("altı", 6), ("beş", 5),
        ("dört", 4), ("üç", 3), ("iki", 2), ("bir", 1)
    ]

    private static func extractTurkishAmount(from text: String) -> (String, String)? {
        var remaining = text
        var total = 0

        for (word, value) in turkishNumbers {
            if remaining.contains(word) {
                remaining = remaining.replacingOccurrences(of: word, with: "")
                total += value
            }
        }

        guard total > 0 else { return nil }

        // Remove currency keywords
        for kw in ["lira", "tl", "₺"] {
            remaining = remaining.replacingOccurrences(of: kw, with: "")
        }

        return ("\(total)", remaining)
    }

    private static func cleanNote(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
           .components(separatedBy: .whitespaces)
           .filter { !$0.isEmpty }
           .joined(separator: " ")
    }
}

//
//  VoiceEntryContent.swift
//  Budgetella
//
//  Sesli giriş — immersive dark UI, press-and-hold mic, SFSpeechRecognizer.
//  Basılı tut → dinle, bırak → parse et.
//

import SwiftUI
import Speech
import AVFoundation

struct VoiceEntryContent: View {

    @Bindable var vm: QuickEntryViewModel
    let categories: [Category]
    @Binding var mode: EntryMode

    @State private var recognizer = SpeechEntryRecognizer()
    @State private var phase: Phase = .idle
    @State private var hasStartedListening = false

    enum Phase {
        case idle, requesting, listening, parsed, error(String)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Forced dark background
            Color(hex: "#0A0B14").ignoresSafeArea()

            // Radial glow from bottom (reacts to listening state)
            RadialGradient(
                colors: [Color(hex: "#6E5BFF").opacity(isListening ? 0.22 : 0.07), .clear],
                center: .bottom,
                startRadius: 0,
                endRadius: 380
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: isListening)

            VStack(spacing: 0) {
                // ── Header
                headerRow
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                Spacer()

                // ── Center content (transcript / parsed card)
                centerContent
                    .padding(.horizontal, 24)

                Spacer()

                // ── Waveform (while listening)
                if isListening {
                    waveformBars
                        .padding(.bottom, 28)
                        .transition(.opacity)
                }

                // ── Mic button + hint
                micSection
                    .padding(.horizontal, 32)
                    .padding(.bottom, 36)
            }
        }
        .colorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        .onDisappear { recognizer.stop() }
        .animation(.spring(response: 0.4), value: isListening)
        .animation(.spring(response: 0.4), value: isParsed)
    }

    // MARK: - Header row

    private var headerRow: some View {
        ZStack {
            HStack {
                closeButton
                Spacer()
            }
            statusPill
        }
    }

    private var closeButton: some View {
        Button {
            recognizer.stop()
            withAnimation(.spring(response: 0.3)) { mode = .manual }
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(.white.opacity(0.12))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var statusPill: some View {
        HStack(spacing: 6) {
            switch phase {
            case .listening:
                Circle()
                    .fill(Color(hex: "#FF4D4D"))
                    .frame(width: 7, height: 7)
                Text("DİNLİYOR")
                    .font(.brand(.caption))
                    .foregroundStyle(.white)
                    .tracking(1.0)
            case .parsed:
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(hex: "#4CAF50"))
                Text("ANLAŞILDI")
                    .font(.brand(.caption))
                    .foregroundStyle(.white)
                    .tracking(1.0)
            case .error:
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(hex: "#FF9500"))
                Text("HATA")
                    .font(.brand(.caption))
                    .foregroundStyle(.white)
                    .tracking(1.0)
            default:
                Image(systemName: "mic")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                Text("SESLİ GİRİŞ")
                    .font(.brand(.caption))
                    .foregroundStyle(.white.opacity(0.5))
                    .tracking(1.0)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(.white.opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - Center content

    @ViewBuilder
    private var centerContent: some View {
        if isParsed {
            parsedCard
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
        } else if case .error(let msg) = phase {
            errorContent(msg)
                .transition(.opacity)
        } else if !recognizer.transcript.isEmpty {
            transcriptSection
                .transition(.opacity)
        } else {
            idlePrompt
                .transition(.opacity)
        }
    }

    private var idlePrompt: some View {
        VStack(spacing: Spacing.md) {
            Text("Basılı tut ve konuş")
                .font(.brand(.title))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text("Örnek: \"120 lira yemek\" ya da \"Kahve kırk beş\"")
                .font(.brand(.footnote))
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
    }

    private var transcriptSection: some View {
        VStack(spacing: Spacing.sm) {
            Text("SEN DEDİN Kİ")
                .font(.brand(.caption))
                .foregroundStyle(Color(hex: "#6E5BFF"))
                .tracking(1.2)

            Text("\"\(recognizer.transcript)\"")
                .font(.brand(.title))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var parsedCard: some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "#6E5BFF"))
                Text("AI ANLADI")
                    .font(.brand(.caption))
                    .foregroundStyle(Color(hex: "#6E5BFF"))
                    .tracking(1.0)
            }

            VStack(spacing: Spacing.sm) {
                parsedRow(label: "Tutar", value: "₺\(vm.rawInput)")
                parsedRow(
                    label: "Tip",
                    value: vm.transactionType == .expense ? "Gider" : "Gelir",
                    valueColor: vm.transactionType == .expense ? Color(hex: "#FF6B6B") : Color(hex: "#4CAF50")
                )
                if !vm.note.isEmpty {
                    parsedRow(label: "Açıklama", value: vm.note)
                }
                if let suggestion = vm.aiSuggestions.first,
                   let cat = categories.first(where: { $0.slug == suggestion.slug.rawValue }) {
                    parsedRow(
                        label: "Kategori",
                        value: "\(cat.name) · \(Int(suggestion.confidence * 100))%"
                    )
                }
            }
            .padding(Spacing.md)
            .background(.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 1)
            )

            Button {
                withAnimation(.spring(response: 0.3)) { mode = .manual }
            } label: {
                HStack(spacing: 4) {
                    Text("Manuel düzenle")
                        .font(.brand(.footnote))
                        .foregroundStyle(Color(hex: "#6E5BFF"))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: "#6E5BFF"))
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func parsedRow(label: String, value: String, valueColor: Color = .white) -> some View {
        HStack {
            Text(label)
                .font(.brand(.footnote))
                .foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.brand(.footnote))
                .foregroundStyle(valueColor)
        }
    }

    private func errorContent(_ msg: String) -> some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "mic.slash.fill")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.white.opacity(0.3))
            Text(msg)
                .font(.brand(.body))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Waveform

    private var waveformBars: some View {
        HStack(spacing: 3) {
            ForEach(0..<24, id: \.self) { i in
                let center = 11.5
                let distance = abs(Double(i) - center)
                let falloff = max(0, 1.0 - distance / 12.0)
                let level = Double(recognizer.audioLevel) * falloff
                let minH: CGFloat = 3
                let maxAdd: CGFloat = 36
                Capsule()
                    .fill(Color(hex: "#6E5BFF").opacity(0.4 + level * 0.6))
                    .frame(width: 3, height: minH + CGFloat(level) * maxAdd)
                    .animation(.easeOut(duration: 0.08), value: recognizer.audioLevel)
            }
        }
        .frame(height: 52)
    }

    // MARK: - Mic section

    private var micSection: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                // Outer pulse ring when listening
                if isListening {
                    Circle()
                        .stroke(Color(hex: "#6E5BFF").opacity(0.2 + Double(recognizer.audioLevel) * 0.3), lineWidth: 2)
                        .frame(width: 100 + CGFloat(recognizer.audioLevel) * 24, height: 100 + CGFloat(recognizer.audioLevel) * 24)
                        .animation(.easeOut(duration: 0.08), value: recognizer.audioLevel)
                }

                Circle()
                    .fill(
                        isListening
                        ? LinearGradient(colors: [Color(hex: "#FF4D4D"), Color(hex: "#FF6B35")],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color(hex: "#6E5BFF"), Color(hex: "#9B8BFF")],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: isListening ? Color(hex: "#FF4D4D").opacity(0.5) : Color(hex: "#6E5BFF").opacity(0.5), radius: 20, y: 6)

                Image(systemName: isListening ? "mic.fill" : "mic")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)
            }
            .scaleEffect(isListening ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isListening)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !hasStartedListening {
                            hasStartedListening = true
                            startListening()
                        }
                    }
                    .onEnded { _ in
                        hasStartedListening = false
                        if isListening { stopAndParse() }
                        else if case .requesting = phase { phase = .idle }
                    }
            )

            Text(isListening ? "Konuşmayı bitirmek için bırak" : (isParsed ? "Yeniden kayıt için basılı tut" : "Konuşmak için basılı tut"))
                .font(.brand(.caption))
                .foregroundStyle(.white.opacity(0.35))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Helpers

    private var isListening: Bool {
        if case .listening = phase { return true }
        return false
    }

    private var isParsed: Bool {
        if case .parsed = phase { return true }
        return false
    }

    // MARK: - Recognition

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
            // Auto-select the top AI suggestion — less taps for user
            if let top = vm.aiSuggestions.first,
               let cat = categories.first(where: { $0.slug == top.slug.rawValue }) {
                vm.selectedCategoryId = cat.id
            }
            // Skip the intermediate "AI ANLADI" screen; go straight to manual entry
            withAnimation(.spring(response: 0.3)) { mode = .manual }
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

        if let (amount, remainder) = extractDigitAmount(from: lower) {
            return (amount, cleanNote(remainder))
        }

        if let (amount, remainder) = extractTurkishAmount(from: lower) {
            return (amount, cleanNote(remainder))
        }

        return nil
    }

    private static func extractDigitAmount(from text: String) -> (String, String)? {
        // Normalize Turkish thousands separators: "11.250" → "11250", "1.234.567" → "1234567"
        // Dot followed by exactly 3 digits is a thousands separator in Turkish locale.
        var normalized = text
        if let thousandsRe = try? NSRegularExpression(pattern: #"(\d+)\.(\d{3})(?!\d)"#) {
            var prev = ""
            while prev != normalized {
                prev = normalized
                normalized = thousandsRe.stringByReplacingMatches(
                    in: normalized,
                    range: NSRange(normalized.startIndex..., in: normalized),
                    withTemplate: "$1$2"
                )
            }
        }

        // Now match digits, optionally followed by comma+1-2 decimal digits
        let pattern = #"(\d+)(?:,(\d{1,2}))?\s*(?:lira|tl|₺|try)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let nsNorm = normalized as NSString
        guard let match = regex.firstMatch(in: normalized, range: NSRange(location: 0, length: nsNorm.length)) else { return nil }

        let whole = nsNorm.substring(with: match.range(at: 1))
        var amount = whole
        if match.range(at: 2).location != NSNotFound {
            let frac = nsNorm.substring(with: match.range(at: 2))
            amount += ",\(frac)"
        }

        let fullMatchRange = match.range(at: 0)
        let after = (fullMatchRange.location + fullMatchRange.length < nsNorm.length)
            ? nsNorm.substring(from: fullMatchRange.location + fullMatchRange.length)
            : ""
        let before = fullMatchRange.location > 0
            ? nsNorm.substring(to: fullMatchRange.location)
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

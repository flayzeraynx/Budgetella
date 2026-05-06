//
//  CameraEntryContent.swift
//  Budgetella
//
//  Fiş OCR — PhotosPicker ile fotoğraf seçimi + Gemini Vision API ile tutar/açıklama parse.
//  Kamera erişimi: iOS native UIImagePickerController (camera) + PhotosPicker (library).
//

import SwiftUI
import PhotosUI

struct CameraEntryContent: View {

    @Bindable var vm: QuickEntryViewModel
    @Binding var mode: EntryMode

    @AppStorage("aiDataConsentGiven") private var aiConsentGiven = false
    @State private var phase: Phase = .idle
    @State private var pickerItem: PhotosPickerItem?
    @State private var showPicker = false
    @State private var showCamera = false
    @State private var selectedImage: UIImage?
    @State private var showConsentAlert = false
    @State private var pendingAction: (() -> Void)?

    enum Phase {
        case idle
        case processing
        case parsed(receiptResult: ReceiptResult)
        case error(String)
    }

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Hide receipt display and status while camera sheet is presenting (no idle flash)
            if !showCamera || selectedImage != nil {
                receiptDisplay
                statusText
            }

            // Action buttons
            switch phase {
            case .idle, .error:
                // Only show source buttons when camera is not already open
                if !showCamera {
                    photoSourceButtons
                }
            case .processing:
                ProgressView()
                    .tint(BrandColor.primary)
                    .scaleEffect(1.4)
            case .parsed(let result):
                parsedActionRow(result: result)
            }

            // Back
            Button {
                withAnimation(.spring(response: 0.3)) { mode = .manual }
            } label: {
                Text("Manuel Girişe Dön")
                    .font(.brand(.footnote))
                    .foregroundStyle(BrandColor.textTertiary)
            }
            .buttonStyle(.plain)
            .padding(.bottom, Spacing.xl)

            Spacer()
        }
        .padding(.horizontal, 24)
        .photosPicker(isPresented: $showPicker,
                      selection: $pickerItem,
                      matching: .images,
                      photoLibrary: .shared())
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task { await loadAndProcess(item: item) }
        }
        .sheet(isPresented: $showCamera) {
            CameraPickerView(
                onImage: { image in
                    selectedImage = image
                    showCamera = false
                    Task { await processImage(image) }
                },
                onCancel: {
                    showCamera = false
                }
            )
            .ignoresSafeArea()
        }
        .onAppear {
            if case .idle = phase {
                if aiConsentGiven {
                    showCamera = true
                } else {
                    pendingAction = { showCamera = true }
                    showConsentAlert = true
                }
            }
        }
        .alert("AI Veri Bildirimi", isPresented: $showConsentAlert) {
            Button("Kabul Et") {
                aiConsentGiven = true
                pendingAction?()
                pendingAction = nil
            }
            Button("İptal", role: .cancel) {
                pendingAction = nil
            }
        } message: {
            Text("Fiş tarama özelliği, fotoğrafınızı Google Gemini API'ye gönderir. Kişisel kimlik bilgileri dahil edilmez.")
        }
    }

    // MARK: - Receipt display

    private var receiptDisplay: some View {
        ZStack {
            if let img = selectedImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 180, height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                            .strokeBorder(BrandColor.primary.opacity(0.4), lineWidth: 2)
                    )
                    .shadow(color: BrandColor.primary.opacity(0.2), radius: 16, y: 6)

                if case .processing = phase {
                    RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                        .fill(.black.opacity(0.5))
                        .frame(width: 180, height: 240)
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                        .fill(BrandColor.primary.opacity(0.1))
                        .frame(width: 140, height: 180)
                        .overlay(
                            RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                                .strokeBorder(BrandColor.primary.opacity(0.3), lineWidth: 1.5)
                                .padding(4)
                        )

                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 52, weight: .light))
                        .foregroundStyle(BrandColor.primary)
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
        .animation(.spring(response: 0.4), value: selectedImage != nil)
    }

    // MARK: - Status text

    private var statusText: some View {
        Group {
            switch phase {
            case .idle:
                VStack(spacing: Spacing.xs) {
                    Text("Fiş Tarama")
                        .font(.brand(.title))
                        .foregroundStyle(BrandColor.textPrimary)
                    Text("Fişini çek veya galeriden seç")
                        .font(.brand(.footnote))
                        .foregroundStyle(BrandColor.textTertiary)
                }
            case .processing:
                Text("Gemini AI okuyor…")
                    .font(.brand(.body))
                    .foregroundStyle(BrandColor.primary)
            case .parsed(let result):
                VStack(spacing: 4) {
                    Text("₺\(result.amount)")
                        .font(.brand(.displayHero))
                        .foregroundStyle(BrandColor.textPrimary)
                    if !result.merchantName.isEmpty {
                        Text(result.merchantName)
                            .font(.brand(.body))
                            .foregroundStyle(BrandColor.textTertiary)
                    }
                }
            case .error(let msg):
                Text(msg)
                    .font(.brand(.footnote))
                    .foregroundStyle(BrandColor.expense)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Photo source buttons

    private var photoSourceButtons: some View {
        HStack(spacing: Spacing.md) {
            Button {
                if aiConsentGiven {
                    showCamera = true
                } else {
                    pendingAction = { showCamera = true }
                    showConsentAlert = true
                }
            } label: {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 22))
                    Text("Kamera")
                        .font(.brand(.footnote))
                }
                .foregroundStyle(BrandColor.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(BrandColor.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                        .strokeBorder(BrandColor.primary.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Button {
                if aiConsentGiven {
                    showPicker = true
                } else {
                    pendingAction = { showPicker = true }
                    showConsentAlert = true
                }
            } label: {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 22))
                    Text("Galeri")
                        .font(.brand(.footnote))
                }
                .foregroundStyle(BrandColor.info)
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(BrandColor.info.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                        .strokeBorder(BrandColor.info.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Parsed action row

    private func parsedActionRow(result: ReceiptResult) -> some View {
        HStack(spacing: Spacing.md) {
            Button {
                phase = .idle
                selectedImage = nil
                pickerItem = nil
            } label: {
                Text("Yeniden Tara")
                    .font(.brand(.subheadline))
                    .foregroundStyle(BrandColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(BrandColor.surface.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                vm.rawInput = result.amount
                vm.note = result.merchantName.isEmpty ? result.description : result.merchantName
                vm.updateSuggestions()
                withAnimation(.spring(response: 0.3)) { mode = .manual }
            } label: {
                Text("Formu Doldur")
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

    // MARK: - Processing

    private func loadAndProcess(item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        selectedImage = image
        await processImage(image)
    }

    private func processImage(_ image: UIImage) async {
        phase = .processing
        guard let jpegData = image.jpegData(compressionQuality: 0.7) else {
            phase = .error("Görsel işlenemedi.")
            return
        }
        let base64 = jpegData.base64EncodedString()
        do {
            let result = try await GeminiReceiptParser.parse(imageBase64: base64)
            withAnimation(.spring(response: 0.4)) {
                phase = .parsed(receiptResult: result)
            }
        } catch {
            phase = .error("OCR başarısız: \(error.localizedDescription)")
        }
    }
}

// MARK: - Receipt result

struct ReceiptResult {
    let amount: String
    let merchantName: String
    let description: String
}

// MARK: - Gemini Vision parser

enum GeminiReceiptParser {

    static func parse(imageBase64: String) async throws -> ReceiptResult {
        let apiKey = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String ?? ""
        guard !apiKey.isEmpty else { throw OCRError.missingAPIKey }

        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else { throw OCRError.invalidURL }

        let prompt = """
        Sen bir fiş/makbuz OCR asistanısın. Bu fişten şu bilgileri JSON formatında çıkar:
        - "amount": toplam tutar (sadece sayılar ve nokta, örn. "124.90")
        - "merchant": mağaza/işyeri adı (string)
        - "description": ne satın alındı (kısa, Türkçe, örn. "Market alışverişi")

        Eğer toplam tutar bulamazsan "amount": "" döndür.
        Sadece JSON döndür, başka hiçbir şey yok.
        Örnek: {"amount":"124.90","merchant":"Migros","description":"Market alışverişi"}
        """

        let requestBody: [String: Any] = [
            "contents": [[
                "parts": [
                    ["text": prompt],
                    ["inline_data": ["mime_type": "image/jpeg", "data": imageBase64]]
                ]
            ]]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw OCRError.serverError
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String
        else { throw OCRError.parseError }

        // Extract JSON from response (it might have markdown code fences)
        let jsonText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let resultData = jsonText.data(using: .utf8),
              let resultJSON = try? JSONSerialization.jsonObject(with: resultData) as? [String: Any]
        else { throw OCRError.parseError }

        let rawAmount = resultJSON["amount"] as? String ?? ""
        let merchant  = resultJSON["merchant"] as? String ?? ""
        let desc      = resultJSON["description"] as? String ?? ""

        // Normalize amount (replace commas with dots)
        let normalizedAmount = rawAmount
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: "₺", with: "")
            .replacingOccurrences(of: "TL", with: "")
            .trimmingCharacters(in: .whitespaces)

        guard !normalizedAmount.isEmpty, Double(normalizedAmount) != nil else {
            throw OCRError.noAmountFound
        }

        // Convert to Turkish comma format for vm.rawInput
        let turkishAmount = normalizedAmount.replacingOccurrences(of: ".", with: ",")
        return ReceiptResult(amount: turkishAmount, merchantName: merchant, description: desc)
    }
}

enum OCRError: LocalizedError {
    case missingAPIKey, invalidURL, serverError, parseError, noAmountFound

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:   return "Gemini API anahtarı bulunamadı."
        case .invalidURL:      return "Geçersiz API URL."
        case .serverError:     return "Sunucu hatası. Lütfen tekrar deneyin."
        case .parseError:      return "Yanıt ayrıştırılamadı."
        case .noAmountFound:   return "Fişten tutar okunamadı. Manuel giriş dene."
        }
    }
}

// MARK: - Camera UIKit wrapper

struct CameraPickerView: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onImage: onImage, onCancel: onCancel) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImage: (UIImage) -> Void
        let onCancel: () -> Void
        init(onImage: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onImage = onImage
            self.onCancel = onCancel
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage { onImage(img) }
            // SwiftUI binding handles sheet dismissal — don't call picker.dismiss() here
            // (picker.dismiss would propagate up and close the entire QuickEntry sheet)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}

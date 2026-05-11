package com.budgetella.app.data.remote

import com.budgetella.app.BuildConfig
import io.ktor.client.HttpClient
import io.ktor.client.engine.okhttp.OkHttp
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.contentType
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Thin Ktor wrapper around Google's generativelanguage.googleapis.com
 * gemini-2.0-flash endpoint — same wire format the iOS BudgiChatService uses.
 *
 * The API key comes from BuildConfig.GEMINI_API_KEY (populated from
 * gradle.properties / env at build time — see app/build.gradle.kts).
 */
@Singleton
class GeminiChatService @Inject constructor() {

    private val client = HttpClient(OkHttp) {
        install(ContentNegotiation) {
            json(Json { ignoreUnknownKeys = true; isLenient = true })
        }
    }

    /**
     * Sends a single user turn plus context. Returns the assistant's reply
     * text, or a localised fallback if anything goes wrong.
     */
    suspend fun send(
        message: String,
        contextBlock: String,
        languageCode: String,
    ): String {
        val key = BuildConfig.GEMINI_API_KEY
        if (key.isBlank()) {
            return if (languageCode.startsWith("en")) "API key isn't configured."
            else "API anahtarı yapılandırılmamış."
        }

        val isEn = languageCode.startsWith("en")
        val systemPrompt = if (isEn) """
            You are Budgi, the user's personal finance assistant. Respond in English.
            Keep answers short, friendly, and practical. No unnecessary long explanations.
            Help only with financial topics.

            $contextBlock
        """.trimIndent() else """
            Sen Budgi'sin — kullanıcının kişisel finans asistanısın. Türkçe konuşuyorsun.
            Kısa, samimi, ve pratik cevaplar ver. Gereksiz uzun açıklamalar yapma.
            Sadece finansal konularda yardımcı ol.

            $contextBlock
        """.trimIndent()

        val payload = GeminiRequest(
            contents = listOf(
                GeminiContent(
                    role = "user",
                    parts = listOf(GeminiPart(text = systemPrompt + "\n\nUser: " + message)),
                )
            ),
            generationConfig = GenerationConfig(maxOutputTokens = 300, temperature = 0.7),
        )

        return runCatching {
            val response = client.post(
                "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$key"
            ) {
                contentType(ContentType.Application.Json)
                setBody(payload)
            }
            val raw = response.bodyAsText()
            val parsed = Json { ignoreUnknownKeys = true }.decodeFromString<GeminiResponse>(raw)
            parsed.candidates.orEmpty()
                .firstOrNull()?.content?.parts.orEmpty()
                .firstOrNull()?.text?.trim()
                ?: if (isEn) "Couldn't parse the answer." else "Yanıt ayrıştırılamadı."
        }.getOrElse {
            if (isEn) "I can't reply right now. Please try again later."
            else "Şu an cevap veremiyorum. Lütfen daha sonra tekrar dene."
        }
    }

    // ── Wire types ─────────────────────────────────────────────────────────

    @Serializable
    private data class GeminiRequest(
        val contents: List<GeminiContent>,
        val generationConfig: GenerationConfig,
    )

    @Serializable
    private data class GeminiContent(
        val role: String,
        val parts: List<GeminiPart>,
    )

    @Serializable
    private data class GeminiPart(val text: String)

    @Serializable
    private data class GenerationConfig(
        val maxOutputTokens: Int,
        val temperature: Double,
    )

    @Serializable
    private data class GeminiResponse(val candidates: List<Candidate>? = null) {
        @Serializable data class Candidate(val content: Content? = null)
        @Serializable data class Content(val parts: List<Part>? = null)
        @Serializable data class Part(val text: String? = null)
    }
}

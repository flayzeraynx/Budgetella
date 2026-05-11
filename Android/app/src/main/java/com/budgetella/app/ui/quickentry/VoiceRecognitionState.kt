package com.budgetella.app.ui.quickentry

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

/**
 * Thin wrapper around Android's [SpeechRecognizer] that exposes
 * Compose-state-backed fields — an exact port of the iOS
 * `SpeechEntryRecognizer @Observable` class.
 *
 * Must be created and used on the main thread (SpeechRecognizer requirement).
 * Wrap with `remember { VoiceRecognitionState(context) }` inside a Composable
 * and clean up with a `DisposableEffect { onDispose { cancel() } }`.
 */
@Stable
class VoiceRecognitionState(private val context: Context) {

    /** Running partial or final transcript. */
    var transcript: String by mutableStateOf("")
        private set

    /**
     * Normalised RMS audio level, 0 (silent) … 1 (loud).
     * Updated ~10 Hz by [RecognitionListener.onRmsChanged].
     */
    var audioLevel: Float by mutableFloatStateOf(0f)
        private set

    /** True once [SpeechRecognizer] fires onResults (or a finalising error). */
    var isFinal: Boolean by mutableStateOf(false)
        private set

    /** Non-null on a hard error (permission denied, network, …). */
    var error: String? by mutableStateOf(null)
        private set

    private var recognizer: SpeechRecognizer? = null

    // ── Public API ────────────────────────────────────────────────────────────

    fun start() {
        isFinal    = false
        error      = null
        transcript = ""
        audioLevel = 0f

        recognizer?.destroy()
        recognizer = SpeechRecognizer.createSpeechRecognizer(context).apply {
            setRecognitionListener(listener)
            startListening(buildIntent())
        }
    }

    /**
     * Graceful stop — signals end of speech audio and waits for the recogniser
     * to emit a final result via [RecognitionListener.onResults].
     * Mirrors iOS `SpeechEntryRecognizer.stopRecording()`.
     */
    fun stopListening() {
        audioLevel = 0f
        recognizer?.stopListening()
    }

    /**
     * Hard cancel — destroys the recogniser immediately without waiting for a
     * final result. Mirrors iOS `SpeechEntryRecognizer.cancel()`.
     */
    fun cancel() {
        audioLevel = 0f
        recognizer?.destroy()
        recognizer = null
    }

    // ── Internal ──────────────────────────────────────────────────────────────

    private fun buildIntent() = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
        putExtra(RecognizerIntent.EXTRA_LANGUAGE,                           "tr-TR")
        putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE,                "tr-TR")
        putExtra(RecognizerIntent.EXTRA_ONLY_RETURN_LANGUAGE_PREFERENCE,    true)
        putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS,                    true)
        putExtra(RecognizerIntent.EXTRA_MAX_RESULTS,                        1)
        // Give the user 2 s of silence before auto-finalising.
        putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS,          2_000L)
        putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 1_500L)
    }

    private val listener = object : RecognitionListener {
        override fun onReadyForSpeech(params: Bundle?) {}
        override fun onBeginningOfSpeech()              {}
        override fun onBufferReceived(buffer: ByteArray?) {}
        override fun onEvent(eventType: Int, params: Bundle?) {}

        override fun onRmsChanged(rmsdB: Float) {
            // onRmsChanged: roughly -2 dB (silence) … +10 dB (loud) → normalise 0..1
            audioLevel = ((rmsdB + 2f) / 12f).coerceIn(0f, 1f)
        }

        override fun onEndOfSpeech() {
            audioLevel = 0f
        }

        override fun onPartialResults(partialResults: Bundle?) {
            val first = partialResults
                ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                ?.firstOrNull() ?: return
            if (first.isNotEmpty()) transcript = first
        }

        override fun onResults(results: Bundle?) {
            audioLevel = 0f
            val best = results
                ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                ?.firstOrNull() ?: transcript
            transcript = best
            isFinal    = true
        }

        override fun onError(errorCode: Int) {
            audioLevel = 0f
            // Map to human-readable Turkish messages. null = soft error (silence /
            // no-match) — finalise with whatever partial text we already have.
            val msg = when (errorCode) {
                SpeechRecognizer.ERROR_AUDIO                  -> "Ses kaydı hatası."
                SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS ->
                    "Mikrofon izni verilmedi.\nAyarlar > Budgetella > Mikrofon"
                SpeechRecognizer.ERROR_RECOGNIZER_BUSY        -> "Tanıyıcı meşgul. Tekrar dene."
                SpeechRecognizer.ERROR_SERVER                 -> "Sunucu hatası. Tekrar dene."
                SpeechRecognizer.ERROR_NETWORK,
                SpeechRecognizer.ERROR_NETWORK_TIMEOUT        -> "İnternet bağlantısı gerekli."
                // ERROR_NO_MATCH / ERROR_SPEECH_TIMEOUT → treat as silent finalisers
                else                                          -> null
            }
            if (!isFinal) {
                if (msg != null) error = msg
                isFinal = true     // triggers the parse LaunchedEffect in VoiceEntrySheet
            }
        }
    }
}

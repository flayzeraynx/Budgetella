package com.budgetella.app.ui.quickentry

/**
 * Extracts a (rawAmount, note) pair from raw OCR text captured from a receipt.
 *
 * Strategy:
 *  1. Scan lines from the bottom — totals almost always appear near the end
 *     of a receipt (after item list, tax, service charge).
 *  2. Match lines containing Turkish/English total keywords.
 *  3. Feed each match to [VoiceParser] which already handles digit + Turkish
 *     word extraction, thousands separators, etc.
 *  4. If no labelled total is found, pick the line with the largest numeric
 *     value (heuristic — usually the grand total on a receipt).
 *
 * The note is set to "Fiş" (receipt) by default, so the user gets a
 * sensible pre-fill even when the OCR text has no merchant name.
 */
object ReceiptParser {

    private val TOTAL_KEYWORDS = listOf(
        "toplam", "tutar", "total", "genel toplam", "ödenecek", "ara toplam",
        "kdv dahil", "ödenecek tutar", "net tutar", "genel tutar"
    )

    /**
     * Parse [ocrText] (full recognised text from ML Kit) and return a
     * [VoiceParser.ParseResult] or null if no amount could be extracted.
     */
    fun parse(ocrText: String): VoiceParser.ParseResult? {
        if (ocrText.isBlank()) return null

        val lines = ocrText.lines().map { it.trim() }.filter { it.isNotEmpty() }

        // Strategy 1: find a labelled total line (search reversed — bottom first)
        for (line in lines.reversed()) {
            val lower = line.lowercase()
            if (TOTAL_KEYWORDS.any { lower.contains(it) }) {
                val result = VoiceParser.parse(line)
                if (result != null) return result.withDefaultNote("Fiş")
            }
        }

        // Strategy 2: largest parseable amount in the whole text
        var bestAmount = 0.0
        var bestResult: VoiceParser.ParseResult? = null
        for (line in lines) {
            val result = VoiceParser.parse(line) ?: continue
            val value  = result.rawAmount.replace(",", ".").toDoubleOrNull() ?: continue
            if (value > bestAmount) {
                bestAmount = value
                bestResult = result
            }
        }
        return bestResult?.withDefaultNote("Fiş")
    }

    private fun VoiceParser.ParseResult.withDefaultNote(default: String) =
        if (note.isEmpty()) copy(note = default) else this
}

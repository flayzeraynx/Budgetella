package com.budgetella.app.ui.quickentry

/**
 * Port of iOS VoiceParser.
 *
 * Extracts (rawAmount, note) from a voice transcript or OCR string.
 *
 * Digit path:
 *   "120 lira yemek"  → ParseResult("120",   "yemek")
 *   "1.250 tl kira"   → ParseResult("1250",  "kira")    ← thousands separator stripped
 *   "45,50 kahve"     → ParseResult("45,50", "kahve")   ← decimal kept
 *
 * Turkish-word path:
 *   "kırk beş kahve"  → ParseResult("45",    "kahve")
 *   "yüz yirmi lira"  → ParseResult("120",   "")
 */
object VoiceParser {

    data class ParseResult(val rawAmount: String, val note: String)

    fun parse(text: String): ParseResult? {
        val lower = text.lowercase()
        return extractDigitAmount(lower) ?: extractTurkishAmount(lower)
    }

    // ── Digit path ────────────────────────────────────────────────────────────

    private fun extractDigitAmount(text: String): ParseResult? {
        // Strip thousands separators: 1.000 → 1000 (repeat until stable)
        var normalized = text
        val thousandsRe = Regex("""(\d+)\.(\d{3})(?!\d)""")
        var prev = ""
        while (prev != normalized) {
            prev = normalized
            normalized = thousandsRe.replace(normalized) { "${it.groupValues[1]}${it.groupValues[2]}" }
        }

        // Match: digits, optional decimal (comma-separated), optional currency keyword
        val pattern = Regex("""(\d+)(?:,(\d{1,2}))?\s*(?:lira|tl|₺|try)?""")
        val match = pattern.find(normalized) ?: return null

        val whole   = match.groupValues[1]
        val decimal = match.groupValues[2]
        val amount  = if (decimal.isNotEmpty()) "$whole,$decimal" else whole

        val before = normalized.substring(0, match.range.first).trim()
        val after  = if (match.range.last + 1 < normalized.length)
            normalized.substring(match.range.last + 1).trim() else ""
        return ParseResult(amount, cleanNote("$before $after"))
    }

    // ── Turkish-word path ─────────────────────────────────────────────────────

    // Ordered longest-first so "on dokuz" matches before "on" or "dokuz".
    private val turkishNumbers: List<Pair<String, Int>> = listOf(
        "bin"       to 1000, "yüz"      to 100,  "elli"  to 50,
        "kırk"      to 40,   "otuz"     to 30,   "yirmi" to 20,
        "on dokuz"  to 19,   "on sekiz" to 18,   "on yedi" to 17,
        "on altı"   to 16,   "on beş"   to 15,   "on dört" to 14,
        "on üç"     to 13,   "on iki"   to 12,   "on bir"  to 11,
        "on"        to 10,   "dokuz"    to 9,    "sekiz"  to 8,
        "yedi"      to 7,    "altı"     to 6,    "beş"    to 5,
        "dört"      to 4,    "üç"       to 3,    "iki"    to 2,
        "bir"       to 1,
    )

    private fun extractTurkishAmount(text: String): ParseResult? {
        var remaining = text
        var total = 0
        for ((word, value) in turkishNumbers) {
            if (remaining.contains(word)) {
                remaining = remaining.replace(word, "")
                total += value
            }
        }
        if (total == 0) return null
        for (kw in listOf("lira", "tl", "₺")) remaining = remaining.replace(kw, "")
        return ParseResult("$total", cleanNote(remaining))
    }

    // ── Shared ────────────────────────────────────────────────────────────────

    fun cleanNote(raw: String): String =
        raw.trim()
           .split(Regex("\\s+"))
           .filter { it.isNotEmpty() }
           .joinToString(" ")
}

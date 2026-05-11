package com.budgetella.app.ui.quickentry

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.MicOff
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.design.BrandText
import com.budgetella.app.core.design.Spacing
import kotlinx.coroutines.delay

// ── Private colour constants (identical to iOS design tokens) ────────────────
private val DarkBg          = Color(0xFF0A0B14)
private val RedStop         = Color(0xFFFF4D4D)
private val RedStopAlt      = Color(0xFFFF6B35)
private val AccentPurple    = Color(0xFF6E5BFF)
private val AccentPurpleLt  = Color(0xFF9B8BFF)
private val GreenOk         = Color(0xFF4CAF50)

// ── Phase ─────────────────────────────────────────────────────────────────────

sealed interface VoicePhase {
    data object Idle    : VoicePhase
    data object Listening : VoicePhase
    data object Parsing : VoicePhase
    data class Parsed(val result: VoiceParser.ParseResult) : VoicePhase
    data class Error(val message: String) : VoicePhase
}

// ── Sheet ─────────────────────────────────────────────────────────────────────

/**
 * Full-screen voice entry sheet — mirrors iOS VoiceEntryContent exactly.
 *
 * On successful parse [onParsed] is called with (rawAmount, note) and the
 * sheet dismisses itself 450 ms later. The caller (MainScaffold) should
 * immediately open AddEditTransactionSheet with those values pre-filled.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VoiceEntrySheet(
    onDismiss: () -> Unit,
    onParsed: (amount: String, note: String) -> Unit,
) {
    val context     = LocalContext.current
    val sheetState  = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    var phase by remember { mutableStateOf<VoicePhase>(VoicePhase.Idle) }

    // ── Recogniser ────────────────────────────────────────────────────────────
    val recognizer = remember { VoiceRecognitionState(context) }
    DisposableEffect(Unit) { onDispose { recognizer.cancel() } }

    // ── Permission ────────────────────────────────────────────────────────────
    var permGranted by remember {
        mutableStateOf(
            ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) ==
                    PackageManager.PERMISSION_GRANTED
        )
    }
    val permLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        permGranted = granted
        if (granted) {
            recognizer.start()
            phase = VoicePhase.Listening
        } else {
            phase = VoicePhase.Error(
                "Mikrofon izni verilmedi.\nAyarlar > Budgetella > Mikrofon"
            )
        }
    }

    // ── Auto-start ────────────────────────────────────────────────────────────
    LaunchedEffect(Unit) {
        delay(120) // let the sheet animate in
        if (permGranted) {
            recognizer.start()
            phase = VoicePhase.Listening
        } else {
            permLauncher.launch(Manifest.permission.RECORD_AUDIO)
        }
    }

    // ── Watch isFinal → parse ─────────────────────────────────────────────────
    LaunchedEffect(recognizer.isFinal) {
        if (recognizer.isFinal && phase is VoicePhase.Parsing) {
            doParseAndNavigate(
                transcript = recognizer.transcript,
                errorMsg   = recognizer.error,
                setPhase   = { phase = it },
                onParsed   = onParsed,
            )
        }
    }

    // ── Parsing timeout (3 s — mirrors iOS) ───────────────────────────────────
    LaunchedEffect(phase) {
        if (phase is VoicePhase.Parsing) {
            delay(3_000)
            if (phase is VoicePhase.Parsing) {
                doParseAndNavigate(
                    transcript = recognizer.transcript,
                    errorMsg   = null,
                    setPhase   = { phase = it },
                    onParsed   = onParsed,
                )
            }
        }
    }

    // ── Auto-dismiss after parsed (450 ms — mirrors iOS) ─────────────────────
    LaunchedEffect(phase) {
        if (phase is VoicePhase.Parsed) {
            delay(450)
            onDismiss()
        }
    }

    // ── UI ────────────────────────────────────────────────────────────────────
    ModalBottomSheet(
        onDismissRequest = { recognizer.cancel(); onDismiss() },
        sheetState       = sheetState,
        containerColor   = DarkBg,
        dragHandle       = null,
    ) {
        val isListening = phase is VoicePhase.Listening

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(520.dp)
                .background(
                    Brush.radialGradient(
                        colors = listOf(
                            AccentPurple.copy(alpha = if (isListening) 0.22f else 0.07f),
                            Color.Transparent,
                        ),
                        radius = 900f,
                    )
                )
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .navigationBarsPadding()
                    .padding(horizontal = Spacing.xl, vertical = Spacing.lg),
            ) {

                // ── Header ────────────────────────────────────────────────────
                Box(modifier = Modifier.fillMaxWidth()) {
                    // Close button
                    Box(
                        modifier = Modifier
                            .align(Alignment.CenterStart)
                            .size(36.dp)
                            .clip(CircleShape)
                            .background(Color.White.copy(alpha = 0.12f))
                            .clickable { recognizer.cancel(); onDismiss() },
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(
                            imageVector     = Icons.Filled.Close,
                            contentDescription = "Kapat",
                            tint            = Color.White,
                            modifier        = Modifier.size(15.dp),
                        )
                    }
                    // Status pill
                    StatusPill(phase = phase, modifier = Modifier.align(Alignment.Center))
                }

                Spacer(Modifier.weight(1f))

                // ── Centre content ────────────────────────────────────────────
                Box(
                    modifier        = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = Spacing.md),
                    contentAlignment = Alignment.Center,
                ) {
                    AnimatedContent(
                        targetState    = phase,
                        transitionSpec = { fadeIn(tween(200)) togetherWith fadeOut(tween(150)) },
                        label          = "voice_center",
                    ) { p ->
                        when (p) {
                            VoicePhase.Idle -> Text(
                                text      = "Hazırlanıyor…",
                                style     = BrandText.title,
                                color     = Color.White.copy(alpha = 0.35f),
                                textAlign = TextAlign.Center,
                            )

                            VoicePhase.Listening -> {
                                if (recognizer.transcript.isEmpty()) {
                                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                        Text(
                                            text      = "Konuşun",
                                            style     = BrandText.largeTitle,
                                            color     = Color.White,
                                            textAlign = TextAlign.Center,
                                        )
                                        Spacer(Modifier.height(Spacing.md))
                                        Text(
                                            text      = "Örnek: \"120 lira yemek\" ya da \"Kahve kırk beş\"",
                                            style     = BrandText.footnote,
                                            color     = Color.White.copy(alpha = 0.4f),
                                            textAlign = TextAlign.Center,
                                        )
                                    }
                                } else {
                                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                        Text(
                                            text  = "SEN DEDİN Kİ",
                                            style = BrandText.caption.copy(letterSpacing = 1.2.sp),
                                            color = AccentPurple,
                                        )
                                        Spacer(Modifier.height(Spacing.sm))
                                        Text(
                                            text      = "\"${recognizer.transcript}\"",
                                            style     = BrandText.title,
                                            color     = Color.White,
                                            textAlign = TextAlign.Center,
                                            maxLines  = 4,
                                        )
                                    }
                                }
                            }

                            VoicePhase.Parsing -> Column(
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.spacedBy(Spacing.md),
                            ) {
                                CircularProgressIndicator(
                                    color       = Color.White,
                                    modifier    = Modifier.size(32.dp),
                                    strokeWidth = 2.dp,
                                )
                                Text(
                                    text  = "Anlaşılıyor…",
                                    style = BrandText.body,
                                    color = Color.White.copy(alpha = 0.5f),
                                )
                            }

                            is VoicePhase.Parsed -> VoiceParsedCard(result = p.result)

                            is VoicePhase.Error -> Column(
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.spacedBy(Spacing.sm),
                            ) {
                                Icon(
                                    imageVector        = Icons.Filled.MicOff,
                                    contentDescription = null,
                                    tint               = Color.White.copy(alpha = 0.3f),
                                    modifier           = Modifier.size(40.dp),
                                )
                                Text(
                                    text      = p.message,
                                    style     = BrandText.body,
                                    color     = Color.White.copy(alpha = 0.6f),
                                    textAlign = TextAlign.Center,
                                )
                            }
                        }
                    }
                }

                Spacer(Modifier.weight(1f))

                // ── Waveform ──────────────────────────────────────────────────
                AnimatedVisibility(
                    visible = isListening,
                    enter   = fadeIn(),
                    exit    = fadeOut(),
                ) {
                    WaveformBars(
                        audioLevel = recognizer.audioLevel,
                        modifier   = Modifier
                            .fillMaxWidth()
                            .height(52.dp)
                            .padding(bottom = Spacing.md),
                    )
                }

                // ── Action buttons ────────────────────────────────────────────
                Column(
                    modifier            = Modifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(Spacing.sm),
                ) {
                    when (phase) {
                        VoicePhase.Listening -> {
                            VoiceStopButton {
                                phase = VoicePhase.Parsing
                                recognizer.stopListening()
                            }
                            Text(
                                text  = "Durdurmak için dokun",
                                style = BrandText.caption,
                                color = Color.White.copy(alpha = 0.35f),
                            )
                        }

                        is VoicePhase.Error -> {
                            VoiceRetryButton {
                                recognizer.start()
                                phase = VoicePhase.Listening
                            }
                            Text(
                                text  = "veya manuel giriş kullan",
                                style = BrandText.caption,
                                color = Color.White.copy(alpha = 0.35f),
                            )
                        }

                        else -> Spacer(Modifier.height(80.dp))
                    }
                }

                Spacer(Modifier.height(Spacing.xl))
            }
        }
    }
}

// ── Logic helper ─────────────────────────────────────────────────────────────

private fun doParseAndNavigate(
    transcript: String,
    errorMsg: String?,
    setPhase: (VoicePhase) -> Unit,
    onParsed: (amount: String, note: String) -> Unit,
) {
    val trimmed = transcript.trim()
    if (trimmed.isEmpty()) {
        setPhase(VoicePhase.Error(errorMsg ?: "Konuşma algılanamadı.\nTekrar dene."))
        return
    }
    val result = VoiceParser.parse(trimmed)
    if (result != null) {
        setPhase(VoicePhase.Parsed(result))
        onParsed(result.rawAmount, result.note)
    } else {
        setPhase(VoicePhase.Error("Tutar anlaşılamadı.\nTekrar dene veya manuel giriş kullan."))
    }
}

// ── Components ────────────────────────────────────────────────────────────────

@Composable
private fun StatusPill(phase: VoicePhase, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier
            .clip(RoundedCornerShape(Spacing.radiusFull))
            .background(Color.White.copy(alpha = 0.10f))
            .padding(horizontal = 14.dp, vertical = 7.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment     = Alignment.CenterVertically,
    ) {
        when (phase) {
            VoicePhase.Idle -> {
                Icon(Icons.Filled.Mic, null, tint = Color.White.copy(alpha = 0.5f), modifier = Modifier.size(11.dp))
                Text("SESLİ GİRİŞ", style = BrandText.caption.copy(letterSpacing = 1.sp), color = Color.White.copy(alpha = 0.5f))
            }
            VoicePhase.Listening -> {
                Box(Modifier.size(7.dp).clip(CircleShape).background(RedStop))
                Text("DİNLİYOR", style = BrandText.caption.copy(letterSpacing = 1.sp), color = Color.White)
            }
            VoicePhase.Parsing -> {
                CircularProgressIndicator(color = Color.White, modifier = Modifier.size(14.dp), strokeWidth = 2.dp)
                Text("İŞLENİYOR", style = BrandText.caption.copy(letterSpacing = 1.sp), color = Color.White)
            }
            is VoicePhase.Parsed -> {
                Icon(Icons.Filled.CheckCircle, null, tint = GreenOk, modifier = Modifier.size(11.dp))
                Text("ANLAŞILDI", style = BrandText.caption.copy(letterSpacing = 1.sp), color = Color.White)
            }
            is VoicePhase.Error -> {
                Icon(Icons.Filled.Warning, null, tint = BrandColor.Warning, modifier = Modifier.size(11.dp))
                Text("HATA", style = BrandText.caption.copy(letterSpacing = 1.sp), color = Color.White)
            }
        }
    }
}

@Composable
private fun WaveformBars(audioLevel: Float, modifier: Modifier = Modifier) {
    val barCount = 24
    val center   = (barCount - 1) / 2f
    Row(
        modifier              = modifier,
        horizontalArrangement = Arrangement.spacedBy(3.dp, Alignment.CenterHorizontally),
        verticalAlignment     = Alignment.CenterVertically,
    ) {
        repeat(barCount) { i ->
            val distance = kotlin.math.abs(i - center)
            val falloff  = maxOf(0f, 1f - distance / center)
            val level    = audioLevel * falloff
            val heightPx by animateFloatAsState(
                targetValue    = 3f + level * 36f,
                animationSpec  = tween(80),
                label          = "waveBar_$i",
            )
            Box(
                modifier = Modifier
                    .width(3.dp)
                    .height(heightPx.dp)
                    .clip(RoundedCornerShape(Spacing.radiusFull))
                    .background(AccentPurple.copy(alpha = 0.4f + level * 0.6f)),
            )
        }
    }
}

@Composable
fun VoiceParsedCard(result: VoiceParser.ParseResult) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(Spacing.md),
    ) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(Spacing.xs),
            verticalAlignment     = Alignment.CenterVertically,
        ) {
            Icon(Icons.Filled.Star, null, tint = AccentPurple, modifier = Modifier.size(13.dp))
            Text(
                text  = "AI ANLADI",
                style = BrandText.caption.copy(letterSpacing = 1.sp),
                color = AccentPurple,
            )
        }
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(Spacing.radiusMedium))
                .background(Color.White.copy(alpha = 0.06f))
                .border(1.dp, Color.White.copy(alpha = 0.10f), RoundedCornerShape(Spacing.radiusMedium))
                .padding(Spacing.md),
            verticalArrangement = Arrangement.spacedBy(Spacing.sm),
        ) {
            ParsedRow("Tutar", "₺${result.rawAmount}")
            if (result.note.isNotEmpty()) ParsedRow("Açıklama", result.note)
        }
    }
}

@Composable
private fun ParsedRow(label: String, value: String, valueColor: Color = Color.White) {
    Row(modifier = Modifier.fillMaxWidth()) {
        Text(label, style = BrandText.footnote, color = Color.White.copy(alpha = 0.5f), modifier = Modifier.weight(1f))
        Text(value, style = BrandText.footnote, color = valueColor)
    }
}

@Composable
private fun VoiceStopButton(onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .size(80.dp)
            .clip(CircleShape)
            .background(Brush.linearGradient(colors = listOf(RedStop, RedStopAlt)))
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            modifier = Modifier
                .size(28.dp)
                .clip(RoundedCornerShape(5.dp))
                .background(Color.White),
        )
    }
}

@Composable
private fun VoiceRetryButton(onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .size(72.dp)
            .clip(CircleShape)
            .background(Brush.linearGradient(colors = listOf(AccentPurple, AccentPurpleLt)))
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            imageVector        = Icons.Filled.Mic,
            contentDescription = "Tekrar Dene",
            tint               = Color.White,
            modifier           = Modifier.size(26.dp),
        )
    }
}

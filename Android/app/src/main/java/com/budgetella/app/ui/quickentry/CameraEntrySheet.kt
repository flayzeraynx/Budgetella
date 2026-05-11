package com.budgetella.app.ui.quickentry

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.ImageProxy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.animation.AnimatedContent
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.NoPhotography
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
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import com.budgetella.app.core.design.BrandColor
import com.budgetella.app.core.design.BrandText
import com.budgetella.app.core.design.Spacing
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import kotlinx.coroutines.delay
import java.util.concurrent.Executors

// ── Shared colours ────────────────────────────────────────────────────────────
private val DarkBgC      = Color(0xFF0A0B14)
private val AccentC      = Color(0xFF6E5BFF)
private val AccentLtC    = Color(0xFF9B8BFF)
private val GreenOkC     = Color(0xFF4CAF50)

// ── Phase ─────────────────────────────────────────────────────────────────────

sealed interface CameraPhase {
    data object Preview   : CameraPhase
    data object Scanning  : CameraPhase   // ML Kit running
    data class  Scanned(val result: VoiceParser.ParseResult) : CameraPhase
    data class  Error(val message: String) : CameraPhase
    data object NoPerm    : CameraPhase
}

// ── Sheet ─────────────────────────────────────────────────────────────────────

/**
 * Receipt camera entry sheet — shows a CameraX viewfinder, lets the user
 * capture a photo, runs ML Kit Text Recognition, and pre-fills the
 * add-transaction form with the parsed amount + "Fiş" note.
 *
 * Mirrors the UX of [VoiceEntrySheet]: same dark background, same parsed card,
 * same auto-dismiss after 450 ms.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CameraEntrySheet(
    onDismiss: () -> Unit,
    onParsed: (amount: String, note: String) -> Unit,
) {
    val context        = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val sheetState     = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    var phase by remember { mutableStateOf<CameraPhase>(CameraPhase.Preview) }

    // ── Permission ────────────────────────────────────────────────────────────
    var permGranted by remember {
        mutableStateOf(
            ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) ==
                    PackageManager.PERMISSION_GRANTED
        )
    }
    val permLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        permGranted = granted
        if (!granted) phase = CameraPhase.NoPerm
    }
    LaunchedEffect(Unit) {
        if (!permGranted) permLauncher.launch(Manifest.permission.CAMERA)
    }

    // ── CameraX setup ─────────────────────────────────────────────────────────
    val imageCapture = remember {
        ImageCapture.Builder()
            .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
            .build()
    }
    val executor = remember { Executors.newSingleThreadExecutor() }
    DisposableEffect(Unit) { onDispose { executor.shutdown() } }

    val cameraProviderFuture = remember { ProcessCameraProvider.getInstance(context) }

    // ── ML Kit recogniser ─────────────────────────────────────────────────────
    val textRecognizer = remember {
        TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
    }
    DisposableEffect(Unit) { onDispose { textRecognizer.close() } }

    // ── Auto-dismiss after scanned ────────────────────────────────────────────
    LaunchedEffect(phase) {
        if (phase is CameraPhase.Scanned) {
            delay(450)
            onDismiss()
        }
    }

    // ── Capture logic ─────────────────────────────────────────────────────────
    fun captureAndScan() {
        if (phase is CameraPhase.Scanning) return
        phase = CameraPhase.Scanning
        imageCapture.takePicture(
            executor,
            object : ImageCapture.OnImageCapturedCallback() {
                override fun onCaptureSuccess(imageProxy: ImageProxy) {
                    val mediaImage = imageProxy.image
                    if (mediaImage == null) {
                        phase = CameraPhase.Error("Görüntü alınamadı. Tekrar dene.")
                        imageProxy.close()
                        return
                    }
                    val inputImage = InputImage.fromMediaImage(
                        mediaImage,
                        imageProxy.imageInfo.rotationDegrees,
                    )
                    textRecognizer.process(inputImage)
                        .addOnSuccessListener { visionText ->
                            imageProxy.close()
                            val result = ReceiptParser.parse(visionText.text)
                            if (result != null) {
                                phase = CameraPhase.Scanned(result)
                                onParsed(result.rawAmount, result.note)
                            } else {
                                phase = CameraPhase.Error(
                                    "Tutarı okuyamadım.\nTutarı daha net görecek şekilde tekrar çek."
                                )
                            }
                        }
                        .addOnFailureListener {
                            imageProxy.close()
                            phase = CameraPhase.Error("OCR hatası: ${it.message}")
                        }
                }

                override fun onError(exception: ImageCaptureException) {
                    phase = CameraPhase.Error("Fotoğraf çekilemedi: ${exception.message}")
                }
            }
        )
    }

    // ── UI ────────────────────────────────────────────────────────────────────
    ModalBottomSheet(
        onDismissRequest = { onDismiss() },
        sheetState       = sheetState,
        containerColor   = DarkBgC,
        dragHandle       = null,
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(560.dp)
        ) {
            // Camera viewfinder fills the background when permission is granted
            // and we haven't yet scanned / errored.
            if (permGranted && phase !is CameraPhase.Scanned && phase !is CameraPhase.Error) {
                AndroidView(
                    factory = { ctx ->
                        val previewView = PreviewView(ctx)
                        cameraProviderFuture.addListener(
                            {
                                val provider = cameraProviderFuture.get()
                                val preview  = androidx.camera.core.Preview.Builder().build().also {
                                    it.setSurfaceProvider(previewView.surfaceProvider)
                                }
                                try {
                                    provider.unbindAll()
                                    provider.bindToLifecycle(
                                        lifecycleOwner,
                                        CameraSelector.DEFAULT_BACK_CAMERA,
                                        preview,
                                        imageCapture,
                                    )
                                } catch (_: Exception) {
                                    phase = CameraPhase.Error("Kamera başlatılamadı.")
                                }
                            },
                            ContextCompat.getMainExecutor(ctx),
                        )
                        previewView
                    },
                    modifier = Modifier.fillMaxSize(),
                )
                // Semi-transparent overlay so UI elements are readable
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color.Black.copy(alpha = 0.30f))
                )
            }

            // Foreground content
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .navigationBarsPadding()
                    .padding(horizontal = Spacing.xl, vertical = Spacing.lg),
            ) {

                // ── Header ────────────────────────────────────────────────────
                Box(modifier = Modifier.fillMaxWidth()) {
                    Box(
                        modifier = Modifier
                            .align(Alignment.CenterStart)
                            .size(36.dp)
                            .clip(CircleShape)
                            .background(Color.White.copy(alpha = 0.16f))
                            .clickable { onDismiss() },
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(Icons.Filled.Close, "Kapat", tint = Color.White, modifier = Modifier.size(15.dp))
                    }
                    CameraStatusPill(phase = phase, modifier = Modifier.align(Alignment.Center))
                }

                Spacer(Modifier.weight(1f))

                // ── Centre content (non-preview states) ───────────────────────
                AnimatedContent(
                    targetState    = phase,
                    transitionSpec = { fadeIn(tween(200)) togetherWith fadeOut(tween(150)) },
                    label          = "camera_center",
                ) { p ->
                    Box(
                        modifier         = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = Spacing.md),
                        contentAlignment = Alignment.Center,
                    ) {
                        when (p) {
                            CameraPhase.Preview -> {
                                // Instruction overlay on the viewfinder
                                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                    Text(
                                        "Fişi çerçevele",
                                        style     = BrandText.largeTitle,
                                        color     = Color.White,
                                        textAlign = TextAlign.Center,
                                    )
                                    Spacer(Modifier.height(Spacing.sm))
                                    Text(
                                        "Tutarın görünür olduğundan emin ol",
                                        style     = BrandText.footnote,
                                        color     = Color.White.copy(alpha = 0.6f),
                                        textAlign = TextAlign.Center,
                                    )
                                }
                            }
                            CameraPhase.Scanning -> Column(
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.spacedBy(Spacing.md),
                            ) {
                                CircularProgressIndicator(color = Color.White, modifier = Modifier.size(32.dp), strokeWidth = 2.dp)
                                Text("Tutar okunuyor…", style = BrandText.body, color = Color.White.copy(alpha = 0.5f))
                            }
                            is CameraPhase.Scanned -> VoiceParsedCard(result = p.result)
                            is CameraPhase.Error -> Column(
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.spacedBy(Spacing.sm),
                            ) {
                                Icon(Icons.Filled.NoPhotography, null, tint = Color.White.copy(alpha = 0.3f), modifier = Modifier.size(40.dp))
                                Text(p.message, style = BrandText.body, color = Color.White.copy(alpha = 0.6f), textAlign = TextAlign.Center)
                            }
                            CameraPhase.NoPerm -> Column(
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.spacedBy(Spacing.sm),
                            ) {
                                Icon(Icons.Filled.NoPhotography, null, tint = Color.White.copy(alpha = 0.3f), modifier = Modifier.size(40.dp))
                                Text(
                                    "Kamera izni gerekli.\nAyarlar > Budgetella > Kamera",
                                    style     = BrandText.body,
                                    color     = Color.White.copy(alpha = 0.6f),
                                    textAlign = TextAlign.Center,
                                )
                            }
                        }
                    }
                }

                Spacer(Modifier.weight(1f))

                // ── Capture / Retry button ────────────────────────────────────
                Column(
                    modifier            = Modifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(Spacing.sm),
                ) {
                    when (phase) {
                        CameraPhase.Preview -> {
                            CaptureButton(onClick = ::captureAndScan)
                            Text("Fişi çekmek için dokun", style = BrandText.caption, color = Color.White.copy(alpha = 0.4f))
                        }
                        is CameraPhase.Error -> {
                            RetryCapButton { phase = CameraPhase.Preview }
                            Text("Tekrar dene", style = BrandText.caption, color = Color.White.copy(alpha = 0.35f))
                        }
                        else -> Spacer(Modifier.height(80.dp))
                    }
                }

                Spacer(Modifier.height(Spacing.xl))
            }
        }
    }
}

// ── Components ────────────────────────────────────────────────────────────────

@Composable
private fun CameraStatusPill(phase: CameraPhase, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier
            .clip(RoundedCornerShape(Spacing.radiusFull))
            .background(Color.White.copy(alpha = 0.14f))
            .padding(horizontal = 14.dp, vertical = 7.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment     = Alignment.CenterVertically,
    ) {
        when (phase) {
            CameraPhase.Preview -> {
                Icon(Icons.Filled.CameraAlt, null, tint = Color.White.copy(alpha = 0.7f), modifier = Modifier.size(11.dp))
                Text("KAMERA GİRİŞİ", style = BrandText.caption.copy(letterSpacing = 1.sp), color = Color.White.copy(alpha = 0.7f))
            }
            CameraPhase.Scanning -> {
                CircularProgressIndicator(color = Color.White, modifier = Modifier.size(14.dp), strokeWidth = 2.dp)
                Text("OKUNUYOR", style = BrandText.caption.copy(letterSpacing = 1.sp), color = Color.White)
            }
            is CameraPhase.Scanned -> {
                Icon(Icons.Filled.CheckCircle, null, tint = GreenOkC, modifier = Modifier.size(11.dp))
                Text("ANLAŞILDI", style = BrandText.caption.copy(letterSpacing = 1.sp), color = Color.White)
            }
            is CameraPhase.Error, CameraPhase.NoPerm -> {
                Icon(Icons.Filled.Warning, null, tint = BrandColor.Warning, modifier = Modifier.size(11.dp))
                Text("HATA", style = BrandText.caption.copy(letterSpacing = 1.sp), color = Color.White)
            }
        }
    }
}

@Composable
private fun CaptureButton(onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .size(80.dp)
            .clip(CircleShape)
            .background(Color.White.copy(alpha = 0.16f))
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            modifier = Modifier
                .size(60.dp)
                .clip(CircleShape)
                .background(Color.White),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Filled.CameraAlt, "Çek", tint = DarkBgC, modifier = Modifier.size(26.dp))
        }
    }
}

@Composable
private fun RetryCapButton(onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .size(72.dp)
            .clip(CircleShape)
            .background(Brush.linearGradient(colors = listOf(AccentC, AccentLtC)))
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Icon(Icons.Filled.CameraAlt, "Tekrar dene", tint = Color.White, modifier = Modifier.size(26.dp))
    }
}

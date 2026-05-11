package com.budgetella.app.ui.settings

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.platform.LocalContext
import com.budgetella.app.data.backup.BackupService
import com.budgetella.app.data.prefs.UserPrefs
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Storage Access Framework wrappers around [BackupService].
 *
 * Compose's launcher API runs the picker on the activity scope but the heavy
 * lifting (DB reads + JSON encode) happens off the main thread via
 * [Dispatchers.IO]. The launcher returns the URI; we open an output/input
 * stream against the user's content provider and stream the JSON through.
 *
 * Both helpers take [BackupService] + [UserPrefs] as parameters so they don't
 * have to depend on Hilt entry-point plumbing — the caller wires them from a
 * ViewModel that already has them injected.
 */

@Composable
fun rememberBackupExportLauncher(
    backupService: BackupService,
    userPrefs: UserPrefs,
    onResult: (success: Boolean) -> Unit,
): () -> Unit {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    val launcher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.CreateDocument(MIME_TYPE_JSON),
    ) { uri ->
        if (uri == null) {
            // User cancelled — surface as failure so the screen can reset its
            // "exporting…" state without showing the success toast.
            onResult(false)
            return@rememberLauncherForActivityResult
        }
        scope.launch {
            val ok = runCatching {
                val uid = userPrefs.currentUserId.first()
                val json = backupService.export(uid)
                withContext(Dispatchers.IO) {
                    context.contentResolver.openOutputStream(uri)?.use { out ->
                        out.write(json.toByteArray(Charsets.UTF_8))
                        out.flush()
                    } ?: error("No output stream for $uri")
                }
            }.isSuccess
            onResult(ok)
        }
    }

    return remember(launcher) {
        {
            val filename = defaultBackupFilename()
            launcher.launch(filename)
        }
    }
}

@Composable
fun rememberBackupImportLauncher(
    backupService: BackupService,
    userPrefs: UserPrefs,
    onResult: (transactionsImported: Int, transactionsSkipped: Int) -> Unit,
): () -> Unit {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    val launcher = rememberLauncherForActivityResult(
        // GetContent with application/json — same picker the iOS UIDocumentPicker
        // mirrors with .json content type.
        contract = ActivityResultContracts.GetContent(),
    ) { uri ->
        if (uri == null) {
            onResult(0, 0)
            return@rememberLauncherForActivityResult
        }
        scope.launch {
            runCatching {
                val uid = userPrefs.currentUserId.first()
                val payload = withContext(Dispatchers.IO) {
                    context.contentResolver.openInputStream(uri)?.use { stream ->
                        stream.readBytes().toString(Charsets.UTF_8)
                    } ?: error("No input stream for $uri")
                }
                backupService.import(payload, uid)
            }.fold(
                onSuccess = { onResult(it.transactionsImported, it.transactionsSkipped) },
                onFailure = { onResult(0, 0) },
            )
        }
    }

    return remember(launcher) {
        { launcher.launch(MIME_TYPE_JSON) }
    }
}

private const val MIME_TYPE_JSON = "application/json"

private fun defaultBackupFilename(): String {
    val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
    return "budgetella_backup_$today.json"
}

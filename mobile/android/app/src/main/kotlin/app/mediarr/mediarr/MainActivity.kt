package app.mediarr.mediarr

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import app.mediarr.mediarr.backup.BackupChannel
import app.mediarr.mediarr.widget.AlbumWidget
import app.mediarr.mediarr.widget.WidgetStore
import app.mediarr.mediarr.widget.WidgetSync
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.UUID

class MainActivity : FlutterFragmentActivity() {
    private var backup: BackupChannel? = null
    private var share: MethodChannel? = null
    private val waiting = mutableListOf<String>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        backup = BackupChannel(this, messenger)
        share = MethodChannel(messenger, "app.mediarr/share").apply {
            setMethodCallHandler { call, result ->
                if (call.method == "take") {
                    result.success(waiting.toList())
                    waiting.clear()
                } else {
                    result.notImplemented()
                }
            }
        }
        // A slideshow keeps the screen on while it plays.
        MethodChannel(messenger, "app.mediarr/awake").setMethodCallHandler { call, result ->
            if (call.method == "set") {
                if (call.argument<Boolean>("on") == true) {
                    window.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                } else {
                    window.clearFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                }
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
        // The home screen widget shows an album the user chooses here.
        MethodChannel(messenger, "app.mediarr/widget").setMethodCallHandler { call, result ->
            val store = WidgetStore(this)
            when (call.method) {
                "configure" -> {
                    store.configure(
                        call.argument<String>("server") ?: "",
                        call.argument<String>("key") ?: "",
                        call.argument<String>("albumId") ?: "",
                        call.argument<String>("albumTitle") ?: "",
                    )
                    WidgetSync.schedule(this)
                    AlbumWidget.refresh(this)
                    result.success(null)
                }
                "clear" -> {
                    WidgetSync.cancel(this)
                    store.clear()
                    AlbumWidget.refresh(this)
                    result.success(null)
                }
                "status" -> result.success(
                    mapOf(
                        "albumId" to store.albumId,
                        "albumTitle" to store.albumTitle,
                        "pictures" to store.pictures.size,
                    ),
                )
                else -> result.notImplemented()
            }
        }
        receive(intent)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        backup?.dispose()
        backup = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        receive(intent)
    }

    @Suppress("DEPRECATION")
    private fun sharedUris(intent: Intent): List<Uri> = when (intent.action) {
        Intent.ACTION_SEND -> listOfNotNull(
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                intent.getParcelableExtra(Intent.EXTRA_STREAM)
            },
        )
        Intent.ACTION_SEND_MULTIPLE ->
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM)
            } ?: emptyList()
        else -> emptyList()
    }

    /** The app only gets to read a shared file for a moment, so it works on its own copy. */
    private fun receive(intent: Intent?) {
        val uris = intent?.let(::sharedUris).orEmpty()
        if (uris.isEmpty()) return
        intent?.action = null
        Thread {
            val copies = uris.mapNotNull(::copy)
            runOnUiThread {
                waiting += copies
                share?.invokeMethod("changed", null)
            }
        }.start()
    }

    private fun copy(uri: Uri): String? = try {
        val name = contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { if (it.moveToFirst()) it.getString(0) else null }
            ?: "shared"
        val dir = File(cacheDir, "shared/${UUID.randomUUID()}").apply { mkdirs() }
        // Only the last part: a name from another app must not lead out of this folder.
        val file = File(dir, File(name).name)
        contentResolver.openInputStream(uri)?.use { input ->
            file.outputStream().use { input.copyTo(it) }
        }
        file.path
    } catch (_: java.io.IOException) {
        null
    } catch (_: SecurityException) {
        null
    }
}

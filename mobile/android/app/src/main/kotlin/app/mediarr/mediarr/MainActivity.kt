package app.mediarr.mediarr

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import app.mediarr.mediarr.backup.BackupChannel
import app.mediarr.mediarr.backup.isServerAddress
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
                if (call.argument<Any>("on") == true) {
                    window.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                } else {
                    window.clearFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                }
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
        // With the app lock on, the list of recent apps shows no picture of the app. Screenshots
        // stay allowed, so this is not FLAG_SECURE.
        MethodChannel(messenger, "app.mediarr/lock").setMethodCallHandler { call, result ->
            if (call.method == "recents") {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    setRecentsScreenshotEnabled(call.argument<Any>("hidden") != true)
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
                    val server = call.argument<Any>("server") as? String
                    val key = call.argument<Any>("key") as? String
                    val album = call.argument<Any>("albumId") as? String
                    if (!isServerAddress(server) || key.isNullOrEmpty() || album.isNullOrEmpty() ||
                        !album.all { it.isLetterOrDigit() || it == '-' }
                    ) {
                        result.error("args", "server, key and albumId are needed", null)
                    } else {
                        store.configure(server!!.trimEnd('/'), key, album, call.argument<Any>("albumTitle") as? String ?: "")
                        WidgetSync.schedule(this)
                        AlbumWidget.refresh(this)
                        result.success(null)
                    }
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

    /**
     * Only what another app offers through its own content provider. A file:// address, or one of
     * this app's own providers, would be opened with this app's rights, and could hand over its
     * private files (its keys among them) as if they had been shared.
     */
    private fun mayReceive(uri: Uri): Boolean {
        if (uri.scheme != "content") return false
        val authority = uri.authority ?: return false
        val owner = try {
            packageManager.resolveContentProvider(authority, 0)?.packageName
        } catch (_: RuntimeException) {
            null
        }
        // A provider this app cannot see is not one of its own.
        return owner != packageName
    }

    /** The app only gets to read a shared file for a moment, so it works on its own copy. */
    private fun receive(intent: Intent?) {
        val uris = intent?.let(::sharedUris).orEmpty().filter(::mayReceive).take(MAX_SHARED)
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
        val safe = File(name).name.takeUnless { it.isBlank() || it == "." || it == ".." } ?: "shared"
        val file = File(dir, safe.take(MAX_NAME))
        val input = contentResolver.openInputStream(uri)
        if (input == null) {
            dir.delete()
            null
        } else {
            input.use { source -> file.outputStream().use { source.copyTo(it) } }
            file.path
        }
    } catch (_: java.io.IOException) {
        null
    } catch (_: SecurityException) {
        null
    } catch (_: IllegalArgumentException) {
        null
    }

    private companion object {
        /** More at once than anyone shares by hand. */
        const val MAX_SHARED = 500
        const val MAX_NAME = 200
    }
}

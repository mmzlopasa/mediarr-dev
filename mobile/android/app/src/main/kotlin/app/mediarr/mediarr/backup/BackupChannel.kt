package app.mediarr.mediarr.backup

import android.content.Context
import android.database.ContentObserver
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/** Connects the native backup to the Flutter interface, the same way as on iOS. */
class BackupChannel(context: Context, messenger: BinaryMessenger) {
    private val app = context.applicationContext
    private val engine = BackupEngine(app)
    private val background = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    /** While the app is open it looks for new photos every minute, and at once on a change. */
    private val tick = object : Runnable {
        override fun run() {
            engine.runNow()
            main.postDelayed(this, CHECK_EVERY_MS)
        }
    }
    private val observer = object : ContentObserver(main) {
        override fun onChange(selfChange: Boolean) = engine.runNow()
    }

    init {
        MethodChannel(messenger, "app.mediarr/backup").setMethodCallHandler { call, result ->
            fun <T> reply(work: () -> T) = background.execute {
                try {
                    val value = work()
                    main.post { result.success(value) }
                } catch (cause: SecurityException) {
                    main.post { result.error("permission", cause.message, null) }
                } catch (cause: android.database.SQLException) {
                    main.post { result.error("store", cause.message, null) }
                }
            }
            when (call.method) {
                "enable" -> {
                    val server = call.argument<String>("server")
                    val key = call.argument<String>("key")
                    val id = call.argument<String>("albumId")
                    val name = call.argument<String>("albumName") ?: ""
                    if (server == null || key == null || (id == null && name.isEmpty())) {
                        result.error("arguments", "server, key and album are required", null)
                    } else {
                        reply {
                            engine.enable(
                                server, key,
                                call.argument<Boolean>("wifiOnly") ?: true,
                                call.argument<Boolean>("onlyNew") ?: false,
                                id, name,
                            )
                            null
                        }
                    }
                }
                "setAlbum" -> reply {
                    engine.setAlbum(
                        call.argument<String>("albumId"),
                        call.argument<String>("albumName") ?: "",
                        call.argument<Boolean>("onlyNew") ?: false,
                    )
                    null
                }
                "albums" -> reply {
                    engine.albums().map { mapOf("id" to it.id, "title" to it.title, "count" to it.count) }
                }
                "disable" -> reply { engine.disable(); null }
                "setWifiOnly" -> reply { engine.setWifiOnly(call.argument<Boolean>("value") ?: true); null }
                "setChargingOnly" -> reply { engine.setChargingOnly(call.argument<Boolean>("value") ?: false); null }
                "setServer" -> reply { call.argument<String>("value")?.let(engine::setServer); null }
                "retryFailed" -> reply { engine.retryFailed(); null }
                "status" -> reply { engine.status() }
                "statuses" -> reply { engine.store.statuses(call.argument<List<String>>("ids") ?: emptyList()) }
                "verifiedChecksums" -> reply { engine.store.verifiedChecksums() }
                "waiting" -> reply { engine.store.waiting(call.argument<Int>("limit") ?: DEFAULT_LIMIT) }
                else -> result.notImplemented()
            }
        }
        main.postDelayed(tick, CHECK_EVERY_MS)
        for (collection in listOf(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
        )) {
            app.contentResolver.registerContentObserver(collection, true, observer)
        }
    }

    fun dispose() {
        main.removeCallbacks(tick)
        app.contentResolver.unregisterContentObserver(observer)
        background.shutdown()
    }

    private companion object {
        const val CHECK_EVERY_MS = 60_000L
        const val DEFAULT_LIMIT = 60
    }
}

package app.mediarr.mediarr.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import app.mediarr.mediarr.MainActivity
import app.mediarr.mediarr.R
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.TimeUnit
import org.json.JSONArray
import org.json.JSONObject

/** What the widget shows: an album the user chose in the app, with a few of its pictures kept here. */
class WidgetStore(context: Context) {
    private val context = context.applicationContext
    private val prefs = this.context.getSharedPreferences("mediarr_widget", Context.MODE_PRIVATE)
    val folder: File get() = File(context.filesDir, "widget").apply { mkdirs() }

    val server get() = prefs.getString(KEY_SERVER, null)
    val key get() = prefs.getString(KEY_KEY, null)
    val albumId get() = prefs.getString(KEY_ALBUM, null)
    val albumTitle get() = prefs.getString(KEY_TITLE, "") ?: ""

    /** The pictures kept, as files, in the order they were chosen. */
    val pictures: List<File>
        get() = prefs.getString(KEY_PICTURES, null)?.let { raw ->
            val list = JSONArray(raw)
            (0 until list.length()).map { File(folder, list.getString(it)) }.filter { it.isFile }
        } ?: emptyList()

    fun configure(server: String, key: String, albumId: String, title: String) {
        prefs.edit().putString(KEY_SERVER, server).putString(KEY_KEY, key)
            .putString(KEY_ALBUM, albumId).putString(KEY_TITLE, title).apply()
    }

    fun clear() {
        prefs.edit().clear().apply()
        folder.listFiles()?.forEach { it.delete() }
    }

    fun setPictures(names: List<String>) {
        prefs.edit().putString(KEY_PICTURES, JSONArray(names).toString()).apply()
        val keep = names.toSet()
        folder.listFiles()?.filter { it.name !in keep }?.forEach { it.delete() }
    }

    companion object {
        private const val KEY_SERVER = "server"
        private const val KEY_KEY = "key"
        private const val KEY_ALBUM = "album"
        private const val KEY_TITLE = "title"
        private const val KEY_PICTURES = "pictures"
    }
}

/** A picture from the chosen album on the home screen; it changes every hour and opens the app. */
class AlbumWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val store = WidgetStore(context)
        val pictures = store.pictures
        for (id in ids) {
            val views = RemoteViews(context.packageName, R.layout.album_widget)
            val open = PendingIntent.getActivity(
                context, 0, Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, open)
            val picture = pictures.getOrNull(((System.currentTimeMillis() / HOUR_MS) % pictures.size.coerceAtLeast(1)).toInt())
            val bitmap = picture?.let { BitmapFactory.decodeFile(it.path) }
            if (bitmap != null) {
                views.setImageViewBitmap(R.id.widget_picture, bitmap)
                views.setViewVisibility(R.id.widget_picture, View.VISIBLE)
                views.setTextViewText(R.id.widget_title, store.albumTitle)
                views.setViewVisibility(R.id.widget_title, if (store.albumTitle.isEmpty()) View.GONE else View.VISIBLE)
                views.setViewVisibility(R.id.widget_hint, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_picture, View.GONE)
                views.setViewVisibility(R.id.widget_title, View.GONE)
                views.setViewVisibility(R.id.widget_hint, View.VISIBLE)
                views.setTextViewText(
                    R.id.widget_hint,
                    context.getString(if (store.albumId == null) R.string.widget_choose else R.string.widget_loading),
                )
            }
            manager.updateAppWidget(id, views)
        }
    }

    override fun onEnabled(context: Context) {
        if (WidgetStore(context).albumId != null) WidgetSync.schedule(context)
    }

    companion object {
        private const val HOUR_MS = 60 * 60 * 1000L

        /** Draws every widget again, after the album or its pictures changed. */
        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, AlbumWidget::class.java))
            if (ids.isNotEmpty()) AlbumWidget().onUpdate(context, manager, ids)
        }
    }
}

/** Fetches up to 20 pictures of the chosen album, so the widget shows them without a connection. */
class WidgetSync(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        val store = WidgetStore(applicationContext)
        val server = store.server ?: return Result.success()
        val key = store.key ?: return Result.success()
        val album = store.albumId ?: return Result.success()
        return try {
            val months = JSONObject(get("$server/api/albums/$album/buckets", key).decodeToString())
                .optJSONArray("buckets") ?: JSONArray()
            val ids = mutableListOf<String>()
            for (i in 0 until months.length()) {
                if (ids.size >= CANDIDATES) break
                val month = months.getJSONObject(i).getString("month")
                val items = JSONObject(get("$server/api/albums/$album/buckets/$month", key).decodeToString())
                    .optJSONArray("items") ?: continue
                for (j in 0 until items.length()) {
                    val item = items.getJSONObject(j)
                    if (item.optString("kind") == "photo") ids += item.getString("id")
                }
            }
            val names = mutableListOf<String>()
            for (id in ids.shuffled().take(KEPT)) {
                if (isStopped) break
                val name = "$id.jpg"
                val file = File(store.folder, name)
                if (!file.isFile) {
                    val bytes = get("$server/api/assets/$id/thumbnail?size=large", key)
                    val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: continue
                    // Small enough for a widget, which has little memory to draw with.
                    val scale = MAX_SIDE.toFloat() / maxOf(bitmap.width, bitmap.height)
                    val sized = if (scale < 1f) {
                        Bitmap.createScaledBitmap(bitmap, (bitmap.width * scale).toInt(), (bitmap.height * scale).toInt(), true)
                    } else {
                        bitmap
                    }
                    file.outputStream().use { sized.compress(Bitmap.CompressFormat.JPEG, QUALITY, it) }
                }
                names += name
            }
            store.setPictures(names)
            AlbumWidget.refresh(applicationContext)
            Result.success()
        } catch (_: java.io.IOException) {
            Result.retry()
        } catch (_: org.json.JSONException) {
            Result.retry()
        }
    }

    private fun get(url: String, key: String): ByteArray {
        val connection = URL(url).openConnection() as HttpURLConnection
        return try {
            connection.connectTimeout = TIMEOUT_MS
            connection.readTimeout = TIMEOUT_MS
            connection.setRequestProperty("X-Api-Key", key)
            if (connection.responseCode != 200) throw java.io.IOException("the server answered ${connection.responseCode}")
            connection.inputStream.use { it.readBytes() }
        } finally {
            connection.disconnect()
        }
    }

    companion object {
        private const val CANDIDATES = 400
        private const val KEPT = 20
        private const val MAX_SIDE = 800
        private const val QUALITY = 85
        private const val TIMEOUT_MS = 20_000
        private const val NOW = "mediarr-widget-now"
        private const val DAILY = "mediarr-widget-daily"

        private val network = Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build()

        /** Fetches now, and then twice a day, for new pictures in the album. */
        fun schedule(context: Context) {
            val manager = WorkManager.getInstance(context)
            manager.enqueueUniqueWork(
                NOW, ExistingWorkPolicy.REPLACE,
                OneTimeWorkRequestBuilder<WidgetSync>().setConstraints(network).build(),
            )
            manager.enqueueUniquePeriodicWork(
                DAILY, ExistingPeriodicWorkPolicy.UPDATE,
                PeriodicWorkRequestBuilder<WidgetSync>(12, TimeUnit.HOURS).setConstraints(network).build(),
            )
        }

        fun cancel(context: Context) {
            val manager = WorkManager.getInstance(context)
            manager.cancelUniqueWork(NOW)
            manager.cancelUniqueWork(DAILY)
        }
    }
}

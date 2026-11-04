package app.mediarr.mediarr.backup

import android.content.ContentUris
import android.content.Context
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Base64
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import org.json.JSONArray
import org.json.JSONObject

data class BackupAlbum(val id: String, val title: String, val count: Int)

data class LocalAsset(
    val id: String,
    val uri: Uri,
    val name: String,
    val size: Long,
    val createdMs: Long,
)

/** What a finished transfer means for the file. */
sealed class Outcome {
    object Verified : Outcome()
    data class Retry(val reason: String) : Outcome()
    data class Rejected(val reason: String) : Outcome()
    object Unauthorized : Outcome()
}

/** The same meaning the iOS code gives to the server's answers. */
fun outcomeOf(status: Int): Outcome = when (status) {
    201, 204 -> Outcome.Verified
    401, 403 -> Outcome.Unauthorized
    460 -> Outcome.Rejected("The file was damaged on the way to the server.")
    408, 429, in 500..599 -> Outcome.Retry("The server answered $status.")
    else -> Outcome.Rejected("The server refused this file ($status).")
}

fun normalizeAlbumName(name: String) = name.trim().lowercase()

/** The chosen album, or one with the typed name. Null means nothing is sent, ever. */
fun findAlbum(id: String?, name: String?, albums: List<BackupAlbum>): BackupAlbum? {
    albums.firstOrNull { it.id == id }?.let { return it }
    val wanted = normalizeAlbumName(name ?: return null)
    if (wanted.isEmpty()) return null
    return albums.firstOrNull { normalizeAlbumName(it.title) == wanted }
}

fun encodeMetadata(metadata: List<Pair<String, String>>): String =
    metadata.joinToString(",") { (key, value) ->
        "$key ${Base64.encodeToString(value.toByteArray(), Base64.NO_WRAP)}"
    }

class BackupEngine(context: Context) {
    private val context = context.applicationContext
    private val prefs = this.context.getSharedPreferences("mediarr_backup", Context.MODE_PRIVATE)
    val store = BackupStore(this.context)

    val enabled get() = prefs.getBoolean(KEY_ENABLED, false)
    private val server get() = prefs.getString(KEY_SERVER, null)
    private val key get() = prefs.getString(KEY_KEY, null)
    private val wifiOnly get() = prefs.getBoolean(KEY_WIFI, true)
    private val chargingOnly get() = prefs.getBoolean(KEY_CHARGING, false)
    private val albumId get() = prefs.getString(KEY_ALBUM_ID, null)
    private val albumName get() = prefs.getString(KEY_ALBUM_NAME, null)
    private val moreAlbums get() = prefs.getStringSet(KEY_MORE_ALBUMS, emptySet()) ?: emptySet()
    private val excludedAlbums get() = prefs.getStringSet(KEY_EXCLUDED_ALBUMS, emptySet()) ?: emptySet()

    fun enable(server: String, key: String, wifiOnly: Boolean, onlyNew: Boolean, albumId: String?, albumName: String) {
        prefs.edit()
            .putBoolean(KEY_ENABLED, true)
            .putBoolean(KEY_UNAUTHORIZED, false)
            .putString(KEY_SERVER, server)
            .putString(KEY_KEY, key)
            .putBoolean(KEY_WIFI, wifiOnly)
            .apply()
        choose(albumId, albumName, onlyNew)
    }

    fun setAlbum(albumId: String?, albumName: String, onlyNew: Boolean) = choose(albumId, albumName, onlyNew)

    private fun choose(albumId: String?, albumName: String, onlyNew: Boolean) {
        prefs.edit().putString(KEY_ALBUM_ID, albumId).putString(KEY_ALBUM_NAME, albumName).apply()
        val album = findAlbum(albumId, albumName, albums())
        val inAlbum = album?.let(::assetsIn) ?: emptyList()
        store.forgetPending(inAlbum.map { it.id }.toSet())
        if (onlyNew) store.addSkipped(inAlbum.map { it.id to it.createdMs })
        schedule()
        runNow()
    }

    /** More albums beside the chosen one, and albums whose photos are never sent. */
    fun setAlbumLists(more: List<String>, excluded: List<String>, onlyNew: Boolean) {
        val added = more.toSet() - moreAlbums
        prefs.edit()
            .putStringSet(KEY_MORE_ALBUMS, more.toSet())
            .putStringSet(KEY_EXCLUDED_ALBUMS, excluded.toSet())
            .apply()
        if (onlyNew) {
            for (album in albums().filter { it.id in added }) {
                store.addSkipped(assetsIn(album).map { it.id to it.createdMs })
            }
        }
        store.forgetPending(assetsToSend().map { it.id }.toSet())
        runNow()
    }

    /** For each chosen album, the checksums of its photos that are safely on the server. */
    fun albumChecksums(): List<Map<String, Any>> {
        val all = albums()
        val verified = store.verifiedChecksums()
        val never = excludedAlbums
        return (listOfNotNull(findAlbum(albumId, albumName, all)) + all.filter { it.id in moreAlbums })
            .distinctBy { it.id }
            .filter { it.id !in never }
            .map { album ->
                mapOf(
                    "title" to album.title,
                    "checksums" to assetsIn(album).flatMap { verified[it.id] ?: emptyList() },
                )
            }
    }

    /** Everything in the chosen albums, except what is also in an excluded one. */
    private fun assetsToSend(): List<LocalAsset> {
        val all = albums()
        val chosen = (listOfNotNull(findAlbum(albumId, albumName, all)) + all.filter { it.id in moreAlbums })
            .distinctBy { it.id }
            .filter { it.id !in excludedAlbums }
        val assets = chosen.flatMap(::assetsIn).distinctBy { it.id }
        val never = all.filter { it.id in excludedAlbums }.flatMap(::assetsIn).map { it.id }.toSet()
        return assets.filter { it.id !in never }
    }

    fun disable() {
        val manager = WorkManager.getInstance(context)
        manager.cancelUniqueWork(WORK_ONCE)
        manager.cancelUniqueWork(WORK_PERIODIC)
        prefs.edit()
            .putBoolean(KEY_ENABLED, false)
            .remove(KEY_KEY)
            .remove(KEY_ALBUM_ID)
            .remove(KEY_ALBUM_NAME)
            .remove(KEY_MORE_ALBUMS)
            .remove(KEY_EXCLUDED_ALBUMS)
            .apply()
        store.clear()
    }

    fun setWifiOnly(value: Boolean) {
        prefs.edit().putBoolean(KEY_WIFI, value).apply()
        schedule()
        runNow()
    }

    fun setChargingOnly(value: Boolean) {
        prefs.edit().putBoolean(KEY_CHARGING, value).apply()
        schedule()
        runNow()
    }

    fun setServer(value: String) {
        prefs.edit().putString(KEY_SERVER, value).apply()
        runNow()
    }

    fun retryFailed() {
        store.retryFailed()
        runNow()
    }

    private fun constraints() = Constraints.Builder()
        .setRequiredNetworkType(if (wifiOnly) NetworkType.UNMETERED else NetworkType.CONNECTED)
        .setRequiresCharging(chargingOnly)
        .build()

    /** Android decides when this runs, at most every 15 minutes, also with the app closed. */
    private fun schedule() {
        val periodic = PeriodicWorkRequestBuilder<BackupWorker>(15, TimeUnit.MINUTES)
            .setConstraints(constraints())
            .build()
        WorkManager.getInstance(context)
            .enqueueUniquePeriodicWork(WORK_PERIODIC, ExistingPeriodicWorkPolicy.UPDATE, periodic)
    }

    fun runNow() {
        if (!enabled) return
        val once = OneTimeWorkRequestBuilder<BackupWorker>().setConstraints(constraints()).build()
        // Keep a run in progress: it looks through the album again before it finishes.
        WorkManager.getInstance(context).enqueueUniqueWork(WORK_ONCE, ExistingWorkPolicy.KEEP, once)
    }

    private fun collections(): List<Uri> = listOf(
        MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
        MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
    )

    fun albums(): List<BackupAlbum> {
        val found = linkedMapOf<String, BackupAlbum>()
        for (collection in collections()) {
            context.contentResolver.query(
                collection,
                arrayOf(MediaStore.MediaColumns.BUCKET_ID, MediaStore.MediaColumns.BUCKET_DISPLAY_NAME),
                null,
                null,
                null,
            )?.use { cursor ->
                while (cursor.moveToNext()) {
                    val id = cursor.getString(0) ?: continue
                    val title = cursor.getString(1) ?: continue
                    val known = found[id]
                    found[id] = BackupAlbum(id, title, (known?.count ?: 0) + 1)
                }
            }
        }
        return found.values.sortedBy { it.title.lowercase() }
    }

    private fun currentAlbum(): BackupAlbum? = findAlbum(albumId, albumName, albums())

    private fun assetsIn(album: BackupAlbum): List<LocalAsset> {
        val out = mutableListOf<LocalAsset>()
        for (collection in collections()) {
            context.contentResolver.query(
                collection,
                arrayOf(
                    MediaStore.MediaColumns._ID,
                    MediaStore.MediaColumns.DISPLAY_NAME,
                    MediaStore.MediaColumns.SIZE,
                    MediaStore.MediaColumns.DATE_ADDED,
                ),
                "${MediaStore.MediaColumns.BUCKET_ID} = ?",
                arrayOf(album.id),
                null,
            )?.use { cursor ->
                while (cursor.moveToNext()) {
                    val id = cursor.getLong(0)
                    out += LocalAsset(
                        id.toString(),
                        ContentUris.withAppendedId(collection, id),
                        cursor.getString(1) ?: "$id",
                        cursor.getLong(2),
                        cursor.getLong(3) * 1000,
                    )
                }
            }
        }
        return out
    }

    private fun original(uri: Uri): Uri =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                // With the location still in the file, as the owner took it.
                MediaStore.setRequireOriginal(uri)
            } catch (_: UnsupportedOperationException) {
                uri
            }
        } else {
            uri
        }

    private fun open(uri: Uri): InputStream? =
        try {
            context.contentResolver.openInputStream(original(uri))
        } catch (_: SecurityException) {
            context.contentResolver.openInputStream(uri)
        }

    private fun sha256(uri: Uri): String? {
        val digest = MessageDigest.getInstance("SHA-256")
        val stream = open(uri) ?: return null
        stream.use { input ->
            val buffer = ByteArray(BUFFER)
            while (true) {
                val read = input.read(buffer)
                if (read < 0) break
                digest.update(buffer, 0, read)
            }
        }
        return digest.digest().joinToString("") { "%02x".format(it) }
    }

    private fun serverHasFile(checksum: String): Boolean {
        val connection = URL("$server/api/assets/check").openConnection() as HttpURLConnection
        return try {
            connection.requestMethod = "POST"
            connection.doOutput = true
            connection.connectTimeout = TIMEOUT_MS
            connection.readTimeout = TIMEOUT_MS
            connection.setRequestProperty("X-Api-Key", key)
            connection.setRequestProperty("Content-Type", "application/json")
            connection.outputStream.use {
                it.write(JSONObject().put("checksums", JSONArray(listOf(checksum))).toString().toByteArray())
            }
            if (connection.responseCode != 200) return false
            val body = connection.inputStream.use { it.readBytes().decodeToString() }
            val existing = JSONObject(body).optJSONArray("existing") ?: return false
            (0 until existing.length()).any { existing.getString(it) == checksum }
        } catch (_: java.io.IOException) {
            // The upload then goes ahead, and the server still stores no duplicate.
            false
        } catch (_: org.json.JSONException) {
            false
        } finally {
            connection.disconnect()
        }
    }

    private fun upload(asset: LocalAsset, checksum: String): Outcome {
        val connection = URL("$server/api/uploads").openConnection() as HttpURLConnection
        return try {
            connection.requestMethod = "POST"
            connection.doOutput = true
            connection.setFixedLengthStreamingMode(asset.size)
            connection.connectTimeout = TIMEOUT_MS
            connection.readTimeout = UPLOAD_TIMEOUT_MS
            connection.setRequestProperty("X-Api-Key", key)
            connection.setRequestProperty("Tus-Resumable", "1.0.0")
            connection.setRequestProperty("Upload-Length", asset.size.toString())
            connection.setRequestProperty("Content-Type", "application/offset+octet-stream")
            connection.setRequestProperty(
                "Upload-Metadata",
                encodeMetadata(
                    listOf(
                        "filename" to asset.name,
                        "checksum" to checksum,
                        "lastModified" to asset.createdMs.toString(),
                    ),
                ),
            )
            val source = open(asset.uri) ?: return Outcome.Retry("The file could not be read.")
            source.use { input -> connection.outputStream.use { input.copyTo(it, BUFFER) } }
            outcomeOf(connection.responseCode)
        } catch (cause: java.io.IOException) {
            Outcome.Retry(cause.message ?: "The connection was lost.")
        } finally {
            connection.disconnect()
        }
    }

    /** Looks through the chosen album and sends what is new. Returns false if it should run again. */
    fun work(progress: (sent: Int) -> Unit, stopped: () -> Boolean): Boolean {
        // The periodic and the immediate job can start together, and would send the same file twice.
        if (!running.compareAndSet(false, true)) return true
        return try {
            send(progress, stopped)
        } finally {
            running.set(false)
        }
    }

    private fun send(progress: (sent: Int) -> Unit, stopped: () -> Boolean): Boolean {
        if (!enabled || server == null || key == null) return true
        store.recoverInterrupted()
        val assets = assetsToSend().associateBy { it.id }
        if (assets.isEmpty() && currentAlbum() == null && moreAlbums.isEmpty()) return true
        store.add(assets.values.map { it.id to it.createdMs })
        store.forgetPending(assets.keys)
        var sent = 0
        while (!stopped()) {
            val item = store.nextPending() ?: return true
            val asset = assets[item.assetId]
            if (asset == null) {
                store.recordFailure(item.assetId, "The file is no longer in the album.", MAX_ATTEMPTS)
                continue
            }
            val checksum = try {
                sha256(asset.uri)
            } catch (cause: java.io.IOException) {
                store.recordFailure(item.assetId, cause.message ?: "The file could not be read.", MAX_ATTEMPTS)
                continue
            }
            if (checksum == null) {
                store.recordFailure(item.assetId, "The file could not be read.", MAX_ATTEMPTS)
                continue
            }
            store.setUploading(item.assetId, checksum)
            if (serverHasFile(checksum)) {
                store.markVerified(item.assetId)
                continue
            }
            when (val outcome = upload(asset, checksum)) {
                Outcome.Verified -> {
                    store.markVerified(item.assetId)
                    sent += 1
                    progress(sent)
                }
                is Outcome.Retry -> {
                    store.recordFailure(item.assetId, outcome.reason, MAX_ATTEMPTS)
                    return false
                }
                is Outcome.Rejected -> store.recordFailure(item.assetId, outcome.reason, 1)
                Outcome.Unauthorized -> {
                    prefs.edit().putBoolean(KEY_UNAUTHORIZED, true).apply()
                    store.recoverInterrupted()
                    return true
                }
            }
        }
        return false
    }

    fun status(): Map<String, Any?> {
        val counts = store.counts()
        val album = currentAlbum()
        return mapOf(
            "enabled" to enabled,
            "wifiOnly" to wifiOnly,
            "chargingOnly" to chargingOnly,
            "unauthorized" to prefs.getBoolean(KEY_UNAUTHORIZED, false),
            "pending" to (counts[BackupStatus.PENDING] ?: 0),
            "working" to (counts[BackupStatus.UPLOADING] ?: 0),
            "verified" to (counts[BackupStatus.VERIFIED] ?: 0),
            "failed" to (counts[BackupStatus.FAILED] ?: 0),
            "lastFinished" to store.lastFinished()?.let { it / 1000.0 },
            "failures" to store.failures(FAILURES_SHOWN),
            "albumName" to (album?.title ?: albumName ?: ""),
            "albumFound" to (album != null || moreAlbums.isNotEmpty()),
            "moreAlbums" to moreAlbums.toList(),
            "excludedAlbums" to excludedAlbums.toList(),
            "limitedAccess" to false,
        )
    }

    companion object {
        private val running = AtomicBoolean(false)
        const val MAX_ATTEMPTS = 5
        private const val FAILURES_SHOWN = 5
        private const val BUFFER = 1024 * 1024
        private const val TIMEOUT_MS = 20_000
        private const val UPLOAD_TIMEOUT_MS = 10 * 60_000
        private const val WORK_ONCE = "mediarr-backup-once"
        private const val WORK_PERIODIC = "mediarr-backup-periodic"
        private const val KEY_ENABLED = "enabled"
        private const val KEY_UNAUTHORIZED = "unauthorized"
        private const val KEY_SERVER = "server"
        private const val KEY_KEY = "key"
        private const val KEY_WIFI = "wifiOnly"
        private const val KEY_CHARGING = "chargingOnly"
        private const val KEY_ALBUM_ID = "albumId"
        private const val KEY_ALBUM_NAME = "albumName"
        private const val KEY_MORE_ALBUMS = "moreAlbums"
        private const val KEY_EXCLUDED_ALBUMS = "excludedAlbums"
    }
}

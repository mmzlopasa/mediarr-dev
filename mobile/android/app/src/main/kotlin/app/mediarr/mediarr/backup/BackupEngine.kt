package app.mediarr.mediarr.backup

import android.Manifest
import android.content.ContentUris
import android.content.Context
import android.content.pm.PackageManager
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
    /** When the file was last written, from MediaStore. A change after it was sent means an edit. */
    val modifiedMs: Long = 0,
)

/** The checksum of exactly the bytes that are sent, and how many there are. */
data class Hashed(val checksum: String, val size: Long)

/** What a finished transfer means for the file. */
sealed class Outcome {
    object Verified : Outcome()
    data class Retry(val reason: String) : Outcome()
    data class Rejected(val reason: String) : Outcome()
    object Unauthorized : Outcome()
    /** The file could not be read to the end, or changed while it was sent. Not the server's fault. */
    data class Unreadable(val reason: String) : Outcome()
    /** Android asked the work to stop between two parts. Not a failure: the next run goes on. */
    object Paused : Outcome()
}

/** The file ended early, or could not be read, while it was being sent. */
class FileChanged(message: String) : Exception(message)

/**
 * Copies exactly [size] bytes, the number that was hashed. Fewer means the file changed since, and
 * a reading error is the file's, not the network's: neither may count as an unreachable server.
 */
fun copyExactly(input: InputStream, output: java.io.OutputStream, size: Long, buffer: Int = 1024 * 1024) {
    val bytes = ByteArray(buffer)
    var left = size
    while (left > 0) {
        val read = try {
            input.read(bytes, 0, minOf(bytes.size.toLong(), left).toInt())
        } catch (cause: java.io.IOException) {
            throw FileChanged("The file could not be read: ${cause.message ?: cause.javaClass.simpleName}")
        }
        if (read < 0) throw FileChanged("The file changed while it was being sent.")
        output.write(bytes, 0, read)
        left -= read
    }
}

/**
 * Passes over the first [count] bytes, for an upload that goes on from where the server got to.
 * skip() may pass over fewer than asked, or none, without the file having ended: a read then tells
 * which it is. The file ending first means it changed.
 */
fun skipExactly(input: InputStream, count: Long, buffer: Int = 64 * 1024) {
    var left = count
    var scratch: ByteArray? = null
    while (left > 0) {
        try {
            val skipped = input.skip(left)
            if (skipped > 0) {
                left -= skipped
                continue
            }
            val bytes = scratch ?: ByteArray(buffer).also { scratch = it }
            val read = input.read(bytes, 0, minOf(bytes.size.toLong(), left).toInt())
            if (read < 0) throw FileChanged("The file changed while it was being sent.")
            left -= read
        } catch (cause: java.io.IOException) {
            throw FileChanged("The file could not be read: ${cause.message ?: cause.javaClass.simpleName}")
        }
    }
}

/**
 * The upload's id from the Location the server gives when it makes one. Only the id is kept: the
 * address is put together again from the server the app is set up with, as a proxy may report a
 * host or a scheme this phone cannot reach. Letters, digits and dashes only, as it goes in a path.
 */
fun uploadIdFrom(location: String?): String? {
    val id = location?.substringBefore('?')?.trimEnd('/')?.substringAfterLast('/') ?: return null
    if (id.isEmpty() || id.length > 64) return null
    return if (id.all { (it in 'a'..'z') || (it in 'A'..'Z') || (it in '0'..'9') || it == '-' }) id else null
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

/**
 * The original could not be opened. Android would give a copy without the photo's location
 * instead, which is never sent: the phone could later free up space believing it was safe.
 */
class OriginalUnavailable : Exception()

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
    /** Kept encrypted with a key in the Android Keystore. */
    private val key get() = SecretStore.read(prefs, KEY_KEY)
    private val unauthorized get() = prefs.getBoolean(KEY_UNAUTHORIZED, false)
    private val wifiOnly get() = prefs.getBoolean(KEY_WIFI, true)
    private val chargingOnly get() = prefs.getBoolean(KEY_CHARGING, false)
    private val albumId get() = prefs.getString(KEY_ALBUM_ID, null)
    private val albumName get() = prefs.getString(KEY_ALBUM_NAME, null)
    private val moreAlbums get() = prefs.getStringSet(KEY_MORE_ALBUMS, emptySet()) ?: emptySet()
    private val excludedAlbums get() = prefs.getStringSet(KEY_EXCLUDED_ALBUMS, emptySet()) ?: emptySet()

    /** This phone among the devices the server lists. Made up once, and kept when backup is off. */
    val deviceId: String
        get() = prefs.getString(KEY_DEVICE_ID, null)
            ?: java.util.UUID.randomUUID().toString().also { prefs.edit().putString(KEY_DEVICE_ID, it).apply() }

    val deviceName: String
        get() {
            val maker = Build.MANUFACTURER.replaceFirstChar { it.uppercase() }
            return if (Build.MODEL.startsWith(maker, ignoreCase = true)) Build.MODEL else "$maker ${Build.MODEL}"
        }

    fun enable(server: String, key: String, wifiOnly: Boolean, onlyNew: Boolean, albumId: String?, albumName: String) {
        prefs.edit()
            .putBoolean(KEY_ENABLED, true)
            .putBoolean(KEY_UNAUTHORIZED, false)
            .putBoolean(KEY_UNREACHABLE, false)
            .putString(KEY_SERVER, server)
            .putBoolean(KEY_WIFI, wifiOnly)
            .apply()
        SecretStore.write(prefs, KEY_KEY, key)
        choose(albumId, albumName, onlyNew)
    }

    fun setAlbum(albumId: String?, albumName: String, onlyNew: Boolean) = choose(albumId, albumName, onlyNew)

    private fun choose(albumId: String?, albumName: String, onlyNew: Boolean) {
        prefs.edit().putString(KEY_ALBUM_ID, albumId).putString(KEY_ALBUM_NAME, albumName).apply()
        val album = findAlbum(albumId, albumName, albums())
        val inAlbum = album?.let(::assetsIn) ?: emptyList()
        store.forgetPending(inAlbum.map { it.id }.toSet())
        // "Everything" for this album, even if it was once chosen with "only new".
        if (onlyNew) store.addSkipped(inAlbum.map { it.id to it.createdMs }) else store.forgetSkipped(inAlbum.map { it.id })
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
        // Each album keeps the choice made for it when it was added.
        for (album in albums().filter { it.id in added }) {
            val inAlbum = assetsIn(album)
            if (onlyNew) {
                store.addSkipped(inAlbum.map { it.id to it.createdMs })
            } else {
                store.forgetSkipped(inAlbum.map { it.id })
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
                    MediaStore.MediaColumns.DATE_MODIFIED,
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
                        cursor.getLong(4) * 1000,
                    )
                }
            }
        }
        return out
    }

    /** Since Android 10 the photo's location is only in the file with this permission. */
    private fun mayReadLocation(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.Q ||
            context.checkSelfPermission(Manifest.permission.ACCESS_MEDIA_LOCATION) ==
            PackageManager.PERMISSION_GRANTED

    /** The file as the owner took it, with its location. Never the copy without it. */
    private fun open(uri: Uri): InputStream? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return context.contentResolver.openInputStream(uri)
        return try {
            context.contentResolver.openInputStream(MediaStore.setRequireOriginal(uri))
        } catch (_: SecurityException) {
            throw OriginalUnavailable()
        } catch (_: UnsupportedOperationException) {
            throw OriginalUnavailable()
        }
    }

    /**
     * The original's bytes, as setRequireOriginal gives them: the same the app hashes when it frees
     * up space. Its length is counted here, as MediaStore's size can be out of date or missing.
     */
    private fun sha256(uri: Uri): Hashed? {
        val digest = MessageDigest.getInstance("SHA-256")
        val stream = open(uri) ?: return null
        var size = 0L
        stream.use { input ->
            val buffer = ByteArray(BUFFER)
            while (true) {
                val read = input.read(buffer)
                if (read < 0) break
                digest.update(buffer, 0, read)
                size += read
            }
        }
        return Hashed(digest.digest().joinToString("") { "%02x".format(it) }, size)
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

    /** A connection with what every request to the upload address carries. */
    private fun uploadConnection(path: String, method: String, readTimeout: Int): HttpURLConnection {
        val connection = URL("$server/api/uploads$path").openConnection() as HttpURLConnection
        connection.requestMethod = method
        connection.connectTimeout = TIMEOUT_MS
        connection.readTimeout = readTimeout
        connection.setRequestProperty("X-Api-Key", key)
        connection.setRequestProperty("Tus-Resumable", "1.0.0")
        return connection
    }

    private fun metadata(asset: LocalAsset, hashed: Hashed) = encodeMetadata(
        listOf(
            "filename" to asset.name,
            "checksum" to hashed.checksum,
            "lastModified" to asset.createdMs.toString(),
        ),
    )

    /** Any answer at all shows the server can be reached. */
    private fun answered() = prefs.edit().putBoolean(KEY_UNREACHABLE, false).apply()

    /**
     * Sends the file, carrying on with an upload an earlier attempt began when it is still for the
     * same file. The server compares the checksum of all it got and refuses a damaged file.
     */
    private fun upload(asset: LocalAsset, hashed: Hashed, stopped: () -> Boolean): Outcome {
        return try {
            transfer(asset, hashed, stopped)
        } catch (cause: FileChanged) {
            Outcome.Unreadable(cause.message ?: "The file could not be read.")
        } catch (cause: java.io.IOException) {
            // No answer from the server; cleared by the next answer of any kind. The upload is kept,
            // so the next attempt goes on from what arrived.
            prefs.edit().putBoolean(KEY_UNREACHABLE, true).apply()
            Outcome.Retry(cause.message ?: "The connection was lost.")
        }
    }

    private fun transfer(asset: LocalAsset, hashed: Hashed, stopped: () -> Boolean): Outcome {
        var uploadId: String
        var offset: Long
        when (val resumed = resume(asset, hashed)) {
            is Resume.Stop -> return resumed.outcome
            is Resume.At -> {
                uploadId = resumed.uploadId
                offset = resumed.offset
            }
            Resume.Fresh -> {
                // A small file goes whole in the request that makes the upload, as before: there is
                // little to go on with if it is cut off.
                if (hashed.size <= CHUNK) return sendWhole(asset, hashed)
                when (val created = create(asset, hashed)) {
                    is Created.Stop -> return created.outcome
                    is Created.Made -> uploadId = created.uploadId
                }
                offset = 0
            }
        }
        var input = openAt(asset.uri, offset) ?: return Outcome.Retry("The file could not be read.")
        try {
            var stalled = 0
            while (true) {
                if (stopped()) return Outcome.Paused
                val length = minOf(CHUNK, hashed.size - offset)
                val answer = patch(uploadId, input, offset, length)
                val status = answer.status
                val reached = answer.offset
                if (status == 409) {
                    // The server has a different amount than this phone thought: ask, and go on from there.
                    val head = head(uploadId)
                    if (head.status != 200 && head.status != 204) return endedBy(asset, head.status)
                    val now = head.offset ?: return Outcome.Retry("The server did not say how much it has.")
                    if (now >= hashed.size || now < 0) {
                        dropUpload(asset.id, uploadId)
                        return Outcome.Retry("The upload could not be finished; it starts again.")
                    }
                    if (++stalled > MAX_STALLS) return Outcome.Retry("The server did not take the rest of the file.")
                    input.close()
                    input = openAt(asset.uri, now) ?: return Outcome.Retry("The file could not be read.")
                    offset = now
                    continue
                }
                if (status != 204 && status != 200) return endedBy(asset, status)
                if (reached == null || reached < offset || reached > hashed.size) {
                    return Outcome.Retry("The server did not say how much it received.")
                }
                // The last part is answered only once the server has checked and kept the whole file.
                if (reached == hashed.size) {
                    store.forgetUpload(asset.id)
                    return Outcome.Verified
                }
                if (reached != offset + length) {
                    // Part of what was sent did not arrive: send it again from where the server got to.
                    if (reached == offset && ++stalled > MAX_STALLS) {
                        return Outcome.Retry("The server did not take the rest of the file.")
                    }
                    input.close()
                    input = openAt(asset.uri, reached) ?: return Outcome.Retry("The file could not be read.")
                }
                offset = reached
            }
        } finally {
            input.close()
        }
    }

    /** What an answer other than "received" means for the upload, and for the file. */
    private fun endedBy(asset: LocalAsset, status: Int): Outcome {
        if (status == 404 || status == 410) {
            // The server no longer has the upload, for example cleared as too old: the next
            // attempt starts a new one.
            store.forgetUpload(asset.id)
            return Outcome.Retry("The server no longer had the upload; it starts again.")
        }
        // Locked: another request, perhaps one cut off a moment ago, still holds the upload.
        if (status == 423) return Outcome.Retry("The server answered $status.")
        val outcome = outcomeOf(status)
        when (outcome) {
            // A damaged file is removed by the server, and anything else refused is not tried again.
            is Outcome.Rejected -> store.forgetUpload(asset.id)
            // A success here is not one: only the last part's answer says the file was kept.
            Outcome.Verified -> return Outcome.Retry("The server answered $status.")
            else -> {}
        }
        return outcome
    }

    /** Where an upload begun in an earlier attempt stands. */
    private sealed class Resume {
        data class At(val uploadId: String, val offset: Long) : Resume()
        object Fresh : Resume()
        data class Stop(val outcome: Outcome) : Resume()
    }

    private sealed class Created {
        data class Made(val uploadId: String) : Created()
        data class Stop(val outcome: Outcome) : Created()
    }

    private class Answer(val status: Int, val offset: Long?, val length: Long?)

    /**
     * Asks the server how much of an upload begun earlier it has. Only while the file is still the
     * one it was begun with: if it changed, the upload is dropped and a new one made.
     */
    private fun resume(asset: LocalAsset, hashed: Hashed): Resume {
        val started = store.startedUpload(asset.id) ?: return Resume.Fresh
        if (!started.isFor(hashed.checksum, hashed.size, asset.modifiedMs)) {
            dropUpload(asset.id, started.uploadId)
            return Resume.Fresh
        }
        val answer = head(started.uploadId)
        return when (val status = answer.status) {
            200, 204 -> {
                val offset = answer.offset
                if (offset != null && offset >= 0 && offset < hashed.size &&
                    (answer.length == null || answer.length == hashed.size)
                ) {
                    Resume.At(started.uploadId, offset)
                } else {
                    // All of it arrived but it was never kept (the server failed as it finished),
                    // or an answer that cannot be used: a new upload is the safe way.
                    dropUpload(asset.id, started.uploadId)
                    Resume.Fresh
                }
            }
            401, 403 -> Resume.Stop(Outcome.Unauthorized)
            408, 423, 429, in 500..599 -> Resume.Stop(Outcome.Retry("The server answered $status."))
            // 404 or 410: the upload is gone, kept too long or already finished. Anything else is
            // not an answer to go on from either.
            else -> {
                store.forgetUpload(asset.id)
                Resume.Fresh
            }
        }
    }

    private fun head(uploadId: String): Answer {
        val connection = uploadConnection("/$uploadId", "HEAD", TIMEOUT_MS)
        return try {
            val status = connection.responseCode
            answered()
            Answer(
                status,
                connection.getHeaderField("Upload-Offset")?.trim()?.toLongOrNull(),
                connection.getHeaderField("Upload-Length")?.trim()?.toLongOrNull(),
            )
        } finally {
            connection.disconnect()
        }
    }

    /**
     * Makes an upload with nothing in it yet, and keeps its id before the file is sent, so a
     * connection lost in the first part still leaves something to go on from.
     */
    private fun create(asset: LocalAsset, hashed: Hashed): Created {
        val connection = uploadConnection("", "POST", TIMEOUT_MS)
        return try {
            connection.doOutput = true
            connection.setFixedLengthStreamingMode(0L)
            connection.setRequestProperty("Upload-Length", hashed.size.toString())
            connection.setRequestProperty("Upload-Metadata", metadata(asset, hashed))
            connection.outputStream.close()
            val status = connection.responseCode
            answered()
            if (status != 201) {
                val outcome = outcomeOf(status)
                return Created.Stop(if (outcome == Outcome.Verified) Outcome.Retry("The server answered $status.") else outcome)
            }
            val uploadId = uploadIdFrom(connection.getHeaderField("Location"))
                ?: return Created.Stop(Outcome.Retry("The server gave no address for the upload."))
            store.saveUpload(asset.id, StartedUpload(uploadId, hashed.checksum, hashed.size, asset.modifiedMs))
            Created.Made(uploadId)
        } finally {
            connection.disconnect()
        }
    }

    /** One part of the file, streamed as it is read, so a large video never has to fit in memory. */
    private fun patch(uploadId: String, input: InputStream, offset: Long, length: Long): Answer {
        val connection = uploadConnection("/$uploadId", "PATCH", UPLOAD_TIMEOUT_MS)
        return try {
            connection.doOutput = true
            connection.setFixedLengthStreamingMode(length)
            connection.setRequestProperty("Upload-Offset", offset.toString())
            connection.setRequestProperty("Content-Type", "application/offset+octet-stream")
            connection.outputStream.use { copyExactly(input, it, length, BUFFER) }
            val status = connection.responseCode
            answered()
            Answer(status, connection.getHeaderField("Upload-Offset")?.trim()?.toLongOrNull(), null)
        } finally {
            connection.disconnect()
        }
    }

    /** The whole file in the request that makes the upload (tus creation-with-upload). */
    private fun sendWhole(asset: LocalAsset, hashed: Hashed): Outcome {
        val connection = uploadConnection("", "POST", UPLOAD_TIMEOUT_MS)
        return try {
            connection.doOutput = true
            // Streamed as it is read, so a large video never has to fit in memory.
            connection.setFixedLengthStreamingMode(hashed.size)
            connection.setRequestProperty("Upload-Length", hashed.size.toString())
            connection.setRequestProperty("Content-Type", "application/offset+octet-stream")
            connection.setRequestProperty("Upload-Metadata", metadata(asset, hashed))
            val source = open(asset.uri) ?: return Outcome.Retry("The file could not be read.")
            source.use { input -> connection.outputStream.use { copyExactly(input, it, hashed.size, BUFFER) } }
            val status = connection.responseCode
            answered()
            // Made, but not all of it arrived: the server cannot have kept it.
            val reached = connection.getHeaderField("Upload-Offset")?.trim()?.toLongOrNull()
            if (status == 201 && reached != null && reached != hashed.size) {
                return Outcome.Retry("The server did not receive the whole file.")
            }
            outcomeOf(status)
        } finally {
            connection.disconnect()
        }
    }

    /** The original, passed over up to [offset]. Null when it cannot be opened at all. */
    private fun openAt(uri: Uri, offset: Long): InputStream? {
        val input = open(uri) ?: return null
        try {
            skipExactly(input, offset)
        } catch (cause: Throwable) {
            input.close()
            throw cause
        }
        return input
    }

    /**
     * Forgets an upload that is no longer wanted, and asks the server to remove what it has of it.
     * That is only a courtesy: the server also clears old uploads by itself, so no answer is needed.
     */
    private fun dropUpload(assetId: String, uploadId: String) {
        store.forgetUpload(assetId)
        val connection = try {
            uploadConnection("/$uploadId", "DELETE", TIMEOUT_MS)
        } catch (_: java.io.IOException) {
            return
        }
        try {
            connection.responseCode
        } catch (_: java.io.IOException) {
            // Left for the server to clear.
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
            checkInIfDue()
        }
    }

    /**
     * Tells the server how this phone's backup is doing, at most once an hour, also when there is
     * nothing to send: a phone that stops doing so is the one its owner is warned about. The
     * checksums of what is safe are given by the app when it is open; this keeps them as they are.
     */
    private fun checkInIfDue() {
        val server = server ?: return
        val key = key ?: return
        if (!enabled || unauthorized) return
        val now = System.currentTimeMillis()
        if (now - prefs.getLong(KEY_LAST_REPORT, 0) < REPORT_EVERY_MS) return
        val counts = store.counts()
        val version = try {
            context.packageManager.getPackageInfo(context.packageName, 0).versionName ?: ""
        } catch (_: Exception) {
            ""
        }
        val body = JSONObject()
            .put("name", deviceName)
            .put("platform", "android")
            .put("appVersion", version)
            .put("pending", counts[BackupStatus.PENDING] ?: 0)
            .put("working", counts[BackupStatus.UPLOADING] ?: 0)
            .put("verified", counts[BackupStatus.VERIFIED] ?: 0)
            .put("failed", counts[BackupStatus.FAILED] ?: 0)
        val connection = URL("$server/api/me/backup-devices/$deviceId").openConnection() as HttpURLConnection
        try {
            connection.requestMethod = "PUT"
            connection.doOutput = true
            connection.connectTimeout = TIMEOUT_MS
            connection.readTimeout = TIMEOUT_MS
            connection.setRequestProperty("X-Api-Key", key)
            connection.setRequestProperty("Content-Type", "application/json")
            connection.outputStream.use { it.write(body.toString().toByteArray()) }
            if (connection.responseCode == 200) prefs.edit().putLong(KEY_LAST_REPORT, now).apply()
        } catch (_: java.io.IOException) {
            // The next run tries again.
        } finally {
            connection.disconnect()
        }
    }

    private fun send(progress: (sent: Int) -> Unit, stopped: () -> Boolean): Boolean {
        if (!enabled || server == null || key == null) return true
        // The key was refused: nothing is read or sent until the app turns backup on again.
        if (unauthorized) return true
        // Without it only copies without the location could be read. Shown in status().
        if (!mayReadLocation()) return true
        store.recoverInterrupted()
        store.retryFailedAutomatically()
        val assets = assetsToSend().associateBy { it.id }
        if (assets.isEmpty() && currentAlbum() == null && moreAlbums.isEmpty()) return true
        // A photo edited in place since it was sent is no longer what the server has.
        store.resendChanged(assets.values.associate { it.id to (it.size to it.modifiedMs) })
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
            val hashed = try {
                sha256(asset.uri)
            } catch (cause: java.io.IOException) {
                store.recordFailure(item.assetId, cause.message ?: "The file could not be read.", MAX_ATTEMPTS)
                continue
            } catch (_: OriginalUnavailable) {
                store.markWaiting(item.assetId, WAITING_FOR_LOCATION, System.currentTimeMillis() + WAIT_MS)
                continue
            }
            if (hashed == null) {
                store.recordFailure(item.assetId, "The file could not be read.", MAX_ATTEMPTS)
                continue
            }
            store.setUploading(item.assetId, hashed.checksum)
            if (serverHasFile(hashed.checksum)) {
                store.markVerified(item.assetId, asset.size, asset.modifiedMs)
                continue
            }
            val outcome = try {
                upload(asset, hashed, stopped)
            } catch (_: OriginalUnavailable) {
                store.markWaiting(item.assetId, WAITING_FOR_LOCATION, System.currentTimeMillis() + WAIT_MS)
                continue
            }
            when (outcome) {
                Outcome.Verified -> {
                    store.markVerified(item.assetId, asset.size, asset.modifiedMs)
                    sent += 1
                    progress(sent)
                }
                is Outcome.Retry -> {
                    store.recordFailure(item.assetId, outcome.reason, MAX_ATTEMPTS)
                    return false
                }
                is Outcome.Rejected -> store.recordFailure(item.assetId, outcome.reason, 1)
                is Outcome.Unreadable -> store.recordFailure(item.assetId, outcome.reason, MAX_ATTEMPTS)
                // Left uploading, which the next run puts back in the queue, with its upload kept.
                Outcome.Paused -> return false
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
            // Also when the stored key can no longer be decrypted: turning backup on again fixes both.
            "unauthorized" to (unauthorized || (enabled && key == null)),
            // Nothing is sent until the app is allowed to read where photos were taken.
            "waitingForMediaLocation" to (enabled && !mayReadLocation()),
            "pending" to (counts[BackupStatus.PENDING] ?: 0),
            "working" to (counts[BackupStatus.UPLOADING] ?: 0),
            "verified" to (counts[BackupStatus.VERIFIED] ?: 0),
            "failed" to (counts[BackupStatus.FAILED] ?: 0),
            "serverUnreachable" to (enabled && prefs.getBoolean(KEY_UNREACHABLE, false)),
            // Android waits for Wi-Fi through WorkManager's network rule, not per file.
            "waitingForWifi" to 0,
            "retrying" to store.retryingCount(),
            "lastFinished" to store.lastFinished()?.let { it / 1000.0 },
            "failures" to store.failures(FAILURES_SHOWN),
            "albumName" to (album?.title ?: albumName ?: ""),
            "albumFound" to (album != null || moreAlbums.isNotEmpty()),
            "moreAlbums" to moreAlbums.toList(),
            "excludedAlbums" to excludedAlbums.toList(),
            "limitedAccess" to false,
            "deviceId" to deviceId,
            "deviceName" to deviceName,
        )
    }

    companion object {
        private val running = AtomicBoolean(false)
        const val MAX_ATTEMPTS = 5
        const val WAITING_FOR_LOCATION =
            "Waiting for permission to read where photos were taken, so the original is sent with its location."
        private const val WAIT_MS = 60 * 60_000L
        private const val FAILURES_SHOWN = 5
        private const val BUFFER = 1024 * 1024
        /** How much one request sends. A connection lost costs at most this much again. */
        private const val CHUNK = 8L * 1024 * 1024
        /** How often the server may take nothing of a part before the attempt counts as failed. */
        private const val MAX_STALLS = 3
        private const val TIMEOUT_MS = 20_000
        private const val UPLOAD_TIMEOUT_MS = 10 * 60_000
        private const val WORK_ONCE = "mediarr-backup-once"
        private const val WORK_PERIODIC = "mediarr-backup-periodic"
        private const val KEY_ENABLED = "enabled"
        private const val KEY_UNAUTHORIZED = "unauthorized"
        private const val KEY_UNREACHABLE = "unreachable"
        private const val KEY_SERVER = "server"
        private const val KEY_KEY = "key"
        private const val KEY_WIFI = "wifiOnly"
        private const val KEY_CHARGING = "chargingOnly"
        private const val KEY_ALBUM_ID = "albumId"
        private const val KEY_ALBUM_NAME = "albumName"
        private const val KEY_MORE_ALBUMS = "moreAlbums"
        private const val KEY_EXCLUDED_ALBUMS = "excludedAlbums"
        private const val KEY_DEVICE_ID = "deviceId"
        private const val KEY_LAST_REPORT = "lastReport"
        private const val REPORT_EVERY_MS = 60 * 60_000L
    }
}

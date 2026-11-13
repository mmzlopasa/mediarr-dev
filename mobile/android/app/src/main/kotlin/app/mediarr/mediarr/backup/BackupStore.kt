package app.mediarr.mediarr.backup

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

object BackupStatus {
    const val PENDING = "pending"
    const val UPLOADING = "uploading"
    const val VERIFIED = "verified"
    const val FAILED = "failed"

    /** Was already in the album when backup started with "only new". Never sent. */
    const val SKIPPED = "skipped"
}

data class BackupItem(val assetId: String, val attempts: Int)

/** The wait before a file that failed is tried again: 1, 4, 16, 64 minutes, at most 6 hours. */
fun backoffMs(attempts: Int): Long {
    var wait = 60_000L
    repeat((attempts - 1).coerceIn(0, 6)) { wait *= 4 }
    return wait.coerceAtMost(6 * 60 * 60_000L)
}

/** What happened to each file, so that the same one is never sent twice. */
class BackupStore(context: Context) :
    SQLiteOpenHelper(context.applicationContext, "backup.sqlite", null, 2) {

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            """
            CREATE TABLE items (
              asset_id TEXT PRIMARY KEY,
              status TEXT NOT NULL,
              attempts INTEGER NOT NULL DEFAULT 0,
              created INTEGER NOT NULL,
              error TEXT,
              checksum TEXT,
              finished INTEGER,
              retry_after INTEGER
            )
            """.trimIndent(),
        )
        db.execSQL("CREATE INDEX items_status ON items (status, created DESC)")
    }

    /** Version 2: when a waiting file may be tried again, or a failed one tried anew. Null is now. */
    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        if (oldVersion < 2) db.execSQL("ALTER TABLE items ADD COLUMN retry_after INTEGER")
    }

    private fun insert(id: String, created: Long, status: String) {
        writableDatabase.insertWithOnConflict(
            "items",
            null,
            ContentValues().apply {
                put("asset_id", id)
                put("status", status)
                put("created", created)
            },
            SQLiteDatabase.CONFLICT_IGNORE,
        )
    }

    fun add(assets: List<Pair<String, Long>>) = transaction {
        assets.forEach { (id, created) -> insert(id, created, BackupStatus.PENDING) }
    }

    fun addSkipped(assets: List<Pair<String, Long>>) = transaction {
        assets.forEach { (id, created) -> insert(id, created, BackupStatus.SKIPPED) }
    }

    /** The user chose "everything" for these files after all, so they are no longer kept back. */
    fun forgetSkipped(ids: List<String>) = transaction {
        val db = writableDatabase
        ids.forEach { db.delete("items", "asset_id = ? AND status = ?", arrayOf(it, BackupStatus.SKIPPED)) }
    }

    /** Switching album drops what the old one had queued. What was already sent stays known. */
    fun forgetPending(keep: Set<String>) = transaction {
        val db = writableDatabase
        val gone = ids("status = ?", arrayOf(BackupStatus.PENDING)).filterNot(keep::contains)
        gone.forEach { db.delete("items", "asset_id = ?", arrayOf(it)) }
    }

    fun forgetUnfinished() {
        writableDatabase.delete(
            "items",
            "status IN (?, ?)",
            arrayOf(BackupStatus.PENDING, BackupStatus.UPLOADING),
        )
    }

    private fun ids(where: String, args: Array<String>): List<String> =
        readableDatabase.query("items", arrayOf("asset_id"), where, args, null, null, null).use {
            buildList { while (it.moveToNext()) add(it.getString(0)) }
        }

    /** The newest file waiting, except those still waiting out a failure. */
    fun nextPending(now: Long = System.currentTimeMillis()): BackupItem? =
        readableDatabase.query(
            "items",
            arrayOf("asset_id", "attempts"),
            "status = ? AND (retry_after IS NULL OR retry_after <= ?)",
            arrayOf(BackupStatus.PENDING, now.toString()),
            null,
            null,
            "created DESC",
            "1",
        ).use { if (it.moveToFirst()) BackupItem(it.getString(0), it.getInt(1)) else null }

    fun setUploading(id: String, checksum: String) {
        writableDatabase.update(
            "items",
            ContentValues().apply {
                put("status", BackupStatus.UPLOADING)
                put("checksum", checksum)
                putNull("retry_after")
            },
            "asset_id = ?",
            arrayOf(id),
        )
    }

    fun markVerified(id: String, now: Long = System.currentTimeMillis()) {
        writableDatabase.update(
            "items",
            ContentValues().apply {
                put("status", BackupStatus.VERIFIED)
                putNull("error")
                put("finished", now)
            },
            "asset_id = ?",
            arrayOf(id),
        )
    }

    /**
     * Records a failed attempt. It stays in the queue, after a wait that grows with every attempt,
     * until it has used up its attempts. A failed file is tried again by itself after a day.
     */
    fun recordFailure(id: String, error: String, limit: Int, now: Long = System.currentTimeMillis()) {
        val attempts = readableDatabase.query(
            "items", arrayOf("attempts"), "asset_id = ?", arrayOf(id), null, null, null,
        ).use { if (it.moveToFirst()) it.getInt(0) + 1 else 1 }
        val failed = attempts >= limit
        writableDatabase.update(
            "items",
            ContentValues().apply {
                put("attempts", attempts)
                put("error", error)
                put("status", if (failed) BackupStatus.FAILED else BackupStatus.PENDING)
                put("retry_after", now + if (failed) FAILED_RETRY_MS else backoffMs(attempts))
            },
            "asset_id = ?",
            arrayOf(id),
        )
    }

    /** Not the file's fault and not counted: it waits, with the reason shown, and is tried later. */
    fun markWaiting(id: String, reason: String, until: Long) {
        writableDatabase.update(
            "items",
            ContentValues().apply {
                put("status", BackupStatus.PENDING)
                put("error", reason)
                put("retry_after", until)
            },
            "asset_id = ?",
            arrayOf(id),
        )
    }

    /** How many files wait out a failure (or a missing permission) before they are tried again. */
    fun retryingCount(now: Long = System.currentTimeMillis()): Int =
        readableDatabase.rawQuery(
            "SELECT count(*) FROM items WHERE status = ? AND error IS NOT NULL AND retry_after > ?",
            arrayOf(BackupStatus.PENDING, now.toString()),
        ).use { if (it.moveToFirst()) it.getInt(0) else 0 }

    /** Failed files whose wait is over get a fresh set of attempts. Older ones are tried at once. */
    fun retryFailedAutomatically(now: Long = System.currentTimeMillis()) {
        writableDatabase.update(
            "items",
            ContentValues().apply {
                put("status", BackupStatus.PENDING)
                put("attempts", 0)
                putNull("error")
                putNull("retry_after")
            },
            "status = ? AND (retry_after IS NULL OR retry_after <= ?)",
            arrayOf(BackupStatus.FAILED, now.toString()),
        )
    }

    /** A file left uploading by a process that was killed goes back in the queue. */
    fun recoverInterrupted() {
        writableDatabase.update(
            "items",
            ContentValues().apply { put("status", BackupStatus.PENDING) },
            "status = ?",
            arrayOf(BackupStatus.UPLOADING),
        )
    }

    /** The user asked: every failed file, and every file still waiting, goes now. */
    fun retryFailed() {
        writableDatabase.update(
            "items",
            ContentValues().apply { putNull("retry_after") },
            "status = ?",
            arrayOf(BackupStatus.PENDING),
        )
        writableDatabase.update(
            "items",
            ContentValues().apply {
                put("status", BackupStatus.PENDING)
                put("attempts", 0)
                putNull("error")
                putNull("retry_after")
            },
            "status = ?",
            arrayOf(BackupStatus.FAILED),
        )
    }

    fun counts(): Map<String, Int> =
        readableDatabase.rawQuery("SELECT status, count(*) FROM items GROUP BY status", null).use {
            buildMap { while (it.moveToNext()) put(it.getString(0), it.getInt(1)) }
        }

    fun lastFinished(): Long? =
        readableDatabase.rawQuery("SELECT max(finished) FROM items", null).use {
            if (it.moveToFirst() && !it.isNull(0)) it.getLong(0) else null
        }

    fun statuses(ids: List<String>): Map<String, String> = buildMap {
        for (id in ids) {
            readableDatabase.query(
                "items", arrayOf("status"), "asset_id = ?", arrayOf(id), null, null, null,
            ).use {
                if (it.moveToFirst() && it.getString(0) != BackupStatus.SKIPPED) {
                    put(id, it.getString(0))
                }
            }
        }
    }

    fun verifiedChecksums(): Map<String, List<String>> =
        readableDatabase.query(
            "items",
            arrayOf("asset_id", "checksum"),
            "status = ? AND checksum IS NOT NULL",
            arrayOf(BackupStatus.VERIFIED),
            null,
            null,
            null,
        ).use {
            buildMap { while (it.moveToNext()) put(it.getString(0), listOf(it.getString(1))) }
        }

    fun waiting(limit: Int): List<Map<String, String>> =
        readableDatabase.query(
            "items",
            arrayOf("asset_id", "status"),
            "status NOT IN (?, ?)",
            arrayOf(BackupStatus.VERIFIED, BackupStatus.SKIPPED),
            null,
            null,
            "created DESC",
            limit.toString(),
        ).use {
            buildList {
                while (it.moveToNext()) add(mapOf("id" to it.getString(0), "status" to it.getString(1)))
            }
        }

    fun failures(limit: Int): List<Map<String, String>> =
        readableDatabase.query(
            "items",
            arrayOf("asset_id", "error"),
            "status = ?",
            arrayOf(BackupStatus.FAILED),
            null,
            null,
            "created DESC",
            limit.toString(),
        ).use {
            buildList {
                while (it.moveToNext()) add(mapOf("id" to it.getString(0), "error" to (it.getString(1) ?: "")))
            }
        }

    private fun transaction(block: () -> Unit) {
        val db = writableDatabase
        db.beginTransaction()
        try {
            block()
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
    }

    fun clear() {
        writableDatabase.delete("items", null, null)
    }

    private companion object {
        const val FAILED_RETRY_MS = 24 * 60 * 60_000L
    }
}

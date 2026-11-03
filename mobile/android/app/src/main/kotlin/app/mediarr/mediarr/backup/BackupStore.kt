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

/** What happened to each file, so that the same one is never sent twice. */
class BackupStore(context: Context) :
    SQLiteOpenHelper(context.applicationContext, "backup.sqlite", null, 1) {

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
              finished INTEGER
            )
            """.trimIndent(),
        )
        db.execSQL("CREATE INDEX items_status ON items (status, created DESC)")
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) = Unit

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

    fun nextPending(): BackupItem? =
        readableDatabase.query(
            "items",
            arrayOf("asset_id", "attempts"),
            "status = ?",
            arrayOf(BackupStatus.PENDING),
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

    /** Records a failed attempt. It stays in the queue until it has used up its attempts. */
    fun recordFailure(id: String, error: String, limit: Int) {
        val attempts = readableDatabase.query(
            "items", arrayOf("attempts"), "asset_id = ?", arrayOf(id), null, null, null,
        ).use { if (it.moveToFirst()) it.getInt(0) + 1 else 1 }
        writableDatabase.update(
            "items",
            ContentValues().apply {
                put("attempts", attempts)
                put("error", error)
                put("status", if (attempts >= limit) BackupStatus.FAILED else BackupStatus.PENDING)
            },
            "asset_id = ?",
            arrayOf(id),
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

    fun retryFailed() {
        writableDatabase.update(
            "items",
            ContentValues().apply {
                put("status", BackupStatus.PENDING)
                put("attempts", 0)
                putNull("error")
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
}

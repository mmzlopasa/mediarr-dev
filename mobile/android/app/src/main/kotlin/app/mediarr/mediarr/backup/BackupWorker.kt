package app.mediarr.mediarr.backup

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.ServiceInfo
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.work.CoroutineWorker
import androidx.work.ForegroundInfo
import androidx.work.WorkerParameters
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/** Sends photos with the app closed. The notification keeps Android from stopping a long upload. */
class BackupWorker(context: Context, parameters: WorkerParameters) :
    CoroutineWorker(context, parameters) {

    private fun foreground(text: String): ForegroundInfo {
        val manager = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL, "Backup", NotificationManager.IMPORTANCE_LOW),
            )
        }
        val notification = NotificationCompat.Builder(applicationContext, CHANNEL)
            .setSmallIcon(android.R.drawable.stat_sys_upload)
            .setContentTitle("Mediarr backup")
            .setContentText(text)
            .setOngoing(true)
            .build()
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ForegroundInfo(NOTIFICATION, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            ForegroundInfo(NOTIFICATION, notification)
        }
    }

    override suspend fun getForegroundInfo(): ForegroundInfo = foreground("Looking for new photos")

    override suspend fun doWork(): Result {
        try {
            setForeground(foreground("Looking for new photos"))
        } catch (_: IllegalStateException) {
            // Android does not allow it from the background right now. The work still runs.
        }
        val engine = BackupEngine(applicationContext)
        val finished = withContext(Dispatchers.IO) {
            engine.work(progress = {}, stopped = { isStopped })
        }
        return if (finished) Result.success() else Result.retry()
    }

    private companion object {
        const val CHANNEL = "mediarr_backup"
        const val NOTIFICATION = 1001
    }
}

package ir.lpad.mobile

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * Keeps the running task visible on the lock screen.
 *
 * The notification is built with `setUsesChronometer` + `setWhen`, so Android
 * ticks the elapsed time itself from the entry's start timestamp. No Dart code
 * has to run while the phone is locked, and the clock stays accurate even if
 * the Flutter isolate is suspended. Running as a foreground service is what
 * keeps it alive through Doze and OEM task-killers.
 */
class TimerService : Service() {

    companion object {
        const val EXTRA_TASK_NAME = "taskName"
        const val EXTRA_START_TIME = "startTimeMillis"
        const val EXTRA_CONTENT_TEXT = "contentText"
        const val EXTRA_CHANNEL_NAME = "channelName"

        private const val CHANNEL_ID = "launchpad_timer"
        private const val NOTIFICATION_ID = 1001
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // A null intent means Android restarted us after reclaiming the process
        // without anything to show. Do not linger as a zombie foreground service.
        val taskName = intent?.getStringExtra(EXTRA_TASK_NAME)
        if (taskName == null) {
            stopSelf()
            return START_NOT_STICKY
        }

        val startTimeMillis =
            intent.getLongExtra(EXTRA_START_TIME, System.currentTimeMillis())
        val contentText = intent.getStringExtra(EXTRA_CONTENT_TEXT)
        val channelName = intent.getStringExtra(EXTRA_CHANNEL_NAME) ?: "Launchpad"

        ensureChannel(channelName)
        startForeground(
            NOTIFICATION_ID,
            buildNotification(taskName, contentText, startTimeMillis),
        )
        return START_STICKY
    }

    /** Idempotent: re-creating a channel with the same id only refreshes its name. */
    private fun ensureChannel(channelName: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            channelName,
            // LOW keeps it silent and out of the way while still showing on the
            // lock screen.
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            setShowBadge(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }

        val manager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(
        taskName: String,
        contentText: String?,
        startTimeMillis: Long,
    ): Notification {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_timer)
            .setContentTitle(taskName)
            .setContentText(contentText)
            .setWhen(startTimeMillis)
            .setShowWhen(true)
            .setUsesChronometer(true)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_STOPWATCH)
            // Show the task name on the lock screen even when the user has
            // notification content hidden by default.
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(pendingIntent)
            .build()
    }
}

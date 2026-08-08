package ir.lpad.mobile

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "ir.lpad.mobile/timer_service"
        private const val NOTIFICATION_PERMISSION_REQUEST = 1002
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        startTimerService(call)
                        result.success(null)
                    }
                    "stop" -> {
                        // Destroying the service also removes its foreground
                        // notification, and stopService is not subject to the
                        // background start restrictions of startForegroundService.
                        stopService(Intent(this, TimerService::class.java))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startTimerService(call: MethodCall) {
        ensureNotificationPermission()

        val intent = Intent(this, TimerService::class.java).apply {
            putExtra(TimerService.EXTRA_TASK_NAME, call.argument<String>("taskName"))
            putExtra(
                TimerService.EXTRA_START_TIME,
                call.argument<Number>("startTimeMillis")?.toLong()
                    ?: System.currentTimeMillis(),
            )
            putExtra(
                TimerService.EXTRA_CONTENT_TEXT,
                call.argument<String>("contentText"),
            )
            putExtra(
                TimerService.EXTRA_CHANNEL_NAME,
                call.argument<String>("channelName"),
            )
        }
        ContextCompat.startForegroundService(this, intent)
    }

    /**
     * Asked the first time a task is started rather than at cold launch, so the
     * prompt arrives with context. The service runs either way; without the
     * grant the notification simply stays hidden until the user allows it.
     */
    private fun ensureNotificationPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return

        val granted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.POST_NOTIFICATIONS,
        ) == PackageManager.PERMISSION_GRANTED

        if (!granted) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                NOTIFICATION_PERMISSION_REQUEST,
            )
        }
    }
}

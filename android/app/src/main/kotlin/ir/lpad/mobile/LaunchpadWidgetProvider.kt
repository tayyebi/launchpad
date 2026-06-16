package ir.lpad.mobile

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Base64
import android.widget.RemoteViews

class LaunchpadWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val gridBase64 = prefs.getString("launchpad_grid", null)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.launchpad_widget_layout)

            if (!gridBase64.isNullOrEmpty()) {
                try {
                    val imageBytes = Base64.decode(gridBase64, Base64.DEFAULT)
                    val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)

                    if (bitmap != null) {
                        views.setImageViewBitmap(R.id.widget_grid, bitmap)
                    }
                } catch (_: Exception) {
                    views.setImageViewBitmap(R.id.widget_grid, createFallbackBitmap(context))
                }
            } else {
                views.setImageViewBitmap(R.id.widget_grid, createFallbackBitmap(context))
            }

            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_grid, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun createFallbackBitmap(context: Context): Bitmap {
        val bmp = Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
        bmp.eraseColor(android.graphics.Color.TRANSPARENT)
        return bmp
    }
}

package com.launchpad.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Base64
import android.widget.RemoteViews
import org.json.JSONArray

class LaunchpadWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

        val tasksJson = prefs.getString("launchpad_tasks", null)
        val tilesJson = prefs.getString("launchpad_tiles", null)

        val cellIds = listOf(
            R.id.cell_1, R.id.cell_2, R.id.cell_3,
            R.id.cell_4, R.id.cell_5, R.id.cell_6,
            R.id.cell_7, R.id.cell_8, R.id.cell_9
        )

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.launchpad_widget_layout)

            for (i in 0 until 9) {
                views.setViewVisibility(cellIds[i], android.view.View.GONE)
            }

            val tasks = if (!tasksJson.isNullOrEmpty()) {
                try {
                    JSONArray(tasksJson)
                } catch (_: Exception) {
                    null
                }
            } else null

            if (!tilesJson.isNullOrEmpty()) {
                try {
                    val tiles = JSONArray(tilesJson)

                    for (i in 0 until minOf(tiles.length(), 9)) {
                        val base64Str = tiles.optString(i, "")
                        if (base64Str.isEmpty()) continue

                        val imageBytes = Base64.decode(base64Str, Base64.DEFAULT)
                        val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)

                        if (bitmap != null) {
                            views.setViewVisibility(cellIds[i], android.view.View.VISIBLE)
                            views.setImageViewBitmap(cellIds[i], bitmap)
                        }

                        if (tasks != null && i < tasks.length()) {
                            val task = tasks.getJSONObject(i)
                            val name = task.optString("name", "")
                            if (name.isNotEmpty()) {
                                val intent = Intent(context, MainActivity::class.java).apply {
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                                    putExtra("task_name", name)
                                }
                                val pendingIntent = PendingIntent.getActivity(
                                    context, i, intent,
                                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                                )
                                views.setOnClickPendingIntent(cellIds[i], pendingIntent)
                            }
                        }
                    }
                } catch (_: Exception) {
                    views.setViewVisibility(cellIds[0], android.view.View.VISIBLE)
                    val errBitmap = Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
                    errBitmap.eraseColor(android.graphics.Color.parseColor("#FF4444"))
                    views.setImageViewBitmap(cellIds[0], errBitmap)
                }
            } else {
                views.setViewVisibility(cellIds[0], android.view.View.VISIBLE)
                val emptyBitmap = Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
                emptyBitmap.eraseColor(android.graphics.Color.parseColor("#1AFFFFFF"))
                views.setImageViewBitmap(cellIds[0], emptyBitmap)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

package com.launchpad.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
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

        val cellIds = listOf(
            R.id.cell_1, R.id.cell_2, R.id.cell_3,
            R.id.cell_4, R.id.cell_5, R.id.cell_6,
            R.id.cell_7, R.id.cell_8, R.id.cell_9
        )

        val nameIds = listOf(
            R.id.name_1, R.id.name_2, R.id.name_3,
            R.id.name_4, R.id.name_5, R.id.name_6,
            R.id.name_7, R.id.name_8, R.id.name_9
        )

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.launchpad_widget_layout)

            for (i in 0 until 9) {
                views.setViewVisibility(cellIds[i], android.view.View.GONE)
            }

            if (!tasksJson.isNullOrEmpty()) {
                try {
                    val tasks = JSONArray(tasksJson)
                    views.setTextViewText(R.id.widget_title, "Launchpad")

                    val count = minOf(tasks.length(), 9)
                    for (i in 0 until count) {
                        val task = tasks.getJSONObject(i)
                        val name = task.getString("name")
                        val colorInt = task.getInt("color")
                        val taskId = task.getString("id")
                        val isActive = task.optBoolean("isActive", false)

                        views.setViewVisibility(cellIds[i], android.view.View.VISIBLE)
                        views.setTextViewText(nameIds[i], name)

                        val bgColor = if (isActive) {
                            lightenColor(colorInt, 0.3f)
                        } else {
                            darkenColor(colorInt, 0.4f)
                        }
                        views.setInt(cellIds[i], "setBackgroundColor", bgColor)

                        views.setTextColor(nameIds[i], Color.WHITE)

                        val intent = Intent(context, MainActivity::class.java).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                            putExtra("task_id", taskId)
                        }
                        val pendingIntent = PendingIntent.getActivity(
                            context, i, intent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        views.setOnClickPendingIntent(cellIds[i], pendingIntent)
                    }
                } catch (_: Exception) {
                    views.setTextViewText(R.id.widget_title, "Error")
                }
            } else {
                views.setTextViewText(R.id.widget_title, "No tasks")
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun lightenColor(color: Int, factor: Float): Int {
        val r = (Color.red(color) * (1 + factor) + 255 * factor).toInt().coerceIn(0, 255)
        val g = (Color.green(color) * (1 + factor) + 255 * factor).toInt().coerceIn(0, 255)
        val b = (Color.blue(color) * (1 + factor) + 255 * factor).toInt().coerceIn(0, 255)
        return Color.rgb(r, g, b)
    }

    private fun darkenColor(color: Int, factor: Float): Int {
        val r = (Color.red(color) * (1 - factor)).toInt().coerceIn(0, 255)
        val g = (Color.green(color) * (1 - factor)).toInt().coerceIn(0, 255)
        val b = (Color.blue(color) * (1 - factor)).toInt().coerceIn(0, 255)
        return Color.rgb(r, g, b)
    }
}

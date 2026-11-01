package com.deeneralo.deener_alo

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class PrayerListWidgetProvider : HomeWidgetProvider() {

    private val rows = listOf(
        Triple("fajr", R.id.box_fajr, R.id.time_fajr),
        Triple("dhuhr", R.id.box_dhuhr, R.id.time_dhuhr),
        Triple("asr", R.id.box_asr, R.id.time_asr),
        Triple("maghrib", R.id.box_maghrib, R.id.time_maghrib),
        Triple("isha", R.id.box_isha, R.id.time_isha)
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val schedule = WidgetSchedule.load(widgetData)
        val now = System.currentTimeMillis()
        val day = schedule?.dayAt(now)
        val currentKey = schedule?.currentPrayer(now)?.key

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_prayer_list).apply {
                setTextViewText(R.id.widget_list_city, schedule?.city ?: "")

                rows.forEach { (key, boxId, timeId) ->
                    val prayer = day?.prayers?.firstOrNull { it.key == key }
                    setTextViewText(timeId, prayer?.text ?: "--:--")
                    // Highlight the active waqt.
                    setInt(
                        boxId, "setBackgroundResource",
                        if (key == currentKey) R.drawable.widget_pill_active else 0
                    )
                }

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_list_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
        WidgetSchedule.scheduleNextRefresh(context, schedule)
    }
}

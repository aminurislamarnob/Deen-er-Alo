package com.deeneralo.deener_alo

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class PrayerListWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_prayer_list).apply {
                val city = widgetData.getString("list_city", "ঢাকা")
                val fajr = widgetData.getString("list_fajr", "০৪:৫৫")
                val dhuhr = widgetData.getString("list_dhuhr", "১১:৪৫")
                val asr = widgetData.getString("list_asr", "০৩:৪৫")
                val maghrib = widgetData.getString("list_maghrib", "০৫:১৮")
                val isha = widgetData.getString("list_isha", "০৬:৩৫")

                setTextViewText(R.id.widget_list_city, city)
                setTextViewText(R.id.time_fajr, fajr)
                setTextViewText(R.id.time_dhuhr, dhuhr)
                setTextViewText(R.id.time_asr, asr)
                setTextViewText(R.id.time_maghrib, maghrib)
                setTextViewText(R.id.time_isha, isha)

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_list_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

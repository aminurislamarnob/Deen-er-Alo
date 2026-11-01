package com.deeneralo.deener_alo

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class SaomTimerWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_saom_timer).apply {
                val location = widgetData.getString("saom_location", "ঢাকা")
                val sehri = widgetData.getString("saom_sehri", "০৪:৫৫ AM")
                val iftar = widgetData.getString("saom_iftar", "০৫:১৮ PM")
                val countdown = widgetData.getString("saom_countdown", "রোজা পালনের প্রস্তুতি নিন")

                setTextViewText(R.id.widget_saom_location, location)
                setTextViewText(R.id.widget_sehri_time, sehri)
                setTextViewText(R.id.widget_iftar_time, iftar)
                setTextViewText(R.id.widget_saom_countdown, countdown)

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_saom_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

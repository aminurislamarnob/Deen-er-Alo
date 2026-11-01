package com.deeneralo.deener_alo

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class DaySummaryWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_day_summary).apply {
                val hijri = widgetData.getString("summary_hijri", "দ্বীনের আলো")
                val location = widgetData.getString("summary_location", "ঢাকা")
                val currentWaqt = widgetData.getString("summary_current_waqt", "ওয়াক্ত চলমান")
                val nextWaqt = widgetData.getString("summary_next_waqt", "পরবর্তী ওয়াক্ত লোড হচ্ছে...")
                val countdown = widgetData.getString("summary_countdown", "পরবর্তী ওয়াক্তের অপেক্ষা")

                setTextViewText(R.id.widget_summary_hijri, hijri)
                setTextViewText(R.id.widget_summary_location, location)
                setTextViewText(R.id.widget_summary_current_waqt, currentWaqt)
                setTextViewText(R.id.widget_summary_next_waqt, nextWaqt)
                setTextViewText(R.id.widget_summary_countdown, countdown)

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_summary_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

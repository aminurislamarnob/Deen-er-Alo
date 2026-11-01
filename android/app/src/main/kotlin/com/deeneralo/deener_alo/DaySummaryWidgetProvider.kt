package com.deeneralo.deener_alo

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
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
        val schedule = WidgetSchedule.load(widgetData)
        val now = System.currentTimeMillis()

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_day_summary).apply {
                val day = schedule?.dayAt(now)
                val current = schedule?.currentPrayer(now)
                val next = schedule?.nextPrayer(now)

                setTextViewText(R.id.widget_summary_hijri, day?.hijri ?: "দ্বীনের আলো")
                setTextViewText(R.id.widget_summary_location, schedule?.city ?: "")
                setTextViewText(
                    R.id.widget_summary_current_waqt,
                    if (current != null) "বর্তমান ওয়াক্ত: ${current.name}" else "এখন কোনো ফরজ ওয়াক্ত নেই"
                )

                if (next != null) {
                    setTextViewText(R.id.widget_summary_next_waqt, "পরবর্তী: ${next.name} (${next.text})")
                    setTextViewText(R.id.widget_summary_countdown, "${next.name} বাকি:")
                    setViewVisibility(R.id.widget_summary_chrono, View.VISIBLE)
                    WidgetSchedule.setCountdown(this, R.id.widget_summary_chrono, next.start, now)
                } else {
                    setTextViewText(R.id.widget_summary_next_waqt, "সময়সূচি হালনাগাদ করতে অ্যাপ খুলুন")
                    setTextViewText(R.id.widget_summary_countdown, "অ্যাপ খুলুন")
                    setViewVisibility(R.id.widget_summary_chrono, View.GONE)
                }

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_summary_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
        WidgetSchedule.scheduleNextRefresh(context, schedule)
    }
}

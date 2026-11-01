package com.deeneralo.deener_alo

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
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
        val schedule = WidgetSchedule.load(widgetData)
        val now = System.currentTimeMillis()

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_saom_timer).apply {
                setTextViewText(R.id.widget_saom_location, schedule?.city ?: "")

                val event = schedule?.nextFastingEvent(now)
                if (event != null) {
                    val (isSehri, day) = event
                    // Show the sehri/iftar pair of the day the next event belongs to.
                    setTextViewText(R.id.widget_sehri_time, day.sehriText)
                    setTextViewText(R.id.widget_iftar_time, day.iftarText)
                    setTextViewText(
                        R.id.widget_saom_countdown,
                        if (isSehri) "সাহরির বাকি:" else "ইফতারের বাকি:"
                    )
                    setViewVisibility(R.id.widget_saom_chrono, View.VISIBLE)
                    WidgetSchedule.setCountdown(
                        this, R.id.widget_saom_chrono,
                        if (isSehri) day.sehri else day.iftar, now
                    )
                } else {
                    setTextViewText(R.id.widget_saom_countdown, "সময়সূচি হালনাগাদ করতে অ্যাপ খুলুন")
                    setViewVisibility(R.id.widget_saom_chrono, View.GONE)
                }

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_saom_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
        WidgetSchedule.scheduleNextRefresh(context, schedule)
    }
}

package com.deeneralo.deener_alo

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews
import org.json.JSONObject

/**
 * Multi-day prayer schedule written by Flutter (key `widget_schedule_v2`).
 *
 * All instants are epoch milliseconds, and all display strings are already
 * formatted on the selected city's wall clock, so the widgets never need to
 * know the city's time zone. Because several days are stored, widgets keep
 * rolling over correctly (current waqt, countdown, date) without the app.
 */
data class WidgetPrayer(val key: String, val name: String, val start: Long, val end: Long, val text: String)

data class WidgetDay(
    val start: Long,
    val end: Long,
    val hijri: String,
    val sehri: Long,
    val sehriText: String,
    val iftar: Long,
    val iftarText: String,
    val prayers: List<WidgetPrayer>
)

class WidgetSchedule(val city: String, val days: List<WidgetDay>) {

    /** The schedule day containing [now], or null when data has run out. */
    fun dayAt(now: Long): WidgetDay? = days.firstOrNull { now >= it.start && now < it.end }

    /** All prayers across days, chronological. */
    private val allPrayers: List<WidgetPrayer> by lazy { days.flatMap { it.prayers }.sortedBy { it.start } }

    fun currentPrayer(now: Long): WidgetPrayer? = allPrayers.lastOrNull { it.start <= now && now < it.end }

    fun nextPrayer(now: Long): WidgetPrayer? = allPrayers.firstOrNull { it.start > now }

    /** Next sehri/iftar event after [now]: Pair(isSehri, day). */
    fun nextFastingEvent(now: Long): Pair<Boolean, WidgetDay>? {
        for (day in days) {
            if (day.sehri > now) return Pair(true, day)
            if (day.iftar > now) return Pair(false, day)
        }
        return null
    }

    /** Next instant at which any widget's content changes. */
    fun nextBoundary(now: Long): Long? {
        val candidates = mutableListOf<Long>()
        for (day in days) {
            candidates.add(day.start); candidates.add(day.end)
            candidates.add(day.sehri); candidates.add(day.iftar)
            for (p in day.prayers) { candidates.add(p.start); candidates.add(p.end) }
        }
        return candidates.filter { it > now }.minOrNull()
    }

    companion object {
        const val KEY = "widget_schedule_v2"

        fun load(prefs: SharedPreferences): WidgetSchedule? {
            val raw = prefs.getString(KEY, null) ?: return null
            return try {
                val json = JSONObject(raw)
                val daysJson = json.getJSONArray("days")
                val days = (0 until daysJson.length()).map { i ->
                    val d = daysJson.getJSONObject(i)
                    val pj = d.getJSONArray("prayers")
                    WidgetDay(
                        start = d.getLong("start"),
                        end = d.getLong("end"),
                        hijri = d.optString("hijri", ""),
                        sehri = d.getLong("sehri"),
                        sehriText = d.optString("sehriText", ""),
                        iftar = d.getLong("iftar"),
                        iftarText = d.optString("iftarText", ""),
                        prayers = (0 until pj.length()).map { j ->
                            val p = pj.getJSONObject(j)
                            WidgetPrayer(
                                key = p.getString("key"),
                                name = p.getString("name"),
                                start = p.getLong("start"),
                                end = p.getLong("end"),
                                text = p.optString("text", "")
                            )
                        }
                    )
                }
                WidgetSchedule(json.optString("city", ""), days)
            } catch (e: Exception) {
                null
            }
        }

        /** Points a RemoteViews Chronometer at [targetMillis], counting down. */
        fun setCountdown(views: RemoteViews, chronoId: Int, targetMillis: Long, now: Long) {
            val base = SystemClock.elapsedRealtime() + (targetMillis - now)
            views.setChronometer(chronoId, base, null, true)
            views.setChronometerCountDown(chronoId, true)
        }

        /**
         * Schedules a one-shot refresh of all three widgets at the next schedule
         * boundary so the labels (current waqt, sehri/iftar) roll over on time.
         */
        fun scheduleNextRefresh(context: Context, schedule: WidgetSchedule?) {
            val now = System.currentTimeMillis()
            // Refresh at the next boundary, or in 6 hours if data has run out.
            val at = (schedule?.nextBoundary(now) ?: (now + 6 * 3600_000L)) + 1_000L
            val intent = Intent(context, WidgetRefreshReceiver::class.java)
            val pending = PendingIntent.getBroadcast(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val canExact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || am.canScheduleExactAlarms()
            try {
                if (canExact) {
                    am.setExactAndAllowWhileIdle(AlarmManager.RTC, at, pending)
                } else {
                    am.setAndAllowWhileIdle(AlarmManager.RTC, at, pending)
                }
            } catch (e: SecurityException) {
                am.set(AlarmManager.RTC, at, pending)
            }
        }

        /** Asks every widget provider to redraw. */
        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            listOf(
                SaomTimerWidgetProvider::class.java,
                DaySummaryWidgetProvider::class.java,
                PrayerListWidgetProvider::class.java
            ).forEach { cls ->
                val ids = manager.getAppWidgetIds(ComponentName(context, cls))
                if (ids.isNotEmpty()) {
                    val intent = Intent(context, cls).apply {
                        action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                    }
                    context.sendBroadcast(intent)
                }
            }
        }
    }
}

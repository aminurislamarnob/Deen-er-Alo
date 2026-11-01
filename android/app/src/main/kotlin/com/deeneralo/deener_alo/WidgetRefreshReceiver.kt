package com.deeneralo.deener_alo

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Fired by AlarmManager at the next prayer/sehri/iftar/day boundary, and on
 * boot / time / time-zone changes, to redraw all home screen widgets.
 */
class WidgetRefreshReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        WidgetSchedule.refreshAll(context)
    }
}

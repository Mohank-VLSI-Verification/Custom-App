package com.chief.shift_tracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class ShiftWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (widgetId in appWidgetIds) {
            val clockedIn = widgetData.getBoolean("clocked_in", false)
            val views = RemoteViews(context.packageName, R.layout.shift_widget).apply {
                setTextViewText(R.id.widget_status, widgetData.getString("status", "Clocked out"))
                setTextViewText(R.id.widget_today, widgetData.getString("today", "Today: 0h 0m"))
                setTextViewText(R.id.widget_button, widgetData.getString("action_label", "Punch In"))
                setInt(
                    R.id.widget_button,
                    "setBackgroundResource",
                    if (clockedIn) R.drawable.widget_btn_red else R.drawable.widget_btn_green
                )
                setOnClickPendingIntent(
                    R.id.widget_button,
                    HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("shiftwidget://toggle"))
                )
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

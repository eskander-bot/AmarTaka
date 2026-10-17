package com.meskander.amartaka
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class LedgerWidgetProvider: AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { update(context, manager, it) }
    }
    companion object {
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            manager.getAppWidgetIds(ComponentName(context, LedgerWidgetProvider::class.java)).forEach { update(context, manager, it) }
        }
        private fun update(context: Context, manager: AppWidgetManager, id: Int) {
            val prefs = context.getSharedPreferences("ledger_widget", Context.MODE_PRIVATE)
            val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
            val views = RemoteViews(context.packageName, R.layout.ledger_widget)
            val text = if (prefs.getBoolean("hidden", true)) "অ্যাপ খুলুন" else try {
                JSONObject(prefs.getString("totals", "{}") ?: "{}").optString(today, prefs.getString("zero", "৳ ০") ?: "৳ ০")
            } catch (_: Exception) { "অ্যাপ খুলুন" }
            views.setTextViewText(R.id.widget_title, "Amar Taka · ব্যয় · $today")
            views.setTextViewText(R.id.widget_amount, text)
            fun launch(action: String, code: Int): PendingIntent {
                val intent = Intent(context, MainActivity::class.java).putExtra("ledger_action", action)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                return PendingIntent.getActivity(context, code, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            }
            views.setOnClickPendingIntent(R.id.widget_root, launch("", 10))
            views.setOnClickPendingIntent(R.id.widget_income, launch("income", 11))
            views.setOnClickPendingIntent(R.id.widget_expense, launch("expense", 12))
            manager.updateAppWidget(id, views)
        }
    }
}

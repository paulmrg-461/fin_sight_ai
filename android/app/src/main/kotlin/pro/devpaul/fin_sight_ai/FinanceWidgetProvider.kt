package pro.devpaul.fin_sight_ai

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/** Home-screen widget that mirrors the latest dashboard summary. */
class FinanceWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val snapshot = WidgetStore.read(context)
        appWidgetIds.forEach { appWidgetId ->
            appWidgetManager.updateAppWidget(appWidgetId, buildViews(context, snapshot))
        }
    }

    private fun buildViews(context: Context, snapshot: WidgetStore.Snapshot?): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.finance_widget)
        if (snapshot == null) {
            views.setTextViewText(R.id.widget_balance, context.getString(R.string.widget_empty))
            views.setTextViewText(R.id.widget_expenses, "")
            views.setTextViewText(R.id.widget_currency, "")
        } else {
            views.setTextViewText(R.id.widget_balance, snapshot.balance)
            views.setTextViewText(
                R.id.widget_expenses,
                context.getString(R.string.widget_spent, snapshot.expenses),
            )
            views.setTextViewText(R.id.widget_currency, snapshot.currency)
        }

        val openApp = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            openApp,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
        return views
    }

    companion object {
        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, FinanceWidgetProvider::class.java),
            )
            if (ids.isEmpty()) {
                return
            }
            val intent = Intent(context, FinanceWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(intent)
        }
    }
}

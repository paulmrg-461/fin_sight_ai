package pro.devpaul.fin_sight_ai

import android.content.Context
import android.content.SharedPreferences

/** Persists the latest dashboard snapshot for the home-screen widget. */
object WidgetStore {
    private const val PREFS = "fin_sight_widget"
    private const val KEY_BALANCE = "balance"
    private const val KEY_EXPENSES = "expenses"
    private const val KEY_CURRENCY = "currency"
    private const val KEY_UPDATED_AT = "updated_at"

    data class Snapshot(
        val balance: String,
        val expenses: String,
        val currency: String,
        val updatedAt: String,
    )

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun save(
        context: Context,
        balance: String,
        expenses: String,
        currency: String,
        updatedAt: String,
    ) {
        prefs(context).edit()
            .putString(KEY_BALANCE, balance)
            .putString(KEY_EXPENSES, expenses)
            .putString(KEY_CURRENCY, currency)
            .putString(KEY_UPDATED_AT, updatedAt)
            .apply()
    }

    fun read(context: Context): Snapshot? {
        val values = prefs(context)
        val balance = values.getString(KEY_BALANCE, null) ?: return null
        val expenses = values.getString(KEY_EXPENSES, null) ?: return null
        return Snapshot(
            balance = balance,
            expenses = expenses,
            currency = values.getString(KEY_CURRENCY, "") ?: "",
            updatedAt = values.getString(KEY_UPDATED_AT, "") ?: "",
        )
    }
}

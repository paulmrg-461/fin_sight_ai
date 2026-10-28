package pro.devpaul.fin_sight_ai

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "update") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                WidgetStore.save(
                    context = this,
                    balance = call.argument<String>("balance") ?: "",
                    expenses = call.argument<String>("expenses") ?: "",
                    currency = call.argument<String>("currency") ?: "",
                    updatedAt = call.argument<String>("updatedAt") ?: "",
                )
                FinanceWidgetProvider.refreshAll(this)
                result.success(null)
            }
    }

    companion object {
        const val WIDGET_CHANNEL = "devpaul.fin_sight_ai/widget"
    }
}

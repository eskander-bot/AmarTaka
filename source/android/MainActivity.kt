package com.meskander.amartaka
import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private var bridge: MethodChannel? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        bridge = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.meskander.amartaka/widget")
        bridge!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "update" -> {
                    getSharedPreferences("ledger_widget", MODE_PRIVATE).edit()
                        .putString("totals", call.argument<String>("totals") ?: "{}")
                        .putString("zero", call.argument<String>("zero") ?: "৳ ০")
                        .putBoolean("hidden", call.argument<Boolean>("hidden") ?: true).apply()
                    LedgerWidgetProvider.updateAll(this)
                    result.success(null)
                }
                "takeAction" -> {
                    val action = intent?.getStringExtra("ledger_action")
                    intent?.removeExtra("ledger_action")
                    result.success(if (action == "income" || action == "expense") action else null)
                }
                else -> result.notImplemented()
            }
        }
    }
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        bridge?.invokeMethod("actionReady", null)
    }
}

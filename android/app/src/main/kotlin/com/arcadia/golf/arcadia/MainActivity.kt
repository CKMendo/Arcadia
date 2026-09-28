package com.arcadia.golf.arcadia

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.arcadia.golf.arcadia/communication"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "sendSms" -> sendSms(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun sendSms(call: MethodCall, result: MethodChannel.Result) {
        val phoneNumbers = call.argument<List<String>>("phoneNumbers")
            ?.map { it.trim() }
            ?.filter { it.isNotEmpty() }
            .orEmpty()
        val message = call.argument<String>("message").orEmpty()
        if (phoneNumbers.isEmpty()) {
            result.error("missing_recipients", "Choose at least one recipient.", null)
            return
        }
        val recipientList = phoneNumbers.joinToString(";")
        val intent = Intent(
            Intent.ACTION_SENDTO,
            Uri.parse("smsto:${Uri.encode(recipientList, ";+")}"),
        ).putExtra("sms_body", message)
        try {
            startActivity(intent)
            result.success(null)
        } catch (_: ActivityNotFoundException) {
            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, message)
            }
            try {
                startActivity(Intent.createChooser(shareIntent, "Share Tournament Rules"))
                result.success(null)
            } catch (_: ActivityNotFoundException) {
                result.error(
                    "sms_unavailable",
                    "No messaging or sharing app is available.",
                    null,
                )
            }
        }
    }
}

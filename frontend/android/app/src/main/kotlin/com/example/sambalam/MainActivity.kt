package com.example.sambalam

import android.content.Intent
import android.os.Bundle
import android.provider.AlarmClock
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.sambalam/alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "setSystemAlarm") {
                    val hour = call.argument<Int>("hour") ?: 0
                    val minute = call.argument<Int>("minute") ?: 0
                    val message = call.argument<String>("message") ?: "Attendance alarm"

                    val intent = Intent(AlarmClock.ACTION_SET_ALARM).apply {
                        putExtra(AlarmClock.EXTRA_HOUR, hour)
                        putExtra(AlarmClock.EXTRA_MINUTES, minute)
                        putExtra(AlarmClock.EXTRA_MESSAGE, message)
                        putExtra(AlarmClock.EXTRA_SKIP_UI, false) // show Clock UI
                    }

                    // Let Android pick the clock app if multiple exist
                    if (intent.resolveActivity(packageManager) != null) {
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.error("NO_CLOCK", "No alarm clock app found", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}

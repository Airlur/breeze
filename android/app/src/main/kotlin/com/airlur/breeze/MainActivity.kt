package com.airlur.breeze

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val shortcutChannelName = "breeze/shortcuts"
    private var shortcutChannel: MethodChannel? = null
    private var pendingShortcut: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        pendingShortcut = extractShortcut(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        shortcutChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            shortcutChannelName
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getShortcut" -> {
                        result.success(pendingShortcut)
                        pendingShortcut = null
                    }

                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        extractShortcut(intent)?.let { dispatchShortcut(it) }
    }

    private fun dispatchShortcut(shortcutId: String) {
        shortcutChannel?.invokeMethod("shortcutTriggered", shortcutId)
            ?: run { pendingShortcut = shortcutId }
    }

    private fun extractShortcut(intent: Intent?): String? {
        if (intent == null || Intent.ACTION_VIEW != intent.action) {
            return null
        }
        val dataString = intent.dataString ?: return null
        val prefix = "breeze://shortcut/"
        return if (dataString.startsWith(prefix)) {
            dataString.substring(prefix.length)
        } else {
            null
        }
    }
}

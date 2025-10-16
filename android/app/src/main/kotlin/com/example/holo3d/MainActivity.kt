package com.example.holo3d

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.KeyEvent

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.holo3d/keys"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            result.notImplemented()
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        println("=== Native Android Key Event ===")
        println("KeyCode: $keyCode")
        println("Event: $event")
        println("===============================")
        
        // Send ANY key event to Flutter (including keycode 0)
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, CHANNEL).invokeMethod("onKeyDown", keyCode)
        }
        
        // Let the system handle the key normally
        return super.onKeyDown(keyCode, event)
    }
}

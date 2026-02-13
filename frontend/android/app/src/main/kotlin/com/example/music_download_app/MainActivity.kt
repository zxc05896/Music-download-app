package com.example.music_download_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import android.os.Build
import android.view.WindowManager

class MainActivity: FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 🚀 تفعيل تسجيل جميع الإضافات (Plugins) أوتوماتيكياً
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }

    override fun onResume() {
        super.onResume()
        
        // 💎 تفعيل وضع "السرعة القصوى" للرسوميات (Hardware Acceleration)
        // هذا يجعل التنقل داخل التطبيق ناعماً جداً (120Hz Refresh Rate Support)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false) 
        } else {
            @Suppress("DEPRECATION")
            window.setFlags(
                WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
                WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED
            )
        }
    }
}

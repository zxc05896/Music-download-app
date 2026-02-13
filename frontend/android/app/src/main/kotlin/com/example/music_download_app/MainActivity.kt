package com.example.music_download_app

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    // ملاحظات:
    // - مع Android Embedding V2 مافيش حاجة لازمة لـ GeneratedPluginRegistrant.registerWith
    // - لو عندك plugins بتحتاج تسجيل خاص (مثل background isolates)، الافضل تنفيذها عبر FlutterPlugin APIs أو توكيلها على native side حسب توجيه كل plugin.

    override fun onResume() {
        super.onResume()

        // تشغيل hardware acceleration / تعديل واجهة النوافذ بناءً على إصدار الـ Android
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // API 30+: التحكم في الواجهة الحديثة
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

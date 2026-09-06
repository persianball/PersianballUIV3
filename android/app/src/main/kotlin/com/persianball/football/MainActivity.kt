package com.persianball.football

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createDefaultNotificationChannel()
    }

    /**
     * کانالِ پیش‌فرضی که AndroidManifest به آن اشاره می‌کند.
     *
     * روی اندروید ۸ به بالا نوتیفیکیشن بدونِ کانالِ موجود نمایش داده
     * نمی‌شود؛ اگر این کانال ساخته نشود، FCM بی‌صدا به کانالِ عمومیِ
     * «Miscellaneous» برمی‌گردد و تنظیماتِ صدا و اهمیت از دست می‌رود.
     */
    private fun createDefaultNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            "persianball_default",
            "اعلان‌های پرشین شاپ",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "سفارش‌ها، دوره‌ها و پیام‌های فروشگاه"
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager?.createNotificationChannel(channel)
    }
}

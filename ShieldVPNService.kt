package com.shieldvpn.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.IBinder
import android.os.ParcelFileDescriptor
import androidx.core.app.NotificationCompat
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class ShieldVPNService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    private var executor: ExecutorService? = null
    private val CHANNEL_ID = "shieldvpn_channel"
    private val NOTIFICATION_ID = 1

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val protocol = intent?.getStringExtra("protocol") ?: "vless"
        val config = intent?.getSerializableExtra("config") as? HashMap<String, Any>

        startForeground(NOTIFICATION_ID, buildNotification("ShieldVPN - $protocol"))

        // Build VPN interface based on protocol
        val builder = Builder()
            .setSession("ShieldVPN-$protocol")
            .addAddress("10.0.0.2", 24)
            .addDnsServer("8.8.8.8")
            .addDnsServer("1.1.1.1")
            .addRoute("0.0.0.0", 0)
            .setMtu(1500)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            builder.setMetered(false)
        }

        vpnInterface = builder.establish()

        // Start packet processing
        executor = Executors.newSingleThreadExecutor()
        executor?.execute { processPackets() }

        return START_STICKY
    }

    private fun processPackets() {
        val iface = vpnInterface ?: return
        val input = FileInputStream(iface.fileDescriptor)
        val output = FileOutputStream(iface.fileDescriptor)
        val buffer = ByteBuffer.allocate(32767)

        while (!Thread.interrupted()) {
            try {
                val length = input.read(buffer.array())
                if (length > 0) {
                    // Process packet through Xray-core / protocol library
                    // This is where native protocol implementation would go
                    buffer.clear()
                }
            } catch (e: Exception) {
                break
            }
        }
    }

    override fun onDestroy() {
        executor?.shutdownNow()
        vpnInterface?.close()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "ShieldVPN",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "VPN connection status"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(text: String): android.app.Notification {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("ShieldVPN")
            .setContentText(text)
            .setSmallIcon(R.drawable.ic_vpn)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }
}

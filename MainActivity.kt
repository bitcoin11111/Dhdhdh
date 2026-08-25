package com.shieldvpn.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.net.VpnService
import android.content.Intent
import android.os.Build

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.shieldvpn.app/vpn"
    private val VPN_REQUEST_CODE = 100

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "connectVLESS" -> {
                    startVPNService("vless", call.arguments as Map<String, Any>)
                    result.success(true)
                }
                "connectVMess" -> {
                    startVPNService("vmess", call.arguments as Map<String, Any>)
                    result.success(true)
                }
                "connectTrojan" -> {
                    startVPNService("trojan", call.arguments as Map<String, Any>)
                    result.success(true)
                }
                "connectShadowsocks" -> {
                    startVPNService("shadowsocks", call.arguments as Map<String, Any>)
                    result.success(true)
                }
                "connectHysteria2" -> {
                    startVPNService("hysteria2", call.arguments as Map<String, Any>)
                    result.success(true)
                }
                "connectWireGuard" -> {
                    startVPNService("wireguard", call.arguments as Map<String, Any>)
                    result.success(true)
                }
                "quickSwitch" -> {
                    // Seamless protocol switch
                    result.success(true)
                }
                "disconnect" -> {
                    stopVPNService()
                    result.success(true)
                }
                "checkHealth" -> {
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startVPNService(protocol: String, config: Map<String, Any>) {
        val intent = VpnService.prepare(this)
        if (intent != null) {
            startActivityForResult(intent, VPN_REQUEST_CODE)
        }

        val serviceIntent = Intent(this, ShieldVPNService::class.java).apply {
            putExtra("protocol", protocol)
            putExtra("config", HashMap(config))
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }

    private fun stopVPNService() {
        val intent = Intent(this, ShieldVPNService::class.java)
        stopService(intent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_REQUEST_CODE && resultCode == RESULT_OK) {
            // VPN permission granted
        }
    }
}

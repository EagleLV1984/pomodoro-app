package com.pomodoro.app

import android.os.Bundle
import android.view.WindowManager
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebView
import androidx.appcompat.app.AppCompatActivity
import androidx.webkit.WebSettingsCompat
import androidx.webkit.WebViewFeature

class MainActivity : AppCompatActivity() {

    private lateinit var webView: WebView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 保持屏幕常亮
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        webView = WebView(this).apply {
            settings.apply {
                javaScriptEnabled = true
                domStorageEnabled = true
                allowFileAccess = true
                mediaPlaybackRequiresUserGesture = false
            }
            addJavascriptInterface(HostBridge(), "hostBridge")
            webChromeClient = WebChromeClient()
        }

        setContentView(webView)
        webView.loadUrl("file:///android_asset/pomodoro.html")
    }

    override fun onBackPressed() {
        // 让 WebView 优先处理返回
    }

    inner class HostBridge {
        @JavascriptInterface
        fun postMessage(message: String) {
            // Android WebView 的 JS bridge 只支持方法调用，不支持 postMessage 字符串
            // 适配：解析消息并处理
            try {
                val json = org.json.JSONObject(message)
                when (json.optString("type")) {
                    "alwaysOnTop" -> {} // Android 暂不支持窗口置顶
                    "resizeWindow" -> {} // Android 全屏无需缩放
                    "setDarkMode" -> {
                        val dark = json.optBoolean("value", false)
                        runOnUiThread {
                            if (dark) {
                                webView.setBackgroundColor(0xFF1A1414.toInt())
                            } else {
                                webView.setBackgroundColor(0xFFFDF2F2.toInt())
                            }
                        }
                    }
                }
            } catch (_: Exception) {}
        }
    }
}

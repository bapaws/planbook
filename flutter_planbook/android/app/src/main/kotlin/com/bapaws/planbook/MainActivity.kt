package com.bapaws.planbook

import com.bapaws.planbook_widget.WidgetActionDispatcher
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // 把主 App 的 FlutterEngine 缓存起来，供 widget 端的 WidgetActionDispatcher 复用，
        // 避免 widget 点击时另起一个 headless engine。
        FlutterEngineCache
            .getInstance()
            .put(WidgetActionDispatcher.ENGINE_CACHE_KEY, flutterEngine)
    }
}

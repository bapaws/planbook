package es.antonborri.home_widget

import android.content.Context
import android.content.SharedPreferences
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** HomeWidgetPlugin - 仅提供 saveWidgetData / getWidgetData */
class HomeWidgetPlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context

  private val doubleLongPrefix: String = "home_widget.double."

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "home_widget")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "saveWidgetData" -> {
        if (call.hasArgument("id") && call.hasArgument("data")) {
          val id = call.argument<String>("id")
          val data = call.argument<Any>("data")
          val prefs = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).edit()
          if (data != null) {
            prefs.putBoolean("$doubleLongPrefix$id", data is Double)
            when (data) {
              is Boolean -> prefs.putBoolean(id, data)
              is Float -> prefs.putFloat(id, data)
              is String -> prefs.putString(id, data)
              is Double -> prefs.putLong(id, java.lang.Double.doubleToRawLongBits(data))
              is Int -> prefs.putInt(id, data)
              is Long -> prefs.putLong(id, data)
              else ->
                  result.error(
                      "-10",
                      "Invalid Type ${data!!::class.java.simpleName}. Supported types are Boolean, Float, String, Double, Long",
                      IllegalArgumentException(),
                  )
            }
          } else {
            prefs.remove(id)
            prefs.remove("$doubleLongPrefix$id")
          }
          result.success(prefs.commit())
        } else {
          result.error(
              "-1",
              "InvalidArguments saveWidgetData must be called with id and data",
              IllegalArgumentException(),
          )
        }
      }
      "getWidgetData" -> {
        if (call.hasArgument("id")) {
          val id = call.argument<String>("id")
          val defaultValue = call.argument<Any>("defaultValue")

          val prefs = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

          val value = prefs.all[id] ?: defaultValue

          if (value is Long && prefs.getBoolean("$doubleLongPrefix$id", false)) {
            result.success(java.lang.Double.longBitsToDouble(value))
          } else {
            result.success(value)
          }
        } else {
          result.error(
              "-2",
              "InvalidArguments getWidgetData must be called with id",
              IllegalArgumentException(),
          )
        }
      }
      "setAppGroupId" -> {
        result.success(true)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  companion object {
    internal const val PREFERENCES = "HomeWidgetPreferences"

    fun getData(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
  }
}

import Flutter
import UIKit

public class HomeWidgetPlugin: NSObject, FlutterPlugin {

  private static var groupId: String?

  private let notInitializedError = FlutterError(
    code: "-7", message: "AppGroupId not set. Call setAppGroupId first", details: nil)

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = HomeWidgetPlugin()

    let channel = FlutterMethodChannel(name: "home_widget", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "setAppGroupId" {
      guard let args = call.arguments else {
        return
      }
      if let myArgs = args as? [String: Any?],
        let groupId = myArgs["groupId"] as? String
      {
        HomeWidgetPlugin.groupId = groupId
        result(true)
      } else {
        result(
          FlutterError(
            code: "-6", message: "InvalidArguments setAppGroupId must be called with a group id",
            details: nil))
      }
    } else if call.method == "saveWidgetData" {
      if HomeWidgetPlugin.groupId == nil {
        result(notInitializedError)
        return
      }
      guard let args = call.arguments else {
        return
      }
      if let myArgs = args as? [String: Any?],
        let id = myArgs["id"] as? String,
        let data = myArgs["data"]
      {
        let preferences = UserDefaults.init(suiteName: HomeWidgetPlugin.groupId)
        if data != nil {
          if let binaryData = data as? FlutterStandardTypedData {
            preferences?.setValue(Data(binaryData.data), forKey: id)
          } else {
            preferences?.setValue(data, forKey: id)
          }
        } else {
          preferences?.removeObject(forKey: id)
        }
        result(true)
      } else {
        result(
          FlutterError(
            code: "-1", message: "InvalidArguments saveWidgetData must be called with id and data",
            details: nil))
      }
    } else if call.method == "getWidgetData" {
      if HomeWidgetPlugin.groupId == nil {
        result(notInitializedError)
        return
      }
      guard let args = call.arguments else {
        return
      }
      if let myArgs = args as? [String: Any?],
        let id = myArgs["id"] as? String,
        let defaultValue = myArgs["defaultValue"]
      {
        let preferences = UserDefaults.init(suiteName: HomeWidgetPlugin.groupId)
        result(preferences?.value(forKey: id) ?? defaultValue)
      } else {
        result(
          FlutterError(
            code: "-2", message: "InvalidArguments getWidgetData must be called with id",
            details: nil))
      }
    } else {
      result(FlutterMethodNotImplemented)
    }
  }
}

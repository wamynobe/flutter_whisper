import Flutter
import UIKit

public class FlutterWhisperPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_whisper", binaryMessenger: registrar.messenger())
    let instance = FlutterWhisperPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS")
  }
}

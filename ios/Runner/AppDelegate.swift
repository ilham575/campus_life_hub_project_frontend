import UIKit
import Flutter
import GoogleMaps   // << ต้องเพิ่มบรรทัดนี้

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyAohjRHJI1PtZcOhQbCVuT3o0oUhLdPWh0") // << ใส่ API Key ของคุณตรงนี้
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

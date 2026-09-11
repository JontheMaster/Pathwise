import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let fertig = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    // Noch vor dem Ende des Starts: sonst geht der Tipp verloren, mit dem die
    // App aus einer Erinnerung heraus gestartet wurde.
    UNUserNotificationCenter.current().delegate = PathwiseBruecke.shared
    return fertig
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Widget und Erinnerung (lib/data/einsprung_bruecke.dart).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PathwiseBruecke") {
      PathwiseBruecke.shared.anmelden(registrar)
    }
  }
}

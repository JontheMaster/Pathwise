// Die iOS-Seite von lib/data/einsprung_bruecke.dart.
//
// Drei Aufgaben, alle ausserhalb der App:
//   - dem Widget den Stand der App hinueberreichen (ueber die App Group),
//   - die taegliche Erinnerung planen,
//   - Tipps auf Widget und Erinnerung an Flutter weitergeben.
//
// Bewusst ohne Plugin: Android, Web und Desktop bauen davon nichts mit.
import Flutter
import UIKit
import UserNotifications
import WidgetKit

final class PathwiseBruecke: NSObject {
  static let shared = PathwiseBruecke()

  /// Muss mit dem Widget (PathwiseWidget.swift) und beiden .entitlements
  /// uebereinstimmen.
  static let appGruppe = "group.de.sommerer.pathwise"
  static let widgetSchluessel = "pw_widget"
  private static let erinnerungPraefix = "pw-erinnerung-"

  private var kanal: FlutterMethodChannel?

  /// Flutter hat nach dem Startziel gefragt; ab jetzt geht jeder Tipp direkt
  /// hinueber.
  private var dartBereit = false

  /// Ein Tipp, der ankam, bevor Flutter so weit war — typisch beim Kaltstart
  /// aus dem Widget heraus.
  private var wartendesZiel: String?

  func anmelden(_ registrar: FlutterPluginRegistrar) {
    let kanal = FlutterMethodChannel(
      name: "pathwise/einsprung", binaryMessenger: registrar.messenger())
    kanal.setMethodCallHandler { [weak self] aufruf, antwort in
      self?.behandeln(aufruf, antwort)
    }
    self.kanal = kanal
    // Flutter reicht die Szenen-Ereignisse an angemeldete Delegates weiter —
    // darueber kommen die Adressen aus dem Widget an.
    registrar.addSceneDelegate(self)
  }

  // MARK: Tipps weitergeben

  func ziel(_ adresse: String) {
    if dartBereit, let kanal {
      kanal.invokeMethod("ziel", arguments: adresse)
    } else {
      wartendesZiel = adresse
    }
  }

  private func ziel(aus url: URL?) -> Bool {
    guard let url, url.scheme == "pathwise" else { return false }
    ziel(url.absoluteString)
    return true
  }

  // MARK: Kanal

  private func behandeln(_ aufruf: FlutterMethodCall, _ antwort: @escaping FlutterResult) {
    switch aufruf.method {
    case "startZiel":
      dartBereit = true
      antwort(wartendesZiel)
      wartendesZiel = nil

    case "widgetDaten":
      guard let json = aufruf.arguments as? String else {
        antwort(nil)
        return
      }
      UserDefaults(suiteName: Self.appGruppe)?.set(json, forKey: Self.widgetSchluessel)
      WidgetCenter.shared.reloadAllTimelines()
      antwort(nil)

    case "erlaubnis":
      UNUserNotificationCenter.current().getNotificationSettings { e in
        let status: String
        switch e.authorizationStatus {
        case .authorized, .provisional, .ephemeral: status = "erlaubt"
        case .denied: status = "abgelehnt"
        default: status = "offen"
        }
        DispatchQueue.main.async { antwort(status) }
      }

    case "erlaubnisAnfragen":
      // Nur die Mitteilung selbst: kein Ton, keine Zahl am App-Symbol.
      // DESIGN.md 1 — kein Sound, keine Zaehler.
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { erlaubt, _ in
        DispatchQueue.main.async { antwort(erlaubt) }
      }

    case "erinnerungenPlanen":
      planen(aufruf.arguments as? [[String: Any]] ?? [], antwort)

    case "erinnerungenLoeschen":
      loeschen { DispatchQueue.main.async { antwort(nil) } }

    case "geplant":
      UNUserNotificationCenter.current().getPendingNotificationRequests { anfragen in
        let ids = anfragen.map(\.identifier)
          .filter { $0.hasPrefix(Self.erinnerungPraefix) }
          .sorted()
        DispatchQueue.main.async { antwort(ids) }
      }

    case "systemEinstellungen":
      let adresse: String
      if #available(iOS 16.0, *) {
        adresse = UIApplication.openNotificationSettingsURLString
      } else {
        adresse = UIApplication.openSettingsURLString
      }
      if let url = URL(string: adresse) { UIApplication.shared.open(url) }
      antwort(nil)

    default:
      antwort(FlutterMethodNotImplemented)
    }
  }

  // MARK: Erinnerungen

  private func loeschen(_ fertig: @escaping () -> Void) {
    let zentrale = UNUserNotificationCenter.current()
    zentrale.getPendingNotificationRequests { anfragen in
      let ids = anfragen.map(\.identifier).filter { $0.hasPrefix(Self.erinnerungPraefix) }
      zentrale.removePendingNotificationRequests(withIdentifiers: ids)
      fertig()
    }
  }

  /// Ersetzt den ganzen Plan. Jede Erinnerung ist ein einzelner Termin, kein
  /// sich wiederholender: so kann jeder Tag ein anderes Szenario vorschlagen.
  private func planen(_ eintraege: [[String: Any]], _ antwort: @escaping FlutterResult) {
    loeschen {
      let zentrale = UNUserNotificationCenter.current()
      let gruppe = DispatchGroup()
      var fehler: Error?

      for e in eintraege {
        guard let id = e["id"] as? String,
          let jahr = e["jahr"] as? Int, let monat = e["monat"] as? Int,
          let tag = e["tag"] as? Int, let stunde = e["stunde"] as? Int,
          let minute = e["minute"] as? Int
        else { continue }

        let inhalt = UNMutableNotificationContent()
        inhalt.title = e["titel"] as? String ?? ""
        inhalt.subtitle = e["untertitel"] as? String ?? ""
        inhalt.body = e["text"] as? String ?? ""
        inhalt.userInfo = ["ziel": e["ziel"] as? String ?? ""]
        inhalt.threadIdentifier = "pathwise-erinnerung"
        // inhalt.sound bleibt leer: kein Ton (DESIGN.md 1).

        var zeit = DateComponents()
        zeit.year = jahr
        zeit.month = monat
        zeit.day = tag
        zeit.hour = stunde
        zeit.minute = minute

        gruppe.enter()
        zentrale.add(
          UNNotificationRequest(
            identifier: id, content: inhalt,
            trigger: UNCalendarNotificationTrigger(dateMatching: zeit, repeats: false))
        ) { f in
          DispatchQueue.main.async {
            if let f { fehler = f }
            gruppe.leave()
          }
        }
      }

      gruppe.notify(queue: .main) {
        if let fehler {
          antwort(FlutterError(code: "planen", message: fehler.localizedDescription, details: nil))
        } else {
          antwort(nil)
        }
      }
    }
  }
}

// MARK: Adressen aus dem Widget

extension PathwiseBruecke: FlutterSceneLifeCycleDelegate {
  /// Kaltstart: die App wurde ueber das Widget geoeffnet.
  func scene(
    _ scene: UIScene, willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions?
  ) -> Bool {
    _ = ziel(aus: connectionOptions?.urlContexts.first?.url)
    return false
  }

  /// Die App lief schon.
  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    ziel(aus: URLContexts.first?.url)
  }
}

// MARK: Tipps auf die Erinnerung

extension PathwiseBruecke: UNUserNotificationCenterDelegate {
  func userNotificationCenter(
    _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
    withCompletionHandler fertig: @escaping () -> Void
  ) {
    if let adresse = response.notification.request.content.userInfo["ziel"] as? String,
      !adresse.isEmpty
    {
      ziel(adresse)
    }
    fertig()
  }

  /// Ist die App gerade offen, genuegt die Mitteilungszentrale — kein Banner
  /// ueber dem, was man gerade liest.
  func userNotificationCenter(
    _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
    withCompletionHandler fertig: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    fertig([.list])
  }
}

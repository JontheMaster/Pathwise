// Das Widget auf dem Homescreen.
//
// Steckt jemand mitten in einem Szenario, zeigt es die "Weiter machen"-Karte
// der Uebersicht. Sonst ein offenes Szenario mit Titel, Themenfeld und
// Vorgeschichte — alle vier Stunden ein anderes. Die Daten legt die App in der
// App Group ab (lib/data/vorschlag.dart, ios/Runner/PathwiseBruecke.swift);
// den Wechsel plant das Widget selbst, auch wenn die App geschlossen bleibt.
import SwiftUI
import WidgetKit

// MARK: Daten

struct PwSzenarioEintrag: Codable, Hashable {
  let id: String
  let titel: String
  let themenfeld: String
  let kurz: String
  let vorgeschichte: String
  let punkte: Int
  /// Nur bei einem unterbrochenen Szenario: der offene Entscheidungspunkt,
  /// einsbasiert.
  let punkt: Int?

  /// Fuer die Widget-Galerie und die Vorschau, solange die App noch nie offen
  /// war. Text aus assets/szenarien.json.
  static let beispiel = PwSzenarioEintrag(
    id: "heimspiel",
    titel: "Vor dem Heimspiel",
    themenfeld: "Umkleide, Duschen und Räume",
    kurz: "Ein Vater bleibt in der Kabine, während sich die Kinder umziehen. "
      + "Er gehört seit Jahren zum Verein und hilft regelmäßig aus.",
    vorgeschichte: "Heimspieltag. Der Vater fährt seit zwei Jahren Auswärtsfahrten "
      + "mit und verteilt vor den Spielen die Trikots. Eine Regel, wer sich während "
      + "des Umziehens in der Kabine aufhalten darf, gibt es im Team nicht.",
    punkte: 3,
    punkt: nil)
}

struct PwWidgetDaten: Codable {
  let version: Int
  let theme: String
  let laufend: PwSzenarioEintrag?
  let vorschlaege: [PwSzenarioEintrag]

  /// Muss mit ios/Runner/PathwiseBruecke.swift und den .entitlements
  /// uebereinstimmen.
  static let appGruppe = "group.de.sommerer.pathwise"

  static func laden() -> PwWidgetDaten? {
    guard
      let text = UserDefaults(suiteName: appGruppe)?.string(forKey: "pw_widget"),
      let daten = text.data(using: .utf8)
    else { return nil }
    return try? JSONDecoder().decode(PwWidgetDaten.self, from: daten)
  }
}

enum PwWidgetInhalt {
  /// Die App wurde noch nie geoeffnet.
  case erststart
  case weiter(PwSzenarioEintrag)
  case vorschlag(PwSzenarioEintrag)

  var adresse: URL {
    switch self {
    case .erststart: return URL(string: "pathwise://start")!
    case .weiter(let s), .vorschlag(let s):
      return URL(string: "pathwise://szenario/\(s.id)")!
    }
  }
}

struct PwEintrag: TimelineEntry {
  let date: Date
  let inhalt: PwWidgetInhalt
  let theme: String
}

/// Alle vier Stunden ein anderes Szenario.
let pwWechselAbstand: TimeInterval = 4 * 60 * 60

func pwInhalt(_ daten: PwWidgetDaten?, um zeit: Date) -> PwWidgetInhalt {
  guard let daten else { return .erststart }
  if let laufend = daten.laufend { return .weiter(laufend) }
  guard !daten.vorschlaege.isEmpty else { return .erststart }
  let fenster = Int((zeit.timeIntervalSince1970 / pwWechselAbstand).rounded(.down))
  return .vorschlag(daten.vorschlaege[fenster % daten.vorschlaege.count])
}

struct PwAnbieter: TimelineProvider {
  func placeholder(in context: Context) -> PwEintrag {
    PwEintrag(date: .now, inhalt: .vorschlag(.beispiel), theme: "dark")
  }

  func getSnapshot(in context: Context, completion: @escaping (PwEintrag) -> Void) {
    let daten = PwWidgetDaten.laden()
    // In der Widget-Galerie steht lieber ein Szenario als der Erststart.
    let inhalt: PwWidgetInhalt =
      context.isPreview && daten == nil ? .vorschlag(.beispiel) : pwInhalt(daten, um: .now)
    completion(PwEintrag(date: .now, inhalt: inhalt, theme: daten?.theme ?? "dark"))
  }

  /// Ein Eintrag fuer jetzt und je einer an den naechsten sechs Wechseln —
  /// ein Tag im Voraus. Danach fragt WidgetKit neu.
  func getTimeline(in context: Context, completion: @escaping (Timeline<PwEintrag>) -> Void) {
    let daten = PwWidgetDaten.laden()
    let theme = daten?.theme ?? "dark"
    let jetzt = Date.now
    let fensterBeginn = Date(
      timeIntervalSince1970:
        (jetzt.timeIntervalSince1970 / pwWechselAbstand).rounded(.down) * pwWechselAbstand)

    var eintraege = [PwEintrag(date: jetzt, inhalt: pwInhalt(daten, um: jetzt), theme: theme)]
    for i in 1...6 {
      let zeit = fensterBeginn.addingTimeInterval(Double(i) * pwWechselAbstand)
      eintraege.append(PwEintrag(date: zeit, inhalt: pwInhalt(daten, um: zeit), theme: theme))
    }
    completion(Timeline(entries: eintraege, policy: .atEnd))
  }
}

// MARK: Widget

@main
struct PathwiseWidget: Widget {
  let kind = "PathwiseWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: PwAnbieter()) { eintrag in
      PwWidgetAnsicht(eintrag: eintrag)
    }
    .configurationDisplayName("Pathwise")
    .description("Ein Szenario zum Durchdenken — oder weiter, wo du unterbrochen hast.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    // Die Raender setzt die Ansicht selbst: die Farbkante der Marke laeuft
    // bis an den oberen Rand.
    .contentMarginsDisabled()
  }
}

#Preview(as: .systemMedium) {
  PathwiseWidget()
} timeline: {
  PwEintrag(date: .now, inhalt: .vorschlag(.beispiel), theme: "dark")
  PwEintrag(
    date: .now,
    inhalt: .weiter(
      PwSzenarioEintrag(
        id: "hilfestellung", titel: "Die Hilfestellung",
        themenfeld: "Körperkontakt und Hilfestellung", kurz: PwSzenarioEintrag.beispiel.kurz,
        vorgeschichte: PwSzenarioEintrag.beispiel.vorgeschichte, punkte: 3, punkt: 2)),
    theme: "light")
}

// Die Ansicht des Widgets — die Gestaltung der App im Kleinen.
//
// Eine Karte wie in der App (DESIGN.md 4.3): Kartenflaeche, oben die 3 dp
// hohe Farbkante der Marke, Mikro-Label, Titel in Jost, Text in Nunito Sans.
// Die eine handlungsleitende Aktion ist wie in der App koralle (DESIGN.md 2.1).
// Farben aus lib/design/pathwise_tokens.dart.
import SwiftUI
import WidgetKit

// MARK: Tokens

extension Color {
  init(_ hex: UInt32) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255,
      opacity: 1)
  }
}

struct PwFarben {
  let flaeche: Color  // surfaceCard
  let ueberschrift: Color  // textHeading
  let text: Color  // textBody
  let leise: Color  // textMuted
  let blass: Color  // textFaint
  let rand: Color  // borderSubtle
  let primaer: Color  // actionPrimary
  let akzent: Color  // actionAccent
  let aufAkzent: Color  // textInverse
  let aufTint: Color  // iconOnTint

  static let dunkel = PwFarben(
    flaeche: Color(0x1A212C), ueberschrift: Color(0xEDF2F8), text: Color(0xC3CDD9),
    leise: Color(0x93A0AF), blass: Color(0x6E7C8C), rand: Color(0x28323F),
    primaer: Color(0x3E6394), akzent: Color(0xEE6070), aufAkzent: Color(0x12171F),
    aufTint: Color(0x9CBDE2))

  static let hell = PwFarben(
    flaeche: Color(0xFFFFFF), ueberschrift: Color(0x1F3557), text: Color(0x43484F),
    leise: Color(0x707579), blass: Color(0x9198A0), rand: Color(0xDDE1E6),
    primaer: Color(0x2C4A7C), akzent: Color(0xEE6070), aufAkzent: Color(0xFFFFFF),
    aufTint: Color(0x3A5F96))

  /// Die Drei-Bogen-Folge der Marke — der einzige erlaubte Verlauf.
  static let sweep = LinearGradient(
    stops: [
      .init(color: Color(0xC2D6EB), location: 0),
      .init(color: Color(0x3A5F96), location: 0.26),
      .init(color: Color(0xEE6070), location: 0.62),
      .init(color: Color(0xFF9A6B), location: 1),
    ],
    startPoint: .leading, endPoint: .trailing)
}

/// Die Schriften der App, im Widget-Bundle mitgeliefert (Info.plist,
/// UIAppFonts). Sie wachsen mit der Textgroesse des Systems, aber nur so weit,
/// wie ein Widget es traegt.
enum PwSchrift {
  static func jost(_ groesse: CGFloat, leicht: Bool = false) -> Font {
    .custom(leicht ? "JostRoman-Light" : "JostRoman-Medium", size: groesse, relativeTo: .title3)
  }

  static func text(_ groesse: CGFloat) -> Font {
    .custom("NunitoSans-Normal", size: groesse, relativeTo: .body)
  }

  static func halbfett(_ groesse: CGFloat) -> Font {
    .custom("NunitoSans-NormalSemiBold", size: groesse, relativeTo: .body)
  }

  static func fett(_ groesse: CGFloat) -> Font {
    .custom("NunitoSans-NormalBold", size: groesse, relativeTo: .caption)
  }
}

// MARK: Bausteine

/// PwLabel: das einzige versal gesetzte Element, 11,5 pt, fett, gesperrt.
struct PwMikroLabel: View {
  let text: String
  let farbe: Color

  var body: some View {
    Text(text.uppercased())
      .font(PwSchrift.fett(11.5))
      .tracking(0.92)
      .foregroundStyle(farbe)
      .lineLimit(1)
  }
}

struct PwMarke: View {
  let groesse: CGFloat

  var body: some View {
    Image("LogoMarke")
      .resizable()
      .scaledToFill()
      .frame(width: groesse, height: groesse)
      .clipShape(Circle())
      .accessibilityHidden(true)
  }
}

/// PwStepIndicator: erledigt und aktuell in actionPrimary, der aktuelle Punkt
/// breiter.
struct PwSchritte: View {
  let gesamt: Int
  let aktuell: Int
  let f: PwFarben

  var body: some View {
    HStack(spacing: 5) {
      ForEach(1...max(gesamt, 1), id: \.self) { i in
        Capsule()
          .fill(i <= aktuell ? f.primaer : f.rand)
          .frame(width: i == aktuell ? 18 : 7, height: 7)
      }
    }
    .accessibilityElement()
    .accessibilityLabel("Entscheidungspunkt \(aktuell) von \(gesamt)")
  }
}

/// PwTag: Themenfeld als Pille.
struct PwThemenfeld: View {
  let text: String
  let f: PwFarben

  var body: some View {
    Text(text)
      .font(PwSchrift.halbfett(12.5))
      .foregroundStyle(f.aufTint)
      .lineLimit(1)
      .padding(.horizontal, 10)
      .frame(minHeight: 24)
      .background(Capsule().fill(f.flaeche))
      .overlay(Capsule().stroke(f.rand, lineWidth: 1))
  }
}

/// Die eine Aktion: koralle, Radius wie alle Bedienelemente (10).
struct PwAktion: View {
  let text: String
  let f: PwFarben
  var vollBreite = false
  var hoehe: CGFloat = 32

  var body: some View {
    HStack(spacing: 6) {
      Text(text).font(PwSchrift.halbfett(13.5)).lineLimit(1)
      Image(systemName: "arrow.right").font(.system(size: 11.5, weight: .semibold))
    }
    .foregroundStyle(f.aufAkzent)
    .padding(.horizontal, 13)
    .frame(maxWidth: vollBreite ? .infinity : nil, minHeight: hoehe)
    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(f.akzent))
  }
}

/// Nur der Pfeil — fuer das kleine Widget, in dem kein Wort Platz hat.
struct PwAktionRund: View {
  let f: PwFarben

  var body: some View {
    Image(systemName: "arrow.right")
      .font(.system(size: 13, weight: .semibold))
      .foregroundStyle(f.aufAkzent)
      .frame(width: 32, height: 32)
      .background(Circle().fill(f.akzent))
  }
}

// MARK: Ansicht

struct PwWidgetAnsicht: View {
  let eintrag: PwEintrag

  @Environment(\.widgetFamily) private var familie
  @Environment(\.colorScheme) private var system

  /// Das Theme der App gilt auch hier; "Wie das System" folgt dem Geraet.
  private var dunkel: Bool {
    switch eintrag.theme {
    case "light": return false
    case "system": return system == .dark
    default: return true  // Dunkel ist die Vorgabe der App (DESIGN.md 3).
    }
  }

  var body: some View {
    let f = dunkel ? PwFarben.dunkel : PwFarben.hell
    VStack(spacing: 0) {
      Rectangle().fill(PwFarben.sweep).frame(height: 3)
      Group {
        switch familie {
        case .systemSmall: klein(f)
        case .systemLarge: gross(f)
        default: mittel(f)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    .dynamicTypeSize(...DynamicTypeSize.xLarge)
    .widgetURL(eintrag.inhalt.adresse)
    .containerBackground(for: .widget) { f.flaeche }
    .environment(\.colorScheme, dunkel ? .dark : .light)
  }

  // MARK: Texte je Zustand

  private var label: String {
    switch eintrag.inhalt {
    case .erststart: return "Zum Anfangen"
    case .weiter: return "Weiter machen"
    case .vorschlag: return "Zum Durchdenken"
    }
  }

  private var titel: String {
    switch eintrag.inhalt {
    case .erststart: return "Die meisten Situationen im Training sind nicht eindeutig."
    case .weiter(let s), .vorschlag(let s): return s.titel
    }
  }

  private var themenfeld: String? {
    switch eintrag.inhalt {
    case .erststart: return nil
    case .weiter(let s), .vorschlag(let s): return s.themenfeld
    }
  }

  private var vorgeschichte: String {
    switch eintrag.inhalt {
    case .erststart:
      return "Hier kannst du sie einmal durchdenken, bevor du in der Halle entscheiden musst."
    case .weiter(let s), .vorschlag(let s): return s.vorgeschichte
    }
  }

  private var aktion: String {
    switch eintrag.inhalt {
    case .erststart: return "Erstes Szenario ansehen"
    case .weiter: return "Fortsetzen"
    case .vorschlag: return "Szenario beginnen"
    }
  }

  @ViewBuilder private func schritte(_ f: PwFarben, mitText: Bool) -> some View {
    if case .weiter(let s) = eintrag.inhalt {
      HStack(spacing: 8) {
        PwSchritte(gesamt: s.punkte, aktuell: s.punkt ?? 1, f: f)
        if mitText {
          Text("Punkt \(s.punkt ?? 1) von \(s.punkte)")
            .font(PwSchrift.text(12))
            .foregroundStyle(f.leise)
            .lineLimit(1)
        }
      }
    }
  }

  // MARK: Klein — Label, Titel, Pfeil

  private func klein(_ f: PwFarben) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 6) {
        PwMarke(groesse: 16)
        PwMikroLabel(text: label == "Zum Durchdenken" ? "Szenario" : label, farbe: f.blass)
      }
      Spacer(minLength: 8)
      Text(titel)
        .font(PwSchrift.jost(16))
        .foregroundStyle(f.ueberschrift)
        .lineLimit(3)
        .minimumScaleFactor(0.85)
        .fixedSize(horizontal: false, vertical: true)
      Spacer(minLength: 8)
      HStack(alignment: .center) {
        if case .weiter = eintrag.inhalt {
          schritte(f, mitText: false)
        } else if let themenfeld {
          Text(themenfeld)
            .font(PwSchrift.text(11))
            .foregroundStyle(f.blass)
            .lineLimit(2)
        }
        Spacer(minLength: 6)
        PwAktionRund(f: f)
      }
    }
    .padding(.horizontal, 14)
    .padding(.top, 12)
    .padding(.bottom, 13)
  }

  // MARK: Mittel — dazu die Vorgeschichte

  private func mittel(_ f: PwFarben) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 6) {
        PwMarke(groesse: 16)
        PwMikroLabel(text: label, farbe: f.blass)
        Spacer(minLength: 8)
        if let themenfeld {
          Text(themenfeld)
            .font(PwSchrift.text(11.5))
            .foregroundStyle(f.blass)
            .lineLimit(1)
        }
      }
      Text(titel)
        .font(PwSchrift.jost(18))
        .foregroundStyle(f.ueberschrift)
        .lineLimit(2)
        .padding(.top, 8)
      Text(vorgeschichte)
        .font(PwSchrift.text(12.5))
        .foregroundStyle(f.leise)
        .lineSpacing(1.5)
        .lineLimit(3)
        .padding(.top, 3)
      Spacer(minLength: 6)
      HStack(alignment: .center) {
        schritte(f, mitText: true)
        Spacer(minLength: 8)
        PwAktion(text: aktion, f: f, hoehe: 30)
      }
    }
    .padding(.horizontal, 16)
    .padding(.top, 13)
    .padding(.bottom, 14)
  }

  // MARK: Gross — wie der Einstieg eines Szenarios

  private func gross(_ f: PwFarben) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 8) {
        PwMarke(groesse: 20)
        PwMikroLabel(text: label, farbe: f.blass)
      }
      if let themenfeld {
        PwThemenfeld(text: themenfeld, f: f).padding(.top, 14)
      }
      Text(titel)
        .font(PwSchrift.jost(25, leicht: true))
        .foregroundStyle(f.ueberschrift)
        .lineLimit(3)
        .minimumScaleFactor(0.9)
        .padding(.top, 10)
      if themenfeld != nil {
        PwMikroLabel(text: "Vorgeschichte", farbe: f.blass).padding(.top, 14)
      }
      Text(vorgeschichte)
        .font(PwSchrift.text(14))
        .foregroundStyle(f.text)
        .lineSpacing(3)
        .lineLimit(7)
        .padding(.top, 6)
      Spacer(minLength: 10)
      if case .weiter(let s) = eintrag.inhalt {
        HStack(spacing: 10) {
          PwSchritte(gesamt: s.punkte, aktuell: s.punkt ?? 1, f: f)
          Text("Entscheidungspunkt \(s.punkt ?? 1) von \(s.punkte)")
            .font(PwSchrift.text(12.5))
            .foregroundStyle(f.leise)
            .lineLimit(1)
        }
        .padding(.bottom, 12)
      }
      PwAktion(text: aktion, f: f, vollBreite: true, hoehe: 42)
    }
    .padding(.horizontal, 18)
    .padding(.top, 16)
    .padding(.bottom, 18)
  }
}

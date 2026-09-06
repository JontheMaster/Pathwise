# Pathwise — Design-Handoff für die Flutter-App

Referenzdokument für die Implementierung. Beim Bauen jedes Screens hier nachschlagen,
nicht im Chatverlauf.

**Quelle der Wahrheit:** die HTML-Prototypen `PathwiseApp.dc.html` (interaktiv, alle Screens,
beide Themes) und `Pathwise Geräte.dc.html` (Responsive-Ansicht), sowie das Pathwise Design
System (`_ds/pathwise-design-system-.../tokens/*.css`). Die HTML-Dateien sind **Design-Referenz,
kein Produktionscode** — sie zeigen Aussehen und Verhalten, umgesetzt wird in Flutter mit
Flutter-Mitteln.

**Fidelity:** hi-fi. Farben, Typografie, Abstände, Radien, Schatten und Timings sind final und
unten exakt angegeben. Inhalte (Szenariotexte) sind erfunden und fachlich ungeprüft.

---

## 1. Produkt in einem Absatz

Szenariobasiertes Lernformat für ehrenamtliche Trainerinnen und Trainer. Ein Durchlauf:
Situation lesen → drei Entscheidungspunkte mit je genau drei Handlungsoptionen → auf Abruf eine
dreiteilige fachliche Rückmeldung (Erkennen · Absichern · Handeln) → Auswertung mit Ampel-Einordnung
der Situationsmerkmale, Einschätzungsspiegel des Trainerteams und Ansprechpersonen des Vereins.
Höchstens fünf Minuten, jederzeit unterbrechbar, ohne Anmeldung.

**Harte Verbote (aus den Anforderungen NF04, NF10, NF11, F14):**

- Keine Bewertung der Wahl als richtig/falsch. Keine Punkte, Ränge, Abzeichen, Streaks, Fristen.
- Keine Konfetti-/Belohnungs-/Feieranimation. Kein Sound. Kein Haptic-Feedback als Belohnung.
- Keine Konten, kein Login, kein Personenbezug. Fortschritt liegt lokal auf dem Gerät.
- Ampelfarben (grün/aprikot/koralle) gehören **ausschließlich** der Einordnung von
  Situationsmerkmalen. Nie an Buttons, Optionen, Fortschritt.
- Keine Fachbegriffe im Interface, keine Quellenangaben, keine Emoji, keine Ausrufezeichen.
- Kein Foto, keine Illustration, keine Figuren. Einziges Bildmotiv ist die Marke.

---

## 2. Design-Tokens als Dart-Konstanten

Datei: `lib/design/pathwise_tokens.dart`. Werte 1:1 aus `tokens/colors.css`, `dark.css`,
`spacing.css`, `radius.css`, `elevation.css`, `motion.css`, `typography.css`.

### 2.1 Basisrampen (theme-unabhängig)

```dart
import 'package:flutter/material.dart';

/// Basisrampen der Marke. Nie direkt im UI verwenden — immer über [PwColors].
abstract final class PwPalette {
  // Blau — Struktur, Navigation, primäre Aktion
  static const blue900 = Color(0xFF1F3557);
  static const blue800 = Color(0xFF2C4A7C);
  static const blue700 = Color(0xFF3A5F96);
  static const blue600 = Color(0xFF5178A8);
  static const blue500 = Color(0xFF7A9BC4);
  static const blue400 = Color(0xFF9DB8D8);
  static const blue300 = Color(0xFFC2D6EB);
  static const blue200 = Color(0xFFDCE8F5);
  static const blue100 = Color(0xFFEDF4FB);

  // Koralle — Betonung, genau eine handlungsleitende Aktion je Ansicht
  static const coral700 = Color(0xFFC8323F);
  static const coral600 = Color(0xFFE03B4C);
  static const coral500 = Color(0xFFEE6070);
  static const coral400 = Color(0xFFF4838F);
  static const coral300 = Color(0xFFF9AFB7);
  static const coral200 = Color(0xFFFCD8DC);
  static const coral100 = Color(0xFFFEEDEF);

  // Aprikose — Wärme, dritter Akzent
  static const apricot600 = Color(0xFFF1793F);
  static const apricot500 = Color(0xFFFF9A6B);
  static const apricot400 = Color(0xFFFFB48D);
  static const apricot300 = Color(0xFFFFD1B8);
  static const apricot200 = Color(0xFFFFE7DA);

  // Ink — Text und Linien
  static const ink900 = Color(0xFF1A1D21);
  static const ink800 = Color(0xFF2B2F35);
  static const ink700 = Color(0xFF43484F);
  static const ink600 = Color(0xFF5C6269);
  static const ink500 = Color(0xFF707579);
  static const ink400 = Color(0xFF9198A0);
  static const ink300 = Color(0xFFBCC2C9);
  static const ink200 = Color(0xFFDDE1E6);
  static const ink100 = Color(0xFFEEF0F3);
  static const ink050 = Color(0xFFF6F7F9);
  static const white  = Color(0xFFFFFFFF);

  static const green600 = Color(0xFF1F8A6D);
  static const green100 = Color(0xFFE2F3EE);
  static const amber600 = Color(0xFFB87A0E);
  static const amber100 = Color(0xFFFCF1DA);

  /// Der einzige erlaubte Gradient: die Drei-Bogen-Folge der Marke.
  /// Nur als 3px-Oberkante einer Karte, im Fortschrittsring, als Avatarfläche.
  /// Nie hinter Text, nie als Buttonfläche.
  static const sweep = LinearGradient(
    begin: Alignment(-0.87, -0.5), end: Alignment(0.87, 0.5), // ≈ 112deg
    colors: [blue300, blue700, coral500, apricot500],
    stops: [0.0, 0.26, 0.62, 1.0],
  );
}
```

### 2.2 Semantische Farben, Light und Dark

Als `ThemeExtension` — so bleibt `Theme.of(context).extension<PwColors>()!` die einzige
Bezugsquelle und Theme-Wechsel funktioniert ohne Sonderfälle. Material-`ColorScheme`
allein reicht nicht: Pathwise hat Ampelstufen, Rückmeldungsfarben und getönte Flächen,
die kein M3-Slot abbildet.

```dart
@immutable
class PwColors extends ThemeExtension<PwColors> {
  const PwColors({
    required this.surfacePage, required this.surfaceCard, required this.surfaceRaised,
    required this.surfaceSunken, required this.surfaceTint, required this.surfaceTintWarm,
    required this.surfaceInverse, required this.surfaceOverlay, required this.glassBg,
    required this.textHeading, required this.textBody, required this.textMuted,
    required this.textFaint, required this.textInverse, required this.textAccent,
    required this.textLink, required this.textOnTint, required this.textOnTintMuted,
    required this.iconOnTint,
    required this.borderSubtle, required this.borderDefault, required this.borderStrong,
    required this.borderFocus, required this.divider, required this.focusRing,
    required this.actionPrimary, required this.actionPrimaryHover, required this.actionPrimaryActive,
    required this.actionAccent, required this.actionAccentHover, required this.actionAccentActive,
    required this.actionQuietHover, required this.actionDisabledBg, required this.actionDisabledText,
    required this.levelOk, required this.levelOkBg,
    required this.levelCheck, required this.levelCheckBg,
    required this.levelViolation, required this.levelViolationBg,
    required this.levelAbsent, required this.levelAbsentBg,
    required this.feedbackErkennen, required this.feedbackAbsichern, required this.feedbackHandeln,
    required this.statusDanger,
  });

  final Color surfacePage, surfaceCard, surfaceRaised, surfaceSunken, surfaceTint,
      surfaceTintWarm, surfaceInverse, surfaceOverlay, glassBg;
  final Color textHeading, textBody, textMuted, textFaint, textInverse, textAccent,
      textLink, textOnTint, textOnTintMuted, iconOnTint;
  final Color borderSubtle, borderDefault, borderStrong, borderFocus, divider, focusRing;
  final Color actionPrimary, actionPrimaryHover, actionPrimaryActive,
      actionAccent, actionAccentHover, actionAccentActive,
      actionQuietHover, actionDisabledBg, actionDisabledText;
  final Color levelOk, levelOkBg, levelCheck, levelCheckBg,
      levelViolation, levelViolationBg, levelAbsent, levelAbsentBg;
  final Color feedbackErkennen, feedbackAbsichern, feedbackHandeln, statusDanger;

  static const light = PwColors(
    surfacePage: PwPalette.ink050,
    surfaceCard: PwPalette.white,
    surfaceRaised: PwPalette.white,
    surfaceSunken: PwPalette.ink100,
    surfaceTint: PwPalette.blue100,
    surfaceTintWarm: PwPalette.apricot200,
    surfaceInverse: PwPalette.blue900,
    surfaceOverlay: Color(0x701F3557),          // rgba(31,53,87,.44)
    glassBg: Color(0xB8FFFFFF),                 // rgba(255,255,255,.72)
    textHeading: PwPalette.blue900,
    textBody: PwPalette.ink700,
    textMuted: PwPalette.ink500,
    textFaint: PwPalette.ink400,
    textInverse: PwPalette.white,
    textAccent: PwPalette.coral600,
    textLink: PwPalette.blue700,
    textOnTint: PwPalette.blue900,
    textOnTintMuted: PwPalette.blue800,
    iconOnTint: PwPalette.blue700,
    borderSubtle: PwPalette.ink200,
    borderDefault: PwPalette.ink300,
    borderStrong: PwPalette.blue400,
    borderFocus: PwPalette.blue600,
    divider: PwPalette.ink100,
    focusRing: Color(0x595178A8),               // rgba(81,120,168,.35)
    actionPrimary: PwPalette.blue800,
    actionPrimaryHover: PwPalette.blue900,
    actionPrimaryActive: Color(0xFF16273F),
    actionAccent: PwPalette.coral500,
    actionAccentHover: PwPalette.coral600,
    actionAccentActive: PwPalette.coral700,
    actionQuietHover: PwPalette.blue100,
    actionDisabledBg: PwPalette.ink100,
    actionDisabledText: PwPalette.ink400,
    levelOk: PwPalette.green600,        levelOkBg: PwPalette.green100,
    levelCheck: PwPalette.apricot600,   levelCheckBg: PwPalette.apricot200,
    levelViolation: PwPalette.coral600, levelViolationBg: PwPalette.coral100,
    levelAbsent: PwPalette.ink400,      levelAbsentBg: PwPalette.ink100,
    feedbackErkennen: PwPalette.blue700,
    feedbackAbsichern: PwPalette.blue500,
    feedbackHandeln: PwPalette.apricot600,
    statusDanger: PwPalette.coral600,
  );

  /// Dunkel ist der Standard der App (abendliche Nutzung auf dem Handy).
  static const dark = PwColors(
    surfacePage: Color(0xFF12171F),
    surfaceCard: Color(0xFF1A212C),
    surfaceRaised: Color(0xFF212A38),
    surfaceSunken: Color(0xFF0D1218),
    surfaceTint: Color(0xFF1C2A3D),
    surfaceTintWarm: Color(0xFF33241C),
    surfaceInverse: Color(0xFF0B1220),
    surfaceOverlay: Color(0xA8060A11),          // rgba(6,10,17,.66)
    glassBg: Color(0xC71A212C),                 // rgba(26,33,44,.78)
    textHeading: Color(0xFFEDF2F8),
    textBody: Color(0xFFC3CDD9),
    textMuted: Color(0xFF93A0AF),
    textFaint: Color(0xFF6E7C8C),
    textInverse: Color(0xFF12171F),
    textAccent: PwPalette.coral400,
    textLink: Color(0xFF8FB2DA),
    textOnTint: Color(0xFFDEE8F5),
    textOnTintMuted: Color(0xFFBDD0E6),
    iconOnTint: Color(0xFF9CBDE2),
    borderSubtle: Color(0xFF28323F),
    borderDefault: Color(0xFF384556),
    borderStrong: Color(0xFF4C5F78),
    borderFocus: Color(0xFF7FA5D4),
    divider: Color(0xFF232D3A),
    focusRing: Color(0x528FB2DA),               // rgba(143,178,218,.32)
    actionPrimary: Color(0xFF3E6394),
    actionPrimaryHover: Color(0xFF4C74A9),
    actionPrimaryActive: Color(0xFF35567F),
    actionAccent: PwPalette.coral500,
    actionAccentHover: PwPalette.coral400,
    actionAccentActive: PwPalette.coral600,
    actionQuietHover: Color(0xFF22303F),
    actionDisabledBg: Color(0xFF222B36),
    actionDisabledText: Color(0xFF5C6875),
    levelOk: Color(0xFF4FBF9B),        levelOkBg: Color(0xFF13322A),
    levelCheck: Color(0xFFE9A06A),     levelCheckBg: Color(0xFF33240F),
    levelViolation: Color(0xFFF4838F), levelViolationBg: Color(0xFF3A1A20),
    levelAbsent: Color(0xFF6E7C8C),    levelAbsentBg: Color(0xFF1F2733),
    feedbackErkennen: Color(0xFF8FB2DA),
    feedbackAbsichern: Color(0xFFA9C4E2),
    feedbackHandeln: Color(0xFFE9A06A),
    statusDanger: Color(0xFFF4838F),
  );

  @override
  PwColors copyWith() => this; // Tokens sind fix; kein partielles Überschreiben vorgesehen.
  @override
  PwColors lerp(ThemeExtension<PwColors>? other, double t) =>
      (other is PwColors && t >= 0.5) ? other : this; // harter Schnitt, kein Farbmisch-Fade
}
```

`lerp` schneidet hart um: ein 200ms-Kreuzblenden aller Flächen beim Theme-Wechsel wirkt
unruhig und ist nicht Teil der Motion-Spec.

### 2.3 Abstände, Radien, Größen

```dart
abstract final class PwSpace {
  static const s0 = 0.0;  static const s1 = 2.0;   static const s2 = 4.0;
  static const s3 = 6.0;  static const s4 = 8.0;   static const s5 = 12.0;
  static const s6 = 16.0; static const s7 = 20.0;  static const s8 = 24.0;
  static const s9 = 32.0; static const s10 = 40.0; static const s11 = 56.0;
  static const s12 = 72.0;

  static const pagePad = 16.0;      // Seitenpolster mobil
  static const pagePadWide = 24.0;  // ab 600 dp
  static const cardPad = 20.0;
  static const cardPadLg = 28.0;
  static const gapTight = 12.0;     // Layout-Lücken: nur 12 / 16 / 24
  static const gap = 16.0;
  static const gapWide = 24.0;
  static const contentMaxWidth = 640.0;
  static const railWidth = 300.0;
}

abstract final class PwRadius {
  static const xs = 4.0;    // Checkbox
  static const sm = 6.0;    // kleine Chrome
  static const md = 10.0;   // alle Bedienelemente
  static const lg = 14.0;   // Karten
  static const xl = 20.0;   // Dialoge, Bottom Sheets
  static const xxl = 28.0;  // Geräte-/Feature-Rahmen
  static const pill = 999.0;

  static const card = BorderRadius.all(Radius.circular(lg));
  static const control = BorderRadius.all(Radius.circular(md));
  static const sheet = BorderRadius.vertical(top: Radius.circular(xl));
  static const dialog = BorderRadius.all(Radius.circular(xl));
}

abstract final class PwSize {
  static const controlSm = 30.0;
  static const controlMd = 38.0;
  static const controlLg = 46.0;
  static const touchMin = 44.0;   // Untergrenze für jedes tippbare Element
  static const buttonFull = 48.0; // volle Breite im Footer
}
```

### 2.4 Elevation

Schatten sind blau getönt, nie neutral schwarz — im Dark Mode neutral schwarz mit höherer
Deckkraft. Flutter: `BoxShadow`-Listen, **nicht** `Material.elevation` (dessen Kurven treffen
die Tönung nicht).

```dart
abstract final class PwShadow {
  static const _blue = Color(0xFF1F3557);

  static List<BoxShadow> xs(bool dark) => dark
      ? const [BoxShadow(color: Color(0x66000000), blurRadius: 2, offset: Offset(0, 1))]
      : [BoxShadow(color: _blue.withValues(alpha: .06), blurRadius: 2, offset: const Offset(0, 1))];

  static List<BoxShadow> sm(bool dark) => dark
      ? const [
          BoxShadow(color: Color(0x73000000), blurRadius: 3, offset: Offset(0, 1)),
          BoxShadow(color: Color(0x4D000000), blurRadius: 1, offset: Offset(0, 1)),
        ]
      : [
          BoxShadow(color: _blue.withValues(alpha: .07), blurRadius: 3, offset: const Offset(0, 1)),
          BoxShadow(color: _blue.withValues(alpha: .04), blurRadius: 1, offset: const Offset(0, 1)),
        ];

  static List<BoxShadow> md(bool dark) => dark
      ? const [BoxShadow(color: Color(0x80000000), blurRadius: 14, offset: Offset(0, 4))]
      : [BoxShadow(color: _blue.withValues(alpha: .09), blurRadius: 14, offset: const Offset(0, 4))];

  static List<BoxShadow> lg(bool dark) => dark
      ? const [BoxShadow(color: Color(0x8C000000), blurRadius: 32, offset: Offset(0, 12))]
      : [BoxShadow(color: _blue.withValues(alpha: .12), blurRadius: 32, offset: const Offset(0, 12))];

  static List<BoxShadow> xl(bool dark) => dark
      ? const [BoxShadow(color: Color(0x99000000), blurRadius: 64, offset: Offset(0, 24))]
      : [BoxShadow(color: _blue.withValues(alpha: .16), blurRadius: 64, offset: const Offset(0, 24))];

  /// Nur unter Korallen-Aktionen (Button variant=accent).
  static List<BoxShadow> accent(bool dark) => [
        BoxShadow(color: const Color(0xFFEE6070).withValues(alpha: dark ? .30 : .24),
            blurRadius: 22, offset: const Offset(0, 8)),
      ];
}
```

Elevation-Skala im Klartext: `xs` Chips und Inputs · `sm` Karten im Ruhezustand ·
`md` Karte unter dem Finger / gehoben · `lg` Bottom Sheet · `xl` Dialog und Sheet-Rand ·
`accent` ausschließlich Korallen-Button.

### 2.5 Motion-Token

```dart
abstract final class PwDur {
  static const instant = Duration(milliseconds: 80);   // Press-Scale
  static const fast = Duration(milliseconds: 140);     // Bedienfeedback, Farbwechsel
  static const base = Duration(milliseconds: 220);     // Flächen, AnimatedSize
  static const slow = Duration(milliseconds: 360);     // Dialoge, Balkenwachstum
  static const ambient = Duration(milliseconds: 900);
  static const staggerStep = Duration(milliseconds: 60);
}

abstract final class PwCurve {
  static const standard = Cubic(0.32, 0.72, 0.32, 1.0);  // Regelfall
  static const out      = Cubic(0.16, 1.0, 0.30, 1.0);   // Eintritte, Sheets
  static const inn      = Cubic(0.55, 0.0, 1.0, 0.45);   // Austritte
  static const gentle   = Cubic(0.40, 0.14, 0.30, 1.0);  // langsames Atmen
}

const double kPressScale = 0.985;   // Press-Zustand, 80 ms
const double kLiftHover = -2.0;     // Karte hebt sich (nur Zeigergeräte)
const double kRevealShift = 14.0;   // Eintritts-Versatz nach oben
```

### 2.6 Typografie

Schriften: **Jost** (Display: Hero, Display, H1, Screen-Titel) und **Nunito Sans**
(H2/H3, Text, Bedienelemente, Labels), **JetBrains Mono** nur für Prozentwerte,
Telefonnummern, Zähler wie „2/3". Lesegröße 15/1.5.

`pubspec.yaml`: entweder `google_fonts` (Jost, Nunito Sans, JetBrains Mono) oder die
`.ttf` in `assets/fonts/` mit `fontFamily: Jost | NunitoSans | JetBrainsMono`.

| Rolle | Flutter-Slot | Familie | Größe | Gewicht | Höhe | Tracking |
|---|---|---|---|---|---|---|
| Display 1 | `displayLarge` | Jost | 48 | 300 | 1.24 | −0.015em |
| Display 2 | `displayMedium` | Jost | 38 | 300 | 1.24 | −0.015em |
| Display 3 / Erststart-H2 | `displaySmall` | Jost | 27 | 300 | 1.25 | −0.015em |
| H1 / Screen-Titel | `titleLarge` | Jost | 24 | 500 | 1.24 | −0.005em |
| Kopfzeilentitel | `titleMedium` | Jost | 17 | 500 | 1.2 | −0.005em |
| H2 | `headlineSmall` | Nunito Sans | 20 | 600 | 1.24 | 0 |
| H3 / Leitfrage | `titleSmall` | Nunito Sans | 17 | 600 | 1.45 | 0 |
| Text | `bodyLarge` | Nunito Sans | 15 | 400 | 1.5 | 0 |
| Text klein | `bodyMedium` | Nunito Sans | 13.5 | 400 | 1.5 | 0 |
| Button | `labelLarge` | Nunito Sans | 14 | 600 | 1.0 | 0.005em |
| Mikro-Label (Versal) | `labelSmall` | Nunito Sans | 11.5 | 700 | 1.2 | 0.08em |
| Mono | eigener Style | JetBrains Mono | 13.5 | 400 | 1.5 | 0 |

Nur das 11,5px-Mikro-Label wird versal gesetzt (`.pw-label`). Sonst normale
Groß-/Kleinschreibung. Textumbruch: `softWrap: true`, kein `overflow: ellipsis`
außer im Kopfzeilentitel (dort eine Zeile mit Ellipse).

---

## 3. ThemeData

Datei: `lib/design/pathwise_theme.dart`.

```dart
ThemeData pwTheme({required bool dark}) {
  final c = dark ? PwColors.dark : PwColors.light;
  final scheme = ColorScheme(
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: c.actionPrimary,
    onPrimary: dark ? const Color(0xFFEDF2F8) : PwPalette.white,
    primaryContainer: c.surfaceTint,
    onPrimaryContainer: c.textOnTint,
    secondary: c.actionAccent,                  // Koralle: genau eine Aktion je Ansicht
    onSecondary: dark ? const Color(0xFF12171F) : PwPalette.white,
    secondaryContainer: dark ? const Color(0xFF3A1A20) : PwPalette.coral100,
    onSecondaryContainer: dark ? const Color(0xFFF4A0A9) : PwPalette.coral700,
    tertiary: PwPalette.apricot600,
    onTertiary: PwPalette.white,
    error: c.statusDanger,
    onError: dark ? const Color(0xFF12171F) : PwPalette.white,
    surface: c.surfaceCard,
    onSurface: c.textBody,
    surfaceContainerLowest: c.surfaceSunken,
    surfaceContainerLow: c.surfacePage,
    surfaceContainer: c.surfaceCard,
    surfaceContainerHigh: c.surfaceRaised,
    surfaceContainerHighest: c.surfaceTint,
    onSurfaceVariant: c.textMuted,
    outline: c.borderDefault,
    outlineVariant: c.borderSubtle,
    inverseSurface: c.surfaceInverse,
    onInverseSurface: PwPalette.white,
    shadow: dark ? Colors.black : PwPalette.blue900,
    scrim: c.surfaceOverlay,
  );

  const jost = 'Jost', sans = 'NunitoSans', mono = 'JetBrainsMono';
  final text = TextTheme(
    displayLarge:  TextStyle(fontFamily: jost, fontSize: 48, height: 1.24, fontWeight: FontWeight.w300, letterSpacing: -0.72, color: c.textHeading),
    displayMedium: TextStyle(fontFamily: jost, fontSize: 38, height: 1.24, fontWeight: FontWeight.w300, letterSpacing: -0.57, color: c.textHeading),
    displaySmall:  TextStyle(fontFamily: jost, fontSize: 27, height: 1.25, fontWeight: FontWeight.w300, letterSpacing: -0.40, color: c.textHeading),
    titleLarge:    TextStyle(fontFamily: jost, fontSize: 24, height: 1.24, fontWeight: FontWeight.w500, letterSpacing: -0.12, color: c.textHeading),
    titleMedium:   TextStyle(fontFamily: jost, fontSize: 17, height: 1.20, fontWeight: FontWeight.w500, letterSpacing: -0.09, color: c.textHeading),
    headlineSmall: TextStyle(fontFamily: sans, fontSize: 20, height: 1.24, fontWeight: FontWeight.w600, color: c.textHeading),
    titleSmall:    TextStyle(fontFamily: sans, fontSize: 17, height: 1.45, fontWeight: FontWeight.w600, color: c.textHeading),
    bodyLarge:     TextStyle(fontFamily: sans, fontSize: 15, height: 1.5, color: c.textBody),
    bodyMedium:    TextStyle(fontFamily: sans, fontSize: 13.5, height: 1.5, color: c.textMuted),
    labelLarge:    TextStyle(fontFamily: sans, fontSize: 14, height: 1.0, fontWeight: FontWeight.w600, letterSpacing: 0.07, color: c.textHeading),
    labelMedium:   TextStyle(fontFamily: mono, fontSize: 13.5, height: 1.5, color: c.textMuted),
    labelSmall:    TextStyle(fontFamily: sans, fontSize: 11.5, height: 1.2, fontWeight: FontWeight.w700, letterSpacing: 0.92, color: c.textFaint),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: scheme.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.surfacePage,
    canvasColor: c.surfacePage,
    textTheme: text,
    fontFamily: sans,
    splashFactory: NoSplash.splashFactory,       // Pathwise nutzt Press-Scale, keine Ripple
    highlightColor: Colors.transparent,
    dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: c.glassBg, surfaceTintColor: Colors.transparent,
      elevation: 0, scrolledUnderElevation: 0, centerTitle: false,
      titleTextStyle: text.titleMedium, foregroundColor: c.textMuted,
      shape: Border(bottom: BorderSide(color: c.borderSubtle)),
    ),
    cardTheme: CardThemeData(
      color: c.surfaceCard, surfaceTintColor: Colors.transparent, elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: PwRadius.card, side: BorderSide(color: c.borderSubtle)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surfaceCard, surfaceTintColor: Colors.transparent,
      modalBarrierColor: c.surfaceOverlay, elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: PwRadius.sheet),
      showDragHandle: false,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surfaceCard, surfaceTintColor: Colors.transparent, elevation: 0,
      barrierColor: c.surfaceOverlay,
      shape: RoundedRectangleBorder(
        borderRadius: PwRadius.dialog, side: BorderSide(color: c.borderSubtle)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: c.surfaceCard, isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      hintStyle: text.bodyLarge!.copyWith(color: c.textFaint),
      border: OutlineInputBorder(borderRadius: PwRadius.control,
          borderSide: BorderSide(color: c.borderDefault)),
      enabledBorder: OutlineInputBorder(borderRadius: PwRadius.control,
          borderSide: BorderSide(color: c.borderDefault)),
      focusedBorder: OutlineInputBorder(borderRadius: PwRadius.control,
          borderSide: BorderSide(color: c.borderFocus)),
      errorBorder: OutlineInputBorder(borderRadius: PwRadius.control,
          borderSide: BorderSide(color: c.statusDanger)),
      disabledBorder: OutlineInputBorder(borderRadius: PwRadius.control,
          borderSide: BorderSide(color: c.borderSubtle)),
    ),
    filledButtonTheme: FilledButtonThemeData(style: ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, PwSize.buttonFull)),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: PwRadius.control)),
      textStyle: WidgetStatePropertyAll(text.labelLarge),
      backgroundColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.disabled) ? c.actionDisabledBg
        : s.contains(WidgetState.pressed) ? c.actionAccentActive
        : s.contains(WidgetState.hovered) ? c.actionAccentHover
        : c.actionAccent),
      foregroundColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.disabled) ? c.actionDisabledText : c.textInverse),
    )),
    outlinedButtonTheme: OutlinedButtonThemeData(style: ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, PwSize.buttonFull)),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: PwRadius.control)),
      textStyle: WidgetStatePropertyAll(text.labelLarge),
      backgroundColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.disabled) ? c.actionDisabledBg
        : s.contains(WidgetState.pressed) ? c.surfaceSunken : c.surfaceCard),
      foregroundColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.disabled) ? c.actionDisabledText : c.textHeading),
      side: WidgetStateProperty.resolveWith((s) => BorderSide(
        color: s.contains(WidgetState.disabled) ? Colors.transparent
             : s.contains(WidgetState.hovered) ? c.borderStrong : c.borderDefault)),
    )),
    extensions: [dark ? PwColors.dark : PwColors.light],
  );
}
```

App-Einstieg: `MaterialApp(theme: pwTheme(dark: false), darkTheme: pwTheme(dark: true),
themeMode: gespeicherterModus ?? ThemeMode.dark)` — **Standard ist Dark**, nicht `system`.
Der Wunsch wird lokal gespeichert.

Zugriffshelfer:

```dart
extension PwThemeX on BuildContext {
  PwColors get pw => Theme.of(this).extension<PwColors>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
```

---

## 4. Komponenten

Für jede Komponente: Aufbau, Varianten, Zustände, Flutter-Entsprechung. Alle liegen unter
`lib/design/components/`. Alles, was tippbar ist, misst mindestens 44 dp in der Höhe.

### 4.1 PwButton

**Aufbau:** Zeile aus optionalem Führungs-Icon (16), Label, optionalem Folge-Icon (16),
Abstand 8. Höhe nach Größe, Radius 10, ein 1px-Rand in Flächenfarbe.

**Varianten**

| Variante | Fläche | Text | Rand | Schatten | Einsatz |
|---|---|---|---|---|---|
| `accent` | `actionAccent` | `textInverse` | gleich Fläche | `PwShadow.accent` | die eine handlungsleitende Aktion je Ansicht |
| `primary` | `actionPrimary` | `textInverse` | gleich Fläche | keiner | Zweitwichtiges, außerhalb des Footers |
| `secondary` | `surfaceCard` | `textHeading` | `borderDefault` | `xs` | Nebenaktion („Nochmal", „Antwort ändern") |
| `ghost` | transparent | `textLink` | transparent | keiner | Textaktionen in Sheets |
| `quiet` | `surfaceTint` | `textOnTintMuted` | transparent | keiner | Aktion auf getönter Fläche |

**Größen:** `sm` 30 · `md` 38 · `lg` 46 dp; Innenpolster 12/18/24; Schrift 13/14/15.5.
Im Footer immer `fullWidth` mit 48 dp Höhe.

**States**

| State | Darstellung |
|---|---|
| default | wie Tabelle |
| hovered (nur Zeigergerät) | Fläche eine Rampenstufe dunkler (`*Hover`), `secondary` zusätzlich Rand `borderStrong` |
| pressed | Fläche `*Active` **und** `scale(0.985)` über 80 ms `PwCurve.standard` |
| focused | 3px Ring `focusRing` außen, Rand `borderFocus`; nie entfernen |
| disabled | Fläche `actionDisabledBg`, Text `actionDisabledText`, Rand transparent, kein Schatten, `onPressed: null` |
| loading | wie disabled, statt Führungs-Icon ein 16px-Spinner, 900 ms linear, Label bleibt stehen |
| error | Buttons tragen keinen Fehlerzustand — Fehler stehen am Feld (`PwField.error`) |

**Flutter:** `FilledButton` (accent/primary), `OutlinedButton` (secondary), `TextButton`
(ghost/quiet) mit den Themes aus Abschnitt 3, umschlossen von einem eigenen
`_PressScale`-Widget (`AnimatedScale`, 80 ms, `PwCurve.standard`) für den Press-Scale.
`splashFactory: NoSplash` ist global gesetzt — Pathwise hat keine Ripple.

### 4.2 PwIconButton

Quadrat 30/38/46 dp, Radius 10, Icon 15/18/20. Varianten `ghost` (transparent, Icon
`textMuted`), `secondary` (Karte + Rand), `primary` (Blaufläche). Hover: `actionQuietHover`,
Icon `textOnTintMuted`. Disabled: Icon `actionDisabledText`.
**Wichtig:** Trotz 30 dp Kantenlänge bekommt `sm` eine 44 dp große Trefferfläche.
**Flutter:** `IconButton` mit `constraints: BoxConstraints.tightFor(width: 30, height: 30)`,
`padding: EdgeInsets.zero`, umgeben von `SizedBox(width: 44, height: 44)`; immer mit
`tooltip` und `semanticLabel`.

### 4.3 PwCard

Fläche `surfaceCard`, Radius 14, 1px `borderSubtle`, `PwShadow.sm`, Polster 20
(`padding: lg` → 28). Töne: `default`, `tint` (`surfaceTint`, Text über `textOnTint`),
`warm` (`surfaceTintWarm`), `inverse` (`surfaceInverse`, höchstens einmal je Ansicht).
Dekoration nur als 3 dp hohe Oberkante (`accent: sweep` oder eine Volltonfarbe) — eine
farbige **linke** Kante ist kein Pathwise-Muster.
**States:** `interactive` hebt bei Hover um 2 dp und wechselt auf `PwShadow.md` (220 ms
`PwCurve.out`); auf Touch entfällt der Hover, dafür Press-Scale 0.985.
**Flutter:** `DecoratedBox` + `ClipRRect` (die Oberkante muss beschnitten werden) statt
`Card` — `Card` bringt Material-Elevation und Surface-Tint mit, die hier stören.

### 4.4 PwTag / Themenfeld-Chip

Pille, Höhe 28, Polster 0/12, Schrift 13.5/600. Unselektiert: `surfaceCard`, Text
`iconOnTint`, Rand `borderSubtle`. Selektiert: Fläche `iconOnTint`, Text `textInverse`.
Hover (nur klickbar): `actionQuietHover`. Optionales `x` zum Entfernen (13px).
**Flutter:** `FilterChip` mit `showCheckmark: false` und `ChipThemeData`, oder ein
eigenes `GestureDetector` + `AnimatedContainer` (140 ms) — letzteres trifft die
Farbwechsel exakter.

### 4.5 PwStepIndicator

Reihe aus n Punkten, Abstand 5: erledigt/aktuell `actionPrimary`, offen `borderSubtle`;
der aktuelle Punkt ist 18 × 7 statt 7 × 7. Danach 10 dp Abstand und der Text
„Entscheidungspunkt {i} von {n}" in `bodyMedium`/`textMuted`.
**Animation:** Breitenwechsel 220 ms `PwCurve.out`, Farbwechsel 220 ms `PwCurve.standard`.
**Flutter:** `Row` aus `AnimatedContainer`. Semantik: `Semantics(label: 'Entscheidungspunkt 2 von 3')`.

### 4.6 PwSituationText

Karte (Radius 14, Polster 20) mit Rahmen-Chips oben (Altersgruppe, Ort, Zeitpunkt:
Polster 3/9, Pille, `surfaceSunken`, `bodyMedium`/`textMuted`, `Wrap` mit 8 dp Lücke),
darunter der Situationstext in `bodyLarge`. Variante `fortsetzung: true` ersetzt die Chips
durch Icon `corner-down-right` + Mikro-Label „So geht es weiter".
**Flutter:** `Container` + `Wrap` + `Text`.

### 4.7 PwDecisionPoint

**Aufbau:** Leitfrage (`titleSmall`, 17/600/1.45), darunter genau drei Optionskarten,
Abstand 10. Option: Kreis 22 dp mit Buchstabe A/B/C (11.5/700), 12 dp Abstand, Text
`bodyLarge`, Mindesthöhe 44, Polster 13/15, Radius 10, Rand `borderDefault`, Schatten `xs`.

**States je Option**

| State | Darstellung |
|---|---|
| default | Karte wie oben, Kreis mit Rand `borderDefault` und Buchstabe |
| hovered (vor der Wahl) | Rand `borderStrong` |
| pressed | Press-Scale 0.985, 80 ms |
| gewählt | Fläche `surfaceTint`, Rand `blue600`, kein Schatten, Kreis gefüllt `actionPrimary` mit `check`-Icon |
| nicht gewählt, nachdem gewählt wurde | Deckkraft 0.55, nicht mehr tippbar (`cursor: default`), Übergang 220 ms |
| disabled/loading | kommt nicht vor — die Optionen sind lokal und sofort |

**Nie:** Ampelfarben, Häkchen/Kreuz als Wertung, Reihenfolge nach „Güte".
**Flutter:** `Column` aus `AnimatedOpacity` + `InkWell`-freien `GestureDetector`-Karten;
Zustandswechsel über `AnimatedContainer(220 ms, PwCurve.standard)`.
Semantik: `Semantics(button: true, selected: gewaehlt == id)`.

### 4.8 PwFeedbackPanel

Getönte Karte (`surfaceTint`, Radius 14, Rand `blue200` hell / `borderSubtle` dunkel).
Kopfzeile: `book-open`-Icon (16, `iconOnTint`), Text „Fachliche Einordnung anzeigen /
ausblenden" (15/600, `textOnTintMuted`), rechts `chevron-down`/`chevron-up`, Mindesthöhe 44.
Aufgeklappt: drei Blöcke in fester Reihenfolge **Erkennen · Absichern · Handeln**, je
Kreis 28 dp (`surfaceCard`) mit Icon `eye` / `shield` / `footprints` in
`feedbackErkennen` / `feedbackAbsichern` / `feedbackHandeln`, daneben Versal-Mikro-Label
in derselben Farbe und der Text in `bodyLarge`/`textOnTint`.

**States:** zu (Standard, immer zu bis zum Abruf) · offen · Hinweis-Puls (siehe Motion M7).
Kein disabled, kein error. Wird erst gerendert, nachdem eine Option gewählt wurde.
**Flutter:** eigenes Widget mit `AnimatedSize(duration: 220 ms, curve: PwCurve.out)` +
`FadeTransition`. **Nicht** `ExpansionTile` — dessen Chrome und Ripple passen nicht.

### 4.9 PwLevelList (Ampel-Einordnung)

Kopf: Kreis 22 dp in `level*Bg` mit Icon `circle-check` / `circle-help` / `circle-alert`
in `level*`, daneben Versal-Mikro-Label „Unbedenklich" / „Klärungsbedürftig" /
„Grenzverletzend" in derselben Farbe. Darunter Liste: je Merkmal ein Block, Polster 11/13,
Radius 10, Fläche `level*Bg`, links ein 3 dp breiter Strich in `level*`, Text `bodyLarge`.
Nicht eingetretene Merkmale: Fläche `levelAbsentBg`, Strich `levelAbsent`, Text `textMuted`
plus Nachsatz in `bodyMedium`/`textFaint`: „In diesem Durchlauf nicht eingetreten — hier
würde die Situation kippen."
**Keine States** — reine Anzeige. Farbe ist hier bedeutungstragend, deshalb trägt jeder
Block zusätzlich sein Icon und sein Textlabel (Farbe nie als einziger Träger).
**Flutter:** `Column` aus `Container`; Eintritt gestaffelt (Motion M8).

### 4.10 PwMirrorBar (Einschätzungsspiegel)

Je Option: Zeile aus Optionstext (`bodyLarge`) — bei der eigenen Wahl gefolgt vom Zusatz
„deine Wahl" (`bodyMedium`, `iconOnTint`) — rechts der Prozentwert in **Mono**. Darunter
ein 8 dp hoher Pillenbalken, Spur `surfaceSunken`, Füllung `actionPrimary` bei der eigenen
Wahl, sonst `blue300` (hell) / `borderStrong` (dunkel).
**Variante `zuWenige`:** statt der Balken ein Hinweisblock (`surfaceSunken`, Radius 10,
Icon `users` 15) mit dem Satz „Für diesen Entscheidungspunkt liegen noch zu wenige
Einschätzungen vor. …" — das ist der Empty-State, kein Fehler.
**Loading:** solange die Zählwerte geladen werden, die Spur ohne Füllung zeigen und den
Prozenttext durch `—` ersetzen; **kein** Skeleton-Shimmer.
**Error:** schlägt der Abruf fehl, denselben Block wie `zuWenige` zeigen, Text: „Die
Einschätzungen des Teams sind gerade nicht abrufbar." Kein Retry-Button, kein Toast.
**Flutter:** `TweenAnimationBuilder<double>` auf die Balkenbreite, 360 ms `PwCurve.out`,
gestaffelt 60 ms je Zeile.

### 4.11 PwContactList

Mikro-Label „Ansprechpersonen · {Verein}", darunter je Person eine Zeile: Kreis 34 dp
(`surfaceTint`, Icon `user` 16, `iconOnTint`), Name (15/600, `textHeading`), Rolle
(`bodyMedium`/`textMuted`), rechts ein Link mit Icon `mail` oder `phone` (14) und der
Kontaktangabe in 13.5/600.
**Verhalten:** Tippen öffnet `tel:` bzw. `mailto:` (`url_launcher`). Schlägt das fehl,
Kontakt in die Zwischenablage kopieren und einen ruhigen `SnackBar`-Hinweis zeigen.
**Flutter:** `Column` aus `Container` + `InkWell`-freiem `GestureDetector`.

### 4.12 PwHelpBar

Dauerhaft am Ende jeder Ansicht (außer Vereinsangaben). Fläche `surfaceInverse`, Radius 10,
Mindesthöhe 44, Polster 11/14: Icon `life-buoy` 17 (`blue300`), Titel „Hilfetelefon
Sexueller Missbrauch" (13.5/600, weiß), Zeile 2 „0800 22 55 530 · anonym und kostenfrei"
(`bodyMedium`, `blue300`), rechts `phone` 16 weiß.
**Verhalten:** in der App tippbar → öffnet das Hilfe-Sheet (siehe S6), nicht direkt den
Anruf; der Anruf startet erst aus dem Sheet. Das verhindert versehentliche Anrufe.

### 4.13 Formular: PwField / PwInput / PwTextarea

`PwField`: Label (13.5/600, `textHeading`, optional `*` in `textAccent`), Kind, darunter
Hinweis (`bodyMedium`/`textMuted`) **oder** Fehler (`bodyMedium`/`statusDanger`) — nie beides.
`PwInput`: Höhe 38 (md) / 46 (lg), Polster 12, Radius 10, Fläche `surfaceCard`, Rand
`borderDefault`, Schatten `xs`.

| State | Rand | Sonstiges |
|---|---|---|
| default | `borderDefault` | Schatten `xs` |
| focused | `borderFocus` | 3px `focusRing` statt Schatten |
| invalid | `statusDanger` | Fehlertext unter dem Feld |
| disabled | `borderSubtle` | Fläche `surfaceSunken`, Text `actionDisabledText` |
| loading | — | tritt nicht auf; beim Absenden wird der Button `loading` |

`PwTextarea`: `maxLines` 4 (Rückmeldung) bzw. 6 (Situation einschicken), `minLines` gleich,
Polster 12, sonst wie Input. Kein Zeichenzähler.
**Flutter:** `TextField` mit `inputDecorationTheme` aus Abschnitt 3, umgeben von einem
eigenen `PwField`-Wrapper.

### 4.14 Bottom Sheet (Grundform für alle Overlays)

Fläche `surfaceCard`, obere Ecken 20, maximale Höhe 92 % (Hilfe/Info) bzw. 94 %
(Rückmeldung), Polster 22/20/20, `PwShadow.xl`, Schleier `surfaceOverlay` + 3px Blur.
Kopf: Titel (Jost 22/500) links, `PwIconButton(x)` rechts. Abschluss immer ein
`secondary`-Button voller Breite („Verstanden" / „Zurück zum Szenario" / „Schließen").
Schließen: Tippen auf den Schleier, der x-Button, Systemzurück, Herunterziehen.
**Flutter:** `showModalBottomSheet(isScrollControlled: true, useSafeArea: true,
barrierColor: pw.surfaceOverlay)` mit `BackdropFilter(sigmaX: 3, sigmaY: 3)` im Barrier;
Inhalt in `DraggableScrollableSheet` nur, wenn er die Höhe reißt.

### 4.15 Nicht verwenden

`ProgressRing` und `SideNav` aus dem Design System gehören zur Web-Fassung. Im Handy-Layout
kommen sie nicht vor; `ProgressRing` dürfte ohnehin nur Fortschritt zeigen, nie eine Punktzahl.
Ebenso ungenutzt: `Confetti` (Verbot), `Toast` (bis auf den Kopier-Hinweis in 4.11),
`Tabs`, `Switch`, `Checkbox`, `RadioGroup`, `Select`.

---

## 5. Motion-Spec

Grundsätze: 80 ms Press · 140 ms Bedienfeedback · 220 ms Flächen · 360 ms Dialoge.
Eintritte sind ein kurzes Aufsteigen mit Einblenden (8–22 dp), Austritte einfaches
Ausblenden. Kein Federn, kein Bounce, keine Deckkraft als Hover-Zustand.

| # | Element / Auslöser | Bewegung | Dauer | Curve |
|---|---|---|---|---|
| M1 | Jeder Button/jede Optionskarte, `onTapDown` → `onTapUp` | `scale 1 → 0.985 → 1` | 80 ms | `PwCurve.standard` |
| M2 | Button/Chip/Input, Farb- oder Randwechsel | Farbinterpolation | 140 ms | `PwCurve.standard` |
| M3 | Karte, Hover (nur Zeigergerät) | `translateY -2`, Schatten `sm → md` | 220 ms | `PwCurve.out` |
| M4 | **Szenario öffnen** (Übersicht → Einstieg), Tippen auf Szenariokarte | `scale 0.94 → 1` + `translateY 12 → 0`, Fade in | 340 ms | `PwCurve.out` |
| M5 | **Szenario schließen** (→ Übersicht), Zurück-Button im Header | `scale 1.04 → 1`, Fade in | 260 ms | `PwCurve.out` |
| M6 | **Entscheidungspunkt vor/zurück** („Weiter" / Mini-Pfeil) | vorwärts: `translateX +16 → 0`; zurück: `translateX −16 → 0`, jeweils Fade in | 260 ms | `PwCurve.out` |
| M7 | **Rückmeldungs-Hinweis**: eine Option wurde gewählt, Panel noch zu | Ring um das Panel, `box-shadow 0 → 5 dp` in `textLink` 34 %, 4 Zyklen, 2,6 s je Zyklus, Start nach 600 ms | 2600 ms × 4 | `easeInOut` |
| M8 | **Fachliche Einordnung** auf-/zuklappen | `AnimatedSize` Höhe + Inhalt `translateY −6 → 0`, Fade in | 260 ms auf / 220 ms zu | `PwCurve.out` |
| M9 | **Situation nachlesen** auf-/zuklappen (Punkt und Auswertung) | `AnimatedSize` + Fade, Chevron dreht 180° | 240 ms | `PwCurve.out` |
| M10 | **Vereinsangaben öffnen** (Zahnrad) | `translateY +22 → 0`, Fade in | 300 ms | `PwCurve.out` |
| M11 | **Vereinsangaben schließen** | `translateY −14 → 0`, Fade in | 260 ms | `PwCurve.out` |
| M12 | **Auswertung öffnen** („Auswertung"-Button am letzten Punkt) | wie M6 vorwärts | 260 ms | `PwCurve.out` |
| M13 | **Bottom Sheet** (Hilfe, Info, Rückmeldung) | Inhalt `translateY 100 % → 0` | 300 ms | `PwCurve.out` |
| M14 | Schleier hinter jedem Overlay | Fade `0 → 1` | 200 ms | `PwCurve.out` |
| M15 | Sheet/Dialog schließen | Inhalt herunter + Schleier aus | 220 ms | `PwCurve.inn` |
| M16 | **„Kommt bald"-Dialog** öffnen | `translateY 14 → 0`, Fade in | 360 ms | `PwCurve.out` |
| M17 | Ringe im „Kommt bald"-Dialog (Dauerschleife) | drei Ringe `scale 0.6 → 1.9`, Deckkraft `0.55 → 0`, Versatz 0 / 0.9 / 1.8 s | 2600 ms, endlos | `PwCurve.out` |
| M18 | Icon im „Kommt bald"-Dialog | `scale 1 → 1.06 → 1` | 3400 ms, endlos | `PwCurve.gentle` |
| M19 | Drei Punkte im „Kommt bald"-Dialog | Deckkraft `0.25 → 1 → 0.25`, Versatz 0 / 0.2 / 0.4 s | 1400 ms, endlos | `easeInOut` |
| M20 | **Schrittanzeige**, Punktwechsel | aktiver Punkt `7 → 18` dp breit, Farbwechsel | 220 ms | `PwCurve.out` |
| M21 | **Spiegelbalken**, Auswertung erscheint | Breite `0 → Anteil %`, je Zeile 60 ms versetzt | 360 ms | `PwCurve.out` |
| M22 | **Ampel-Listen**, Auswertung erscheint | je Block `translateY 14 → 0` + Fade, 60 ms Stagger | 220 ms | `PwCurve.out` |
| M23 | Rückmeldung abgeschickt → Bestätigung | Inhaltstausch im Sheet, `translateY 14 → 0` + Fade | 320 ms | `PwCurve.out` |
| M24 | Button `loading` | Spinner-Rotation | 900 ms, endlos | `Curves.linear` |

**Reduzierte Bewegung:** `MediaQuery.of(context).disableAnimations` (bzw.
`accessibleNavigation`) → alle Dauern auf ~0 ms, Endzustand sofort; die Dauerschleifen
M17–M19 laufen gar nicht erst an. Ein zentrales `PwMotion.scale(context)` liefert den
Faktor 1.0 oder 0.0 und wird auf **jede** Dauer angewendet.

---

## 6. Navigationsstruktur

Ein `Navigator` mit benannten Routen; die Overlays sind keine Routen, sondern Sheets/Dialoge
(bleiben aber im Backstack, damit Systemzurück sie schließt).

```
Übersicht (/)                             Wurzel, nie im Backstack ersetzt
 ├─ Szenario-Einstieg (/szenario/:id)      M4 öffnen · M5 zurück
 │   └─ Entscheidungspunkt (/szenario/:id/punkt/:n)   M6 vor · M6 zurück
 │       └─ Auswertung (/szenario/:id/auswertung)     M12
 │            ├─ „Nochmal"      → Einstieg desselben Szenarios, Wahlen gelöscht
 │            └─ „Zur Übersicht" → Übersicht (Stack bis zur Wurzel abräumen), M5
 ├─ Vereinsangaben (/verein)               M10 öffnen · M11 zurück
 ├─ Hilfe-Sheet          modal, von jedem Screen (HelpBar unten)          M13
 ├─ Info-Sheet           modal, Info-Symbol im Header, Erststart-Karte    M13
 ├─ Rückmeldungs-Sheet   modal, Übersicht/Seitenleiste/Info-Sheet         M13
 └─ „Kommt bald"-Dialog  modal, Kacheln unter „Weitere Bereiche"          M16
```

**Wege im Detail**

- Szenariokarte tippen: noch nicht begonnen → Einstieg; begonnen → direkt zum zuletzt
  offenen Entscheidungspunkt.
- „Weiter machen"-Karte oben in der Übersicht springt zum ersten unabgeschlossenen Szenario.
- Header links: bei jedem Screen außer der Übersicht ein `chevron-left`, der **zur Übersicht**
  zurückführt (nicht einen Schritt) — der Durchlauf ist jederzeit unterbrechbar.
- Im Entscheidungspunkt zusätzlich ein kleiner `chevron-left` **über** der Schrittanzeige:
  einen Punkt zurück. Er erscheint erst ab Punkt 2.
- Systemzurück (Android-Geste, iOS-Swipe): schließt zuerst ein offenes Overlay, sonst wie
  der Header-Zurück. Auf der Übersicht verlässt er die App.

**Page-Transitions in Flutter**

```dart
Route<T> pwRoute<T>(Widget page, PwTransition kind) => PageRouteBuilder<T>(
  transitionDuration: kind.dur,               // M4 340 · M6/M5 260 · M10 300
  reverseTransitionDuration: kind.reverseDur,
  opaque: true,
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (ctx, anim, sec, child) {
    final e = CurvedAnimation(parent: anim, curve: PwCurve.out);
    return FadeTransition(opacity: e, child: switch (kind) {
      PwTransition.oeffnen => ScaleTransition(                    // M4
          scale: Tween(begin: .94, end: 1.0).animate(e),
          child: SlideTransition(
              position: Tween(begin: const Offset(0, .03), end: Offset.zero).animate(e),
              child: child)),
      PwTransition.schliessen => ScaleTransition(                 // M5
          scale: Tween(begin: 1.04, end: 1.0).animate(e), child: child),
      PwTransition.vor => SlideTransition(                        // M6 vorwärts
          position: Tween(begin: const Offset(.045, 0), end: Offset.zero).animate(e),
          child: child),
      PwTransition.zurueck => SlideTransition(                    // M6 zurück
          position: Tween(begin: const Offset(-.045, 0), end: Offset.zero).animate(e),
          child: child),
      PwTransition.hoch => SlideTransition(                       // M10
          position: Tween(begin: const Offset(0, .06), end: Offset.zero).animate(e),
          child: child),
      PwTransition.runter => SlideTransition(                     // M11
          position: Tween(begin: const Offset(0, -.04), end: Offset.zero).animate(e),
          child: child),
    });
  },
);
```

Die Entscheidungspunkte 1–3 sind **nicht** drei Routen, sondern eine Route mit
`AnimatedSwitcher` (260 ms, M6) über den Punktinhalt — Header, Schrittanzeige und Footer
bleiben stehen und wechseln nicht mit. Kopfzeile, Fußzeile und die Schrittanzeige
animieren nie mit dem Screen.

---

## 7. Screens

Gemeinsames Gerüst aller Screens (`PwScaffold`):

- **Kopfzeile**, 56 dp, `glassBg` mit `BackdropFilter(14, 14)` und `saturate 1.4`, unten
  1px `borderSubtle`, klebt oben. Inhalt: optional Zurück-Icon · optional Logo (nur
  Übersicht) · Titel (`titleMedium`, eine Zeile, Ellipse) · im Punkt-Screen rechts der
  Mono-Zähler „2/3" in `textFaint` · Info-Icon · auf der Übersicht Zahnrad.
- **Inhalt**: scrollbar, Seitenpolster 16, Inhaltsbreite maximal 640 dp, zentriert,
  Elementabstand 16.
- **Fußzeile**: `glassBg`, oben 1px `borderSubtle`, Polster 12/16/14 + `SafeArea`,
  darin die Primäraktion(en) und darunter die `PwHelpBar`.

### S1 Übersicht (`/`)

Zweck: Szenario auswählen oder weitermachen.
Reihenfolge: Erststart-Karte (nur beim ersten Öffnen) · „Weiter machen"-Karte (nur bei
laufendem Szenario) · Einleitungssatz · Themenfeld-Chips (`Wrap`) · Szenario-Raster ·
Abschnitt „Weitere Bereiche" · Rückmeldungs-Block · HelpBar.

- **Erststart-Karte:** `padding: lg`, `accent: sweep`, Mikro-Label „Zum Anfangen",
  Überschrift Jost 27/300, zwei Absätze, Trennlinie, die sechs Info-Blöcke (Kreis 30 dp
  + Titel 15/600 + Text `bodyMedium`), Abschluss-Button `accent` volle Breite.
- **„Weiter machen":** `accent: sweep`, Mikro-Label + Themenfeld rechts, Titel Jost 21/500,
  Schrittanzeige, Button `accent` „Fortsetzen".
- **Szenariokarte:** Raster `minmax(272, 1fr)`, Lücke 12 — auf dem Handy eine Spalte.
  Inhalt: Themenfeld-Tag und rechts der Status („Noch nicht bearbeitet" `textFaint` /
  „Angefangen" `blue700` + `rotate-ccw` / „Abgeschlossen" `levelOk` + `check`), Titel
  Jost 17/500, Kurztext `bodyMedium`. **Keine Fußzeile, kein Button, keine Zeitangabe** —
  die ganze Karte ist die Aktion.
- **Weitere Bereiche:** Kacheln mit gestricheltem Rand `borderStrong`, Icon-Quadrat 32 dp,
  Titel 14/600, Zusatz `bodyMedium`, rechts `arrow-up-right`. Tippen öffnet den
  „Kommt bald"-Dialog.
- **Rückmeldungs-Block:** getönte Fläche, Icon `message-square`, zwei Zeilen, `chevron-right`.

Kleine Displays: unter 360 dp Breite Seitenpolster auf 12, Karten einspaltig, Chips
umbrechen; die Kopfzeile behält Zurück/Titel/Info und lässt bei Platznot das Zahnrad
in das Info-Sheet wandern.

### S2 Szenario-Einstieg (`/szenario/:id`)

Mikro-Label Themenfeld · Titel Jost 27/300 · `PwSituationText` mit Rahmen-Chips ·
getönte Karte „Vorgeschichte". Footer: ein `accent`-Button „Szenario beginnen" + HelpBar.
Der Screen ist bewusst kurz — er soll ohne Scrollen auf ein 390 × 844-Display passen.

### S3 Entscheidungspunkt (`/szenario/:id/punkt/:n`)

Reihenfolge: Zeile aus Mini-Zurück (ab Punkt 2) + Schrittanzeige · aufklappbares Feld
„Situation nachlesen" (Icon `file-text`, Mindesthöhe 44, aufgeklappt zeigt es
Ausgangssituation und Vorgeschichte) · Karte mit Verlaufsmarke (`corner-down-right` +
Mikro-Label „Was gerade passiert" / „Wie es weitergeht" / „Was danach geschieht") und dem
Punkttext · `PwDecisionPoint` · nach der Wahl `PwFeedbackPanel` (zu, mit Hinweis-Puls M7),
davor der Satz „Eine fachliche Einordnung erscheint, sobald du dich entschieden hast."
(`bodyMedium`/`textFaint`).
Footer: `secondary` „Antwort ändern" (Flex 1) und `accent` „Weiter" / am letzten Punkt
„Auswertung" (Flex 1.2), darunter die HelpBar. „Weiter" ist **disabled**, solange nichts
gewählt ist.

Kleine Displays: unter 360 dp die beiden Footer-Buttons untereinander (Flex-Reihe wird zu
`Column` mit 10 dp Lücke), „Weiter" oben.

### S4 Auswertung (`/szenario/:id/auswertung`)

Überschrift „Was war unbedenklich, was klärungsbedürftig?" (Jost 26/300) + Erläuterungssatz ·
drei `PwLevelList` · Trennlinie · Abschnitt „Einschätzungsspiegel" mit einer Karte je
Entscheidungspunkt (Mikro-Label, rechts „Situation nachlesen" mit `file-text`, Leitfrage,
aufklappbarer Situationstext auf getönter Fläche, `PwMirrorBar`) · Trennlinie ·
`PwContactList` · Schlusssatz „Dieser Prototyp gehört zur Prävention. Er ersetzt keine
Meldung und keine Beratung." Footer: `secondary` „Nochmal" + `accent` „Zur Übersicht".

**Adaptive Regel für die Ampel-Listen:** ab 900 dp verfügbarer Inhaltsbreite stehen die
drei Stufen nebeneinander (`LayoutBuilder`, drei gleich breite Spalten, Lücke 20), darunter
untereinander mit 20 dp Abstand. Maßgeblich ist die Breite des Inhaltsbereichs, nicht die
des Fensters — im Zweispalten-Layout ist die Seitenleiste schon abgezogen.

### S5 Vereinsangaben (`/verein`)

Titel = Vereinsname (Jost 26/300) + Erläuterungssatz · `PwContactList` · Abschnitt „Externe
Beratung" (Karten mit Kreis-Icon `life-buoy`, Titel, Zusatz, Nummer in Mono) · getönte Karte
„Was gespeichert wird". Footer: `secondary` „Zurück zur Übersicht", **keine HelpBar** (die
Beratungsangebote stehen hier schon im Inhalt).

### S6 Hilfe-Sheet

Titel „Hilfe und Beratung" + Untertitel · Beratungskarten · `PwContactList` · Hinweissatz ·
`secondary` „Zurück zum Szenario". Erreichbar von jedem Screen über die HelpBar, ohne den
Durchlauf zu verlassen: Zustand des Szenarios bleibt vollständig erhalten.

### S7 Info-Sheet („So funktioniert Pathwise")

Dieselben sechs Info-Blöcke wie die Erststart-Karte, dazu der Hinweis „Pathwise ersetzt keine
Beratung …", ein Textlink zur Rückmeldung und `secondary` „Verstanden".

### S8 Rückmeldungs-Sheet

Zwei Auswahlkacheln („Rückmeldung zur App" / „Situation einschicken"; gewählt =
`surfaceTint` + Rand `borderFocus`), `PwField` + `PwTextarea` (4 bzw. 6 Zeilen, Label und
Platzhalter wechseln mit der Art), `PwField` + `PwInput` für die freiwillige E-Mail,
getönter Hinweisblock, `accent`-Button „Abschicken" (disabled bei leerem Text).
Nach dem Senden tauscht der Sheet-Inhalt (M23) gegen die Bestätigung „Angekommen" mit
Kreis-Icon `check` in `levelOk` und `secondary` „Schließen".
**Fehlerfall:** Senden schlägt fehl → Fehlertext unter dem Textfeld („Das hat gerade nicht
geklappt. Der Text bleibt stehen, versuch es später noch einmal."), Button verlässt den
`loading`-Zustand, Eingaben bleiben erhalten.

### S9 „Kommt bald"-Dialog

Zentriert, maximal 400 dp breit, Radius 20: Ringanimation (M17–M19) mit Modul-Icon,
Mikro-Label Modulname, „Kommt bald" (Jost 25/300), Erklärtext, drei pulsierende Punkte,
`secondary` „Zurück zur Übersicht".

### Responsive-Regeln (gelten für alle Screens)

| Breite | Layout |
|---|---|
| < 360 dp | Seitenpolster 12, Footer-Buttons untereinander, Kartenraster einspaltig |
| 360–599 dp | Standard: Seitenpolster 16, eine Spalte, Inhalt volle Breite |
| 600–899 dp | Seitenpolster 24, Inhalt zentriert auf 640 dp, Szenarioraster zweispaltig |
| ≥ 900 dp | Zweispalten-Layout: links eine 300 dp breite Seitenleiste (Logo, Zahnrad, Szenarienliste, HelpBar, Info- und Rückmeldungs-Link, Hinweiszeile), rechts der Screen ohne Logo und Zahnrad in der Kopfzeile; Ampel-Listen dreispaltig |

Die Seitenleiste ersetzt keine Navigation, sie spiegelt sie: dieselben Ziele, dieselben
Zustandstexte („Noch nicht bearbeitet" / „Angefangen" / „Abgeschlossen").
Textskalierung bis 200 % muss ohne Überlauf funktionieren — keine festen Höhen an
Textcontainern, Buttons wachsen mit (`minimumSize`, nicht `fixedSize`).

---

## 8. Zustand und Persistenz

```dart
class DurchlaufState {
  final int szenarioIndex;
  final int punktIndex;                       // 0..2
  final Map<String, String> wahlen;           // "szIndex:punktIndex" -> "a"|"b"|"c"
  final Set<int> begonnen;
  final bool einordnungOffen;                 // FeedbackPanel je Punkt
  final bool situationOffen;                  // Aufklappfeld je Punkt
  final int? spiegelOffen;                    // welcher Spiegel-Block aufgeklappt ist
  final String themenfeldFilter;              // "Alle" oder Themenfeldname
}
```

- Zustandsverwaltung frei wählbar (Riverpod passt); wichtig ist nur, dass Wahlen und
  Fortschritt einen App-Neustart überleben.
- **Lokal** (`shared_preferences` oder `sqflite`): `wahlen`, `begonnen`, letzter Punkt je
  Szenario, `erststartGesehen`, `themeMode`. Kein Konto, keine Cloud-Sicherung, kein
  Analytics-SDK.
- **Zentral** (einziger Netzaufruf): je Entscheidungspunkt und Handlungsoption ein
  Zählwert `POST /zaehlwert {punktId, optionId}` beim Wählen, `GET /spiegel/:szenarioId`
  für die Auswertung. Ohne Gerätekennung, ohne Zeitstempel im Klartext, ohne Sitzungs-ID.
- Netzfehler sind nie blockierend: die Auswertung erscheint auch ohne Spiegelwerte
  (siehe 4.10 Error).
- Statusableitung: kein Eintrag → „Noch nicht bearbeitet"; mindestens eine Wahl → „Angefangen";
  Wahl am letzten Punkt vorhanden → „Abgeschlossen".
- „Nochmal" löscht nur die Wahlen dieses Szenarios und setzt auf den Einstieg zurück.
- Szenariodaten liegen als Asset-JSON (`assets/szenarien.json`) im Bündel, Struktur wie in
  `PathwiseApp.dc.html` (`SZENARIEN`): `id, titel, themenfeld, kurz, rahmen[], vorgeschichte,
  ausgangssituation, punkte[{text, leitfrage, optionen[3], anteile?, zuWenige?, erkennen,
  absichern, handeln}], merkmale[{text, stufe: ok|check|viol, nichtEingetreten?}]`.

---

## 9. Barrierefreiheit

- Trefferflächen mindestens 44 dp, auch bei 30 dp großen Icon-Buttons.
- Jede Farbaussage trägt zusätzlich Text und Icon (Ampelstufen, Szenariostatus).
- Fokusring nie entfernen: 3 dp `focusRing` — die App wird auch von Personen bedient, die
  selten Apps benutzen.
- Semantik: Optionen als `Semantics(button, selected)`; die Schrittanzeige liefert
  „Entscheidungspunkt 2 von 3"; das Aufklappfeld liefert `expanded`.
- Textskalierung bis 200 %; `MediaQuery.textScalerOf(context)` nicht deckeln.
- `disableAnimations` schaltet alle Bewegung ab (siehe Motion-Spec).
- Kontrast: Fließtext mindestens 4,5:1. Auf getönten Flächen ausschließlich `textOnTint`
  und `textOnTintMuted` verwenden, nie die Basisrampen — sonst bricht der Kontrast im
  dunklen Modus.

---

## 10. Assets

| Asset | Herkunft | Verwendung |
|---|---|---|
| `assets/logo-mark.png` | Design System | Kopfzeile Übersicht (28 dp), Seitenleiste (26 dp) |
| `assets/logo-wordmark.png`, `logo-lockup.png` | Design System | derzeit ungenutzt; für Splash/Store |
| Icons | Lucide 0.441.0 | `lucide_icons_flutter` oder die benötigten SVGs als Asset |

Verwendetes Icon-Vokabular: `chevron-left/right/up/down`, `check`, `rotate-ccw`, `book-open`,
`eye`, `shield`, `footprints`, `circle-check`, `circle-help`, `circle-alert`, `users`, `user`,
`user-x`, `mail`, `phone`, `life-buoy`, `settings`, `plus`, `info`, `corner-down-right`,
`arrow-right`, `arrow-up-right`, `list-checks`, `x`, `file-text`, `message-square`,
`smartphone`, `eye-off`, `flag`, `loader-circle`.
Icongrößen: 16 im Text, 18 in Bedienelementen, 20–24 einzeln stehend. Keine Emoji, keine
gefüllten Icon-Sätze mischen, keine eigenen SVGs zeichnen.

---

## 11. Offene Punkte — noch nicht designt oder nicht entschieden

**Gestaltung fehlt vollständig:**

1. **Splash- und App-Icon.** Das Logo liegt nur als flächiges JPG auf Weiß vor: keine
   Transparenz, kein Vektor, keine Negativvariante. Die Marke kann derzeit nicht auf Navy
   stehen. Ein adaptives Android-Icon und die iOS-Icon-Sätze fehlen.
2. **Onboarding jenseits der Erststart-Karte** (Sprachwahl, Vereinszuordnung) — nicht entworfen.
   Wie ein Gerät überhaupt „seinen" Verein erfährt (Einladungslink? Code? feste Build-Variante?),
   ist offen und betrifft die Vereinsangaben und den Einschätzungsspiegel.
3. **Vereinsangaben pflegen.** Der Screen zeigt die Daten nur an. Woher sie kommen und wie
   der Verein sie ändert, ist nicht designt.
4. **Ladezustände beim ersten Start** (Szenariodaten aus dem Netz statt aus dem Asset) —
   es gibt bisher keinen Skeleton-, Spinner- oder Leerzustand für die Übersicht.
5. **Offline-Zustand.** Kein Banner, kein Hinweis entworfen. Vorschlag: still bleiben, nur
   der Spiegel zeigt seinen Empty-State.
6. **Fehler-Screen** für unerwartete Ausnahmen (Crash-Fallback) — nicht entworfen.
7. **Einstellungen** über Theme hinaus (Textgröße, Sprache, Daten löschen). Besonders
   „Alle lokalen Daten löschen" fehlt und ist datenschutzrechtlich wahrscheinlich nötig.
8. **Suche und Sortierung** in der Szenarioliste — bei drei Szenarien unnötig, ab etwa
   zehn nicht mehr.
9. **Die drei Module** unter „Weitere Bereiche" (Elterngespräche, Wettkampf und Fahrten,
   Schutzkonzept) existieren nur als „Kommt bald"-Kachel.
10. **Push, Widgets, Deeplinks, Tablet-Landscape über 900 dp hinaus, Web-Fassung** —
    alles außerhalb des bisherigen Entwurfs.

**Inhaltlich zu klären (nicht Entwicklungsaufgabe, aber blockierend für den Einsatz):**

11. **Alle Szenariotexte sind erfunden und fachlich ungeprüft.** Vor jeder Verwendung im
    Verein durch den Kinderschutzbeauftragten prüfen lassen.
12. **Schriften.** Jost und Nunito Sans stehen für die tatsächliche Wortmarken-Schrift ein
    (geometrische Sans, Century-Gothic-/Futura-Familie). Bei Lizenzdateien werden die
    `fontFamily`-Werte getauscht — sonst ändert sich nichts.
13. **Icons.** Lucide ist ein Substitut für einen nicht definierten Satz.
14. **Anrede „du"** und die Themenfeld-Bezeichnungen sind Vorschläge.
15. **Endpunkte und Datenschema** des Zählwert-Backends sind nicht spezifiziert; die
    Aufrufe in Abschnitt 8 sind ein Vorschlag.
16. **Rechtstexte** (Impressum, Datenschutzerklärung, Barrierefreiheitserklärung) fehlen —
    Platz dafür ist in den Vereinsangaben oder im Info-Sheet.

---

## 12. Reihenfolge für die Umsetzung

1. Tokens, Theme, `PwColors`-Extension, Schriften einbinden — sichtbares Ergebnis: eine
   leere Seite in der richtigen Farbe und Schrift, Light und Dark umschaltbar.
2. `PwScaffold` (Kopfzeile, Inhaltsbreite, Fußzeile, HelpBar) + Übersicht mit statischen
   Daten aus `assets/szenarien.json`.
3. Kernkomponenten in dieser Reihenfolge: `PwButton`, `PwCard`, `PwTag`, `PwStepIndicator`,
   `PwSituationText`, `PwDecisionPoint`, `PwFeedbackPanel`.
4. Durchlauf: Einstieg → drei Punkte → Auswertung, inklusive Transitions M4/M5/M6/M12.
5. Auswertung: `PwLevelList`, `PwMirrorBar`, `PwContactList` + Staffelanimationen M21/M22.
6. Overlays: Hilfe, Info, Rückmeldung, „Kommt bald".
7. Persistenz und Zählwert-Anbindung.
8. Zweispalten-Layout ab 900 dp, Textskalierung, `disableAnimations`, Semantik.
</content>

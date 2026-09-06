// Pathwise Design Tokens — generiert aus dem Design System.
// Siehe DESIGN.md, Abschnitt 2.

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


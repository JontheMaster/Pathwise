// Pathwise ThemeData — siehe DESIGN.md, Abschnitt 3.
import 'package:flutter/material.dart';
import 'pathwise_tokens.dart';

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


extension PwThemeX on BuildContext {
  PwColors get pw => Theme.of(this).extension<PwColors>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

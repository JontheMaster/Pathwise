# Handoff: Pathwise — Flutter-App

## Überblick

Pathwise ist ein szenariobasiertes Lernformat für ehrenamtliche Trainerinnen und Trainer im
Sportverein. Ein Durchlauf dauert höchstens fünf Minuten: Situation lesen, an drei
Entscheidungspunkten je eine von drei Handlungsoptionen wählen, auf Abruf eine dreiteilige
fachliche Rückmeldung lesen, am Ende die Ampel-Einordnung der Situationsmerkmale, den
Einschätzungsspiegel des Trainerteams und die Ansprechpersonen des Vereins sehen.

Ziel dieses Bündels: eine Flutter-App (iOS und Android, adaptiv bis Tablet) aus den
vorliegenden Entwürfen bauen.

## Zu den Design-Dateien

Die HTML-Dateien in diesem Bündel sind **Design-Referenzen**, keine Produktionsvorlage zum
Kopieren. Sie zeigen Aussehen, Zustände und Bewegung im Browser. Die Aufgabe ist, diese
Entwürfe in Flutter **nachzubauen** — mit Flutter-Widgets, Flutter-Animationen und den in
`DESIGN.md` festgelegten Dart-Konstanten, nicht mit einem WebView und nicht durch CSS-Portierung.

## Fidelity

**Hi-fi.** Farben, Typografie, Abstände, Radien, Schatten, Timings und Curves sind final und in
`DESIGN.md` exakt angegeben. Die Szenario-**Inhalte** sind erfunden und fachlich ungeprüft.

## Was wo liegt

| Datei | Inhalt |
|---|---|
| `DESIGN.md` | **Das Referenzdokument.** Tokens, ThemeData, Komponenten mit States, Motion-Spec, Navigation, alle Screens, offene Punkte. Gehört ins Repo-Root, damit beim Bauen jedes Screens dort nachgeschlagen wird statt im Chatverlauf. |
| `lib/design/pathwise_tokens.dart` | Farben (Light/Dark als `ThemeExtension`), Spacing, Radius, Größen, Schatten, Dauern, Curves |
| `lib/design/pathwise_theme.dart` | `pwTheme(dark: bool)` mit `ColorScheme`, `TextTheme` und Widget-Themes; `context.pw` |
| `lib/design/pathwise_routes.dart` | `PwTransition` + `pwRoute` — die sechs Page-Transitions der App |
| `assets/szenarien.json` | Die drei Szenarien, Info-Blöcke, Beratungsstellen, Ansprechpersonen, Module |
| `PathwiseApp.dc.html` | Interaktiver Prototyp: alle Screens, alle Übergänge, Light und Dark |
| `Pathwise Geräte.dc.html` | Responsive-Ansicht Handy → Desktop, maßstabsgerecht |

Die Prototypen brauchen den Ordner `_ds/` und `assets/` aus dem Projekt; ohne sie starten sie
nicht. Zum reinen Nachschlagen genügt `DESIGN.md`.

## Erste Schritte

1. `DESIGN.md` ins Repo-Root legen.
2. `lib/design/*.dart` übernehmen, Schriften (Jost, Nunito Sans, JetBrains Mono) und
   Lucide-Icons in `pubspec.yaml` eintragen.
3. `MaterialApp(theme: pwTheme(dark: false), darkTheme: pwTheme(dark: true),
   themeMode: ThemeMode.dark)` — **Dark ist der Standard**, nicht `system`.
4. Weiter nach der Reihenfolge in `DESIGN.md`, Abschnitt 12.

## Die fünf Regeln, die man nicht brechen darf

1. Keine Bewertung der Wahl als richtig oder falsch. Keine Punkte, Ränge, Abzeichen, Streaks,
   Fristen, Nachweise.
2. Keine Feier-, Belohnungs- oder Konfettianimation. Kein Sound.
3. Ampelfarben nur für Situationsmerkmale — nie an Buttons, Optionen oder Fortschritt.
4. Kein Konto, kein Personenbezug. Fortschritt bleibt lokal; zentral geht nur ein Zählwert je
   Entscheidungspunkt und Option.
5. Keine Fachbegriffe, keine Emoji, keine Ausrufezeichen, keine Fotos oder Illustrationen.

## Offene Punkte

`DESIGN.md`, Abschnitt 11 — sechzehn Punkte, davon zehn nicht designt (Splash und App-Icon,
Vereinszuordnung, Ladezustände, Offline, Fehler-Screen, Einstellungen, Datenlöschung, Suche,
die drei angekündigten Module, Deeplinks) und sechs inhaltlich zu klären (fachliche Prüfung der
Szenarien, Schriftlizenzen, Icons, Anrede, Backend-Schema, Rechtstexte).
</content>

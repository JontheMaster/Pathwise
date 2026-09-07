# Lottie-Animationen

Hier hinein kommen die `.json`-Dateien aus LottieFiles. Der Ordner ist in
`pubspec.yaml` als Ganzes eingetragen — was hier liegt, ist automatisch mit im
Bündel, ohne dass jemand die pubspec anfassen muss.

## Was gebraucht wird

Vier Stellen, jeweils in der Einstellung **Bewegung → Verspielt**. In den
Vorgaben *Normal* und *Reduziert* läuft nichts davon.

| Datei | Stelle | Was sie zeigen soll |
|---|---|---|
| `auswertung.json` | Kopf der Auswertung, einmal beim Erscheinen | Untersuchen, prüfen, genau hinsehen — eine Lupe oder Ähnliches. **Keine** Feier: an dieser Stelle wird die Situation eingeordnet, nicht eine Leistung belohnt. |
| `angekommen.json` | Rückmeldungs-Sheet, nachdem abgeschickt wurde | Eine Bestätigung: Haken, Briefumschlag, „ist raus". Kurz und ruhig. |
| `kommt-bald.json` | „Kommt bald"-Dialog, in Dauerschleife | Ersetzt die drei pulsierenden Ringe. Darf verspielter sein — der Bildschirm ist ein reiner Platzhalter ohne inhaltliches Gewicht. |
| `abschluss.json` | Szenariokarte auf der Übersicht, beim ersten Abschluss | Ersetzt die eigene Konfetti-Geste. Läuft einmal je Szenario. |

Andere Dateinamen sind kein Problem — leg ab, was du hast, die Zuordnung
übernehme ich.

## Worauf zu achten ist

**Farben.** Die Ampelfarben Grün, Aprikot und Koralle gehören in ihrer
Signalbedeutung allein der Einordnung von Situationsmerkmalen (`DESIGN.md` §1).
Animationen sollten in den Markenfarben der Drei-Bogen-Folge bleiben — Blau,
Koralle, Aprikot als *Schmuck*, nicht als Ampel. Am besten wirken zurückhaltende,
möglichst einfarbige Animationen.

**Keine Figuren.** `DESIGN.md` §1 schließt Fotos, Illustrationen und Figuren
aus. Abstrakte Formen und Symbole passen, gezeichnete Menschen nicht.

**Größe.** Unter 100 KB je Datei. Lottie-Exporte mit eingebetteten Bildern
(Base64) werden schnell mehrere Megabyte groß — solche bitte nicht.

**Dauer.** Eine bis zwei Sekunden. Nur `kommt-bald.json` läuft in Schleife.

## Lizenzen

Für jede Datei brauche ich die Lizenz, damit sie in der README stehen kann.
Auf LottieFiles steht sie auf der Seite der Animation:

- **Lottie Simple License (FL 9.13.21)** — frei nutzbar, auch kommerziell, ohne
  Namensnennung. Unproblematisch.
- **CC BY** und Ähnliches — Namensnennung nötig. Geht, muss aber vermerkt
  werden.
- **Nur für den persönlichen Gebrauch** — für ein veröffentlichtes Projekt
  nicht verwendbar.

Trag die Quelle am besten hier ein, sobald du eine Datei ablegst:

| Datei | Quelle (URL) | Urheber | Lizenz |
|---|---|---|---|
| | | | |

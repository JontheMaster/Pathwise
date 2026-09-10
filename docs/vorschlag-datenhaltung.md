# Vorschlag: Szenarien und Vereinsangaben aus der Datenbank, dazu ein Dashboard

**Stand 10. September 2026 — als Vorschlag geschrieben.**

> **Was daraus geworden ist:** Die Phasen 1 bis 3 sind gebaut und in Betrieb —
> Vereinsangaben über einen Vereinscode
> ([`0002_vereine.sql`](../supabase/migrations/0002_vereine.sql)) und Szenarien mit Entwürfen
> und Fassungen ([`0003_szenarien.sql`](../supabase/migrations/0003_szenarien.sql)). Das
> Dashboard (Phase 4) steht noch aus. Wo dieses Papier und das SQL auseinandergehen, gilt das
> SQL; die kurze Fassung steht im [README](../README.md#backend). Dieser Text bleibt als
> Begründung stehen, warum es so und nicht anders aufgebaut ist.

Zwei Wünsche hängen zusammen und werden hier gemeinsam beantwortet:

1. Die **Vereinsangaben** sollen zentral liegen. Eine Person ändert sie, alle im Verein sehen
   die neuen.
2. Die **Szenarien** sollen aus der Datenbank kommen, damit Aktualisierungen beim Öffnen der App
   ankommen. Verwaltet werden sie über eine **eigene Admin-Website**, die nur läuft, wenn du sie
   startest.

---

## 1. Was heute da ist

| Wo | Was | Wie aktualisiert |
|---|---|---|
| `assets/szenarien.json` im App-Bündel | Szenarien, Info-Blöcke, Beratungsstellen, **Ansprechpersonen**, Vereinsname | Nur durch ein neues App-Update |
| Supabase `zaehlwerte` | Zählwert je Szenario, Entscheidungspunkt, Option | Die App zählt hoch |
| Supabase `rueckmeldungen` | Freitext aus dem Rückmeldungs-Sheet | Die App schreibt, niemand liest |

Die Vereinsangaben stecken also im Bündel. Eine Änderung bedeutet heute: neue APK bauen und an
alle verteilen. Genau das soll weg — und genau das führt `DESIGN.md` §11 als Punkt 3 auf
(„Vereinsangaben pflegen. Der Screen zeigt die Daten nur an.").

### Ein Fund, der vorher geklärt werden sollte

Die Auswertung sagt: **„So haben die Trainerinnen und Trainer deines Vereins entschieden."**

Die Tabelle `zaehlwerte` kennt aber keinen Verein. Sie zählt über *alle* Geräte hinweg, die die
App benutzen. Solange nur ein Verein sie nutzt, stimmt der Satz zufällig. Sobald ein zweiter
dazukommt, stimmt er nicht mehr — und das ist keine Kleinigkeit, weil der Einschätzungsspiegel
seinen Zweck („Anlass für ein Gespräch im Trainerteam", Grundfunktion 5) nur mit den Zahlen des
eigenen Teams erfüllt.

Sobald es Vereine als Datensatz gibt, lässt sich das mitlösen. Vorher geht es nicht.

---

## 2. Die Kernfrage: Woher weiß ein Gerät, zu welchem Verein es gehört?

Ohne diese Antwort funktioniert nichts davon — weder vereinsbezogene Angaben noch ein
vereinsbezogener Spiegel. `DESIGN.md` §11 führt das als Punkt 2 und lässt es offen:
*„Wie ein Gerät überhaupt ‚seinen' Verein erfährt (Einladungslink? Code? feste Build-Variante?),
ist offen."*

Drei Wege, mit Bewertung:

| Weg | Wie es sich anfühlt | Dagegen |
|---|---|---|
| **Vereinscode** — beim ersten Start ein kurzer Code, z. B. `POSTSV-2026` | Eine Eingabe, einmalig, kein Konto, passt zu „ohne Anmeldung" | Der Code muss verteilt werden (Aushang, Trainerchat) |
| **Einladungslink** — `pathwise.app/v/postsv` öffnet die App vorbelegt | Bequemer, ein Klick | Braucht Deeplinks, die es noch nicht gibt (`DESIGN.md` §11, Punkt 10) — und für den Web-Zugang ohnehin einen Link |
| **Eigener Build je Verein** | Nichts einzugeben | Pro Verein eine App im Store; skaliert nicht |

**Empfehlung: Vereinscode**, mit dem Einladungslink als späterem Zusatz, der denselben Code
setzt. Der Code ist kein Geheimnis — wer ihn hat, sieht die Ansprechpersonen des Vereins. Die
sind ohnehin nicht vertraulich (der Kinderschutzbeauftragte steht im Schutzkonzept). Es ist
**kein Login** und darf auch nicht als solches wirken.

Kein Verein eingetragen? Dann bleibt die App bei den gebündelten Angaben und zeigt den Spiegel
mit dem Empty-State. Nichts blockiert.

---

## 3. Datenmodell

Vier neue Tabellen, zwei Änderungen an bestehenden.

### Vereine und ihre Angaben

```sql
create table vereine (
  id           uuid primary key default gen_random_uuid(),
  code         text unique not null,     -- was im Gerät eingegeben wird
  name         text not null,            -- "Post SV Nürnberg"
  aktiv        boolean not null default true,
  erstellt_am  timestamptz not null default now()
);

create table ansprechpersonen (
  id           uuid primary key default gen_random_uuid(),
  verein_id    uuid not null references vereine(id) on delete cascade,
  name         text not null,
  rolle        text not null,
  kontakt      text not null,
  kontaktart   text not null check (kontaktart in ('mail', 'telefon')),
  reihenfolge  smallint not null default 0
);

-- Beratungsstellen: verein_id null heißt "gilt für alle".
-- So bleiben Hilfetelefon und Nummer gegen Kummer zentral, ein Verein kann
-- aber eine regionale Stelle ergänzen.
create table beratungsstellen (
  id           uuid primary key default gen_random_uuid(),
  verein_id    uuid references vereine(id) on delete cascade,
  titel        text not null,
  zusatz       text not null,
  nummer       text not null,
  reihenfolge  smallint not null default 0
);
```

### Szenarien

```sql
create table szenarien (
  id               text primary key,        -- "heimspiel", bleibt lesbar
  titel            text not null,
  themenfeld       text not null,
  kurz             text not null,
  dauer            text,
  status           text not null default 'entwurf'
                     check (status in ('entwurf', 'veroeffentlicht', 'archiviert')),
  reihenfolge      smallint not null default 0,
  -- verein_id null heißt: für alle Vereine. Ein Verein kann eigene ergänzen.
  verein_id        uuid references vereine(id) on delete cascade,
  inhalt           jsonb not null,          -- rahmen, vorgeschichte,
                                            -- ausgangssituation, punkte, merkmale
  version          integer not null default 1,
  aktualisiert_am  timestamptz not null default now()
);
```

**Warum der Inhalt als JSONB und nicht in eigenen Tabellen?** Die App parst heute schon genau
diese Struktur aus dem Bündel — `PwSzenario.ausJson` bliebe unverändert. Die Felder, nach denen
man *sortiert, filtert und veröffentlicht* (Titel, Themenfeld, Status), stehen als eigene
Spalten daneben, sodass Listen und Rechte ohne JSON-Gefummel funktionieren.

Die Alternative — `punkte`, `optionen`, `merkmale` als eigene Tabellen — wäre sauberer für
Fremdschlüssel und Validierung, kostet aber vier zusätzliche Tabellen und Joins für einen
Bestand von momentan drei Szenarien. Falls die Zählwerte später auf echte Options-Zeilen
verweisen sollen, wäre das der Zeitpunkt zum Umbau.

### Zwei Änderungen an Bestehendem

```sql
-- Der Spiegel wird vereinsbezogen — siehe den Fund oben.
alter table zaehlwerte add column verein_id uuid references vereine(id);
-- Neuer Primärschlüssel: (verein_id, szenario_id, punkt_index, option_id)

-- Wenn Szenarien bearbeitbar werden, ist "genau drei Punkte" keine feste
-- Größe mehr. Der Check 0..2 muss weg oder weiter gefasst werden.
alter table zaehlwerte drop constraint zaehlwerte_punkt_index_check;

-- Damit im Dashboard sichtbar ist, aus welchem Verein eine Rückmeldung kam.
alter table rueckmeldungen add column verein_id uuid references vereine(id);
alter table rueckmeldungen add column bearbeitet boolean not null default false;
```

> Zur Rückmeldung mit `verein_id`: bei einem kleinen Verein grenzt die Angabe den Kreis der
> möglichen Absender ein. Das steht dem Versprechen „anonym, auch gegenüber dem Verein" nicht
> entgegen, solange nur du als Betreiber sie siehst und nicht der Verein — aber es ist eine
> Abwägung, die du treffen solltest, keine Selbstverständlichkeit.

---

## 4. Wie die App an die Daten kommt

Der bestehende Grundsatz gilt weiter: **Netzfehler blockieren nie** (`DESIGN.md` §8), und für
einen Ladezustand auf der Übersicht gibt es keinen Entwurf (§11, Punkt 4). Daraus folgt eine
Reihenfolge:

```
1. App startet  →  Inhalt aus dem lokalen Zwischenspeicher, sonst aus dem Bündel
2. Übersicht steht sofort, ohne auf das Netz zu warten
3. Im Hintergrund: veröffentlichte Szenarien und Vereinsangaben abrufen
4. Etwas Neues dabei  →  in den Zwischenspeicher schreiben
5. Wirksam beim nächsten Start — oder sofort, wenn gerade kein Durchlauf läuft
```

Das gebündelte `assets/szenarien.json` **bleibt** als unterste Rückfallebene: beim allerersten
Start ohne Netz muss die App etwas zu zeigen haben.

**Ein Fall, der bedacht sein will:** Jemand ist mitten in „Vor dem Heimspiel", und du
veröffentlichst eine geänderte Fassung. Die gespeicherten Entscheidungen hängen an
`szenarioId:punktIndex` — wenn sich die Punkte ändern, passen sie nicht mehr. Vorschlag:
Aktualisierungen greifen nur beim Start, und wenn ein Szenario mit angefangenem Fortschritt eine
neue Version hat, wird dessen Fortschritt zurückgesetzt (dieselbe Wirkung wie „Nochmal"). Der
Alternativweg — die alte Fassung bis zum Abschluss weiterbenutzen — ist freundlicher, aber
deutlich aufwendiger.

---

## 5. Entwürfe und Veröffentlichen

Die Spalte `status` trägt das:

- **Entwurf** — nur im Dashboard sichtbar. Die App bekommt ihn nicht, weil die Rechte ihn gar
  nicht erst herausgeben.
- **Veröffentlicht** — die App zeigt ihn.
- **Archiviert** — verschwindet aus der App, bleibt aber erhalten. Wichtig, weil die Zählwerte
  auf die `szenario_id` verweisen: Löschen würde Geschichte vernichten.

`version` zählt bei jedem Veröffentlichen hoch. Daran erkennt die App, ob sich etwas geändert
hat, ohne den ganzen Inhalt zu vergleichen.

---

## 6. Das Dashboard

### Womit gebaut?

| Weg | Dafür | Dagegen |
|---|---|---|
| **Flutter Web im selben Repo** (`lib/admin/`) | Eine Sprache, dieselben Modelle (`PwSzenario` ist schon geschrieben), dieselben Farben und Schriften, kein zweiter Werkzeugkasten. Start mit `flutter run -d chrome -t lib/admin/main.dart` | Formulare und lange Texte tippen sich in HTML angenehmer als in Flutter Web |
| **Eigene kleine Web-App** (Vite + Svelte oder React) | Formulare und Texteingabe sind die Stärke von HTML | Zweiter Werkzeugkasten, zweiter Abhängigkeitsbaum, Modelle doppelt |
| **Supabase Studio** (die eingebaute Tabellenansicht) | Null Aufwand, sofort da | Verschachteltes JSON von Hand, keine Prüfung, kein Überblick — kein Dashboard |

**Empfehlung: Flutter Web im selben Repo.** Die Modelle und das Aussehen sind schon da, und du
arbeitest weiter in einer Sprache. Bis es steht, ist Supabase Studio der Zwischenweg zum
Datenpflegen.

### „Nicht dauerhaft online"

Genau so ist es gedacht: Das Dashboard läuft **auf deinem Rechner**, gestartet mit einem Befehl,
und redet von dort mit Supabase. Nichts davon ist öffentlich erreichbar. Die einzige öffentliche
Fläche bleibt Supabase selbst — und die ist durch die Rechteregeln geschützt, nicht dadurch,
dass niemand die Adresse kennt.

### Das Passwort

Hier ist eine Unterscheidung wichtig: Ein Passwort, das die Website selbst prüft, wäre
**Theater**. Der Schlüssel für Supabase steckt im ausgelieferten Code; wer ihn nimmt, schreibt an
der Website vorbei direkt in die Datenbank.

Richtig geht es über **Supabase Auth**: du legst einen Benutzer mit E-Mail und Passwort an, das
Dashboard meldet sich damit an, und die Rechteregeln in der Datenbank erlauben das Schreiben nur
diesem Benutzer. Dann ist das Passwort keine Fassade, sondern die eigentliche Schranke.

```sql
-- Wer Admin ist, steht in einer Tabelle - nicht "jeder Angemeldete".
create table admins (
  benutzer_id  uuid primary key references auth.users(id) on delete cascade,
  notiz        text
);
```

### Was darauf zu sehen ist

**Verwalten**

- Szenarien: Liste mit Status, bearbeiten, neu anlegen, duplizieren, veröffentlichen,
  zurückziehen — und eine Vorschau, die aussieht wie in der App
- Vereine: Name, Code, Ansprechpersonen, eigene Beratungsstellen
- Rückmeldungen: lesen und als bearbeitet abhaken *(dafür braucht die Tabelle erstmals ein
  Leserecht — heute kommt niemand an sie heran)*

**Ansehen**

- Wie viele Szenarien veröffentlicht sind, wie viele als Entwurf liegen
- Durchläufe je Szenario und die Verteilung je Entscheidungspunkt — dieselben Zahlen, die der
  Einschätzungsspiegel zeigt
- Wie viele Rückmeldungen offen sind

**Was bewusst nicht darauf steht:** wie viele *Personen* teilgenommen haben, wer wann etwas
gemacht hat, oder irgendetwas, das auf ein Gerät zurückführt. Das ist keine technische Grenze,
sondern die Zusage aus NF04 und NF11 — und die README nennt es heute schon als offengelegten
Zielkonflikt: *„Der Verein kann nicht erheben, wie viele Trainerinnen und Trainer teilgenommen
haben."*

---

## 7. Wer darf was

| Rolle | Szenarien | Vereinsangaben | Zählwerte | Rückmeldungen |
|---|---|---|---|---|
| **App** (`anon`) | nur `veroeffentlicht` lesen | lesen | über die Funktionen hochzählen und lesen | nur schreiben |
| **Dashboard** (Admin) | alles lesen und schreiben | alles lesen und schreiben | lesen | lesen und abhaken |

Die bisherige Linie bleibt: Direktzugriff auf `zaehlwerte` ist für die App gesperrt, gearbeitet
wird über `zaehlwert_erhoehen` und `spiegel`. Beide bekommen einen Parameter `verein_id`.

---

## 8. In welcher Reihenfolge

Jeder Schritt ist für sich lauffähig — nach jedem funktioniert die App weiter.

| # | Schritt | Ergebnis |
|---|---|---|
| 1 | Tabellen `vereine`, `ansprechpersonen`, `beratungsstellen`; Vereinscode in der App; Angaben werden abgerufen | Du änderst eine Telefonnummer, alle sehen sie beim nächsten Start |
| 2 | `verein_id` in `zaehlwerte`, Funktionen erweitern | Der Spiegel zeigt endlich den eigenen Verein — das Versprechen aus der Auswertung stimmt |
| 3 | Tabelle `szenarien`, App holt sie beim Start, Bündel bleibt Rückfallebene | Neue Szenarien ohne App-Update |
| 4 | Dashboard: Anmeldung, Szenarienverwaltung mit Entwürfen, Vereinsangaben, Rückmeldungen, Zahlen | Du verwaltest alles selbst |

Schritt 1 und 2 gehören zusammen — beide hängen daran, dass es Vereine als Datensatz gibt.
Schritt 3 geht auch ohne Dashboard (Pflege übergangsweise im Supabase Studio). Schritt 4 ist der
größte, aber der am wenigsten riskante: er ändert nichts an der App.

---

## 9. Was dabei zu bedenken ist

**Ein Supabase-Projekt im kostenlosen Tarif pausiert nach einer Woche ohne Zugriff.** Wird die
App in einem Verein selten benutzt, kann das Projekt einschlafen — die App fällt dann auf
Zwischenspeicher und Bündel zurück, bleibt also bedienbar, aber Spiegel und Aktualisierungen
fehlen, bis das Projekt wieder geweckt wird. Für einen Prototyp verkraftbar, für den Dauerbetrieb
ein Argument für den bezahlten Tarif.

**Der Vereinscode ist kein Login.** Er ordnet ein Gerät einem Verein zu, mehr nicht. Wer ihn hat,
sieht die Ansprechpersonen und die Zahlen des Vereins. Das sollte man wissen, bevor man ihn
irgendwo aushängt.

**Aus einer Datei werden Datensätze.** Heute liegt der ganze Inhalt in einer versionierten Datei
im Git — nachvollziehbar, wiederherstellbar, überprüfbar. In der Datenbank ist das weg, wenn
niemand sich darum kümmert. Vorschlag: das Dashboard bekommt einen Ausfuhr-Knopf, der den
aktuellen Stand als `szenarien.json` herunterlädt. Damit bleibt der Weg zurück offen — und die
gebündelte Rückfallebene lässt sich aktuell halten.

**Die Inhalte bleiben fachlich ungeprüft.** `DESIGN.md` §11, Punkt 11: alle Szenariotexte sind
erfunden. Ein Dashboard macht das Ändern leichter — es ersetzt aber nicht, dass der
Kinderschutzbeauftragte draufschaut, bevor etwas veröffentlicht wird. Vielleicht gehört genau
das als Schritt in den Veröffentlichungsweg: ein Feld „geprüft von / am".

---

## 10. Was ich von dir brauche

1. **Vereinscode als Weg** — einverstanden, oder lieber Einladungslink?
2. **Dashboard als Flutter Web im selben Repo** — oder doch eine eigene Web-App?
3. **Supabase Auth mit einem Admin-Benutzer** — brauchst du später mehrere Admins, etwa einen je
   Verein, der nur seine eigenen Angaben ändern darf?
4. **Szenarien je Verein oder für alle?** Der Vorschlag erlaubt beides (`verein_id` darf leer
   sein). Ist das gewollt, oder sind Szenarien immer für alle?
5. **Reihenfolge** — bei 1 anfangen, oder ist dir das Dashboard wichtiger als der
   vereinsbezogene Spiegel?

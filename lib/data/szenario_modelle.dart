// Datenmodelle zu assets/szenarien.json — Struktur wie in PathwiseApp.dc.html
// (SZENARIEN, INFOS, BERATUNG, MODULE, PERSONEN, VEREIN), siehe DESIGN.md 8.
import 'package:flutter/foundation.dart';

/// Ampelstufe eines Situationsmerkmals. Die Farben dieser Stufen gehoeren
/// ausschliesslich der Einordnung von Merkmalen — nie Buttons, Optionen,
/// Fortschritt (DESIGN.md 1).
enum PwStufe {
  unbedenklich('ok', 'Unbedenklich'),
  klaerungsbeduerftig('check', 'Klärungsbedürftig'),
  grenzverletzend('viol', 'Grenzverletzend');

  const PwStufe(this.schluessel, this.label);
  final String schluessel;
  final String label;

  static PwStufe vonSchluessel(String s) =>
      values.firstWhere((e) => e.schluessel == s, orElse: () => unbedenklich);
}

@immutable
class PwOption {
  const PwOption({required this.id, required this.text});
  final String id; // "a" | "b" | "c"
  final String text;

  factory PwOption.ausJson(Map<String, dynamic> j) =>
      PwOption(id: j['id'] as String, text: j['text'] as String);
}

@immutable
class PwMerkmal {
  const PwMerkmal({
    required this.text,
    required this.stufe,
    required this.nichtEingetreten,
  });

  final String text;
  final PwStufe stufe;
  final bool nichtEingetreten;

  /// Der Nachsatz haengt am Text, und das Merkmal behaelt die Farbe seiner
  /// Ampelstufe — so macht es der Prototyp (PathwiseApp.dc.html Z. 811-814) mit
  /// der Begruendung, dass grenzverletzende Merkmale auch dann rot bleiben
  /// muessen, wenn sie in diesem Durchlauf nicht eingetreten sind.
  String get anzeigetext => nichtEingetreten
      ? '$text — in diesem Durchlauf nicht eingetreten, hier würde die Situation kippen.'
      : text;

  factory PwMerkmal.ausJson(Map<String, dynamic> j) => PwMerkmal(
        text: j['text'] as String,
        stufe: PwStufe.vonSchluessel(j['stufe'] as String),
        nichtEingetreten: j['nichtEingetreten'] == true,
      );
}

@immutable
class PwPunkt {
  const PwPunkt({
    required this.text,
    required this.leitfrage,
    required this.optionen,
    required this.anteile,
    required this.zuWenige,
    required this.erkennen,
    required this.absichern,
    required this.handeln,
  });

  final String text;
  final String leitfrage;
  final List<PwOption> optionen;

  /// Vorbelegte Anteile aus dem Buendel. Sie greifen nur, solange keine
  /// Zaehlwerte aus Supabase vorliegen (DESIGN.md 4.10 Loading/Error).
  final Map<String, int> anteile;
  final bool zuWenige;

  final String erkennen;
  final String absichern;
  final String handeln;

  factory PwPunkt.ausJson(Map<String, dynamic> j) => PwPunkt(
        text: j['text'] as String,
        leitfrage: j['leitfrage'] as String,
        optionen: (j['optionen'] as List)
            .map((o) => PwOption.ausJson(o as Map<String, dynamic>))
            .toList(growable: false),
        anteile: (j['anteile'] as Map?)
                ?.map((k, v) => MapEntry(k as String, (v as num).toInt())) ??
            const {},
        zuWenige: j['zuWenige'] == true,
        erkennen: j['erkennen'] as String,
        absichern: j['absichern'] as String,
        handeln: j['handeln'] as String,
      );
}

@immutable
class PwSzenario {
  const PwSzenario({
    required this.id,
    required this.titel,
    required this.themenfeld,
    required this.kurz,
    required this.dauer,
    required this.rahmen,
    required this.vorgeschichte,
    required this.ausgangssituation,
    required this.punkte,
    required this.merkmale,
  });

  final String id;
  final String titel;
  final String themenfeld;
  final String kurz;
  final String dauer;
  final List<String> rahmen;
  final String vorgeschichte;
  final String ausgangssituation;
  final List<PwPunkt> punkte;
  final List<PwMerkmal> merkmale;

  List<PwMerkmal> merkmaleDerStufe(PwStufe s) =>
      merkmale.where((m) => m.stufe == s).toList(growable: false);

  /// Der aufklappbare Situationstext im Einschaetzungsspiegel: beim ersten Punkt
  /// die Ausgangssituation, sonst der Punkttext (PathwiseApp.dc.html Z. 915).
  String situationZuPunkt(int i) => i == 0 ? ausgangssituation : punkte[i].text;

  factory PwSzenario.ausJson(Map<String, dynamic> j) => PwSzenario(
        id: j['id'] as String,
        titel: j['titel'] as String,
        themenfeld: j['themenfeld'] as String,
        kurz: j['kurz'] as String,
        dauer: j['dauer'] as String? ?? '',
        rahmen: (j['rahmen'] as List).cast<String>(),
        vorgeschichte: j['vorgeschichte'] as String,
        ausgangssituation: j['ausgangssituation'] as String,
        punkte: (j['punkte'] as List)
            .map((p) => PwPunkt.ausJson(p as Map<String, dynamic>))
            .toList(growable: false),
        merkmale: (j['merkmale'] as List)
            .map((m) => PwMerkmal.ausJson(m as Map<String, dynamic>))
            .toList(growable: false),
      );
}

@immutable
class PwInfo {
  const PwInfo({required this.ikon, required this.titel, required this.text});
  final String ikon;
  final String titel;
  final String text;

  factory PwInfo.ausJson(Map<String, dynamic> j) => PwInfo(
        ikon: j['ikon'] as String,
        titel: j['titel'] as String,
        text: j['text'] as String,
      );
}

@immutable
class PwBeratung {
  const PwBeratung({
    required this.titel,
    required this.zusatz,
    required this.nummer,
  });
  final String titel;
  final String zusatz;
  final String nummer;

  factory PwBeratung.ausJson(Map<String, dynamic> j) => PwBeratung(
        titel: j['titel'] as String,
        zusatz: j['zusatz'] as String,
        nummer: j['nummer'] as String,
      );
}

@immutable
class PwModul {
  const PwModul({
    required this.id,
    required this.ikon,
    required this.titel,
    required this.zusatz,
    required this.text,
  });
  final String id;
  final String ikon;
  final String titel;
  final String zusatz;
  final String text;

  factory PwModul.ausJson(Map<String, dynamic> j) => PwModul(
        id: j['id'] as String,
        ikon: j['ikon'] as String,
        titel: j['titel'] as String,
        zusatz: j['zusatz'] as String,
        text: j['text'] as String,
      );
}

@immutable
class PwPerson {
  const PwPerson({
    required this.name,
    required this.rolle,
    required this.kontakt,
    required this.perTelefon,
  });

  final String name;
  final String rolle;
  final String kontakt;
  final bool perTelefon;

  /// Ziel fuer url_launcher (DESIGN.md 4.11).
  Uri get ziel => perTelefon
      ? Uri(scheme: 'tel', path: kontakt.replaceAll(' ', ''))
      : Uri(scheme: 'mailto', path: kontakt);

  factory PwPerson.ausJson(Map<String, dynamic> j) => PwPerson(
        name: j['name'] as String,
        rolle: j['rolle'] as String,
        kontakt: j['kontakt'] as String,
        perTelefon: j['kontaktart'] == 'telefon',
      );
}

@immutable
class PwInhalt {
  const PwInhalt({
    required this.szenarien,
    required this.infos,
    required this.beratung,
    required this.module,
    required this.personen,
    required this.verein,
  });

  final List<PwSzenario> szenarien;
  final List<PwInfo> infos;
  final List<PwBeratung> beratung;
  final List<PwModul> module;
  final List<PwPerson> personen;
  final String verein;

  /// "Alle" gefolgt von den Themenfeldern in Reihenfolge der Szenarien
  /// (PathwiseApp.dc.html Z. 815).
  List<String> get themenfelder =>
      ['Alle', ...szenarien.map((s) => s.themenfeld)];

  factory PwInhalt.ausJson(Map<String, dynamic> j) => PwInhalt(
        szenarien: (j['szenarien'] as List)
            .map((s) => PwSzenario.ausJson(s as Map<String, dynamic>))
            .toList(growable: false),
        infos: (j['infos'] as List)
            .map((i) => PwInfo.ausJson(i as Map<String, dynamic>))
            .toList(growable: false),
        beratung: (j['beratung'] as List)
            .map((b) => PwBeratung.ausJson(b as Map<String, dynamic>))
            .toList(growable: false),
        module: (j['module'] as List)
            .map((m) => PwModul.ausJson(m as Map<String, dynamic>))
            .toList(growable: false),
        personen: (j['personen'] as List)
            .map((p) => PwPerson.ausJson(p as Map<String, dynamic>))
            .toList(growable: false),
        verein: j['verein'] as String,
      );
}

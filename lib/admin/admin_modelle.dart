// Was das Dashboard sieht — die Zeilen der Datenbank, nicht die Sicht der App.
//
// Die App kennt nur veroeffentlichte Szenarien und bekommt sie fertig geformt
// aus einer Funktion. Das Dashboard sieht die Tabelle: Entwuerfe, Fassungen,
// Zeitstempel. Deshalb eigene Modelle statt PwSzenario.
import 'package:flutter/foundation.dart';

enum AdminStatus {
  entwurf('entwurf', 'Entwurf'),
  veroeffentlicht('veroeffentlicht', 'Veröffentlicht');

  const AdminStatus(this.schluessel, this.label);
  final String schluessel;
  final String label;

  static AdminStatus vonSchluessel(String? s) => values.firstWhere(
        (e) => e.schluessel == s,
        orElse: () => AdminStatus.entwurf,
      );
}

@immutable
class AdminSzenario {
  const AdminSzenario({
    required this.id,
    required this.status,
    required this.reihenfolge,
    required this.fassung,
    required this.signatur,
    required this.inhalt,
    this.aktualisiertAm,
  });

  final String id;
  final AdminStatus status;
  final int reihenfolge;
  final int fassung;
  final String signatur;

  /// Das rohe jsonb. Der Editor arbeitet darauf und laesst unbekannte
  /// Schluessel unangetastet — was heute nicht bearbeitet wird, soll durch
  /// eine Bearbeitung nicht verschwinden.
  final Map<String, dynamic> inhalt;

  final DateTime? aktualisiertAm;

  String get titel => (inhalt['titel'] as String?) ?? '(ohne Titel)';
  String get themenfeld => (inhalt['themenfeld'] as String?) ?? '';
  int get punkteAnzahl => (inhalt['punkte'] as List?)?.length ?? 0;

  factory AdminSzenario.ausZeile(Map<String, dynamic> z) => AdminSzenario(
        id: z['id'] as String,
        status: AdminStatus.vonSchluessel(z['status'] as String?),
        reihenfolge: (z['reihenfolge'] as num?)?.toInt() ?? 0,
        fassung: (z['fassung'] as num?)?.toInt() ?? 1,
        signatur: (z['signatur'] as String?) ?? '',
        inhalt: Map<String, dynamic>.from(z['inhalt'] as Map),
        aktualisiertAm: DateTime.tryParse(z['aktualisiert_am'] as String? ?? ''),
      );

  AdminSzenario copyWith({
    AdminStatus? status,
    int? reihenfolge,
    Map<String, dynamic>? inhalt,
  }) =>
      AdminSzenario(
        id: id,
        status: status ?? this.status,
        reihenfolge: reihenfolge ?? this.reihenfolge,
        fassung: fassung,
        signatur: signatur,
        inhalt: inhalt ?? this.inhalt,
        aktualisiertAm: aktualisiertAm,
      );
}

@immutable
class AdminVerein {
  const AdminVerein({
    required this.id,
    required this.code,
    required this.name,
    required this.aktiv,
    this.personen = const [],
    this.beratung = const [],
  });

  final String id;
  final String code;
  final String name;
  final bool aktiv;
  final List<AdminPerson> personen;

  /// Nur die Stellen dieses Vereins. Die bundesweiten liegen ohne verein_id
  /// und werden getrennt gefuehrt.
  final List<AdminBeratung> beratung;

  factory AdminVerein.ausZeile(Map<String, dynamic> z) => AdminVerein(
        id: z['id'] as String,
        code: z['code'] as String,
        name: z['name'] as String,
        aktiv: z['aktiv'] as bool? ?? true,
      );

  AdminVerein mit({
    List<AdminPerson>? personen,
    List<AdminBeratung>? beratung,
  }) =>
      AdminVerein(
        id: id,
        code: code,
        name: name,
        aktiv: aktiv,
        personen: personen ?? this.personen,
        beratung: beratung ?? this.beratung,
      );
}

@immutable
class AdminPerson {
  const AdminPerson({
    required this.id,
    required this.vereinId,
    required this.name,
    required this.rolle,
    required this.kontakt,
    required this.perTelefon,
    required this.reihenfolge,
  });

  final String? id;
  final String vereinId;
  final String name;
  final String rolle;
  final String kontakt;
  final bool perTelefon;
  final int reihenfolge;

  factory AdminPerson.ausZeile(Map<String, dynamic> z) => AdminPerson(
        id: z['id'] as String?,
        vereinId: z['verein_id'] as String,
        name: z['name'] as String,
        rolle: z['rolle'] as String,
        kontakt: z['kontakt'] as String,
        perTelefon: z['kontaktart'] == 'telefon',
        reihenfolge: (z['reihenfolge'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> zuZeile() => {
        if (id != null) 'id': id,
        'verein_id': vereinId,
        'name': name,
        'rolle': rolle,
        'kontakt': kontakt,
        'kontaktart': perTelefon ? 'telefon' : 'mail',
        'reihenfolge': reihenfolge,
      };
}

@immutable
class AdminBeratung {
  const AdminBeratung({
    required this.id,
    required this.vereinId,
    required this.titel,
    required this.zusatz,
    required this.nummer,
    required this.reihenfolge,
  });

  final String? id;

  /// Null heisst: gilt fuer alle Vereine.
  final String? vereinId;

  final String titel;
  final String zusatz;
  final String nummer;
  final int reihenfolge;

  bool get bundesweit => vereinId == null;

  factory AdminBeratung.ausZeile(Map<String, dynamic> z) => AdminBeratung(
        id: z['id'] as String?,
        vereinId: z['verein_id'] as String?,
        titel: z['titel'] as String,
        zusatz: z['zusatz'] as String? ?? '',
        nummer: z['nummer'] as String,
        reihenfolge: (z['reihenfolge'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> zuZeile() => {
        if (id != null) 'id': id,
        'verein_id': vereinId,
        'titel': titel,
        'zusatz': zusatz,
        'nummer': nummer,
        'reihenfolge': reihenfolge,
      };
}

@immutable
class AdminRueckmeldung {
  const AdminRueckmeldung({
    required this.id,
    required this.art,
    required this.text,
    required this.email,
    required this.bearbeitet,
    required this.erstelltAm,
    this.vereinId,
  });

  final String id;

  /// 'feedback' oder 'szenario'.
  final String art;

  final String text;
  final String? email;
  final bool bearbeitet;
  final DateTime? erstelltAm;
  final String? vereinId;

  String get artLabel =>
      art == 'szenario' ? 'Situation eingeschickt' : 'Rückmeldung';

  factory AdminRueckmeldung.ausZeile(Map<String, dynamic> z) =>
      AdminRueckmeldung(
        id: z['id'] as String,
        art: z['art'] as String,
        text: z['text'] as String,
        email: z['email'] as String?,
        bearbeitet: z['bearbeitet'] as bool? ?? false,
        erstelltAm: DateTime.tryParse(z['erstellt_am'] as String? ?? ''),
        vereinId: z['verein_id'] as String?,
      );
}

/// Ein Zaehlwert, wie ihn die Zahlen-Seite zeigt.
@immutable
class AdminZahl {
  const AdminZahl({
    required this.vereinId,
    required this.szenarioId,
    required this.signatur,
    required this.punktIndex,
    required this.optionId,
    required this.anzahl,
  });

  final String vereinId;
  final String szenarioId;
  final String signatur;
  final int punktIndex;
  final String optionId;
  final int anzahl;

  factory AdminZahl.ausZeile(Map<String, dynamic> z) => AdminZahl(
        vereinId: z['verein_id'] as String,
        szenarioId: z['szenario_id'] as String,
        signatur: z['signatur'] as String? ?? '',
        punktIndex: (z['punkt_index'] as num).toInt(),
        optionId: z['option_id'] as String,
        anzahl: (z['anzahl'] as num).toInt(),
      );
}

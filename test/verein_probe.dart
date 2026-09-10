// Ein Verein für Tests.
//
// Seit die Vereinsangaben aus der Datenbank kommen, zeigt die App ohne
// eingetragenen Code keine Ansprechpersonen und stellt beim ersten Start
// einmal die Frage nach dem Code. Beides ist gewollt — aber in Tests, die
// etwas anderes prüfen, steht es nur im Weg.
//
// Die Angaben stammen aus assets/szenarien.json, damit die Golden-Bilder
// dieselben Namen zeigen wie vorher.
import 'package:pathwise/data/fortschritt_speicher.dart';
import 'package:pathwise/data/szenario_modelle.dart';
import 'package:pathwise/data/verein_modelle.dart';

PwVerein probeVerein(PwInhalt inhalt) => PwVerein(
      id: '00000000-0000-4000-8000-000000000001',
      code: 'PROBE-2026',
      name: inhalt.verein,
      personen: inhalt.personen,
      beratung: inhalt.beratung,
    );

/// Setzt den Verein und markiert die Erststart-Frage als erledigt.
Fortschritt mitVerein(Fortschritt f, PwInhalt inhalt) =>
    f.copyWith(verein: probeVerein(inhalt), vereinGefragt: true);

// Laedt die gebuendelten Schriften in den Test-Renderer.
//
// Ohne das zeichnet flutter_test jede Glyphe als gleich breiten Kasten. Texte
// werden dadurch deutlich breiter als in der App, und Layouttests melden
// Ueberlaeufe, die es gar nicht gibt.
import 'dart:io';

import 'package:flutter/services.dart';

Future<void> schriftenLaden() async {
  const familien = {
    'Jost': ['Jost-Light.ttf', 'Jost-Medium.ttf'],
    'NunitoSans': [
      'NunitoSans-Regular.ttf',
      'NunitoSans-SemiBold.ttf',
      'NunitoSans-Bold.ttf',
    ],
    'JetBrainsMono': ['JetBrainsMono-Regular.ttf'],
  };

  for (final eintrag in familien.entries) {
    final loader = FontLoader(eintrag.key);
    for (final datei in eintrag.value) {
      final bytes = await File('assets/fonts/$datei').readAsBytes();
      loader.addFont(Future.value(bytes.buffer.asByteData()));
    }
    await loader.load();
  }

  // Lucide liegt im Paket, nicht im Projekt. Der Pfad kommt aus dem
  // package_config, damit der Test nicht an einer Cache-Adresse haengt.
  final wurzel = _paketWurzel('lucide_icons_flutter');
  final lucide = File(
    '$wurzel${wurzel.endsWith(Platform.pathSeparator) ? '' : Platform.pathSeparator}'
    'assets${Platform.pathSeparator}lucide.ttf',
  );
  if (lucide.existsSync()) {
    // Schriften aus einem Paket tragen im Test das Praefix packages/<paket>/.
    final loader = FontLoader('packages/lucide_icons_flutter/Lucide')
      ..addFont(lucide.readAsBytes().then((b) => b.buffer.asByteData()));
    await loader.load();
  } else {
    // ignore: avoid_print
    print('Hinweis: Lucide-Schrift nicht gefunden unter ${lucide.path}');
  }
}

/// Pfad des Paketverzeichnisses aus .dart_tool/package_config.json.
String _paketWurzel(String paket) {
  final roh = File('.dart_tool/package_config.json').readAsStringSync();
  final treffer = RegExp(
    '"name"\\s*:\\s*"$paket".*?"rootUri"\\s*:\\s*"([^"]+)"',
    dotAll: true,
  ).firstMatch(roh);
  if (treffer == null) return '';
  final uri = Uri.parse(treffer.group(1)!);
  return uri.hasScheme ? uri.toFilePath() : treffer.group(1)!;
}

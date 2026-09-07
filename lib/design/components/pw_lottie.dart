// Lottie-Animationen — nur in der Bewegungsstufe "Verspielt".
//
// Die Dateien liegen in assets/lottie/ und sind nicht Teil des Repos, solange
// sie niemand ablegt. Fehlt eine, faellt die Stelle stillschweigend auf ihre
// Vorgabe zurueck: die App darf an keiner Stelle davon abhaengen, dass eine
// Animation da ist.
//
// Ampelfarben sind hier tabu — sie gehoeren allein der Einordnung von
// Situationsmerkmalen (DESIGN.md 1). Worauf eine Datei sonst achten muss,
// steht in assets/lottie/LIESMICH.md.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:lottie/lottie.dart';

import '../pw_motion.dart';

/// Die Stellen, an denen die App eine Lottie-Animation zeigen kann.
enum PwLottieStelle {
  /// Kopf der Auswertung: untersuchen, pruefen — keine Feier.
  auswertung('assets/lottie/auswertung.json', schleife: false),

  /// Bestaetigung, nachdem eine Rueckmeldung abgeschickt wurde.
  angekommen('assets/lottie/angekommen.json', schleife: false),

  /// "Kommt bald"-Dialog, ersetzt die drei pulsierenden Ringe.
  kommtBald('assets/lottie/kommt-bald.json', schleife: true),

  /// Szenariokarte, beim ersten Abschluss.
  abschluss('assets/lottie/abschluss.json', schleife: false);

  const PwLottieStelle(this.pfad, {required this.schleife});

  final String pfad;
  final bool schleife;
}

/// Merkt sich je Pfad, ob die Datei im Buendel liegt — sonst fragt jeder
/// Bildaufbau erneut nach.
final Map<String, Future<bool>> _vorhanden = {};

Future<bool> _datenVorhanden(String pfad) =>
    _vorhanden[pfad] ??= rootBundle.load(pfad).then(
          (_) => true,
          onError: (_, _) => false,
        );

/// Zeigt die Animation zu [stelle] — oder [ersatz], wenn keine Datei da ist.
///
/// [an] steuert, ob ueberhaupt eine Animation gezeigt wird; die Screens geben
/// dort die Bewegungsstufe hinein. Bei reduzierter Bewegung laeuft nichts,
/// unabhaengig von der Einstellung.
class PwLottie extends StatelessWidget {
  const PwLottie({
    super.key,
    required this.stelle,
    required this.an,
    required this.ersatz,
    this.groesse,
    this.onFertig,
  });

  final PwLottieStelle stelle;
  final bool an;

  /// Was ohne Animation steht — bei fehlender Datei, abgeschalteter Stufe oder
  /// reduzierter Bewegung.
  final Widget ersatz;

  final double? groesse;

  /// Wird gerufen, wenn eine einmalige Animation durch ist. Bei fehlender
  /// Datei sofort, damit der Ablauf nicht haengen bleibt.
  final VoidCallback? onFertig;

  @override
  Widget build(BuildContext context) {
    if (!an || !PwMotion.schleifenErlaubt(context)) {
      _sofortFertig();
      return ersatz;
    }

    return FutureBuilder<bool>(
      future: _datenVorhanden(stelle.pfad),
      builder: (ctx, schnappschuss) {
        if (schnappschuss.data != true) {
          if (schnappschuss.connectionState == ConnectionState.done) {
            _sofortFertig();
          }
          return ersatz;
        }
        return SizedBox(
          width: groesse,
          height: groesse,
          child: Lottie.asset(
            stelle.pfad,
            repeat: stelle.schleife,
            fit: BoxFit.contain,
            onLoaded: stelle.schleife
                ? null
                : (komposition) {
                    // Einmalige Animationen melden sich nach ihrer Laufzeit.
                    Future.delayed(komposition.duration, () {
                      onFertig?.call();
                    });
                  },
            errorBuilder: (_, _, _) => ersatz,
          ),
        );
      },
    );
  }

  void _sofortFertig() {
    if (onFertig == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => onFertig!());
  }
}

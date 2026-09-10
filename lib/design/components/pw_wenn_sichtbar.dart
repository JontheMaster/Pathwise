// Baut seinen Inhalt erst, wenn er wirklich im Bild steht.
//
// Ein Scrollbereich baut alle seine Kinder sofort, auch die weit unterhalb des
// sichtbaren Ausschnitts. Eine Animation, die beim Bauen startet, ist damit
// vorbei, bevor jemand hinscrollt — und wenn sie sich danach als "gezeigt"
// merkt, bekommt man sie nie zu sehen.
//
// Deshalb hier: melden, sobald ein ausreichender Teil im Sichtfenster des
// umgebenden Scrollbereichs liegt. Gibt es keinen, zaehlt der Bildschirm.
import 'package:flutter/material.dart';

class PwWennSichtbar extends StatefulWidget {
  const PwWennSichtbar({
    super.key,
    required this.builder,
    this.anteil = 0.6,
  });

  /// Bekommt `true`, sobald der Bereich sichtbar ist — und behaelt es dann.
  final Widget Function(BuildContext context, bool sichtbar) builder;

  /// Wie viel der eigenen Hoehe im Sichtfenster liegen muss.
  final double anteil;

  @override
  State<PwWennSichtbar> createState() => _PwWennSichtbarState();
}

class _PwWennSichtbarState extends State<PwWennSichtbar> {
  bool _sichtbar = false;
  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sichtbar) return;

    final neue = Scrollable.maybeOf(context)?.position;
    if (neue != _position) {
      _position?.removeListener(_pruefen);
      _position = neue;
      _position?.addListener(_pruefen);
    }
    // Der erste Aufbau hat noch keine Groesse — eine Bildfolge spaeter schon.
    WidgetsBinding.instance.addPostFrameCallback((_) => _pruefen());
  }

  @override
  void dispose() {
    _position?.removeListener(_pruefen);
    super.dispose();
  }

  void _pruefen() {
    if (_sichtbar || !mounted) return;

    final eigen = context.findRenderObject() as RenderBox?;
    if (eigen == null || !eigen.hasSize || eigen.size.height <= 0) return;

    final fenster = _sichtfenster(eigen);
    if (fenster == null) return;

    final selbst = eigen.localToGlobal(Offset.zero) & eigen.size;
    final ueberlappung = selbst.intersect(fenster);
    if (ueberlappung.height <= 0) return;

    if (ueberlappung.height / selbst.height >= widget.anteil) {
      _position?.removeListener(_pruefen);
      setState(() => _sichtbar = true);
    }
  }

  /// Der sichtbare Ausschnitt des umgebenden Scrollbereichs — oder der
  /// Bildschirm, wenn es keinen gibt.
  Rect? _sichtfenster(RenderBox eigen) {
    final scrollKontext = Scrollable.maybeOf(context)?.context;
    final scrollBox = scrollKontext?.findRenderObject() as RenderBox?;
    if (scrollBox != null && scrollBox.hasSize) {
      return scrollBox.localToGlobal(Offset.zero) & scrollBox.size;
    }
    final mq = MediaQuery.maybeOf(context);
    return mq == null ? null : Offset.zero & mq.size;
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _sichtbar);
}

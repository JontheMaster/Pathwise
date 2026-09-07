// Bottom Sheet und Dialog — DESIGN.md 4.14, Motion M13, M14, M15, M16.
//
// Als eigene Route statt showModalBottomSheet: nur so laesst sich der Schleier
// mit 3 dp Blur unterlegen, die Hoehenbegrenzung in Prozent setzen und die
// Zeiten der Motion-Spec exakt treffen. Als Route bleibt das Overlay im
// Backstack, Systemzurueck schliesst es zuerst (DESIGN.md 6).
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../pathwise_theme.dart';
import '../pathwise_tokens.dart';
import '../pw_motion.dart';
import 'pw_icon_button.dart';
import 'pw_icons.dart';

/// Oeffnet ein Sheet. [anteilHoehe] ist 0.92 fuer Hilfe und Info, 0.94 fuer
/// die Rueckmeldung.
Future<T?> pwSheetZeigen<T>(
  BuildContext context, {
  required String titel,
  required WidgetBuilder builder,
  String? untertitel,
  double anteilHoehe = 0.92,
}) {
  return Navigator.of(context).push<T>(
    _OverlayRoute<T>(
      ausrichtung: Alignment.bottomCenter,
      blur: 3,
      dauer: const Duration(milliseconds: 300), // M13
      rueckDauer: const Duration(milliseconds: 220), // M15
      inhalt: (ctx, anim) => _Sheet(
        titel: titel,
        untertitel: untertitel,
        anteilHoehe: anteilHoehe,
        anim: anim,
        child: Builder(builder: builder),
      ),
    ),
  );
}

/// Oeffnet einen zentrierten Dialog (S9). M16: translateY 14 -> 0, 360 ms.
Future<T?> pwDialogZeigen<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return Navigator.of(context).push<T>(
    _OverlayRoute<T>(
      ausrichtung: Alignment.center,
      blur: 4,
      dauer: PwDur.slow,
      rueckDauer: const Duration(milliseconds: 220),
      inhalt: (ctx, anim) => _Dialog(anim: anim, child: Builder(builder: builder)),
    ),
  );
}

class _OverlayRoute<T> extends PageRouteBuilder<T> {
  _OverlayRoute({
    required this.ausrichtung,
    required this.blur,
    required this.inhalt,
    required Duration dauer,
    required Duration rueckDauer,
  }) : super(
          opaque: false,
          barrierDismissible: false, // wird unten selbst behandelt
          fullscreenDialog: true,
          transitionDuration: dauer,
          reverseTransitionDuration: rueckDauer,
          pageBuilder: (_, _, _) => const SizedBox.shrink(),
        );

  final Alignment ausrichtung;
  final double blur;
  final Widget Function(BuildContext, Animation<double>) inhalt;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final c = context.pw;
    // M14: Schleier blendet in 200 ms ein.
    final schleier = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.66, curve: PwCurve.out),
      reverseCurve: PwCurve.inn,
    );

    return Stack(
      children: [
        FadeTransition(
          opacity: schleier,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: ColoredBox(
                color: c.surfaceOverlay,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        Align(
          alignment: ausrichtung,
          // Tippen auf den Inhalt darf nicht bis zum Schleier durchschlagen.
          child: GestureDetector(
            onTap: () {},
            // Material-Widgets im Sheet — allen voran TextField in S8 —
            // brauchen einen Material-Vorfahren. Die Route bringt keinen mit,
            // deshalb hier ein transparenter: die Flaeche zeichnet das Sheet
            // selbst.
            child: Material(
              type: MaterialType.transparency,
              child: inhalt(context, animation),
            ),
          ),
        ),
      ],
    );
  }
}

class _Sheet extends StatefulWidget {
  const _Sheet({
    required this.titel,
    required this.untertitel,
    required this.anteilHoehe,
    required this.anim,
    required this.child,
  });

  final String titel;
  final String? untertitel;
  final double anteilHoehe;
  final Animation<double> anim;
  final Widget child;

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  double _zug = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;
    final mq = MediaQuery.of(context);
    final skala = PwMotion.scale(context);

    final gleiten = Tween<Offset>(
      begin: const Offset(0, 1), // M13: translateY 100 % -> 0
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: widget.anim,
      curve: PwCurve.out,
      reverseCurve: PwCurve.inn,
    ));

    final sheet = Container(
      constraints: BoxConstraints(
        maxWidth: 520,
        maxHeight: mq.size.height * widget.anteilHoehe,
      ),
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: PwRadius.sheet,
        boxShadow: PwShadow.xl(context.isDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 22,
            bottom: 20 + mq.viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.titel,
                          style: t.titleLarge?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (widget.untertitel != null) ...[
                          const SizedBox(height: PwSpace.s3),
                          Text(
                            widget.untertitel!,
                            style: t.bodyMedium?.copyWith(color: c.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: PwSpace.gap),
                  PwIconButton(
                    ikon: PwIcons.x,
                    label: 'Schließen',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              const SizedBox(height: PwSpace.gap),
              widget.child,
            ],
          ),
        ),
      ),
    );

    return SlideTransition(
      position: gleiten,
      child: GestureDetector(
        // Herunterziehen schliesst das Sheet (DESIGN.md 4.14).
        onVerticalDragUpdate: (d) =>
            setState(() => _zug = (_zug + d.delta.dy).clamp(0, 400)),
        onVerticalDragEnd: (d) {
          if (_zug > 110 || d.velocity.pixelsPerSecond.dy > 700) {
            Navigator.of(context).maybePop();
          } else {
            setState(() => _zug = 0);
          }
        },
        child: Transform.translate(
          offset: Offset(0, _zug * skala),
          child: sheet,
        ),
      ),
    );
  }
}

class _Dialog extends StatelessWidget {
  const _Dialog({required this.anim, required this.child});

  final Animation<double> anim;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final kurve = CurvedAnimation(
      parent: anim,
      curve: PwCurve.out,
      reverseCurve: PwCurve.inn,
    );

    return FadeTransition(
      opacity: kurve,
      child: AnimatedBuilder(
        animation: kurve,
        builder: (_, kind) => Transform.translate(
          // M16: translateY 14 -> 0.
          offset: Offset(0, kRevealShift * (1 - kurve.value)),
          child: kind,
        ),
        child: Padding(
          padding: const EdgeInsets.all(PwSpace.s7),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 22),
            decoration: BoxDecoration(
              color: c.surfaceCard,
              borderRadius: PwRadius.dialog,
              border: Border.all(color: c.borderSubtle),
              boxShadow: PwShadow.xl(context.isDark),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

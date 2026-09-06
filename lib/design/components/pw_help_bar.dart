// PwHelpBar — DESIGN.md 4.12.
//
// Steht am Ende jeder Ansicht ausser den Vereinsangaben. Tippen oeffnet das
// Hilfe-Sheet und startet *nicht* direkt den Anruf: der Anruf beginnt erst aus
// dem Sheet heraus. Das verhindert versehentliche Anrufe.
import 'package:flutter/material.dart';

import '../pathwise_theme.dart';
import '../pathwise_tokens.dart';
import 'pw_icons.dart';
import 'pw_press_scale.dart';

class PwHelpBar extends StatelessWidget {
  const PwHelpBar({super.key, required this.onTap});

  final VoidCallback onTap;

  static const titel = 'Hilfetelefon Sexueller Missbrauch';
  static const zeile2 = '0800 22 55 530 · anonym und kostenfrei';

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: '$titel. $zeile2. Öffnet Hilfe und Beratung.',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: PwPressScale(
            child: Container(
              constraints: const BoxConstraints(minHeight: PwSize.touchMin),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: c.surfaceInverse,
                borderRadius: PwRadius.control,
              ),
              child: Row(
                children: [
                  Icon(PwIcons.lifeBuoy, size: 17, color: PwPalette.blue300),
                  const SizedBox(width: PwSpace.gapTight),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          titel,
                          style: const TextStyle(
                            fontFamily: 'NunitoSans',
                            fontSize: 13.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: PwPalette.white,
                          ),
                        ),
                        Text(
                          zeile2,
                          style: t.bodyMedium
                              ?.copyWith(color: PwPalette.blue300),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: PwSpace.s4),
                  const Icon(PwIcons.phone, size: 16, color: PwPalette.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

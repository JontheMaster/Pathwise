// Ein Szenario bearbeiten.
//
// Der Editor arbeitet auf einer Kopie des rohen jsonb und schreibt nur die
// Felder zurueck, die er kennt. Was er nicht kennt, bleibt unangetastet — ein
// spaeter dazukommendes Feld soll durch eine Bearbeitung nicht verschwinden.
//
// Gespeichert wird ausdruecklich, nicht nebenbei: wer bearbeitet, soll den
// Moment bestimmen, in dem eine Aenderung fuer alle gilt. Beim Verlassen mit
// ungesicherten Aenderungen fragt der Editor nach.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/components/pw_button.dart';
import '../../design/components/pw_icons.dart';
import '../../design/components/pw_label.dart';
import '../../design/pathwise_theme.dart';
import '../../design/pathwise_tokens.dart';
import '../admin_modelle.dart';
import '../admin_state.dart';
import '../widgets/admin_bausteine.dart';

/// Die drei Ampelstufen, wie sie im jsonb stehen.
const _stufen = <String, String>{
  'ok': 'Unbedenklich',
  'check': 'Klärungsbedürftig',
  'viol': 'Grenzverletzend',
};

class SzenarioEditor extends ConsumerStatefulWidget {
  const SzenarioEditor({super.key, required this.szenario, this.neu = false});

  final AdminSzenario szenario;

  /// True, wenn das Szenario noch nicht in der Datenbank steht.
  final bool neu;

  @override
  ConsumerState<SzenarioEditor> createState() => _SzenarioEditorState();
}

class _SzenarioEditorState extends ConsumerState<SzenarioEditor> {
  late Map<String, dynamic> _inhalt;
  late AdminStatus _status;
  late int _reihenfolge;
  late String _id;
  bool _geaendert = false;
  bool _speichert = false;

  @override
  void initState() {
    super.initState();
    // Tiefe Kopie ueber JSON: der Editor darf am Original nichts veraendern,
    // solange nicht gespeichert wurde.
    _inhalt = jsonDecode(jsonEncode(widget.szenario.inhalt))
        as Map<String, dynamic>;
    _status = widget.szenario.status;
    _reihenfolge = widget.szenario.reihenfolge;
    _id = widget.szenario.id;

    _inhalt['punkte'] ??= <dynamic>[];
    _inhalt['merkmale'] ??= <dynamic>[];
    _inhalt['rahmen'] ??= <dynamic>[];
  }

  void _setzen(void Function() aendern) {
    setState(() {
      aendern();
      _geaendert = true;
    });
  }

  List<Map<String, dynamic>> get _punkte =>
      (_inhalt['punkte'] as List).cast<Map<String, dynamic>>();

  List<Map<String, dynamic>> get _merkmale =>
      (_inhalt['merkmale'] as List).cast<Map<String, dynamic>>();

  List<String> get _rahmen => (_inhalt['rahmen'] as List).cast<String>();

  // ── Speichern ──────────────────────────────────────────────────────────

  String? get _fehlt {
    if (_id.trim().isEmpty) return 'Die Kennung fehlt.';
    if (!RegExp(r'^[a-z0-9-]{1,64}$').hasMatch(_id.trim())) {
      return 'Die Kennung darf nur Kleinbuchstaben, Ziffern und Bindestriche '
          'enthalten.';
    }
    if ((_inhalt['titel'] as String? ?? '').trim().isEmpty) {
      return 'Der Titel fehlt.';
    }
    if ((_inhalt['themenfeld'] as String? ?? '').trim().isEmpty) {
      return 'Das Themenfeld fehlt.';
    }
    if (_punkte.isEmpty) return 'Mindestens ein Entscheidungspunkt ist nötig.';
    for (var i = 0; i < _punkte.length; i++) {
      final optionen = (_punkte[i]['optionen'] as List?) ?? const [];
      if (optionen.length != 3) {
        return 'Entscheidungspunkt ${i + 1} braucht genau drei '
            'Handlungsoptionen.';
      }
      for (final o in optionen.cast<Map<String, dynamic>>()) {
        if ((o['text'] as String? ?? '').trim().isEmpty) {
          return 'Eine Handlungsoption in Entscheidungspunkt ${i + 1} ist leer.';
        }
      }
      if ((_punkte[i]['leitfrage'] as String? ?? '').trim().isEmpty) {
        return 'Die Leitfrage von Entscheidungspunkt ${i + 1} fehlt.';
      }
    }
    return null;
  }

  Future<void> _speichern() async {
    final fehlt = _fehlt;
    if (fehlt != null) {
      adminMelden(context, fehlt, fehler: true);
      return;
    }

    setState(() => _speichert = true);
    final repo = ref.read(adminRepositoryProvider);
    final s = AdminSzenario(
      id: _id.trim(),
      status: _status,
      reihenfolge: _reihenfolge,
      fassung: widget.szenario.fassung,
      signatur: widget.szenario.signatur,
      inhalt: _inhalt,
    );

    final geklappt = await adminTun(
      context,
      () => widget.neu ? repo.szenarioAnlegen(s) : repo.szenarioSichern(s),
      erfolg: widget.neu ? 'Szenario angelegt.' : 'Szenario gespeichert.',
    );

    if (!mounted) return;
    setState(() {
      _speichert = false;
      if (geklappt) _geaendert = false;
    });
    if (geklappt) {
      ref.szenarienNeu();
      Navigator.of(context).pop();
    }
  }

  Future<bool> _darfSchliessen() async {
    if (!_geaendert) return true;
    return adminBestaetigen(
      context,
      titel: 'Änderungen verwerfen?',
      text: 'Es gibt Änderungen, die noch nicht gespeichert sind. Sie gehen '
          'verloren.',
      knopf: 'Verwerfen',
    );
  }

  // ── Aufbau ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (schon, _) async {
        if (schon) return;
        if (await _darfSchliessen() && mounted) {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: c.surfacePage,
        appBar: AppBar(
          backgroundColor: c.surfaceCard,
          surfaceTintColor: Colors.transparent,
          shape: Border(bottom: BorderSide(color: c.borderSubtle)),
          leading: IconButton(
            icon: Icon(PwIcons.chevronLeft, color: c.textHeading),
            tooltip: 'Zurück zur Liste',
            onPressed: () async {
              if (await _darfSchliessen() && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            widget.neu ? 'Neues Szenario' : 'Szenario bearbeiten',
            style: t.titleMedium,
          ),
          actions: [
            if (_geaendert)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  'nicht gespeichert',
                  style: t.bodyMedium?.copyWith(color: c.textAccent),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: PwSpace.gap),
              child: PwButton(
                label: widget.neu ? 'Anlegen' : 'Speichern',
                variante: PwButtonVariante.accent,
                ikon: PwIcons.check,
                laedt: _speichert,
                onPressed: _speichert ? null : _speichern,
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(PwSpace.gap),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _kopf(),
                    const SizedBox(height: PwSpace.gap),
                    _situation(),
                    const SizedBox(height: PwSpace.gap),
                    _merkmalsBlock(),
                    const SizedBox(height: PwSpace.gap),
                    for (var i = 0; i < _punkte.length; i++) ...[
                      _punktBlock(i),
                      const SizedBox(height: PwSpace.gap),
                    ],
                    PwButton(
                      label: 'Entscheidungspunkt hinzufügen',
                      ikon: PwIcons.plus,
                      vollBreite: true,
                      onPressed: () => _setzen(() => _punkte.add({
                            'text': '',
                            'leitfrage': '',
                            'optionen': [
                              for (final id in ['a', 'b', 'c'])
                                {'id': id, 'text': ''},
                            ],
                            'erkennen': '',
                            'absichern': '',
                            'handeln': '',
                          })),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kopf() => AdminBlock(
        titel: 'Grunddaten',
        zusatz: 'Die Kennung steht in der Datenbank und in den Zählwerten. '
            'Sie lässt sich nach dem Anlegen nicht mehr ändern.',
        kinder: [
          if (widget.neu)
            AdminFeld(
              label: 'Kennung',
              wert: _id,
              platzhalter: 'z. B. umkleide-fotos',
              hinweis: 'Kleinbuchstaben, Ziffern und Bindestriche.',
              onGeaendert: (v) => _setzen(() => _id = v),
            )
          else
            _NurLesen(label: 'Kennung', wert: _id),
          AdminFeld(
            label: 'Titel',
            wert: _inhalt['titel'] as String? ?? '',
            onGeaendert: (v) => _setzen(() => _inhalt['titel'] = v),
          ),
          AdminFeld(
            label: 'Themenfeld',
            wert: _inhalt['themenfeld'] as String? ?? '',
            hinweis: 'Steht als Filter über der Übersicht.',
            onGeaendert: (v) => _setzen(() => _inhalt['themenfeld'] = v),
          ),
          AdminFeld(
            label: 'Kurzbeschreibung',
            wert: _inhalt['kurz'] as String? ?? '',
            zeilen: 3,
            hinweis: 'Zwei Sätze auf der Szenariokarte.',
            onGeaendert: (v) => _setzen(() => _inhalt['kurz'] = v),
          ),
          AdminFeld(
            label: 'Dauer',
            wert: _inhalt['dauer'] as String? ?? '',
            platzhalter: 'ca. 5 Min.',
            onGeaendert: (v) => _setzen(() => _inhalt['dauer'] = v),
          ),
          _RahmenFeld(
            werte: _rahmen,
            onGeaendert: (neu) =>
                _setzen(() => _inhalt['rahmen'] = List<String>.from(neu)),
          ),
          _StatusFeld(
            status: _status,
            reihenfolge: _reihenfolge,
            fassung: widget.neu ? null : widget.szenario.fassung,
            onStatus: (s) => _setzen(() => _status = s),
            onReihenfolge: (r) => _setzen(() => _reihenfolge = r),
          ),
        ],
      );

  Widget _situation() => AdminBlock(
        titel: 'Situation',
        kinder: [
          AdminFeld(
            label: 'Vorgeschichte',
            wert: _inhalt['vorgeschichte'] as String? ?? '',
            zeilen: 4,
            onGeaendert: (v) => _setzen(() => _inhalt['vorgeschichte'] = v),
          ),
          AdminFeld(
            label: 'Ausgangssituation',
            wert: _inhalt['ausgangssituation'] as String? ?? '',
            zeilen: 5,
            onGeaendert: (v) => _setzen(() => _inhalt['ausgangssituation'] = v),
          ),
        ],
      );

  Widget _merkmalsBlock() => AdminBlock(
        titel: 'Merkmale der Situation',
        zusatz: 'Die Ampelstufen der Auswertung. Sie gehören ausschließlich '
            'den Merkmalen — nie Buttons, Optionen oder Fortschritt.',
        aktion: PwButton(
          label: 'Merkmal',
          ikon: PwIcons.plus,
          groesse: PwButtonGroesse.sm,
          onPressed: () => _setzen(
            () => _merkmale.add({'text': '', 'stufe': 'check'}),
          ),
        ),
        kinder: [
          for (var i = 0; i < _merkmale.length; i++)
            _MerkmalZeile(
              key: ValueKey('merkmal-$i'),
              merkmal: _merkmale[i],
              onGeaendert: (neu) => _setzen(() => _merkmale[i] = neu),
              onLoeschen: () => _setzen(() => _merkmale.removeAt(i)),
            ),
          if (_merkmale.isEmpty)
            Text(
              'Noch keine Merkmale. Ohne sie bleibt die Auswertung leer.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.pw.textMuted),
            ),
        ],
      );

  Widget _punktBlock(int i) {
    final p = _punkte[i];
    final optionen = ((p['optionen'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();

    return AdminBlock(
      titel: 'Entscheidungspunkt ${i + 1}',
      aktion: PwButton(
        label: 'Entfernen',
        groesse: PwButtonGroesse.sm,
        onPressed: () => _setzen(() => _punkte.removeAt(i)),
      ),
      kinder: [
        AdminFeld(
          label: i == 0 ? 'Text (wird von der Ausgangssituation ersetzt)'
              : 'Was passiert',
          wert: p['text'] as String? ?? '',
          zeilen: 4,
          onGeaendert: (v) => _setzen(() => p['text'] = v),
        ),
        AdminFeld(
          label: 'Leitfrage',
          wert: p['leitfrage'] as String? ?? '',
          platzhalter: 'Wie reagierst du?',
          hinweis: 'Sie geht in die Signatur ein: eine Änderung hier setzt '
              'den Einschätzungsspiegel dieses Szenarios zurück.',
          onGeaendert: (v) => _setzen(() => p['leitfrage'] = v),
        ),
        const PwLabel('Handlungsoptionen'),
        for (var o = 0; o < optionen.length; o++)
          AdminFeld(
            key: ValueKey('punkt-$i-option-$o'),
            label: (optionen[o]['id'] as String? ?? '?').toUpperCase(),
            wert: optionen[o]['text'] as String? ?? '',
            zeilen: 2,
            onGeaendert: (v) => _setzen(() => optionen[o]['text'] = v),
          ),
        const PwLabel('Rückmeldung'),
        AdminFeld(
          label: 'Erkennen',
          wert: p['erkennen'] as String? ?? '',
          zeilen: 3,
          onGeaendert: (v) => _setzen(() => p['erkennen'] = v),
        ),
        AdminFeld(
          label: 'Absichern',
          wert: p['absichern'] as String? ?? '',
          zeilen: 3,
          onGeaendert: (v) => _setzen(() => p['absichern'] = v),
        ),
        AdminFeld(
          label: 'Handeln',
          wert: p['handeln'] as String? ?? '',
          zeilen: 3,
          onGeaendert: (v) => _setzen(() => p['handeln'] = v),
        ),
      ],
    );
  }
}

class _NurLesen extends StatelessWidget {
  const _NurLesen({required this.label, required this.wert});

  final String label;
  final String wert;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PwLabel(label),
        const SizedBox(height: PwSpace.s3),
        Container(
          padding: const EdgeInsets.all(PwSpace.gapTight),
          decoration: BoxDecoration(
            color: c.surfaceSunken,
            borderRadius: PwRadius.control,
          ),
          child: Text(
            wert,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: c.textMuted),
          ),
        ),
      ],
    );
  }
}

class _StatusFeld extends StatelessWidget {
  const _StatusFeld({
    required this.status,
    required this.reihenfolge,
    required this.fassung,
    required this.onStatus,
    required this.onReihenfolge,
  });

  final AdminStatus status;
  final int reihenfolge;
  final int? fassung;
  final ValueChanged<AdminStatus> onStatus;
  final ValueChanged<int> onReihenfolge;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const PwLabel('Status'),
        const SizedBox(height: PwSpace.s4),
        Row(
          children: [
            for (final s in AdminStatus.values) ...[
              PwButton(
                label: s.label,
                variante: status == s
                    ? PwButtonVariante.primary
                    : PwButtonVariante.secondary,
                ikon: status == s ? PwIcons.check : null,
                onPressed: () => onStatus(s),
              ),
              const SizedBox(width: PwSpace.s4),
            ],
            Expanded(
              child: Text(
                status == AdminStatus.veroeffentlicht
                    ? fassung == null
                        ? 'Wird beim Anlegen sofort in der App sichtbar.'
                        : 'Sichtbar in der App. Jede Änderung am Inhalt macht '
                            'eine neue Fassung (aktuell $fassung).'
                    : 'Nur hier sichtbar. Die App bekommt Entwürfe nicht zu '
                        'sehen.',
                style: t.bodyMedium?.copyWith(color: c.textMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: PwSpace.gap),
        _ZahlFeld(
          label: 'Reihenfolge',
          wert: reihenfolge,
          hinweis: 'Kleinere Zahlen stehen in der Übersicht weiter oben.',
          onGeaendert: onReihenfolge,
        ),
      ],
    );
  }
}

class _ZahlFeld extends StatelessWidget {
  const _ZahlFeld({
    required this.label,
    required this.wert,
    required this.onGeaendert,
    this.hinweis,
  });

  final String label;
  final int wert;
  final ValueChanged<int> onGeaendert;
  final String? hinweis;

  @override
  Widget build(BuildContext context) => AdminFeld(
        label: label,
        wert: '$wert',
        hinweis: hinweis,
        onGeaendert: (v) => onGeaendert(int.tryParse(v.trim()) ?? 0),
      );
}

/// Die Rahmen-Chips: eine Zeile je Angabe.
class _RahmenFeld extends StatelessWidget {
  const _RahmenFeld({required this.werte, required this.onGeaendert});

  final List<String> werte;
  final ValueChanged<List<String>> onGeaendert;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Expanded(child: PwLabel('Rahmen')),
            PwButton(
              label: 'Angabe',
              ikon: PwIcons.plus,
              groesse: PwButtonGroesse.sm,
              onPressed: () => onGeaendert([...werte, '']),
            ),
          ],
        ),
        const SizedBox(height: PwSpace.s4),
        Text(
          'Die Chips über der Situation, etwa „U12, 10 bis 12 Jahre".',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: context.pw.textMuted),
        ),
        for (var i = 0; i < werte.length; i++) ...[
          const SizedBox(height: PwSpace.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AdminFeld(
                  key: ValueKey('rahmen-$i'),
                  label: 'Angabe ${i + 1}',
                  wert: werte[i],
                  onGeaendert: (v) {
                    final neu = [...werte];
                    neu[i] = v;
                    onGeaendert(neu);
                  },
                ),
              ),
              const SizedBox(width: PwSpace.s4),
              Padding(
                padding: const EdgeInsets.only(top: 26),
                child: PwButton(
                  label: 'Weg',
                  groesse: PwButtonGroesse.sm,
                  onPressed: () =>
                      onGeaendert([...werte]..removeAt(i)),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MerkmalZeile extends StatelessWidget {
  const _MerkmalZeile({
    super.key,
    required this.merkmal,
    required this.onGeaendert,
    required this.onLoeschen,
  });

  final Map<String, dynamic> merkmal;
  final ValueChanged<Map<String, dynamic>> onGeaendert;
  final VoidCallback onLoeschen;

  @override
  Widget build(BuildContext context) {
    final c = context.pw;
    final t = Theme.of(context).textTheme;
    final stufe = merkmal['stufe'] as String? ?? 'check';
    final nichtEingetreten = merkmal['nichtEingetreten'] == true;

    final farbe = switch (stufe) {
      'ok' => c.levelOk,
      'viol' => c.levelViolation,
      _ => c.levelCheck,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: PwSpace.s4),
      padding: const EdgeInsets.all(PwSpace.gapTight),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: PwRadius.control,
        border: Border.all(color: c.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AdminFeld(
            label: 'Merkmal',
            wert: merkmal['text'] as String? ?? '',
            zeilen: 2,
            onGeaendert: (v) => onGeaendert({...merkmal, 'text': v}),
          ),
          const SizedBox(height: PwSpace.s4),
          Wrap(
            spacing: PwSpace.s4,
            runSpacing: PwSpace.s4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final e in _stufen.entries)
                PwButton(
                  label: e.value,
                  groesse: PwButtonGroesse.sm,
                  variante: stufe == e.key
                      ? PwButtonVariante.primary
                      : PwButtonVariante.secondary,
                  onPressed: () => onGeaendert({...merkmal, 'stufe': e.key}),
                ),
              Container(width: 1, height: 20, color: c.divider),
              PwButton(
                label: nichtEingetreten
                    ? 'Nicht eingetreten'
                    : 'Eingetreten',
                groesse: PwButtonGroesse.sm,
                ikon: nichtEingetreten ? PwIcons.eyeOff : PwIcons.eye,
                onPressed: () => onGeaendert({
                  ...merkmal,
                  'nichtEingetreten': !nichtEingetreten,
                }),
              ),
              PwButton(
                label: 'Löschen',
                groesse: PwButtonGroesse.sm,
                onPressed: onLoeschen,
              ),
            ],
          ),
          const SizedBox(height: PwSpace.s3),
          Text(
            nichtEingetreten
                ? 'Erscheint mit dem Nachsatz „in diesem Durchlauf nicht '
                    'eingetreten" und behält die Farbe seiner Stufe.'
                : _stufen[stufe] ?? '',
            style: t.bodyMedium?.copyWith(color: farbe),
          ),
        ],
      ),
    );
  }
}

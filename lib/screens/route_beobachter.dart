// Ein RouteObserver, damit ein Screen merkt, wenn er wieder obenauf liegt.
//
// Flutter baut den Screen darunter beim Zurueckkommen nicht neu — er stand ja
// die ganze Zeit da. Wer trotzdem etwas tun will, sobald er wieder dran ist,
// braucht diesen Umweg.
//
// Gebraucht wird das an genau einer Stelle: die Uebersicht fragt einmalig nach
// dem Vereinscode, und zwar erst, nachdem die Erststart-Karte weg ist. Weg ist
// sie ab dem Moment, in dem das erste Szenario oeffnet — die Frage muss also
// warten, bis man von dort zurueckkommt.
import 'package:flutter/widgets.dart';

final pwRouteBeobachter = RouteObserver<ModalRoute<void>>();

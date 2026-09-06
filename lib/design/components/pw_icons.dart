// Das Icon-Vokabular aus DESIGN.md 10, Lucide.
//
// Die Datendateien nennen Icons in Kebab-Schreibweise ("user-x"); hier werden
// sie auf die Konstanten des Pakets abgebildet. Nur diese Namen kommen vor —
// keine eigenen SVGs, keine gefuellten Saetze, keine Emoji.
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

abstract final class PwIcons {
  static const chevronLeft = LucideIcons.chevronLeft;
  static const chevronRight = LucideIcons.chevronRight;
  static const chevronUp = LucideIcons.chevronUp;
  static const chevronDown = LucideIcons.chevronDown;
  static const check = LucideIcons.check;
  static const rotateCcw = LucideIcons.rotateCcw;
  static const bookOpen = LucideIcons.bookOpen;
  static const eye = LucideIcons.eye;
  static const shield = LucideIcons.shield;
  static const footprints = LucideIcons.footprints;
  static const circleCheck = LucideIcons.circleCheck;
  static const circleHelp = LucideIcons.circleHelp;
  static const circleAlert = LucideIcons.circleAlert;
  static const users = LucideIcons.users;
  static const user = LucideIcons.user;
  static const userX = LucideIcons.userX;
  static const mail = LucideIcons.mail;
  static const phone = LucideIcons.phone;
  static const lifeBuoy = LucideIcons.lifeBuoy;
  static const settings = LucideIcons.settings;
  static const plus = LucideIcons.plus;
  static const info = LucideIcons.info;
  static const cornerDownRight = LucideIcons.cornerDownRight;
  static const arrowRight = LucideIcons.arrowRight;
  static const arrowUpRight = LucideIcons.arrowUpRight;
  static const listChecks = LucideIcons.listChecks;
  static const x = LucideIcons.x;
  static const fileText = LucideIcons.fileText;
  static const messageSquare = LucideIcons.messageSquare;
  static const smartphone = LucideIcons.smartphone;
  static const eyeOff = LucideIcons.eyeOff;
  static const flag = LucideIcons.flag;
  static const loaderCircle = LucideIcons.loaderCircle;

  static const _nachName = <String, IconData>{
    'chevron-left': chevronLeft,
    'chevron-right': chevronRight,
    'chevron-up': chevronUp,
    'chevron-down': chevronDown,
    'check': check,
    'rotate-ccw': rotateCcw,
    'book-open': bookOpen,
    'eye': eye,
    'shield': shield,
    'footprints': footprints,
    'circle-check': circleCheck,
    'circle-help': circleHelp,
    'circle-alert': circleAlert,
    'users': users,
    'user': user,
    'user-x': userX,
    'mail': mail,
    'phone': phone,
    'life-buoy': lifeBuoy,
    'settings': settings,
    'plus': plus,
    'info': info,
    'corner-down-right': cornerDownRight,
    'arrow-right': arrowRight,
    'arrow-up-right': arrowUpRight,
    'list-checks': listChecks,
    'x': x,
    'file-text': fileText,
    'message-square': messageSquare,
    'smartphone': smartphone,
    'eye-off': eyeOff,
    'flag': flag,
    'loader-circle': loaderCircle,
  };

  /// Icon zu einem Namen aus den Datendateien. Unbekannte Namen fallen auf
  /// `info` zurueck, damit ein Tippfehler in den Daten nichts zerreisst.
  static IconData ausName(String name) => _nachName[name] ?? info;
}

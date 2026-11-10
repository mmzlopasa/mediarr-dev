import 'dart:ui';

import 'package:intl/intl.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// The languages the app speaks, each in its own words. A machine translation says so.
const appLanguages = {
  'en': 'English',
  'hr': 'Hrvatski',
  'de': 'Deutsch (maschinell übersetzt)',
  'sl': 'Slovenščina (strojni prevod)',
};

/// A language's name alone, without the note that it is machine translated.
String languageName(String code) =>
    (appLanguages[code] ?? code).split(' (').first;

/// Machine translated, not yet read by a person who speaks the language.
const unreviewedLanguages = {'de', 'sl'};

AppLocalizations _current = lookupAppLocalizations(const Locale('en'));

/// The texts in the chosen language, for widgets and for code that has no context.
AppLocalizations get l => _current;

/// The language a code names, or English when the app does not speak it.
String appLanguageOf(String? code) =>
    code != null && appLanguages.containsKey(code) ? code : 'en';

/// Switches every text to a language.
void useLanguage(String code) {
  _current = lookupAppLocalizations(Locale(appLanguageOf(code)));
}

String _two(int value) => value.toString().padLeft(2, '0');

/// A moment in the chosen language, without seconds: "9. Nov. 2026 22:39".
String localTime(DateTime at) {
  final local = at.toLocal();
  try {
    return DateFormat.yMMMd(l.localeName).add_Hm().format(local);
  } on Object {
    // The language's dates are not loaded (as in a test): numbers say it too.
    return '${local.year}-${_two(local.month)}-${_two(local.day)} '
        '${_two(local.hour)}:${_two(local.minute)}';
  }
}

/// A day in the chosen language: "15. Nov. 2026".
String localDay(DateTime at) {
  final local = at.toLocal();
  try {
    return DateFormat.yMMMd(l.localeName).format(local);
  } on Object {
    return '${local.year}-${_two(local.month)}-${_two(local.day)}';
  }
}

/// A count with the chosen language's grouping: 48,211 or 48.211.
String localCount(int value) {
  try {
    return NumberFormat.decimalPattern(l.localeName).format(value);
  } on Object {
    return '$value';
  }
}

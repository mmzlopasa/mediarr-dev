import 'dart:ui';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// The languages the app speaks, each in its own words. A machine translation says so.
const appLanguages = {
  'en': 'English',
  'hr': 'Hrvatski',
  'de': 'Deutsch (maschinell übersetzt)',
  'sl': 'Slovenščina (strojni prevod)',
};

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

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _arb(String language) =>
    jsonDecode(File('lib/l10n/app_$language.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _keys(Map<String, dynamic> arb) =>
    arb.keys.where((key) => !key.startsWith('@')).toSet();

Set<String> _names(String text) =>
    RegExp(r'\{(\w+)[,}]').allMatches(text).map((m) => m.group(1)!).toSet();

void main() {
  final english = _arb('en');

  for (final language in ['hr', 'de', 'sl']) {
    test('$language has every text, with what the code fills in', () {
      final other = _arb(language);
      expect(_keys(english).difference(_keys(other)), isEmpty);
      final wrong = [
        for (final key in _keys(english))
          if (_names(other[key] as String)
              .difference(_names(english[key] as String))
              .isNotEmpty)
            key,
      ];
      expect(wrong, isEmpty);
    });
  }
}

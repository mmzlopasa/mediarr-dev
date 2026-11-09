import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mediarr_api/api.dart';

import '../l10n/l10n.dart';

/// The language of the app. A phone that has not chosen one starts in its own language when the app
/// speaks it, then in the account's.
final languageProvider = NotifierProvider<LanguageNotifier, String>(
  LanguageNotifier.new,
);

class LanguageNotifier extends Notifier<String> {
  static const _key = 'app_language';
  static const _storage = FlutterSecureStorage();
  bool _chosenHere = false;

  @override
  String build() {
    final phone = appLanguageOf(
      PlatformDispatcher.instance.locale.languageCode,
    );
    useLanguage(phone);
    unawaited(_load());
    return phone;
  }

  Future<void> _load() async {
    final saved = await _storage.read(key: _key);
    if (saved == null) return;
    _chosenHere = true;
    _apply(appLanguageOf(saved));
  }

  void _apply(String code) {
    useLanguage(code);
    state = code;
  }

  /// Chooses a language on this phone and, when signed in, for the account.
  Future<void> choose(String code, {DefaultApi? api}) async {
    _chosenHere = true;
    _apply(appLanguageOf(code));
    await _storage.write(key: _key, value: state);
    if (api != null) await _tellAccount(api);
  }

  /// After signing in: a phone that chose keeps its choice and gives it to the account; one that did
  /// not takes the account's.
  Future<void> followAccount(DefaultApi api, Language? account) async {
    if (!_chosenHere) {
      if (account != null) _apply(appLanguageOf(account.value));
      return;
    }
    if (account?.value != state) await _tellAccount(api);
  }

  Future<void> _tellAccount(DefaultApi api) async {
    try {
      await api.updateProfile(
        ProfileUpdate(language: Language.fromJson(state)),
      );
    } on ApiException {
      // The phone keeps its language; the account learns it next time.
    }
  }
}

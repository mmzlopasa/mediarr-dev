import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import 'session.dart';

/// What this person chose, kept on the server so that it follows them to every device.
final accountPreferencesProvider =
    AsyncNotifierProvider<AccountPreferencesNotifier, UserPreferences?>(
      AccountPreferencesNotifier.new,
    );

class AccountPreferencesNotifier extends AsyncNotifier<UserPreferences?> {
  @override
  Future<UserPreferences?> build() async {
    final session = ref.watch(sessionProvider).value;
    if (session == null) return null;
    try {
      return await session.api.getMyPreferences();
    } on ApiException {
      return null;
    }
  }

  Future<void> change(UserPreferences next) async {
    final session = ref.read(sessionProvider).value;
    if (session == null) return;
    final saved = await session.api.setMyPreferences(next);
    state = AsyncData(saved ?? next);
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/api_keys_screen.dart';
import 'package:mediarr_api/api.dart';

void main() {
  test('a key is described by its rights and its end', () {
    final key = ApiKey(
      id: 'a',
      name: 'x',
      createdAt: DateTime(2026),
      scopes: [ApiKeyScopesEnum.read, ApiKeyScopesEnum.upload],
    );
    expect(describeKey(key), 'read, upload');
  });

  test('a phone cannot offer the administrator right', () {
    expect(keyScopes.containsKey(ApiKeyCreateScopesEnum.admin), isFalse);
  });
}

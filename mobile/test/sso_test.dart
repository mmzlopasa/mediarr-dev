import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/services/session.dart';

void main() {
  test('the server sees only the hash of the secret', () {
    const verifier = 'the-secret';
    final address = ssoStartUrl('http://192.168.1.10:9851', verifier);
    expect(address, isNot(contains(verifier)));
    final challenge = Uri.parse(address).queryParameters['appChallenge']!;
    final expected = base64UrlEncode(
      sha256.convert(utf8.encode(verifier)).bytes,
    ).replaceAll('=', '');
    expect(challenge, expected);
    expect(address, startsWith('http://192.168.1.10:9851/api/auth/oidc/start'));
  });

  test('each sign-in has its own secret', () {
    expect(newSsoVerifier(), isNot(newSsoVerifier()));
    expect(newSsoVerifier().length, greaterThan(40));
  });

  test('the code comes from the address the browser came back with', () {
    expect(ssoCodeFrom('mediarr://oidc?code=abc'), 'abc');
    expect(ssoCodeFrom('mediarr://oidc?error=failed'), isNull);
  });
}

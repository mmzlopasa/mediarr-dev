import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/services/session.dart';

void main() {
  test('a sign-in code carries the server and the code', () {
    final link = parseSignInLink(
      'mediarr://sign-in?code=K7QM2XPA&server=http%3A%2F%2F192.168.1.20%3A9851',
    );
    expect(link?.server, 'http://192.168.1.20:9851');
    expect(link?.code, 'K7QM2XPA');
  });

  test('other codes are not sign-in codes', () {
    expect(parseSignInLink('mediarr-keep:abc'), isNull);
    expect(parseSignInLink('https://example.com/?code=1'), isNull);
    expect(parseSignInLink('mediarr://sign-in?code=K7QM2XPA'), isNull);
  });
}

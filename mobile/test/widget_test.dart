import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/login_screen.dart';
import 'package:mediarr/services/session.dart';
import 'package:mediarr/theme.dart';

void main() {
  group('normalizeServerUrl', () {
    test('accepts an IP address and port, as a self-hosted server has', () {
      expect(
        normalizeServerUrl(' 192.168.1.10:9851/ '),
        'http://192.168.1.10:9851',
      );
    });

    test('keeps a full URL', () {
      expect(
        normalizeServerUrl('https://photos.example.com/'),
        'https://photos.example.com',
      );
    });

    test('rejects an empty address', () {
      expect(() => normalizeServerUrl('  '), throwsA(isA<LoginFailure>()));
    });
  });

  group('sessionCookieFrom', () {
    test('reads the token and drops the attributes', () {
      expect(
        sessionCookieFrom(
          'mediarr_session=abc-123; Path=/; HttpOnly; SameSite=Lax',
        ),
        'mediarr_session=abc-123',
      );
    });

    test('returns null without a session cookie', () {
      expect(sessionCookieFrom('other=1'), isNull);
      expect(sessionCookieFrom(null), isNull);
    });
  });

  testWidgets('the login screen asks for the server, email and password', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith(_SignedOut.new)],
        child: MaterialApp(theme: buildTheme(), home: const LoginScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('Server address'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}

class _SignedOut extends SessionNotifier {
  @override
  Future<Session?> build() async => null;

  @override
  Future<String?> lastServer() async => null;
}

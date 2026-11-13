import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mediarr/l10n/l10n.dart';
import 'package:mediarr/screens/login_screen.dart';
import 'package:mediarr/services/session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  testWidgets('a sign-in link names its server and waits for a yes', (
    tester,
  ) async {
    const link = SignInLink('http://evil.example:9851', 'K7QM2XPA');
    final answers = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                answers.add(await confirmSignInLink(context, link)),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.textContaining('http://evil.example:9851'), findsOneWidget);
    await tester.tap(find.text(l.loginScreenCancel));
    await tester.pumpAndSettle();
    expect(answers, [false]);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.loginScreenLinkContinue));
    await tester.pumpAndSettle();
    expect(answers, [false, true]);
  });

  test('an answer that is not JSON is read as nothing', () {
    expect(readJson('<html>401 Authorization Required</html>'), isNull);
    expect(readJson(''), isNull);
    expect(readJson('{"totpRequired":true}'), {'totpRequired': true});
  });

  group('a proxy answering in its own words', () {
    Future<Object?> signInAgainst(int status, String body) async {
      FlutterSecureStorage.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(sessionProvider.future);
      try {
        await http.runWithClient(
          () => container
              .read(sessionProvider.notifier)
              .signIn(
                server: '192.168.1.10:9851',
                email: 'a@example.com',
                password: 'x',
              ),
          () => MockClient((request) async => http.Response(body, status)),
        );
      } on Object catch (cause) {
        return cause;
      }
      return null;
    }

    test('an HTML 401 says the answer could not be read', () async {
      final failure = await signInAgainst(401, '<html>Unauthorized</html>');
      expect(failure, isA<LoginFailure>());
      expect((failure! as LoginFailure).message, l.sessionOddAnswer);
    });

    test('an HTML 403 says the same', () async {
      final failure = await signInAgainst(403, '<html>Forbidden</html>');
      expect((failure! as LoginFailure).message, l.sessionOddAnswer);
    });

    test('a real 401 still says the password is wrong', () async {
      final failure = await signInAgainst(
        401,
        jsonEncode({'totpRequired': false}),
      );
      expect((failure! as LoginFailure).message, l.sessionWrongPassword);
    });

    test('an HTML 200 does not start a session', () async {
      final failure = await signInAgainst(200, '<html>Welcome</html>');
      expect((failure! as LoginFailure).message, l.sessionNoSession);
    });
  });
}

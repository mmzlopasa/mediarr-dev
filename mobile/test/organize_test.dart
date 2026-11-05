import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mediarr/screens/organize_screens.dart';
import 'package:mediarr/services/session.dart';
import 'package:mediarr/theme.dart';
import 'package:mediarr_api/api.dart';

class _FakeSession extends Session {
  _FakeSession(this.handler)
    : super(
        serverUrl: 'http://192.168.1.10:9851',
        cookie: 'mediarr_session=x',
        user: User(
          id: 'u',
          email: 'a@example.com',
          name: 'A',
          isAdmin: false,
          totpEnabled: false,
        ),
      );

  final Future<http.Response> Function(http.Request request) handler;

  @override
  DefaultApi get api {
    final client = ApiClient(basePath: serverUrl);
    client.client = MockClient(handler);
    return DefaultApi(client);
  }
}

class _FakeNotifier extends SessionNotifier {
  _FakeNotifier(this.session);

  final Session session;

  @override
  Future<Session?> build() async => session;
}

http.Response _json(Object? body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Future<void> _show(
  WidgetTester tester,
  Widget child,
  Future<http.Response> Function(http.Request) handler,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith(
          () => _FakeNotifier(_FakeSession(handler)),
        ),
      ],
      child: MaterialApp(
        theme: buildTheme(),
        home: Consumer(
          builder: (context, ref, _) => ref.watch(sessionProvider).value == null
              ? const SizedBox.shrink()
              : child,
        ),
      ),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  familyTests();
  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  test('a photo in the vault stays off the disk, others may stay on it', () {
    final base = _FakeSession((_) async => _json({}));
    expect(base.keepOnDisk, isTrue);
    final vault = CollectionSession(base, 'vault', vaultToken: 'secret');
    expect(vault.keepOnDisk, isFalse);
    expect(vault.headers['X-Vault-Token'], 'secret');
    expect(
      vault.thumbnailUrl('1', large: true),
      'http://192.168.1.10:9851/api/collections/vault/assets/1/thumbnail?size=large',
    );
    expect(CollectionSession(base, 'trash').keepOnDisk, isTrue);
    expect(
      CollectionSession(base, 'trash').headers.containsKey('X-Vault-Token'),
      isFalse,
    );
  });

  testWidgets('an empty archive and trash say so', (tester) async {
    Future<http.Response> server(http.Request request) async =>
        request.url.path == '/api/server/status'
        ? _json({
            'version': '1',
            'updateAvailable': false,
            'diskUsedBytes': 1,
            'diskTotalBytes': 2,
            'trashDays': 7,
          })
        : _json({'buckets': <Object>[]});
    await _show(tester, const ArchiveScreen(), server);
    expect(find.text('The archive is empty.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await _show(tester, const TrashScreen(), server);
    expect(find.text('The trash is empty.'), findsOneWidget);
    // The administrator's number, not one written into the app.
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('after 7 days'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'a vault without a PIN asks for one and says it is not encrypted',
    (tester) async {
      Object? sent;
      await _show(tester, const VaultScreen(), (request) async {
        if (request.url.path.endsWith('/status')) {
          return _json({'hasPin': sent != null, 'unlocked': false});
        }
        if (request.url.path.endsWith('/pin')) {
          sent = jsonDecode(request.body);
          return http.Response('', 204);
        }
        if (request.url.path.endsWith('/unlock')) return _json({'token': 't'});
        return _json({'buckets': <Object>[]});
      });
      expect(find.textContaining('not encrypted'), findsOneWidget);
      expect(find.text('Set PIN'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '4321');
      await tester.tap(find.text('Set PIN'));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect((sent as Map)['pin'], '4321');
      expect(find.text('The vault is empty.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('a wrong PIN opens nothing', (tester) async {
    await _show(tester, const VaultScreen(), (request) async {
      if (request.url.path.endsWith('/status')) {
        return _json({'hasPin': true, 'unlocked': false});
      }
      return _json({'message': 'wrong PIN'}, 401);
    });
    await tester.enterText(find.byType(TextField), '0000');
    await tester.tap(find.text('Unlock'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(find.text('Wrong PIN.'), findsOneWidget);
    expect(find.text('The vault is empty.'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tags come from the server', (tester) async {
    await _show(
      tester,
      const TagsScreen(),
      (request) async => _json([
        {'id': '1', 'name': 'Beach', 'assetCount': 4},
      ]),
    );
    expect(find.text('Beach'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

void familyTests() {
  test('someone outside the family is told why there is nothing', () {
    expect(
      familyClosedText(Family(enabled: false, member: true)),
      contains('administrator'),
    );
    expect(
      familyClosedText(Family(enabled: true, member: false)),
      contains('not in the family'),
    );
    expect(familyClosedText(Family(enabled: true, member: true)), isNull);
  });
}

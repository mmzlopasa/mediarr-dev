import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mediarr/l10n/l10n.dart';
import 'package:mediarr/screens/home_widget_screen.dart';
import 'package:mediarr/services/home_widget.dart';
import 'package:mediarr/services/session.dart';
import 'package:mediarr/theme.dart';
import 'package:mediarr_api/api.dart';

import 'fake_session.dart';

const _channel = MethodChannel('app.mediarr/widget');

Album _album() => Album.fromJson({
  'id': '11111111-1111-1111-1111-111111111111',
  'ownerId': '22222222-2222-2222-2222-222222222222',
  'title': 'Summer',
  'description': '',
  'role': 'owner',
  'ownerName': 'Ana',
  'assetCount': 3,
  'order': 'newest',
  'isSmart': false,
  'members': <Object>[],
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
})!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <String>[];

  void native(Future<Object?> Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) {
          calls.add(call.method);
          return handler(call);
        });
  }

  setUp(calls.clear);
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  Future<http.Response> server(http.Request request) async {
    if (request.method == 'POST') {
      return jsonReply({'id': 'key-new', 'key': 'secret'}, 201);
    }
    return http.Response('', 204);
  }

  test('a new key is handed over before the old one is revoked', () async {
    FlutterSecureStorage.setMockInitialValues({'widget_key_id': 'key-old'});
    native((call) async => null);
    final session = RecordingSession(server);
    await HomeWidgetService().choose(session, _album());
    expect(session.requests, [
      'POST /api/me/api-keys',
      'DELETE /api/me/device-keys/key-old',
    ]);
    expect(calls, ['configure']);
    expect(
      await const FlutterSecureStorage().read(key: 'widget_key_id'),
      'key-new',
    );
  });

  test('when no key can be made, the widget keeps the one it has', () async {
    FlutterSecureStorage.setMockInitialValues({'widget_key_id': 'key-old'});
    native((call) async => null);
    final session = RecordingSession(
      (request) async => http.Response('nope', 500),
    );
    await expectLater(
      HomeWidgetService().choose(session, _album()),
      throwsA(isA<ApiException>()),
    );
    expect(session.requests, ['POST /api/me/api-keys']);
    expect(calls, isEmpty);
    expect(
      await const FlutterSecureStorage().read(key: 'widget_key_id'),
      'key-old',
    );
  });

  test(
    'a key the widget could not take is revoked, and the old one stays',
    () async {
      FlutterSecureStorage.setMockInitialValues({'widget_key_id': 'key-old'});
      native((call) async => throw PlatformException(code: 'keychain'));
      final session = RecordingSession(server);
      await expectLater(
        HomeWidgetService().choose(session, _album()),
        throwsA(isA<ApiException>()),
      );
      expect(session.requests, [
        'POST /api/me/api-keys',
        'DELETE /api/me/device-keys/key-new',
      ]);
      expect(
        await const FlutterSecureStorage().read(key: 'widget_key_id'),
        'key-old',
      );
    },
  );

  test('signing out clears the widget and revokes its key', () async {
    FlutterSecureStorage.setMockInitialValues({'widget_key_id': 'key-old'});
    native((call) async => null);
    final session = RecordingSession(server);
    await HomeWidgetService().forget(session);
    expect(calls, ['clear']);
    expect(session.requests, ['DELETE /api/me/device-keys/key-old']);
    expect(
      await const FlutterSecureStorage().read(key: 'widget_key_id'),
      isNull,
    );
  });

  test('signing out works without a widget and without a connection', () async {
    FlutterSecureStorage.setMockInitialValues({'widget_key_id': 'key-old'});
    final session = RecordingSession(
      (request) async => throw const SocketExceptionStandIn(),
    );
    await HomeWidgetService().forget(session);
    expect(
      await const FlutterSecureStorage().read(key: 'widget_key_id'),
      isNull,
    );
  });

  test('a phone that cannot answer counts as no widget chosen', () async {
    native((call) async => throw PlatformException(code: 'broken'));
    final choice = await HomeWidgetService().status();
    expect(choice.chosen, isFalse);
  });

  test(
    'the widget key is named in the chosen language, others as they are',
    () {
      expect(apiKeyLabel(widgetKeyName), l.homeWidgetKeyName);
      expect(apiKeyLabel('Backups'), 'Backups');
    },
  );

  test('a fine install says what to do if iOS still does not offer it', () {
    expect(l.widgetInstallFine, contains('in the app and signed'));
    expect(l.widgetInstallFine, contains('install it again'));
  });

  testWidgets(
    'albums that could not be loaded say so, not that there are none',
    (tester) async {
      native((call) async => throw PlatformException(code: 'broken'));
      final session = RecordingSession(
        (request) async => http.Response('down', 502),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sessionProvider.overrideWith(() => _Signed(session))],
          // As in the app, the screen opens only once the session is known.
          child: MaterialApp(
            theme: buildTheme(),
            home: Consumer(
              builder: (context, ref, _) =>
                  ref.watch(sessionProvider).value == null
                  ? const SizedBox.shrink()
                  : const HomeWidgetScreen(),
            ),
          ),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(
        find.byKey(const ValueKey('widget-albums-failed')),
        findsOneWidget,
      );
      expect(find.text(l.homeWidgetScreenNoAlbums), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

class SocketExceptionStandIn implements Exception {
  const SocketExceptionStandIn();
}

class _Signed extends SessionNotifier {
  _Signed(this.session);

  final Session session;

  @override
  Future<Session?> build() async => session;
}

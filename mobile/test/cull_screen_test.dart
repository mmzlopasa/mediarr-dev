import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mediarr/l10n/app_localizations.dart';
import 'package:mediarr/screens/cull_screen.dart';
import 'package:mediarr/services/session.dart';
import 'package:mediarr_api/api.dart';

const _photo = '11111111-1111-4111-8111-111111111111';

class _FakeSession extends Session {
  _FakeSession(this.handler)
    : super(
        serverUrl: 'http://192.168.1.10:9851',
        cookie: 'mediarr_session=x',
        user: User(
          id: '22222222-2222-2222-2222-222222222222',
          email: 'a@example.com',
          name: 'A',
          isAdmin: false,
          totpEnabled: false,
        ),
      );

  final Future<http.Response> Function(http.Request request) handler;

  @override
  bool get keepOnDisk => false;

  @override
  DefaultApi get api {
    final client = ApiClient(basePath: serverUrl);
    client.client = MockClient(handler);
    return DefaultApi(client);
  }
}

void main() {
  testWidgets('it fits a narrow phone, and a mark reaches the server', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final picks = <int>[];
    final session = _FakeSession((request) async {
      if (request.url.path.endsWith('/pick/read')) {
        return http.Response(
          jsonEncode({
            'items': [
              {'id': _photo, 'pick': 0, 'rating': 2},
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path.endsWith('/pick')) {
        picks.add(jsonDecode(request.body)['pick'] as int);
        return http.Response(
          '{"changed":1}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('', 404);
    });
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('hr'),
        home: CullScreen(
          session: session,
          items: [
            TimelineItem(
              id: _photo,
              kind: TimelineItemKindEnum.photo,
              ratio: 1,
              isFavorite: false,
              localAt: '2024-07-01T10:00:00',
            ),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('cull-tally')), findsOneWidget);

    await tester.drag(find.byKey(const Key('cull-stage')), const Offset(0, -300));
    await tester.pump(const Duration(milliseconds: 100));
    expect(picks, [1]);
    expect(tester.takeException(), isNull);
  });
}

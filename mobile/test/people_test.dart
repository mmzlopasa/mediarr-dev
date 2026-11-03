import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mediarr/screens/people_screens.dart';
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
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  test('filters are shown as the server understood them', () {
    final labels = filterLabels(
      SearchFilters(
        from: DateTime.utc(2024),
        to: DateTime.utc(2024, 12, 31),
        person: 'Ana',
        place: 'Hvar',
      ),
    );
    expect(labels, ['2024-01-01 – 2024-12-31', 'Ana', 'Hvar']);
    expect(filterLabels(SearchFilters()), isEmpty);
  });

  testWidgets('people say when recognition is off, and when nobody is known', (
    tester,
  ) async {
    await _show(
      tester,
      const PeopleScreen(),
      (_) async => _json({'enabled': false, 'people': <Object>[]}),
    );
    expect(find.textContaining('not turned on'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await _show(
      tester,
      const PeopleScreen(),
      (_) async => _json({'enabled': true, 'people': <Object>[]}),
    );
    expect(find.text('No people recognised yet.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'only visible people are listed until hidden ones are asked for',
    (tester) async {
      await _show(
        tester,
        const PeopleScreen(),
        (_) async => _json({
          'enabled': true,
          'people': [
            {'id': '1', 'name': 'Ana', 'hidden': false, 'assetCount': 4},
            {'id': '2', 'name': 'Secret', 'hidden': true, 'assetCount': 2},
          ],
        }),
      );
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Secret'), findsNothing);
      await tester.tap(find.text('Hidden people'));
      await tester.pump();
      expect(find.text('Secret'), findsOneWidget);
      expect(find.text('Ana'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('a search shows its filters and says when nothing is found', (
    tester,
  ) async {
    await _show(
      tester,
      const SearchScreen(),
      (request) async => _json({
        'items': <Object>[],
        'smart': false,
        'filters': {'place': 'Hvar'},
      }),
    );
    expect(find.textContaining('Describe what'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Hvar');
    await tester.tap(find.byTooltip('Search'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(find.text('Hvar'), findsWidgets);
    expect(find.text('Nothing was found.'), findsOneWidget);
    expect(find.textContaining('Smart search is off'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

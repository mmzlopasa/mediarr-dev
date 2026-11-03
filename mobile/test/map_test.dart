import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mediarr/screens/map_screen.dart';
import 'package:mediarr/services/session.dart';
import 'package:mediarr/services/timeline.dart';
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

const _style = {'light': 'http://s/l.json', 'dark': 'http://s/d.json'};

Future<void> _show(
  WidgetTester tester,
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
              : MapScreen(
                  mapBuilder: (style, points, onPhoto) =>
                      Text('native map $style ${points.ids.length}'),
                ),
        ),
      ),
    ),
  );
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  test('every photo keeps its id on the map', () {
    final json = pointsToGeoJson(
      MapPoints(ids: ['a'], kinds: ['photo'], lats: [43.1], lons: [16.4]),
    );
    final feature = (json['features'] as List).single as Map;
    expect(feature['id'], 'a');
    expect((feature['geometry'] as Map)['coordinates'], [16.4, 43.1]);
  });

  test('a known list needs no server', () {
    final store = TimelineStore.fixed(null, [
      TimelineItem(
        id: 'a',
        kind: TimelineItemKindEnum.photo,
        ratio: 1,
        isFavorite: false,
        localAt: '',
      ),
    ]);
    expect(store.loadedItems.single.id, 'a');
    store.dispose();
  });

  testWidgets('no located photos says so', (tester) async {
    await _show(tester, (request) async {
      if (request.url.path.endsWith('/style')) return _json(_style);
      if (request.url.path.endsWith('/trips')) return _json(<Object>[]);
      return _json({'ids': [], 'kinds': [], 'lats': [], 'lons': []});
    });
    expect(find.text('No photos with a location yet.'), findsOneWidget);
    expect(find.textContaining('native map'), findsNothing);
  });

  testWidgets('points and trips come from the server', (tester) async {
    await _show(tester, (request) async {
      if (request.url.path.endsWith('/style')) return _json(_style);
      if (request.url.path.endsWith('/trips')) {
        return _json([
          {
            'from': '2024-06-10',
            'to': '2024-06-12',
            'count': 3,
            'coverId': 'a',
            'lat': 43.1,
            'lon': 16.4,
            'places': ['Hvar', 'Vis'],
          },
        ]);
      }
      return _json({
        'ids': ['a'],
        'kinds': ['photo'],
        'lats': [43.1],
        'lons': [16.4],
      });
    });
    expect(find.text('native map http://s/d.json 1'), findsOneWidget);
    expect(find.text('Hvar, Vis'), findsOneWidget);
    expect(find.text('Photos: 1'), findsOneWidget);
  });

  testWidgets('a failure is not shown as an empty map', (tester) async {
    await _show(tester, (request) async => _json({'message': 'no'}, 500));
    expect(find.textContaining('could not be loaded'), findsOneWidget);
    expect(find.text('No photos with a location yet.'), findsNothing);
  });
}

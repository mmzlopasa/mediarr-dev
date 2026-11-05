import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mediarr/screens/explore_screen.dart';
import 'package:mediarr/services/session.dart';
import 'package:mediarr_api/api.dart';

class _FakeSession extends Session {
  _FakeSession(this.handler)
    : super(
        serverUrl: 'http://server',
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

Future<void> _show(
  WidgetTester tester,
  Future<http.Response> Function(http.Request request) handler,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith(
          () => _FakeNotifier(_FakeSession(handler)),
        ),
      ],
      child: const MaterialApp(home: _Waits()),
    ),
  );
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

/// Opens Explore once the session is there, as it is by the time anyone reaches it.
class _Waits extends ConsumerWidget {
  const _Waits();

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(sessionProvider).value == null
      ? const SizedBox()
      : const ExploreScreen();
}

void main() {
  testWidgets('empty parts say so', (tester) async {
    await _show(tester, (request) async {
      final body = switch (request.url.path) {
        '/api/people' => {'enabled': true, 'people': []},
        '/api/explore/places' => {'places': []},
        _ => <dynamic>[],
      };
      return http.Response(
        jsonEncode(body),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    expect(find.text('No named people yet.'), findsOneWidget);
    expect(find.text('No photos with a place yet.'), findsOneWidget);
    expect(find.text('No memories today.'), findsOneWidget);
  });

  testWidgets('one part failing leaves the others', (tester) async {
    await _show(tester, (request) async {
      if (request.url.path == '/api/explore/places') {
        return http.Response('{"message":"no"}', 500);
      }
      final body = request.url.path == '/api/people'
          ? {'enabled': true, 'people': []}
          : <dynamic>[];
      return http.Response(
        jsonEncode(body),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    expect(find.text('Places could not be loaded.'), findsOneWidget);
    expect(find.text('No named people yet.'), findsOneWidget);
    expect(find.text('No memories today.'), findsOneWidget);
  });
}

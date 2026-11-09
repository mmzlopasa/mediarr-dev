import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mediarr/screens/admin/overview_screen.dart';
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
          isAdmin: true,
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

Future<http.Response> _overview(http.Request request, Object health) async {
  final body = request.url.path.endsWith('/health')
      ? health
      : <String, Object>{
          'users': 1,
          'photos': 2,
          'videos': 0,
          'libraryBytes': 100,
          'processing': 0,
          'failed': 0,
          'diskFreeBytes': 1000,
          'diskTotalBytes': 2000,
          'jobs': {'queued': 0, 'running': 0, 'completed': 0, 'failed': 0},
          'databaseVersion': '16',
          'version': '1.0.0',
        };
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    200,
    headers: {'content-type': 'application/json'},
  );
}

Future<void> _show(WidgetTester tester, Object health) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith(
          () => _FakeNotifier(
            _FakeSession((request) => _overview(request, health)),
          ),
        ),
      ],
      child: MaterialApp(
        theme: buildTheme(),
        home: Consumer(
          builder: (context, ref, _) => ref.watch(sessionProvider).value == null
              ? const SizedBox.shrink()
              : const AdminOverviewScreen(),
        ),
      ),
    ),
  );
  await tester.pump();
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  testWidgets('the admin sees the models, the memory and the acceleration', (
    tester,
  ) async {
    await _show(tester, {
      'workerRunning': true,
      'mlEnabled': true,
      'databaseBytes': 1000,
      'mlRunning': true,
      'ml': {
        'state': 'connected',
        'models': [
          {'name': 'clip-text', 'loaded': true, 'inUse': 0, 'idleSeconds': 2},
          {'name': 'ocr', 'loaded': false, 'inUse': 0},
        ],
        'rssBytes': 1048576,
        'acceleration': {
          'requested': 'cpu',
          'providers': ['CPUExecutionProvider'],
        },
        'idleMinutes': 5,
      },
    });
    final list = find.byType(Scrollable);
    await tester.scrollUntilVisible(
      find.text('Connected'),
      300,
      scrollable: list.first,
    );
    expect(find.text('Connected'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('clip-text'),
      300,
      scrollable: list.first,
    );
    expect(find.text('clip-text'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('CPUExecutionProvider'),
      300,
      scrollable: list.first,
    );
    expect(find.textContaining('CPUExecutionProvider'), findsOneWidget);
  });

  testWidgets('the admin is told when the token is wrong', (tester) async {
    await _show(tester, {
      'workerRunning': true,
      'mlEnabled': true,
      'databaseBytes': 1000,
      'mlRunning': false,
      'ml': {'state': 'wrongToken'},
    });
    await tester.scrollUntilVisible(
      find.textContaining('refused the token'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('refused the token'), findsOneWidget);
  });
}

// Pictures of the app's screens against the running demo, for design review. Not part of the test
// suite: run with `flutter test tool/shots/shots_test.dart --update-goldens`; the images land in
// build/shots.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/main.dart';
import 'package:mediarr/services/session.dart';
import 'package:mediarr_api/api.dart';

const _server = 'http://127.0.0.1:9852';

/// Material icons and Roboto ship with Flutter itself.
final _sdkFonts =
    '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';

/// Pictures stay in memory: the disk cache needs plugins a test does not have.
class _ShotSession extends Session {
  _ShotSession({
    required super.serverUrl,
    required super.cookie,
    required super.user,
  });

  @override
  bool get keepOnDisk => false;
}

class _Signed extends SessionNotifier {
  _Signed(this.session);

  final Session session;

  @override
  Future<Session?> build() async => session;
}

Future<void> _font(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(
      File(file).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
    );
  }
  await loader.load();
}

Future<Session> _signIn(String theme) async {
  final client = HttpClient();
  final request = await client.postUrl(Uri.parse('$_server/api/auth/login'));
  request.headers.contentType = ContentType.json;
  request.write(
    jsonEncode({'email': 'demo@mediarr.app', 'password': 'mediarr-demo'}),
  );
  final response = await request.close();
  final body = jsonDecode(await response.transform(utf8.decoder).join());
  final cookie = response.cookies.firstWhere(
    (c) => c.name == 'mediarr_session',
  );
  client.close();
  return _ShotSession(
    serverUrl: _server,
    cookie: 'mediarr_session=${cookie.value}',
    user: User.fromJson(body['user'] ?? body)!,
  );
}

Future<void> _settle(WidgetTester tester, [int seconds = 3]) async {
  for (var i = 0; i < seconds * 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _shot(WidgetTester tester, String name) => expectLater(
  find.byType(MaterialApp),
  matchesGoldenFile('../../build/shots/$name.png'),
);

void main() {
  testWidgets('screens', (tester) async {
    HttpOverrides.global = null;
    await tester.runAsync(() async {
      await _font('Inter Tight', ['assets/fonts/InterTight.ttf']);
      await _font('JetBrains Mono', ['assets/fonts/JetBrainsMono.ttf']);
      await _font('MaterialIcons', ['$_sdkFonts/MaterialIcons-Regular.otf']);
      await _font('Roboto', ['$_sdkFonts/Roboto-Regular.ttf']);
    });
    final theme = Platform.environment['SHOT_THEME'] ?? 'dark';
    FlutterSecureStorage.setMockInitialValues({
      'app_settings': jsonEncode({'theme': theme}),
    });
    final session = (await tester.runAsync(() => _signIn(theme)))!;
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith(() => _Signed(session))],
        child: const MediarrApp(),
      ),
    );
    await _settle(tester, 8);
    await _shot(tester, '$theme-01-library');

    Future<void> tapText(String text) async {
      final found = find.text(text);
      if (found.evaluate().isEmpty) {
        debugPrint('shots: no "$text"');
        return;
      }
      await tester.tap(found.first, warnIfMissed: false);
      await _settle(tester, 3);
    }

    Future<void> back() async {
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).last,
      );
      navigator.maybePop();
      await _settle(tester, 2);
    }

    await tester.tap(find.byType(Image).at(1), warnIfMissed: false);
    await _settle(tester, 4);
    await _shot(tester, '$theme-02-viewer');
    final details = find.byTooltip('Details');
    if (details.evaluate().isNotEmpty) {
      await tester.tap(details.first);
      await _settle(tester, 3);
      await _shot(tester, '$theme-03-viewer-details');
      await back();
    }
    await back();

    await tapText('Search');
    await _shot(tester, '$theme-04-search');
    await tapText('Albums');
    await _shot(tester, '$theme-05-albums');
    await tapText('Library');
    await _shot(tester, '$theme-06-library-tab');
    for (final (name, label) in [
      ('07-people', 'People'),
      ('08-map', 'Map'),
      ('09-memories', 'Memories'),
      ('10-favorites', 'Favorites'),
    ]) {
      if (find.text(label).evaluate().isEmpty) continue;
      await tapText(label);
      await _shot(tester, '$theme-$name');
      await back();
    }
    await tapText('Media');
    final avatar = find.text('DE');
    if (avatar.evaluate().isNotEmpty) {
      await tester.tap(avatar.first, warnIfMissed: false);
      await _settle(tester, 3);
      await _shot(tester, '$theme-11-account');
    }
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/settings_screen.dart';
import 'package:mediarr/services/session.dart';
import 'package:mediarr/services/settings.dart';
import 'package:mediarr/theme.dart';
import 'package:mediarr_api/api.dart';
import 'package:mediarr/timeline/layout.dart';

void main() {
  final now = DateTime(2026, 11, 4);
  bool may(
    FreeSpaceRules rules, {
    int age = 400,
    bool video = false,
    bool favorite = false,
    bool album = false,
  }) => rules.mayRemove(
    taken: now.subtract(Duration(days: age)),
    now: now,
    isVideo: video,
    isFavorite: favorite,
    inKeptAlbum: album,
  );

  group('free up space rules', () {
    test('by default favorites stay and everything else may go', () {
      const rules = FreeSpaceRules();
      expect(may(rules), isTrue);
      expect(may(rules, favorite: true), isFalse);
    });

    test('a kept album wins over everything', () {
      expect(
        may(const FreeSpaceRules(keepFavorites: false), album: true),
        isFalse,
      );
    });

    test('kept kinds stay', () {
      expect(may(const FreeSpaceRules(keepVideos: true), video: true), isFalse);
      expect(may(const FreeSpaceRules(keepVideos: true)), isTrue);
      expect(may(const FreeSpaceRules(keepPhotos: true)), isFalse);
      expect(may(const FreeSpaceRules(keepPhotos: true), video: true), isTrue);
    });

    test('newer than the limit stays', () {
      const rules = FreeSpaceRules(olderThanDays: 365);
      expect(may(rules, age: 364), isFalse);
      expect(may(rules, age: 365), isTrue);
    });
  });

  test('settings survive being saved and read back', () {
    final settings = AppSettings(
      perRow: 3,
      groupByDay: false,
      loopVideos: true,
      accent: AppAccent.mint,
      readOnly: true,
      freeSpace: FreeSpaceRules(olderThanDays: 90, keepAlbums: ['a']),
    );
    final back = AppSettings.fromJson(settings.toJson());
    expect(back.perRow, 3);
    expect(back.groupByDay, isFalse);
    expect(back.loopVideos, isTrue);
    expect(back.accent, AppAccent.mint);
    expect(back.readOnly, isTrue);
    expect(back.freeSpace.olderThanDays, 90);
    expect(back.freeSpace.keepAlbums, ['a']);
    expect(AppSettings.fromJson(const {'perRow': 99}).perRow, maxPerRow);
  });

  test('what is kept to oneself when sharing is remembered', () {
    const fresh = AppSettings();
    expect(fresh.shareRemoveLocation, isTrue);
    expect(fresh.shareRemoveCamera, isTrue);
    expect(fresh.shareHideFaces, isFalse);
    final changed = AppSettings.fromJson(
      fresh.copyWith(shareRemoveLocation: false, shareHideFaces: true).toJson(),
    );
    expect(changed.shareRemoveLocation, isFalse);
    expect(changed.shareRemoveCamera, isTrue);
    expect(changed.shareHideFaces, isTrue);
  });

  test('the accent is midnight blue with contrast in both themes, and the button stays gold', () {
    Palette.light = false;
    expect(Palette.gold, const Color(0xFF8FB0FF));
    expect(Palette.buttonGold, const Color(0xFFFFD76A));
    Palette.light = true;
    expect(Palette.gold, isNot(Palette.buttonGold));
    expect(Palette.gold.computeLuminance(), lessThan(0.2));
    expect(Palette.bg.computeLuminance(), greaterThan(0.5));
    Palette.light = false;
    expect(Palette.bg.computeLuminance(), lessThan(0.1));
  });

  test('both themes can be built, and building one changes nothing', () {
    Palette.light = false;
    expect(buildTheme(light: true).brightness, Brightness.light);
    expect(buildTheme().brightness, Brightness.dark);
    expect(Palette.light, isFalse);
  });

  test('a fixed number to a row makes equal squares', () {
    final items = [
      for (var i = 0; i < 5; i++)
        TimelineItem(
          id: '$i',
          kind: TimelineItemKindEnum.photo,
          ratio: 2,
          isFavorite: false,
          localAt: '2026-01-01T10:00:00',
        ),
    ];
    final rows = squares(items, 10, 100, 2);
    expect(rows.length, 3);
    expect(rows.first.tiles.length, 2);
    expect(rows.last.tiles.length, 1);
    expect(rows.first.tiles.first.width, rows.first.height);
    expect(rows.last.tiles.first.index, 14);
  });

  group('choosing a server address', () {
    Future<bool> Function(String) only(Set<String> up) =>
        (server) async => up.contains(server);

    test('with one address nothing is asked', () async {
      expect(await pickServer('a', null, only({})), 'a');
    });

    test('the main address wins when both answer', () async {
      expect(await pickServer('a', 'b', only({'a', 'b'})), 'a');
    });

    test('the second is used when the main does not answer', () async {
      expect(await pickServer('a', 'b', only({'b'})), 'b');
    });

    test('with neither there is no answer', () async {
      expect(await pickServer('a', 'b', only({})), isNull);
    });
  });

  testWidgets('a screen in a transition covers the one under it', (
    tester,
  ) async {
    for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(platform),
          theme: buildTheme().copyWith(platform: platform),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(body: Text('Next page')),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(
        find.ancestor(
          of: find.text('Next page'),
          matching: find.byType(SkyBackground),
        ),
        findsOneWidget,
        reason: platform.name,
      );
      await tester.pumpAndSettle();
    }
  });

  testWidgets('read-only mode is set under Advanced', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AdvancedSettings()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Read-only mode'));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).readOnly, isTrue);
  });

  testWidgets('the settings list offers every subject', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    for (final title in ['Asset viewer', 'Photo grid', 'Preferences']) {
      expect(find.text(title), findsOneWidget);
    }
  });
}

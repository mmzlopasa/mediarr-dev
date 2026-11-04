import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/settings_screen.dart';
import 'package:mediarr/services/settings.dart';
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
    const settings = AppSettings(
      gridSize: GridSize.large,
      readOnly: true,
      freeSpace: FreeSpaceRules(olderThanDays: 90, keepAlbums: ['a']),
    );
    final back = AppSettings.fromJson(settings.toJson());
    expect(back.gridSize, GridSize.large);
    expect(back.readOnly, isTrue);
    expect(back.freeSpace.olderThanDays, 90);
    expect(back.freeSpace.keepAlbums, ['a']);
    expect(
      AppSettings.fromJson(const {'gridSize': 'unknown'}).gridSize,
      GridSize.medium,
    );
  });

  test('a larger grid size makes rows taller', () {
    expect(
      rowHeightFor(400, GridSize.large.scale),
      greaterThan(rowHeightFor(400)),
    );
    expect(
      rowHeightFor(400, GridSize.small.scale),
      lessThan(rowHeightFor(400)),
    );
  });

  testWidgets('choosing a grid size and read-only mode changes the settings', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Free up space'), findsOneWidget);

    await tester.tap(find.text('Large'));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).gridSize, GridSize.large);

    await tester.tap(find.text('Read-only mode'));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).readOnly, isTrue);
    expect(find.text('Free up space'), findsNothing);
  });
}

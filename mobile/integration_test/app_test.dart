import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mediarr/main.dart';
import 'package:mediarr/screens/asset_picture.dart';
import 'package:mediarr/services/backup.dart';
import 'package:mediarr/services/session.dart';
import 'package:photo_manager/photo_manager.dart';

import 'fake_server.dart';

/// A real picture for the phone's library: larger than the tiny one, and new on every run.
Future<AssetEntity> addPhotoToAlbum(String albumName) async {
  final album = await PhotoManager.editor.darwin.createAlbum(albumName);
  final saved = await PhotoManager.editor.saveImage(
    base64Decode(tinyJpeg),
    filename: 'phone.jpg',
    title: 'phone.jpg',
  );
  await PhotoManager.editor.copyAssetToPath(asset: saved, pathEntity: album!);
  return saved;
}

/// Spinners and timers never settle, so this waits for what the user would wait for.
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TimeoutException('Never appeared: $finder');
}

Future<void> signIn(WidgetTester tester, String server, String pass) async {
  await waitFor(tester, find.text('Sign in'));
  await tester.enterText(
    find.widgetWithText(TextField, 'Server address'),
    server,
  );
  await tester.enterText(find.widgetWithText(TextField, 'Email'), email);
  await tester.enterText(find.widgetWithText(TextField, 'Password'), pass);
  await tester.tap(find.text('Sign in'));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late FakeServer server;

  setUp(() async {
    debugPrint('setUp: clearing the keychain');
    await const FlutterSecureStorage().deleteAll();
    server = FakeServer();
    await server.start();
    debugPrint('setUp: server at ${server.address}');
  });

  tearDown(() => server.stop());

  testWidgets(
    'a wrong password is refused, and the right one opens the library',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MediarrApp()));

      await signIn(tester, server.address, 'wrong');
      await waitFor(tester, find.text('Wrong email or password.'));

      await signIn(tester, server.address, password);
      await waitFor(tester, find.byType(AssetPicture));

      // The photo opens in the viewer, with its details.
      await tester.tap(find.byType(AssetPicture).first);
      await waitFor(tester, find.byTooltip('Details'));
      await tester.tap(find.byTooltip('Details'));
      await waitFor(tester, find.text('beach.jpg'));
    },
  );

  testWidgets('the native backup sends a photo from the chosen album, once', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MediarrApp()));
    await signIn(tester, server.address, password);
    await waitFor(tester, find.byType(AssetPicture));

    final state = await PhotoManager.requestPermissionExtend();
    expect(state.hasAccess, isTrue, reason: 'CI grants access beforehand');
    final albumName = 'Mediarr test ${DateTime.now().millisecondsSinceEpoch}';
    await addPhotoToAlbum(albumName);

    final element = tester.element(find.byType(AssetPicture).first);
    final container = ProviderScope.containerOf(element);
    final session = container.read(sessionProvider).value!;
    final backup = container.read(backupProvider);

    // Another photo outside the album must stay on the phone.
    await PhotoManager.editor.saveImage(
      base64Decode(tinyJpeg),
      filename: 'private.jpg',
      title: 'private.jpg',
    );

    final albums = await backup.albums();
    final album = albums.firstWhere((a) => a.title == albumName);
    await backup.enable(
      session,
      wifiOnly: false,
      onlyNew: false,
      albumId: album.id,
      albumName: albumName,
    );

    final end = DateTime.now().add(const Duration(minutes: 3));
    var status = await backup.status();
    while (status.verified < 1 && DateTime.now().isBefore(end)) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 1)),
      );
      status = await backup.status();
    }
    expect(status.failures, isEmpty);
    expect(
      status.verified,
      1,
      reason: 'status: pending ${status.pending}, working ${status.working}',
    );
    expect(server.uploads, hasLength(1));
    final upload = server.uploads.single;
    expect(upload.actualChecksum, upload.declaredChecksum);

    // Another look through the album sends nothing again.
    await backup.setAlbum(
      albumId: album.id,
      albumName: albumName,
      onlyNew: false,
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 10)),
    );
    expect(server.uploads, hasLength(1));

    await backup.disable(session);
  });
}

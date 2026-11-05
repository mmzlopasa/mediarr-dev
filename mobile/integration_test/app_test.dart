import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  if (Platform.isAndroid) {
    // On Android an album is the folder a photo is in.
    return PhotoManager.editor.saveImage(
      base64Decode(tinyJpeg),
      filename: 'phone.jpg',
      title: 'phone.jpg',
      relativePath: 'Pictures/$albumName',
    );
  }
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
  // The keyboard moves the button, and a tap during that goes past it.
  FocusManager.instance.primaryFocus?.unfocus();
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.ensureVisible(find.text('Sign in'));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text('Sign in'), warnIfMissed: false);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late FakeServer server;

  // Stays up for the whole run: a picture may still be loading when a test ends.
  setUpAll(() async {
    server = FakeServer();
    await server.start();
    debugPrint('server at ${server.address}');
  });

  tearDownAll(() => server.stop());

  setUp(() async {
    debugPrint('setUp: clearing the keychain');
    await const FlutterSecureStorage().deleteAll();
    server.uploads.clear();
    debugPrint('setUp: done');
  });

  testWidgets(
    'a wrong password is refused, and the right one opens the library',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MediarrApp()));

      await signIn(tester, server.address, 'wrong');
      await waitFor(tester, find.text('Wrong email or password.'));

      await signIn(tester, server.address, password);
      await waitFor(tester, find.byType(AssetPicture));

      // The photo opens in the viewer, with its details.
      await tester.tap(find.byType(AssetPicture).first, warnIfMissed: false);
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

    debugPrint('backup test: asking for photos');
    // Only reads the state: asking would open a dialog that nobody can answer.
    final state = await PhotoManager.getPermissionState(
      requestOption: const PermissionRequestOption(),
    );
    debugPrint('backup test: access to photos is $state');
    expect(state.hasAccess, isTrue, reason: 'CI grants access beforehand');
    final albumName = 'Mediarr test ${DateTime.now().millisecondsSinceEpoch}';
    debugPrint('backup test: adding a photo to the album');
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

    debugPrint('backup test: listing albums');
    final albums = await backup.albums();
    final album = albums.firstWhere((a) => a.title == albumName);
    debugPrint('backup test: enabling backup');
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
    debugPrint(
      'backup test: finished waiting: verified ${status.verified}, pending ${status.pending}, working ${status.working}, failed ${status.failed}',
    );
    expect(status.failures, isEmpty);
    expect(
      status.verified,
      1,
      reason: 'status: pending ${status.pending}, working ${status.working}',
    );
    expect(server.uploads, hasLength(1));
    final upload = server.uploads.single;
    expect(upload.actualChecksum, upload.declaredChecksum);
    expect(upload.name, contains('phone'), reason: 'only the chosen album');

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
    // The simulator records the access, yet the app still reads it as not decided, and a dialog
    // nobody can answer then waits forever. On iOS this has to be confirmed on a real iPhone.
  }, skip: Platform.isIOS);

  testWidgets('the bell lists what the server has to say', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MediarrApp()));
    await signIn(tester, server.address, password);
    await waitFor(tester, find.byType(AssetPicture));
    await tester.tap(find.byTooltip('Notifications').first);
    await waitFor(tester, find.text('The import from immich finished'));
    await tester.tap(find.byTooltip('Remove').first);
  });

  testWidgets('the details name the faces in a photo', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MediarrApp()));
    await signIn(tester, server.address, password);
    await waitFor(tester, find.byType(AssetPicture));
    await tester.tap(find.byType(AssetPicture).first);
    await waitFor(tester, find.byTooltip('Details'));
    await tester.tap(find.byTooltip('Details'));
    await waitFor(tester, find.text('Ana'));
    expect(find.byTooltip('Who this is'), findsOneWidget);
    await tester.tap(find.text('Edit details'));
    await waitFor(tester, find.text('Use what the file says'));
  });

  testWidgets('Explore shows the places in the library', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MediarrApp()));
    await signIn(tester, server.address, password);
    await waitFor(tester, find.byType(AssetPicture));
    await tester.tap(find.text('Library').last);
    await waitFor(tester, find.text('Explore'));
    await tester.tap(find.text('Explore'));
    await waitFor(tester, find.text('Hvar'));
  });

  testWidgets('read-only mode takes away uploading and deleting', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MediarrApp()));
    await signIn(tester, server.address, password);
    await waitFor(tester, find.byType(AssetPicture));
    expect(find.byTooltip('Add'), findsWidgets);

    await tester.tap(find.byTooltip('Account').first);
    await waitFor(tester, find.text('Settings'));
    await tester.tap(find.text('Settings'));
    await waitFor(tester, find.text('Asset viewer'));
    await tester.scrollUntilVisible(
      find.text('Advanced'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text('Advanced'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Advanced'), warnIfMissed: false);
    await tester.pump(const Duration(seconds: 1));
    await waitFor(tester, find.text('Read-only mode'));
    await tester.tap(find.text('Read-only mode'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pageBack();
    await tester.pump(const Duration(seconds: 1));
    await tester.pageBack();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byTooltip('Add'), findsNothing);
    await tester.tap(find.text('Media').last);
    await waitFor(tester, find.byType(AssetPicture));
    await tester.tap(find.byType(AssetPicture).first, warnIfMissed: false);
    await waitFor(tester, find.byTooltip('Details'));
    expect(find.byTooltip('Delete'), findsNothing);

    await const FlutterSecureStorage().delete(key: 'app_settings');
  });

  testWidgets('a second album is sent too', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MediarrApp()));
    await signIn(tester, server.address, password);
    await waitFor(tester, find.byType(AssetPicture));
    final element = tester.element(find.byType(AssetPicture).first);
    final container = ProviderScope.containerOf(element);
    final session = container.read(sessionProvider).value!;
    final backup = container.read(backupProvider);

    await addPhotoToAlbum('MediarrFirst');
    final extra = await addPhotoToAlbum('MediarrSecond');
    final albums = await backup.albums();
    final first = albums.firstWhere((a) => a.title == 'MediarrFirst');
    final second = albums.firstWhere((a) => a.title == 'MediarrSecond');
    await backup.enable(
      session,
      wifiOnly: false,
      onlyNew: false,
      albumId: first.id,
      albumName: first.title,
    );
    await backup.setAlbumLists(
      more: [second.id],
      excluded: const [],
      onlyNew: false,
    );

    final end = DateTime.now().add(const Duration(minutes: 3));
    var state = await backup.statuses([extra.id]);
    while (state[extra.id] != 'verified' && DateTime.now().isBefore(end)) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 1)),
      );
      state = await backup.statuses([extra.id]);
    }
    expect(state[extra.id], 'verified');
    await backup.disable(session);
  }, skip: Platform.isIOS);
}

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
import 'package:mediarr/screens/panorama_view.dart';
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
    expect(find.byTooltip('4 of 5 stars'), findsOneWidget);
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

  testWidgets('Recently added shows what came in last', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MediarrApp()));
    await signIn(tester, server.address, password);
    await waitFor(tester, find.byType(AssetPicture));
    await tester.tap(find.text('Library').last);
    await waitFor(tester, find.text('Recently added'));
    await tester.tap(find.text('Recently added'));
    await waitFor(tester, find.text('Recently added').last);
    await waitFor(tester, find.byType(AssetPicture));
    // It is a 360° panorama: marked on its tile, and turning in the viewer.
    expect(find.text('360°'), findsOneWidget);
    await tester.tap(find.byType(AssetPicture).first);
    await waitFor(tester, find.byType(PanoramaView));
    await tester.tap(find.byTooltip('Flat view'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(PanoramaView), findsNothing);
    expect(find.byTooltip('360° view'), findsOneWidget);
    // A slideshow from the open photo, and back.
    await tester.tap(find.byTooltip('Slideshow'));
    await waitFor(tester, find.text('1 / 1'));
    // The controls hide after a moment; a tap brings them back.
    await tester.tapAt(const Offset(160, 300));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byTooltip('Close'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pageBack();
    await tester.pump(const Duration(seconds: 1));
    await tester.pageBack();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Media').last);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('an administrator chooses the storage template in the app', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MediarrApp()));
    await signIn(tester, server.address, password);
    await waitFor(tester, find.byType(AssetPicture));
    await tester.tap(find.byTooltip('Account').first);
    await waitFor(tester, find.text('Storage template'));
    await tester.ensureVisible(find.text('Storage template'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Storage template'));
    await waitFor(tester, find.widgetWithText(TextField, 'Template'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Template'),
      '{{y}}/{{filename}}.{{ext}}',
    );
    await waitFor(tester, find.text('2024/beach.jpg'));
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Save'));
    await waitFor(tester, find.text('Saved.'));
    expect(server.storageTemplate, '{{y}}/{{filename}}.{{ext}}');
    await tester.pageBack();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the home screen widget is given an album', (tester) async {
    // On iOS only the signing at install lets the app share with its widget.
    if (!Platform.isAndroid) return;
    await tester.pumpWidget(const ProviderScope(child: MediarrApp()));
    await signIn(tester, server.address, password);
    await waitFor(tester, find.byType(AssetPicture));
    await tester.tap(find.byTooltip('Account').first);
    await waitFor(tester, find.text('Settings'));
    await tester.ensureVisible(find.text('Settings'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Settings'));
    await waitFor(tester, find.text('Asset viewer'));
    await tester.scrollUntilVisible(
      find.text('Home screen widget'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    // On a small screen it can stop right at the edge.
    await tester.ensureVisible(find.text('Home screen widget'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Home screen widget'));
    await waitFor(tester, find.text('Travels'));
    await tester.tap(find.text('Travels'));
    await waitFor(tester, find.text('Showing Travels'));
    await tester.tap(find.text('Turn off'));
    await waitFor(tester, find.text('The widget shows nothing now.'));
    await tester.pageBack();
    await tester.pump(const Duration(seconds: 1));
    await tester.pageBack();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a phone signs in with a code once the other screen allows it', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MediarrApp()));
    await waitFor(tester, find.text('Sign in'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Server address'),
      server.address,
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.ensureVisible(find.text('Enter a sign-in code'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Enter a sign-in code'));
    await waitFor(tester, find.text('Sign-in code'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Code'),
      FakeServer.qrCode.toLowerCase(),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(TextButton, 'Sign in'));
    await waitFor(tester, find.byType(AssetPicture));
    expect(server.qrDevice, isNotEmpty);
    expect(server.qrWaits, 2);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the dates of selected photos are shifted after a preview', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MediarrApp()));
    await signIn(tester, server.address, password);
    await waitFor(tester, find.byType(AssetPicture));
    await tester.longPress(find.byType(AssetPicture).first);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byTooltip('More'));
    await waitFor(tester, find.text('Date and time…'));
    await tester.tap(find.text('Date and time…'));
    await waitFor(tester, find.widgetWithText(TextField, 'Hours'));
    await tester.enterText(find.widgetWithText(TextField, 'Hours'), '1');
    await waitFor(tester, find.text('Will change: 1'));
    await tester.tap(find.text('Save'));
    await waitFor(tester, find.text('Changed: 1'));
    expect(server.savedDates?['action'], 'shift');
    expect(server.savedDates?['minutes'], -60);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('an album shows the albums inside it', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MediarrApp()));
    await signIn(tester, server.address, password);
    await waitFor(tester, find.byType(AssetPicture));
    await tester.tap(find.text('Albums').last);
    await waitFor(tester, find.text('Travels'));
    // Japan is inside Travels, so the list does not show it.
    expect(find.text('Japan'), findsNothing);
    await tester.tap(find.text('Travels'));
    await waitFor(tester, find.text('Albums inside'));
    expect(find.text('Japan'), findsOneWidget);
    await tester.pageBack();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Media').last);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a duplicate is resolved, and a screenshot is cleaned up', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MediarrApp()));
    await signIn(tester, server.address, password);
    await waitFor(tester, find.byType(AssetPicture));
    await tester.tap(find.text('Library').last);
    await waitFor(tester, find.text('Duplicates'));
    await tester.ensureVisible(find.text('Duplicates'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Duplicates'));
    await waitFor(tester, find.text('Resolve (1 to the trash)'));
    expect(find.textContaining("the camera's original"), findsOneWidget);
    await tester.tap(find.text('Resolve (1 to the trash)'));
    await waitFor(tester, find.text('Resolve this group?'));
    await tester.tap(find.widgetWithText(TextButton, 'Resolve'));
    await waitFor(tester, find.text('No similar photos were found.'));
    final groups = server.savedResolve?['groups'] as List?;
    expect((groups?.first as Map?)?['keepId'], photoId);
    expect((groups?.first as Map?)?['trashIds'], [FakeServer.copyId]);
    await tester.pageBack();
    await tester.pump(const Duration(seconds: 1));

    await waitFor(tester, find.text('Clean up'));
    await tester.ensureVisible(find.text('Clean up'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Clean up'));
    await waitFor(tester, find.byKey(const ValueKey('cleanup-screenshots')));
    await tester.tap(find.byKey(const ValueKey('cleanup-screenshots')));
    await waitFor(
      tester,
      find.byKey(const ValueKey('cleanup-item-Screenshot_1.png')),
    );
    await tester.tap(find.textContaining('To the trash (1'));
    await waitFor(tester, find.text('Move to the trash?'));
    await tester.tap(find.widgetWithText(TextButton, 'Move'));
    await waitFor(tester, find.text('Nothing to clean up here.'));
    expect(server.trashed, [photoId]);
    await tester.pageBack();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a tag is renamed in the app', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MediarrApp()));
    await signIn(tester, server.address, password);
    await waitFor(tester, find.byType(AssetPicture));
    await tester.tap(find.text('Library').last);
    await waitFor(tester, find.text('Tags'));
    await tester.ensureVisible(find.text('Tags'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Tags'));
    await waitFor(tester, find.text('summer'));
    await tester.tap(find.text('summer'));
    await waitFor(tester, find.byTooltip('Rename'));
    await tester.tap(find.byTooltip('Rename'));
    await waitFor(tester, find.widgetWithText(TextField, 'New name'));
    await tester.enterText(
      find.widgetWithText(TextField, 'New name'),
      'Summer 2024',
    );
    await tester.tap(find.text('Save'));
    await waitFor(tester, find.text('Summer 2024'));
    expect(server.tagName, 'Summer 2024');
    await tester.pageBack();
    await tester.pump(const Duration(seconds: 1));
    await tester.pageBack();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Media').last);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('an import from Google Takeout is followed from the account', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MediarrApp()));
    await signIn(tester, server.address, password);
    await waitFor(tester, find.byType(AssetPicture));
    await tester.tap(find.byTooltip('Account').first);
    await waitFor(tester, find.text('Import'));
    await tester.ensureVisible(find.text('Import'));
    await tester.tap(find.text('Import'));
    await waitFor(tester, find.textContaining('Google Takeout'));
    expect(find.textContaining('10 / 40'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
    await tester.pageBack();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('an administrator sees the copies of the backup in the app', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MediarrApp()));
    await signIn(tester, server.address, password);
    await waitFor(tester, find.byType(AssetPicture));
    await tester.tap(find.byTooltip('Account').first);
    await waitFor(tester, find.text('Backup'));
    await tester.ensureVisible(find.text('Backup'));
    await tester.tap(find.text('Backup'));
    await waitFor(tester, find.text('Scheduled backup'));
    // The screen's own list: a text field with several lines is a Scrollable too.
    for (final name in ['Mum and dad', 'Ana', 'v0.2.19 → v0.2.20']) {
      await tester.dragUntilVisible(
        find.text(name),
        find.byType(ListView).last,
        const Offset(0, -300),
      );
      expect(find.text(name), findsOneWidget);
    }
    await tester.pageBack();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a person changes their name in the app', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MediarrApp()));
    await signIn(tester, server.address, password);
    await waitFor(tester, find.byType(AssetPicture));
    await tester.tap(find.byTooltip('Account').first);
    await waitFor(tester, find.text('Profile'));
    await tester.ensureVisible(find.text('Profile'));
    await tester.tap(find.text('Profile'));
    await waitFor(tester, find.text('Add a picture'));
    // The keyboard is closed first: while it moves, the list changes size under the tap. Save can
    // then still be below the fold of the list, not built yet. An emulator's keyboard can take
    // back what was typed as it closes, so it is typed again until it stays.
    for (var attempt = 0; attempt < 5; attempt++) {
      await tester.enterText(
        find.widgetWithText(TextField, 'Name'),
        'Ana Horvat',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(seconds: 1));
      if (find.text('Ana Horvat').evaluate().isNotEmpty) break;
    }
    expect(find.text('Ana Horvat'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Save'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Save'));
    await waitFor(tester, find.text('Saved.'));
    expect(server.name, 'Ana Horvat');
    await tester.pageBack();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a photo is offered for sending or saving on the phone', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MediarrApp()));
    await signIn(tester, server.address, password);
    await waitFor(tester, find.byType(AssetPicture));
    await tester.tap(find.byType(AssetPicture).first);
    await waitFor(tester, find.byTooltip('Share'));
    await tester.tap(find.byTooltip('Share'));
    await waitFor(tester, find.text('Smaller, for messages'));
    expect(find.text('Original'), findsOneWidget);
    expect(find.text('Save to this phone'), findsOneWidget);
    await tester.tapAt(const Offset(20, 40));
    await tester.pump(const Duration(seconds: 1));
    await tester.pageBack();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a search is narrowed by filters, shown as chips', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MediarrApp()));
    await signIn(tester, server.address, password);
    await waitFor(tester, find.byType(AssetPicture));
    await tester.tap(find.text('Search').last);
    await waitFor(tester, find.byTooltip('Filters'));
    await tester.tap(find.byTooltip('Filters'));
    await waitFor(tester, find.text('Apply'));
    // On a small screen the last filters are below the fold of the sheet, not built yet.
    await tester.scrollUntilVisible(
      find.text('Favourites only'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(DraggableScrollableSheet),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Favourites only'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Apply'));
    await waitFor(tester, find.widgetWithText(InputChip, 'Favourites'));
    // Back to the library, for the tests after this one.
    await tester.tap(find.text('Media').last);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('backup devices show what the server confirms', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MediarrApp()));
    await signIn(tester, server.address, password);
    await waitFor(tester, find.byType(AssetPicture));
    await tester.tap(find.byTooltip('Account').first);
    await waitFor(tester, find.text('Backup devices'));
    await tester.ensureVisible(find.text('Backup devices'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Backup devices'));
    await waitFor(tester, find.text('Old phone'));
    expect(find.text('Quiet'), findsOneWidget);
    expect(
      find.text('119 files confirmed by the server, of 121 the device sent'),
      findsOneWidget,
    );
    await tester.tap(find.text('What is missing'));
    await waitFor(tester, find.textContaining('IMG_0042.HEIC'));
    expect(find.textContaining('beach.jpg'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Warn me after'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('3 days'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('7 days').last);
    await waitFor(tester, find.text('Saved.'));
    expect(server.quietDays, 7);
    await tester.pageBack();
    await tester.pump(const Duration(seconds: 1));
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
    // The account sheet has grown, so on a small screen Settings is below its fold.
    await tester.ensureVisible(find.text('Settings'));
    await tester.pump(const Duration(milliseconds: 500));
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

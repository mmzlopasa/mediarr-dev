import 'dart:convert';

import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:mediarr_api/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/backup_card.dart';
import 'package:mediarr/services/backup.dart';
import 'package:mediarr/theme.dart';

const _channel = MethodChannel('app.mediarr/backup');

void main() {
  freeSpaceTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  void reply(Map<String, Object?> status) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          _channel,
          (call) async => call.method == 'status' ? status : null,
        );
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(
            body: SingleChildScrollView(child: BackupCard()),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  test('the status map from the native engine is read', () {
    final status = BackupStatus.fromMap({
      'enabled': true,
      'wifiOnly': false,
      'chargingOnly': true,
      'moreAlbums': ['b'],
      'excludedAlbums': ['c'],
      'pending': 2,
      'working': 1,
      'verified': 7,
      'failed': 1,
      'lastFinished': 1000,
      'failures': [
        {'id': 'a', 'error': 'damaged'},
      ],
    });
    expect(status.total, 11);
    expect(status.wifiOnly, isFalse);
    expect(status.chargingOnly, isTrue);
    expect(status.moreAlbums, ['b']);
    expect(status.excludedAlbums, ['c']);
    expect(status.lastFinished, DateTime.fromMillisecondsSinceEpoch(1000000));
    expect(status.failures.single.error, 'damaged');
  });

  test('a missing or empty status is safe', () {
    final status = BackupStatus.fromMap(const {});
    expect(status.enabled, isFalse);
    expect(status.total, 0);
  });

  test('the last backup is described in plain words', () {
    final now = DateTime(2026, 11, 3, 12);
    expect(describeLastBackup(null, now), contains('Nothing'));
    expect(
      describeLastBackup(now.subtract(const Duration(seconds: 5)), now),
      contains('just now'),
    );
    expect(
      describeLastBackup(now.subtract(const Duration(minutes: 9)), now),
      contains('9 min'),
    );
    expect(
      describeLastBackup(now.subtract(const Duration(hours: 3)), now),
      contains('3 h'),
    );
    expect(
      describeLastBackup(now.subtract(const Duration(days: 2)), now),
      contains('2 d'),
    );
  });

  testWidgets('when it is off, the limits of iOS are explained', (
    tester,
  ) async {
    reply({'enabled': false});
    await show(tester);
    expect(find.text('Automatic backup'), findsOneWidget);
    expect(find.textContaining('swipe the app away'), findsOneWidget);
    expect(find.textContaining('one album'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('when it is on, the real counts are shown', (tester) async {
    reply({
      'enabled': true,
      'albumName': 'Backup',
      'albumFound': true,
      'pending': 3,
      'working': 2,
      'verified': 5,
      'failed': 1,
    });
    await show(tester);
    expect(find.text('5 of 11 verified on the server'), findsOneWidget);
    expect(find.textContaining('2 sending'), findsOneWidget);
    expect(find.text('Album: Backup'), findsOneWidget);
    expect(find.textContaining('Nothing is being sent'), findsNothing);
    expect(find.text('Try the 1 failed again'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a missing album is reported, because nothing is sent then', (
    tester,
  ) async {
    reply({'enabled': true, 'albumName': 'Gone', 'albumFound': false});
    await show(tester);
    expect(find.textContaining('Nothing is being sent'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an album can be picked from the list or by a typed name', (
    tester,
  ) async {
    AlbumChoice? choice;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: Builder(
          builder: (context) => TextButton(
            child: const Text('open'),
            onPressed: () async {
              choice = await showModalBottomSheet<AlbumChoice>(
                context: context,
                isScrollControlled: true,
                builder: (_) => AlbumPicker(
                  albums: [BackupAlbum(id: '1', title: 'Backup', count: 3)],
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Backup'));
    await tester.pumpAndSettle();
    expect(choice?.id, '1');

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Putovanje');
    await tester.pump();
    await tester.tap(find.text('Use the name "Putovanje"'));
    await tester.pumpAndSettle();
    expect(choice?.id, isNull);
    expect(choice?.name, 'Putovanje');
  });
}

void freeSpaceTests() {
  test('only what the server has right now may leave the phone', () {
    expect(
      safeToRemove(
        {
          'whole': ['a'],
          'live': ['b', 'c'],
          'half-live': ['b', 'gone'],
          'deleted-on-server': ['gone'],
          'no-checksum': [],
        },
        {'a', 'b', 'c'},
      ),
      ['whole', 'live'],
    );
  });

  test('roles become the two lists, and a removed album is in neither', () {
    final lists = albumListsFrom({
      'a': AlbumRole.send,
      'b': AlbumRole.never,
      'c': AlbumRole.none,
    });
    expect(lists.more, ['a']);
    expect(lists.excluded, ['b']);
  });

  group('copying albums to the server', () {
    DefaultApi fake(List<Map<String, dynamic>> albums, List<String> requests) {
      final client = ApiClient(basePath: 'http://server');
      client.client = MockClient((request) async {
        requests.add('${request.method} ${request.url.path}');
        final path = request.url.path;
        if (path == '/api/assets/check') {
          return Response(
            jsonEncode({
              'existing': ['aa'],
              'ids': {'aa': 'asset-1'},
            }),
            200,
          );
        }
        if (path == '/api/albums' && request.method == 'GET') {
          return Response(jsonEncode(albums), 200);
        }
        if (path == '/api/albums' && request.method == 'POST') {
          return Response(jsonEncode(_album('new', 'Holiday')), 201);
        }
        return Response(jsonEncode({'changed': 1}), 200);
      });
      return DefaultApi(client);
    }

    test('a missing album is created, then filled', () async {
      final requests = <String>[];
      final done = await mirrorAlbums(fake([], requests), const [
        PhoneAlbum('Holiday', ['aa']),
      ]);
      expect(done, 1);
      expect(requests, contains('POST /api/albums'));
      expect(requests, contains('POST /api/albums/new/assets'));
    });

    test('an album of the same name is reused', () async {
      final requests = <String>[];
      await mirrorAlbums(fake([_album('old', 'Holiday')], requests), const [
        PhoneAlbum('Holiday', ['aa']),
      ]);
      expect(requests, isNot(contains('POST /api/albums')));
      expect(requests, contains('POST /api/albums/old/assets'));
    });

    test('someone else\'s album of that name is left alone', () async {
      final requests = <String>[];
      await mirrorAlbums(
        fake([_album('theirs', 'Holiday', role: 'viewer')], requests),
        const [
          PhoneAlbum('Holiday', ['aa']),
        ],
      );
      expect(requests, contains('POST /api/albums'));
      expect(requests, isNot(contains('POST /api/albums/theirs/assets')));
    });

    test('an album with nothing on the server yet is not created', () async {
      final requests = <String>[];
      await mirrorAlbums(fake([], requests), const [PhoneAlbum('Empty', [])]);
      expect(requests, isNot(contains('POST /api/albums')));
    });
  });
}

Map<String, dynamic> _album(String id, String title, {String role = 'owner'}) =>
    {
      'id': id,
      'title': title,
      'description': '',
      'role': role,
      'ownerId': 'me',
      'ownerName': 'me',
      'assetCount': 0,
      'order': 'newest',
      'isSmart': false,
      'createdAt': '2026-01-01T00:00:00Z',
      'updatedAt': '2026-01-01T00:00:00Z',
    };

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mediarr/screens/album_screen.dart';
import 'package:mediarr/screens/album_sheets.dart';
import 'package:mediarr/screens/albums_screen.dart';
import 'package:mediarr/services/session.dart';
import 'package:mediarr/theme.dart';
import 'package:mediarr_api/api.dart';

const _albumId = '11111111-1111-1111-1111-111111111111';
const _owner = '22222222-2222-2222-2222-222222222222';

class _FakeSession extends Session {
  _FakeSession(this.handler)
    : super(
        serverUrl: 'http://192.168.1.10:9851',
        cookie: 'mediarr_session=x',
        user: User(
          id: _owner,
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

Map<String, Object?> _album({
  String role = 'owner',
  bool smart = false,
  int count = 0,
  String title = 'Summer',
}) => {
  'id': _albumId,
  'title': title,
  'description': '',
  'role': role,
  'ownerId': _owner,
  'ownerName': 'Ana',
  'assetCount': count,
  'order': 'newest',
  'isSmart': smart,
  'members': <Object>[],
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
};

http.Response _json(Object? body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Future<void> _show(
  WidgetTester tester,
  Widget child,
  Future<http.Response> Function(http.Request) handler,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith(
          () => _FakeNotifier(_FakeSession(handler)),
        ),
      ],
      // As in the app, screens open only once the session is known.
      child: MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) =>
                ref.watch(sessionProvider).value == null
                ? const SizedBox.shrink()
                : child,
          ),
        ),
      ),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

Future<void> _finish(WidgetTester tester) async {
  // Ends the screen's refresh timer.
  await tester.pumpWidget(const SizedBox());
}

Future<http.Response> Function(http.Request) _albumServer(
  Map<String, Object?> album,
) => (request) async {
  if (request.url.path.endsWith('/buckets')) {
    return _json({'buckets': <Object>[]});
  }
  return _json(album);
};

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.byTooltip('More'));
  await tester.pumpAndSettle();
}

void main() {
  group('AlbumRights', () {
    test('follows the roles of the spec', () {
      AlbumRights rights(AlbumRoleEnum role, {bool smart = false}) =>
          AlbumRights(role, isSmart: smart);
      expect(rights(AlbumRoleEnum.viewer).canAdd, isFalse);
      expect(rights(AlbumRoleEnum.viewer).canEdit, isFalse);
      expect(rights(AlbumRoleEnum.contributor).canAdd, isTrue);
      expect(rights(AlbumRoleEnum.contributor).canEdit, isFalse);
      expect(rights(AlbumRoleEnum.editor).canEdit, isTrue);
      expect(rights(AlbumRoleEnum.editor).isOwner, isFalse);
      expect(rights(AlbumRoleEnum.owner).isOwner, isTrue);
      expect(rights(AlbumRoleEnum.owner, smart: true).canAdd, isFalse);
    });
  });

  test('a public link uses the address in use, also an IP address', () {
    expect(
      publicLinkUrl('http://192.168.1.10:9851', 'abc'),
      'http://192.168.1.10:9851/s/abc',
    );
  });

  testWidgets('albums come from the server', (tester) async {
    await _show(tester, const AlbumsScreen(), (request) async {
      return _json([
        _album(count: 3),
        {..._album(role: 'viewer', title: 'Theirs', smart: true), 'id': '3'},
      ]);
    });
    expect(find.text('Summer'), findsOneWidget);
    expect(find.textContaining('3 items'), findsOneWidget);
    expect(find.text('0 items • Smart • Ana'), findsOneWidget);
    await _finish(tester);
  });

  testWidgets('no albums says so, and a failure is not shown as empty', (
    tester,
  ) async {
    await _show(
      tester,
      const AlbumsScreen(),
      (request) async => _json(<Object>[]),
    );
    expect(find.text('No albums yet.'), findsOneWidget);
    await _finish(tester);

    await _show(
      tester,
      const AlbumsScreen(),
      (request) async => _json({'message': 'no'}, 500),
    );
    expect(find.text('No albums yet.'), findsNothing);
    expect(find.textContaining('could not be loaded'), findsOneWidget);
    await _finish(tester);
  });

  testWidgets('a new album is sent to the server', (tester) async {
    Object? sent;
    await _show(tester, const AlbumsScreen(), (request) async {
      if (request.method == 'POST') {
        sent = jsonDecode(request.body);
        return _json(_album(), 201);
      }
      return _json(<Object>[]);
    });
    await tester.tap(find.byTooltip('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Trip');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect((sent as Map)['title'], 'Trip');
    await _finish(tester);
  });

  testWidgets('an owner can share, link and delete', (tester) async {
    await _show(
      tester,
      const AlbumScreen(albumId: _albumId, title: 'Summer'),
      _albumServer(_album()),
    );
    await _openMenu(tester);
    for (final label in [
      'Add from library',
      'Share with users',
      'Public links',
      'Edit',
      'Delete',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('Leave'), findsNothing);
    await _finish(tester);
  });

  testWidgets('a viewer can only look, comment and leave', (tester) async {
    await _show(
      tester,
      const AlbumScreen(albumId: _albumId, title: 'Summer'),
      _albumServer(_album(role: 'viewer')),
    );
    expect(find.byTooltip('Comments'), findsOneWidget);
    expect(find.text('This album is empty.'), findsOneWidget);
    await _openMenu(tester);
    for (final label in [
      'Add from library',
      'Share with users',
      'Public links',
      'Edit',
      'Delete',
    ]) {
      expect(find.text(label), findsNothing, reason: label);
    }
    expect(find.text('Leave'), findsOneWidget);
    await _finish(tester);
  });

  testWidgets('a smart album takes no manual photos', (tester) async {
    await _show(
      tester,
      const AlbumScreen(albumId: _albumId, title: 'Summer'),
      _albumServer(_album(smart: true)),
    );
    expect(find.text('No photos match the rules.'), findsOneWidget);
    await _openMenu(tester);
    expect(find.text('Add from library'), findsNothing);
    expect(find.text('Share with users'), findsOneWidget);
    await _finish(tester);
  });

  testWidgets('ended access hides the album', (tester) async {
    await _show(
      tester,
      const AlbumScreen(albumId: _albumId, title: 'Summer'),
      (request) async => _json({'message': 'no such album'}, 404),
    );
    expect(find.text('This album is not available.'), findsOneWidget);
    await _finish(tester);
  });

  test('search and the owner filter leave the right albums', () {
    Album album(String title, String role) =>
        Album.fromJson(_album(title: title, role: role))!;
    final albums = [album('Summer', 'owner'), album('Winter', 'viewer')];
    List<String> titles(List<Album> list) => [for (final a in list) a.title];
    expect(titles(visibleAlbums(albums, search: 'sum', mine: null)), [
      'Summer',
    ]);
    expect(titles(visibleAlbums(albums, search: '', mine: true)), ['Summer']);
    expect(titles(visibleAlbums(albums, search: '', mine: false)), ['Winter']);
    expect(visibleAlbums(albums, search: 'x', mine: null), isEmpty);
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const userId = '11111111-1111-4111-8111-111111111111';
const photoId = '22222222-2222-4222-8222-222222222222';
const email = 'owner@example.com';
const password = 'correct horse';

/// A real JPEG, so the app decodes what it gets.
const tinyJpeg =
    '/9j/4QFaRXhpZgAASUkqAAgAAAAHABIBAwABAAAAAQAAABoBBQABAAAAYgAAABsBBQABAAAAagAAACgBAwABAAAAAgAAABMCAwABAAAAAQAAAGmHBAABAAAAcgAAACWIBAABAAAA4AAAAAAAAAA4YwAA6AMAADhjAADoAwAABwAAkAcABAAAADAyMTADkAIAFAAAAMwAAAABkQcABAAAAAECAwAAoAcABAAAADAxMDABoAMAAQAAAP//AAACoAQAAQAAAEAAAAADoAQAAQAAADAAAAAAAAAAMjAyNDowNjoxNSAxMDowMDowMAAFAAAAAQAEAAAAAgMAAAEAAgACAAAATgAAAAIABQADAAAAIgEAAAMAAgACAAAARQAAAAQABQADAAAAOgEAAAAAAAArAAAAAQAAAAoAAAABAAAAMQIAABkAAAAQAAAAAQAAABoAAAABAAAAuwIAABkAAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/wAALCAAwAEABAREA/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/9oACAEBAAA/APn+iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiv/9k=';

/// One upload that reached the server.
class ReceivedUpload {
  ReceivedUpload(this.name, this.declaredChecksum, this.actualChecksum);

  final String name;
  final String declaredChecksum;
  final String actualChecksum;
}

/// Answers what the app asks, with the shapes of api/openapi.yaml. It runs inside the test, because
/// the simulator's machine has no Docker for the real server.
class FakeServer {
  late final HttpServer _server;
  final uploads = <ReceivedUpload>[];

  String get address => 'http://127.0.0.1:${_server.port}';

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen(_handle);
  }

  Future<void> stop() => _server.close(force: true);

  Future<void> _json(HttpRequest request, int status, Object body) async {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
    await request.response.close();
  }

  /// The person's name, which they can change.
  String name = 'Owner';

  /// The account's language, as the app last saved it.
  String? language;
  int quietDays = 3;
  String tagName = 'summer';
  String storageTemplate = '';
  Map<String, dynamic>? savedDates;

  /// The mark the app last gave the photo.
  int? lastPick;

  /// The code a signed-in screen showed, and the device that handed it in.
  static const qrCode = 'K7QM-2XPA';

  /// A copy of the photo, for duplicates.
  static const copyId = '33333333-3333-4333-8333-333333333333';
  Map<String, dynamic>? savedResolve;

  /// The server settings an administrator changes in the app.
  Map<String, dynamic> serverSettings = {
    'trashDays': 30,
    'imageQuality': 82,
    'previewSize': 1440,
    'videoQuality': 26,
    'videoMaxHeight': 1080,
    'loginMessage': '',
    'passwordLogin': true,
    'maintenance': false,
    'faceMinScore': 0.6,
    'faceMaxDistance': 0.5,
    'workerConcurrency': 0,
    'videoWorkers': 1,
    'analysisWorkers': 1,
    'externalScanHours': 6,
    'visibleOnNetwork': true,
  };
  List<String> trashed = [];

  /// Only the test of memories sees one; on the home screen it would come before the photos.
  bool showMemories = false;
  bool tripHidden = false;
  String? hiddenMemoryKey;

  /// The album's one public link, as the app last changed it.
  static const linkId = '00000000-0000-4000-8000-0000000000b1';
  static const visitorName = 'Ana from school';
  Map<String, dynamic> link = {
    'id': linkId,
    'label': 'Family',
    'hasPassword': false,
    'downloadCount': 1,
    'allowDownload': true,
    'allowUpload': false,
    'uploadOnly': false,
    'showLocation': false,
    'createdAt': '2026-11-01T10:00:00Z',
    'hideFaces': 'none',
    'visiblePeople': <String>[],
    'stripCamera': true,
    'stripDate': false,
    'askName': false,
    'visits': 2,
    'lastVisitAt': '2026-11-08T18:30:00Z',
  };
  String? qrDevice;
  int qrWaits = 0;

  /// A DLNA TV on the network and the server's side of casting. Only the test of the TV turns it on,
  /// so no other test finds a TV.
  bool tvOn = false;
  static const castToken = 'tv-token-1';
  static const castSessionId = '00000000-0000-4000-8000-0000000000c1';
  final tvActions = <String>[];
  String? tvUri;

  /// What the TV got when it opened the address itself, without a cookie.
  int? tvFetched;
  bool castStopped = false;

  void resetTv() {
    tvOn = false;
    tvActions.clear();
    tvUri = null;
    tvFetched = null;
    castStopped = false;
  }

  Future<bool> _tv(HttpRequest request, String path) async {
    if (!tvOn) return false;
    if (path == '/renderer/description.xml') {
      request.response.headers.contentType = ContentType('text', 'xml');
      request.response.write(
        '<?xml version="1.0"?><root xmlns="urn:schemas-upnp-org:device-1-0"><device>'
        '<deviceType>urn:schemas-upnp-org:device:MediaRenderer:1</deviceType>'
        '<friendlyName>Fake TV</friendlyName><UDN>uuid:fake-tv</UDN><serviceList>'
        '<service><serviceType>urn:schemas-upnp-org:service:AVTransport:1</serviceType>'
        '<controlURL>control</controlURL></service></serviceList></device></root>',
      );
      await request.response.close();
      return true;
    }
    if (path == '/renderer/control' && request.method == 'POST') {
      final body = await utf8.decoder.bind(request).join();
      final action = (request.headers.value('soapaction') ?? '')
          .replaceAll('"', '')
          .split('#')
          .last;
      if (action == 'SetAVTransportURI') {
        final uri = RegExp(r'<CurrentURI>([^<]*)</CurrentURI>')
            .firstMatch(body)
            ?.group(1);
        tvUri = uri?.replaceAll('&amp;', '&');
        final fetch = await HttpClient().getUrl(Uri.parse(tvUri!));
        final answer = await fetch.close();
        await answer.drain<void>();
        tvFetched = answer.statusCode;
      }
      tvActions.add(action);
      request.response.headers.contentType = ContentType('text', 'xml');
      request.response.write(
        '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Body>'
        '<u:${action}Response xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"/>'
        '</s:Body></s:Envelope>',
      );
      await request.response.close();
      return true;
    }
    Map<String, Object> media(String id) => {
      'id': id,
      'kind': 'photo',
      'image': '/api/tv/{token}/assets/$id/image',
    };
    if (path == '/api/cast-sessions' && request.method == 'POST') {
      final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
      await _json(request, 201, {
        'id': castSessionId,
        'token': castToken,
        'expiresAt': '2026-11-10T14:00:00Z',
        'media': [for (final id in body['ids'] as List) media(id as String)],
      });
      return true;
    }
    if (path == '/api/cast-sessions/$castSessionId/assets' &&
        request.method == 'POST') {
      final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
      await _json(request, 200, {
        'id': castSessionId,
        'expiresAt': '2026-11-10T14:00:00Z',
        'media': [for (final id in body['ids'] as List) media(id as String)],
      });
      return true;
    }
    if (path == '/api/cast-sessions/$castSessionId' &&
        request.method == 'DELETE') {
      castStopped = true;
      request.response.statusCode = 204;
      await request.response.close();
      return true;
    }
    if (path == '/api/tv/$castToken/assets/$photoId/image' && !castStopped) {
      request.response.headers.contentType = ContentType('image', 'jpeg');
      request.response.add(base64Decode(tinyJpeg));
      await request.response.close();
      return true;
    }
    return false;
  }

  /// The export of the library: none, then running, then ready after the app has asked once.
  String? exportStatus;
  int exportPolls = 0;

  Map<String, Object> get _export => {
    'id': '00000000-0000-4000-8000-0000000000e1',
    'userId': userId,
    'userEmail': email,
    'status': exportStatus!,
    'startedByAdmin': false,
    'startedBy': 'Owner',
    'totalFiles': 40,
    'totalBytes': 4000,
    'doneFiles': exportStatus == 'done' ? 40 : 10,
    'doneBytes': exportStatus == 'done' ? 4000 : 1000,
    'missing': 0,
    'lastError': '',
    'createdAt': '2026-11-09T10:00:00Z',
    if (exportStatus == 'done') 'expiresAt': '2026-11-16T10:00:00Z',
    'parts': [
      if (exportStatus == 'done') {'number': 1, 'size': 4096, 'files': 40},
    ],
    'canDownload': true,
  };

  Map<String, Object> get _user => {
    'id': userId,
    'email': email,
    'name': name,
    'isAdmin': true,
    'totpEnabled': false,
  };

  Future<void> _handle(HttpRequest request) async {
    final path = request.uri.path;
    final signedIn =
        request.headers.value('cookie')?.contains('mediarr_session=abc') ??
        false;
    final hasKey = request.headers.value('x-api-key') == 'device-key';

    if (await _tv(request, path)) return;
    if (path == '/api/uploads' && request.method == 'POST') {
      await _upload(request, hasKey);
      return;
    }
    if (path == '/api/assets/check' && request.method == 'POST') {
      await utf8.decoder.bind(request).join();
      await _json(request, hasKey ? 200 : 401, {'existing': <String>[]});
      return;
    }
    if (path == '/api/auth/login' && request.method == 'POST') {
      final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
      if (body['email'] != email || body['password'] != password) {
        await _json(request, 401, {'message': 'wrong', 'totpRequired': false});
        return;
      }
      request.response.headers.add(
        'set-cookie',
        'mediarr_session=abc; Path=/; HttpOnly',
      );
      await _json(request, 200, _user);
      return;
    }
    if (path == '/api/server/hello') {
      await _json(request, 200, {'app': 'mediarr', 'version': '0.0.0-test'});
      return;
    }
    if (path == '/api/auth/qr/redeem' && request.method == 'POST') {
      final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
      if ('${body['code']}'.toUpperCase() != qrCode) {
        await _json(request, 401, {'message': 'expired'});
        return;
      }
      qrDevice = '${body['device']}';
      qrWaits = 0;
      await _json(request, 200, {'ticket': 'ticket-1'});
      return;
    }
    if (path == '/api/auth/qr/wait' && request.method == 'POST') {
      await utf8.decoder.bind(request).join();
      // The first time nobody has answered yet; then the signed-in screen allows it.
      if (qrWaits++ == 0) {
        request.response.statusCode = 202;
        await request.response.close();
        return;
      }
      request.response.headers.add(
        'set-cookie',
        'mediarr_session=abc; Path=/; HttpOnly',
      );
      await _json(request, 200, _user);
      return;
    }
    if (path == '/api/auth/status') {
      await _json(request, 200, {
        'setupRequired': false,
        if (signedIn) 'user': _user,
      });
      return;
    }
    if (!signedIn) {
      await _json(request, 401, {'message': 'sign in'});
      return;
    }
    await _signedIn(request, path);
  }

  Future<void> _signedIn(HttpRequest request, String path) async {
    if (path == '/api/assets/$photoId/faces') {
      await _json(request, 200, {
        'faces': [
          {
            'id': '00000000-0000-0000-0000-000000000010',
            'x1': 0.1,
            'y1': 0.1,
            'x2': 0.4,
            'y2': 0.4,
            'person': {
              'id': '00000000-0000-0000-0000-000000000011',
              'name': 'Ana',
            },
          },
        ],
      });
      return;
    }
    if (path == '/api/people') {
      await _json(request, 200, {'enabled': true, 'people': []});
      return;
    }
    if (path == '/api/explore/places') {
      await _json(request, 200, {
        'places': [
          {
            'name': 'Hvar',
            'country': 'HR',
            'assetCount': 3,
            'coverId': photoId,
          },
        ],
      });
      return;
    }
    if (path == '/api/memories') {
      await _json(request, 200, [
        if (showMemories && !tripHidden)
          {
            'kind': 'trip',
            'key': 'Split|2024-07-03',
            'title': '2024-07-03 – 2024-07-05',
            'titleParams': {'place': 'Split', 'month': 7, 'year': 2024},
            'items': [
              {
                'id': photoId,
                'kind': 'photo',
                'ratio': 1.33,
                'isFavorite': false,
                'localAt': '2024-07-03T10:00:00',
              },
            ],
          },
      ]);
      return;
    }
    if (path == '/api/memories/hidden' && request.method == 'PUT') {
      final body = jsonDecode(
        await utf8.decoder.bind(request).join(),
      ) as Map<String, dynamic>;
      tripHidden = body['hidden'] == true;
      hiddenMemoryKey = body['key'] as String?;
      request.response.statusCode = 204;
      await request.response.close();
      return;
    }
    if (path == '/api/me' && request.method == 'PATCH') {
      final body = jsonDecode(
        await utf8.decoder.bind(request).join(),
      ) as Map<String, dynamic>;
      name = (body['name'] as String?) ?? name;
      language = (body['language'] as String?) ?? language;
      await _json(request, 200, _user);
      return;
    }
    if (path == '/api/me/api-keys' && request.method == 'POST') {
      await utf8.decoder.bind(request).join();
      await _json(request, 201, {
        'id': '44444444-4444-4444-8444-444444444444',
        'key': 'widget-key',
      });
      return;
    }
    if (path.startsWith('/api/me/device-keys/') && request.method == 'DELETE') {
      request.response.statusCode = 204;
      await request.response.close();
      return;
    }
    if (path == '/api/admin/server-settings') {
      if (request.method == 'PUT') {
        serverSettings = jsonDecode(
          await utf8.decoder.bind(request).join(),
        ) as Map<String, dynamic>;
      }
      await _json(request, 200, serverSettings);
      return;
    }
    if (path == '/api/duplicates') {
      Map<String, Object> item(
        String id,
        String name, {
        bool original = false,
      }) => {
        'id': id,
        'originalName': name,
        'sizeBytes': 2000000,
        'width': 3000,
        'height': 2000,
        'ratio': 1.5,
        'localAt': '2024-07-01T10:00:00',
        'favorite': false,
        'original': original,
        'resaved': !original,
        'hasDate': true,
        'hasLocation': false,
        'hasCaption': false,
      };
      await _json(request, 200, {
        'total': savedResolve == null ? 1 : 0,
        'pending': 0,
        'exactTotal': 0,
        'groups': [
          if (savedResolve == null)
            {
              'keepId': photoId,
              'exact': false,
              'freedBytes': 2000000,
              'items': [
                item(photoId, 'beach.heic', original: true),
                item(copyId, 'IMG-20240701-WA0001.jpg'),
              ],
            },
        ],
      });
      return;
    }
    if (path == '/api/duplicates/resolve' && request.method == 'POST') {
      final body = jsonDecode(
        await utf8.decoder.bind(request).join(),
      ) as Map<String, dynamic>;
      if (body['dryRun'] != true) savedResolve = body;
      await _json(request, 200, {
        'groups': 1,
        'trashed': 1,
        'freedBytes': 2000000,
        'background': false,
      });
      return;
    }
    if (path == '/api/cleanup') {
      await _json(request, 200, {
        'pending': 0,
        'categories': [
          for (final id in ['blurry', 'screenshots', 'largeVideos', 'bursts'])
            {
              'id': id,
              'count': id == 'screenshots' && trashed.isEmpty ? 1 : 0,
              'bytes': 1000,
            },
        ],
      });
      return;
    }
    if (path.startsWith('/api/cleanup/')) {
      final screenshots = path.endsWith('/screenshots') && trashed.isEmpty;
      await _json(request, 200, {
        'items': [
          if (screenshots)
            {
              'id': photoId,
              'originalName': 'Screenshot_1.png',
              'sizeBytes': 1000,
              'kind': 'photo',
              'ratio': 0.5,
              'localAt': '2024-07-01T10:00:00',
              'favorite': false,
              'inAlbum': false,
            },
        ],
      });
      return;
    }
    if (path == '/api/assets/pick/read' && request.method == 'POST') {
      await utf8.decoder.bind(request).join();
      await _json(request, 200, {
        'items': [
          {'id': photoId, 'pick': lastPick ?? 0, 'rating': 0},
        ],
      });
      return;
    }
    if (path == '/api/assets/pick' && request.method == 'POST') {
      final body = jsonDecode(
        await utf8.decoder.bind(request).join(),
      ) as Map<String, dynamic>;
      lastPick = body['pick'] as int;
      await _json(request, 200, {'changed': (body['ids'] as List).length});
      return;
    }
    if (path == '/api/assets/bulk' && request.method == 'POST') {
      final body = jsonDecode(
        await utf8.decoder.bind(request).join(),
      ) as Map<String, dynamic>;
      if (body['action'] == 'delete') {
        trashed = [...(body['ids'] as List).cast<String>()];
      }
      await _json(request, 200, {'changed': (body['ids'] as List).length});
      return;
    }
    if (path == '/api/assets/dates' && request.method == 'POST') {
      final body = jsonDecode(
        await utf8.decoder.bind(request).join(),
      ) as Map<String, dynamic>;
      if (body['dryRun'] != true) savedDates = body;
      await _json(request, 200, {
        'changed': 1,
        'skipped': 0,
        'changes': [
          {
            'id': photoId,
            'name': 'beach.jpg',
            'before': '2024-07-01T10:00:00',
            'after': '2024-07-01T09:00:00',
          },
        ],
      });
      return;
    }
    if (path == '/api/admin/storage-template') {
      if (request.method == 'PUT') {
        final body = jsonDecode(
          await utf8.decoder.bind(request).join(),
        ) as Map<String, dynamic>;
        storageTemplate = body['template'] as String;
      }
      await _json(request, 200, {
        'template': storageTemplate,
        'defaultLayout': '{{y}}/{{MM}}/{{hash}}-{{filename}}.{{ext}}',
        'tokens': [
          {'token': '{{y}}', 'means': 'year, 2024'},
          {'token': '{{filename}}', 'means': 'the name it came with'},
          {'token': '{{ext}}', 'means': 'the extension, jpg'},
        ],
      });
      return;
    }
    if (path == '/api/admin/storage-template/preview') {
      await utf8.decoder.bind(request).join();
      await _json(request, 200, [
        {'name': 'beach.jpg', 'path': '2024/beach.jpg'},
      ]);
      return;
    }
    const travelsId = '00000000-0000-4000-8000-0000000000a1';
    const japanId = '00000000-0000-4000-8000-0000000000a2';
    Map<String, Object?> album(
      String id,
      String title, {
      String? parent,
      int children = 0,
    }) => {
      'id': id,
      'title': title,
      'description': '',
      'role': 'owner',
      'ownerId': '11111111-1111-4111-8111-111111111111',
      'ownerName': 'Owner',
      'assetCount': 0,
      'order': 'newest',
      'isSmart': false,
      'createdAt': '2026-11-01T10:00:00Z',
      'updatedAt': '2026-11-01T10:00:00Z',
      'parentId': ?parent,
      if (children > 0) 'childCount': children,
    };
    if (path == '/api/albums' && request.method == 'GET') {
      await _json(request, 200, [
        album(travelsId, 'Travels', children: 1),
        album(japanId, 'Japan', parent: travelsId),
      ]);
      return;
    }
    if (path == '/api/albums/$travelsId/links' && request.method == 'GET') {
      await _json(request, 200, [link]);
      return;
    }
    if (path == '/api/albums/$travelsId/links/$linkId' &&
        request.method == 'PATCH') {
      final body = jsonDecode(
        await utf8.decoder.bind(request).join(),
      ) as Map<String, dynamic>;
      link = {
        ...link,
        for (final entry in body.entries)
          if (entry.value != null) entry.key: entry.value,
      };
      await _json(request, 200, link);
      return;
    }
    if (path == '/api/albums/$travelsId/links/$linkId/visits') {
      await _json(request, 200, [
        {
          'at': '2026-11-08T18:30:00Z',
          'name': visitorName,
          'city': 'Split',
          'country': 'Croatia',
          'device': 'Phone · Safari',
          'viewed': 4,
          'downloaded': 1,
        },
        {
          'at': '2026-11-07T09:00:00Z',
          'device': 'Computer · Firefox',
          'viewed': 2,
          'downloaded': 0,
        },
      ]);
      return;
    }
    if (path == '/api/albums/$travelsId/privacy') {
      await _json(request, 200, {'photos': 12, 'unchecked': 2, 'videos': 1});
      return;
    }
    if (path == '/api/albums/$travelsId') {
      await _json(request, 200, album(travelsId, 'Travels', children: 1));
      return;
    }
    if (path == '/api/albums/$travelsId/buckets') {
      await _json(request, 200, {'buckets': []});
      return;
    }
    const tagId = '00000000-0000-4000-8000-0000000000t1';
    if (path == '/api/tags') {
      await _json(request, 200, [
        {'id': tagId, 'name': tagName, 'assetCount': 1},
      ]);
      return;
    }
    if (path == '/api/tags/$tagId' && request.method == 'PATCH') {
      final body = jsonDecode(
        await utf8.decoder.bind(request).join(),
      ) as Map<String, dynamic>;
      tagName = body['name'] as String;
      await _json(request, 200, {
        'id': tagId,
        'name': tagName,
        'assetCount': 1,
      });
      return;
    }
    if (path == '/api/tags/$tagId/buckets') {
      await _json(request, 200, {'buckets': []});
      return;
    }
    if (path == '/api/me/backup-devices') {
      await _json(request, 200, {
        'quietDays': quietDays,
        'devices': [
          {
            'id': '00000000-0000-4000-8000-0000000000d1',
            'name': 'Old phone',
            'platform': 'android',
            'appVersion': '0.7.0',
            'createdAt': '2026-10-01T10:00:00Z',
            'reportedAt': '2026-10-20T10:00:00Z',
            'quiet': true,
            'pending': 4,
            'working': 0,
            'verified': 120,
            'failed': 1,
            'files': 121,
            'confirmed': 119,
            'trashed': 1,
            'gone': 1,
            'ownerEmail': 'owner@example.com',
            'ownerName': 'Owner',
          },
        ],
      });
      return;
    }
    if (path == '/api/me/backup-devices/quiet-days') {
      final body = jsonDecode(
        await utf8.decoder.bind(request).join(),
      ) as Map<String, dynamic>;
      quietDays = body['days'] as int;
      request.response.statusCode = 204;
      await request.response.close();
      return;
    }
    if (path.endsWith('/missing') &&
        path.startsWith('/api/me/backup-devices/')) {
      await _json(request, 200, {
        'failures': [
          {'name': 'IMG_0042.HEIC', 'reason': 'The file could not be read.'},
        ],
        'gone': [
          {'checksum': 'ab' * 32, 'name': 'beach.jpg', 'inTrash': true},
        ],
      });
      return;
    }
    if (path == '/api/search/options') {
      await _json(request, 200, {
        'cameras': ['X-T5'],
        'lenses': [],
        'places': ['Hvar'],
        'tags': ['summer'],
      });
      return;
    }
    if (path == '/api/search/warm') {
      request.response.statusCode = 204;
      await request.response.close();
      return;
    }
    if (path == '/api/search') {
      final favourite = request.uri.queryParameters['favorite'] == 'true';
      await _json(request, 200, {
        'items': [],
        'smart': false,
        'filters': {if (favourite) 'favorite': true},
      });
      return;
    }
    if (path == '/api/features') {
      await _json(request, 200, {'backup': true});
      return;
    }
    if (path == '/api/admin/backup') {
      await _json(request, 200, {
        'repository': '',
        'hour': 3,
        'hasPassword': true,
        'hasS3Key': false,
        'localFolder': '/backup',
      });
      return;
    }
    if (path == '/api/admin/backup/runs') {
      await _json(request, 200, []);
      return;
    }
    if (path == '/api/admin/backup/destinations') {
      await _json(request, 200, [
        {
          'id': '00000000-0000-0000-0000-00000000000b',
          'name': 'Mum and dad',
          'address': 'https://keep.example.com',
          'quotaBytes': 107374182400,
          'lastError': '',
          'lastSuccessAt': '2026-11-06T03:10:00Z',
          'createdAt': '2026-11-01T10:00:00Z',
        },
      ]);
      return;
    }
    if (path == '/api/admin/upgrade-snapshots') {
      await _json(request, 200, [
        {
          'name': 'schema-36-to-37-20261107T120000Z',
          'fromVersion': 'v0.2.19',
          'toVersion': 'v0.2.20',
          'fromSchema': 36,
          'toSchema': 37,
          'createdAt': '2026-11-07T12:00:00Z',
          'sizeBytes': 52428800,
        },
      ]);
      return;
    }
    if (path == '/api/admin/keep/guests') {
      await _json(request, 200, [
        {
          'id': '00000000-0000-0000-0000-00000000000c',
          'name': 'Ana',
          'status': 'active',
          'quotaBytes': 53687091200,
          'usedBytes': 1073741824,
          'deletedBytes': 0,
          'address': 'https://photos.example.com',
          'createdAt': '2026-11-01T10:00:00Z',
        },
      ]);
      return;
    }
    if (path == '/api/exports' && request.method == 'POST') {
      exportStatus = 'running';
      exportPolls = 0;
      await _json(request, 201, _export);
      return;
    }
    if (path == '/api/exports') {
      if (exportStatus == 'running' && exportPolls++ > 0) {
        exportStatus = 'done';
      }
      await _json(request, 200, [if (exportStatus != null) _export]);
      return;
    }
    if (path == '/api/exports/00000000-0000-4000-8000-0000000000e1' &&
        request.method == 'DELETE') {
      exportStatus = null;
      request.response.statusCode = 204;
      await request.response.close();
      return;
    }
    if (path == '/api/imports') {
      await _json(request, 200, [
        {
          'id': '00000000-0000-0000-0000-00000000000a',
          'source': 'takeout',
          'status': 'running',
          'fromZip': true,
          'parts': [],
          'total': 40,
          'added': 10,
          'skipped': 0,
          'failed': 0,
          'lastError': '',
          'createdAt': '2026-11-06T10:00:00Z',
        },
      ]);
      return;
    }
    if (path == '/api/notifications') {
      await _json(request, 200, {
        'unread': 1,
        'items': [
          {
            'id': '00000000-0000-0000-0000-000000000009',
            'kind': 'import_done',
            'subject': 'immich',
            'ref': '',
            'createdAt': '2026-01-01T10:00:00Z',
            'read': false,
          },
        ],
      });
      return;
    }
    if (path == '/api/notifications/read') {
      request.response.statusCode = 204;
      await request.response.close();
      return;
    }
    if (path == '/api/timeline/buckets') {
      await _json(request, 200, {
        'buckets': [
          {'month': '2024-07', 'count': 1},
        ],
      });
    } else if (path == '/api/timeline/buckets/2024-07') {
      await _json(request, 200, {
        'month': '2024-07',
        'items': [
          {
            'id': photoId,
            'kind': 'photo',
            'ratio': 1.0,
            'isFavorite': false,
            'localAt': '2024-07-01T10:00:00',
          },
        ],
      });
    } else if (path == '/api/collections/recent/buckets') {
      await _json(request, 200, {
        'buckets': [
          {'month': '2026-11', 'count': 1},
        ],
      });
    } else if (path == '/api/collections/recent/buckets/2026-11') {
      await _json(request, 200, {
        'month': '2026-11',
        'items': [
          {
            'id': photoId,
            'kind': 'photo',
            'ratio': 1.0,
            'isFavorite': false,
            'localAt': '2026-11-07T09:00:00',
            'isPanorama': true,
          },
        ],
      });
    } else if (path == '/api/collections/recent/assets/$photoId/thumbnail' ||
        path == '/api/assets/$photoId/thumbnail') {
      request.response.headers.contentType = ContentType('image', 'jpeg');
      request.response.add(base64Decode(tinyJpeg));
      await request.response.close();
    } else if (path == '/api/assets/$photoId') {
      await _json(request, 200, {
        'id': photoId,
        'originalName': 'beach.jpg',
        'kind': 'photo',
        'status': 'ready',
        'sizeBytes': 1000,
        'isFavorite': false,
        'isArchived': false,
        'isOwner': true,
        'localAt': '2024-07-01T10:00:00',
        'createdAt': '2024-07-01T10:00:00Z',
      });
    } else if (path == '/api/me/device-keys' && request.method == 'POST') {
      await utf8.decoder.bind(request).join();
      await _json(request, 201, {
        'id': '33333333-3333-4333-8333-333333333333',
        'key': 'device-key',
      });
    } else {
      await _json(request, 404, {'message': 'not found'});
    }
  }

  Future<void> _upload(HttpRequest request, bool hasKey) async {
    final bytes = <int>[];
    await request.forEach(bytes.addAll);
    if (!hasKey) {
      await _json(request, 401, {'message': 'no key'});
      return;
    }
    final metadata = <String, String>{
      for (final part in (request.headers.value('upload-metadata') ?? '').split(
        ',',
      ))
        if (part.contains(' '))
          part.split(' ').first: utf8.decode(
            base64Decode(part.split(' ').last),
          ),
    };
    final actual = sha256.convert(bytes).toString();
    uploads.add(
      ReceivedUpload(
        metadata['filename'] ?? '',
        metadata['checksum'] ?? '',
        actual,
      ),
    );
    request.response.statusCode = 201;
    request.response.headers.set('Location', '/api/uploads/1');
    request.response.headers.set('Upload-Offset', '${bytes.length}');
    request.response.headers.set('X-Asset-Id', photoId);
    await request.response.close();
  }
}

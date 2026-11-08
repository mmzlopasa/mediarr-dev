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
  int quietDays = 3;
  String tagName = 'summer';
  String storageTemplate = '';

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
      await _json(request, 200, []);
      return;
    }
    if (path == '/api/me' && request.method == 'PATCH') {
      final body = jsonDecode(
        await utf8.decoder.bind(request).join(),
      ) as Map<String, dynamic>;
      name = (body['name'] as String?) ?? name;
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

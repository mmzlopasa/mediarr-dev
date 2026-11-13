import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mediarr/services/tus.dart';

void main() {
  late Directory dir;
  late File file;
  final content = List<int>.generate(100, (i) => i);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('tus');
    file = File('${dir.path}/photo.jpg');
    await file.writeAsBytes(content);
  });

  tearDown(() => dir.delete(recursive: true));

  TusClient clientFor(MockClientStreamHandler handler) => TusClient(
    baseUrl: 'http://192.168.1.10:9851',
    headers: const {'Cookie': 'mediarr_session=x'},
    client: MockClient.streaming(handler),
    chunkSize: 40,
    retryDelays: const [Duration.zero, Duration.zero],
  );

  http.StreamedResponse reply(
    int status, [
    Map<String, String> headers = const {},
  ]) => http.StreamedResponse(const Stream.empty(), status, headers: headers);

  test('sends the whole file in chunks and reports the result', () async {
    final received = <int>[];
    final offsets = <String>[];
    Map<String, String>? created;
    final client = clientFor((request, body) async {
      if (request.method == 'POST') {
        created = request.headers;
        // The host from a proxy must be ignored.
        return reply(201, {
          'location': 'https://wrong.example/api/uploads/abc',
        });
      }
      expect(
        request.url.toString(),
        'http://192.168.1.10:9851/api/uploads/abc',
      );
      offsets.add(request.headers['Upload-Offset']!);
      received.addAll(await body.expand((chunk) => chunk).toList());
      final last = received.length == content.length;
      return reply(
        204,
        last ? {'x-asset-id': 'id-1', 'x-asset-duplicate': 'true'} : {},
      );
    });

    final progress = <int>[];
    final result = await client.upload(
      file,
      name: 'Šišmiš.jpg',
      lastModifiedMs: 1000,
      onProgress: (sent, _) => progress.add(sent),
    );

    expect(received, content);
    expect(offsets, ['0', '40', '80']);
    expect(progress, [40, 80, 100]);
    expect(result.assetId, 'id-1');
    expect(result.duplicate, isTrue);
    expect(created!['Cookie'], 'mediarr_session=x');
    expect(created!['Upload-Length'], '100');
    expect(
      created!['Upload-Metadata'],
      contains('filename ${base64.encode(utf8.encode('Šišmiš.jpg'))}'),
    );
  });

  test('after a dropped connection it asks the offset and continues', () async {
    final received = <int>[];
    var dropped = false;
    final client = clientFor((request, body) async {
      if (request.method == 'POST') {
        return reply(201, {'location': '/api/uploads/abc'});
      }
      if (request.method == 'HEAD') {
        return reply(200, {'upload-offset': '${received.length}'});
      }
      final bytes = await body.expand((chunk) => chunk).toList();
      if (received.length == 40 && !dropped) {
        dropped = true;
        throw const SocketException('connection lost');
      }
      received.addAll(bytes);
      return reply(204);
    });

    await client.upload(file, name: 'a.jpg');
    expect(dropped, isTrue);
    expect(received, content);
  });

  test('a rejected upload fails at once, without retrying', () async {
    var attempts = 0;
    final client = clientFor((request, body) async {
      attempts += 1;
      return reply(401);
    });
    await expectLater(
      client.upload(file, name: 'a.jpg'),
      throwsA(isA<UploadRejected>()),
    );
    expect(attempts, 1);
  });

  test('it stops after the retries run out', () async {
    var attempts = 0;
    final client = clientFor((request, body) async {
      attempts += 1;
      return reply(503);
    });
    await expectLater(
      client.upload(file, name: 'a.jpg'),
      throwsA(isA<HttpException>()),
    );
    expect(attempts, 3);
  });

  TusClient impatient(MockClientStreamHandler handler) => TusClient(
    baseUrl: 'http://192.168.1.10:9851',
    headers: const {'Cookie': 'mediarr_session=x'},
    client: MockClient.streaming(handler),
    chunkSize: 40,
    retryDelays: const [Duration.zero, Duration.zero],
    requestTimeout: const Duration(milliseconds: 50),
    chunkTimeout: const Duration(milliseconds: 50),
  );

  test('a stalled chunk is given up and sent again', () async {
    final received = <int>[];
    var stalled = false;
    final client = impatient((request, body) async {
      if (request.method == 'POST') {
        return reply(201, {'location': '/api/uploads/abc'});
      }
      if (request.method == 'HEAD') {
        return reply(200, {'upload-offset': '${received.length}'});
      }
      final bytes = await body.expand((chunk) => chunk).toList();
      if (received.length == 40 && !stalled) {
        stalled = true;
        // Never answers, like a connection that went quiet.
        return Completer<http.StreamedResponse>().future;
      }
      received.addAll(bytes);
      return reply(204);
    });

    await client.upload(file, name: 'a.jpg');
    expect(stalled, isTrue);
    expect(received, content);
  });

  test(
    'a server that never answers fails the upload instead of hanging',
    () async {
      var attempts = 0;
      final client = impatient((request, body) {
        attempts += 1;
        return Completer<http.StreamedResponse>().future;
      });
      await expectLater(
        client.upload(file, name: 'a.jpg'),
        throwsA(isA<TimeoutException>()),
      );
      expect(attempts, 3);
    },
  );
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/services/discovery.dart';

void main() {
  test('only home and office networks are looked through', () {
    expect(isPrivateIPv4(InternetAddress('192.168.1.20')), isTrue);
    expect(isPrivateIPv4(InternetAddress('10.0.0.5')), isTrue);
    expect(isPrivateIPv4(InternetAddress('172.20.1.1')), isTrue);
    expect(isPrivateIPv4(InternetAddress('172.40.1.1')), isFalse);
    expect(isPrivateIPv4(InternetAddress('8.8.8.8')), isFalse);
  });

  test('the neighbours of an address leave out the phone itself', () {
    final all = neighboursOf(InternetAddress('192.168.1.20'));
    expect(all, hasLength(253));
    expect(all, isNot(contains('192.168.1.20')));
    expect(all.first, '192.168.1.1');
    expect(all.last, '192.168.1.254');
  });

  test(
    'a Mediarr server says hello, and anything else does not count',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) {
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          request.uri.path == '/api/server/hello'
              ? jsonEncode({
                  'app': 'mediarr',
                  'version': '0.2.30',
                  'name': 'Kuća',
                })
              : '{}',
        );
        request.response.close();
      });
      final url = 'http://127.0.0.1:${server.port}';
      expect(await helloFrom(url), '0.2.30');
      expect((await helloOf(url))?.name, 'Kuća');
      expect(await helloFrom('http://127.0.0.1:1'), isNull);
      await server.close(force: true);
    },
  );

  group('an answer to the hello', () {
    late HttpServer server;
    late String body;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) {
        request.response
          ..headers.contentType = ContentType.json
          ..write(body)
          ..close();
      });
    });

    tearDown(() => server.close(force: true));

    String url() => 'http://127.0.0.1:${server.port}';

    test('is read when it is short', () async {
      body = jsonEncode({'app': 'mediarr', 'version': '1.2', 'name': 'Home'});
      final hello = await helloOf(url(), wait: const Duration(seconds: 2));
      expect(hello?.name, 'Home');
      expect(hello?.version, '1.2');
    });

    test('is not read when it is far too long to be one', () async {
      body = jsonEncode({'app': 'mediarr', 'pad': 'x' * 100000});
      expect(await helloOf(url(), wait: const Duration(seconds: 2)), isNull);
    });

    test('has a long or odd name cut short', () async {
      body = jsonEncode({'app': 'mediarr', 'name': 'A\n${'b' * 200}'});
      final hello = await helloOf(url(), wait: const Duration(seconds: 2));
      expect(hello!.name, isNot(contains('\n')));
      expect(hello.name.length, lessThanOrEqualTo(61));
    });
  });
}

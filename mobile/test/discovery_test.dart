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
              ? jsonEncode({'app': 'mediarr', 'version': '0.2.30'})
              : '{}',
        );
        request.response.close();
      });
      final url = 'http://127.0.0.1:${server.port}';
      expect(await helloFrom(url), '0.2.30');
      expect(await helloFrom('http://127.0.0.1:1'), isNull);
      await server.close(force: true);
    },
  );
}

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mediarr/services/session.dart';
import 'package:mediarr_api/api.dart';

/// A signed-in session whose server is a function, and which remembers what it was asked.
class RecordingSession extends Session {
  RecordingSession(this.handler)
    : super(
        serverUrl: 'http://192.168.1.10:9851',
        cookie: 'mediarr_session=x',
        user: User(
          id: '22222222-2222-2222-2222-222222222222',
          email: 'a@example.com',
          name: 'A',
          isAdmin: false,
          totpEnabled: false,
        ),
      );

  final Future<http.Response> Function(http.Request request) handler;
  final requests = <String>[];

  @override
  DefaultApi get api {
    final client = ApiClient(basePath: serverUrl);
    client.client = MockClient((request) {
      requests.add('${request.method} ${request.url.path}');
      return handler(request);
    });
    return DefaultApi(client);
  }
}

http.Response jsonReply(Object? body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

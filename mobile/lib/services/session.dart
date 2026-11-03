import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' show Response;
import 'package:mediarr_api/api.dart';

/// A signed-in connection to one Mediarr server.
class Session {
  Session({required this.serverUrl, required this.cookie, required this.user});

  final String serverUrl;
  final String cookie;
  final User user;

  Map<String, String> get headers => {'Cookie': cookie};

  DefaultApi get api {
    final client = ApiClient(basePath: serverUrl);
    client.addDefaultHeader('Cookie', cookie);
    return DefaultApi(client);
  }

  String thumbnailUrl(String id, {bool large = false}) =>
      '$serverUrl/api/assets/$id/thumbnail${large ? '?size=large' : ''}';

  String originalUrl(String id) => '$serverUrl/api/assets/$id/original';

  String hlsUrl(String id) => '$serverUrl/api/assets/$id/video/master.m3u8';

  String motionUrl(String id) => '$serverUrl/api/assets/$id/motion';
}

/// A user-facing sign-in failure.
class LoginFailure implements Exception {
  LoginFailure(this.message, {this.totpRequired = false});

  final String message;
  final bool totpRequired;

  @override
  String toString() => message;
}

/// Accepts what people type: an IP address and port, or a full URL.
String normalizeServerUrl(String input) {
  var url = input.trim();
  if (url.isEmpty) throw LoginFailure('Enter the address of your server.');
  if (!url.contains('://')) url = 'http://$url';
  final parsed = Uri.tryParse(url);
  if (parsed == null || parsed.host.isEmpty) {
    throw LoginFailure('That server address is not valid.');
  }
  return url.replaceAll(RegExp(r'/+$'), '');
}

/// Reads the session token from a Set-Cookie header.
String? sessionCookieFrom(String? setCookie) {
  if (setCookie == null) return null;
  final match = RegExp(r'mediarr_session=([^;,\s]+)').firstMatch(setCookie);
  return match == null ? null : 'mediarr_session=${match.group(1)}';
}

final sessionProvider = AsyncNotifierProvider<SessionNotifier, Session?>(
  SessionNotifier.new,
);

class SessionNotifier extends AsyncNotifier<Session?> {
  static const _serverKey = 'server_url';
  static const _cookieKey = 'session_cookie';
  static const _storage = FlutterSecureStorage();

  /// Restores the last session, if the server still accepts it.
  @override
  Future<Session?> build() async {
    final server = await _storage.read(key: _serverKey);
    final cookie = await _storage.read(key: _cookieKey);
    if (server == null || cookie == null) return null;

    final client = ApiClient(basePath: server);
    client.addDefaultHeader('Cookie', cookie);
    try {
      final status = await DefaultApi(client).getAuthStatus();
      final user = status?.user;
      if (user == null) {
        await _storage.delete(key: _cookieKey);
        return null;
      }
      return Session(serverUrl: server, cookie: cookie, user: user);
    } on ApiException {
      // The server is unreachable right now. Keep the cookie and ask again on the login screen.
      return null;
    }
  }

  Future<String?> lastServer() => _storage.read(key: _serverKey);

  Future<void> signIn({
    required String server,
    required String email,
    required String password,
    String? code,
  }) async {
    final url = normalizeServerUrl(server);
    final api = DefaultApi(ApiClient(basePath: url));
    final Response response;
    try {
      response = await api.loginWithHttpInfo(
        LoginRequest(email: email.trim(), password: password, totpCode: code),
      );
    } on ApiException catch (cause) {
      throw LoginFailure(
        'Could not reach the server. Check the address. (${cause.message})',
      );
    }

    if (response.statusCode == 401) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final totp = body['totpRequired'] == true;
      throw LoginFailure(
        totp && code != null
            ? 'The code is wrong.'
            : 'Wrong email or password.',
        totpRequired: totp,
      );
    }
    if (response.statusCode == 429) {
      throw LoginFailure('Too many attempts. Try again later.');
    }
    if (response.statusCode != 200) {
      throw LoginFailure('Sign-in failed (${response.statusCode}).');
    }

    final cookie = sessionCookieFrom(response.headers['set-cookie']);
    final user = User.fromJson(jsonDecode(response.body));
    if (cookie == null || user == null) {
      throw LoginFailure('The server did not start a session.');
    }
    await _storage.write(key: _serverKey, value: url);
    await _storage.write(key: _cookieKey, value: cookie);
    state = AsyncData(Session(serverUrl: url, cookie: cookie, user: user));
  }

  Future<void> signOut() async {
    final session = state.value;
    if (session != null) {
      try {
        await session.api.logout();
      } on ApiException {
        // Signing out locally still has to work without a connection.
      }
    }
    await _storage.delete(key: _cookieKey);
    state = const AsyncData(null);
  }
}

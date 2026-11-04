import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http show get;
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

  /// False for what must not stay on the device, such as photos from the vault.
  bool get keepOnDisk => true;

  Future<AssetDetail?> detail(String id) => api.getAsset(id);
}

/// The same connection, reading from the archive, the trash or the unlocked vault.
class CollectionSession extends Session {
  CollectionSession(Session session, this.scope, {this.vaultToken})
    : _parent = session,
      super(
        serverUrl: session.serverUrl,
        cookie: session.cookie,
        user: session.user,
      );

  final Session _parent;
  final String scope;
  final String? vaultToken;

  String get _base => '$serverUrl/api/collections/$scope/assets';

  @override
  Map<String, String> get headers => {
    ...super.headers,
    'X-Vault-Token': ?vaultToken,
  };

  @override
  DefaultApi get api {
    final api = _parent.api;
    final token = vaultToken;
    if (token != null) api.apiClient.addDefaultHeader('X-Vault-Token', token);
    return api;
  }

  @override
  String thumbnailUrl(String id, {bool large = false}) =>
      '$_base/$id/thumbnail${large ? '?size=large' : ''}';

  @override
  String originalUrl(String id) => '$_base/$id/original';

  @override
  String hlsUrl(String id) => '$_base/$id/video/master.m3u8';

  @override
  String motionUrl(String id) => '$_base/$id/motion';

  @override
  bool get keepOnDisk => scope != 'vault';

  @override
  Future<AssetDetail?> detail(String id) => api.getCollectionAsset(scope, id);
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

/// Answers whether a Mediarr server is at this address, within a short time.
Future<bool> serverAnswers(String server) async {
  try {
    final answer = await http
        .get(Uri.parse('$server/api/auth/status'))
        .timeout(serverProbeWait);
    return answer.statusCode == 200;
  } on Exception {
    return false;
  }
}

const serverProbeWait = Duration(seconds: 3);

/// The first address that answers. The main one wins when both do.
Future<String?> pickServer(
  String main,
  String? second,
  Future<bool> Function(String server) answers,
) async {
  if (second == null || second.isEmpty) return main;
  final results = await Future.wait([answers(main), answers(second)]);
  if (results[0]) return main;
  return results[1] ? second : null;
}

/// A secret that proves later that this app is the one that started the sign-in.
String newSsoVerifier() {
  final random = Random.secure();
  return base64UrlEncode(List<int>.generate(32, (_) => random.nextInt(256)))
      .replaceAll('=', '');
}

/// Where a sign-in starts. The server sees only the hash of the secret.
String ssoStartUrl(String server, String verifier) {
  final challenge = base64UrlEncode(sha256.convert(utf8.encode(verifier)).bytes)
      .replaceAll('=', '');
  return '$server/api/auth/oidc/start?appChallenge=$challenge';
}

/// The one-time code in the address the browser came back with, if the sign-in worked.
String? ssoCodeFrom(String callback) =>
    Uri.tryParse(callback)?.queryParameters['code'];

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
  static const _secondKey = 'server_second';
  static const _storage = FlutterSecureStorage();

  /// Restores the last session, if the server still accepts it.
  @override
  Future<Session?> build() async {
    final server = await _storage.read(key: _serverKey);
    final cookie = await _storage.read(key: _cookieKey);
    if (server == null || cookie == null) return null;
    final second = await _storage.read(key: _secondKey);
    final reachable = await pickServer(server, second, serverAnswers) ?? server;

    final client = ApiClient(basePath: reachable);
    client.addDefaultHeader('Cookie', cookie);
    try {
      final status = await DefaultApi(client).getAuthStatus();
      final user = status?.user;
      if (user == null) {
        await _storage.delete(key: _cookieKey);
        return null;
      }
      return Session(serverUrl: reachable, cookie: cookie, user: user);
    } on ApiException {
      // The server is unreachable right now. Keep the cookie and ask again on the login screen.
      return null;
    }
  }

  Future<String?> lastServer() => _storage.read(key: _serverKey);

  Future<String?> mainServer() => _storage.read(key: _serverKey);

  Future<String?> secondServer() => _storage.read(key: _secondKey);

  /// A second way to the same server, such as a home address and an outside one.
  Future<void> setSecondServer(String? input) async {
    final text = input?.trim() ?? '';
    if (text.isEmpty) {
      await _storage.delete(key: _secondKey);
      return;
    }
    final url = normalizeServerUrl(text);
    if (!await serverAnswers(url)) {
      throw LoginFailure('No Mediarr server answered at that address.');
    }
    await _storage.write(key: _secondKey, value: url);
  }

  /// After coming back to the app: moves to the other address only if this one stopped answering.
  Future<String?> recheckServer() async {
    final session = state.value;
    if (session == null || await serverAnswers(session.serverUrl)) return null;
    final main = await _storage.read(key: _serverKey);
    final second = await _storage.read(key: _secondKey);
    if (main == null || second == null) return null;
    final other = session.serverUrl == main ? second : main;
    if (!await serverAnswers(other)) return null;
    state = AsyncData(
      Session(serverUrl: other, cookie: session.cookie, user: session.user),
    );
    return other;
  }

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

  /// Signs in through the server's identity provider, in the system's browser.
  Future<void> signInWithProvider(String server) async {
    final url = normalizeServerUrl(server);
    final verifier = newSsoVerifier();
    final String answer;
    try {
      answer = await FlutterWebAuth2.authenticate(
        url: ssoStartUrl(url, verifier),
        callbackUrlScheme: 'mediarr',
      );
    } on PlatformException catch (cause) {
      if (cause.code == 'CANCELED') {
        throw LoginFailure('Signing in was cancelled.');
      }
      throw LoginFailure('Single sign-on is not turned on for this server.');
    }
    final code = ssoCodeFrom(answer);
    if (code == null) {
      throw LoginFailure(
        'Single sign-on did not work. You may not have an account on this server.',
      );
    }
    final Response response;
    try {
      response = await DefaultApi(
        ApiClient(basePath: url),
      ).exchangeOIDCWithHttpInfo(OIDCExchange(code: code, verifier: verifier));
    } on ApiException catch (cause) {
      throw LoginFailure('Could not reach the server. (${cause.message})');
    }
    final cookie = sessionCookieFrom(response.headers['set-cookie']);
    final user = response.statusCode == 200
        ? User.fromJson(jsonDecode(response.body))
        : null;
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
    // It belongs to this server, and the next sign-in may be to another one.
    await _storage.delete(key: _secondKey);
    state = const AsyncData(null);
  }
}

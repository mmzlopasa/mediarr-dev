import 'dart:async';
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

import '../l10n/l10n.dart';
import 'language.dart';

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

  String thumbnailUrl(String id, {bool large = false, String? version}) =>
      '$serverUrl/api/assets/$id/thumbnail${previewQuery(large ? 'large' : null, version)}';

  String fullPhotoUrl(String id, {String? version}) =>
      '$serverUrl/api/assets/$id/thumbnail${previewQuery('full', version)}';

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
  String thumbnailUrl(String id, {bool large = false, String? version}) =>
      '$_base/$id/thumbnail${previewQuery(large ? 'large' : null, version)}';

  @override
  String fullPhotoUrl(String id, {String? version}) =>
      '$_base/$id/thumbnail${previewQuery('full', version)}';

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

String get deviceNotApprovedMessage => l.sessionDeviceNotApproved;

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
  if (url.isEmpty) throw LoginFailure(l.sessionEnterAddress);
  if (!url.contains('://')) url = 'http://$url';
  final parsed = Uri.tryParse(url);
  if (parsed == null || parsed.host.isEmpty) {
    throw LoginFailure(l.sessionAddressInvalid);
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
  return '$server/api/auth/oidc/start?appReturn=mediarr-sso&appChallenge=$challenge';
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

/// A JSON answer, or null for anything else, such as a proxy's web page.
Object? readJson(String body) {
  try {
    return jsonDecode(body);
  } on FormatException {
    return null;
  }
}

/// What a sign-in QR code carries: the server's address and a one-time code.
class SignInLink {
  const SignInLink(this.server, this.code);

  final String server;
  final String code;
}

/// Reads `mediarr://sign-in?server=…&code=…`, or nothing if the code is something else.
SignInLink? parseSignInLink(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || uri.scheme != 'mediarr' || uri.host != 'sign-in') {
    return null;
  }
  final server = uri.queryParameters['server'] ?? '';
  final code = uri.queryParameters['code'] ?? '';
  if (server.isEmpty || code.isEmpty) return null;
  return SignInLink(server, code);
}

/// How long this phone keeps waiting for the signed-in screen to answer.
const qrAnswerWait = Duration(minutes: 3);

final sessionProvider = AsyncNotifierProvider<SessionNotifier, Session?>(
  SessionNotifier.new,
);

class SessionNotifier extends AsyncNotifier<Session?> {
  static const _serverKey = 'server_url';
  static const _cookieKey = 'session_cookie';
  static const _secondKey = 'server_second';
  static const _deviceKey = 'device_id';

  /// Names this phone to the server, which can require a device to be approved.
  Future<String> _deviceId() async {
    final saved = await _storage.read(key: _deviceKey);
    if (saved != null) return saved;
    final random = Random.secure();
    final fresh = base64UrlEncode(
      List<int>.generate(32, (_) => random.nextInt(256)),
    ).replaceAll('=', '');
    await _storage.write(key: _deviceKey, value: fresh);
    return fresh;
  }

  Future<ApiClient> _signInClient(String url) async {
    final client = ApiClient(basePath: url);
    client.addDefaultHeader('X-Device-Id', await _deviceId());
    return client;
  }

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
      final restored = Session(
        serverUrl: reachable,
        cookie: cookie,
        user: user,
      );
      unawaited(_followLanguage(restored));
      return restored;
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
      throw LoginFailure(l.sessionNoServer);
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
    final api = DefaultApi(await _signInClient(url));
    final Response response;
    try {
      response = await api.loginWithHttpInfo(
        LoginRequest(email: email.trim(), password: password, totpCode: code),
      );
    } on ApiException catch (cause) {
      throw LoginFailure(l.sessionUnreachableCheck('${cause.message}'));
    }

    if (response.statusCode == 401) {
      final body = readJson(response.body);
      // A proxy in front of the server answers in its own words, often a web page.
      if (body is! Map) throw LoginFailure(l.sessionOddAnswer);
      final totp = body['totpRequired'] == true;
      throw LoginFailure(
        totp && code != null ? l.sessionCodeWrong : l.sessionWrongPassword,
        totpRequired: totp,
      );
    }
    if (response.statusCode == 403) {
      final answer = readJson(response.body);
      if (answer is! Map) throw LoginFailure(l.sessionOddAnswer);
      throw LoginFailure(
        answer['message'] is String
            ? answer['message'] as String
            : deviceNotApprovedMessage,
      );
    }
    if (response.statusCode == 429) {
      throw LoginFailure(l.sessionTooManyAttempts);
    }
    if (response.statusCode != 200) {
      throw LoginFailure(l.sessionSignInFailed('${response.statusCode}'));
    }

    final cookie = sessionCookieFrom(response.headers['set-cookie']);
    final user = User.fromJson(readJson(response.body));
    if (cookie == null || user == null) {
      throw LoginFailure(l.sessionNoSession);
    }
    await _storage.write(key: _serverKey, value: url);
    await _storage.write(key: _cookieKey, value: cookie);
    _signedIn(Session(serverUrl: url, cookie: cookie, user: user));
  }

  /// Signs in through the server's identity provider, in the system's browser.
  Future<void> signInWithProvider(String server) async {
    final url = normalizeServerUrl(server);
    final verifier = newSsoVerifier();
    final String answer;
    try {
      answer = await FlutterWebAuth2.authenticate(
        url: ssoStartUrl(url, verifier),
        callbackUrlScheme: 'mediarr-sso',
      );
    } on PlatformException catch (cause) {
      if (cause.code == 'CANCELED') {
        throw LoginFailure(l.sessionCancelled);
      }
      throw LoginFailure(l.sessionSsoOff);
    }
    final code = ssoCodeFrom(answer);
    if (code == null) {
      throw LoginFailure(l.sessionSsoFailed);
    }
    final Response response;
    try {
      response = await DefaultApi(
        await _signInClient(url),
      ).exchangeOIDCWithHttpInfo(OIDCExchange(code: code, verifier: verifier));
    } on ApiException catch (cause) {
      throw LoginFailure(l.sessionUnreachable('${cause.message}'));
    }
    final cookie = sessionCookieFrom(response.headers['set-cookie']);
    final user = response.statusCode == 200
        ? User.fromJson(readJson(response.body))
        : null;
    if (cookie == null || user == null) {
      throw LoginFailure(l.sessionNoSession);
    }
    await _storage.write(key: _serverKey, value: url);
    await _storage.write(key: _cookieKey, value: cookie);
    _signedIn(Session(serverUrl: url, cookie: cookie, user: user));
  }

  /// Signs in with a code from a signed-in screen. That screen has to allow it, so this waits.
  Future<void> signInWithCode({
    required String server,
    required String code,
    required String device,
    bool Function()? cancelled,
  }) async {
    final url = normalizeServerUrl(server);
    final api = DefaultApi(await _signInClient(url));
    final Response redeemed;
    try {
      redeemed = await api.redeemQRSignInWithHttpInfo(
        QRRedeem(code: code.trim(), device: device),
      );
    } on ApiException catch (cause) {
      throw LoginFailure(l.sessionUnreachableCheck('${cause.message}'));
    }
    if (redeemed.statusCode == 429) {
      throw LoginFailure(l.sessionTooManyAttempts);
    }
    if (redeemed.statusCode != 200) {
      throw LoginFailure(l.sessionCodeExpired);
    }
    final ticket = QRTicket.fromJson(readJson(redeemed.body))?.ticket;
    if (ticket == null) throw LoginFailure(l.sessionNoAnswer);
    final until = DateTime.now().add(qrAnswerWait);
    while (DateTime.now().isBefore(until)) {
      if (cancelled?.call() ?? false) {
        throw LoginFailure(l.sessionCancelled);
      }
      final Response response;
      try {
        response = await api.waitQRSignInWithHttpInfo(QRTicket(ticket: ticket));
      } on ApiException {
        await Future<void>.delayed(const Duration(seconds: 2));
        continue;
      }
      if (response.statusCode == 202) continue;
      if (response.statusCode == 403) {
        final answer = readJson(response.body);
        throw LoginFailure(
          answer is Map && answer['message'] is String
              ? '${answer['message']}'
              : l.sessionNotAllowed,
        );
      }
      if (response.statusCode != 200) {
        throw LoginFailure(l.sessionSignInExpired);
      }
      final cookie = sessionCookieFrom(response.headers['set-cookie']);
      final user = User.fromJson(readJson(response.body));
      if (cookie == null || user == null) {
        throw LoginFailure(l.sessionNoSession);
      }
      await _storage.write(key: _serverKey, value: url);
      await _storage.write(key: _cookieKey, value: cookie);
      _signedIn(Session(serverUrl: url, cookie: cookie, user: user));
      return;
    }
    throw LoginFailure(l.sessionNobodyAnswered);
  }

  void _signedIn(Session session) {
    state = AsyncData(session);
    unawaited(_followLanguage(session));
  }

  /// The account's language, for a phone that has not chosen one.
  Future<void> _followLanguage(Session session) => ref
      .read(languageProvider.notifier)
      .followAccount(session.api, session.user.language);

  /// After the person changes their name, email address or picture.
  void updateUser(User user) {
    final session = state.value;
    if (session == null) return;
    state = AsyncData(
      Session(serverUrl: session.serverUrl, cookie: session.cookie, user: user),
    );
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

/// A short mark for a picture's current look. The blurhash changes when an edit makes new
/// previews, so the address and the cache entry change, and every device shows the edit.
String? previewVersion(String? blurhash) {
  if (blurhash == null || blurhash.isEmpty) return null;
  var hash = 0;
  for (final unit in blurhash.codeUnits) {
    hash = (hash * 31 + unit) & 0xffffffff;
  }
  return hash.toRadixString(36);
}

String previewQuery(String? size, String? version) {
  final parts = [
    ?(size == null ? null : 'size=$size'),
    ?(version == null ? null : 'v=$version'),
  ];
  return parts.isEmpty ? '' : '?${parts.join('&')}';
}

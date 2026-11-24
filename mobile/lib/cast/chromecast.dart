import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'tv.dart';

/// One message of the Cast protocol: a small protobuf with text in it. Written by hand, as only
/// these fields are ever used.
class CastMessage {
  const CastMessage({
    required this.source,
    required this.destination,
    required this.namespace,
    required this.payload,
  });

  final String source;
  final String destination;
  final String namespace;
  final String payload;

  /// The payload, or an empty map for anything that is not a JSON object.
  Map<String, dynamic> get json {
    try {
      final value = jsonDecode(payload);
      return value is Map<String, dynamic> ? value : const {};
    } on FormatException {
      return const {};
    }
  }

  static void _varint(BytesBuilder out, int value) {
    var v = value;
    while (v >= 0x80) {
      out.addByte((v & 0x7f) | 0x80);
      v >>= 7;
    }
    out.addByte(v);
  }

  static void _text(BytesBuilder out, int field, String value) {
    final bytes = utf8.encode(value);
    _varint(out, (field << 3) | 2);
    _varint(out, bytes.length);
    out.add(bytes);
  }

  /// The message with the four bytes of its length in front, as it goes on the wire.
  Uint8List encode() {
    final body = BytesBuilder();
    _varint(body, 1 << 3);
    _varint(body, 0);
    _text(body, 2, source);
    _text(body, 3, destination);
    _text(body, 4, namespace);
    _varint(body, 5 << 3);
    _varint(body, 0);
    _text(body, 6, payload);
    final bytes = body.toBytes();
    final out = BytesBuilder()
      ..add([
        (bytes.length >> 24) & 0xff,
        (bytes.length >> 16) & 0xff,
        (bytes.length >> 8) & 0xff,
        bytes.length & 0xff,
      ])
      ..add(bytes);
    return out.toBytes();
  }

  /// Reads a message without its length.
  static CastMessage decode(Uint8List bytes) {
    var at = 0;
    int varint() {
      var result = 0;
      var shift = 0;
      while (true) {
        if (at >= bytes.length || shift > 35) {
          throw const FormatException('not a Cast message');
        }
        final byte = bytes[at++];
        result |= (byte & 0x7f) << shift;
        if (byte < 0x80) return result;
        shift += 7;
      }
    }

    final texts = <int, String>{};
    while (at < bytes.length) {
      final key = varint();
      final field = key >> 3;
      switch (key & 7) {
        case 0:
          varint();
        case 2:
          final length = varint();
          if (at + length > bytes.length) {
            throw const FormatException('not a Cast message');
          }
          texts[field] = utf8.decode(
            bytes.sublist(at, at + length),
            allowMalformed: true,
          );
          at += length;
        default:
          throw const FormatException('not a Cast message');
      }
    }
    return CastMessage(
      source: texts[2] ?? '',
      destination: texts[3] ?? '',
      namespace: texts[4] ?? '',
      payload: texts[6] ?? '{}',
    );
  }
}

/// Splits what comes from the socket into messages.
class CastFramer {
  /// The Cast protocol allows no bigger message. Anything claiming more is not a Chromecast, and
  /// would otherwise make the phone keep everything it sends.
  static const maxMessage = 64 * 1024;

  final _buffer = BytesBuilder();

  /// Throws [FormatException] for what is not the Cast protocol.
  List<CastMessage> add(List<int> data) {
    _buffer.add(data);
    final out = <CastMessage>[];
    var bytes = _buffer.takeBytes();
    while (bytes.length >= 4) {
      final length =
          (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
      if (length > maxMessage) {
        throw const FormatException('not a Cast message');
      }
      if (bytes.length < 4 + length) break;
      out.add(CastMessage.decode(bytes.sublist(4, 4 + length)));
      bytes = bytes.sublist(4 + length);
    }
    _buffer.add(bytes);
    return out;
  }
}

const _connection = 'urn:x-cast-com.google.cast.tp.connection';
const _heartbeat = 'urn:x-cast-com.google.cast.tp.heartbeat';
const _receiver = 'urn:x-cast-com.google.cast.receiver';
const _media = 'urn:x-cast-com.google.cast.media';

/// Google's Default Media Receiver: it shows a picture or plays a video from an address.
const defaultMediaReceiver = 'CC1AD845';

/// Opens the connection to a Chromecast. Tests give a plain socket.
typedef CastSocketFactory = Future<Socket> Function(String host, int port);

Future<Socket> _secureSocket(String host, int port) => SecureSocket.connect(
  host,
  port,
  // A Chromecast has a certificate of its own that no one signs. Only this socket accepts it, and
  // all it carries are the cast token's short-lived addresses.
  onBadCertificate: (_) => true,
  timeout: const Duration(seconds: 8),
);

/// A Chromecast, spoken to directly over the Cast protocol on the home network. The same code runs
/// on Android and on iOS, and needs no Google services on the phone.
class ChromecastConnection implements TvConnection {
  ChromecastConnection(this.host, this.port, {CastSocketFactory? connect})
    : _connect = connect ?? _secureSocket;

  final String host;
  final int port;
  final CastSocketFactory _connect;
  Socket? _socket;
  StreamSubscription<List<int>>? _reading;
  Timer? _ping;
  int _requestId = 1;
  String? _transport;
  String? _session;
  int? _mediaSession;
  final _waiting = <int, Completer<Map<String, dynamic>>>{};
  final _status = StreamController<TvStatus>.broadcast();

  @override
  Stream<TvStatus> get status => _status.stream;

  void _emit(TvStatus status) {
    if (!_status.isClosed) _status.add(status);
  }

  void _send(String destination, String namespace, Map<String, Object?> body) {
    try {
      _socket?.add(
        CastMessage(
          source: 'sender-0',
          destination: destination,
          namespace: namespace,
          payload: jsonEncode(body),
        ).encode(),
      );
    } on Object {
      // The socket closed under it; the end is reported by the reader.
    }
  }

  Future<Map<String, dynamic>> _ask(
    String destination,
    String namespace,
    Map<String, Object?> body,
  ) {
    final id = _requestId++;
    final answer = Completer<Map<String, dynamic>>();
    _waiting[id] = answer;
    _send(destination, namespace, {...body, 'requestId': id});
    return answer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        _waiting.remove(id);
        throw TimeoutException('the Chromecast did not answer');
      },
    );
  }

  void _received(CastMessage message) {
    final body = message.json;
    if (message.namespace == _heartbeat && body['type'] == 'PING') {
      _send(message.source, _heartbeat, {'type': 'PONG'});
      return;
    }
    if (message.namespace == _media && body['type'] == 'MEDIA_STATUS') {
      final list = body['status'];
      if (list is List && list.isNotEmpty && list.first is Map) {
        final status = list.first as Map;
        final id = status['mediaSessionId'];
        if (id is int) _mediaSession = id;
        final time = status['currentTime'];
        _emit(
          TvStatus(
            playing: status['playerState'] == 'PLAYING',
            position: Duration(
              milliseconds: ((time is num && time.isFinite ? time : 0) * 1000)
                  .round(),
            ),
          ),
        );
      }
    }
    if (message.namespace == _receiver &&
        body['type'] == 'RECEIVER_STATUS' &&
        _session != null) {
      final apps = (body['status'] as Map?)?['applications'];
      final still =
          apps is List &&
          apps.any((app) => app is Map && app['sessionId'] == _session);
      // Someone stopped it on the TV, or started something else there.
      if (!still) _emit(const TvStatus(ended: true));
    }
    final id = body['requestId'];
    if (id is int && id != 0) _waiting.remove(id)?.complete(body);
  }

  @override
  Future<void> open() async {
    final socket = await _connect(host, port);
    _socket = socket;
    final framer = CastFramer();
    _reading = socket.listen(
      (data) {
        try {
          for (final message in framer.add(data)) {
            _received(message);
          }
        } on Object {
          // Not a Chromecast speaking: the connection is given up.
          _emit(const TvStatus(ended: true));
          _reading?.cancel();
        }
      },
      onDone: () => _emit(const TvStatus(ended: true)),
      onError: (_) => _emit(const TvStatus(ended: true)),
    );
    _send('receiver-0', _connection, {'type': 'CONNECT'});
    _ping = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _send('receiver-0', _heartbeat, {'type': 'PING'}),
    );
    final launched = await _ask('receiver-0', _receiver, {
      'type': 'LAUNCH',
      'appId': defaultMediaReceiver,
    });
    final status = launched['status'];
    final apps = status is Map ? status['applications'] : null;
    final app = apps is List
        ? apps
              .whereType<Map>()
              .where((app) => app['appId'] == defaultMediaReceiver)
              .firstOrNull
        : null;
    final transport = app?['transportId'];
    if (app == null || transport is! String) {
      throw const TvException('the Chromecast did not start');
    }
    _transport = transport;
    final session = app['sessionId'];
    _session = session is String ? session : null;
    _send(_transport!, _connection, {'type': 'CONNECT'});
  }

  @override
  Future<void> show(TvMedia media) async {
    final transport = _transport;
    if (transport == null) throw const TvException('not connected');
    final answer = await _ask(transport, _media, {
      'type': 'LOAD',
      'autoplay': true,
      'currentTime': 0,
      'media': {
        'contentId': media.url,
        'contentType': media.contentType,
        'streamType': 'BUFFERED',
        'metadata': {
          // 4 is a photo and 0 anything else, to the Default Media Receiver.
          'metadataType': media.video ? 0 : 4,
          'title': media.title,
        },
      },
    });
    if (answer['type'] == 'LOAD_FAILED' || answer['type'] == 'LOAD_CANCELLED') {
      throw const TvException('the Chromecast could not open it');
    }
    final list = answer['status'];
    if (list is List && list.isNotEmpty && list.first is Map) {
      final id = (list.first as Map)['mediaSessionId'];
      if (id is int) _mediaSession = id;
    }
  }

  Future<void> _control(String type, [Map<String, Object?> extra = const {}]) {
    final transport = _transport;
    final media = _mediaSession;
    if (transport == null || media == null) return Future.value();
    return _ask(transport, _media, {
      'type': type,
      'mediaSessionId': media,
      ...extra,
    });
  }

  @override
  Future<void> play() => _control('PLAY');

  @override
  Future<void> pause() => _control('PAUSE');

  @override
  Future<void> seek(Duration to) =>
      _control('SEEK', {'currentTime': to.inMilliseconds / 1000});

  @override
  Future<void> close() async {
    try {
      if (_session != null) {
        _send('receiver-0', _receiver, {
          'type': 'STOP',
          'sessionId': _session,
          'requestId': _requestId++,
        });
      }
      _send('receiver-0', _connection, {'type': 'CLOSE'});
      await _socket?.flush();
    } catch (_) {
      // Already gone.
    }
    _ping?.cancel();
    await _reading?.cancel();
    try {
      await _socket?.close();
    } on Object {
      // Already gone.
    }
    _socket = null;
    for (final waiting in _waiting.values) {
      if (!waiting.isCompleted) {
        waiting.completeError(const TvException('closed'));
      }
    }
    _waiting.clear();
    if (!_status.isClosed) await _status.close();
  }
}

import 'dart:async';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../services/session.dart';
import 'chromecast.dart';
import 'dlna.dart';
import 'tv.dart';

/// Chromecasts announce themselves over mDNS under this name.
const chromecastService = '_googlecast._tcp';

/// Finds Chromecasts. The friendly name is in the TXT record as fn.
Stream<TvDevice> findChromecasts({Duration wait = const Duration(seconds: 4)}) {
  final out = StreamController<TvDevice>();
  Future<void> run() async {
    final discovery = BonsoirDiscovery(type: chromecastService);
    try {
      await discovery.initialize();
      final events = discovery.eventStream?.listen((event) {
        final service = event.service;
        if (service == null) return;
        if (event is BonsoirDiscoveryServiceFoundEvent) {
          discovery.serviceResolver.resolveService(service);
        } else if (event is BonsoirDiscoveryServiceResolvedEvent) {
          final host = service.hostAddresses
              .where(
                (h) =>
                    InternetAddress.tryParse(h)?.type ==
                    InternetAddressType.IPv4,
              )
              .firstOrNull;
          if (host == null || out.isClosed) return;
          final attributes = service.attributes;
          out.add(
            TvDevice(
              id: 'cast:${attributes['id'] ?? service.name}',
              name: attributes['fn'] ?? service.name,
              kind: TvKind.chromecast,
              host: host,
              port: service.port,
            ),
          );
        }
      });
      await discovery.start();
      await Future<void>.delayed(wait);
      await events?.cancel();
    } on Object {
      // No multicast here; nothing is found this way.
    } finally {
      try {
        await discovery.stop();
      } on Object {
        // Already stopped.
      }
      if (!out.isClosed) await out.close();
    }
  }

  run();
  return out.stream;
}

/// An asset as the viewer and the slideshow know it.
class TvAsset {
  const TvAsset(this.id, {required this.video});

  final String id;
  final bool video;
}

/// What the phone is showing on a TV.
class TvState {
  const TvState({
    this.device,
    this.connecting = false,
    this.current,
    this.video = false,
    this.playing = false,
    this.position = Duration.zero,
    this.duration,
    this.added = const [],
  });

  final TvDevice? device;
  final bool connecting;
  final String? current;
  final bool video;
  final bool playing;
  final Duration position;
  final Duration? duration;

  /// TVs added by their address in this run of the app.
  final List<TvDevice> added;

  bool get active => device != null && !connecting;

  TvState copyWith({
    TvDevice? device,
    bool clearDevice = false,
    bool? connecting,
    String? current,
    bool? video,
    bool? playing,
    Duration? position,
    Duration? duration,
    List<TvDevice>? added,
  }) => TvState(
    device: clearDevice ? null : device ?? this.device,
    connecting: connecting ?? this.connecting,
    current: clearDevice ? null : current ?? this.current,
    video: video ?? this.video,
    playing: playing ?? this.playing,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    added: added ?? this.added,
  );
}

/// Opens a connection to a device. Tests give their own.
typedef TvConnector = TvConnection Function(TvDevice device);

TvConnection connectTo(TvDevice device) => switch (device.kind) {
  TvKind.chromecast => ChromecastConnection(device.host, device.port),
  TvKind.dlna => DlnaConnection(device),
};

/// The server's side of casting: a short-lived token that opens only what was sent.
abstract class CastServer {
  Future<CastSession> start(List<String> ids);
  Future<CastSession> add(String sessionId, List<String> ids);
  Future<void> stop(String sessionId);
  String get serverUrl;
}

class ApiCastServer implements CastServer {
  ApiCastServer(this.session);

  final Session session;

  @override
  String get serverUrl => session.serverUrl;

  @override
  Future<CastSession> start(List<String> ids) async =>
      (await session.api.createCastSession(CastAssets(ids: ids)))!;

  @override
  Future<CastSession> add(String sessionId, List<String> ids) async =>
      (await session.api.addCastAssets(sessionId, CastAssets(ids: ids)))!;

  @override
  Future<void> stop(String sessionId) =>
      session.api.deleteCastSession(sessionId);
}

/// What a TV of this kind plays for an asset. A DLNA TV rarely plays HLS, so it gets the file.
TvMedia tvMediaFor(
  CastMedia media,
  String serverUrl,
  String token,
  TvKind kind,
) {
  String full(String path) =>
      serverUrl + path.replaceAll('{token}', Uri.encodeComponent(token));
  final video = media.kind == CastMediaKindEnum.video;
  final duration = media.durationMs == null
      ? null
      : Duration(milliseconds: media.durationMs!);
  if (video && kind == TvKind.chromecast && media.hls != null) {
    return TvMedia(
      id: media.id,
      url: full(media.hls!),
      contentType: 'application/vnd.apple.mpegurl',
      video: true,
      duration: duration,
    );
  }
  if (video && media.file != null) {
    return TvMedia(
      id: media.id,
      url: full(media.file!),
      contentType: media.mimeType ?? 'video/mp4',
      video: true,
      duration: duration,
    );
  }
  return TvMedia(
    id: media.id,
    url: full(media.image),
    contentType: 'image/jpeg',
    video: false,
  );
}

class TvController extends Notifier<TvState> {
  TvController({TvConnector? connector}) : _connector = connector ?? connectTo;

  final TvConnector _connector;
  TvConnection? _connection;
  StreamSubscription<TvStatus>? _status;
  CastServer? _server;
  String? _sessionId;
  String _token = '';
  final _sent = <String, CastMedia>{};

  /// The asset that should be on the TV, so that fast swiping ends on the last one.
  String? _wanted;

  @override
  TvState build() {
    ref.onDispose(() => _release(updateState: false));
    return const TvState();
  }

  void addDevice(TvDevice device) {
    if (state.added.contains(device)) return;
    state = state.copyWith(added: [...state.added, device]);
  }

  /// Connects to a TV and shows this asset on it.
  Future<void> start(CastServer server, TvDevice device, TvAsset asset) async {
    await stop();
    state = state.copyWith(device: device, connecting: true, current: asset.id);
    try {
      final session = await server.start([asset.id]);
      _server = server;
      _sessionId = session.id;
      _token = session.token ?? '';
      for (final media in session.media) {
        _sent[media.id] = media;
      }
      final connection = _connector(device);
      _connection = connection;
      await connection.open();
      _status = connection.status.listen((status) {
        if (status.ended) {
          stop();
          return;
        }
        state = state.copyWith(
          playing: status.playing,
          position: status.position,
        );
      });
      state = state.copyWith(connecting: false);
      _wanted = asset.id;
      await _show(asset.id);
    } catch (_) {
      await stop();
      rethrow;
    }
  }

  Future<CastMedia?> _mediaOf(String id) async {
    final known = _sent[id];
    if (known != null) return known;
    final server = _server;
    final session = _sessionId;
    if (server == null || session == null) return null;
    final added = await server.add(session, [id]);
    for (final media in added.media) {
      _sent[media.id] = media;
    }
    return _sent[id];
  }

  Future<void> _show(String id) async {
    final media = await _mediaOf(id);
    final connection = _connection;
    final device = state.device;
    final server = _server;
    if (media == null ||
        connection == null ||
        device == null ||
        server == null) {
      return;
    }
    // Swiped on while this was on its way: the TV gets only the photo on the screen now.
    if (_wanted != id) return;
    final tv = tvMediaFor(media, server.serverUrl, _token, device.kind);
    await connection.show(tv);
    state = state.copyWith(
      current: id,
      video: tv.video,
      playing: true,
      position: Duration.zero,
      duration: tv.duration,
    );
  }

  /// Called as the photo on the phone changes: the TV follows.
  Future<void> follow(TvAsset asset) async {
    if (!state.active || state.current == asset.id && _wanted == asset.id) {
      return;
    }
    _wanted = asset.id;
    try {
      await _show(asset.id);
    } on Object {
      // This one cannot be shown; the TV keeps the last one.
    }
  }

  Future<void> playOrPause() async {
    final connection = _connection;
    if (connection == null) return;
    if (state.playing) {
      await connection.pause();
    } else {
      await connection.play();
    }
    state = state.copyWith(playing: !state.playing);
  }

  Future<void> seek(Duration to) async {
    await _connection?.seek(to);
    state = state.copyWith(position: to);
  }

  /// Stops casting; the TV's token stops working at once.
  Future<void> stop() => _release(updateState: true);

  Future<void> _release({required bool updateState}) async {
    final connection = _connection;
    final server = _server;
    final session = _sessionId;
    final status = _status;
    _connection = null;
    _server = null;
    _sessionId = null;
    _status = null;
    _wanted = null;
    _sent.clear();
    if (updateState && (state.device != null || state.connecting)) {
      state = TvState(added: state.added);
    }
    await status?.cancel();
    try {
      await connection?.close();
    } on Object {
      // Already gone.
    }
    if (server != null && session != null) {
      try {
        await server.stop(session);
      } on Object {
        // It ends by itself after four hours.
      }
    }
  }
}

final tvProvider = NotifierProvider<TvController, TvState>(TvController.new);

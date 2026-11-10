import 'dart:async';

/// What kind of TV a device is, which decides how the phone speaks to it.
enum TvKind { chromecast, dlna }

/// A TV found on the network, or added by its address.
class TvDevice {
  const TvDevice({
    required this.id,
    required this.name,
    required this.kind,
    required this.host,
    this.port = 0,
    this.controlUrl,
  });

  final String id;
  final String name;
  final TvKind kind;
  final String host;
  final int port;

  /// A DLNA TV's AVTransport control address.
  final String? controlUrl;

  @override
  bool operator ==(Object other) => other is TvDevice && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// What a TV is told to show: an address it opens itself, without any cookie.
class TvMedia {
  const TvMedia({
    required this.id,
    required this.url,
    required this.contentType,
    required this.video,
    this.title = 'Mediarr',
    this.duration,
  });

  final String id;
  final String url;
  final String contentType;
  final bool video;
  final String title;
  final Duration? duration;
}

/// What a TV says about what it plays.
class TvStatus {
  const TvStatus({
    this.playing = false,
    this.position = Duration.zero,
    this.ended = false,
  });

  final bool playing;
  final Duration position;

  /// The TV went away, or someone stopped it there.
  final bool ended;
}

class TvException implements Exception {
  const TvException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A connection to one TV.
abstract class TvConnection {
  Future<void> open();
  Future<void> show(TvMedia media);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration to);
  Future<void> close();
  Stream<TvStatus> get status;
}

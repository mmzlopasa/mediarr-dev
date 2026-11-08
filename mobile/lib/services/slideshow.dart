import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// How slides change.
enum SlideChange { fade, slide, zoom, none }

const slidePaces = [3, 5, 10, 20];

/// How a slideshow plays, kept on this phone.
class SlideshowSettings {
  const SlideshowSettings({
    this.seconds = 5,
    this.transition = SlideChange.fade,
    this.shuffle = false,
    this.loop = true,
    this.caption = false,
  });

  /// Anything missing or wrong takes its default.
  factory SlideshowSettings.fromJson(Object? raw) {
    if (raw is! Map) return const SlideshowSettings();
    final seconds = raw['seconds'];
    final transition = SlideChange.values
        .where((value) => value.name == raw['transition'])
        .firstOrNull;
    bool flag(String key, bool fallback) =>
        raw[key] is bool ? raw[key] as bool : fallback;
    return SlideshowSettings(
      seconds: slidePaces.contains(seconds) ? seconds as int : 5,
      transition: transition ?? SlideChange.fade,
      shuffle: flag('shuffle', false),
      loop: flag('loop', true),
      caption: flag('caption', false),
    );
  }

  final int seconds;
  final SlideChange transition;
  final bool shuffle;
  final bool loop;
  final bool caption;

  Map<String, Object> toJson() => {
    'seconds': seconds,
    'transition': transition.name,
    'shuffle': shuffle,
    'loop': loop,
    'caption': caption,
  };

  SlideshowSettings copyWith({
    int? seconds,
    SlideChange? transition,
    bool? shuffle,
    bool? loop,
    bool? caption,
  }) => SlideshowSettings(
    seconds: seconds ?? this.seconds,
    transition: transition ?? this.transition,
    shuffle: shuffle ?? this.shuffle,
    loop: loop ?? this.loop,
    caption: caption ?? this.caption,
  );

  static const _storage = FlutterSecureStorage();
  static const _key = 'slideshow';

  static Future<SlideshowSettings> load() async {
    try {
      final raw = await _storage.read(key: _key);
      return SlideshowSettings.fromJson(raw == null ? null : jsonDecode(raw));
    } on Exception {
      return const SlideshowSettings();
    }
  }

  Future<void> save() async {
    try {
      await _storage.write(key: _key, value: jsonEncode(toJson()));
    } on Exception {
      // The slideshow still plays.
    }
  }
}

/// The order of the slides: from the photo that was open; shuffled, that one still comes first.
List<T> playOrder<T>(
  List<T> items,
  bool Function(T) isStart,
  bool shuffle, [
  Random? random,
]) {
  final start = max(0, items.indexWhere(isStart));
  if (!shuffle) return [...items.skip(start), ...items.take(start)];
  if (items.isEmpty) return [];
  final first = items[start];
  final rest = [
    for (var i = 0; i < items.length; i++)
      if (i != start) items[i],
  ]..shuffle(random);
  return [first, ...rest];
}

/// The next slide, or null at the end when it does not go round again.
int? nextSlide(int index, int count, bool loop, [int step = 1]) {
  if (count == 0) return null;
  final next = index + step;
  if (next >= 0 && next < count) return next;
  if (!loop) return null;
  return ((next % count) + count) % count;
}

/// With less motion asked for, slides only fade.
SlideChange shownTransition(SlideChange transition, bool reduceMotion) =>
    reduceMotion &&
        (transition == SlideChange.slide || transition == SlideChange.zoom)
    ? SlideChange.fade
    : transition;

/// Keeps the screen on while a slideshow plays.
class KeepAwake {
  static const _channel = MethodChannel('app.mediarr/awake');

  static Future<void> set(bool on) async {
    try {
      await _channel.invokeMethod<void>('set', {'on': on});
    } on MissingPluginException {
      // Tests, and platforms without it.
    } on PlatformException {
      // The screen may sleep; the slideshow goes on.
    }
  }
}

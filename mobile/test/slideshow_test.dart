import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/services/slideshow.dart';

void main() {
  final items = ['a', 'b', 'c', 'd', 'e'];

  test('starts from the open photo and keeps the order of the list', () {
    expect(playOrder(items, (id) => id == 'c', false), [
      'c',
      'd',
      'e',
      'a',
      'b',
    ]);
    expect(playOrder(items, (id) => id == 'x', false), items);
  });

  test('shuffled, still starts from the open photo and shows each once', () {
    final order = playOrder(items, (id) => id == 'c', true, Random(7));
    expect(order.first, 'c');
    expect([...order]..sort(), items);
    expect(playOrder(<String>[], (id) => true, true), isEmpty);
  });

  test('goes round again only when it loops', () {
    expect(nextSlide(1, 5, false), 2);
    expect(nextSlide(4, 5, false), isNull);
    expect(nextSlide(4, 5, true), 0);
    expect(nextSlide(0, 5, true, -1), 4);
    expect(nextSlide(0, 0, true), isNull);
  });

  test('settings take their defaults for anything wrong', () {
    expect(SlideshowSettings.fromJson(null).seconds, 5);
    final kept = SlideshowSettings.fromJson(
      const SlideshowSettings(
        seconds: 10,
        transition: SlideChange.zoom,
        shuffle: true,
        loop: false,
        caption: true,
      ).toJson(),
    );
    expect(kept.seconds, 10);
    expect(kept.transition, SlideChange.zoom);
    expect(kept.shuffle, isTrue);
    expect(kept.loop, isFalse);
    expect(kept.caption, isTrue);
    final wrong = SlideshowSettings.fromJson({
      'seconds': 7,
      'transition': 'spin',
      'shuffle': 'yes',
    });
    expect(wrong.seconds, 5);
    expect(wrong.transition, SlideChange.fade);
    expect(wrong.shuffle, isFalse);
  });

  test('only fades when less motion is asked for', () {
    expect(shownTransition(SlideChange.zoom, true), SlideChange.fade);
    expect(shownTransition(SlideChange.none, true), SlideChange.none);
    expect(shownTransition(SlideChange.slide, false), SlideChange.slide);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/services/cull.dart';

void main() {
  test('the next photos are ready, the nearest first', () {
    expect(preloadIndexes(1, 6), [2, 3, 4, 0]);
    expect(preloadIndexes(1, 2), [0]);
  });

  test('long lists are cut for the server', () {
    expect(chunksOf([1, 2, 3], 2), [
      [1, 2],
      [3],
    ]);
    expect(chunksOf(<int>[]), isEmpty);
  });

  test('up to four photos are compared', () {
    expect(toggleCompared(['a'], 'b'), ['a', 'b']);
    expect(toggleCompared(['a', 'b'], 'a'), ['b']);
    expect(toggleCompared(['a', 'b', 'c', 'd'], 'e'), ['a', 'b', 'c', 'd']);
  });

  test('a drag up picks, down rejects, and sideways moves on', () {
    expect(swipeVerdict(0, -200), 1);
    expect(swipeVerdict(10, 200), -1);
    expect(swipeVerdict(200, 10), isNull);
    expect(swipeVerdict(0, 20), isNull);
    expect(swipeMove(-200, 0), 1);
    expect(swipeMove(200, 0), -1);
    expect(swipeMove(0, 200), isNull);
  });
}

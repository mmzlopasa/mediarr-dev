import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/timeline/layout.dart';
import 'package:mediarr_api/api.dart';

TimelineItem item(double ratio, {String localAt = '2024-07-15T12:00:00'}) =>
    TimelineItem(
      id: 'a',
      kind: TimelineItemKindEnum.photo,
      ratio: ratio,
      isFavorite: false,
      localAt: localAt,
    );

void main() {
  test('complete rows fill the width exactly', () {
    final rows = justify(List.generate(20, (_) => item(1.5)), 0, 366, 110);
    for (final row in rows.sublist(0, rows.length - 1)) {
      final used =
          row.tiles.fold<double>(0, (sum, tile) => sum + tile.width) +
          gap * (row.tiles.length - 1);
      expect(used, closeTo(366, 0.001));
    }
  });

  test('an unfinished last row is not stretched', () {
    final rows = justify([item(1)], 0, 366, 110);
    expect(rows.single.height, 110);
    expect(rows.single.tiles.single.width, 110);
  });

  test('a very wide panorama stays inside the width', () {
    final rows = justify([item(20)], 0, 300, 110);
    expect(rows.single.tiles.single.width, lessThanOrEqualTo(300.001));
  });

  test('a broken ratio still gives a tile', () {
    for (final ratio in [0.0, -1.0, double.nan, double.infinity]) {
      final rows = justify([item(ratio)], 0, 300, 110);
      expect(rows.single.tiles.single.width, greaterThan(0));
    }
  });

  test('tiles count from the start of the timeline', () {
    final rows = justify([item(1), item(1)], 7, 1000, 110);
    expect(rows.single.tiles.map((tile) => tile.index), [7, 8]);
  });

  test('a month has headers for itself and each local day', () {
    final rows = layoutMonth(
      [
        item(1, localAt: '2024-07-15T12:00:00'),
        item(1, localAt: '2024-07-14T23:59:00'),
      ],
      start: 0,
      width: 366,
      monthLabel: 'July 2024',
      dayLabel: formatDay,
    );
    final labels = rows.whereType<HeaderRow>().map((row) => row.label);
    expect(labels, ['July 2024', 'Mon 15 July', 'Sun 14 July']);
  });

  test('dates show the wall clock of the capture', () {
    expect(formatDateTime('2024-08-01T00:30:00'), '1 August 2024, 0:30');
    expect(formatMonth('2024-08'), 'August 2024');
    expect(formatBytes(1536), '1.5 KB');
    expect(formatBytes(512), '512 B');
  });
}

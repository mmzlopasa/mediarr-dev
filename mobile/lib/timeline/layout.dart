import 'package:mediarr_api/api.dart';

import '../l10n/l10n.dart';

const gap = 3.0;
const monthHeaderHeight = 60.0;
const dayHeaderHeight = 40.0;

sealed class TimelineRow {
  double get height;
}

class HeaderRow extends TimelineRow {
  HeaderRow(this.label, {required this.isMonth});

  final String label;
  final bool isMonth;

  @override
  double get height => isMonth ? monthHeaderHeight : dayHeaderHeight;
}

class Tile {
  Tile(this.item, this.index, this.width);

  final TimelineItem item;

  /// The position in the whole timeline, for opening the viewer.
  final int index;
  final double width;
}

class TilesRow extends TimelineRow {
  TilesRow(this.tiles, this.height);

  final List<Tile> tiles;

  @override
  final double height;
}

double rowHeightFor(double width) => width < 600 ? 110 : 170;

double _clamp(double ratio) =>
    ratio.isFinite && ratio > 0 ? ratio.clamp(0.4, 4.0).toDouble() : 1;

/// Splits items into rows that fill the width exactly, except for an unfinished last row.
List<TilesRow> justify(
  List<TimelineItem> items,
  int start,
  double width,
  double target,
) {
  final rows = <TilesRow>[];
  final current = <(TimelineItem, int, double)>[];
  var sum = 0.0;

  void close({required bool fill}) {
    final free = width - gap * (current.length - 1);
    var height = free / sum;
    if (!fill && height > target) height = target;
    rows.add(
      TilesRow([
        for (final (item, index, ratio) in current)
          Tile(item, index, ratio * height),
      ], height),
    );
    current.clear();
    sum = 0;
  }

  for (var i = 0; i < items.length; i++) {
    final ratio = _clamp(items[i].ratio);
    current.add((items[i], start + i, ratio));
    sum += ratio;
    if (sum * target + gap * (current.length - 1) >= width) close(fill: true);
  }
  if (current.isNotEmpty) close(fill: false);
  return rows;
}

/// Equal squares, a fixed number to a row.
List<TilesRow> squares(
  List<TimelineItem> items,
  int start,
  double width,
  int perRow,
) {
  final side = (width - gap * (perRow - 1)) / perRow;
  return [
    for (var from = 0; from < items.length; from += perRow)
      TilesRow([
        for (var i = from; i < from + perRow && i < items.length; i++)
          Tile(items[i], start + i, side),
      ], side),
  ];
}

/// A whole month from aspect ratios alone, so nothing moves as images load.
List<TimelineRow> layoutMonth(
  List<TimelineItem> items, {
  required int start,
  required double width,
  required String monthLabel,
  required String Function(String localAt) dayLabel,
  int perRow = 0,
  bool byDay = true,
}) {
  final target = rowHeightFor(width);
  List<TilesRow> arrange(List<TimelineItem> part, int first) => perRow > 0
      ? squares(part, first, width, perRow)
      : justify(part, first, width, target);
  final rows = <TimelineRow>[HeaderRow(monthLabel, isMonth: true)];
  if (!byDay) {
    rows.addAll(arrange(items, start));
    return rows;
  }
  var from = 0;
  while (from < items.length) {
    final day = items[from].localAt.substring(0, 10);
    var to = from + 1;
    while (to < items.length && items[to].localAt.substring(0, 10) == day) {
      to += 1;
    }
    rows.add(HeaderRow(dayLabel(items[from].localAt), isMonth: false));
    rows.addAll(arrange(items.sublist(from, to), start + from));
    from = to;
  }
  return rows;
}

/// Height of a month that has not loaded yet.
double estimateMonthHeight(int count, double width, [int perRow = 0]) {
  if (perRow > 0) {
    final side = (width - gap * (perRow - 1)) / perRow;
    return monthHeaderHeight +
        (count < 12 ? count : 12) * dayHeaderHeight +
        (count / perRow).ceil() * (side + gap);
  }
  final target = rowHeightFor(width);
  final fitting = (width / (1.4 * target + gap)).clamp(1.0, 100.0);
  final rows = (count / fitting).ceil();
  return monthHeaderHeight +
      (count < 12 ? count : 12) * dayHeaderHeight +
      rows * (target + gap);
}

/// Month names on their own, as in a heading.
List<String> get _months => [
  l.layoutJanuary,
  l.layoutFebruary,
  l.layoutMarch,
  l.layoutApril,
  l.layoutMay,
  l.layoutJune,
  l.layoutJuly,
  l.layoutAugust,
  l.layoutSeptember,
  l.layoutOctober,
  l.layoutNovember,
  l.layoutDecember,
];

/// Month names inside a date, which some languages decline.
List<String> get _monthsOf => [
  l.layoutJanuaryOf,
  l.layoutFebruaryOf,
  l.layoutMarchOf,
  l.layoutAprilOf,
  l.layoutMayOf,
  l.layoutJuneOf,
  l.layoutJulyOf,
  l.layoutAugustOf,
  l.layoutSeptemberOf,
  l.layoutOctoberOf,
  l.layoutNovemberOf,
  l.layoutDecemberOf,
];

List<String> get _weekdays => [
  l.layoutWeekdayMon,
  l.layoutWeekdayTue,
  l.layoutWeekdayWed,
  l.layoutWeekdayThu,
  l.layoutWeekdayFri,
  l.layoutWeekdaySat,
  l.layoutWeekdaySun,
];

String formatMonth(String month) {
  final parts = month.split('-');
  return l.layoutMonthYear(_months[int.parse(parts[1]) - 1], parts[0]);
}

// Local capture times have no zone. UTC keeps the wall clock of where the photo was taken.
DateTime parseLocal(String localAt) => DateTime.parse('${localAt}Z');

String formatDay(String localAt) {
  final date = parseLocal(localAt);
  return l.layoutDayLabel(
    _weekdays[date.weekday - 1],
    '${date.day}',
    _monthsOf[date.month - 1],
  );
}

String formatDateTime(String localAt) {
  final date = parseLocal(localAt);
  final minute = date.minute.toString().padLeft(2, '0');
  return l.layoutDateTime(
    '${date.day}',
    _monthsOf[date.month - 1],
    '${date.year}',
    '${date.hour}',
    minute,
  );
}

String formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit += 1;
  }
  return unit == 0 ? '$bytes B' : '${value.toStringAsFixed(1)} ${units[unit]}';
}

String formatDuration(int ms) {
  final total = (ms / 1000).round();
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = (total % 60).toString().padLeft(2, '0');
  return hours > 0
      ? '$hours:${minutes.toString().padLeft(2, '0')}:$seconds'
      : '$minutes:$seconds';
}

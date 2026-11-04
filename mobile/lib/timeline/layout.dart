import 'package:mediarr_api/api.dart';

const gap = 3.0;
const monthHeaderHeight = 58.0;
const dayHeaderHeight = 38.0;

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

double rowHeightFor(double width, [double scale = 1]) =>
    (width < 600 ? 110 : 170) * scale;

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

/// A whole month from aspect ratios alone, so nothing moves as images load.
List<TimelineRow> layoutMonth(
  List<TimelineItem> items, {
  required int start,
  required double width,
  required String monthLabel,
  required String Function(String localAt) dayLabel,
  double scale = 1,
}) {
  final target = rowHeightFor(width, scale);
  final rows = <TimelineRow>[HeaderRow(monthLabel, isMonth: true)];
  var from = 0;
  while (from < items.length) {
    final day = items[from].localAt.substring(0, 10);
    var to = from + 1;
    while (to < items.length && items[to].localAt.substring(0, 10) == day) {
      to += 1;
    }
    rows.add(HeaderRow(dayLabel(items[from].localAt), isMonth: false));
    rows.addAll(justify(items.sublist(from, to), start + from, width, target));
    from = to;
  }
  return rows;
}

/// Height of a month that has not loaded yet.
double estimateMonthHeight(int count, double width, [double scale = 1]) {
  final target = rowHeightFor(width, scale);
  final perRow = (width / (1.4 * target + gap)).clamp(1.0, 100.0);
  final rows = (count / perRow).ceil();
  return monthHeaderHeight +
      (count < 12 ? count : 12) * dayHeaderHeight +
      rows * (target + gap);
}

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String formatMonth(String month) {
  final parts = month.split('-');
  return '${_months[int.parse(parts[1]) - 1]} ${parts[0]}';
}

// Local capture times have no zone. UTC keeps the wall clock of where the photo was taken.
DateTime parseLocal(String localAt) => DateTime.parse('${localAt}Z');

String formatDay(String localAt) {
  final date = parseLocal(localAt);
  return '${_weekdays[date.weekday - 1]} ${date.day} ${_months[date.month - 1]}';
}

String formatDateTime(String localAt) {
  final date = parseLocal(localAt);
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.day} ${_months[date.month - 1]} ${date.year}, ${date.hour}:$minute';
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

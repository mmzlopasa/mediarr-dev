import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/memories_screen.dart';
import 'package:mediarr/services/days.dart';
import 'package:mediarr_api/api.dart';

void main() {
  test('today is the date on the phone, without the time', () {
    expect(localToday(DateTime(2026, 11, 3, 23, 59)), '2026-11-03');
    // Just after midnight it is already the new day, whatever the time zone.
    expect(localToday(DateTime(2026, 11, 6, 0, 5)), '2026-11-06');
  });

  test('a day sent in a body stays the same day in UTC', () {
    expect(dayOnly(DateTime(2024, 6, 15)).toUtc().day, 15);
    expect(dayString(DateTime(2024, 6, 5)), '2024-06-05');
  });

  test('a memory is titled by what it is', () {
    final now = DateTime(2026, 6, 15);
    expect(
      memoryTitle(
        Memory(kind: MemoryKindEnum.onThisDay, title: '2024-06-15', year: 2024),
        now,
      ),
      'On this day, 2 years ago',
    );
    expect(
      memoryTitle(Memory(kind: MemoryKindEnum.week, title: 'x'), now),
      'The last week',
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/memories_screen.dart';
import 'package:mediarr_api/api.dart';

void main() {
  test('today is the date on the phone, without the time', () {
    expect(localToday(DateTime(2026, 11, 3, 23, 59)), DateTime(2026, 11, 3));
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

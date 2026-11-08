import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/fix_sheet.dart';

void main() {
  test('a shift is counted in minutes, later or earlier', () {
    expect(shiftOf(later: true, hours: 1, minutes: 12), 72);
    expect(shiftOf(later: false, days: 1), -1440);
    expect(shiftOf(later: true), 0);
  });

  test('a typed time is sent with the offset of that day', () {
    final local = DateTime(2024, 7, 5, 14, 30);
    final text = withOffset(local);
    expect(text, startsWith('2024-07-05T14:30:00'));
    expect(DateTime.parse(text).isAtSameMomentAs(local), isTrue);
  });

  test('the zones on offer are real names', () {
    expect(commonZones, contains('Europe/Zagreb'));
    expect(
      commonZones.every((zone) => zone == 'UTC' || zone.contains('/')),
      isTrue,
    );
  });
}

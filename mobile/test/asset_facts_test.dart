import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/asset_facts.dart';

void main() {
  test('a moment keeps the offset of where it was taken', () {
    final clock = DateTime(2001, 2, 3, 4, 5, 6);
    expect(takenAtText(clock, 120), '2001-02-03T04:05:06+02:00');
    expect(takenAtText(clock, -330), '2001-02-03T04:05:06-05:30');
    expect(takenAtText(clock, 0), '2001-02-03T04:05:06+00:00');
  });
}

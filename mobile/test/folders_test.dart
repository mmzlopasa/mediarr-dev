import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/folders_screen.dart';

void main() {
  test('a folder is found by its path from the top', () {
    expect(folderChild('', 'trip'), 'trip');
    expect(folderChild('trip', 'day1'), 'trip/day1');
  });
}

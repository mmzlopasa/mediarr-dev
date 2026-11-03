import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/duplicates_screen.dart';
import 'package:mediarr_api/api.dart';

DuplicateItem _item(String id) => DuplicateItem(
  id: id,
  originalName: '$id.jpg',
  sizeBytes: 10,
  ratio: 1,
  localAt: '2024-01-01T10:00:00',
);

void main() {
  final group = DuplicateGroup(keepId: 'a', items: [_item('a'), _item('b')]);

  test('the proposal keeps one and trashes the rest', () {
    expect(shotsToTrash(group, {}), ['b']);
  });

  test('the user decides what is kept', () {
    expect(shotsToTrash(group, {'b': true}), isEmpty);
    expect(shotsToTrash(group, {'a': false, 'b': true}), ['a']);
  });

  test('a group can never go to the trash as a whole', () {
    expect(shotsToTrash(group, {'a': false}), isEmpty);
  });
}

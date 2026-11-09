import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/duplicates_screen.dart';
import 'package:mediarr_api/api.dart';

DuplicateItem _item(String id, {bool original = false, bool resaved = false}) =>
    DuplicateItem(
      id: id,
      originalName: '$id.jpg',
      sizeBytes: 10,
      ratio: 1,
      localAt: '2024-01-01T10:00:00',
      favorite: false,
      original: original,
      resaved: resaved,
      hasDate: true,
      hasLocation: false,
      hasCaption: false,
    );

void main() {
  final group = DuplicateGroup(
    keepId: 'a',
    exact: false,
    freedBytes: 10,
    items: [_item('a', original: true), _item('b', resaved: true)],
  );

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

  test('resolving keeps one, and another when the proposal is unticked', () {
    final choice = duplicateChoice(group, {});
    expect(choice?.keepId, 'a');
    expect(choice?.trashIds, ['b']);
    final other = duplicateChoice(group, {'a': false, 'b': true});
    expect(other?.keepId, 'b');
    expect(other?.trashIds, ['a']);
    expect(duplicateChoice(group, {'a': false}), isNull);
  });

  test('it says why one is proposed and how the copies differ', () {
    expect(duplicateReason(group), "the camera's original");
    expect(duplicateNotes(group.items[1]), ['Saved again by an app']);
  });
}

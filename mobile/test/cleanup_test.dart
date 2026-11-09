import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/cleanup_screen.dart';
import 'package:mediarr_api/api.dart';

CleanupItem _item({bool favorite = false, bool inAlbum = false}) => CleanupItem(
  id: 'a',
  originalName: 'a.png',
  sizeBytes: 1,
  kind: CleanupItemKindEnum.photo,
  ratio: 1,
  localAt: '2024-07-05T10:00:00',
  favorite: favorite,
  inAlbum: inAlbum,
);

void main() {
  test('all is ticked but favorites and photos in albums', () {
    expect(cleanupTicked(_item()), isTrue);
    expect(cleanupTicked(_item(favorite: true)), isFalse);
    expect(cleanupTicked(_item(inAlbum: true)), isFalse);
  });

  test('a video says how long it is', () {
    expect(videoLength(65000), '1:05');
    expect(videoLength(3725000), '1:02:05');
  });

  test('each kind has a name', () {
    expect(cleanupTitle(CleanupCategoryId.largeVideos), 'Large videos');
  });
}

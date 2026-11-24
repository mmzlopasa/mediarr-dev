import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/services/uploads.dart';

void main() {
  test(
    "a Live Photo's video is named after its still, as the server pairs them",
    () {
      expect(
        livePhotoVideoName('IMG_0001.HEIC', '/tmp/x/ABC-123.mov'),
        'IMG_0001.MOV',
      );
      expect(livePhotoVideoName('IMG_0002', '/tmp/a.mp4'), 'IMG_0002.MP4');
      expect(livePhotoVideoName('IMG.0003.JPG', '/tmp/v'), 'IMG.0003.MOV');
    },
  );

  test('only a video is sent as the moving part', () {
    expect(isVideoPath('/tmp/a.MOV'), isTrue);
    expect(isVideoPath('/tmp/a.mp4'), isTrue);
    expect(isVideoPath('/tmp/a.heic'), isFalse);
  });
}

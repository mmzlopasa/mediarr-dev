import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/photo_editor_screen.dart';

void main() {
  test('a corner moves and stays inside the picture', () {
    final moved = CropArea.whole.moved(CropCorner.topLeft, 0.25, 0.5);
    expect(moved.x, 0.25);
    expect(moved.y, 0.5);
    expect(moved.width, 0.75);
    expect(moved.height, 0.5);
    final outside = CropArea.whole.moved(CropCorner.bottomRight, 5, -5);
    expect(outside.width, 1);
    expect(outside.height, closeTo(minCropSide, 0.0001));
  });

  test('the box follows the picture when it turns, like on the web', () {
    const left = CropArea(0, 0, 0.5, 1);
    final turned = left.turned();
    expect([turned.x, turned.y, turned.width, turned.height], [0, 0, 1, 0.5]);
    final around = left.turned().turned().turned().turned();
    expect([around.x, around.y, around.width, around.height], [0, 0, 0.5, 1]);
  });

  test('no changes leave the colours as they are', () {
    expect(editColorMatrix(0, 0, 0), [
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]);
  });
}

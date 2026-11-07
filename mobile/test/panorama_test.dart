import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/screens/panorama_view.dart';

void main() {
  test(
    'dragging turns the panorama all the way round and stops at the poles',
    () {
      const look = PanoramaLook(yaw: 0, pitch: 0, fov: math.pi / 2);
      final right = look.dragged(const Offset(-100, 0), 100);
      expect(right.yaw, closeTo(math.pi / 2, 1e-9));
      final round = look.dragged(const Offset(-400, 0), 100);
      expect(round.yaw, closeTo(0, 1e-9));
      final up = look.dragged(const Offset(0, 1000), 100);
      expect(up.pitch, panoramaPitchLimit);
      final down = look.dragged(const Offset(0, -1000), 100);
      expect(down.pitch, -panoramaPitchLimit);
    },
  );

  test('pinching zooms within limits', () {
    const look = PanoramaLook(fov: math.pi / 2);
    expect(look.zoomed(2, math.pi / 2).fov, closeTo(math.pi / 4, 1e-9));
    expect(look.zoomed(100, math.pi / 2).fov, panoramaFovMin);
    expect(look.zoomed(0.1, math.pi / 2).fov, panoramaFovMax);
  });
}

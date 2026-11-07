import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// How far one can look up or down, and zoom, in a panorama.
const panoramaPitchLimit = 85 * math.pi / 180;
const panoramaFovMin = 30 * math.pi / 180;
const panoramaFovMax = 100 * math.pi / 180;

/// Where one looks in a panorama.
class PanoramaLook {
  const PanoramaLook({
    this.yaw = 0,
    this.pitch = 0,
    this.fov = 75 * math.pi / 180,
  });

  final double yaw;
  final double pitch;
  final double fov;

  /// A drag of [delta] pixels on a view [height] tall turns as much as the field of view shows.
  PanoramaLook dragged(Offset delta, double height) {
    final perPixel = fov / height;
    return PanoramaLook(
      yaw: (yaw - delta.dx * perPixel) % (2 * math.pi),
      pitch: (pitch + delta.dy * perPixel).clamp(
        -panoramaPitchLimit,
        panoramaPitchLimit,
      ),
      fov: fov,
    );
  }

  /// Pinching out by [scale] narrows the view, as a zoom.
  PanoramaLook zoomed(double scale, double startFov) => PanoramaLook(
    yaw: yaw,
    pitch: pitch,
    fov: (startFov / scale).clamp(panoramaFovMin, panoramaFovMax),
  );
}

/// A 360° panorama, turned with a finger and zoomed with two. Drawn by a small shader, so it needs
/// no 3D library.
class PanoramaView extends StatefulWidget {
  const PanoramaView({super.key, required this.url, required this.headers});

  final String url;
  final Map<String, String> headers;

  @override
  State<PanoramaView> createState() => _PanoramaViewState();
}

class _PanoramaViewState extends State<PanoramaView> {
  static const _maxWidth = 4096;

  ui.FragmentProgram? _program;
  ui.Image? _image;
  bool _failed = false;
  PanoramaLook _look = const PanoramaLook();
  double _startFov = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/panorama.frag',
      );
      final response = await http.get(
        Uri.parse(widget.url),
        headers: widget.headers,
      );
      if (response.statusCode != 200) {
        throw StateError('${response.statusCode}');
      }
      // A phone's graphics memory takes a panorama this wide, and it stays sharp.
      final codec = await ui.instantiateImageCodec(
        response.bodyBytes,
        targetWidth: _maxWidth,
        allowUpscaling: false,
      );
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() {
        _program = program;
        _image = frame.image;
      });
    } on Exception {
      if (mounted) setState(() => _failed = true);
    } on Error {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    final program = _program;
    if (_failed) {
      return const Center(
        child: Text(
          'The panorama cannot be shown.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    if (image == null || program == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Semantics(
      label: '360° panorama',
      image: true,
      child: LayoutBuilder(
        builder: (context, box) => GestureDetector(
          onScaleStart: (_) => _startFov = _look.fov,
          onScaleUpdate: (details) => setState(() {
            _look = details.pointerCount > 1
                ? _look.zoomed(details.scale, _startFov)
                : _look.dragged(details.focalPointDelta, box.maxHeight);
          }),
          child: CustomPaint(
            size: Size(box.maxWidth, box.maxHeight),
            painter: _PanoramaPainter(program.fragmentShader(), image, _look),
          ),
        ),
      ),
    );
  }
}

class _PanoramaPainter extends CustomPainter {
  _PanoramaPainter(this.shader, this.image, this.look);

  final ui.FragmentShader shader;
  final ui.Image image;
  final PanoramaLook look;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, look.yaw)
      ..setFloat(3, look.pitch)
      ..setFloat(4, look.fov)
      ..setImageSampler(0, image);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_PanoramaPainter old) =>
      old.look != look || old.image != image;
}

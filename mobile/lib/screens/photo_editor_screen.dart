import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mediarr_api/api.dart';

import '../services/session.dart';
import '../theme.dart';

const minCropSide = 0.05;

enum CropCorner { topLeft, topRight, bottomLeft, bottomRight }

/// A part of the picture after rotating it, in fractions of its sides.
class CropArea {
  const CropArea(this.x, this.y, this.width, this.height);

  static const whole = CropArea(0, 0, 1, 1);

  final double x;
  final double y;
  final double width;
  final double height;

  bool get isWhole => x == 0 && y == 0 && width == 1 && height == 1;

  /// Moves one corner, keeping the box inside the picture and from turning inside out.
  CropArea moved(CropCorner corner, double toX, double toY) {
    var left = x;
    var top = y;
    var right = x + width;
    var bottom = y + height;
    if (corner == CropCorner.topLeft || corner == CropCorner.bottomLeft) {
      left = toX.clamp(0, right - minCropSide);
    } else {
      right = toX.clamp(left + minCropSide, 1);
    }
    if (corner == CropCorner.topLeft || corner == CropCorner.topRight) {
      top = toY.clamp(0, bottom - minCropSide);
    } else {
      bottom = toY.clamp(top + minCropSide, 1);
    }
    return CropArea(left, top, right - left, bottom - top);
  }

  /// The same part of the picture after it turns 90° clockwise.
  CropArea turned() => CropArea(1 - y - height, x, height, width);
}

/// Colour changes in the preview, close to what the server applies to the previews it makes.
List<double> editColorMatrix(int brightness, int contrast, int saturation) {
  final c = 1 + contrast / 100;
  final s = 1 + saturation / 100;
  final offset = 128 * (1 - c) + brightness * 1.28;
  const r = 0.2126;
  const g = 0.7152;
  const b = 0.0722;
  return [
    c * (r * (1 - s) + s),
    c * g * (1 - s),
    c * b * (1 - s),
    0,
    offset,
    c * r * (1 - s),
    c * (g * (1 - s) + s),
    c * b * (1 - s),
    0,
    offset,
    c * r * (1 - s),
    c * g * (1 - s),
    c * (b * (1 - s) + s),
    0,
    offset,
    0,
    0,
    0,
    1,
    0,
  ];
}

/// A preview of each look, close to the table the server applies.
List<double>? lookMatrix(AssetEditsFilterEnum? look) {
  const r = 0.2126;
  const g = 0.7152;
  const b = 0.0722;
  if (look == AssetEditsFilterEnum.mono) {
    return const [r, g, b, 0, 0, r, g, b, 0, 0, r, g, b, 0, 0, 0, 0, 0, 1, 0];
  }
  if (look == AssetEditsFilterEnum.warm) {
    return const [
      1.08,
      0,
      0,
      0,
      5,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      0.9,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }
  if (look == AssetEditsFilterEnum.cool) {
    return const [
      0.9,
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
      1.08,
      0,
      5,
      0,
      0,
      0,
      1,
      0,
    ];
  }
  if (look == AssetEditsFilterEnum.vintage) {
    return const [
      0.86,
      0,
      0,
      0,
      20,
      0,
      0.82,
      0,
      0,
      18,
      0,
      0,
      0.68,
      0,
      25,
      0,
      0,
      0,
      1,
      0,
    ];
  }
  if (look == AssetEditsFilterEnum.vivid) {
    const p = 1.35;
    final q = 1 - p;
    return [
      q * r + p,
      q * g,
      q * b,
      0,
      0,
      q * r,
      q * g + p,
      q * b,
      0,
      0,
      q * r,
      q * g,
      q * b + p,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }
  return null;
}

/// Edits a photo as a list of changes. The original on the server is never touched. Returns true
/// when the previews changed.
class PhotoEditorScreen extends StatefulWidget {
  const PhotoEditorScreen({super.key, required this.session, required this.id});

  final Session session;
  final String id;

  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  static const _waitEvery = Duration(milliseconds: 500);
  static const _waitTries = 120;

  AssetDetail? _detail;
  int _rotate = 0;
  CropArea _crop = CropArea.whole;
  int _brightness = 0;
  int _contrast = 0;
  int _saturation = 0;
  AssetEditsFilterEnum? _look;
  bool _filtersOn = false;
  Size? _pictureSize;
  bool _busy = false;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  String get _sourceUrl =>
      '${widget.session.serverUrl}/api/assets/${widget.id}/thumbnail?size=source';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    final listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    super.dispose();
  }

  Future<void> _load() async {
    final detail = await widget.session.detail(widget.id);
    if (!mounted || detail == null) return;
    final edits = detail.edits;
    final crop = edits?.crop;
    setState(() {
      _detail = detail;
      _rotate = edits?.rotate ?? 0;
      _crop = crop == null
          ? CropArea.whole
          : CropArea(
              crop.x.toDouble(),
              crop.y.toDouble(),
              crop.width.toDouble(),
              crop.height.toDouble(),
            );
      _brightness = edits?.brightness ?? 0;
      _contrast = edits?.contrast ?? 0;
      _saturation = edits?.saturation ?? 0;
      _look = edits?.filter;
    });
    try {
      final features = await widget.session.api.getFeatures();
      if (mounted) {
        setState(() => _filtersOn = features?['filters'] ?? false);
      }
    } on ApiException {
      // The rest of the editor works without filters.
    }
    final image = NetworkImage(_sourceUrl, headers: widget.session.headers);
    _stream = image.resolve(ImageConfiguration.empty);
    _listener = ImageStreamListener((info, _) {
      if (mounted) {
        setState(() {
          _pictureSize = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
        });
      }
    });
    _stream!.addListener(_listener!);
  }

  Future<void> _finish(Future<void> Function() action) async {
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      for (var attempt = 0; attempt < _waitTries; attempt++) {
        final current = await widget.session.detail(widget.id);
        if (current?.isEditing != true) break;
        await Future<void>.delayed(_waitEvery);
      }
      final server = widget.session.serverUrl;
      await CachedNetworkImage.evictFromCache(
        widget.session.thumbnailUrl(widget.id),
        cacheKey: '$server/${widget.id}/s',
      );
      await CachedNetworkImage.evictFromCache(
        widget.session.thumbnailUrl(widget.id, large: true),
        cacheKey: '$server/${widget.id}/l',
      );
      navigator.pop(true);
    } on ApiException catch (cause) {
      messenger.showSnackBar(
        SnackBar(content: Text('The action failed. ${cause.message ?? ''}')),
      );
      if (mounted) setState(() => _busy = false);
    }
  }

  void _save() => _finish(
    () => widget.session.api.setAssetEdits(
      widget.id,
      AssetEdits(
        rotate: _rotate,
        crop: _crop.isWhole
            ? null
            : CropBox(
                x: _crop.x,
                y: _crop.y,
                width: _crop.width,
                height: _crop.height,
              ),
        brightness: _brightness,
        contrast: _contrast,
        saturation: _saturation,
        filter: _look,
      ),
    ),
  );

  Widget _stage(Size picture) {
    final sideways = _rotate % 180 != 0;
    final ratio = sideways
        ? picture.height / picture.width
        : picture.width / picture.height;
    return Center(
      child: AspectRatio(
        aspectRatio: ratio,
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            final h = box.maxHeight;
            return Stack(
              fit: StackFit.expand,
              children: [
                ColorFiltered(
                  colorFilter: ColorFilter.matrix(
                    editColorMatrix(_brightness, _contrast, _saturation),
                  ),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.matrix(
                      lookMatrix(_look) ?? editColorMatrix(0, 0, 0),
                    ),
                    child: RotatedBox(
                      quarterTurns: _rotate ~/ 90,
                      child: Image.network(
                        _sourceUrl,
                        headers: widget.session.headers,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
                CustomPaint(painter: _CropShade(_crop)),
                for (final corner in CropCorner.values) _handle(corner, w, h),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _handle(CropCorner corner, double w, double h) {
    const size = 36.0;
    final left =
        corner == CropCorner.topLeft || corner == CropCorner.bottomLeft;
    final top = corner == CropCorner.topLeft || corner == CropCorner.topRight;
    final x = (left ? _crop.x : _crop.x + _crop.width) * w;
    final y = (top ? _crop.y : _crop.y + _crop.height) * h;
    return Positioned(
      left: x - size / 2,
      top: y - size / 2,
      width: size,
      height: size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) => setState(() {
          final at = Offset(x, y) + details.delta;
          _crop = _crop.moved(corner, at.dx / w, at.dy / h);
        }),
        child: Center(
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _slider(String label, int value, void Function(int) changed) => Row(
    children: [
      SizedBox(width: 92, child: Text(label)),
      Expanded(
        child: Slider(
          value: value.toDouble(),
          min: -100,
          max: 100,
          activeColor: Palette.gold,
          onChanged: _busy
              ? null
              : (next) => setState(() => changed(next.round())),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final picture = _pictureSize;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Edit'),
        actions: [
          IconButton(
            tooltip: 'Rotate',
            icon: const Icon(Icons.rotate_right),
            onPressed: _busy
                ? null
                : () => setState(() {
                    _rotate = (_rotate + 90) % 360;
                    _crop = _crop.turned();
                  }),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: picture == null
                    ? const Center(
                        child: CircularProgressIndicator(color: Palette.gold),
                      )
                    : _stage(picture),
              ),
            ),
            _slider('Brightness', _brightness, (v) => _brightness = v),
            _slider('Contrast', _contrast, (v) => _contrast = v),
            _slider('Saturation', _saturation, (v) => _saturation = v),
            if (_filtersOn)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButton<AssetEditsFilterEnum?>(
                  isExpanded: true,
                  value: _look,
                  dropdownColor: Palette.bg2,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('No filter')),
                    DropdownMenuItem(
                      value: AssetEditsFilterEnum.mono,
                      child: Text('Black and white'),
                    ),
                    DropdownMenuItem(
                      value: AssetEditsFilterEnum.warm,
                      child: Text('Warm'),
                    ),
                    DropdownMenuItem(
                      value: AssetEditsFilterEnum.cool,
                      child: Text('Cool'),
                    ),
                    DropdownMenuItem(
                      value: AssetEditsFilterEnum.vintage,
                      child: Text('Vintage'),
                    ),
                    DropdownMenuItem(
                      value: AssetEditsFilterEnum.vivid,
                      child: Text('Vivid'),
                    ),
                  ],
                  onChanged: _busy
                      ? null
                      : (next) => setState(() => _look = next),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  if (_detail?.edits != null)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _finish(
                              () =>
                                  widget.session.api.clearAssetEdits(widget.id),
                            ),
                      child: const Text('Back to the original'),
                    ),
                  const Spacer(),
                  SizedBox(
                    width: 120,
                    child: GoldButton(
                      label: 'Save',
                      busy: _busy,
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropShade extends CustomPainter {
  const _CropShade(this.crop);

  final CropArea crop;

  @override
  void paint(Canvas canvas, Size size) {
    final inner = Rect.fromLTWH(
      crop.x * size.width,
      crop.y * size.height,
      crop.width * size.width,
      crop.height * size.height,
    );
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRect(inner),
      ),
      Paint()..color = Colors.black54,
    );
    canvas.drawRect(
      inner,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_CropShade old) => old.crop != crop;
}

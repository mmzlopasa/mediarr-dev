import '../services/days.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:mediarr_api/api.dart';

import '../services/session.dart';
import '../services/timeline.dart';
import '../theme.dart';
import 'viewer_screen.dart';
import '../l10n/l10n.dart';

/// The points as GeoJSON. Each photo keeps its id, which a tap on the map gives back.
Map<String, dynamic> pointsToGeoJson(MapPoints points) => {
  'type': 'FeatureCollection',
  'features': [
    for (var i = 0; i < points.ids.length; i++)
      {
        'type': 'Feature',
        'id': points.ids[i],
        'properties': {'id': points.ids[i]},
        'geometry': {
          'type': 'Point',
          'coordinates': [points.lons[i], points.lats[i]],
        },
      },
  ],
};

String tripTitle(Trip trip) =>
    trip.places.isEmpty ? l.mapScreenNoPlaceName : trip.places.join(', ');

typedef MapBuilder = Widget Function(
  String style,
  MapPoints points,
  void Function(String id) onPhoto,
);

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, this.mapBuilder});

  /// Replaces the native map, which does not exist in widget tests.
  final MapBuilder? mapBuilder;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  MapPoints? _points;
  MapStyle? _style;
  List<Trip> _trips = const [];
  bool _failed = false;
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final style = await _session.api.getMapStyle();
      final trips = await _session.api.getMapTrips();
      if (!mounted) return;
      setState(() {
        _style = style;
        _trips = trips ?? const [];
      });
      await _loadPoints();
    } on ApiException {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _loadPoints() async {
    try {
      final points = await _session.api.getMapPoints(
        from: _from == null ? null : dayString(_from!),
        to: _to == null ? null : dayString(_to!),
      );
      if (mounted) {
        setState(() {
          _points = points;
          _failed = false;
        });
      }
    } on ApiException {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _open(String id) {
    final points = _points;
    if (points == null) return;
    final index = points.ids.indexOf(id);
    if (index < 0) return;
    final store = TimelineStore.fixed(_session, [
      for (var i = 0; i < points.ids.length; i++)
        TimelineItem(
          id: points.ids[i],
          kind:
              TimelineItemKindEnum.fromJson(points.kinds[i]) ??
              TimelineItemKindEnum.photo,
          ratio: 1,
          isFavorite: false,
          localAt: '',
        ),
    ]);
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) =>
                ViewerScreen(initialIndex: index, store: store, readOnly: true),
          ),
        )
        .then((_) => store.dispose());
  }

  Future<void> _pick(bool from) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (from ? _from : _to) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => from ? _from = picked : _to = picked);
    await _loadPoints();
  }

  String _date(DateTime? value, String none) => value == null
      ? none
      : '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final points = _points;
    final style = _style;
    final text = Theme.of(context).textTheme;
    Widget body;
    if (points == null || style == null) {
      body = _failed
          ? EmptyMessage(
              icon: Icons.cloud_off,
              text: l.mapScreenNotLoaded,
              action: GoldButton(
                label: l.mapScreenTryAgain,
                onPressed: _loadAll,
              ),
            )
          : Center(child: CircularProgressIndicator(color: Palette.gold));
    } else if (points.ids.isEmpty && _from == null && _to == null) {
      body = EmptyMessage(icon: Icons.map_outlined, text: l.mapScreenNoPhotos);
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TextButton(
                onPressed: () => _pick(true),
                child: Text(_date(_from, l.mapScreenFromDate)),
              ),
              TextButton(
                onPressed: () => _pick(false),
                child: Text(_date(_to, l.mapScreenToDate)),
              ),
              if (_from != null || _to != null)
                IconButton(
                  tooltip: l.mapScreenClear,
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _from = null;
                      _to = null;
                    });
                    _loadPoints();
                  },
                ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  l.mapScreenItems('${points.ids.length}'),
                  style: text.bodySmall?.copyWith(color: Palette.dim),
                ),
              ),
            ],
          ),
          Expanded(
            child:
                widget.mapBuilder?.call(style.dark, points, _open) ??
                _NativeMap(style: style.dark, points: points, onPhoto: _open),
          ),
          if (_trips.isNotEmpty)
            SizedBox(
              height: 148,
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(l.mapScreenTrips, style: text.titleMedium),
                  ),
                  for (final trip in _trips)
                    ListTile(
                      title: Text(tripTitle(trip)),
                      subtitle: Text(
                        '${trip.from} – ${trip.to} · ${trip.count}',
                      ),
                      onTap: () {
                        setState(() {
                          _from = DateTime.parse(trip.from);
                          _to = DateTime.parse(trip.to);
                        });
                        _loadPoints();
                      },
                    ),
                ],
              ),
            ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.mapScreenTitle)),
      body: body,
    );
  }
}

class _NativeMap extends StatefulWidget {
  const _NativeMap({
    required this.style,
    required this.points,
    required this.onPhoto,
  });

  final String style;
  final MapPoints points;
  final void Function(String id) onPhoto;

  @override
  State<_NativeMap> createState() => _NativeMapState();
}

class _NativeMapState extends State<_NativeMap> {
  static const _source = 'photos';
  static const _gold = '#f5c94c';
  static const _edge = '#1a1a1a';
  MapLibreMapController? _controller;
  bool _ready = false;

  @override
  void didUpdateWidget(_NativeMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controller = _controller;
    if (_ready && controller != null && oldWidget.points != widget.points) {
      controller.setGeoJsonSource(_source, pointsToGeoJson(widget.points));
    }
  }

  Future<void> _styleLoaded() async {
    final controller = _controller;
    if (controller == null) return;
    await controller.addSource(
      _source,
      GeojsonSourceProperties(
        data: pointsToGeoJson(widget.points),
        cluster: true,
        clusterRadius: 50,
      ),
    );
    await controller.addCircleLayer(
      _source,
      'clusters',
      const CircleLayerProperties(
        circleColor: _gold,
        circleOpacity: 0.85,
        circleStrokeWidth: 2,
        circleStrokeColor: _edge,
        circleRadius: [
          'step',
          ['get', 'point_count'],
          14,
          10,
          18,
          100,
          24,
          1000,
          30,
        ],
      ),
      filter: ['has', 'point_count'],
    );
    await controller.addCircleLayer(
      _source,
      'photo',
      const CircleLayerProperties(
        circleColor: _gold,
        circleRadius: 7,
        circleStrokeWidth: 2,
        circleStrokeColor: _edge,
      ),
      filter: [
        '!',
        ['has', 'point_count'],
      ],
    );
    controller.onFeatureTapped.add((
      point,
      coordinates,
      id,
      layerId,
      annotation,
    ) {
      if (layerId == 'photo') {
        widget.onPhoto(id);
      } else if (layerId == 'clusters') {
        controller.animateCamera(CameraUpdate.newLatLngZoom(coordinates, 8));
      }
    });
    _ready = true;
    await _fit();
  }

  Future<void> _fit() async {
    final points = widget.points;
    final controller = _controller;
    if (controller == null || points.ids.isEmpty) return;
    var south = points.lats.first, north = points.lats.first;
    var west = points.lons.first, east = points.lons.first;
    for (var i = 1; i < points.ids.length; i++) {
      if (points.lats[i] < south) south = points.lats[i];
      if (points.lats[i] > north) north = points.lats[i];
      if (points.lons[i] < west) west = points.lons[i];
      if (points.lons[i] > east) east = points.lons[i];
    }
    if (south == north && west == east) {
      await controller.moveCamera(
        CameraUpdate.newLatLngZoom(LatLng(south, west), 10),
      );
      return;
    }
    await controller.moveCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(south, west),
          northeast: LatLng(north, east),
        ),
        left: 48,
        top: 48,
        right: 48,
        bottom: 48,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MapLibreMap(
    styleString: widget.style,
    initialCameraPosition: const CameraPosition(target: LatLng(30, 10)),
    onMapCreated: (controller) => _controller = controller,
    onStyleLoadedCallback: _styleLoaded,
    compassEnabled: false,
    myLocationEnabled: false,
  );
}

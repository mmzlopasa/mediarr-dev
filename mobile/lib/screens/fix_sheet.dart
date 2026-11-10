import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mediarr_api/api.dart';

import '../services/session.dart';
import '../theme.dart';
import '../l10n/l10n.dart';

/// Time zones offered for a trip; any other can be typed.
const commonZones = [
  'Europe/Zagreb',
  'Europe/London',
  'Europe/Lisbon',
  'Europe/Paris',
  'Europe/Berlin',
  'Europe/Athens',
  'Europe/Istanbul',
  'Europe/Moscow',
  'Africa/Cairo',
  'Africa/Johannesburg',
  'Asia/Dubai',
  'Asia/Kolkata',
  'Asia/Bangkok',
  'Asia/Singapore',
  'Asia/Shanghai',
  'Asia/Seoul',
  'Asia/Tokyo',
  'Australia/Perth',
  'Australia/Sydney',
  'Pacific/Auckland',
  'Pacific/Honolulu',
  'America/Anchorage',
  'America/Los_Angeles',
  'America/Denver',
  'America/Chicago',
  'America/New_York',
  'America/Halifax',
  'America/Sao_Paulo',
  'America/Mexico_City',
  'America/Buenos_Aires',
  'Atlantic/Reykjavik',
  'UTC',
];

/// A typed local time with this phone's offset on that day, as the server wants it.
String withOffset(DateTime local) {
  final offset = local.timeZoneOffset.inMinutes;
  String two(int value) => value.toString().padLeft(2, '0');
  final sign = offset < 0 ? '-' : '+';
  final size = offset.abs();
  return '${local.year.toString().padLeft(4, '0')}-${two(local.month)}-${two(local.day)}'
      'T${two(local.hour)}:${two(local.minute)}:00$sign${two(size ~/ 60)}:${two(size % 60)}';
}

/// The shift in minutes from days, hours and minutes, later or earlier.
int shiftOf({
  required bool later,
  int days = 0,
  int hours = 0,
  int minutes = 0,
}) {
  final total = (days * 24 + hours) * 60 + minutes;
  return later ? total : -total;
}

/// Fixes the dates or the places of many photos, showing what changes before it does.
Future<bool> showFixSheet(
  BuildContext context,
  Session session,
  List<String> ids, {
  required bool dates,
}) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (context, scroll) =>
            _FixSheet(session: session, ids: ids, dates: dates, scroll: scroll),
      ),
    ) ??
    false;

class _FixSheet extends StatefulWidget {
  const _FixSheet({
    required this.session,
    required this.ids,
    required this.dates,
    required this.scroll,
  });

  final Session session;
  final List<String> ids;
  final bool dates;
  final ScrollController scroll;

  @override
  State<_FixSheet> createState() => _FixSheetState();
}

class _FixSheetState extends State<_FixSheet> {
  String _dateAction = 'shift';
  String _placeAction = 'fromNeighbours';
  bool _later = false;
  final _days = TextEditingController(text: '0');
  final _hours = TextEditingController(text: '0');
  final _minutes = TextEditingController(text: '0');
  final _cameraZone = TextEditingController(text: 'Europe/Zagreb');
  final _placeZone = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _search = TextEditingController();
  final _near = TextEditingController(text: '30');
  DateTime? _setAt;
  String? _track;
  String _trackName = '';
  List<Place> _places = const [];
  FixResult? _preview;
  String? _problem;
  bool _busy = false;
  Timer? _typing;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _typing?.cancel();
    for (final field in [
      _days,
      _hours,
      _minutes,
      _cameraZone,
      _placeZone,
      _latitude,
      _longitude,
      _search,
      _near,
    ]) {
      field.dispose();
    }
    super.dispose();
  }

  int _number(TextEditingController field) =>
      int.tryParse(field.text.trim()) ?? 0;

  /// What to send, or null while something is missing.
  Future<FixResult?> _send(bool dryRun) {
    final api = widget.session.api;
    if (widget.dates) {
      DateFix? body;
      switch (_dateAction) {
        case 'shift':
          final minutes = shiftOf(
            later: _later,
            days: _number(_days),
            hours: _number(_hours),
            minutes: _number(_minutes),
          );
          if (minutes != 0) {
            body = DateFix(
              ids: widget.ids,
              action: DateFixActionEnum.shift,
              minutes: minutes,
              dryRun: dryRun,
            );
          }
        case 'set':
          if (_setAt != null) {
            body = DateFix(
              ids: widget.ids,
              action: DateFixActionEnum.set_,
              takenAt: withOffset(_setAt!),
              dryRun: dryRun,
            );
          }
        case 'travel':
          if (_cameraZone.text.trim().isNotEmpty &&
              _placeZone.text.trim().isNotEmpty) {
            body = DateFix(
              ids: widget.ids,
              action: DateFixActionEnum.travel,
              cameraZone: _cameraZone.text.trim(),
              placeZone: _placeZone.text.trim(),
              dryRun: dryRun,
            );
          }
        case 'zoneFromPlace':
          body = DateFix(
            ids: widget.ids,
            action: DateFixActionEnum.zoneFromPlace,
            dryRun: dryRun,
          );
        default:
          body = DateFix(
            ids: widget.ids,
            action: DateFixActionEnum.useFile,
            dryRun: dryRun,
          );
      }
      return body == null ? Future.value(null) : api.fixDates(body);
    }
    LocationFix? body;
    switch (_placeAction) {
      case 'set':
        final lat = double.tryParse(_latitude.text.trim());
        final lon = double.tryParse(_longitude.text.trim());
        if (lat != null && lon != null) {
          body = LocationFix(
            ids: widget.ids,
            action: LocationFixActionEnum.set_,
            latitude: lat,
            longitude: lon,
            dryRun: dryRun,
          );
        }
      case 'fromNeighbours':
        body = LocationFix(
          ids: widget.ids,
          action: LocationFixActionEnum.fromNeighbours,
          minutes: _number(_near),
          dryRun: dryRun,
        );
      case 'fromTrack':
        if (_track != null) {
          body = LocationFix(
            ids: widget.ids,
            action: LocationFixActionEnum.fromTrack,
            track: _track,
            dryRun: dryRun,
          );
        }
      case 'clear':
        body = LocationFix(
          ids: widget.ids,
          action: LocationFixActionEnum.clear,
          dryRun: dryRun,
        );
      default:
        body = LocationFix(
          ids: widget.ids,
          action: LocationFixActionEnum.useFile,
          dryRun: dryRun,
        );
    }
    return body == null ? Future.value(null) : api.fixLocations(body);
  }

  /// The preview follows each change, a moment after typing stops.
  void _refresh() {
    _typing?.cancel();
    _typing = Timer(const Duration(milliseconds: 350), () async {
      try {
        final preview = await _send(true);
        if (mounted) {
          setState(() {
            _preview = preview;
            _problem = null;
          });
        }
      } on ApiException catch (cause) {
        if (mounted) {
          setState(() {
            _preview = null;
            _problem = cause.message;
          });
        }
      }
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final done = await _send(false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.fixSheetChanged(done?.changed ?? 0))),
      );
      Navigator.pop(context, true);
    } on ApiException catch (cause) {
      if (mounted) setState(() => _problem = cause.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: _setAt ?? now,
      firstDate: DateTime(1850),
      lastDate: now,
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _setAt ?? DateTime(day.year, day.month, day.day, 12),
      ),
    );
    if (time == null) return;
    setState(
      () => _setAt = DateTime(
        day.year,
        day.month,
        day.day,
        time.hour,
        time.minute,
      ),
    );
    _refresh();
  }

  Future<void> _pickTrack() async {
    final file = await FilePicker.pickFile();
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _track = utf8.decode(bytes, allowMalformed: true);
      _trackName = file.name;
    });
    _refresh();
  }

  Future<void> _findPlaces(String text) async {
    if (text.trim().length < 2) {
      setState(() => _places = const []);
      return;
    }
    try {
      final found = await widget.session.api.searchPlaces(text.trim());
      if (mounted) setState(() => _places = found?.places ?? const []);
    } on ApiException {
      // Coordinates can still be typed.
    }
  }

  Widget _number3(String label, TextEditingController field) => SizedBox(
    width: 84,
    child: TextField(
      controller: field,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onChanged: (_) => _refresh(),
    ),
  );

  Widget _choices(
    List<(String, String)> choices,
    String current,
    void Function(String) set,
  ) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final (value, label) in choices)
        ChoiceChip(
          label: Text(label),
          selected: current == value,
          onSelected: (_) {
            setState(() => set(value));
            _refresh();
          },
        ),
    ],
  );

  List<Widget> _dateFields(TextTheme text) => switch (_dateAction) {
    'shift' => [
      Text(l.fixSheetCameraClockWrong, style: text.bodySmall),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          DropdownButton<bool>(
            value: _later,
            items: [
              DropdownMenuItem(value: false, child: Text(l.fixSheetEarlier)),
              DropdownMenuItem(value: true, child: Text(l.fixSheetLater)),
            ],
            onChanged: (value) {
              setState(() => _later = value ?? false);
              _refresh();
            },
          ),
          _number3(l.fixSheetDays, _days),
          _number3(l.fixSheetHours, _hours),
          _number3(l.fixSheetMinutes, _minutes),
        ],
      ),
    ],
    'set' => [
      Text(l.fixSheetOneDateForAll, style: text.bodySmall),
      OutlinedButton(
        onPressed: _pickDate,
        child: Text(
          _setAt == null
              ? l.fixSheetChooseDateTime
              : withOffset(_setAt!).substring(0, 16).replaceFirst('T', ' '),
        ),
      ),
    ],
    'travel' => [
      Text(l.fixSheetTripHint, style: text.bodySmall),
      _zoneField(l.fixSheetCameraClockWasOn, _cameraZone),
      _zoneField(l.fixSheetTheyWereTakenIn, _placeZone),
    ],
    'zoneFromPlace' => [
      Text(l.fixSheetZoneFromPlaceHint, style: text.bodySmall),
    ],
    _ => [Text(l.fixSheetDatesByHandRemoved, style: text.bodySmall)],
  };

  Widget _zoneField(String label, TextEditingController field) =>
      Autocomplete<String>(
        initialValue: field.value,
        optionsBuilder: (typed) => commonZones.where(
          (zone) => zone.toLowerCase().contains(typed.text.toLowerCase()),
        ),
        onSelected: (zone) {
          field.text = zone;
          _refresh();
        },
        fieldViewBuilder: (context, controller, focus, _) => TextField(
          controller: controller,
          focusNode: focus,
          decoration: InputDecoration(labelText: label),
          onChanged: (value) {
            field.text = value;
            _refresh();
          },
        ),
      );

  List<Widget> _placeFields(TextTheme text) => switch (_placeAction) {
    'fromNeighbours' => [
      Text(l.fixSheetNeighboursHint, style: text.bodySmall),
      SizedBox(
        width: 180,
        child: _number3(l.fixSheetAtMostMinutesApart, _near),
      ),
    ],
    'fromTrack' => [
      Text(l.fixSheetTrackHint, style: text.bodySmall),
      OutlinedButton(
        onPressed: _pickTrack,
        child: Text(_trackName.isEmpty ? l.fixSheetChooseGpx : _trackName),
      ),
    ],
    'set' => [
      TextField(
        controller: _search,
        decoration: InputDecoration(labelText: l.fixSheetFindPlace),
        onChanged: _findPlaces,
      ),
      for (final place in _places.take(5))
        ListTile(
          dense: true,
          title: Text(
            [
              place.name,
              place.state,
              place.country,
            ].where((p) => p.isNotEmpty).join(', '),
          ),
          onTap: () {
            _latitude.text = '${place.latitude}';
            _longitude.text = '${place.longitude}';
            setState(() => _places = const []);
            _refresh();
          },
        ),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _latitude,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(labelText: l.fixSheetLatitude),
              onChanged: (_) => _refresh(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _longitude,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(labelText: l.fixSheetLongitude),
              onChanged: (_) => _refresh(),
            ),
          ),
        ],
      ),
    ],
    'clear' => [Text(l.fixSheetLocationGoes, style: text.bodySmall)],
    _ => [Text(l.fixSheetLocationsByHandRemoved, style: text.bodySmall)],
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final preview = _preview;
    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: widget.scroll,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                Text(
                  widget.dates
                      ? l.fixSheetDateTitle(widget.ids.length)
                      : l.fixSheetLocationTitle(widget.ids.length),
                  style: text.titleLarge,
                ),
                const SizedBox(height: 12),
                if (widget.dates)
                  _choices(
                    [
                      ('shift', l.fixSheetShift),
                      ('set', l.fixSheetSetDate),
                      ('zoneFromPlace', l.fixSheetZoneFromPlace),
                      ('travel', l.fixSheetTrip),
                      ('useFile', l.fixSheetFromFile),
                    ],
                    _dateAction,
                    (value) => _dateAction = value,
                  )
                else
                  _choices(
                    [
                      ('fromNeighbours', l.fixSheetFromNearby),
                      ('fromTrack', l.fixSheetFromTrack),
                      ('set', l.fixSheetSetPlace),
                      ('clear', l.fixSheetClearLocation),
                      ('useFile', l.fixSheetFromFile),
                    ],
                    _placeAction,
                    (value) => _placeAction = value,
                  ),
                const SizedBox(height: 12),
                // Room between a hint and the fields under it, whose labels float above them.
                for (final (index, field)
                    in (widget.dates ? _dateFields(text) : _placeFields(text))
                        .indexed) ...[
                  if (index > 0) const SizedBox(height: 12),
                  field,
                ],
                const Divider(height: 28),
                if (_problem != null)
                  Text(_problem!, style: TextStyle(color: Palette.err))
                else if (preview != null) ...[
                  Text(
                    '${l.fixSheetWillChange(preview.changed)}'
                    '${preview.skipped > 0 ? ' · ${l.fixSheetNothingToGoBy(preview.skipped)}' : ''}',
                    style: text.titleSmall,
                  ),
                  for (final change in preview.changes)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(change.name),
                      subtitle: Text(
                        '${change.before.isEmpty ? '—' : change.before} → '
                        '${change.after.isEmpty ? l.fixSheetNoLocation : change.after}',
                      ),
                    ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l.fixSheetCancel),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _busy || (preview?.changed ?? 0) == 0
                        ? null
                        : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: Palette.buttonGold,
                      foregroundColor: Palette.onGold,
                    ),
                    child: Text(l.fixSheetSave),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

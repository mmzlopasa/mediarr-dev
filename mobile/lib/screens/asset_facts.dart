import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mediarr_api/api.dart';

import '../services/session.dart';
import '../theme.dart';

String _two(int value) => value.toString().padLeft(2, '0');

/// A moment as the server takes it: the time on the clock where it was taken, and that place's offset.
String takenAtText(DateTime clock, int offsetMinutes) {
  final size = offsetMinutes.abs();
  final sign = offsetMinutes < 0 ? '-' : '+';
  return '${clock.year.toString().padLeft(4, '0')}-${_two(clock.month)}-${_two(clock.day)}'
      'T${_two(clock.hour)}:${_two(clock.minute)}:${_two(clock.second)}'
      '$sign${_two(size ~/ 60)}:${_two(size % 60)}';
}

/// Changes a photo's date, place and description. Its file stays as it is. True when something changed.
class AssetFactsDialog extends StatefulWidget {
  const AssetFactsDialog({
    super.key,
    required this.session,
    required this.detail,
  });

  final Session session;
  final AssetDetail detail;

  @override
  State<AssetFactsDialog> createState() => _AssetFactsDialogState();
}

class _AssetFactsDialogState extends State<AssetFactsDialog> {
  late final _latitude = TextEditingController(
    text: widget.detail.latitude?.toString() ?? '',
  );
  late final _longitude = TextEditingController(
    text: widget.detail.longitude?.toString() ?? '',
  );
  late final _caption = TextEditingController(
    text: widget.detail.caption ?? '',
  );
  final _search = TextEditingController();
  late final DateTime _before = DateTime.parse(widget.detail.localAt);
  late DateTime _when = _before;
  List<Place> _places = const [];

  @override
  void dispose() {
    _latitude.dispose();
    _longitude.dispose();
    _caption.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _find(String text) async {
    if (text.trim().length < 2) {
      setState(() => _places = const []);
      return;
    }
    try {
      final found = await widget.session.api.searchPlaces(text.trim());
      if (mounted) setState(() => _places = found?.places ?? const []);
    } on ApiException {
      if (mounted) setState(() => _places = const []);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(1800),
      lastDate: DateTime.now(),
      initialDate: _when,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (!mounted) return;
    setState(() {
      _when = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _when.hour,
        time?.minute ?? _when.minute,
      );
    });
  }

  Future<void> _send(AssetFacts facts) async {
    final navigator = Navigator.of(context);
    try {
      await widget.session.api.setAssetFacts(widget.detail.id, facts);
      navigator.pop(true);
    } on ApiException catch (cause) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not saved. ${cause.message ?? ''}')),
        );
      }
    }
  }

  void _save() {
    final latitude = double.tryParse(_latitude.text.trim());
    final longitude = double.tryParse(_longitude.text.trim());
    final located = latitude != null && longitude != null;
    final offset =
        widget.detail.offsetMinutes ?? _when.timeZoneOffset.inMinutes;
    unawaited(
      _send(
        AssetFacts(
          caption: _caption.text,
          takenAt: _when == _before ? null : takenAtText(_when, offset),
          latitude: located ? latitude : null,
          longitude: located ? longitude : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Edit details'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date and time'),
            subtitle: Text(
              takenAtText(_when, 0).substring(0, 16).replaceAll('T', ' '),
            ),
            trailing: const Icon(Icons.edit_calendar),
            onTap: _pickDate,
          ),
          TextField(
            controller: _search,
            decoration: const InputDecoration(labelText: 'Find a place'),
            onChanged: _find,
          ),
          for (final place in _places)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                [
                  place.name,
                  place.state,
                  place.country,
                ].where((part) => part.isNotEmpty).join(', '),
              ),
              onTap: () => setState(() {
                _latitude.text = '${place.latitude}';
                _longitude.text = '${place.longitude}';
                _search.text = place.name;
                _places = const [];
              }),
            ),
          TextField(
            controller: _latitude,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            decoration: const InputDecoration(labelText: 'Latitude'),
          ),
          TextField(
            controller: _longitude,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            decoration: const InputDecoration(labelText: 'Longitude'),
          ),
          TextField(
            controller: _caption,
            maxLength: 2000,
            maxLines: 3,
            minLines: 1,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          TextButton(
            onPressed: () => _send(AssetFacts(useFile: true)),
            child: const Text('Use what the file says'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(onPressed: _save, child: const Text('Save')),
    ],
  );
}

/// One to five stars. Choosing the stars it already has takes them away.
class RatingRow extends StatelessWidget {
  const RatingRow({super.key, required this.rating, required this.onRate});

  final int rating;
  final ValueChanged<int> onRate;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var stars = 1; stars <= 5; stars++)
        IconButton(
          tooltip: '$stars of 5 stars',
          isSelected: stars == rating,
          icon: Icon(
            stars <= rating ? Icons.star : Icons.star_border,
            color: stars <= rating ? Palette.gold : Palette.dim,
          ),
          onPressed: () => onRate(stars == rating ? 0 : stars),
        ),
    ],
  );
}

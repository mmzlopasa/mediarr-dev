import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mediarr_api/api.dart';

import '../services/session.dart';
import '../theme.dart';

const _cropSize = 48.0;
const _newPerson = 'new';
const _notAPerson = 'none';

/// The faces in a photo, and saying who they are. Only the owner's photos have any, so for anyone
/// else, and on a server too old to say, this shows nothing.
class FacesSection extends StatefulWidget {
  const FacesSection({super.key, required this.session, required this.assetId});

  final Session session;
  final String assetId;

  @override
  State<FacesSection> createState() => _FacesSectionState();
}

class _FacesSectionState extends State<FacesSection> {
  List<AssetFace> _faces = const [];
  List<Person> _people = const [];

  DefaultApi get _api => widget.session.api;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final response = await _api.listAssetFacesWithHttpInfo(widget.assetId);
      if (response.statusCode >= 400 || response.body.isEmpty) return;
      final found = AssetFaces.fromJson(jsonDecode(response.body));
      final known = await _api.listPeople();
      if (!mounted || found == null) return;
      setState(() {
        _faces = found.faces;
        _people = (known?.people ?? const <Person>[])
            .where((person) => person.name.isNotEmpty)
            .toList();
      });
    } on ApiException {
      // Details still show without the faces.
    }
  }

  Future<void> _attempt(Future<void> Function() change) async {
    try {
      await change();
      await _load();
    } on ApiException catch (cause) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('The action failed. ${cause.message ?? ''}')),
        );
      }
    }
  }

  Future<void> _nameNew(AssetFace face) async {
    final field = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New person'),
        content: TextField(controller: field, autofocus: true, maxLength: 100),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, field.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    field.dispose();
    if (name == null || name.isEmpty) return;
    await _attempt(() => _api.assignFace(face.id, FaceAssign(name: name)));
  }

  Future<void> _choose(AssetFace face, String choice) async {
    switch (choice) {
      case _newPerson:
        await _nameNew(face);
      case _notAPerson:
        await _attempt(() => _api.removeFace(face.id));
      default:
        await _attempt(
          () => _api.assignFace(face.id, FaceAssign(personId: choice)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_faces.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Text('People', style: text.titleMedium),
        for (final face in _faces)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: FaceCrop(
              session: widget.session,
              assetId: widget.assetId,
              face: face,
            ),
            title: Text(
              (face.person?.name ?? '').isEmpty ? 'No name' : face.person!.name,
            ),
            trailing: PopupMenuButton<String>(
              tooltip: 'Who this is',
              onSelected: (choice) => _choose(face, choice),
              itemBuilder: (_) => [
                for (final person in _people)
                  PopupMenuItem(value: person.id, child: Text(person.name)),
                const PopupMenuItem(
                  value: _newPerson,
                  child: Text('New person…'),
                ),
                const PopupMenuItem(
                  value: _notAPerson,
                  child: Text('Not a person'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Only the face, out of the whole picture.
class FaceCrop extends StatelessWidget {
  const FaceCrop({
    super.key,
    required this.session,
    required this.assetId,
    required this.face,
  });

  final Session session;
  final String assetId;
  final AssetFace face;

  @override
  Widget build(BuildContext context) {
    final across = _cropSize / (face.x2 - face.x1).clamp(0.01, 1.0);
    final down = _cropSize / (face.y2 - face.y1).clamp(0.01, 1.0);
    return ClipOval(
      child: SizedBox.square(
        dimension: _cropSize,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: -face.x1 * across,
              top: -face.y1 * down,
              width: across,
              height: down,
              child: Image.network(
                '${session.serverUrl}/api/assets/$assetId/thumbnail?size=large',
                headers: session.headers,
                fit: BoxFit.fill,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.person_outline, color: Palette.dim),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

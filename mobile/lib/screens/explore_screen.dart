import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../l10n/l10n.dart';
import '../services/session.dart';
import '../theme.dart';
import 'asset_picture.dart';
import 'memories_screen.dart';
import 'people_screens.dart';

const _peopleShown = 12;
const _coverSize = 112.0;

/// People, places and memories together. Each part stands alone, so one that cannot be read leaves
/// the others in place.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  List<Person>? _people;
  List<ExplorePlace>? _places;
  List<Memory>? _memories;
  bool _peopleFailed = false;
  bool _placesFailed = false;
  bool _memoriesFailed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPeople());
    unawaited(_loadPlaces());
    unawaited(_loadMemories());
  }

  Future<void> _loadPeople() async {
    try {
      final list = await _session.api.listPeople();
      if (!mounted) return;
      final named =
          (list?.people ?? const <Person>[])
              .where((person) => !person.hidden && person.name.isNotEmpty)
              .toList()
            ..sort((a, b) => b.assetCount.compareTo(a.assetCount));
      setState(() => _people = named.take(_peopleShown).toList());
    } on ApiException {
      if (mounted) setState(() => _peopleFailed = true);
    }
  }

  Future<void> _loadPlaces() async {
    try {
      final response = await _session.api.listExplorePlacesWithHttpInfo();
      if (!mounted) return;
      if (response.statusCode >= 400 || response.body.isEmpty) {
        setState(() => _placesFailed = true);
        return;
      }
      final list = ExplorePlaces.fromJson(jsonDecode(response.body));
      setState(() => _places = list?.places ?? const []);
    } on ApiException {
      if (mounted) setState(() => _placesFailed = true);
    }
  }

  Future<void> _loadMemories() async {
    try {
      final list = await _session.api.listMemories(
        date: localToday(DateTime.now()),
      );
      if (mounted) setState(() => _memories = list ?? const []);
    } on ApiException {
      if (mounted) setState(() => _memoriesFailed = true);
    }
  }

  void _open(Widget screen) => unawaited(
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen)),
  );

  Widget _cover(Widget picture, String title, String meta, VoidCallback onTap) {
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _coverSize,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox.square(dimension: _coverSize, child: picture),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodyMedium,
            ),
            Text(
              meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _part(
    String title, {
    required String all,
    required bool failed,
    required String failure,
    required bool loading,
    required String empty,
    required List<Widget> covers,
    required VoidCallback onAll,
  }) {
    final Widget body;
    if (failed) {
      body = Text(failure);
    } else if (loading) {
      body = SizedBox(
        height: _coverSize,
        child: Center(child: CircularProgressIndicator(color: Palette.gold)),
      );
    } else if (covers.isEmpty) {
      body = Text(empty);
    } else {
      body = SizedBox(
        height: _coverSize + 52,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: covers.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, index) => covers[index],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: all,
                icon: const Icon(Icons.chevron_right),
                onPressed: onAll,
              ),
            ],
          ),
          const SizedBox(height: 6),
          body,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final broken = Icon(Icons.broken_image_outlined, color: Palette.dim);
    return Scaffold(
      appBar: AppBar(title: Text(l.exploreScreenExplore)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 40),
        children: [
          _part(
            l.exploreScreenPeople,
            all: l.exploreScreenAllPeople,
            failed: _peopleFailed,
            failure: l.exploreScreenPeopleFailed,
            loading: _people == null,
            empty: l.exploreScreenNoNamedPeople,
            onAll: () => _open(const PeopleScreen()),
            covers: [
              for (final person in _people ?? const <Person>[])
                _cover(
                  Image.network(
                    '${_session.serverUrl}/api/people/${person.id}/thumbnail',
                    headers: _session.headers,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => broken,
                  ),
                  person.name,
                  '${person.assetCount}',
                  () => _open(const PeopleScreen()),
                ),
            ],
          ),
          _part(
            l.exploreScreenPlaces,
            all: l.exploreScreenAllPlaces,
            failed: _placesFailed,
            failure: l.exploreScreenPlacesFailed,
            loading: _places == null,
            empty: l.exploreScreenNoPlaces,
            onAll: () => _open(const SearchScreen()),
            covers: [
              for (final place in _places ?? const <ExplorePlace>[])
                _cover(
                  AssetPicture(
                    session: _session,
                    id: place.coverId,
                    fit: BoxFit.cover,
                    error: broken,
                  ),
                  place.name,
                  '${place.country} · ${place.assetCount}',
                  () => _open(SearchScreen(initialQuery: place.name)),
                ),
            ],
          ),
          _part(
            l.exploreScreenMemories,
            all: l.exploreScreenAllMemories,
            failed: _memoriesFailed,
            failure: l.exploreScreenMemoriesFailed,
            loading: _memories == null,
            empty: l.exploreScreenNoMemories,
            onAll: () => _open(const MemoriesScreen()),
            covers: [
              for (final memory in _memories ?? const <Memory>[])
                if (memory.items.isNotEmpty)
                  _cover(
                    AssetPicture(
                      session: _session,
                      id: memory.items.first.id,
                      fit: BoxFit.cover,
                      error: broken,
                    ),
                    memory.title,
                    '${memory.items.length}',
                    () => _open(const MemoriesScreen()),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

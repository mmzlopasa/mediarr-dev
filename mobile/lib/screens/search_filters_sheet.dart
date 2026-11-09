import 'package:flutter/material.dart';
import 'package:mediarr_api/api.dart';

import '../services/search_query.dart';
import '../services/session.dart';
import '../theme.dart';
import '../l10n/l10n.dart';

String _day(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

/// Every filter of a search, to choose from what this library has, in a sheet from the bottom.
Future<SearchQuery?> showSearchFilters(
  BuildContext context,
  Session session,
  SearchQuery start,
) => showModalBottomSheet<SearchQuery>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.85,
    maxChildSize: 0.95,
    builder: (context, scroll) =>
        _FilterSheet(session: session, start: start, scroll: scroll),
  ),
);

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.session,
    required this.start,
    required this.scroll,
  });

  final Session session;
  final SearchQuery start;
  final ScrollController scroll;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late SearchQuery _q = widget.start;
  SearchOptions? _options;
  List<Person> _people = const [];
  List<Album> _albums = const [];

  @override
  void initState() {
    super.initState();
    final api = widget.session.api;
    api.getSearchOptions().then((found) {
      if (mounted) setState(() => _options = found);
    }, onError: (Object _) {});
    api.listPeople().then((found) {
      if (mounted) {
        setState(
          () => _people = [
            for (final person in found?.people ?? const <Person>[])
              if (person.name.isNotEmpty && !person.hidden) person,
          ],
        );
      }
    }, onError: (Object _) {});
    api.listAlbums(sort: 'title').then((found) {
      if (mounted) setState(() => _albums = found ?? const []);
    }, onError: (Object _) {});
  }

  Future<void> _pickDay(bool start) async {
    final current = start ? _q.from : _q.to;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(current ?? '') ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked == null) return;
    setState(
      () => _q = start
          ? _q.copyWith(from: () => _day(picked))
          : _q.copyWith(to: () => _day(picked)),
    );
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );

  Widget _suggest(
    String label,
    String? value,
    List<String> choices,
    void Function(String?) set,
  ) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Autocomplete<String>(
      initialValue: TextEditingValue(text: value ?? ''),
      optionsBuilder: (typed) => choices.where(
        (choice) => choice.toLowerCase().contains(typed.text.toLowerCase()),
      ),
      onSelected: set,
      fieldViewBuilder: (context, controller, focus, submit) => TextField(
        controller: controller,
        focusNode: focus,
        decoration: InputDecoration(labelText: label),
        onChanged: (text) => set(text.trim().isEmpty ? null : text.trim()),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final options = _options;
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
                  l.searchFiltersSheetFilters,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                _heading(l.searchFiltersSheetDate),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDay(true),
                        child: Text(_q.from ?? l.searchFiltersSheetFrom),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('–'),
                    ),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDay(false),
                        child: Text(_q.to ?? l.searchFiltersSheetTo),
                      ),
                    ),
                  ],
                ),
                _heading(l.searchFiltersSheetType),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: '',
                      label: Text(l.searchFiltersSheetAll),
                    ),
                    ButtonSegment(
                      value: 'photo',
                      label: Text(l.searchFiltersSheetPhotos),
                    ),
                    ButtonSegment(
                      value: 'video',
                      label: Text(l.searchFiltersSheetVideos),
                    ),
                  ],
                  selected: {_q.type ?? ''},
                  onSelectionChanged: (choice) => setState(
                    () => _q = _q.copyWith(
                      type: () => choice.first.isEmpty ? null : choice.first,
                    ),
                  ),
                ),
                if (_people.isNotEmpty) ...[
                  _heading(l.searchFiltersSheetPeople),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final person in _people)
                        FilterChip(
                          label: Text(person.name),
                          selected: _q.people.contains(person.id),
                          onSelected: (on) => setState(
                            () => _q = _q.copyWith(
                              people: on
                                  ? [..._q.people, person.id]
                                  : [
                                      for (final id in _q.people)
                                        if (id != person.id) id,
                                    ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (_q.people.length > 1)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.searchFiltersSheetAnyOfThem),
                      value: _q.anyPerson,
                      onChanged: (on) =>
                          setState(() => _q = _q.copyWith(anyPerson: on)),
                    ),
                ],
                _heading(l.searchFiltersSheetWhereAndWith),
                _suggest(
                  l.searchFiltersSheetPlace,
                  _q.place,
                  options?.places ?? const [],
                  (value) => _q = _q.copyWith(place: () => value),
                ),
                _suggest(
                  l.searchFiltersSheetCamera,
                  _q.camera,
                  options?.cameras ?? const [],
                  (value) => _q = _q.copyWith(camera: () => value),
                ),
                _suggest(
                  l.searchFiltersSheetLens,
                  _q.lens,
                  options?.lenses ?? const [],
                  (value) => _q = _q.copyWith(lens: () => value),
                ),
                _heading(l.searchFiltersSheetRating),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final stars in [0, 1, 2, 3, 4, 5])
                      ChoiceChip(
                        label: Text(
                          stars == 0
                              ? l.searchFiltersSheetAnyRating
                              : '${'★' * stars}+',
                        ),
                        selected: (_q.minRating ?? 0) == stars,
                        onSelected: (_) => setState(
                          () => _q = _q.copyWith(
                            minRating: () => stars == 0 ? null : stars,
                          ),
                        ),
                      ),
                  ],
                ),
                if ((options?.tags ?? const []).isNotEmpty) ...[
                  _heading(l.searchFiltersSheetTags),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in options!.tags)
                        FilterChip(
                          label: Text('#$tag'),
                          selected: _q.tags.contains(tag.toLowerCase()),
                          onSelected: (on) => setState(
                            () => _q = _q.copyWith(
                              tags: on
                                  ? [..._q.tags, tag.toLowerCase()]
                                  : [
                                      for (final t in _q.tags)
                                        if (t != tag.toLowerCase()) t,
                                    ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                _heading(l.searchFiltersSheetAlbum),
                DropdownButtonFormField<String>(
                  initialValue: _q.notInAlbum ? 'none' : (_q.album ?? ''),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text(l.searchFiltersSheetAnyAlbum),
                    ),
                    DropdownMenuItem(
                      value: 'none',
                      child: Text(l.searchFiltersSheetInNoAlbum),
                    ),
                    for (final album in _albums)
                      DropdownMenuItem(
                        value: album.id,
                        child: Text(album.title),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    final title = _albums
                        .where((album) => album.id == value)
                        .map((album) => album.title)
                        .firstOrNull;
                    _q = _q.copyWith(
                      notInAlbum: value == 'none',
                      album: () =>
                          value == null || value.isEmpty || value == 'none'
                          ? null
                          : value,
                      albumTitle: () => title,
                    );
                  }),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.searchFiltersSheetFavouritesOnly),
                  value: _q.favorite,
                  onChanged: (on) =>
                      setState(() => _q = _q.copyWith(favorite: on)),
                ),
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
                    onPressed: () => Navigator.pop(
                      context,
                      SearchQuery(words: widget.start.words),
                    ),
                    child: Text(l.searchFiltersSheetClear),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, _q),
                    style: FilledButton.styleFrom(
                      backgroundColor: Palette.buttonGold,
                      foregroundColor: Palette.onGold,
                    ),
                    child: Text(l.searchFiltersSheetApply),
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

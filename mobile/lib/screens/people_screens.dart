import '../motion.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../l10n/l10n.dart';
import '../services/dispose_later.dart';
import '../services/search_query.dart';
import '../services/session.dart';
import '../services/timeline.dart';
import '../theme.dart';
import 'album_sheets.dart';
import 'asset_picture.dart';
import 'search_filters_sheet.dart';
import 'timeline_screen.dart';
import 'viewer_screen.dart';

String get _noName => l.peopleScreensNoName;

void _tell(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)
      ?.showSnackBar(SnackBar(content: Text(message)));
}

/// A day as shown on a chip.
String _dayLabel(DateTime value) =>
    '${value.day}.${value.month}.${value.year}.';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({
    super.key,
    this.initialQuery,
    this.albumId,
    this.albumTitle,
  });

  /// What to look for at once, when arriving from a place.
  final String? initialQuery;

  /// Only in this album, when arriving from one.
  final String? albumId;
  final String? albumTitle;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  final _query = TextEditingController();
  late SearchQuery _q = SearchQuery(
    album: widget.albumId,
    albumTitle: widget.albumTitle,
  );
  SearchResult? _result;
  bool _busy = false;
  bool _failed = false;
  bool _askOn = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// Searches what is typed, with the filters chosen. New words are read for filters again.
  Future<void> _search({bool fresh = true}) async {
    _q = _q.copyWith(words: _query.text.trim(), plain: fresh ? false : null);
    if (_q.isEmpty) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final result = await _q.run(_session.api);
      if (mounted) setState(() => _result = result);
    } on ApiException {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final first = widget.initialQuery;
    if (first != null) _query.text = first;
    if (first != null || widget.albumId != null) unawaited(_search());
    _session.api.getFeatures().then((features) {
      if (mounted) {
        setState(() => _askOn = features?['descriptions'] ?? false);
      }
    }, onError: (Object _) {});
  }

  /// A model on a machine with no graphics card can take a while. If it fails, the question itself
  /// is searched.
  Future<void> _ask() async {
    final question = _query.text.trim();
    if (question.isEmpty) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final answer = await _session.api.askSearch(
        AskRequest(question: question),
      );
      if (answer != null && answer.query.isNotEmpty && mounted) {
        _query.text = answer.query;
      }
    } on ApiException {
      // The search below still runs, with the question as it is.
    }
    await _search();
  }

  void _open(int index) {
    final store = TimelineStore.fixed(_session, _result!.items);
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) =>
                ViewerScreen(initialIndex: index, store: store, readOnly: true),
          ),
        )
        .then((_) => store.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final text = Theme.of(context).textTheme;
    Widget body;
    if (_busy) {
      body = Center(child: CircularProgressIndicator(color: Palette.gold));
    } else if (_failed) {
      body = EmptyMessage(
        icon: Icons.cloud_off,
        text: l.peopleScreensSearchFailed,
      );
    } else if (result == null) {
      body = EmptyMessage(icon: Icons.search, text: l.peopleScreensDescribe);
    } else {
      final chips = chipsFor(result.filters, _q, _dayLabel);
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!result.smart)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                l.peopleScreensSmartOff,
                style: text.bodySmall?.copyWith(color: Palette.warn),
              ),
            ),
          if (chips.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final chip in chips)
                    InputChip(
                      label: Text(chip.label),
                      // Found in the words: outlined, to tell it from a chosen one.
                      backgroundColor: chip.found ? Colors.transparent : null,
                      side: chip.found
                          ? BorderSide(color: Palette.gold)
                          : BorderSide.none,
                      deleteButtonTooltipMessage: l.peopleScreensRemoveChip(
                        chip.label,
                      ),
                      onDeleted: () {
                        _q = withoutChip(_q, chip, result.filters);
                        if (_q.isEmpty) {
                          setState(() => _result = null);
                          return;
                        }
                        unawaited(_search(fresh: false));
                      },
                    ),
                ],
              ),
            ),
          Expanded(
            child: result.items.isEmpty
                ? EmptyMessage(
                    icon: Icons.search_off,
                    text: l.peopleScreensNothingFound,
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 130,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                    itemCount: result.items.length,
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => _open(index),
                      child: AssetPicture(
                        session: _session,
                        id: result.items[index].id,
                        fit: BoxFit.cover,
                        error: Icon(
                          Icons.broken_image_outlined,
                          color: Palette.dim,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _query,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l.peopleScreensSearchHint,
            border: InputBorder.none,
          ),
          onSubmitted: (_) => _search(),
        ),
        actions: [
          if (_askOn)
            IconButton(
              tooltip: l.peopleScreensAsk,
              icon: const Icon(Icons.auto_awesome_outlined),
              onPressed: _busy ? null : _ask,
            ),
          IconButton(
            tooltip: l.peopleScreensFilters,
            icon: Badge(
              isLabelVisible: _q.chosen > 0,
              label: Text('${_q.chosen}'),
              child: const Icon(Icons.tune),
            ),
            onPressed: () async {
              final next = await showSearchFilters(context, _session, _q);
              if (next == null) return;
              _q = next;
              if (_q.copyWith(words: _query.text.trim()).isEmpty) {
                setState(() => _result = null);
                return;
              }
              unawaited(_search(fresh: false));
            },
          ),
          IconButton(
            tooltip: l.peopleScreensSearch,
            icon: const Icon(Icons.search),
            onPressed: _search,
          ),
        ],
      ),
      body: body,
    );
  }
}

class _PersonPicture extends StatelessWidget {
  const _PersonPicture({required this.session, required this.id});

  final Session session;
  final String id;

  @override
  Widget build(BuildContext context) => Image.network(
    '${session.serverUrl}/api/people/$id/thumbnail',
    headers: session.headers,
    fit: BoxFit.cover,
    errorBuilder: (_, _, _) => Icon(Icons.person_outline, color: Palette.dim),
  );
}

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  PeopleList? _list;
  bool _failed = false;
  bool _showHidden = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await _session.api.listPeople();
      if (mounted) {
        setState(() {
          _list = list;
          _failed = false;
        });
      }
    } on ApiException {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;
    final text = Theme.of(context).textTheme;
    final hidden = (list?.people ?? const <Person>[]).where((p) => p.hidden);
    final shown = (list?.people ?? const <Person>[])
        .where((p) => p.hidden == _showHidden)
        .toList();
    Widget body;
    if (list == null) {
      body = _failed
          ? EmptyMessage(icon: Icons.cloud_off, text: l.peopleScreensLoadFailed)
          : Center(child: CircularProgressIndicator(color: Palette.gold));
    } else if (!list.enabled && list.people.isEmpty) {
      body = EmptyMessage(
        icon: Icons.people_outline,
        text: l.peopleScreensFacesOff,
      );
    } else if (shown.isEmpty) {
      body = EmptyMessage(
        icon: Icons.people_outline,
        text: l.peopleScreensNoneYet,
      );
    } else {
      body = GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 150,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemCount: shown.length,
        itemBuilder: (context, index) {
          final person = shown[index];
          return Rise(
            id: 'person ${person.id}',
            index: index,
            child: GestureDetector(
              onTap: () => Navigator.of(context)
                  .push(
                    MaterialPageRoute<void>(
                      builder: (_) => _PersonScreen(person: person),
                    ),
                  )
                  .then((_) => _load()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox.expand(
                        child: _PersonPicture(session: _session, id: person.id),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    person.name.isEmpty ? _noName : person.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${person.assetCount}',
                    style: text.bodySmall?.copyWith(color: Palette.dim),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l.peopleScreensPeople),
        actions: [
          if (hidden.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _showHidden = !_showHidden),
              child: Text(
                _showHidden
                    ? l.peopleScreensShowOthers
                    : l.peopleScreensHiddenPeople,
              ),
            ),
        ],
      ),
      body: body,
    );
  }
}

class _PersonScreen extends ConsumerStatefulWidget {
  const _PersonScreen({required this.person});

  final Person person;

  @override
  ConsumerState<_PersonScreen> createState() => _PersonScreenState();
}

class _PersonScreenState extends ConsumerState<_PersonScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  late final _store = TimelineStore.person(_session, widget.person.id);
  late String _name = widget.person.name;
  late bool _hidden = widget.person.hidden;
  late String? _birthDate = widget.person.birthDate;
  final _selected = <String>{};

  @override
  void initState() {
    super.initState();
    _store.refresh();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  Future<void> _rename() async {
    final field = TextEditingController(text: _name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.peopleScreensName),
        content: TextField(controller: field, autofocus: true, maxLength: 100),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.albumScreenCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, field.text.trim()),
            child: Text(l.albumScreenSave),
          ),
        ],
      ),
    );
    disposeLater([field]);
    if (name == null) return;
    try {
      await _session.api.updatePerson(
        widget.person.id,
        PersonUpdate(name: name),
      );
      if (mounted) setState(() => _name = name);
    } on ApiException catch (cause) {
      if (mounted) {
        _tell(context, l.albumScreenActionFailed(cause.message ?? ''));
      }
    }
  }

  Future<void> _setBirthDate() async {
    final now = DateTime.now();
    final known = DateTime.tryParse(_birthDate ?? '');
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1880),
      lastDate: now,
      initialDate: known ?? DateTime(now.year - 30),
      helpText: l.peopleScreensDateOfBirth,
    );
    if (picked == null) return;
    final date = picked.toIso8601String().substring(0, 10);
    try {
      await _session.api.updatePerson(
        widget.person.id,
        PersonUpdate(birthDate: date),
      );
      if (mounted) setState(() => _birthDate = date);
    } on ApiException catch (cause) {
      if (mounted) {
        _tell(context, l.albumScreenActionFailed(cause.message ?? ''));
      }
    }
  }

  Future<void> _setHidden(bool hidden) async {
    final navigator = Navigator.of(context);
    try {
      await _session.api.updatePerson(
        widget.person.id,
        PersonUpdate(hidden: hidden),
      );
      if (hidden) {
        navigator.pop();
      } else if (mounted) {
        setState(() => _hidden = false);
      }
    } on ApiException catch (cause) {
      if (mounted) {
        _tell(context, l.albumScreenActionFailed(cause.message ?? ''));
      }
    }
  }

  Future<void> _merge() async {
    final list = await _session.api.listPeople();
    if (!mounted) return;
    final others = (list?.people ?? const <Person>[])
        .where((person) => person.id != widget.person.id)
        .toList();
    final chosen = await showModalBottomSheet<Person>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SheetFrame(
        title: l.peopleScreensMergeWith,
        children: [
          if (others.isEmpty) Text(l.peopleScreensNobodyElse),
          for (final person in others)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(person.name.isEmpty ? _noName : person.name),
              trailing: Text('${person.assetCount}'),
              onTap: () => Navigator.pop(context, person),
            ),
        ],
      ),
    );
    if (chosen == null) return;
    try {
      await _session.api.mergePeople(
        widget.person.id,
        AssetIds(ids: [chosen.id]),
      );
      await _store.refresh(reloadLoaded: true);
      if (mounted) _tell(context, l.peopleScreensMerged);
    } on ApiException catch (cause) {
      if (mounted) {
        _tell(context, l.albumScreenActionFailed(cause.message ?? ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_name.isEmpty ? _noName : _name),
      actions: [
        PopupMenuButton<String>(
          tooltip: l.albumScreenMore,
          onSelected: (choice) => switch (choice) {
            'name' => _rename(),
            'born' => _setBirthDate(),
            'merge' => _merge(),
            'show' => _setHidden(false),
            _ => _setHidden(true),
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'name', child: Text(l.peopleScreensName)),
            PopupMenuItem(
              value: 'born',
              child: Text(
                _birthDate == null
                    ? l.peopleScreensDateOfBirth
                    : l.peopleScreensBorn(_birthDate!),
              ),
            ),
            PopupMenuItem(
              value: 'merge',
              child: Text(l.peopleScreensMergeWith),
            ),
            PopupMenuItem(
              value: _hidden ? 'show' : 'hide',
              child: Text(_hidden ? l.peopleScreensShow : l.peopleScreensHide),
            ),
          ],
        ),
      ],
    ),
    body: ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final months = _store.months;
        if (months == null) {
          return _store.failed
              ? EmptyMessage(
                  icon: Icons.cloud_off,
                  text: l.peopleScreensThisLoadFailed,
                )
              : Center(child: CircularProgressIndicator(color: Palette.gold));
        }
        if (months.isEmpty) {
          return EmptyMessage(
            icon: Icons.photo_outlined,
            text: l.albumScreenNoPhotosYet,
          );
        }
        return TimelineGrid(
          store: _store,
          session: _session,
          selected: _selected,
          onToggle: (_) {},
          onOpen: (index) => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ViewerScreen(initialIndex: index, store: _store),
            ),
          ),
        );
      },
    ),
  );
}

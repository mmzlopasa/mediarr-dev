import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediarr_api/api.dart';

import '../services/session.dart';
import '../services/timeline.dart';
import '../theme.dart';
import 'album_sheets.dart';
import 'asset_picture.dart';
import 'timeline_screen.dart';
import 'viewer_screen.dart';

const _noName = 'No name';

void _tell(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)
      ?.showSnackBar(SnackBar(content: Text(message)));
}

/// What the server took from a query as filters, so that a wrong guess can be seen.
List<String> filterLabels(SearchFilters filters) {
  String day(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  return [
    if (filters.from != null && filters.to != null)
      '${day(filters.from!)} – ${day(filters.to!)}',
    ?filters.person,
    ?filters.place,
    ?filters.camera,
  ];
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final Session _session = ref.read(sessionProvider).value!;
  final _query = TextEditingController();
  SearchResult? _result;
  bool _busy = false;
  bool _failed = false;
  bool _askOn = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _query.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final result = await _session.api.searchAssets(query);
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
      body = const EmptyMessage(
        icon: Icons.cloud_off,
        text: 'The search failed. Check the connection.',
      );
    } else if (result == null) {
      body = const EmptyMessage(
        icon: Icons.search,
        text: 'Describe what you are looking for, in English or Croatian.',
      );
    } else {
      final labels = filterLabels(result.filters);
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!result.smart)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Smart search is off or not available, so only text on pictures, '
                'file names and filters are searched.',
                style: text.bodySmall?.copyWith(color: Palette.warn),
              ),
            ),
          if (labels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Wrap(
                spacing: 6,
                children: [
                  for (final label in labels) Chip(label: Text(label)),
                ],
              ),
            ),
          Expanded(
            child: result.items.isEmpty
                ? const EmptyMessage(
                    icon: Icons.search_off,
                    text: 'Nothing was found.',
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
          decoration: const InputDecoration(
            hintText: 'dog on a beach, Hvar 2024, receipt…',
            border: InputBorder.none,
          ),
          onSubmitted: (_) => _search(),
        ),
        actions: [
          if (_askOn)
            IconButton(
              tooltip: 'Ask',
              icon: const Icon(Icons.auto_awesome_outlined),
              onPressed: _busy ? null : _ask,
            ),
          IconButton(
            tooltip: 'Search',
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
          ? const EmptyMessage(
              icon: Icons.cloud_off,
              text: 'People could not be loaded. Check the connection.',
            )
          : Center(child: CircularProgressIndicator(color: Palette.gold));
    } else if (!list.enabled && list.people.isEmpty) {
      body = const EmptyMessage(
        icon: Icons.people_outline,
        text: 'Face recognition is not turned on for this server.',
      );
    } else if (shown.isEmpty) {
      body = const EmptyMessage(
        icon: Icons.people_outline,
        text: 'No people recognised yet.',
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
          return GestureDetector(
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
          );
        },
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('People'),
        actions: [
          if (hidden.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _showHidden = !_showHidden),
              child: Text(_showHidden ? 'Show the others' : 'Hidden people'),
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
        title: const Text('Name'),
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
    if (name == null) return;
    try {
      await _session.api.updatePerson(
        widget.person.id,
        PersonUpdate(name: name),
      );
      if (mounted) setState(() => _name = name);
    } on ApiException catch (cause) {
      if (mounted) _tell(context, 'The action failed. ${cause.message ?? ''}');
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
      if (mounted) _tell(context, 'The action failed. ${cause.message ?? ''}');
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
        title: 'Merge with…',
        children: [
          if (others.isEmpty) const Text('There is nobody else.'),
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
      if (mounted) _tell(context, 'Merged.');
    } on ApiException catch (cause) {
      if (mounted) _tell(context, 'The action failed. ${cause.message ?? ''}');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_name.isEmpty ? _noName : _name),
      actions: [
        PopupMenuButton<String>(
          tooltip: 'More',
          onSelected: (choice) => switch (choice) {
            'name' => _rename(),
            'merge' => _merge(),
            'show' => _setHidden(false),
            _ => _setHidden(true),
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'name', child: Text('Name')),
            const PopupMenuItem(value: 'merge', child: Text('Merge with…')),
            PopupMenuItem(
              value: _hidden ? 'show' : 'hide',
              child: Text(_hidden ? 'Show' : 'Hide'),
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
              ? const EmptyMessage(
                  icon: Icons.cloud_off,
                  text: 'This could not be loaded. Check the connection.',
                )
              : Center(child: CircularProgressIndicator(color: Palette.gold));
        }
        if (months.isEmpty) {
          return const EmptyMessage(
            icon: Icons.photo_outlined,
            text: 'No photos yet.',
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

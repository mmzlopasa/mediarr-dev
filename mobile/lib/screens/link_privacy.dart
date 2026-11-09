import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediarr_api/api.dart';

import '../l10n/l10n.dart';
import '../services/session.dart';
import '../theme.dart';

/// How private a public link is: whose faces are blurred, and what the files tell about themselves.
class LinkPrivacyChoice {
  const LinkPrivacyChoice({
    this.hideFaces = HideFaces.none,
    this.visiblePeople = const [],
    this.stripCamera = true,
    this.stripDate = false,
    this.askName = false,
  });

  /// What a link has now. A link from before these options removed nothing.
  factory LinkPrivacyChoice.of(ShareLink link) => LinkPrivacyChoice(
    hideFaces: link.hideFaces ?? HideFaces.none,
    visiblePeople: List.of(link.visiblePeople),
    stripCamera: link.stripCamera ?? false,
    stripDate: link.stripDate ?? false,
    askName: link.askName ?? false,
  );

  final HideFaces hideFaces;

  /// The people whose faces stay visible when every other face is hidden.
  final List<String> visiblePeople;
  final bool stripCamera;
  final bool stripDate;
  final bool askName;

  LinkPrivacyChoice copyWith({
    HideFaces? hideFaces,
    List<String>? visiblePeople,
    bool? stripCamera,
    bool? stripDate,
    bool? askName,
  }) => LinkPrivacyChoice(
    hideFaces: hideFaces ?? this.hideFaces,
    visiblePeople: visiblePeople ?? this.visiblePeople,
    stripCamera: stripCamera ?? this.stripCamera,
    stripDate: stripDate ?? this.stripDate,
    askName: askName ?? this.askName,
  );

  /// The same choice with a person's face shown, or hidden again.
  LinkPrivacyChoice togglePerson(String id) => copyWith(
    visiblePeople: visiblePeople.contains(id)
        ? [
            for (final person in visiblePeople)
              if (person != id) person,
          ]
        : [...visiblePeople, id],
  );

  /// The people only count when everyone but them is hidden.
  List<String> get sentPeople =>
      hideFaces == HideFaces.except ? visiblePeople : const [];

  /// The change for a link that exists, which keeps its location setting as it is.
  LinkPrivacy toUpdate({required bool showLocation}) => LinkPrivacy(
    showLocation: showLocation,
    hideFaces: hideFaces,
    visiblePeople: sentPeople,
    stripCamera: stripCamera,
    // The date can only go with the camera details.
    stripDate: stripCamera && stripDate,
    askName: askName,
  );
}

/// The date and time of a visit, in the chosen language.
String visitTime(DateTime at) {
  final local = at.toLocal();
  try {
    return DateFormat.yMMMd(l.localeName).add_Hm().format(local);
  } on Object {
    // The language's dates are not loaded (as in a test): numbers say it too.
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

/// How often a link was opened, and when last.
String linkOpenedLine(ShareLink link) {
  final visits = link.visits ?? 0;
  final last = link.lastVisitAt;
  if (visits == 0 || last == null) return l.linkPrivacyNotOpened;
  return l.linkPrivacyOpened(visits, visitTime(last));
}

/// The rough place a visit came from, from its address. Nothing is guessed when it is not known.
String visitPlace(LinkVisit visit) {
  final parts = [
    for (final part in [visit.city, visit.country])
      if (part != null && part.trim().isNotEmpty) part.trim(),
  ];
  return parts.isEmpty ? l.linkPrivacyUnknownPlace : parts.join(', ');
}

/// What a visitor looked at and took.
String visitActivity(LinkVisit visit) => [
  l.linkPrivacyViewed('${visit.viewed}'),
  l.linkPrivacyDownloaded('${visit.downloaded}'),
].join(' · ');

/// What hiding faces does not cover in this album, so nobody relies on it more than it deserves.
List<String> albumPrivacyFacts(AlbumPrivacy privacy) => [
  if (privacy.unchecked > 0)
    l.linkPrivacyUnchecked('${privacy.unchecked}', '${privacy.photos}')
  else if (privacy.photos > 0)
    l.linkPrivacyAllChecked,
  l.linkPrivacyUnrecognized,
  if (privacy.videos > 0) l.linkPrivacyVideosStill('${privacy.videos}'),
  l.linkPrivacyNoOriginals,
];

/// A grey line where text will be, while it loads.
class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({this.widthFactor = 1});

  final double widthFactor;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    alignment: Alignment.centerLeft,
    widthFactor: widthFactor,
    child: Container(
      height: 12,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Palette.bg3,
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}

/// The privacy options of a link, for a new link and for one that exists.
class LinkPrivacyFields extends StatefulWidget {
  const LinkPrivacyFields({
    super.key,
    required this.session,
    required this.albumId,
    required this.value,
    required this.onChanged,
  });

  final Session session;
  final String albumId;
  final LinkPrivacyChoice value;
  final ValueChanged<LinkPrivacyChoice> onChanged;

  @override
  State<LinkPrivacyFields> createState() => _LinkPrivacyFieldsState();
}

class _LinkPrivacyFieldsState extends State<LinkPrivacyFields> {
  AlbumPrivacy? _facts;
  bool _factsFailed = false;
  List<Person>? _people;
  bool _peopleFailed = false;

  @override
  void initState() {
    super.initState();
    if (widget.value.hideFaces != HideFaces.none) unawaited(_loadFacts());
    if (widget.value.hideFaces == HideFaces.except) unawaited(_loadPeople());
  }

  @override
  void didUpdateWidget(LinkPrivacyFields old) {
    super.didUpdateWidget(old);
    final hide = widget.value.hideFaces;
    if (hide != HideFaces.none && _facts == null && !_factsFailed) {
      unawaited(_loadFacts());
    }
    if (hide == HideFaces.except && _people == null && !_peopleFailed) {
      unawaited(_loadPeople());
    }
  }

  bool _loadingFacts = false;
  bool _loadingPeople = false;

  Future<void> _loadFacts() async {
    if (_loadingFacts) return;
    _loadingFacts = true;
    try {
      final facts = await widget.session.api.getAlbumPrivacy(widget.albumId);
      if (mounted) setState(() => _facts = facts);
    } on Object {
      if (mounted) setState(() => _factsFailed = true);
    } finally {
      _loadingFacts = false;
    }
  }

  Future<void> _loadPeople() async {
    if (_loadingPeople) return;
    _loadingPeople = true;
    try {
      final list = await widget.session.api.listPeople();
      final people = [
        for (final person in list?.people ?? const <Person>[])
          if (!person.hidden && person.name.trim().isNotEmpty) person,
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (mounted) setState(() => _people = people);
    } on Object {
      if (mounted) setState(() => _peopleFailed = true);
    } finally {
      _loadingPeople = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    final dim = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Palette.dim);
    final facts = _facts;
    final people = _people;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          l.linkPrivacyHideFaces,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final (option, label) in [
              (HideFaces.none, l.linkPrivacyFacesNone),
              (HideFaces.all, l.linkPrivacyFacesAll),
              (HideFaces.except, l.linkPrivacyFacesExcept),
            ])
              ChoiceChip(
                key: ValueKey('link-faces-${option.value}'),
                label: Text(label),
                selected: value.hideFaces == option,
                onSelected: (_) =>
                    widget.onChanged(value.copyWith(hideFaces: option)),
              ),
          ],
        ),
        if (value.hideFaces == HideFaces.except) ...[
          const SizedBox(height: 8),
          Text(l.linkPrivacyChoosePeople, style: dim),
          const SizedBox(height: 4),
          if (_peopleFailed)
            Text(l.linkPrivacyPeopleFailed, style: dim)
          else if (people == null)
            const _SkeletonLine(widthFactor: 0.6)
          else if (people.isEmpty)
            Text(l.linkPrivacyNoPeople, style: dim)
          else
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final person in people)
                  FilterChip(
                    label: Text(person.name, overflow: TextOverflow.ellipsis),
                    selected: value.visiblePeople.contains(person.id),
                    onSelected: (_) =>
                        widget.onChanged(value.togglePerson(person.id)),
                  ),
              ],
            ),
        ],
        if (value.hideFaces != HideFaces.none) ...[
          const SizedBox(height: 8),
          if (facts != null)
            for (final fact in albumPrivacyFacts(facts))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(fact, style: dim),
              )
          else if (_factsFailed)
            Text(l.linkPrivacyUnrecognized, style: dim)
          else ...const [
            _SkeletonLine(widthFactor: 0.9),
            _SkeletonLine(widthFactor: 0.7),
          ],
        ],
        SwitchListTile(
          key: const ValueKey('link-strip-camera'),
          contentPadding: EdgeInsets.zero,
          title: Text(l.linkPrivacyRemoveCamera),
          subtitle: Text(l.linkPrivacyRemoveCameraDetail),
          value: value.stripCamera,
          onChanged: (on) => widget.onChanged(
            value.copyWith(stripCamera: on, stripDate: on && value.stripDate),
          ),
        ),
        SwitchListTile(
          key: const ValueKey('link-strip-date'),
          contentPadding: EdgeInsets.zero,
          title: Text(l.linkPrivacyRemoveDate),
          value: value.stripCamera && value.stripDate,
          onChanged: value.stripCamera
              ? (on) => widget.onChanged(value.copyWith(stripDate: on))
              : null,
        ),
        SwitchListTile(
          key: const ValueKey('link-ask-name'),
          contentPadding: EdgeInsets.zero,
          title: Text(l.linkPrivacyAskName),
          subtitle: Text(l.linkPrivacyAskNameDetail),
          value: value.askName,
          onChanged: (on) => widget.onChanged(value.copyWith(askName: on)),
        ),
      ],
    );
  }
}

/// One link of an album: how private it is, changed at once, and who opened it.
class LinkSettingsScreen extends StatefulWidget {
  const LinkSettingsScreen({
    super.key,
    required this.session,
    required this.albumId,
    required this.link,
  });

  final Session session;
  final String albumId;
  final ShareLink link;

  @override
  State<LinkSettingsScreen> createState() => _LinkSettingsScreenState();
}

class _LinkSettingsScreenState extends State<LinkSettingsScreen> {
  late ShareLink _link = widget.link;
  late LinkPrivacyChoice _choice = LinkPrivacyChoice.of(widget.link);

  /// Changes go one at a time, so the last one is what the server keeps.
  Future<void> _saving = Future.value();

  void _change(LinkPrivacyChoice choice) {
    setState(() => _choice = choice);
    _saving = _saving.then((_) => _save(choice));
  }

  Future<void> _save(LinkPrivacyChoice choice) async {
    try {
      final saved = await widget.session.api.updateAlbumLink(
        widget.albumId,
        _link.id,
        choice.toUpdate(showLocation: _link.showLocation),
      );
      if (saved != null && mounted) setState(() => _link = saved);
    } on ApiException catch (cause) {
      if (!mounted) return;
      setState(() => _choice = LinkPrivacyChoice.of(_link));
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text('${l.albumSheetsActionFailed} ${cause.message ?? ''}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _link.label.isEmpty ? l.albumSheetsUnnamedLink : _link.label;
    return Scaffold(
      appBar: AppBar(title: Text(title, overflow: TextOverflow.ellipsis)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(linkOpenedLine(_link)),
            ListTile(
              key: const ValueKey('link-who-opened'),
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.visibility_outlined, color: Palette.dim),
              title: Text(l.linkPrivacyWhoOpened),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LinkVisitsScreen(
                    session: widget.session,
                    albumId: widget.albumId,
                    linkId: _link.id,
                  ),
                ),
              ),
            ),
            Divider(color: Palette.line),
            LinkPrivacyFields(
              session: widget.session,
              albumId: widget.albumId,
              value: _choice,
              onChanged: _change,
            ),
          ],
        ),
      ),
    );
  }
}

/// Who opened a link, newest first. Only the album's owner sees this.
class LinkVisitsScreen extends StatefulWidget {
  const LinkVisitsScreen({
    super.key,
    required this.session,
    required this.albumId,
    required this.linkId,
  });

  final Session session;
  final String albumId;
  final String linkId;

  @override
  State<LinkVisitsScreen> createState() => _LinkVisitsScreenState();
}

class _LinkVisitsScreenState extends State<LinkVisitsScreen> {
  List<LinkVisit>? _visits;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final visits = await widget.session.api.listLinkVisits(
        widget.albumId,
        widget.linkId,
      );
      if (mounted) setState(() => _visits = visits ?? const []);
    } on Object {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visits = _visits;
    final dim = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Palette.dim);
    return Scaffold(
      appBar: AppBar(title: Text(l.linkPrivacyWhoOpened)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_failed)
              Text(l.linkPrivacyVisitsFailed)
            else if (visits == null)
              for (var i = 0; i < 3; i++)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      _SkeletonLine(widthFactor: 0.4),
                      _SkeletonLine(widthFactor: 0.8),
                    ],
                  ),
                )
            else if (visits.isEmpty)
              Text(l.linkPrivacyNoVisits)
            else
              for (final visit in visits)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    visit.name?.trim().isNotEmpty ?? false
                        ? visit.name!.trim()
                        : l.linkPrivacyNoName,
                  ),
                  subtitle: Text(
                    [
                      '${visitTime(visit.at)} · ${visitPlace(visit)}',
                      visit.device,
                      visitActivity(visit),
                    ].join('\n'),
                  ),
                ),
            const SizedBox(height: 16),
            Text(l.linkPrivacyAttribution, style: dim),
          ],
        ),
      ),
    );
  }
}

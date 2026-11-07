import 'package:mediarr_api/api.dart';

/// What a search asks for: the words, and every filter chosen. The same filters as on the web.
class SearchQuery {
  const SearchQuery({
    this.words = '',
    this.plain = false,
    this.from,
    this.to,
    this.people = const [],
    this.anyPerson = false,
    this.place,
    this.camera,
    this.lens,
    this.type,
    this.minRating,
    this.tags = const [],
    this.album,
    this.albumTitle,
    this.notInAlbum = false,
    this.favorite = false,
  });

  final String words;

  /// Take no filters from the words: each word is looked for as it is.
  final bool plain;

  /// Days, as YYYY-MM-DD.
  final String? from;
  final String? to;
  final List<String> people;
  final bool anyPerson;
  final String? place;
  final String? camera;
  final String? lens;

  /// photo or video.
  final String? type;
  final int? minRating;
  final List<String> tags;
  final String? album;
  final String? albumTitle;
  final bool notInAlbum;
  final bool favorite;

  /// How many filters are chosen, for the button that opens them.
  int get chosen => [
    from != null || to != null,
    people.isNotEmpty,
    place != null,
    camera != null,
    lens != null,
    type != null,
    minRating != null,
    tags.isNotEmpty,
    album != null,
    notInAlbum,
    favorite,
  ].where((on) => on).length;

  /// Whether there is anything to search for.
  bool get isEmpty => words.trim().isEmpty && chosen == 0;

  Future<SearchResult?> run(DefaultApi api) => api.searchAssets(
    q: words.trim().isEmpty ? null : words.trim(),
    plain: plain ? true : null,
    from: from,
    to: to,
    person: people.isEmpty ? null : people,
    people: anyPerson && people.length > 1 ? 'any' : null,
    place: place,
    camera: camera,
    lens: lens,
    type: type,
    minRating: minRating,
    tag: tags.isEmpty ? null : tags,
    album: album,
    notInAlbum: notInAlbum ? true : null,
    favorite: favorite ? true : null,
  );

  SearchQuery copyWith({
    String? words,
    bool? plain,
    String? Function()? from,
    String? Function()? to,
    List<String>? people,
    bool? anyPerson,
    String? Function()? place,
    String? Function()? camera,
    String? Function()? lens,
    String? Function()? type,
    int? Function()? minRating,
    List<String>? tags,
    String? Function()? album,
    String? Function()? albumTitle,
    bool? notInAlbum,
    bool? favorite,
  }) => SearchQuery(
    words: words ?? this.words,
    plain: plain ?? this.plain,
    from: from == null ? this.from : from(),
    to: to == null ? this.to : to(),
    people: people ?? this.people,
    anyPerson: anyPerson ?? this.anyPerson,
    place: place == null ? this.place : place(),
    camera: camera == null ? this.camera : camera(),
    lens: lens == null ? this.lens : lens(),
    type: type == null ? this.type : type(),
    minRating: minRating == null ? this.minRating : minRating(),
    tags: tags ?? this.tags,
    album: album == null ? this.album : album(),
    albumTitle: albumTitle == null ? this.albumTitle : albumTitle(),
    notInAlbum: notInAlbum ?? this.notInAlbum,
    favorite: favorite ?? this.favorite,
  );
}

/// A filter a search used, shown as a chip that can be taken away.
class SearchChip {
  const SearchChip(this.key, this.label, {this.value, this.found = false});

  final String key;
  final String label;
  final String? value;

  /// Found in the words, not chosen; taking it away searches the word as a word.
  final bool found;
}

/// The filters of an answer as chips, marked by whether they were chosen or found in the words.
List<SearchChip> chipsFor(
  SearchFilters f,
  SearchQuery q,
  String Function(DateTime) day,
) {
  final chips = <SearchChip>[];
  if (f.from != null || f.to != null) {
    final label =
        '${f.from == null ? '…' : day(f.from!)} – ${f.to == null ? '…' : day(f.to!)}';
    chips.add(
      SearchChip('dates', label, found: q.from == null && q.to == null),
    );
  }
  for (final person in f.people) {
    chips.add(
      SearchChip(
        'person',
        person.name.isEmpty ? 'No name' : person.name,
        value: person.id,
        found: !q.people.contains(person.id),
      ),
    );
  }
  if (f.place != null) {
    chips.add(SearchChip('place', f.place!, found: q.place == null));
  }
  if (f.camera != null) {
    chips.add(SearchChip('camera', f.camera!, found: q.camera == null));
  }
  if (f.lens != null) chips.add(SearchChip('lens', f.lens!));
  if (f.type != null) {
    chips.add(
      SearchChip(
        'type',
        f.type == SearchFiltersTypeEnum.video ? 'Videos' : 'Photos',
      ),
    );
  }
  if (f.minRating != null) {
    chips.add(SearchChip('minRating', '${'★' * f.minRating!}+'));
  }
  for (final tag in f.tags) {
    chips.add(SearchChip('tag', '#$tag', value: tag));
  }
  if (f.album != null) {
    chips.add(SearchChip('album', 'In album: ${f.album!.title}'));
  }
  if (f.notInAlbum == true) {
    chips.add(const SearchChip('notInAlbum', 'In no album'));
  }
  if (f.favorite == true) chips.add(const SearchChip('favorite', 'Favourites'));
  return chips;
}

String _day(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

/// The search without one chip. A chosen filter is dropped. A filter found in the words is dropped
/// by searching the words as they are, keeping the other filters found in them as chosen ones.
SearchQuery withoutChip(SearchQuery q, SearchChip chip, SearchFilters f) {
  if (chip.found) {
    var next = q.copyWith(plain: true);
    if (chip.key != 'dates' && (f.from != null || f.to != null)) {
      next = next.copyWith(
        from: () => f.from == null ? null : _day(f.from!),
        to: () => f.to == null ? null : _day(f.to!),
      );
    }
    final people = [
      ...next.people,
      for (final person in f.people)
        if (!(chip.key == 'person' && chip.value == person.id) &&
            !next.people.contains(person.id))
          person.id,
    ];
    next = next.copyWith(people: people);
    if (chip.key != 'place' && f.place != null && next.place == null) {
      next = next.copyWith(place: () => f.place);
    }
    if (chip.key != 'camera' && f.camera != null && next.camera == null) {
      next = next.copyWith(camera: () => f.camera);
    }
    return next;
  }
  return switch (chip.key) {
    'dates' => q.copyWith(from: () => null, to: () => null),
    'person' => q.copyWith(
      people: [
        for (final id in q.people)
          if (id != chip.value) id,
      ],
    ),
    'place' => q.copyWith(place: () => null),
    'camera' => q.copyWith(camera: () => null),
    'lens' => q.copyWith(lens: () => null),
    'type' => q.copyWith(type: () => null),
    'minRating' => q.copyWith(minRating: () => null),
    'tag' => q.copyWith(
      tags: [
        for (final tag in q.tags)
          if (tag != chip.value) tag,
      ],
    ),
    'album' => q.copyWith(album: () => null, albumTitle: () => null),
    'notInAlbum' => q.copyWith(notInAlbum: false),
    'favorite' => q.copyWith(favorite: false),
    _ => q,
  };
}

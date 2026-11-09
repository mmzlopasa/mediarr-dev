//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SearchFilters {
  /// Returns a new [SearchFilters] instance.
  SearchFilters({
    this.from,
    this.to,
    this.person,
    this.people = const [],
    this.peopleMatch,
    this.place,
    this.camera,
    this.lens,
    this.type,
    this.minRating,
    this.pick,
    this.tags = const [],
    this.album,
    this.notInAlbum,
    this.favorite,
    this.words,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? from;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? to;

  /// The name of a person found in the words
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? person;

  List<PersonRef> people;

  SearchFiltersPeopleMatchEnum? peopleMatch;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? place;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? camera;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? lens;

  SearchFiltersTypeEnum? type;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? minRating;

  /// 1 picked, -1 rejected, 0 unmarked
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? pick;

  List<String> tags;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  AlbumRef? album;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? notInAlbum;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? favorite;

  /// What is left of the query after the filters were taken out
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? words;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchFilters &&
          other.from == from &&
          other.to == to &&
          other.person == person &&
          _deepEquality.equals(other.people, people) &&
          other.peopleMatch == peopleMatch &&
          other.place == place &&
          other.camera == camera &&
          other.lens == lens &&
          other.type == type &&
          other.minRating == minRating &&
          other.pick == pick &&
          _deepEquality.equals(other.tags, tags) &&
          other.album == album &&
          other.notInAlbum == notInAlbum &&
          other.favorite == favorite &&
          other.words == words;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (from == null ? 0 : from!.hashCode) +
      (to == null ? 0 : to!.hashCode) +
      (person == null ? 0 : person!.hashCode) +
      (people.hashCode) +
      (peopleMatch == null ? 0 : peopleMatch!.hashCode) +
      (place == null ? 0 : place!.hashCode) +
      (camera == null ? 0 : camera!.hashCode) +
      (lens == null ? 0 : lens!.hashCode) +
      (type == null ? 0 : type!.hashCode) +
      (minRating == null ? 0 : minRating!.hashCode) +
      (pick == null ? 0 : pick!.hashCode) +
      (tags.hashCode) +
      (album == null ? 0 : album!.hashCode) +
      (notInAlbum == null ? 0 : notInAlbum!.hashCode) +
      (favorite == null ? 0 : favorite!.hashCode) +
      (words == null ? 0 : words!.hashCode);

  @override
  String toString() =>
      'SearchFilters[from=$from, to=$to, person=$person, people=$people, peopleMatch=$peopleMatch, place=$place, camera=$camera, lens=$lens, type=$type, minRating=$minRating, pick=$pick, tags=$tags, album=$album, notInAlbum=$notInAlbum, favorite=$favorite, words=$words]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.from != null) {
      json[r'from'] = _dateFormatter.format(this.from!.toUtc());
    } else {
      json[r'from'] = null;
    }
    if (this.to != null) {
      json[r'to'] = _dateFormatter.format(this.to!.toUtc());
    } else {
      json[r'to'] = null;
    }
    if (this.person != null) {
      json[r'person'] = this.person;
    } else {
      json[r'person'] = null;
    }
    json[r'people'] = this.people;
    if (this.peopleMatch != null) {
      json[r'peopleMatch'] = this.peopleMatch;
    } else {
      json[r'peopleMatch'] = null;
    }
    if (this.place != null) {
      json[r'place'] = this.place;
    } else {
      json[r'place'] = null;
    }
    if (this.camera != null) {
      json[r'camera'] = this.camera;
    } else {
      json[r'camera'] = null;
    }
    if (this.lens != null) {
      json[r'lens'] = this.lens;
    } else {
      json[r'lens'] = null;
    }
    if (this.type != null) {
      json[r'type'] = this.type;
    } else {
      json[r'type'] = null;
    }
    if (this.minRating != null) {
      json[r'minRating'] = this.minRating;
    } else {
      json[r'minRating'] = null;
    }
    if (this.pick != null) {
      json[r'pick'] = this.pick;
    } else {
      json[r'pick'] = null;
    }
    json[r'tags'] = this.tags;
    if (this.album != null) {
      json[r'album'] = this.album;
    } else {
      json[r'album'] = null;
    }
    if (this.notInAlbum != null) {
      json[r'notInAlbum'] = this.notInAlbum;
    } else {
      json[r'notInAlbum'] = null;
    }
    if (this.favorite != null) {
      json[r'favorite'] = this.favorite;
    } else {
      json[r'favorite'] = null;
    }
    if (this.words != null) {
      json[r'words'] = this.words;
    } else {
      json[r'words'] = null;
    }
    return json;
  }

  /// Returns a new [SearchFilters] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SearchFilters? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "SearchFilters[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "SearchFilters[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return SearchFilters(
        from: mapDateTime(json, r'from', r''),
        to: mapDateTime(json, r'to', r''),
        person: mapValueOfType<String>(json, r'person'),
        people: PersonRef.listFromJson(json[r'people']),
        peopleMatch:
            SearchFiltersPeopleMatchEnum.fromJson(json[r'peopleMatch']),
        place: mapValueOfType<String>(json, r'place'),
        camera: mapValueOfType<String>(json, r'camera'),
        lens: mapValueOfType<String>(json, r'lens'),
        type: SearchFiltersTypeEnum.fromJson(json[r'type']),
        minRating: mapValueOfType<int>(json, r'minRating'),
        pick: mapValueOfType<int>(json, r'pick'),
        tags: json[r'tags'] is Iterable
            ? (json[r'tags'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        album: AlbumRef.fromJson(json[r'album']),
        notInAlbum: mapValueOfType<bool>(json, r'notInAlbum'),
        favorite: mapValueOfType<bool>(json, r'favorite'),
        words: mapValueOfType<String>(json, r'words'),
      );
    }
    return null;
  }

  static List<SearchFilters> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SearchFilters>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SearchFilters.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SearchFilters> mapFromJson(dynamic json) {
    final map = <String, SearchFilters>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SearchFilters.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SearchFilters-objects as value to a dart map
  static Map<String, List<SearchFilters>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SearchFilters>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SearchFilters.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{};
}

class SearchFiltersPeopleMatchEnum {
  /// Instantiate a new enum with the provided [value].
  const SearchFiltersPeopleMatchEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const all = SearchFiltersPeopleMatchEnum._(r'all');
  static const any = SearchFiltersPeopleMatchEnum._(r'any');

  /// List of all possible values in this [enum][SearchFiltersPeopleMatchEnum].
  static const values = <SearchFiltersPeopleMatchEnum>[
    all,
    any,
  ];

  static SearchFiltersPeopleMatchEnum? fromJson(dynamic value) =>
      SearchFiltersPeopleMatchEnumTypeTransformer().decode(value);

  static List<SearchFiltersPeopleMatchEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SearchFiltersPeopleMatchEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SearchFiltersPeopleMatchEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SearchFiltersPeopleMatchEnum] to String,
/// and [decode] dynamic data back to [SearchFiltersPeopleMatchEnum].
class SearchFiltersPeopleMatchEnumTypeTransformer {
  factory SearchFiltersPeopleMatchEnumTypeTransformer() =>
      _instance ??= const SearchFiltersPeopleMatchEnumTypeTransformer._();

  const SearchFiltersPeopleMatchEnumTypeTransformer._();

  String encode(SearchFiltersPeopleMatchEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a SearchFiltersPeopleMatchEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SearchFiltersPeopleMatchEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'all':
          return SearchFiltersPeopleMatchEnum.all;
        case r'any':
          return SearchFiltersPeopleMatchEnum.any;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [SearchFiltersPeopleMatchEnumTypeTransformer] instance.
  static SearchFiltersPeopleMatchEnumTypeTransformer? _instance;
}

class SearchFiltersTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const SearchFiltersTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const photo = SearchFiltersTypeEnum._(r'photo');
  static const video = SearchFiltersTypeEnum._(r'video');

  /// List of all possible values in this [enum][SearchFiltersTypeEnum].
  static const values = <SearchFiltersTypeEnum>[
    photo,
    video,
  ];

  static SearchFiltersTypeEnum? fromJson(dynamic value) =>
      SearchFiltersTypeEnumTypeTransformer().decode(value);

  static List<SearchFiltersTypeEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SearchFiltersTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SearchFiltersTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SearchFiltersTypeEnum] to String,
/// and [decode] dynamic data back to [SearchFiltersTypeEnum].
class SearchFiltersTypeEnumTypeTransformer {
  factory SearchFiltersTypeEnumTypeTransformer() =>
      _instance ??= const SearchFiltersTypeEnumTypeTransformer._();

  const SearchFiltersTypeEnumTypeTransformer._();

  String encode(SearchFiltersTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a SearchFiltersTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SearchFiltersTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'photo':
          return SearchFiltersTypeEnum.photo;
        case r'video':
          return SearchFiltersTypeEnum.video;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [SearchFiltersTypeEnumTypeTransformer] instance.
  static SearchFiltersTypeEnumTypeTransformer? _instance;
}

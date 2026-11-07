//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SearchOptions {
  /// Returns a new [SearchOptions] instance.
  SearchOptions({
    this.cameras = const [],
    this.lenses = const [],
    this.places = const [],
    this.tags = const [],
  });

  List<String> cameras;

  List<String> lenses;

  List<String> places;

  List<String> tags;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchOptions &&
          _deepEquality.equals(other.cameras, cameras) &&
          _deepEquality.equals(other.lenses, lenses) &&
          _deepEquality.equals(other.places, places) &&
          _deepEquality.equals(other.tags, tags);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (cameras.hashCode) +
      (lenses.hashCode) +
      (places.hashCode) +
      (tags.hashCode);

  @override
  String toString() =>
      'SearchOptions[cameras=$cameras, lenses=$lenses, places=$places, tags=$tags]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'cameras'] = this.cameras;
    json[r'lenses'] = this.lenses;
    json[r'places'] = this.places;
    json[r'tags'] = this.tags;
    return json;
  }

  /// Returns a new [SearchOptions] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SearchOptions? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "SearchOptions[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "SearchOptions[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return SearchOptions(
        cameras: json[r'cameras'] is Iterable
            ? (json[r'cameras'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        lenses: json[r'lenses'] is Iterable
            ? (json[r'lenses'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        places: json[r'places'] is Iterable
            ? (json[r'places'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        tags: json[r'tags'] is Iterable
            ? (json[r'tags'] as Iterable).cast<String>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<SearchOptions> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SearchOptions>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SearchOptions.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SearchOptions> mapFromJson(dynamic json) {
    final map = <String, SearchOptions>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SearchOptions.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SearchOptions-objects as value to a dart map
  static Map<String, List<SearchOptions>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SearchOptions>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SearchOptions.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'cameras',
    'lenses',
    'places',
    'tags',
  };
}

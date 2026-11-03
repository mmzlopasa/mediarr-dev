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
    this.place,
    this.camera,
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

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? person;

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchFilters &&
          other.from == from &&
          other.to == to &&
          other.person == person &&
          other.place == place &&
          other.camera == camera;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (from == null ? 0 : from!.hashCode) +
      (to == null ? 0 : to!.hashCode) +
      (person == null ? 0 : person!.hashCode) +
      (place == null ? 0 : place!.hashCode) +
      (camera == null ? 0 : camera!.hashCode);

  @override
  String toString() =>
      'SearchFilters[from=$from, to=$to, person=$person, place=$place, camera=$camera]';

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
        place: mapValueOfType<String>(json, r'place'),
        camera: mapValueOfType<String>(json, r'camera'),
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

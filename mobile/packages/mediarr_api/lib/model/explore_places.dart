//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ExplorePlaces {
  /// Returns a new [ExplorePlaces] instance.
  ExplorePlaces({
    this.places = const [],
  });

  List<ExplorePlace> places;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExplorePlaces && _deepEquality.equals(other.places, places);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (places.hashCode);

  @override
  String toString() => 'ExplorePlaces[places=$places]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'places'] = this.places;
    return json;
  }

  /// Returns a new [ExplorePlaces] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ExplorePlaces? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ExplorePlaces[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ExplorePlaces[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ExplorePlaces(
        places: ExplorePlace.listFromJson(json[r'places']),
      );
    }
    return null;
  }

  static List<ExplorePlaces> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ExplorePlaces>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ExplorePlaces.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ExplorePlaces> mapFromJson(dynamic json) {
    final map = <String, ExplorePlaces>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ExplorePlaces.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ExplorePlaces-objects as value to a dart map
  static Map<String, List<ExplorePlaces>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ExplorePlaces>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ExplorePlaces.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'places',
  };
}

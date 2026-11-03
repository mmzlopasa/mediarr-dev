//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MapPoints {
  /// Returns a new [MapPoints] instance.
  MapPoints({
    this.ids = const [],
    this.kinds = const [],
    this.lats = const [],
    this.lons = const [],
  });

  List<String> ids;

  List<String> kinds;

  List<double> lats;

  List<double> lons;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapPoints &&
          _deepEquality.equals(other.ids, ids) &&
          _deepEquality.equals(other.kinds, kinds) &&
          _deepEquality.equals(other.lats, lats) &&
          _deepEquality.equals(other.lons, lons);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (ids.hashCode) + (kinds.hashCode) + (lats.hashCode) + (lons.hashCode);

  @override
  String toString() =>
      'MapPoints[ids=$ids, kinds=$kinds, lats=$lats, lons=$lons]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'ids'] = this.ids;
    json[r'kinds'] = this.kinds;
    json[r'lats'] = this.lats;
    json[r'lons'] = this.lons;
    return json;
  }

  /// Returns a new [MapPoints] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MapPoints? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "MapPoints[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "MapPoints[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return MapPoints(
        ids: json[r'ids'] is Iterable
            ? (json[r'ids'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        kinds: json[r'kinds'] is Iterable
            ? (json[r'kinds'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        lats: json[r'lats'] is Iterable
            ? (json[r'lats'] as Iterable).cast<double>().toList(growable: false)
            : const [],
        lons: json[r'lons'] is Iterable
            ? (json[r'lons'] as Iterable).cast<double>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<MapPoints> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <MapPoints>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MapPoints.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MapPoints> mapFromJson(dynamic json) {
    final map = <String, MapPoints>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MapPoints.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MapPoints-objects as value to a dart map
  static Map<String, List<MapPoints>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<MapPoints>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MapPoints.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'ids',
    'kinds',
    'lats',
    'lons',
  };
}

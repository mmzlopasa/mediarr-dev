//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CastAssets {
  /// Returns a new [CastAssets] instance.
  CastAssets({
    this.ids = const [],
  });

  List<String> ids;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CastAssets && _deepEquality.equals(other.ids, ids);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (ids.hashCode);

  @override
  String toString() => 'CastAssets[ids=$ids]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'ids'] = this.ids;
    return json;
  }

  /// Returns a new [CastAssets] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CastAssets? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "CastAssets[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "CastAssets[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CastAssets(
        ids: json[r'ids'] is Iterable
            ? (json[r'ids'] as Iterable).cast<String>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<CastAssets> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CastAssets>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CastAssets.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CastAssets> mapFromJson(dynamic json) {
    final map = <String, CastAssets>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CastAssets.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CastAssets-objects as value to a dart map
  static Map<String, List<CastAssets>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CastAssets>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CastAssets.listFromJson(
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
  };
}

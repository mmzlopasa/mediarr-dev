//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TrashSummary {
  /// Returns a new [TrashSummary] instance.
  TrashSummary({
    required this.assets,
    required this.bytes,
  });

  int assets;

  int bytes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrashSummary && other.assets == assets && other.bytes == bytes;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (assets.hashCode) + (bytes.hashCode);

  @override
  String toString() => 'TrashSummary[assets=$assets, bytes=$bytes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'assets'] = this.assets;
    json[r'bytes'] = this.bytes;
    return json;
  }

  /// Returns a new [TrashSummary] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TrashSummary? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "TrashSummary[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "TrashSummary[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return TrashSummary(
        assets: mapValueOfType<int>(json, r'assets')!,
        bytes: mapValueOfType<int>(json, r'bytes')!,
      );
    }
    return null;
  }

  static List<TrashSummary> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <TrashSummary>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TrashSummary.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TrashSummary> mapFromJson(dynamic json) {
    final map = <String, TrashSummary>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TrashSummary.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TrashSummary-objects as value to a dart map
  static Map<String, List<TrashSummary>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<TrashSummary>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TrashSummary.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'assets',
    'bytes',
  };
}

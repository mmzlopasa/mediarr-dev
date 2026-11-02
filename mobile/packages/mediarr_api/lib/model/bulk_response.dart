//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class BulkResponse {
  /// Returns a new [BulkResponse] instance.
  BulkResponse({
    required this.changed,
  });

  int changed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BulkResponse && other.changed == changed;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (changed.hashCode);

  @override
  String toString() => 'BulkResponse[changed=$changed]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'changed'] = this.changed;
    return json;
  }

  /// Returns a new [BulkResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BulkResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "BulkResponse[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "BulkResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return BulkResponse(
        changed: mapValueOfType<int>(json, r'changed')!,
      );
    }
    return null;
  }

  static List<BulkResponse> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <BulkResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BulkResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BulkResponse> mapFromJson(dynamic json) {
    final map = <String, BulkResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BulkResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BulkResponse-objects as value to a dart map
  static Map<String, List<BulkResponse>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<BulkResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BulkResponse.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'changed',
  };
}

//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class FixChange {
  /// Returns a new [FixChange] instance.
  FixChange({
    required this.id,
    required this.name,
    required this.before,
    required this.after,
  });

  String id;

  String name;

  /// A date as 2024-07-05T14:30:00+02:00, or a location as 45.81234, 15.97810; empty is none
  String before;

  String after;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FixChange &&
          other.id == id &&
          other.name == name &&
          other.before == before &&
          other.after == after;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) + (name.hashCode) + (before.hashCode) + (after.hashCode);

  @override
  String toString() =>
      'FixChange[id=$id, name=$name, before=$before, after=$after]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'name'] = this.name;
    json[r'before'] = this.before;
    json[r'after'] = this.after;
    return json;
  }

  /// Returns a new [FixChange] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FixChange? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "FixChange[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "FixChange[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return FixChange(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        before: mapValueOfType<String>(json, r'before')!,
        after: mapValueOfType<String>(json, r'after')!,
      );
    }
    return null;
  }

  static List<FixChange> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <FixChange>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FixChange.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FixChange> mapFromJson(dynamic json) {
    final map = <String, FixChange>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FixChange.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FixChange-objects as value to a dart map
  static Map<String, List<FixChange>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<FixChange>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FixChange.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'before',
    'after',
  };
}

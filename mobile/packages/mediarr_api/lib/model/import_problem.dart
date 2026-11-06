//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ImportProblem {
  /// Returns a new [ImportProblem] instance.
  ImportProblem({
    required this.name,
    required this.reason,
  });

  String name;

  String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportProblem && other.name == name && other.reason == reason;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (name.hashCode) + (reason.hashCode);

  @override
  String toString() => 'ImportProblem[name=$name, reason=$reason]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'name'] = this.name;
    json[r'reason'] = this.reason;
    return json;
  }

  /// Returns a new [ImportProblem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ImportProblem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ImportProblem[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ImportProblem[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ImportProblem(
        name: mapValueOfType<String>(json, r'name')!,
        reason: mapValueOfType<String>(json, r'reason')!,
      );
    }
    return null;
  }

  static List<ImportProblem> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ImportProblem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ImportProblem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ImportProblem> mapFromJson(dynamic json) {
    final map = <String, ImportProblem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ImportProblem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ImportProblem-objects as value to a dart map
  static Map<String, List<ImportProblem>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ImportProblem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ImportProblem.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'reason',
  };
}

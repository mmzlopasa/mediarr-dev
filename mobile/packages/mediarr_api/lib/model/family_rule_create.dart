//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class FamilyRuleCreate {
  /// Returns a new [FamilyRuleCreate] instance.
  FamilyRuleCreate({
    required this.title,
    required this.rules,
  });

  String title;

  AlbumRules rules;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilyRuleCreate && other.title == title && other.rules == rules;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (title.hashCode) + (rules.hashCode);

  @override
  String toString() => 'FamilyRuleCreate[title=$title, rules=$rules]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'title'] = this.title;
    json[r'rules'] = this.rules;
    return json;
  }

  /// Returns a new [FamilyRuleCreate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FamilyRuleCreate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "FamilyRuleCreate[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "FamilyRuleCreate[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return FamilyRuleCreate(
        title: mapValueOfType<String>(json, r'title')!,
        rules: AlbumRules.fromJson(json[r'rules'])!,
      );
    }
    return null;
  }

  static List<FamilyRuleCreate> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <FamilyRuleCreate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FamilyRuleCreate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FamilyRuleCreate> mapFromJson(dynamic json) {
    final map = <String, FamilyRuleCreate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FamilyRuleCreate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FamilyRuleCreate-objects as value to a dart map
  static Map<String, List<FamilyRuleCreate>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<FamilyRuleCreate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FamilyRuleCreate.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'title',
    'rules',
  };
}

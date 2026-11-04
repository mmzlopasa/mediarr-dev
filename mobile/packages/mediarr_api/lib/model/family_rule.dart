//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class FamilyRule {
  /// Returns a new [FamilyRule] instance.
  FamilyRule({
    required this.id,
    required this.title,
    required this.rules,
  });

  String id;

  String title;

  AlbumRules rules;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilyRule &&
          other.id == id &&
          other.title == title &&
          other.rules == rules;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) + (title.hashCode) + (rules.hashCode);

  @override
  String toString() => 'FamilyRule[id=$id, title=$title, rules=$rules]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'title'] = this.title;
    json[r'rules'] = this.rules;
    return json;
  }

  /// Returns a new [FamilyRule] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FamilyRule? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "FamilyRule[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "FamilyRule[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return FamilyRule(
        id: mapValueOfType<String>(json, r'id')!,
        title: mapValueOfType<String>(json, r'title')!,
        rules: AlbumRules.fromJson(json[r'rules'])!,
      );
    }
    return null;
  }

  static List<FamilyRule> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <FamilyRule>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FamilyRule.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FamilyRule> mapFromJson(dynamic json) {
    final map = <String, FamilyRule>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FamilyRule.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FamilyRule-objects as value to a dart map
  static Map<String, List<FamilyRule>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<FamilyRule>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FamilyRule.listFromJson(
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
    'title',
    'rules',
  };
}

//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Family {
  /// Returns a new [Family] instance.
  Family({
    required this.enabled,
    required this.member,
    this.members = const [],
    this.rules = const [],
  });

  bool enabled;

  bool member;

  List<UserRef> members;

  List<FamilyRule> rules;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Family &&
          other.enabled == enabled &&
          other.member == member &&
          _deepEquality.equals(other.members, members) &&
          _deepEquality.equals(other.rules, rules);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (enabled.hashCode) +
      (member.hashCode) +
      (members.hashCode) +
      (rules.hashCode);

  @override
  String toString() =>
      'Family[enabled=$enabled, member=$member, members=$members, rules=$rules]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'enabled'] = this.enabled;
    json[r'member'] = this.member;
    json[r'members'] = this.members;
    json[r'rules'] = this.rules;
    return json;
  }

  /// Returns a new [Family] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Family? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Family[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Family[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Family(
        enabled: mapValueOfType<bool>(json, r'enabled')!,
        member: mapValueOfType<bool>(json, r'member')!,
        members: UserRef.listFromJson(json[r'members']),
        rules: FamilyRule.listFromJson(json[r'rules']),
      );
    }
    return null;
  }

  static List<Family> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Family>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Family.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Family> mapFromJson(dynamic json) {
    final map = <String, Family>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Family.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Family-objects as value to a dart map
  static Map<String, List<Family>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Family>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Family.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'enabled',
    'member',
    'members',
    'rules',
  };
}

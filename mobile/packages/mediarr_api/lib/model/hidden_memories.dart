//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class HiddenMemories {
  /// Returns a new [HiddenMemories] instance.
  HiddenMemories({
    required this.count,
    this.people = const [],
  });

  /// Memories that are hidden
  int count;

  List<PersonRef> people;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiddenMemories &&
          other.count == count &&
          _deepEquality.equals(other.people, people);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (count.hashCode) + (people.hashCode);

  @override
  String toString() => 'HiddenMemories[count=$count, people=$people]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'count'] = this.count;
    json[r'people'] = this.people;
    return json;
  }

  /// Returns a new [HiddenMemories] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static HiddenMemories? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "HiddenMemories[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "HiddenMemories[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return HiddenMemories(
        count: mapValueOfType<int>(json, r'count')!,
        people: PersonRef.listFromJson(json[r'people']),
      );
    }
    return null;
  }

  static List<HiddenMemories> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <HiddenMemories>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HiddenMemories.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, HiddenMemories> mapFromJson(dynamic json) {
    final map = <String, HiddenMemories>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = HiddenMemories.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of HiddenMemories-objects as value to a dart map
  static Map<String, List<HiddenMemories>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<HiddenMemories>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = HiddenMemories.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'count',
    'people',
  };
}

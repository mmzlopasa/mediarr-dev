//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MemoryTitleParams {
  /// Returns a new [MemoryTitleParams] instance.
  MemoryTitleParams({
    this.place,
    this.person,
    this.personId,
    this.year,
    this.month,
  });

  /// A trip's place
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? place;

  /// A person's name
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? person;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? personId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? year;

  /// Minimum value: 1
  /// Maximum value: 12
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? month;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryTitleParams &&
          other.place == place &&
          other.person == person &&
          other.personId == personId &&
          other.year == year &&
          other.month == month;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (place == null ? 0 : place!.hashCode) +
      (person == null ? 0 : person!.hashCode) +
      (personId == null ? 0 : personId!.hashCode) +
      (year == null ? 0 : year!.hashCode) +
      (month == null ? 0 : month!.hashCode);

  @override
  String toString() =>
      'MemoryTitleParams[place=$place, person=$person, personId=$personId, year=$year, month=$month]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.place != null) {
      json[r'place'] = this.place;
    } else {
      json[r'place'] = null;
    }
    if (this.person != null) {
      json[r'person'] = this.person;
    } else {
      json[r'person'] = null;
    }
    if (this.personId != null) {
      json[r'personId'] = this.personId;
    } else {
      json[r'personId'] = null;
    }
    if (this.year != null) {
      json[r'year'] = this.year;
    } else {
      json[r'year'] = null;
    }
    if (this.month != null) {
      json[r'month'] = this.month;
    } else {
      json[r'month'] = null;
    }
    return json;
  }

  /// Returns a new [MemoryTitleParams] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MemoryTitleParams? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "MemoryTitleParams[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "MemoryTitleParams[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return MemoryTitleParams(
        place: mapValueOfType<String>(json, r'place'),
        person: mapValueOfType<String>(json, r'person'),
        personId: mapValueOfType<String>(json, r'personId'),
        year: mapValueOfType<int>(json, r'year'),
        month: mapValueOfType<int>(json, r'month'),
      );
    }
    return null;
  }

  static List<MemoryTitleParams> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <MemoryTitleParams>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MemoryTitleParams.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MemoryTitleParams> mapFromJson(dynamic json) {
    final map = <String, MemoryTitleParams>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MemoryTitleParams.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MemoryTitleParams-objects as value to a dart map
  static Map<String, List<MemoryTitleParams>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<MemoryTitleParams>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MemoryTitleParams.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{};
}

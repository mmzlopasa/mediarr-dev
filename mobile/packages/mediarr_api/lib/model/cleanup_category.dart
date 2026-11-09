//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CleanupCategory {
  /// Returns a new [CleanupCategory] instance.
  CleanupCategory({
    required this.id,
    required this.count,
    required this.bytes,
  });

  CleanupCategoryId id;

  int count;

  int bytes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CleanupCategory &&
          other.id == id &&
          other.count == count &&
          other.bytes == bytes;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) + (count.hashCode) + (bytes.hashCode);

  @override
  String toString() => 'CleanupCategory[id=$id, count=$count, bytes=$bytes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'count'] = this.count;
    json[r'bytes'] = this.bytes;
    return json;
  }

  /// Returns a new [CleanupCategory] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CleanupCategory? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "CleanupCategory[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "CleanupCategory[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CleanupCategory(
        id: CleanupCategoryId.fromJson(json[r'id'])!,
        count: mapValueOfType<int>(json, r'count')!,
        bytes: mapValueOfType<int>(json, r'bytes')!,
      );
    }
    return null;
  }

  static List<CleanupCategory> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CleanupCategory>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CleanupCategory.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CleanupCategory> mapFromJson(dynamic json) {
    final map = <String, CleanupCategory>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CleanupCategory.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CleanupCategory-objects as value to a dart map
  static Map<String, List<CleanupCategory>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CleanupCategory>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CleanupCategory.listFromJson(
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
    'count',
    'bytes',
  };
}

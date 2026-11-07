//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UpgradeSnapshot {
  /// Returns a new [UpgradeSnapshot] instance.
  UpgradeSnapshot({
    required this.name,
    required this.fromVersion,
    required this.toVersion,
    required this.fromSchema,
    required this.toSchema,
    required this.createdAt,
    required this.sizeBytes,
  });

  String name;

  /// Empty when the version before is not known
  String fromVersion;

  String toVersion;

  int fromSchema;

  int toSchema;

  DateTime createdAt;

  int sizeBytes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpgradeSnapshot &&
          other.name == name &&
          other.fromVersion == fromVersion &&
          other.toVersion == toVersion &&
          other.fromSchema == fromSchema &&
          other.toSchema == toSchema &&
          other.createdAt == createdAt &&
          other.sizeBytes == sizeBytes;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (name.hashCode) +
      (fromVersion.hashCode) +
      (toVersion.hashCode) +
      (fromSchema.hashCode) +
      (toSchema.hashCode) +
      (createdAt.hashCode) +
      (sizeBytes.hashCode);

  @override
  String toString() =>
      'UpgradeSnapshot[name=$name, fromVersion=$fromVersion, toVersion=$toVersion, fromSchema=$fromSchema, toSchema=$toSchema, createdAt=$createdAt, sizeBytes=$sizeBytes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'name'] = this.name;
    json[r'fromVersion'] = this.fromVersion;
    json[r'toVersion'] = this.toVersion;
    json[r'fromSchema'] = this.fromSchema;
    json[r'toSchema'] = this.toSchema;
    json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    json[r'sizeBytes'] = this.sizeBytes;
    return json;
  }

  /// Returns a new [UpgradeSnapshot] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpgradeSnapshot? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "UpgradeSnapshot[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "UpgradeSnapshot[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return UpgradeSnapshot(
        name: mapValueOfType<String>(json, r'name')!,
        fromVersion: mapValueOfType<String>(json, r'fromVersion')!,
        toVersion: mapValueOfType<String>(json, r'toVersion')!,
        fromSchema: mapValueOfType<int>(json, r'fromSchema')!,
        toSchema: mapValueOfType<int>(json, r'toSchema')!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        sizeBytes: mapValueOfType<int>(json, r'sizeBytes')!,
      );
    }
    return null;
  }

  static List<UpgradeSnapshot> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UpgradeSnapshot>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpgradeSnapshot.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpgradeSnapshot> mapFromJson(dynamic json) {
    final map = <String, UpgradeSnapshot>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpgradeSnapshot.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpgradeSnapshot-objects as value to a dart map
  static Map<String, List<UpgradeSnapshot>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<UpgradeSnapshot>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpgradeSnapshot.listFromJson(
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
    'fromVersion',
    'toVersion',
    'fromSchema',
    'toSchema',
    'createdAt',
    'sizeBytes',
  };
}

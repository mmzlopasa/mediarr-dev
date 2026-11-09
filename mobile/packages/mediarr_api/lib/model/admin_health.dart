//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AdminHealth {
  /// Returns a new [AdminHealth] instance.
  AdminHealth({
    required this.workerRunning,
    this.workerLastSeen,
    required this.mlEnabled,
    this.mlRunning,
    this.ml,
    required this.databaseBytes,
  });

  bool workerRunning;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? workerLastSeen;

  bool mlEnabled;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? mlRunning;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  MlServiceStatus? ml;

  int databaseBytes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminHealth &&
          other.workerRunning == workerRunning &&
          other.workerLastSeen == workerLastSeen &&
          other.mlEnabled == mlEnabled &&
          other.mlRunning == mlRunning &&
          other.ml == ml &&
          other.databaseBytes == databaseBytes;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (workerRunning.hashCode) +
      (workerLastSeen == null ? 0 : workerLastSeen!.hashCode) +
      (mlEnabled.hashCode) +
      (mlRunning == null ? 0 : mlRunning!.hashCode) +
      (ml == null ? 0 : ml!.hashCode) +
      (databaseBytes.hashCode);

  @override
  String toString() =>
      'AdminHealth[workerRunning=$workerRunning, workerLastSeen=$workerLastSeen, mlEnabled=$mlEnabled, mlRunning=$mlRunning, ml=$ml, databaseBytes=$databaseBytes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'workerRunning'] = this.workerRunning;
    if (this.workerLastSeen != null) {
      json[r'workerLastSeen'] = this.workerLastSeen!.toUtc().toIso8601String();
    } else {
      json[r'workerLastSeen'] = null;
    }
    json[r'mlEnabled'] = this.mlEnabled;
    if (this.mlRunning != null) {
      json[r'mlRunning'] = this.mlRunning;
    } else {
      json[r'mlRunning'] = null;
    }
    if (this.ml != null) {
      json[r'ml'] = this.ml;
    } else {
      json[r'ml'] = null;
    }
    json[r'databaseBytes'] = this.databaseBytes;
    return json;
  }

  /// Returns a new [AdminHealth] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AdminHealth? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "AdminHealth[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "AdminHealth[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AdminHealth(
        workerRunning: mapValueOfType<bool>(json, r'workerRunning')!,
        workerLastSeen: mapDateTime(json, r'workerLastSeen', r''),
        mlEnabled: mapValueOfType<bool>(json, r'mlEnabled')!,
        mlRunning: mapValueOfType<bool>(json, r'mlRunning'),
        ml: MlServiceStatus.fromJson(json[r'ml']),
        databaseBytes: mapValueOfType<int>(json, r'databaseBytes')!,
      );
    }
    return null;
  }

  static List<AdminHealth> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AdminHealth>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdminHealth.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AdminHealth> mapFromJson(dynamic json) {
    final map = <String, AdminHealth>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AdminHealth.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AdminHealth-objects as value to a dart map
  static Map<String, List<AdminHealth>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<AdminHealth>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AdminHealth.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'workerRunning',
    'mlEnabled',
    'databaseBytes',
  };
}

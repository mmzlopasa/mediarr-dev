//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class BackupSettingsUpdate {
  /// Returns a new [BackupSettingsUpdate] instance.
  BackupSettingsUpdate({
    required this.repository,
    required this.hour,
    this.password,
    this.s3Key,
    this.s3Secret,
  });

  String repository;

  int hour;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? password;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? s3Key;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? s3Secret;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupSettingsUpdate &&
          other.repository == repository &&
          other.hour == hour &&
          other.password == password &&
          other.s3Key == s3Key &&
          other.s3Secret == s3Secret;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (repository.hashCode) +
      (hour.hashCode) +
      (password == null ? 0 : password!.hashCode) +
      (s3Key == null ? 0 : s3Key!.hashCode) +
      (s3Secret == null ? 0 : s3Secret!.hashCode);

  @override
  String toString() =>
      'BackupSettingsUpdate[repository=$repository, hour=$hour, password=$password, s3Key=$s3Key, s3Secret=$s3Secret]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'repository'] = this.repository;
    json[r'hour'] = this.hour;
    if (this.password != null) {
      json[r'password'] = this.password;
    } else {
      json[r'password'] = null;
    }
    if (this.s3Key != null) {
      json[r's3Key'] = this.s3Key;
    } else {
      json[r's3Key'] = null;
    }
    if (this.s3Secret != null) {
      json[r's3Secret'] = this.s3Secret;
    } else {
      json[r's3Secret'] = null;
    }
    return json;
  }

  /// Returns a new [BackupSettingsUpdate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BackupSettingsUpdate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "BackupSettingsUpdate[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "BackupSettingsUpdate[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return BackupSettingsUpdate(
        repository: mapValueOfType<String>(json, r'repository')!,
        hour: mapValueOfType<int>(json, r'hour')!,
        password: mapValueOfType<String>(json, r'password'),
        s3Key: mapValueOfType<String>(json, r's3Key'),
        s3Secret: mapValueOfType<String>(json, r's3Secret'),
      );
    }
    return null;
  }

  static List<BackupSettingsUpdate> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <BackupSettingsUpdate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BackupSettingsUpdate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BackupSettingsUpdate> mapFromJson(dynamic json) {
    final map = <String, BackupSettingsUpdate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BackupSettingsUpdate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BackupSettingsUpdate-objects as value to a dart map
  static Map<String, List<BackupSettingsUpdate>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<BackupSettingsUpdate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BackupSettingsUpdate.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'repository',
    'hour',
  };
}

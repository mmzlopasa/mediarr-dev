//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class BackupSettings {
  /// Returns a new [BackupSettings] instance.
  BackupSettings({
    required this.repository,
    required this.hour,
    required this.hasPassword,
    required this.hasS3Key,
    required this.localFolder,
  });

  String repository;

  /// The hour of the day, by the server's clock
  int hour;

  bool hasPassword;

  bool hasS3Key;

  /// Where BACKUP_PATH from .env is mounted
  String localFolder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupSettings &&
          other.repository == repository &&
          other.hour == hour &&
          other.hasPassword == hasPassword &&
          other.hasS3Key == hasS3Key &&
          other.localFolder == localFolder;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (repository.hashCode) +
      (hour.hashCode) +
      (hasPassword.hashCode) +
      (hasS3Key.hashCode) +
      (localFolder.hashCode);

  @override
  String toString() =>
      'BackupSettings[repository=$repository, hour=$hour, hasPassword=$hasPassword, hasS3Key=$hasS3Key, localFolder=$localFolder]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'repository'] = this.repository;
    json[r'hour'] = this.hour;
    json[r'hasPassword'] = this.hasPassword;
    json[r'hasS3Key'] = this.hasS3Key;
    json[r'localFolder'] = this.localFolder;
    return json;
  }

  /// Returns a new [BackupSettings] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BackupSettings? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "BackupSettings[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "BackupSettings[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return BackupSettings(
        repository: mapValueOfType<String>(json, r'repository')!,
        hour: mapValueOfType<int>(json, r'hour')!,
        hasPassword: mapValueOfType<bool>(json, r'hasPassword')!,
        hasS3Key: mapValueOfType<bool>(json, r'hasS3Key')!,
        localFolder: mapValueOfType<String>(json, r'localFolder')!,
      );
    }
    return null;
  }

  static List<BackupSettings> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <BackupSettings>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BackupSettings.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BackupSettings> mapFromJson(dynamic json) {
    final map = <String, BackupSettings>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BackupSettings.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BackupSettings-objects as value to a dart map
  static Map<String, List<BackupSettings>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<BackupSettings>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BackupSettings.listFromJson(
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
    'hasPassword',
    'hasS3Key',
    'localFolder',
  };
}

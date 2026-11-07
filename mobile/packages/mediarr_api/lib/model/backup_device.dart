//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class BackupDevice {
  /// Returns a new [BackupDevice] instance.
  BackupDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.appVersion,
    required this.createdAt,
    required this.reportedAt,
    required this.quiet,
    required this.pending,
    required this.working,
    required this.verified,
    required this.failed,
    required this.files,
    required this.confirmed,
    required this.trashed,
    required this.gone,
    required this.ownerEmail,
    required this.ownerName,
  });

  String id;

  String name;

  String platform;

  String appVersion;

  DateTime createdAt;

  DateTime reportedAt;

  /// Has not reported for longer than its owner allows
  bool quiet;

  /// Waiting on the phone, as the phone counts
  int pending;

  int working;

  /// Confirmed, as the phone counts
  int verified;

  int failed;

  /// Checksums the phone has given the server
  int files;

  /// Of those, safe on the server, as the server counts
  int confirmed;

  /// Of those, in the trash
  int trashed;

  /// Of those, no longer on the server
  int gone;

  String ownerEmail;

  String ownerName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupDevice &&
          other.id == id &&
          other.name == name &&
          other.platform == platform &&
          other.appVersion == appVersion &&
          other.createdAt == createdAt &&
          other.reportedAt == reportedAt &&
          other.quiet == quiet &&
          other.pending == pending &&
          other.working == working &&
          other.verified == verified &&
          other.failed == failed &&
          other.files == files &&
          other.confirmed == confirmed &&
          other.trashed == trashed &&
          other.gone == gone &&
          other.ownerEmail == ownerEmail &&
          other.ownerName == ownerName;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (name.hashCode) +
      (platform.hashCode) +
      (appVersion.hashCode) +
      (createdAt.hashCode) +
      (reportedAt.hashCode) +
      (quiet.hashCode) +
      (pending.hashCode) +
      (working.hashCode) +
      (verified.hashCode) +
      (failed.hashCode) +
      (files.hashCode) +
      (confirmed.hashCode) +
      (trashed.hashCode) +
      (gone.hashCode) +
      (ownerEmail.hashCode) +
      (ownerName.hashCode);

  @override
  String toString() =>
      'BackupDevice[id=$id, name=$name, platform=$platform, appVersion=$appVersion, createdAt=$createdAt, reportedAt=$reportedAt, quiet=$quiet, pending=$pending, working=$working, verified=$verified, failed=$failed, files=$files, confirmed=$confirmed, trashed=$trashed, gone=$gone, ownerEmail=$ownerEmail, ownerName=$ownerName]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'name'] = this.name;
    json[r'platform'] = this.platform;
    json[r'appVersion'] = this.appVersion;
    json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    json[r'reportedAt'] = this.reportedAt.toUtc().toIso8601String();
    json[r'quiet'] = this.quiet;
    json[r'pending'] = this.pending;
    json[r'working'] = this.working;
    json[r'verified'] = this.verified;
    json[r'failed'] = this.failed;
    json[r'files'] = this.files;
    json[r'confirmed'] = this.confirmed;
    json[r'trashed'] = this.trashed;
    json[r'gone'] = this.gone;
    json[r'ownerEmail'] = this.ownerEmail;
    json[r'ownerName'] = this.ownerName;
    return json;
  }

  /// Returns a new [BackupDevice] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BackupDevice? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "BackupDevice[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "BackupDevice[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return BackupDevice(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        platform: mapValueOfType<String>(json, r'platform')!,
        appVersion: mapValueOfType<String>(json, r'appVersion')!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        reportedAt: mapDateTime(json, r'reportedAt', r'')!,
        quiet: mapValueOfType<bool>(json, r'quiet')!,
        pending: mapValueOfType<int>(json, r'pending')!,
        working: mapValueOfType<int>(json, r'working')!,
        verified: mapValueOfType<int>(json, r'verified')!,
        failed: mapValueOfType<int>(json, r'failed')!,
        files: mapValueOfType<int>(json, r'files')!,
        confirmed: mapValueOfType<int>(json, r'confirmed')!,
        trashed: mapValueOfType<int>(json, r'trashed')!,
        gone: mapValueOfType<int>(json, r'gone')!,
        ownerEmail: mapValueOfType<String>(json, r'ownerEmail')!,
        ownerName: mapValueOfType<String>(json, r'ownerName')!,
      );
    }
    return null;
  }

  static List<BackupDevice> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <BackupDevice>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BackupDevice.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BackupDevice> mapFromJson(dynamic json) {
    final map = <String, BackupDevice>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BackupDevice.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BackupDevice-objects as value to a dart map
  static Map<String, List<BackupDevice>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<BackupDevice>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BackupDevice.listFromJson(
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
    'name',
    'platform',
    'appVersion',
    'createdAt',
    'reportedAt',
    'quiet',
    'pending',
    'working',
    'verified',
    'failed',
    'files',
    'confirmed',
    'trashed',
    'gone',
    'ownerEmail',
    'ownerName',
  };
}

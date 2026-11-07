//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class BackupDeviceReport {
  /// Returns a new [BackupDeviceReport] instance.
  BackupDeviceReport({
    required this.name,
    required this.platform,
    required this.appVersion,
    required this.pending,
    required this.working,
    required this.verified,
    required this.failed,
    this.failures = const [],
    this.checksums = const [],
    this.replace,
  });

  String name;

  String platform;

  String appVersion;

  /// Minimum value: 0
  int pending;

  /// Minimum value: 0
  int working;

  /// Minimum value: 0
  int verified;

  /// Minimum value: 0
  int failed;

  /// Left out, the ones from before stay
  List<BackupDeviceFailure> failures;

  /// Hex SHA-256 of files confirmed on the server, at most 5000 at a time
  List<String> checksums;

  /// These checksums start the list anew; the following reports add to it
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? replace;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupDeviceReport &&
          other.name == name &&
          other.platform == platform &&
          other.appVersion == appVersion &&
          other.pending == pending &&
          other.working == working &&
          other.verified == verified &&
          other.failed == failed &&
          _deepEquality.equals(other.failures, failures) &&
          _deepEquality.equals(other.checksums, checksums) &&
          other.replace == replace;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (name.hashCode) +
      (platform.hashCode) +
      (appVersion.hashCode) +
      (pending.hashCode) +
      (working.hashCode) +
      (verified.hashCode) +
      (failed.hashCode) +
      (failures.hashCode) +
      (checksums.hashCode) +
      (replace == null ? 0 : replace!.hashCode);

  @override
  String toString() =>
      'BackupDeviceReport[name=$name, platform=$platform, appVersion=$appVersion, pending=$pending, working=$working, verified=$verified, failed=$failed, failures=$failures, checksums=$checksums, replace=$replace]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'name'] = this.name;
    json[r'platform'] = this.platform;
    json[r'appVersion'] = this.appVersion;
    json[r'pending'] = this.pending;
    json[r'working'] = this.working;
    json[r'verified'] = this.verified;
    json[r'failed'] = this.failed;
    json[r'failures'] = this.failures;
    json[r'checksums'] = this.checksums;
    if (this.replace != null) {
      json[r'replace'] = this.replace;
    } else {
      json[r'replace'] = null;
    }
    return json;
  }

  /// Returns a new [BackupDeviceReport] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BackupDeviceReport? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "BackupDeviceReport[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "BackupDeviceReport[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return BackupDeviceReport(
        name: mapValueOfType<String>(json, r'name')!,
        platform: mapValueOfType<String>(json, r'platform')!,
        appVersion: mapValueOfType<String>(json, r'appVersion')!,
        pending: mapValueOfType<int>(json, r'pending')!,
        working: mapValueOfType<int>(json, r'working')!,
        verified: mapValueOfType<int>(json, r'verified')!,
        failed: mapValueOfType<int>(json, r'failed')!,
        failures: BackupDeviceFailure.listFromJson(json[r'failures']),
        checksums: json[r'checksums'] is Iterable
            ? (json[r'checksums'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        replace: mapValueOfType<bool>(json, r'replace'),
      );
    }
    return null;
  }

  static List<BackupDeviceReport> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <BackupDeviceReport>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BackupDeviceReport.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BackupDeviceReport> mapFromJson(dynamic json) {
    final map = <String, BackupDeviceReport>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BackupDeviceReport.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BackupDeviceReport-objects as value to a dart map
  static Map<String, List<BackupDeviceReport>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<BackupDeviceReport>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BackupDeviceReport.listFromJson(
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
    'platform',
    'appVersion',
    'pending',
    'working',
    'verified',
    'failed',
  };
}

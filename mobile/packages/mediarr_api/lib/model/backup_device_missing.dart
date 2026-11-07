//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class BackupDeviceMissing {
  /// Returns a new [BackupDeviceMissing] instance.
  BackupDeviceMissing({
    this.failures = const [],
    this.gone = const [],
  });

  List<BackupDeviceFailure> failures;

  List<BackupDeviceGone> gone;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupDeviceMissing &&
          _deepEquality.equals(other.failures, failures) &&
          _deepEquality.equals(other.gone, gone);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (failures.hashCode) + (gone.hashCode);

  @override
  String toString() => 'BackupDeviceMissing[failures=$failures, gone=$gone]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'failures'] = this.failures;
    json[r'gone'] = this.gone;
    return json;
  }

  /// Returns a new [BackupDeviceMissing] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BackupDeviceMissing? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "BackupDeviceMissing[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "BackupDeviceMissing[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return BackupDeviceMissing(
        failures: BackupDeviceFailure.listFromJson(json[r'failures']),
        gone: BackupDeviceGone.listFromJson(json[r'gone']),
      );
    }
    return null;
  }

  static List<BackupDeviceMissing> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <BackupDeviceMissing>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BackupDeviceMissing.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BackupDeviceMissing> mapFromJson(dynamic json) {
    final map = <String, BackupDeviceMissing>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BackupDeviceMissing.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BackupDeviceMissing-objects as value to a dart map
  static Map<String, List<BackupDeviceMissing>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<BackupDeviceMissing>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BackupDeviceMissing.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'failures',
    'gone',
  };
}

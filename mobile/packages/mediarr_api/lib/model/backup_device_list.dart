//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class BackupDeviceList {
  /// Returns a new [BackupDeviceList] instance.
  BackupDeviceList({
    this.devices = const [],
    required this.quietDays,
  });

  List<BackupDevice> devices;

  int quietDays;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupDeviceList &&
          _deepEquality.equals(other.devices, devices) &&
          other.quietDays == quietDays;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (devices.hashCode) + (quietDays.hashCode);

  @override
  String toString() =>
      'BackupDeviceList[devices=$devices, quietDays=$quietDays]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'devices'] = this.devices;
    json[r'quietDays'] = this.quietDays;
    return json;
  }

  /// Returns a new [BackupDeviceList] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BackupDeviceList? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "BackupDeviceList[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "BackupDeviceList[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return BackupDeviceList(
        devices: BackupDevice.listFromJson(json[r'devices']),
        quietDays: mapValueOfType<int>(json, r'quietDays')!,
      );
    }
    return null;
  }

  static List<BackupDeviceList> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <BackupDeviceList>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BackupDeviceList.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BackupDeviceList> mapFromJson(dynamic json) {
    final map = <String, BackupDeviceList>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BackupDeviceList.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BackupDeviceList-objects as value to a dart map
  static Map<String, List<BackupDeviceList>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<BackupDeviceList>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BackupDeviceList.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'devices',
    'quietDays',
  };
}

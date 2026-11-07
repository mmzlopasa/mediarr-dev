//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class BackupDeviceGone {
  /// Returns a new [BackupDeviceGone] instance.
  BackupDeviceGone({
    required this.checksum,
    required this.name,
    required this.inTrash,
  });

  String checksum;

  /// Known while it is in the trash
  String name;

  bool inTrash;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupDeviceGone &&
          other.checksum == checksum &&
          other.name == name &&
          other.inTrash == inTrash;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (checksum.hashCode) + (name.hashCode) + (inTrash.hashCode);

  @override
  String toString() =>
      'BackupDeviceGone[checksum=$checksum, name=$name, inTrash=$inTrash]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'checksum'] = this.checksum;
    json[r'name'] = this.name;
    json[r'inTrash'] = this.inTrash;
    return json;
  }

  /// Returns a new [BackupDeviceGone] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BackupDeviceGone? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "BackupDeviceGone[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "BackupDeviceGone[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return BackupDeviceGone(
        checksum: mapValueOfType<String>(json, r'checksum')!,
        name: mapValueOfType<String>(json, r'name')!,
        inTrash: mapValueOfType<bool>(json, r'inTrash')!,
      );
    }
    return null;
  }

  static List<BackupDeviceGone> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <BackupDeviceGone>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BackupDeviceGone.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BackupDeviceGone> mapFromJson(dynamic json) {
    final map = <String, BackupDeviceGone>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BackupDeviceGone.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BackupDeviceGone-objects as value to a dart map
  static Map<String, List<BackupDeviceGone>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<BackupDeviceGone>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BackupDeviceGone.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'checksum',
    'name',
    'inTrash',
  };
}

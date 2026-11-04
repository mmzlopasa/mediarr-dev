//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ServerStatus {
  /// Returns a new [ServerStatus] instance.
  ServerStatus({
    required this.version,
    this.latestVersion,
    required this.updateAvailable,
    required this.diskUsedBytes,
    required this.diskTotalBytes,
  });

  String version;

  /// Known only when the update check is on and has answered
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? latestVersion;

  bool updateAvailable;

  int diskUsedBytes;

  int diskTotalBytes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerStatus &&
          other.version == version &&
          other.latestVersion == latestVersion &&
          other.updateAvailable == updateAvailable &&
          other.diskUsedBytes == diskUsedBytes &&
          other.diskTotalBytes == diskTotalBytes;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (version.hashCode) +
      (latestVersion == null ? 0 : latestVersion!.hashCode) +
      (updateAvailable.hashCode) +
      (diskUsedBytes.hashCode) +
      (diskTotalBytes.hashCode);

  @override
  String toString() =>
      'ServerStatus[version=$version, latestVersion=$latestVersion, updateAvailable=$updateAvailable, diskUsedBytes=$diskUsedBytes, diskTotalBytes=$diskTotalBytes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'version'] = this.version;
    if (this.latestVersion != null) {
      json[r'latestVersion'] = this.latestVersion;
    } else {
      json[r'latestVersion'] = null;
    }
    json[r'updateAvailable'] = this.updateAvailable;
    json[r'diskUsedBytes'] = this.diskUsedBytes;
    json[r'diskTotalBytes'] = this.diskTotalBytes;
    return json;
  }

  /// Returns a new [ServerStatus] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ServerStatus? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ServerStatus[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ServerStatus[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ServerStatus(
        version: mapValueOfType<String>(json, r'version')!,
        latestVersion: mapValueOfType<String>(json, r'latestVersion'),
        updateAvailable: mapValueOfType<bool>(json, r'updateAvailable')!,
        diskUsedBytes: mapValueOfType<int>(json, r'diskUsedBytes')!,
        diskTotalBytes: mapValueOfType<int>(json, r'diskTotalBytes')!,
      );
    }
    return null;
  }

  static List<ServerStatus> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ServerStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ServerStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ServerStatus> mapFromJson(dynamic json) {
    final map = <String, ServerStatus>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ServerStatus.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ServerStatus-objects as value to a dart map
  static Map<String, List<ServerStatus>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ServerStatus>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ServerStatus.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'version',
    'updateAvailable',
    'diskUsedBytes',
    'diskTotalBytes',
  };
}

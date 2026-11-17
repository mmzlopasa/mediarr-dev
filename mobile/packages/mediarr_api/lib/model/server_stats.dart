//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ServerStats {
  /// Returns a new [ServerStats] instance.
  ServerStats({
    required this.photos,
    required this.videos,
    required this.usageBytes,
    required this.users,
    required this.processing,
    required this.failed,
    required this.diskTotalBytes,
    required this.diskFreeBytes,
    this.lastUploadAt,
    required this.version,
    this.jobs = const [],
  });

  int photos;

  int videos;

  /// Total size of all originals
  int usageBytes;

  int users;

  /// Files still being prepared
  int processing;

  /// Files that could not be processed
  int failed;

  int diskTotalBytes;

  int diskFreeBytes;

  /// When the newest file arrived; absent in an empty library
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? lastUploadAt;

  String version;

  /// One entry per queue of background work
  List<ServerStatsJobsInner> jobs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerStats &&
          other.photos == photos &&
          other.videos == videos &&
          other.usageBytes == usageBytes &&
          other.users == users &&
          other.processing == processing &&
          other.failed == failed &&
          other.diskTotalBytes == diskTotalBytes &&
          other.diskFreeBytes == diskFreeBytes &&
          other.lastUploadAt == lastUploadAt &&
          other.version == version &&
          _deepEquality.equals(other.jobs, jobs);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (photos.hashCode) +
      (videos.hashCode) +
      (usageBytes.hashCode) +
      (users.hashCode) +
      (processing.hashCode) +
      (failed.hashCode) +
      (diskTotalBytes.hashCode) +
      (diskFreeBytes.hashCode) +
      (lastUploadAt == null ? 0 : lastUploadAt!.hashCode) +
      (version.hashCode) +
      (jobs.hashCode);

  @override
  String toString() =>
      'ServerStats[photos=$photos, videos=$videos, usageBytes=$usageBytes, users=$users, processing=$processing, failed=$failed, diskTotalBytes=$diskTotalBytes, diskFreeBytes=$diskFreeBytes, lastUploadAt=$lastUploadAt, version=$version, jobs=$jobs]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'photos'] = this.photos;
    json[r'videos'] = this.videos;
    json[r'usageBytes'] = this.usageBytes;
    json[r'users'] = this.users;
    json[r'processing'] = this.processing;
    json[r'failed'] = this.failed;
    json[r'diskTotalBytes'] = this.diskTotalBytes;
    json[r'diskFreeBytes'] = this.diskFreeBytes;
    if (this.lastUploadAt != null) {
      json[r'lastUploadAt'] = this.lastUploadAt!.toUtc().toIso8601String();
    } else {
      json[r'lastUploadAt'] = null;
    }
    json[r'version'] = this.version;
    json[r'jobs'] = this.jobs;
    return json;
  }

  /// Returns a new [ServerStats] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ServerStats? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ServerStats[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ServerStats[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ServerStats(
        photos: mapValueOfType<int>(json, r'photos')!,
        videos: mapValueOfType<int>(json, r'videos')!,
        usageBytes: mapValueOfType<int>(json, r'usageBytes')!,
        users: mapValueOfType<int>(json, r'users')!,
        processing: mapValueOfType<int>(json, r'processing')!,
        failed: mapValueOfType<int>(json, r'failed')!,
        diskTotalBytes: mapValueOfType<int>(json, r'diskTotalBytes')!,
        diskFreeBytes: mapValueOfType<int>(json, r'diskFreeBytes')!,
        lastUploadAt: mapDateTime(json, r'lastUploadAt', r''),
        version: mapValueOfType<String>(json, r'version')!,
        jobs: ServerStatsJobsInner.listFromJson(json[r'jobs']),
      );
    }
    return null;
  }

  static List<ServerStats> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ServerStats>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ServerStats.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ServerStats> mapFromJson(dynamic json) {
    final map = <String, ServerStats>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ServerStats.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ServerStats-objects as value to a dart map
  static Map<String, List<ServerStats>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ServerStats>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ServerStats.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'photos',
    'videos',
    'usageBytes',
    'users',
    'processing',
    'failed',
    'diskTotalBytes',
    'diskFreeBytes',
    'version',
    'jobs',
  };
}

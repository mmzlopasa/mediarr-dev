//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AdminOverview {
  /// Returns a new [AdminOverview] instance.
  AdminOverview({
    required this.users,
    required this.photos,
    required this.videos,
    required this.processing,
    required this.failed,
    required this.libraryBytes,
    required this.diskTotalBytes,
    required this.diskFreeBytes,
    required this.jobs,
    required this.version,
    required this.databaseVersion,
  });

  int users;

  int photos;

  int videos;

  int processing;

  int failed;

  /// Total size of all originals
  int libraryBytes;

  int diskTotalBytes;

  int diskFreeBytes;

  AdminOverviewJobs jobs;

  String version;

  String databaseVersion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminOverview &&
          other.users == users &&
          other.photos == photos &&
          other.videos == videos &&
          other.processing == processing &&
          other.failed == failed &&
          other.libraryBytes == libraryBytes &&
          other.diskTotalBytes == diskTotalBytes &&
          other.diskFreeBytes == diskFreeBytes &&
          other.jobs == jobs &&
          other.version == version &&
          other.databaseVersion == databaseVersion;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (users.hashCode) +
      (photos.hashCode) +
      (videos.hashCode) +
      (processing.hashCode) +
      (failed.hashCode) +
      (libraryBytes.hashCode) +
      (diskTotalBytes.hashCode) +
      (diskFreeBytes.hashCode) +
      (jobs.hashCode) +
      (version.hashCode) +
      (databaseVersion.hashCode);

  @override
  String toString() =>
      'AdminOverview[users=$users, photos=$photos, videos=$videos, processing=$processing, failed=$failed, libraryBytes=$libraryBytes, diskTotalBytes=$diskTotalBytes, diskFreeBytes=$diskFreeBytes, jobs=$jobs, version=$version, databaseVersion=$databaseVersion]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'users'] = this.users;
    json[r'photos'] = this.photos;
    json[r'videos'] = this.videos;
    json[r'processing'] = this.processing;
    json[r'failed'] = this.failed;
    json[r'libraryBytes'] = this.libraryBytes;
    json[r'diskTotalBytes'] = this.diskTotalBytes;
    json[r'diskFreeBytes'] = this.diskFreeBytes;
    json[r'jobs'] = this.jobs;
    json[r'version'] = this.version;
    json[r'databaseVersion'] = this.databaseVersion;
    return json;
  }

  /// Returns a new [AdminOverview] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AdminOverview? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "AdminOverview[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "AdminOverview[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AdminOverview(
        users: mapValueOfType<int>(json, r'users')!,
        photos: mapValueOfType<int>(json, r'photos')!,
        videos: mapValueOfType<int>(json, r'videos')!,
        processing: mapValueOfType<int>(json, r'processing')!,
        failed: mapValueOfType<int>(json, r'failed')!,
        libraryBytes: mapValueOfType<int>(json, r'libraryBytes')!,
        diskTotalBytes: mapValueOfType<int>(json, r'diskTotalBytes')!,
        diskFreeBytes: mapValueOfType<int>(json, r'diskFreeBytes')!,
        jobs: AdminOverviewJobs.fromJson(json[r'jobs'])!,
        version: mapValueOfType<String>(json, r'version')!,
        databaseVersion: mapValueOfType<String>(json, r'databaseVersion')!,
      );
    }
    return null;
  }

  static List<AdminOverview> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AdminOverview>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdminOverview.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AdminOverview> mapFromJson(dynamic json) {
    final map = <String, AdminOverview>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AdminOverview.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AdminOverview-objects as value to a dart map
  static Map<String, List<AdminOverview>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<AdminOverview>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AdminOverview.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'users',
    'photos',
    'videos',
    'processing',
    'failed',
    'libraryBytes',
    'diskTotalBytes',
    'diskFreeBytes',
    'jobs',
    'version',
    'databaseVersion',
  };
}

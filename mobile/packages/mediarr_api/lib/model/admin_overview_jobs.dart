//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AdminOverviewJobs {
  /// Returns a new [AdminOverviewJobs] instance.
  AdminOverviewJobs({
    required this.queued,
    required this.running,
    required this.completed,
    required this.failed,
  });

  int queued;

  int running;

  int completed;

  int failed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminOverviewJobs &&
          other.queued == queued &&
          other.running == running &&
          other.completed == completed &&
          other.failed == failed;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (queued.hashCode) +
      (running.hashCode) +
      (completed.hashCode) +
      (failed.hashCode);

  @override
  String toString() =>
      'AdminOverviewJobs[queued=$queued, running=$running, completed=$completed, failed=$failed]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'queued'] = this.queued;
    json[r'running'] = this.running;
    json[r'completed'] = this.completed;
    json[r'failed'] = this.failed;
    return json;
  }

  /// Returns a new [AdminOverviewJobs] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AdminOverviewJobs? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "AdminOverviewJobs[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "AdminOverviewJobs[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AdminOverviewJobs(
        queued: mapValueOfType<int>(json, r'queued')!,
        running: mapValueOfType<int>(json, r'running')!,
        completed: mapValueOfType<int>(json, r'completed')!,
        failed: mapValueOfType<int>(json, r'failed')!,
      );
    }
    return null;
  }

  static List<AdminOverviewJobs> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AdminOverviewJobs>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdminOverviewJobs.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AdminOverviewJobs> mapFromJson(dynamic json) {
    final map = <String, AdminOverviewJobs>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AdminOverviewJobs.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AdminOverviewJobs-objects as value to a dart map
  static Map<String, List<AdminOverviewJobs>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<AdminOverviewJobs>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AdminOverviewJobs.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'queued',
    'running',
    'completed',
    'failed',
  };
}

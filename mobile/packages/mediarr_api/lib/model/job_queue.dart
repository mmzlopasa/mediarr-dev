//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class JobQueue {
  /// Returns a new [JobQueue] instance.
  JobQueue({
    required this.name,
    required this.paused,
    required this.queued,
    required this.running,
  });

  String name;

  bool paused;

  int queued;

  int running;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JobQueue &&
          other.name == name &&
          other.paused == paused &&
          other.queued == queued &&
          other.running == running;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (name.hashCode) +
      (paused.hashCode) +
      (queued.hashCode) +
      (running.hashCode);

  @override
  String toString() =>
      'JobQueue[name=$name, paused=$paused, queued=$queued, running=$running]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'name'] = this.name;
    json[r'paused'] = this.paused;
    json[r'queued'] = this.queued;
    json[r'running'] = this.running;
    return json;
  }

  /// Returns a new [JobQueue] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static JobQueue? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "JobQueue[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "JobQueue[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return JobQueue(
        name: mapValueOfType<String>(json, r'name')!,
        paused: mapValueOfType<bool>(json, r'paused')!,
        queued: mapValueOfType<int>(json, r'queued')!,
        running: mapValueOfType<int>(json, r'running')!,
      );
    }
    return null;
  }

  static List<JobQueue> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <JobQueue>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = JobQueue.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, JobQueue> mapFromJson(dynamic json) {
    final map = <String, JobQueue>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = JobQueue.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of JobQueue-objects as value to a dart map
  static Map<String, List<JobQueue>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<JobQueue>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = JobQueue.listFromJson(
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
    'paused',
    'queued',
    'running',
  };
}

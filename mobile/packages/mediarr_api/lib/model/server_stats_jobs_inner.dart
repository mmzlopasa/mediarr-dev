//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ServerStatsJobsInner {
  /// Returns a new [ServerStatsJobsInner] instance.
  ServerStatsJobsInner({
    required this.queue,
    required this.queued,
    required this.running,
    required this.failed,
  });

  String queue;

  int queued;

  int running;

  /// Jobs that gave up or were cancelled and are still kept
  int failed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerStatsJobsInner &&
          other.queue == queue &&
          other.queued == queued &&
          other.running == running &&
          other.failed == failed;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (queue.hashCode) +
      (queued.hashCode) +
      (running.hashCode) +
      (failed.hashCode);

  @override
  String toString() =>
      'ServerStatsJobsInner[queue=$queue, queued=$queued, running=$running, failed=$failed]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'queue'] = this.queue;
    json[r'queued'] = this.queued;
    json[r'running'] = this.running;
    json[r'failed'] = this.failed;
    return json;
  }

  /// Returns a new [ServerStatsJobsInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ServerStatsJobsInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ServerStatsJobsInner[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ServerStatsJobsInner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ServerStatsJobsInner(
        queue: mapValueOfType<String>(json, r'queue')!,
        queued: mapValueOfType<int>(json, r'queued')!,
        running: mapValueOfType<int>(json, r'running')!,
        failed: mapValueOfType<int>(json, r'failed')!,
      );
    }
    return null;
  }

  static List<ServerStatsJobsInner> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ServerStatsJobsInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ServerStatsJobsInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ServerStatsJobsInner> mapFromJson(dynamic json) {
    final map = <String, ServerStatsJobsInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ServerStatsJobsInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ServerStatsJobsInner-objects as value to a dart map
  static Map<String, List<ServerStatsJobsInner>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ServerStatsJobsInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ServerStatsJobsInner.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'queue',
    'queued',
    'running',
    'failed',
  };
}

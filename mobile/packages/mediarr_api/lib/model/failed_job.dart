//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class FailedJob {
  /// Returns a new [FailedJob] instance.
  FailedJob({
    required this.id,
    required this.kind,
    required this.queue,
    required this.error,
    required this.at,
  });

  int id;

  String kind;

  String queue;

  String error;

  DateTime at;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FailedJob &&
          other.id == id &&
          other.kind == kind &&
          other.queue == queue &&
          other.error == error &&
          other.at == at;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (kind.hashCode) +
      (queue.hashCode) +
      (error.hashCode) +
      (at.hashCode);

  @override
  String toString() =>
      'FailedJob[id=$id, kind=$kind, queue=$queue, error=$error, at=$at]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'kind'] = this.kind;
    json[r'queue'] = this.queue;
    json[r'error'] = this.error;
    json[r'at'] = this.at.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [FailedJob] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FailedJob? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "FailedJob[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "FailedJob[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return FailedJob(
        id: mapValueOfType<int>(json, r'id')!,
        kind: mapValueOfType<String>(json, r'kind')!,
        queue: mapValueOfType<String>(json, r'queue')!,
        error: mapValueOfType<String>(json, r'error')!,
        at: mapDateTime(json, r'at', r'')!,
      );
    }
    return null;
  }

  static List<FailedJob> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <FailedJob>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FailedJob.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FailedJob> mapFromJson(dynamic json) {
    final map = <String, FailedJob>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FailedJob.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FailedJob-objects as value to a dart map
  static Map<String, List<FailedJob>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<FailedJob>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FailedJob.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'kind',
    'queue',
    'error',
    'at',
  };
}

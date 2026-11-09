//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ResolveProgress {
  /// Returns a new [ResolveProgress] instance.
  ResolveProgress({
    required this.done,
    required this.total,
  });

  int done;

  int total;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResolveProgress && other.done == done && other.total == total;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (done.hashCode) + (total.hashCode);

  @override
  String toString() => 'ResolveProgress[done=$done, total=$total]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'done'] = this.done;
    json[r'total'] = this.total;
    return json;
  }

  /// Returns a new [ResolveProgress] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ResolveProgress? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ResolveProgress[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ResolveProgress[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ResolveProgress(
        done: mapValueOfType<int>(json, r'done')!,
        total: mapValueOfType<int>(json, r'total')!,
      );
    }
    return null;
  }

  static List<ResolveProgress> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ResolveProgress>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ResolveProgress.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ResolveProgress> mapFromJson(dynamic json) {
    final map = <String, ResolveProgress>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ResolveProgress.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ResolveProgress-objects as value to a dart map
  static Map<String, List<ResolveProgress>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ResolveProgress>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ResolveProgress.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'done',
    'total',
  };
}

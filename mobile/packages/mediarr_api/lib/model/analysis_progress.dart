//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AnalysisProgress {
  /// Returns a new [AnalysisProgress] instance.
  AnalysisProgress({
    required this.enabled,
    required this.total,
    required this.analyzed,
  });

  bool enabled;

  int total;

  int analyzed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalysisProgress &&
          other.enabled == enabled &&
          other.total == total &&
          other.analyzed == analyzed;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (enabled.hashCode) + (total.hashCode) + (analyzed.hashCode);

  @override
  String toString() =>
      'AnalysisProgress[enabled=$enabled, total=$total, analyzed=$analyzed]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'enabled'] = this.enabled;
    json[r'total'] = this.total;
    json[r'analyzed'] = this.analyzed;
    return json;
  }

  /// Returns a new [AnalysisProgress] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AnalysisProgress? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "AnalysisProgress[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "AnalysisProgress[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AnalysisProgress(
        enabled: mapValueOfType<bool>(json, r'enabled')!,
        total: mapValueOfType<int>(json, r'total')!,
        analyzed: mapValueOfType<int>(json, r'analyzed')!,
      );
    }
    return null;
  }

  static List<AnalysisProgress> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AnalysisProgress>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AnalysisProgress.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AnalysisProgress> mapFromJson(dynamic json) {
    final map = <String, AnalysisProgress>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AnalysisProgress.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AnalysisProgress-objects as value to a dart map
  static Map<String, List<AnalysisProgress>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<AnalysisProgress>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AnalysisProgress.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'enabled',
    'total',
    'analyzed',
  };
}

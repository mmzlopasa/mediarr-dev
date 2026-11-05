//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class IntegrityReport {
  /// Returns a new [IntegrityReport] instance.
  IntegrityReport({
    this.finishedAt,
    required this.checked,
    required this.thorough,
    required this.total,
    this.problems = const [],
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? finishedAt;

  int checked;

  bool thorough;

  int total;

  List<IntegrityProblem> problems;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntegrityReport &&
          other.finishedAt == finishedAt &&
          other.checked == checked &&
          other.thorough == thorough &&
          other.total == total &&
          _deepEquality.equals(other.problems, problems);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (finishedAt == null ? 0 : finishedAt!.hashCode) +
      (checked.hashCode) +
      (thorough.hashCode) +
      (total.hashCode) +
      (problems.hashCode);

  @override
  String toString() =>
      'IntegrityReport[finishedAt=$finishedAt, checked=$checked, thorough=$thorough, total=$total, problems=$problems]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.finishedAt != null) {
      json[r'finishedAt'] = this.finishedAt!.toUtc().toIso8601String();
    } else {
      json[r'finishedAt'] = null;
    }
    json[r'checked'] = this.checked;
    json[r'thorough'] = this.thorough;
    json[r'total'] = this.total;
    json[r'problems'] = this.problems;
    return json;
  }

  /// Returns a new [IntegrityReport] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static IntegrityReport? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "IntegrityReport[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "IntegrityReport[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return IntegrityReport(
        finishedAt: mapDateTime(json, r'finishedAt', r''),
        checked: mapValueOfType<int>(json, r'checked')!,
        thorough: mapValueOfType<bool>(json, r'thorough')!,
        total: mapValueOfType<int>(json, r'total')!,
        problems: IntegrityProblem.listFromJson(json[r'problems']),
      );
    }
    return null;
  }

  static List<IntegrityReport> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <IntegrityReport>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = IntegrityReport.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, IntegrityReport> mapFromJson(dynamic json) {
    final map = <String, IntegrityReport>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = IntegrityReport.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of IntegrityReport-objects as value to a dart map
  static Map<String, List<IntegrityReport>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<IntegrityReport>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = IntegrityReport.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'checked',
    'thorough',
    'total',
    'problems',
  };
}

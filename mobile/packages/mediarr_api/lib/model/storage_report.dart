//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class StorageReport {
  /// Returns a new [StorageReport] instance.
  StorageReport({
    required this.template,
    required this.dryRun,
    required this.running,
    required this.startedAt,
    this.finishedAt,
    required this.checked,
    required this.moved,
    required this.failed,
    this.samples = const [],
    this.errors = const [],
  });

  String template;

  bool dryRun;

  bool running;

  DateTime startedAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? finishedAt;

  int checked;

  /// Moved, or with dryRun would move
  int moved;

  int failed;

  List<StorageMove> samples;

  List<String> errors;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorageReport &&
          other.template == template &&
          other.dryRun == dryRun &&
          other.running == running &&
          other.startedAt == startedAt &&
          other.finishedAt == finishedAt &&
          other.checked == checked &&
          other.moved == moved &&
          other.failed == failed &&
          _deepEquality.equals(other.samples, samples) &&
          _deepEquality.equals(other.errors, errors);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (template.hashCode) +
      (dryRun.hashCode) +
      (running.hashCode) +
      (startedAt.hashCode) +
      (finishedAt == null ? 0 : finishedAt!.hashCode) +
      (checked.hashCode) +
      (moved.hashCode) +
      (failed.hashCode) +
      (samples.hashCode) +
      (errors.hashCode);

  @override
  String toString() =>
      'StorageReport[template=$template, dryRun=$dryRun, running=$running, startedAt=$startedAt, finishedAt=$finishedAt, checked=$checked, moved=$moved, failed=$failed, samples=$samples, errors=$errors]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'template'] = this.template;
    json[r'dryRun'] = this.dryRun;
    json[r'running'] = this.running;
    json[r'startedAt'] = this.startedAt.toUtc().toIso8601String();
    if (this.finishedAt != null) {
      json[r'finishedAt'] = this.finishedAt!.toUtc().toIso8601String();
    } else {
      json[r'finishedAt'] = null;
    }
    json[r'checked'] = this.checked;
    json[r'moved'] = this.moved;
    json[r'failed'] = this.failed;
    json[r'samples'] = this.samples;
    json[r'errors'] = this.errors;
    return json;
  }

  /// Returns a new [StorageReport] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static StorageReport? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "StorageReport[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "StorageReport[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return StorageReport(
        template: mapValueOfType<String>(json, r'template')!,
        dryRun: mapValueOfType<bool>(json, r'dryRun')!,
        running: mapValueOfType<bool>(json, r'running')!,
        startedAt: mapDateTime(json, r'startedAt', r'')!,
        finishedAt: mapDateTime(json, r'finishedAt', r''),
        checked: mapValueOfType<int>(json, r'checked')!,
        moved: mapValueOfType<int>(json, r'moved')!,
        failed: mapValueOfType<int>(json, r'failed')!,
        samples: StorageMove.listFromJson(json[r'samples']),
        errors: json[r'errors'] is Iterable
            ? (json[r'errors'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<StorageReport> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <StorageReport>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StorageReport.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, StorageReport> mapFromJson(dynamic json) {
    final map = <String, StorageReport>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = StorageReport.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of StorageReport-objects as value to a dart map
  static Map<String, List<StorageReport>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<StorageReport>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = StorageReport.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'template',
    'dryRun',
    'running',
    'startedAt',
    'checked',
    'moved',
    'failed',
    'samples',
    'errors',
  };
}

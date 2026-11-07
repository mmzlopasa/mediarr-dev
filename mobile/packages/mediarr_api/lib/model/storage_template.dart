//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class StorageTemplate {
  /// Returns a new [StorageTemplate] instance.
  StorageTemplate({
    required this.template,
    required this.defaultLayout,
    this.tokens = const [],
    this.report,
  });

  /// Empty: the layout originals have always had
  String template;

  String defaultLayout;

  List<StorageToken> tokens;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  StorageReport? report;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorageTemplate &&
          other.template == template &&
          other.defaultLayout == defaultLayout &&
          _deepEquality.equals(other.tokens, tokens) &&
          other.report == report;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (template.hashCode) +
      (defaultLayout.hashCode) +
      (tokens.hashCode) +
      (report == null ? 0 : report!.hashCode);

  @override
  String toString() =>
      'StorageTemplate[template=$template, defaultLayout=$defaultLayout, tokens=$tokens, report=$report]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'template'] = this.template;
    json[r'defaultLayout'] = this.defaultLayout;
    json[r'tokens'] = this.tokens;
    if (this.report != null) {
      json[r'report'] = this.report;
    } else {
      json[r'report'] = null;
    }
    return json;
  }

  /// Returns a new [StorageTemplate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static StorageTemplate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "StorageTemplate[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "StorageTemplate[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return StorageTemplate(
        template: mapValueOfType<String>(json, r'template')!,
        defaultLayout: mapValueOfType<String>(json, r'defaultLayout')!,
        tokens: StorageToken.listFromJson(json[r'tokens']),
        report: StorageReport.fromJson(json[r'report']),
      );
    }
    return null;
  }

  static List<StorageTemplate> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <StorageTemplate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StorageTemplate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, StorageTemplate> mapFromJson(dynamic json) {
    final map = <String, StorageTemplate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = StorageTemplate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of StorageTemplate-objects as value to a dart map
  static Map<String, List<StorageTemplate>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<StorageTemplate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = StorageTemplate.listFromJson(
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
    'defaultLayout',
    'tokens',
  };
}

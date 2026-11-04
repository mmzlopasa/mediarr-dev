//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Documents {
  /// Returns a new [Documents] instance.
  Documents({
    required this.enabled,
    required this.analysisOn,
    this.items = const [],
  });

  /// The administrator has turned this on
  bool enabled;

  /// Picture analysis runs, without which no text is read
  bool analysisOn;

  List<TimelineItem> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Documents &&
          other.enabled == enabled &&
          other.analysisOn == analysisOn &&
          _deepEquality.equals(other.items, items);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (enabled.hashCode) + (analysisOn.hashCode) + (items.hashCode);

  @override
  String toString() =>
      'Documents[enabled=$enabled, analysisOn=$analysisOn, items=$items]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'enabled'] = this.enabled;
    json[r'analysisOn'] = this.analysisOn;
    json[r'items'] = this.items;
    return json;
  }

  /// Returns a new [Documents] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Documents? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Documents[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Documents[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Documents(
        enabled: mapValueOfType<bool>(json, r'enabled')!,
        analysisOn: mapValueOfType<bool>(json, r'analysisOn')!,
        items: TimelineItem.listFromJson(json[r'items']),
      );
    }
    return null;
  }

  static List<Documents> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Documents>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Documents.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Documents> mapFromJson(dynamic json) {
    final map = <String, Documents>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Documents.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Documents-objects as value to a dart map
  static Map<String, List<Documents>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Documents>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Documents.listFromJson(
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
    'analysisOn',
    'items',
  };
}

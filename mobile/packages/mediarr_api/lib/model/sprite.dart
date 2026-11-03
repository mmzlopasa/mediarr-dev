//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Sprite {
  /// Returns a new [Sprite] instance.
  Sprite({
    required this.columns,
    required this.rows,
    required this.count,
    required this.intervalMs,
  });

  int columns;

  int rows;

  int count;

  int intervalMs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Sprite &&
          other.columns == columns &&
          other.rows == rows &&
          other.count == count &&
          other.intervalMs == intervalMs;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (columns.hashCode) +
      (rows.hashCode) +
      (count.hashCode) +
      (intervalMs.hashCode);

  @override
  String toString() =>
      'Sprite[columns=$columns, rows=$rows, count=$count, intervalMs=$intervalMs]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'columns'] = this.columns;
    json[r'rows'] = this.rows;
    json[r'count'] = this.count;
    json[r'intervalMs'] = this.intervalMs;
    return json;
  }

  /// Returns a new [Sprite] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Sprite? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Sprite[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Sprite[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Sprite(
        columns: mapValueOfType<int>(json, r'columns')!,
        rows: mapValueOfType<int>(json, r'rows')!,
        count: mapValueOfType<int>(json, r'count')!,
        intervalMs: mapValueOfType<int>(json, r'intervalMs')!,
      );
    }
    return null;
  }

  static List<Sprite> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Sprite>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Sprite.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Sprite> mapFromJson(dynamic json) {
    final map = <String, Sprite>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Sprite.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Sprite-objects as value to a dart map
  static Map<String, List<Sprite>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Sprite>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Sprite.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'columns',
    'rows',
    'count',
    'intervalMs',
  };
}

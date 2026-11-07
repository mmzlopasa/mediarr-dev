//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class StorageMove {
  /// Returns a new [StorageMove] instance.
  StorageMove({
    required this.from,
    required this.to,
  });

  String from;

  String to;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorageMove && other.from == from && other.to == to;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (from.hashCode) + (to.hashCode);

  @override
  String toString() => 'StorageMove[from=$from, to=$to]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'from'] = this.from;
    json[r'to'] = this.to;
    return json;
  }

  /// Returns a new [StorageMove] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static StorageMove? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "StorageMove[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "StorageMove[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return StorageMove(
        from: mapValueOfType<String>(json, r'from')!,
        to: mapValueOfType<String>(json, r'to')!,
      );
    }
    return null;
  }

  static List<StorageMove> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <StorageMove>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StorageMove.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, StorageMove> mapFromJson(dynamic json) {
    final map = <String, StorageMove>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = StorageMove.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of StorageMove-objects as value to a dart map
  static Map<String, List<StorageMove>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<StorageMove>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = StorageMove.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'from',
    'to',
  };
}

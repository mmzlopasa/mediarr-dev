//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Passkey {
  /// Returns a new [Passkey] instance.
  Passkey({
    required this.id,
    required this.name,
    required this.createdAt,
    this.lastUsedAt,
  });

  String id;

  String name;

  DateTime createdAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? lastUsedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Passkey &&
          other.id == id &&
          other.name == name &&
          other.createdAt == createdAt &&
          other.lastUsedAt == lastUsedAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (name.hashCode) +
      (createdAt.hashCode) +
      (lastUsedAt == null ? 0 : lastUsedAt!.hashCode);

  @override
  String toString() =>
      'Passkey[id=$id, name=$name, createdAt=$createdAt, lastUsedAt=$lastUsedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'name'] = this.name;
    json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    if (this.lastUsedAt != null) {
      json[r'lastUsedAt'] = this.lastUsedAt!.toUtc().toIso8601String();
    } else {
      json[r'lastUsedAt'] = null;
    }
    return json;
  }

  /// Returns a new [Passkey] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Passkey? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Passkey[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Passkey[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Passkey(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        lastUsedAt: mapDateTime(json, r'lastUsedAt', r''),
      );
    }
    return null;
  }

  static List<Passkey> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Passkey>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Passkey.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Passkey> mapFromJson(dynamic json) {
    final map = <String, Passkey>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Passkey.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Passkey-objects as value to a dart map
  static Map<String, List<Passkey>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Passkey>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Passkey.listFromJson(
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
    'name',
    'createdAt',
  };
}

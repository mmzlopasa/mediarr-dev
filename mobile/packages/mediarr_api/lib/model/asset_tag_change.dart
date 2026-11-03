//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AssetTagChange {
  /// Returns a new [AssetTagChange] instance.
  AssetTagChange({
    this.ids = const [],
    required this.name,
    this.remove = false,
  });

  List<String> ids;

  String name;

  bool remove;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetTagChange &&
          _deepEquality.equals(other.ids, ids) &&
          other.name == name &&
          other.remove == remove;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (ids.hashCode) + (name.hashCode) + (remove.hashCode);

  @override
  String toString() => 'AssetTagChange[ids=$ids, name=$name, remove=$remove]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'ids'] = this.ids;
    json[r'name'] = this.name;
    json[r'remove'] = this.remove;
    return json;
  }

  /// Returns a new [AssetTagChange] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AssetTagChange? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "AssetTagChange[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "AssetTagChange[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AssetTagChange(
        ids: json[r'ids'] is Iterable
            ? (json[r'ids'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        name: mapValueOfType<String>(json, r'name')!,
        remove: mapValueOfType<bool>(json, r'remove') ?? false,
      );
    }
    return null;
  }

  static List<AssetTagChange> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AssetTagChange>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AssetTagChange.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AssetTagChange> mapFromJson(dynamic json) {
    final map = <String, AssetTagChange>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AssetTagChange.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AssetTagChange-objects as value to a dart map
  static Map<String, List<AssetTagChange>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<AssetTagChange>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AssetTagChange.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'ids',
    'name',
  };
}

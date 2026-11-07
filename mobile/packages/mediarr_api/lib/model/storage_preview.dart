//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class StoragePreview {
  /// Returns a new [StoragePreview] instance.
  StoragePreview({
    required this.name,
    required this.path,
  });

  String name;

  /// Inside the owner's folder
  String path;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoragePreview && other.name == name && other.path == path;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (name.hashCode) + (path.hashCode);

  @override
  String toString() => 'StoragePreview[name=$name, path=$path]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'name'] = this.name;
    json[r'path'] = this.path;
    return json;
  }

  /// Returns a new [StoragePreview] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static StoragePreview? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "StoragePreview[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "StoragePreview[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return StoragePreview(
        name: mapValueOfType<String>(json, r'name')!,
        path: mapValueOfType<String>(json, r'path')!,
      );
    }
    return null;
  }

  static List<StoragePreview> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <StoragePreview>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StoragePreview.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, StoragePreview> mapFromJson(dynamic json) {
    final map = <String, StoragePreview>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = StoragePreview.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of StoragePreview-objects as value to a dart map
  static Map<String, List<StoragePreview>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<StoragePreview>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = StoragePreview.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'path',
  };
}

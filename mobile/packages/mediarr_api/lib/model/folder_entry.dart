//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class FolderEntry {
  /// Returns a new [FolderEntry] instance.
  FolderEntry({
    required this.name,
    required this.count,
    required this.coverId,
  });

  String name;

  /// Photos anywhere inside it
  int count;

  String coverId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FolderEntry &&
          other.name == name &&
          other.count == count &&
          other.coverId == coverId;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (name.hashCode) + (count.hashCode) + (coverId.hashCode);

  @override
  String toString() =>
      'FolderEntry[name=$name, count=$count, coverId=$coverId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'name'] = this.name;
    json[r'count'] = this.count;
    json[r'coverId'] = this.coverId;
    return json;
  }

  /// Returns a new [FolderEntry] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FolderEntry? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "FolderEntry[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "FolderEntry[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return FolderEntry(
        name: mapValueOfType<String>(json, r'name')!,
        count: mapValueOfType<int>(json, r'count')!,
        coverId: mapValueOfType<String>(json, r'coverId')!,
      );
    }
    return null;
  }

  static List<FolderEntry> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <FolderEntry>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FolderEntry.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FolderEntry> mapFromJson(dynamic json) {
    final map = <String, FolderEntry>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FolderEntry.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FolderEntry-objects as value to a dart map
  static Map<String, List<FolderEntry>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<FolderEntry>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FolderEntry.listFromJson(
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
    'count',
    'coverId',
  };
}

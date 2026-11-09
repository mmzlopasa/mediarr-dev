//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LibraryExportPart {
  /// Returns a new [LibraryExportPart] instance.
  LibraryExportPart({
    required this.number,
    required this.size,
    required this.files,
  });

  int number;

  int size;

  /// Originals in it
  int files;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LibraryExportPart &&
          other.number == number &&
          other.size == size &&
          other.files == files;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (number.hashCode) + (size.hashCode) + (files.hashCode);

  @override
  String toString() =>
      'LibraryExportPart[number=$number, size=$size, files=$files]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'number'] = this.number;
    json[r'size'] = this.size;
    json[r'files'] = this.files;
    return json;
  }

  /// Returns a new [LibraryExportPart] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LibraryExportPart? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "LibraryExportPart[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "LibraryExportPart[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return LibraryExportPart(
        number: mapValueOfType<int>(json, r'number')!,
        size: mapValueOfType<int>(json, r'size')!,
        files: mapValueOfType<int>(json, r'files')!,
      );
    }
    return null;
  }

  static List<LibraryExportPart> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <LibraryExportPart>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LibraryExportPart.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LibraryExportPart> mapFromJson(dynamic json) {
    final map = <String, LibraryExportPart>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LibraryExportPart.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LibraryExportPart-objects as value to a dart map
  static Map<String, List<LibraryExportPart>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<LibraryExportPart>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LibraryExportPart.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'number',
    'size',
    'files',
  };
}

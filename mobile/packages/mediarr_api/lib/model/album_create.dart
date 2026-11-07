//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AlbumCreate {
  /// Returns a new [AlbumCreate] instance.
  AlbumCreate({
    required this.title,
    this.parentId,
    this.description,
    this.rules,
  });

  String title;

  /// Make it inside this album, which must be one's own
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? parentId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? description;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  AlbumRules? rules;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlbumCreate &&
          other.title == title &&
          other.parentId == parentId &&
          other.description == description &&
          other.rules == rules;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (title.hashCode) +
      (parentId == null ? 0 : parentId!.hashCode) +
      (description == null ? 0 : description!.hashCode) +
      (rules == null ? 0 : rules!.hashCode);

  @override
  String toString() =>
      'AlbumCreate[title=$title, parentId=$parentId, description=$description, rules=$rules]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'title'] = this.title;
    if (this.parentId != null) {
      json[r'parentId'] = this.parentId;
    } else {
      json[r'parentId'] = null;
    }
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
    if (this.rules != null) {
      json[r'rules'] = this.rules;
    } else {
      json[r'rules'] = null;
    }
    return json;
  }

  /// Returns a new [AlbumCreate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AlbumCreate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "AlbumCreate[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "AlbumCreate[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AlbumCreate(
        title: mapValueOfType<String>(json, r'title')!,
        parentId: mapValueOfType<String>(json, r'parentId'),
        description: mapValueOfType<String>(json, r'description'),
        rules: AlbumRules.fromJson(json[r'rules']),
      );
    }
    return null;
  }

  static List<AlbumCreate> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AlbumCreate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AlbumCreate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AlbumCreate> mapFromJson(dynamic json) {
    final map = <String, AlbumCreate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AlbumCreate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AlbumCreate-objects as value to a dart map
  static Map<String, List<AlbumCreate>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<AlbumCreate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AlbumCreate.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'title',
  };
}

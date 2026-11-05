//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AssetFacts {
  /// Returns a new [AssetFacts] instance.
  AssetFacts({
    this.takenAt,
    this.latitude,
    this.longitude,
    this.caption,
    this.rating,
    this.useFile,
  });

  /// RFC 3339 with the offset of where it was taken
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? takenAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? latitude;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? longitude;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? caption;

  /// 0 to 5 stars; 0 is none
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? rating;

  /// Forget the date and location set by hand and read the file again
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? useFile;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetFacts &&
          other.takenAt == takenAt &&
          other.latitude == latitude &&
          other.longitude == longitude &&
          other.caption == caption &&
          other.rating == rating &&
          other.useFile == useFile;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (takenAt == null ? 0 : takenAt!.hashCode) +
      (latitude == null ? 0 : latitude!.hashCode) +
      (longitude == null ? 0 : longitude!.hashCode) +
      (caption == null ? 0 : caption!.hashCode) +
      (rating == null ? 0 : rating!.hashCode) +
      (useFile == null ? 0 : useFile!.hashCode);

  @override
  String toString() =>
      'AssetFacts[takenAt=$takenAt, latitude=$latitude, longitude=$longitude, caption=$caption, rating=$rating, useFile=$useFile]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.takenAt != null) {
      json[r'takenAt'] = this.takenAt;
    } else {
      json[r'takenAt'] = null;
    }
    if (this.latitude != null) {
      json[r'latitude'] = this.latitude;
    } else {
      json[r'latitude'] = null;
    }
    if (this.longitude != null) {
      json[r'longitude'] = this.longitude;
    } else {
      json[r'longitude'] = null;
    }
    if (this.caption != null) {
      json[r'caption'] = this.caption;
    } else {
      json[r'caption'] = null;
    }
    if (this.rating != null) {
      json[r'rating'] = this.rating;
    } else {
      json[r'rating'] = null;
    }
    if (this.useFile != null) {
      json[r'useFile'] = this.useFile;
    } else {
      json[r'useFile'] = null;
    }
    return json;
  }

  /// Returns a new [AssetFacts] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AssetFacts? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "AssetFacts[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "AssetFacts[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AssetFacts(
        takenAt: mapValueOfType<String>(json, r'takenAt'),
        latitude: mapValueOfType<double>(json, r'latitude'),
        longitude: mapValueOfType<double>(json, r'longitude'),
        caption: mapValueOfType<String>(json, r'caption'),
        rating: mapValueOfType<int>(json, r'rating'),
        useFile: mapValueOfType<bool>(json, r'useFile'),
      );
    }
    return null;
  }

  static List<AssetFacts> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AssetFacts>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AssetFacts.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AssetFacts> mapFromJson(dynamic json) {
    final map = <String, AssetFacts>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AssetFacts.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AssetFacts-objects as value to a dart map
  static Map<String, List<AssetFacts>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<AssetFacts>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AssetFacts.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{};
}

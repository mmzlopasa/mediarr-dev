//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AssetEdits {
  /// Returns a new [AssetEdits] instance.
  AssetEdits({
    this.rotate,
    this.crop,
    this.brightness,
    this.contrast,
    this.saturation,
  });

  /// Clockwise: 0, 90, 180 or 270
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? rotate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  CropBox? crop;

  /// Minimum value: -100
  /// Maximum value: 100
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? brightness;

  /// Minimum value: -100
  /// Maximum value: 100
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? contrast;

  /// Minimum value: -100
  /// Maximum value: 100
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? saturation;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetEdits &&
          other.rotate == rotate &&
          other.crop == crop &&
          other.brightness == brightness &&
          other.contrast == contrast &&
          other.saturation == saturation;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (rotate == null ? 0 : rotate!.hashCode) +
      (crop == null ? 0 : crop!.hashCode) +
      (brightness == null ? 0 : brightness!.hashCode) +
      (contrast == null ? 0 : contrast!.hashCode) +
      (saturation == null ? 0 : saturation!.hashCode);

  @override
  String toString() =>
      'AssetEdits[rotate=$rotate, crop=$crop, brightness=$brightness, contrast=$contrast, saturation=$saturation]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.rotate != null) {
      json[r'rotate'] = this.rotate;
    } else {
      json[r'rotate'] = null;
    }
    if (this.crop != null) {
      json[r'crop'] = this.crop;
    } else {
      json[r'crop'] = null;
    }
    if (this.brightness != null) {
      json[r'brightness'] = this.brightness;
    } else {
      json[r'brightness'] = null;
    }
    if (this.contrast != null) {
      json[r'contrast'] = this.contrast;
    } else {
      json[r'contrast'] = null;
    }
    if (this.saturation != null) {
      json[r'saturation'] = this.saturation;
    } else {
      json[r'saturation'] = null;
    }
    return json;
  }

  /// Returns a new [AssetEdits] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AssetEdits? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "AssetEdits[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "AssetEdits[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AssetEdits(
        rotate: mapValueOfType<int>(json, r'rotate'),
        crop: CropBox.fromJson(json[r'crop']),
        brightness: mapValueOfType<int>(json, r'brightness'),
        contrast: mapValueOfType<int>(json, r'contrast'),
        saturation: mapValueOfType<int>(json, r'saturation'),
      );
    }
    return null;
  }

  static List<AssetEdits> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AssetEdits>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AssetEdits.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AssetEdits> mapFromJson(dynamic json) {
    final map = <String, AssetEdits>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AssetEdits.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AssetEdits-objects as value to a dart map
  static Map<String, List<AssetEdits>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<AssetEdits>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AssetEdits.listFromJson(
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

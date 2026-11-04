//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PublicLink {
  /// Returns a new [PublicLink] instance.
  PublicLink({
    required this.locked,
    this.title,
    this.description,
    required this.allowDownload,
    required this.allowUpload,
    required this.uploadOnly,
    required this.watermarked,
    required this.kiosk,
  });

  /// A password is needed first. Nothing else is told until then.
  bool locked;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? title;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? description;

  bool allowDownload;

  bool allowUpload;

  bool uploadOnly;

  bool watermarked;

  /// This server allows this link as a slideshow
  bool kiosk;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicLink &&
          other.locked == locked &&
          other.title == title &&
          other.description == description &&
          other.allowDownload == allowDownload &&
          other.allowUpload == allowUpload &&
          other.uploadOnly == uploadOnly &&
          other.watermarked == watermarked &&
          other.kiosk == kiosk;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (locked.hashCode) +
      (title == null ? 0 : title!.hashCode) +
      (description == null ? 0 : description!.hashCode) +
      (allowDownload.hashCode) +
      (allowUpload.hashCode) +
      (uploadOnly.hashCode) +
      (watermarked.hashCode) +
      (kiosk.hashCode);

  @override
  String toString() =>
      'PublicLink[locked=$locked, title=$title, description=$description, allowDownload=$allowDownload, allowUpload=$allowUpload, uploadOnly=$uploadOnly, watermarked=$watermarked, kiosk=$kiosk]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'locked'] = this.locked;
    if (this.title != null) {
      json[r'title'] = this.title;
    } else {
      json[r'title'] = null;
    }
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
    json[r'allowDownload'] = this.allowDownload;
    json[r'allowUpload'] = this.allowUpload;
    json[r'uploadOnly'] = this.uploadOnly;
    json[r'watermarked'] = this.watermarked;
    json[r'kiosk'] = this.kiosk;
    return json;
  }

  /// Returns a new [PublicLink] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PublicLink? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "PublicLink[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "PublicLink[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PublicLink(
        locked: mapValueOfType<bool>(json, r'locked')!,
        title: mapValueOfType<String>(json, r'title'),
        description: mapValueOfType<String>(json, r'description'),
        allowDownload: mapValueOfType<bool>(json, r'allowDownload')!,
        allowUpload: mapValueOfType<bool>(json, r'allowUpload')!,
        uploadOnly: mapValueOfType<bool>(json, r'uploadOnly')!,
        watermarked: mapValueOfType<bool>(json, r'watermarked')!,
        kiosk: mapValueOfType<bool>(json, r'kiosk')!,
      );
    }
    return null;
  }

  static List<PublicLink> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PublicLink>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PublicLink.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PublicLink> mapFromJson(dynamic json) {
    final map = <String, PublicLink>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PublicLink.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PublicLink-objects as value to a dart map
  static Map<String, List<PublicLink>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PublicLink>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PublicLink.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'locked',
    'allowDownload',
    'allowUpload',
    'uploadOnly',
    'watermarked',
    'kiosk',
  };
}

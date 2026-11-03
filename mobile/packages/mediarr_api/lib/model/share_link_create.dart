//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ShareLinkCreate {
  /// Returns a new [ShareLinkCreate] instance.
  ShareLinkCreate({
    this.label,
    this.password,
    this.expiresAt,
    this.downloadLimit,
    this.allowDownload = true,
    this.allowUpload = false,
    this.uploadOnly = false,
    this.showLocation = false,
    this.watermark,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? label;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? password;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? expiresAt;

  /// Minimum value: 1
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? downloadLimit;

  bool allowDownload;

  bool allowUpload;

  bool uploadOnly;

  bool showLocation;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? watermark;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShareLinkCreate &&
          other.label == label &&
          other.password == password &&
          other.expiresAt == expiresAt &&
          other.downloadLimit == downloadLimit &&
          other.allowDownload == allowDownload &&
          other.allowUpload == allowUpload &&
          other.uploadOnly == uploadOnly &&
          other.showLocation == showLocation &&
          other.watermark == watermark;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (label == null ? 0 : label!.hashCode) +
      (password == null ? 0 : password!.hashCode) +
      (expiresAt == null ? 0 : expiresAt!.hashCode) +
      (downloadLimit == null ? 0 : downloadLimit!.hashCode) +
      (allowDownload.hashCode) +
      (allowUpload.hashCode) +
      (uploadOnly.hashCode) +
      (showLocation.hashCode) +
      (watermark == null ? 0 : watermark!.hashCode);

  @override
  String toString() =>
      'ShareLinkCreate[label=$label, password=$password, expiresAt=$expiresAt, downloadLimit=$downloadLimit, allowDownload=$allowDownload, allowUpload=$allowUpload, uploadOnly=$uploadOnly, showLocation=$showLocation, watermark=$watermark]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.label != null) {
      json[r'label'] = this.label;
    } else {
      json[r'label'] = null;
    }
    if (this.password != null) {
      json[r'password'] = this.password;
    } else {
      json[r'password'] = null;
    }
    if (this.expiresAt != null) {
      json[r'expiresAt'] = this.expiresAt!.toUtc().toIso8601String();
    } else {
      json[r'expiresAt'] = null;
    }
    if (this.downloadLimit != null) {
      json[r'downloadLimit'] = this.downloadLimit;
    } else {
      json[r'downloadLimit'] = null;
    }
    json[r'allowDownload'] = this.allowDownload;
    json[r'allowUpload'] = this.allowUpload;
    json[r'uploadOnly'] = this.uploadOnly;
    json[r'showLocation'] = this.showLocation;
    if (this.watermark != null) {
      json[r'watermark'] = this.watermark;
    } else {
      json[r'watermark'] = null;
    }
    return json;
  }

  /// Returns a new [ShareLinkCreate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ShareLinkCreate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ShareLinkCreate[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ShareLinkCreate[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ShareLinkCreate(
        label: mapValueOfType<String>(json, r'label'),
        password: mapValueOfType<String>(json, r'password'),
        expiresAt: mapDateTime(json, r'expiresAt', r''),
        downloadLimit: mapValueOfType<int>(json, r'downloadLimit'),
        allowDownload: mapValueOfType<bool>(json, r'allowDownload') ?? true,
        allowUpload: mapValueOfType<bool>(json, r'allowUpload') ?? false,
        uploadOnly: mapValueOfType<bool>(json, r'uploadOnly') ?? false,
        showLocation: mapValueOfType<bool>(json, r'showLocation') ?? false,
        watermark: mapValueOfType<String>(json, r'watermark'),
      );
    }
    return null;
  }

  static List<ShareLinkCreate> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShareLinkCreate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShareLinkCreate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ShareLinkCreate> mapFromJson(dynamic json) {
    final map = <String, ShareLinkCreate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShareLinkCreate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ShareLinkCreate-objects as value to a dart map
  static Map<String, List<ShareLinkCreate>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ShareLinkCreate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ShareLinkCreate.listFromJson(
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

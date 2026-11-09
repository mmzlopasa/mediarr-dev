//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ShareLink {
  /// Returns a new [ShareLink] instance.
  ShareLink({
    required this.id,
    this.token,
    required this.label,
    required this.hasPassword,
    this.expiresAt,
    this.downloadLimit,
    required this.downloadCount,
    required this.allowDownload,
    required this.allowUpload,
    required this.uploadOnly,
    required this.showLocation,
    this.watermark,
    required this.createdAt,
    this.hideFaces,
    this.visiblePeople = const [],
    this.stripCamera,
    this.stripDate,
    this.askName,
    this.visits,
    this.lastVisitAt,
  });

  String id;

  /// Returned only when the link is created
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? token;

  String label;

  bool hasPassword;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? expiresAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? downloadLimit;

  int downloadCount;

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

  DateTime createdAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  HideFaces? hideFaces;

  /// With hideFaces except: the people who stay visible
  List<String> visiblePeople;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? stripCamera;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? stripDate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? askName;

  /// Times it was opened in the last 90 days
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? visits;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? lastVisitAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShareLink &&
          other.id == id &&
          other.token == token &&
          other.label == label &&
          other.hasPassword == hasPassword &&
          other.expiresAt == expiresAt &&
          other.downloadLimit == downloadLimit &&
          other.downloadCount == downloadCount &&
          other.allowDownload == allowDownload &&
          other.allowUpload == allowUpload &&
          other.uploadOnly == uploadOnly &&
          other.showLocation == showLocation &&
          other.watermark == watermark &&
          other.createdAt == createdAt &&
          other.hideFaces == hideFaces &&
          _deepEquality.equals(other.visiblePeople, visiblePeople) &&
          other.stripCamera == stripCamera &&
          other.stripDate == stripDate &&
          other.askName == askName &&
          other.visits == visits &&
          other.lastVisitAt == lastVisitAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (token == null ? 0 : token!.hashCode) +
      (label.hashCode) +
      (hasPassword.hashCode) +
      (expiresAt == null ? 0 : expiresAt!.hashCode) +
      (downloadLimit == null ? 0 : downloadLimit!.hashCode) +
      (downloadCount.hashCode) +
      (allowDownload.hashCode) +
      (allowUpload.hashCode) +
      (uploadOnly.hashCode) +
      (showLocation.hashCode) +
      (watermark == null ? 0 : watermark!.hashCode) +
      (createdAt.hashCode) +
      (hideFaces == null ? 0 : hideFaces!.hashCode) +
      (visiblePeople.hashCode) +
      (stripCamera == null ? 0 : stripCamera!.hashCode) +
      (stripDate == null ? 0 : stripDate!.hashCode) +
      (askName == null ? 0 : askName!.hashCode) +
      (visits == null ? 0 : visits!.hashCode) +
      (lastVisitAt == null ? 0 : lastVisitAt!.hashCode);

  @override
  String toString() =>
      'ShareLink[id=$id, token=$token, label=$label, hasPassword=$hasPassword, expiresAt=$expiresAt, downloadLimit=$downloadLimit, downloadCount=$downloadCount, allowDownload=$allowDownload, allowUpload=$allowUpload, uploadOnly=$uploadOnly, showLocation=$showLocation, watermark=$watermark, createdAt=$createdAt, hideFaces=$hideFaces, visiblePeople=$visiblePeople, stripCamera=$stripCamera, stripDate=$stripDate, askName=$askName, visits=$visits, lastVisitAt=$lastVisitAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    if (this.token != null) {
      json[r'token'] = this.token;
    } else {
      json[r'token'] = null;
    }
    json[r'label'] = this.label;
    json[r'hasPassword'] = this.hasPassword;
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
    json[r'downloadCount'] = this.downloadCount;
    json[r'allowDownload'] = this.allowDownload;
    json[r'allowUpload'] = this.allowUpload;
    json[r'uploadOnly'] = this.uploadOnly;
    json[r'showLocation'] = this.showLocation;
    if (this.watermark != null) {
      json[r'watermark'] = this.watermark;
    } else {
      json[r'watermark'] = null;
    }
    json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    if (this.hideFaces != null) {
      json[r'hideFaces'] = this.hideFaces;
    } else {
      json[r'hideFaces'] = null;
    }
    json[r'visiblePeople'] = this.visiblePeople;
    if (this.stripCamera != null) {
      json[r'stripCamera'] = this.stripCamera;
    } else {
      json[r'stripCamera'] = null;
    }
    if (this.stripDate != null) {
      json[r'stripDate'] = this.stripDate;
    } else {
      json[r'stripDate'] = null;
    }
    if (this.askName != null) {
      json[r'askName'] = this.askName;
    } else {
      json[r'askName'] = null;
    }
    if (this.visits != null) {
      json[r'visits'] = this.visits;
    } else {
      json[r'visits'] = null;
    }
    if (this.lastVisitAt != null) {
      json[r'lastVisitAt'] = this.lastVisitAt!.toUtc().toIso8601String();
    } else {
      json[r'lastVisitAt'] = null;
    }
    return json;
  }

  /// Returns a new [ShareLink] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ShareLink? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ShareLink[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ShareLink[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ShareLink(
        id: mapValueOfType<String>(json, r'id')!,
        token: mapValueOfType<String>(json, r'token'),
        label: mapValueOfType<String>(json, r'label')!,
        hasPassword: mapValueOfType<bool>(json, r'hasPassword')!,
        expiresAt: mapDateTime(json, r'expiresAt', r''),
        downloadLimit: mapValueOfType<int>(json, r'downloadLimit'),
        downloadCount: mapValueOfType<int>(json, r'downloadCount')!,
        allowDownload: mapValueOfType<bool>(json, r'allowDownload')!,
        allowUpload: mapValueOfType<bool>(json, r'allowUpload')!,
        uploadOnly: mapValueOfType<bool>(json, r'uploadOnly')!,
        showLocation: mapValueOfType<bool>(json, r'showLocation')!,
        watermark: mapValueOfType<String>(json, r'watermark'),
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        hideFaces: HideFaces.fromJson(json[r'hideFaces']),
        visiblePeople: json[r'visiblePeople'] is Iterable
            ? (json[r'visiblePeople'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        stripCamera: mapValueOfType<bool>(json, r'stripCamera'),
        stripDate: mapValueOfType<bool>(json, r'stripDate'),
        askName: mapValueOfType<bool>(json, r'askName'),
        visits: mapValueOfType<int>(json, r'visits'),
        lastVisitAt: mapDateTime(json, r'lastVisitAt', r''),
      );
    }
    return null;
  }

  static List<ShareLink> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShareLink>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShareLink.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ShareLink> mapFromJson(dynamic json) {
    final map = <String, ShareLink>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShareLink.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ShareLink-objects as value to a dart map
  static Map<String, List<ShareLink>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ShareLink>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ShareLink.listFromJson(
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
    'label',
    'hasPassword',
    'downloadCount',
    'allowDownload',
    'allowUpload',
    'uploadOnly',
    'showLocation',
    'createdAt',
  };
}

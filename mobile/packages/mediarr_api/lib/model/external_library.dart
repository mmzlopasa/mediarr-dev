//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ExternalLibrary {
  /// Returns a new [ExternalLibrary] instance.
  ExternalLibrary({
    required this.available,
    this.ownerId,
    required this.assets,
    required this.missing,
    required this.scanning,
    this.scanFinishedAt,
    this.scanError,
  });

  /// A folder was given in .env and can be read
  bool available;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? ownerId;

  int assets;

  /// Records whose file was not found. They are kept
  int missing;

  bool scanning;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? scanFinishedAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? scanError;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExternalLibrary &&
          other.available == available &&
          other.ownerId == ownerId &&
          other.assets == assets &&
          other.missing == missing &&
          other.scanning == scanning &&
          other.scanFinishedAt == scanFinishedAt &&
          other.scanError == scanError;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (available.hashCode) +
      (ownerId == null ? 0 : ownerId!.hashCode) +
      (assets.hashCode) +
      (missing.hashCode) +
      (scanning.hashCode) +
      (scanFinishedAt == null ? 0 : scanFinishedAt!.hashCode) +
      (scanError == null ? 0 : scanError!.hashCode);

  @override
  String toString() =>
      'ExternalLibrary[available=$available, ownerId=$ownerId, assets=$assets, missing=$missing, scanning=$scanning, scanFinishedAt=$scanFinishedAt, scanError=$scanError]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'available'] = this.available;
    if (this.ownerId != null) {
      json[r'ownerId'] = this.ownerId;
    } else {
      json[r'ownerId'] = null;
    }
    json[r'assets'] = this.assets;
    json[r'missing'] = this.missing;
    json[r'scanning'] = this.scanning;
    if (this.scanFinishedAt != null) {
      json[r'scanFinishedAt'] = this.scanFinishedAt!.toUtc().toIso8601String();
    } else {
      json[r'scanFinishedAt'] = null;
    }
    if (this.scanError != null) {
      json[r'scanError'] = this.scanError;
    } else {
      json[r'scanError'] = null;
    }
    return json;
  }

  /// Returns a new [ExternalLibrary] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ExternalLibrary? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ExternalLibrary[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ExternalLibrary[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ExternalLibrary(
        available: mapValueOfType<bool>(json, r'available')!,
        ownerId: mapValueOfType<String>(json, r'ownerId'),
        assets: mapValueOfType<int>(json, r'assets')!,
        missing: mapValueOfType<int>(json, r'missing')!,
        scanning: mapValueOfType<bool>(json, r'scanning')!,
        scanFinishedAt: mapDateTime(json, r'scanFinishedAt', r''),
        scanError: mapValueOfType<String>(json, r'scanError'),
      );
    }
    return null;
  }

  static List<ExternalLibrary> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ExternalLibrary>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ExternalLibrary.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ExternalLibrary> mapFromJson(dynamic json) {
    final map = <String, ExternalLibrary>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ExternalLibrary.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ExternalLibrary-objects as value to a dart map
  static Map<String, List<ExternalLibrary>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ExternalLibrary>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ExternalLibrary.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'available',
    'assets',
    'missing',
    'scanning',
  };
}

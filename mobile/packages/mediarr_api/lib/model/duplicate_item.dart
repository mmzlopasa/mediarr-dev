//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DuplicateItem {
  /// Returns a new [DuplicateItem] instance.
  DuplicateItem({
    required this.id,
    required this.originalName,
    required this.sizeBytes,
    this.width,
    this.height,
    required this.ratio,
    required this.localAt,
  });

  String id;

  String originalName;

  int sizeBytes;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? width;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? height;

  double ratio;

  String localAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DuplicateItem &&
          other.id == id &&
          other.originalName == originalName &&
          other.sizeBytes == sizeBytes &&
          other.width == width &&
          other.height == height &&
          other.ratio == ratio &&
          other.localAt == localAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (originalName.hashCode) +
      (sizeBytes.hashCode) +
      (width == null ? 0 : width!.hashCode) +
      (height == null ? 0 : height!.hashCode) +
      (ratio.hashCode) +
      (localAt.hashCode);

  @override
  String toString() =>
      'DuplicateItem[id=$id, originalName=$originalName, sizeBytes=$sizeBytes, width=$width, height=$height, ratio=$ratio, localAt=$localAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'originalName'] = this.originalName;
    json[r'sizeBytes'] = this.sizeBytes;
    if (this.width != null) {
      json[r'width'] = this.width;
    } else {
      json[r'width'] = null;
    }
    if (this.height != null) {
      json[r'height'] = this.height;
    } else {
      json[r'height'] = null;
    }
    json[r'ratio'] = this.ratio;
    json[r'localAt'] = this.localAt;
    return json;
  }

  /// Returns a new [DuplicateItem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DuplicateItem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "DuplicateItem[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "DuplicateItem[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return DuplicateItem(
        id: mapValueOfType<String>(json, r'id')!,
        originalName: mapValueOfType<String>(json, r'originalName')!,
        sizeBytes: mapValueOfType<int>(json, r'sizeBytes')!,
        width: mapValueOfType<int>(json, r'width'),
        height: mapValueOfType<int>(json, r'height'),
        ratio: mapValueOfType<double>(json, r'ratio')!,
        localAt: mapValueOfType<String>(json, r'localAt')!,
      );
    }
    return null;
  }

  static List<DuplicateItem> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <DuplicateItem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DuplicateItem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DuplicateItem> mapFromJson(dynamic json) {
    final map = <String, DuplicateItem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DuplicateItem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DuplicateItem-objects as value to a dart map
  static Map<String, List<DuplicateItem>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<DuplicateItem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DuplicateItem.listFromJson(
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
    'originalName',
    'sizeBytes',
    'ratio',
    'localAt',
  };
}

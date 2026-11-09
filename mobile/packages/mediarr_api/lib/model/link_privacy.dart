//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LinkPrivacy {
  /// Returns a new [LinkPrivacy] instance.
  LinkPrivacy({
    this.showLocation,
    this.hideFaces,
    this.visiblePeople = const [],
    this.stripCamera,
    this.stripDate,
    this.askName,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? showLocation;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  HideFaces? hideFaces;

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkPrivacy &&
          other.showLocation == showLocation &&
          other.hideFaces == hideFaces &&
          _deepEquality.equals(other.visiblePeople, visiblePeople) &&
          other.stripCamera == stripCamera &&
          other.stripDate == stripDate &&
          other.askName == askName;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (showLocation == null ? 0 : showLocation!.hashCode) +
      (hideFaces == null ? 0 : hideFaces!.hashCode) +
      (visiblePeople.hashCode) +
      (stripCamera == null ? 0 : stripCamera!.hashCode) +
      (stripDate == null ? 0 : stripDate!.hashCode) +
      (askName == null ? 0 : askName!.hashCode);

  @override
  String toString() =>
      'LinkPrivacy[showLocation=$showLocation, hideFaces=$hideFaces, visiblePeople=$visiblePeople, stripCamera=$stripCamera, stripDate=$stripDate, askName=$askName]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.showLocation != null) {
      json[r'showLocation'] = this.showLocation;
    } else {
      json[r'showLocation'] = null;
    }
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
    return json;
  }

  /// Returns a new [LinkPrivacy] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LinkPrivacy? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "LinkPrivacy[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "LinkPrivacy[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return LinkPrivacy(
        showLocation: mapValueOfType<bool>(json, r'showLocation'),
        hideFaces: HideFaces.fromJson(json[r'hideFaces']),
        visiblePeople: json[r'visiblePeople'] is Iterable
            ? (json[r'visiblePeople'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        stripCamera: mapValueOfType<bool>(json, r'stripCamera'),
        stripDate: mapValueOfType<bool>(json, r'stripDate'),
        askName: mapValueOfType<bool>(json, r'askName'),
      );
    }
    return null;
  }

  static List<LinkPrivacy> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <LinkPrivacy>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LinkPrivacy.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LinkPrivacy> mapFromJson(dynamic json) {
    final map = <String, LinkPrivacy>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LinkPrivacy.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LinkPrivacy-objects as value to a dart map
  static Map<String, List<LinkPrivacy>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<LinkPrivacy>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LinkPrivacy.listFromJson(
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

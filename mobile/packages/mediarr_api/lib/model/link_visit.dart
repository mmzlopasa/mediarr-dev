//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LinkVisit {
  /// Returns a new [LinkVisit] instance.
  LinkVisit({
    required this.at,
    this.name,
    this.city,
    this.country,
    required this.device,
    required this.viewed,
    required this.downloaded,
  });

  DateTime at;

  /// What the visitor said they are called, when the link asked
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? city;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? country;

  /// The kind of device and browser, such as iPhone · Safari
  String device;

  int viewed;

  int downloaded;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkVisit &&
          other.at == at &&
          other.name == name &&
          other.city == city &&
          other.country == country &&
          other.device == device &&
          other.viewed == viewed &&
          other.downloaded == downloaded;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (at.hashCode) +
      (name == null ? 0 : name!.hashCode) +
      (city == null ? 0 : city!.hashCode) +
      (country == null ? 0 : country!.hashCode) +
      (device.hashCode) +
      (viewed.hashCode) +
      (downloaded.hashCode);

  @override
  String toString() =>
      'LinkVisit[at=$at, name=$name, city=$city, country=$country, device=$device, viewed=$viewed, downloaded=$downloaded]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'at'] = this.at.toUtc().toIso8601String();
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.city != null) {
      json[r'city'] = this.city;
    } else {
      json[r'city'] = null;
    }
    if (this.country != null) {
      json[r'country'] = this.country;
    } else {
      json[r'country'] = null;
    }
    json[r'device'] = this.device;
    json[r'viewed'] = this.viewed;
    json[r'downloaded'] = this.downloaded;
    return json;
  }

  /// Returns a new [LinkVisit] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LinkVisit? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "LinkVisit[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "LinkVisit[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return LinkVisit(
        at: mapDateTime(json, r'at', r'')!,
        name: mapValueOfType<String>(json, r'name'),
        city: mapValueOfType<String>(json, r'city'),
        country: mapValueOfType<String>(json, r'country'),
        device: mapValueOfType<String>(json, r'device')!,
        viewed: mapValueOfType<int>(json, r'viewed')!,
        downloaded: mapValueOfType<int>(json, r'downloaded')!,
      );
    }
    return null;
  }

  static List<LinkVisit> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <LinkVisit>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LinkVisit.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LinkVisit> mapFromJson(dynamic json) {
    final map = <String, LinkVisit>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LinkVisit.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LinkVisit-objects as value to a dart map
  static Map<String, List<LinkVisit>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<LinkVisit>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LinkVisit.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'at',
    'device',
    'viewed',
    'downloaded',
  };
}

//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PartnerEntry {
  /// Returns a new [PartnerEntry] instance.
  PartnerEntry({
    required this.userId,
    required this.name,
    this.since,
    required this.inTimeline,
  });

  String userId;

  String name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? since;

  bool inTimeline;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartnerEntry &&
          other.userId == userId &&
          other.name == name &&
          other.since == since &&
          other.inTimeline == inTimeline;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (userId.hashCode) +
      (name.hashCode) +
      (since == null ? 0 : since!.hashCode) +
      (inTimeline.hashCode);

  @override
  String toString() =>
      'PartnerEntry[userId=$userId, name=$name, since=$since, inTimeline=$inTimeline]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'userId'] = this.userId;
    json[r'name'] = this.name;
    if (this.since != null) {
      json[r'since'] = _dateFormatter.format(this.since!.toUtc());
    } else {
      json[r'since'] = null;
    }
    json[r'inTimeline'] = this.inTimeline;
    return json;
  }

  /// Returns a new [PartnerEntry] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PartnerEntry? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "PartnerEntry[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "PartnerEntry[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PartnerEntry(
        userId: mapValueOfType<String>(json, r'userId')!,
        name: mapValueOfType<String>(json, r'name')!,
        since: mapDateTime(json, r'since', r''),
        inTimeline: mapValueOfType<bool>(json, r'inTimeline')!,
      );
    }
    return null;
  }

  static List<PartnerEntry> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PartnerEntry>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PartnerEntry.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PartnerEntry> mapFromJson(dynamic json) {
    final map = <String, PartnerEntry>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PartnerEntry.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PartnerEntry-objects as value to a dart map
  static Map<String, List<PartnerEntry>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PartnerEntry>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PartnerEntry.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'userId',
    'name',
    'inTimeline',
  };
}

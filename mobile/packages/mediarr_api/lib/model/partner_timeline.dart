//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PartnerTimeline {
  /// Returns a new [PartnerTimeline] instance.
  PartnerTimeline({
    required this.show_,
  });

  bool show_;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartnerTimeline && other.show_ == show_;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (show_.hashCode);

  @override
  String toString() => 'PartnerTimeline[show_=$show_]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'show'] = this.show_;
    return json;
  }

  /// Returns a new [PartnerTimeline] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PartnerTimeline? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "PartnerTimeline[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "PartnerTimeline[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PartnerTimeline(
        show_: mapValueOfType<bool>(json, r'show')!,
      );
    }
    return null;
  }

  static List<PartnerTimeline> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PartnerTimeline>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PartnerTimeline.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PartnerTimeline> mapFromJson(dynamic json) {
    final map = <String, PartnerTimeline>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PartnerTimeline.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PartnerTimeline-objects as value to a dart map
  static Map<String, List<PartnerTimeline>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PartnerTimeline>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PartnerTimeline.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'show',
  };
}

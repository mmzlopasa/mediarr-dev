//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ExplorePlace {
  /// Returns a new [ExplorePlace] instance.
  ExplorePlace({
    required this.name,
    required this.country,
    required this.assetCount,
    required this.coverId,
  });

  String name;

  String country;

  int assetCount;

  String coverId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExplorePlace &&
          other.name == name &&
          other.country == country &&
          other.assetCount == assetCount &&
          other.coverId == coverId;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (name.hashCode) +
      (country.hashCode) +
      (assetCount.hashCode) +
      (coverId.hashCode);

  @override
  String toString() =>
      'ExplorePlace[name=$name, country=$country, assetCount=$assetCount, coverId=$coverId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'name'] = this.name;
    json[r'country'] = this.country;
    json[r'assetCount'] = this.assetCount;
    json[r'coverId'] = this.coverId;
    return json;
  }

  /// Returns a new [ExplorePlace] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ExplorePlace? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ExplorePlace[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ExplorePlace[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ExplorePlace(
        name: mapValueOfType<String>(json, r'name')!,
        country: mapValueOfType<String>(json, r'country')!,
        assetCount: mapValueOfType<int>(json, r'assetCount')!,
        coverId: mapValueOfType<String>(json, r'coverId')!,
      );
    }
    return null;
  }

  static List<ExplorePlace> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ExplorePlace>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ExplorePlace.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ExplorePlace> mapFromJson(dynamic json) {
    final map = <String, ExplorePlace>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ExplorePlace.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ExplorePlace-objects as value to a dart map
  static Map<String, List<ExplorePlace>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ExplorePlace>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ExplorePlace.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'country',
    'assetCount',
    'coverId',
  };
}

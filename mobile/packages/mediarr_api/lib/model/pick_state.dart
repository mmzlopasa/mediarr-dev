//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PickState {
  /// Returns a new [PickState] instance.
  PickState({
    required this.id,
    required this.pick,
    required this.rating,
  });

  String id;

  /// 1 picked, -1 rejected, 0 none
  int pick;

  /// 0 to 5 stars; 0 is none
  int rating;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PickState &&
          other.id == id &&
          other.pick == pick &&
          other.rating == rating;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) + (pick.hashCode) + (rating.hashCode);

  @override
  String toString() => 'PickState[id=$id, pick=$pick, rating=$rating]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'pick'] = this.pick;
    json[r'rating'] = this.rating;
    return json;
  }

  /// Returns a new [PickState] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PickState? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "PickState[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "PickState[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PickState(
        id: mapValueOfType<String>(json, r'id')!,
        pick: mapValueOfType<int>(json, r'pick')!,
        rating: mapValueOfType<int>(json, r'rating')!,
      );
    }
    return null;
  }

  static List<PickState> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PickState>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PickState.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PickState> mapFromJson(dynamic json) {
    final map = <String, PickState>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PickState.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PickState-objects as value to a dart map
  static Map<String, List<PickState>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PickState>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PickState.listFromJson(
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
    'pick',
    'rating',
  };
}

//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PickRequest {
  /// Returns a new [PickRequest] instance.
  PickRequest({
    this.ids = const [],
    required this.pick,
  });

  List<String> ids;

  /// 1 picked, -1 rejected, 0 none
  ///
  /// Minimum value: -1
  /// Maximum value: 1
  int pick;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PickRequest &&
          _deepEquality.equals(other.ids, ids) &&
          other.pick == pick;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (ids.hashCode) + (pick.hashCode);

  @override
  String toString() => 'PickRequest[ids=$ids, pick=$pick]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'ids'] = this.ids;
    json[r'pick'] = this.pick;
    return json;
  }

  /// Returns a new [PickRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PickRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "PickRequest[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "PickRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PickRequest(
        ids: json[r'ids'] is Iterable
            ? (json[r'ids'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        pick: mapValueOfType<int>(json, r'pick')!,
      );
    }
    return null;
  }

  static List<PickRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PickRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PickRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PickRequest> mapFromJson(dynamic json) {
    final map = <String, PickRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PickRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PickRequest-objects as value to a dart map
  static Map<String, List<PickRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PickRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PickRequest.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'ids',
    'pick',
  };
}

//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MemoryPersonHideRequest {
  /// Returns a new [MemoryPersonHideRequest] instance.
  MemoryPersonHideRequest({
    required this.personId,
    required this.hidden,
  });

  String personId;

  bool hidden;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryPersonHideRequest &&
          other.personId == personId &&
          other.hidden == hidden;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (personId.hashCode) + (hidden.hashCode);

  @override
  String toString() =>
      'MemoryPersonHideRequest[personId=$personId, hidden=$hidden]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'personId'] = this.personId;
    json[r'hidden'] = this.hidden;
    return json;
  }

  /// Returns a new [MemoryPersonHideRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MemoryPersonHideRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "MemoryPersonHideRequest[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "MemoryPersonHideRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return MemoryPersonHideRequest(
        personId: mapValueOfType<String>(json, r'personId')!,
        hidden: mapValueOfType<bool>(json, r'hidden')!,
      );
    }
    return null;
  }

  static List<MemoryPersonHideRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <MemoryPersonHideRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MemoryPersonHideRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MemoryPersonHideRequest> mapFromJson(dynamic json) {
    final map = <String, MemoryPersonHideRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MemoryPersonHideRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MemoryPersonHideRequest-objects as value to a dart map
  static Map<String, List<MemoryPersonHideRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<MemoryPersonHideRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MemoryPersonHideRequest.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'personId',
    'hidden',
  };
}

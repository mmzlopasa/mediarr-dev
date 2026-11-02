//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ChecksumCheckRequest {
  /// Returns a new [ChecksumCheckRequest] instance.
  ChecksumCheckRequest({
    this.checksums = const [],
  });

  List<String> checksums;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChecksumCheckRequest &&
          _deepEquality.equals(other.checksums, checksums);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (checksums.hashCode);

  @override
  String toString() => 'ChecksumCheckRequest[checksums=$checksums]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'checksums'] = this.checksums;
    return json;
  }

  /// Returns a new [ChecksumCheckRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ChecksumCheckRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ChecksumCheckRequest[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ChecksumCheckRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ChecksumCheckRequest(
        checksums: json[r'checksums'] is Iterable
            ? (json[r'checksums'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<ChecksumCheckRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ChecksumCheckRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ChecksumCheckRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ChecksumCheckRequest> mapFromJson(dynamic json) {
    final map = <String, ChecksumCheckRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ChecksumCheckRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ChecksumCheckRequest-objects as value to a dart map
  static Map<String, List<ChecksumCheckRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ChecksumCheckRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ChecksumCheckRequest.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'checksums',
  };
}

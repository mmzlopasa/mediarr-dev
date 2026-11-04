//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AskRequest {
  /// Returns a new [AskRequest] instance.
  AskRequest({
    required this.question,
  });

  String question;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AskRequest && other.question == question;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (question.hashCode);

  @override
  String toString() => 'AskRequest[question=$question]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'question'] = this.question;
    return json;
  }

  /// Returns a new [AskRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AskRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "AskRequest[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "AskRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AskRequest(
        question: mapValueOfType<String>(json, r'question')!,
      );
    }
    return null;
  }

  static List<AskRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AskRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AskRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AskRequest> mapFromJson(dynamic json) {
    final map = <String, AskRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AskRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AskRequest-objects as value to a dart map
  static Map<String, List<AskRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<AskRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AskRequest.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'question',
  };
}

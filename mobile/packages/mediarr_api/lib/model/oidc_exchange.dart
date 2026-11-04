//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class OIDCExchange {
  /// Returns a new [OIDCExchange] instance.
  OIDCExchange({
    required this.code,
    required this.verifier,
  });

  String code;

  String verifier;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OIDCExchange && other.code == code && other.verifier == verifier;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (code.hashCode) + (verifier.hashCode);

  @override
  String toString() => 'OIDCExchange[code=$code, verifier=$verifier]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'code'] = this.code;
    json[r'verifier'] = this.verifier;
    return json;
  }

  /// Returns a new [OIDCExchange] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static OIDCExchange? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "OIDCExchange[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "OIDCExchange[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return OIDCExchange(
        code: mapValueOfType<String>(json, r'code')!,
        verifier: mapValueOfType<String>(json, r'verifier')!,
      );
    }
    return null;
  }

  static List<OIDCExchange> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <OIDCExchange>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OIDCExchange.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, OIDCExchange> mapFromJson(dynamic json) {
    final map = <String, OIDCExchange>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = OIDCExchange.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of OIDCExchange-objects as value to a dart map
  static Map<String, List<OIDCExchange>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<OIDCExchange>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = OIDCExchange.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'code',
    'verifier',
  };
}

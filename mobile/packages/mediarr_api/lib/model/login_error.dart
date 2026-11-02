//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LoginError {
  /// Returns a new [LoginError] instance.
  LoginError({
    required this.message,
    required this.totpRequired,
  });

  String message;

  bool totpRequired;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoginError &&
          other.message == message &&
          other.totpRequired == totpRequired;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (message.hashCode) + (totpRequired.hashCode);

  @override
  String toString() =>
      'LoginError[message=$message, totpRequired=$totpRequired]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'message'] = this.message;
    json[r'totpRequired'] = this.totpRequired;
    return json;
  }

  /// Returns a new [LoginError] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LoginError? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "LoginError[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "LoginError[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return LoginError(
        message: mapValueOfType<String>(json, r'message')!,
        totpRequired: mapValueOfType<bool>(json, r'totpRequired')!,
      );
    }
    return null;
  }

  static List<LoginError> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <LoginError>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LoginError.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LoginError> mapFromJson(dynamic json) {
    final map = <String, LoginError>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LoginError.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LoginError-objects as value to a dart map
  static Map<String, List<LoginError>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<LoginError>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LoginError.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'message',
    'totpRequired',
  };
}

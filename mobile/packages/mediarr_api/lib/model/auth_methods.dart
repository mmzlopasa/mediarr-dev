//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AuthMethods {
  /// Returns a new [AuthMethods] instance.
  AuthMethods({
    required this.passwordLogin,
    required this.loginMessage,
    required this.passkeys,
    this.ssoLabel,
  });

  bool passwordLogin;

  String loginMessage;

  /// This address can use passkeys: HTTPS and a domain name
  bool passkeys;

  /// The name of the single sign-on button, if it is turned on
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? ssoLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthMethods &&
          other.passwordLogin == passwordLogin &&
          other.loginMessage == loginMessage &&
          other.passkeys == passkeys &&
          other.ssoLabel == ssoLabel;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (passwordLogin.hashCode) +
      (loginMessage.hashCode) +
      (passkeys.hashCode) +
      (ssoLabel == null ? 0 : ssoLabel!.hashCode);

  @override
  String toString() =>
      'AuthMethods[passwordLogin=$passwordLogin, loginMessage=$loginMessage, passkeys=$passkeys, ssoLabel=$ssoLabel]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'passwordLogin'] = this.passwordLogin;
    json[r'loginMessage'] = this.loginMessage;
    json[r'passkeys'] = this.passkeys;
    if (this.ssoLabel != null) {
      json[r'ssoLabel'] = this.ssoLabel;
    } else {
      json[r'ssoLabel'] = null;
    }
    return json;
  }

  /// Returns a new [AuthMethods] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AuthMethods? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "AuthMethods[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "AuthMethods[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AuthMethods(
        passwordLogin: mapValueOfType<bool>(json, r'passwordLogin')!,
        loginMessage: mapValueOfType<String>(json, r'loginMessage')!,
        passkeys: mapValueOfType<bool>(json, r'passkeys')!,
        ssoLabel: mapValueOfType<String>(json, r'ssoLabel'),
      );
    }
    return null;
  }

  static List<AuthMethods> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AuthMethods>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AuthMethods.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AuthMethods> mapFromJson(dynamic json) {
    final map = <String, AuthMethods>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AuthMethods.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AuthMethods-objects as value to a dart map
  static Map<String, List<AuthMethods>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<AuthMethods>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AuthMethods.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'passwordLogin',
    'loginMessage',
    'passkeys',
  };
}

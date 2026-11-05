//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class EmailSettings {
  /// Returns a new [EmailSettings] instance.
  EmailSettings({
    required this.enabled,
    required this.host,
    required this.port,
    required this.username,
    required this.from,
    required this.security,
    required this.publicUrl,
    required this.hasPassword,
  });

  bool enabled;

  String host;

  int port;

  String username;

  String from;

  EmailSettingsSecurityEnum security;

  /// The address of this server, for links in messages
  String publicUrl;

  bool hasPassword;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailSettings &&
          other.enabled == enabled &&
          other.host == host &&
          other.port == port &&
          other.username == username &&
          other.from == from &&
          other.security == security &&
          other.publicUrl == publicUrl &&
          other.hasPassword == hasPassword;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (enabled.hashCode) +
      (host.hashCode) +
      (port.hashCode) +
      (username.hashCode) +
      (from.hashCode) +
      (security.hashCode) +
      (publicUrl.hashCode) +
      (hasPassword.hashCode);

  @override
  String toString() =>
      'EmailSettings[enabled=$enabled, host=$host, port=$port, username=$username, from=$from, security=$security, publicUrl=$publicUrl, hasPassword=$hasPassword]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'enabled'] = this.enabled;
    json[r'host'] = this.host;
    json[r'port'] = this.port;
    json[r'username'] = this.username;
    json[r'from'] = this.from;
    json[r'security'] = this.security;
    json[r'publicUrl'] = this.publicUrl;
    json[r'hasPassword'] = this.hasPassword;
    return json;
  }

  /// Returns a new [EmailSettings] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static EmailSettings? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "EmailSettings[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "EmailSettings[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return EmailSettings(
        enabled: mapValueOfType<bool>(json, r'enabled')!,
        host: mapValueOfType<String>(json, r'host')!,
        port: mapValueOfType<int>(json, r'port')!,
        username: mapValueOfType<String>(json, r'username')!,
        from: mapValueOfType<String>(json, r'from')!,
        security: EmailSettingsSecurityEnum.fromJson(json[r'security'])!,
        publicUrl: mapValueOfType<String>(json, r'publicUrl')!,
        hasPassword: mapValueOfType<bool>(json, r'hasPassword')!,
      );
    }
    return null;
  }

  static List<EmailSettings> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <EmailSettings>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = EmailSettings.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, EmailSettings> mapFromJson(dynamic json) {
    final map = <String, EmailSettings>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = EmailSettings.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of EmailSettings-objects as value to a dart map
  static Map<String, List<EmailSettings>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<EmailSettings>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = EmailSettings.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'enabled',
    'host',
    'port',
    'username',
    'from',
    'security',
    'publicUrl',
    'hasPassword',
  };
}

class EmailSettingsSecurityEnum {
  /// Instantiate a new enum with the provided [value].
  const EmailSettingsSecurityEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const starttls = EmailSettingsSecurityEnum._(r'starttls');
  static const tls = EmailSettingsSecurityEnum._(r'tls');
  static const none = EmailSettingsSecurityEnum._(r'none');

  /// List of all possible values in this [enum][EmailSettingsSecurityEnum].
  static const values = <EmailSettingsSecurityEnum>[
    starttls,
    tls,
    none,
  ];

  static EmailSettingsSecurityEnum? fromJson(dynamic value) =>
      EmailSettingsSecurityEnumTypeTransformer().decode(value);

  static List<EmailSettingsSecurityEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <EmailSettingsSecurityEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = EmailSettingsSecurityEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [EmailSettingsSecurityEnum] to String,
/// and [decode] dynamic data back to [EmailSettingsSecurityEnum].
class EmailSettingsSecurityEnumTypeTransformer {
  factory EmailSettingsSecurityEnumTypeTransformer() =>
      _instance ??= const EmailSettingsSecurityEnumTypeTransformer._();

  const EmailSettingsSecurityEnumTypeTransformer._();

  String encode(EmailSettingsSecurityEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a EmailSettingsSecurityEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  EmailSettingsSecurityEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'starttls':
          return EmailSettingsSecurityEnum.starttls;
        case r'tls':
          return EmailSettingsSecurityEnum.tls;
        case r'none':
          return EmailSettingsSecurityEnum.none;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [EmailSettingsSecurityEnumTypeTransformer] instance.
  static EmailSettingsSecurityEnumTypeTransformer? _instance;
}

//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class EmailSettingsUpdate {
  /// Returns a new [EmailSettingsUpdate] instance.
  EmailSettingsUpdate({
    required this.enabled,
    required this.host,
    required this.port,
    required this.username,
    this.password,
    required this.from,
    required this.security,
    required this.publicUrl,
  });

  bool enabled;

  String host;

  int port;

  String username;

  /// Left out keeps the one that is saved
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? password;

  String from;

  EmailSettingsUpdateSecurityEnum security;

  String publicUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailSettingsUpdate &&
          other.enabled == enabled &&
          other.host == host &&
          other.port == port &&
          other.username == username &&
          other.password == password &&
          other.from == from &&
          other.security == security &&
          other.publicUrl == publicUrl;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (enabled.hashCode) +
      (host.hashCode) +
      (port.hashCode) +
      (username.hashCode) +
      (password == null ? 0 : password!.hashCode) +
      (from.hashCode) +
      (security.hashCode) +
      (publicUrl.hashCode);

  @override
  String toString() =>
      'EmailSettingsUpdate[enabled=$enabled, host=$host, port=$port, username=$username, password=$password, from=$from, security=$security, publicUrl=$publicUrl]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'enabled'] = this.enabled;
    json[r'host'] = this.host;
    json[r'port'] = this.port;
    json[r'username'] = this.username;
    if (this.password != null) {
      json[r'password'] = this.password;
    } else {
      json[r'password'] = null;
    }
    json[r'from'] = this.from;
    json[r'security'] = this.security;
    json[r'publicUrl'] = this.publicUrl;
    return json;
  }

  /// Returns a new [EmailSettingsUpdate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static EmailSettingsUpdate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "EmailSettingsUpdate[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "EmailSettingsUpdate[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return EmailSettingsUpdate(
        enabled: mapValueOfType<bool>(json, r'enabled')!,
        host: mapValueOfType<String>(json, r'host')!,
        port: mapValueOfType<int>(json, r'port')!,
        username: mapValueOfType<String>(json, r'username')!,
        password: mapValueOfType<String>(json, r'password'),
        from: mapValueOfType<String>(json, r'from')!,
        security: EmailSettingsUpdateSecurityEnum.fromJson(json[r'security'])!,
        publicUrl: mapValueOfType<String>(json, r'publicUrl')!,
      );
    }
    return null;
  }

  static List<EmailSettingsUpdate> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <EmailSettingsUpdate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = EmailSettingsUpdate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, EmailSettingsUpdate> mapFromJson(dynamic json) {
    final map = <String, EmailSettingsUpdate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = EmailSettingsUpdate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of EmailSettingsUpdate-objects as value to a dart map
  static Map<String, List<EmailSettingsUpdate>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<EmailSettingsUpdate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = EmailSettingsUpdate.listFromJson(
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
  };
}

class EmailSettingsUpdateSecurityEnum {
  /// Instantiate a new enum with the provided [value].
  const EmailSettingsUpdateSecurityEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const starttls = EmailSettingsUpdateSecurityEnum._(r'starttls');
  static const tls = EmailSettingsUpdateSecurityEnum._(r'tls');
  static const none = EmailSettingsUpdateSecurityEnum._(r'none');

  /// List of all possible values in this [enum][EmailSettingsUpdateSecurityEnum].
  static const values = <EmailSettingsUpdateSecurityEnum>[
    starttls,
    tls,
    none,
  ];

  static EmailSettingsUpdateSecurityEnum? fromJson(dynamic value) =>
      EmailSettingsUpdateSecurityEnumTypeTransformer().decode(value);

  static List<EmailSettingsUpdateSecurityEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <EmailSettingsUpdateSecurityEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = EmailSettingsUpdateSecurityEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [EmailSettingsUpdateSecurityEnum] to String,
/// and [decode] dynamic data back to [EmailSettingsUpdateSecurityEnum].
class EmailSettingsUpdateSecurityEnumTypeTransformer {
  factory EmailSettingsUpdateSecurityEnumTypeTransformer() =>
      _instance ??= const EmailSettingsUpdateSecurityEnumTypeTransformer._();

  const EmailSettingsUpdateSecurityEnumTypeTransformer._();

  String encode(EmailSettingsUpdateSecurityEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a EmailSettingsUpdateSecurityEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  EmailSettingsUpdateSecurityEnum? decode(dynamic data,
      {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'starttls':
          return EmailSettingsUpdateSecurityEnum.starttls;
        case r'tls':
          return EmailSettingsUpdateSecurityEnum.tls;
        case r'none':
          return EmailSettingsUpdateSecurityEnum.none;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [EmailSettingsUpdateSecurityEnumTypeTransformer] instance.
  static EmailSettingsUpdateSecurityEnumTypeTransformer? _instance;
}

//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SecurityEvent {
  /// Returns a new [SecurityEvent] instance.
  SecurityEvent({
    required this.id,
    required this.at,
    required this.kind,
    required this.email,
    required this.ip,
    required this.userAgent,
    required this.detail,
  });

  int id;

  DateTime at;

  SecurityEventKindEnum kind;

  String email;

  String ip;

  String userAgent;

  String detail;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecurityEvent &&
          other.id == id &&
          other.at == at &&
          other.kind == kind &&
          other.email == email &&
          other.ip == ip &&
          other.userAgent == userAgent &&
          other.detail == detail;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (at.hashCode) +
      (kind.hashCode) +
      (email.hashCode) +
      (ip.hashCode) +
      (userAgent.hashCode) +
      (detail.hashCode);

  @override
  String toString() =>
      'SecurityEvent[id=$id, at=$at, kind=$kind, email=$email, ip=$ip, userAgent=$userAgent, detail=$detail]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'at'] = this.at.toUtc().toIso8601String();
    json[r'kind'] = this.kind;
    json[r'email'] = this.email;
    json[r'ip'] = this.ip;
    json[r'userAgent'] = this.userAgent;
    json[r'detail'] = this.detail;
    return json;
  }

  /// Returns a new [SecurityEvent] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SecurityEvent? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "SecurityEvent[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "SecurityEvent[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return SecurityEvent(
        id: mapValueOfType<int>(json, r'id')!,
        at: mapDateTime(json, r'at', r'')!,
        kind: SecurityEventKindEnum.fromJson(json[r'kind'])!,
        email: mapValueOfType<String>(json, r'email')!,
        ip: mapValueOfType<String>(json, r'ip')!,
        userAgent: mapValueOfType<String>(json, r'userAgent')!,
        detail: mapValueOfType<String>(json, r'detail')!,
      );
    }
    return null;
  }

  static List<SecurityEvent> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SecurityEvent>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SecurityEvent.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SecurityEvent> mapFromJson(dynamic json) {
    final map = <String, SecurityEvent>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SecurityEvent.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SecurityEvent-objects as value to a dart map
  static Map<String, List<SecurityEvent>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SecurityEvent>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SecurityEvent.listFromJson(
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
    'at',
    'kind',
    'email',
    'ip',
    'userAgent',
    'detail',
  };
}

class SecurityEventKindEnum {
  /// Instantiate a new enum with the provided [value].
  const SecurityEventKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const loginOk = SecurityEventKindEnum._(r'login_ok');
  static const loginFailed = SecurityEventKindEnum._(r'login_failed');
  static const loginLocked = SecurityEventKindEnum._(r'login_locked');
  static const ipBlocked = SecurityEventKindEnum._(r'ip_blocked');
  static const deviceBlocked = SecurityEventKindEnum._(r'device_blocked');

  /// List of all possible values in this [enum][SecurityEventKindEnum].
  static const values = <SecurityEventKindEnum>[
    loginOk,
    loginFailed,
    loginLocked,
    ipBlocked,
    deviceBlocked,
  ];

  static SecurityEventKindEnum? fromJson(dynamic value) =>
      SecurityEventKindEnumTypeTransformer().decode(value);

  static List<SecurityEventKindEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SecurityEventKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SecurityEventKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SecurityEventKindEnum] to String,
/// and [decode] dynamic data back to [SecurityEventKindEnum].
class SecurityEventKindEnumTypeTransformer {
  factory SecurityEventKindEnumTypeTransformer() =>
      _instance ??= const SecurityEventKindEnumTypeTransformer._();

  const SecurityEventKindEnumTypeTransformer._();

  String encode(SecurityEventKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a SecurityEventKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SecurityEventKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'login_ok':
          return SecurityEventKindEnum.loginOk;
        case r'login_failed':
          return SecurityEventKindEnum.loginFailed;
        case r'login_locked':
          return SecurityEventKindEnum.loginLocked;
        case r'ip_blocked':
          return SecurityEventKindEnum.ipBlocked;
        case r'device_blocked':
          return SecurityEventKindEnum.deviceBlocked;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [SecurityEventKindEnumTypeTransformer] instance.
  static SecurityEventKindEnumTypeTransformer? _instance;
}

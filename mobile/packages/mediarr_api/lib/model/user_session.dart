//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UserSession {
  /// Returns a new [UserSession] instance.
  UserSession({
    required this.id,
    required this.userAgent,
    required this.ip,
    required this.createdAt,
    required this.lastSeenAt,
    required this.current,
  });

  String id;

  String userAgent;

  String ip;

  DateTime createdAt;

  DateTime lastSeenAt;

  bool current;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSession &&
          other.id == id &&
          other.userAgent == userAgent &&
          other.ip == ip &&
          other.createdAt == createdAt &&
          other.lastSeenAt == lastSeenAt &&
          other.current == current;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (userAgent.hashCode) +
      (ip.hashCode) +
      (createdAt.hashCode) +
      (lastSeenAt.hashCode) +
      (current.hashCode);

  @override
  String toString() =>
      'UserSession[id=$id, userAgent=$userAgent, ip=$ip, createdAt=$createdAt, lastSeenAt=$lastSeenAt, current=$current]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'userAgent'] = this.userAgent;
    json[r'ip'] = this.ip;
    json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    json[r'lastSeenAt'] = this.lastSeenAt.toUtc().toIso8601String();
    json[r'current'] = this.current;
    return json;
  }

  /// Returns a new [UserSession] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UserSession? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "UserSession[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "UserSession[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return UserSession(
        id: mapValueOfType<String>(json, r'id')!,
        userAgent: mapValueOfType<String>(json, r'userAgent')!,
        ip: mapValueOfType<String>(json, r'ip')!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        lastSeenAt: mapDateTime(json, r'lastSeenAt', r'')!,
        current: mapValueOfType<bool>(json, r'current')!,
      );
    }
    return null;
  }

  static List<UserSession> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UserSession>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UserSession.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UserSession> mapFromJson(dynamic json) {
    final map = <String, UserSession>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UserSession.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UserSession-objects as value to a dart map
  static Map<String, List<UserSession>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<UserSession>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UserSession.listFromJson(
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
    'userAgent',
    'ip',
    'createdAt',
    'lastSeenAt',
    'current',
  };
}

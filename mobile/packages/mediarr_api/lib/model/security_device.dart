//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SecurityDevice {
  /// Returns a new [SecurityDevice] instance.
  SecurityDevice({
    required this.id,
    required this.email,
    required this.ip,
    required this.userAgent,
    required this.firstSeen,
    required this.lastSeen,
    required this.approved,
  });

  String id;

  String email;

  String ip;

  String userAgent;

  DateTime firstSeen;

  DateTime lastSeen;

  bool approved;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecurityDevice &&
          other.id == id &&
          other.email == email &&
          other.ip == ip &&
          other.userAgent == userAgent &&
          other.firstSeen == firstSeen &&
          other.lastSeen == lastSeen &&
          other.approved == approved;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (email.hashCode) +
      (ip.hashCode) +
      (userAgent.hashCode) +
      (firstSeen.hashCode) +
      (lastSeen.hashCode) +
      (approved.hashCode);

  @override
  String toString() =>
      'SecurityDevice[id=$id, email=$email, ip=$ip, userAgent=$userAgent, firstSeen=$firstSeen, lastSeen=$lastSeen, approved=$approved]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'email'] = this.email;
    json[r'ip'] = this.ip;
    json[r'userAgent'] = this.userAgent;
    json[r'firstSeen'] = this.firstSeen.toUtc().toIso8601String();
    json[r'lastSeen'] = this.lastSeen.toUtc().toIso8601String();
    json[r'approved'] = this.approved;
    return json;
  }

  /// Returns a new [SecurityDevice] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SecurityDevice? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "SecurityDevice[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "SecurityDevice[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return SecurityDevice(
        id: mapValueOfType<String>(json, r'id')!,
        email: mapValueOfType<String>(json, r'email')!,
        ip: mapValueOfType<String>(json, r'ip')!,
        userAgent: mapValueOfType<String>(json, r'userAgent')!,
        firstSeen: mapDateTime(json, r'firstSeen', r'')!,
        lastSeen: mapDateTime(json, r'lastSeen', r'')!,
        approved: mapValueOfType<bool>(json, r'approved')!,
      );
    }
    return null;
  }

  static List<SecurityDevice> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SecurityDevice>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SecurityDevice.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SecurityDevice> mapFromJson(dynamic json) {
    final map = <String, SecurityDevice>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SecurityDevice.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SecurityDevice-objects as value to a dart map
  static Map<String, List<SecurityDevice>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SecurityDevice>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SecurityDevice.listFromJson(
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
    'email',
    'ip',
    'userAgent',
    'firstSeen',
    'lastSeen',
    'approved',
  };
}

//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AuditEntry {
  /// Returns a new [AuditEntry] instance.
  AuditEntry({
    required this.id,
    required this.at,
    required this.userEmail,
    required this.method,
    required this.route,
    required this.target,
    required this.status,
    required this.ip,
  });

  int id;

  DateTime at;

  String userEmail;

  String method;

  String route;

  String target;

  int status;

  String ip;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditEntry &&
          other.id == id &&
          other.at == at &&
          other.userEmail == userEmail &&
          other.method == method &&
          other.route == route &&
          other.target == target &&
          other.status == status &&
          other.ip == ip;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (at.hashCode) +
      (userEmail.hashCode) +
      (method.hashCode) +
      (route.hashCode) +
      (target.hashCode) +
      (status.hashCode) +
      (ip.hashCode);

  @override
  String toString() =>
      'AuditEntry[id=$id, at=$at, userEmail=$userEmail, method=$method, route=$route, target=$target, status=$status, ip=$ip]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'at'] = this.at.toUtc().toIso8601String();
    json[r'userEmail'] = this.userEmail;
    json[r'method'] = this.method;
    json[r'route'] = this.route;
    json[r'target'] = this.target;
    json[r'status'] = this.status;
    json[r'ip'] = this.ip;
    return json;
  }

  /// Returns a new [AuditEntry] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AuditEntry? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "AuditEntry[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "AuditEntry[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AuditEntry(
        id: mapValueOfType<int>(json, r'id')!,
        at: mapDateTime(json, r'at', r'')!,
        userEmail: mapValueOfType<String>(json, r'userEmail')!,
        method: mapValueOfType<String>(json, r'method')!,
        route: mapValueOfType<String>(json, r'route')!,
        target: mapValueOfType<String>(json, r'target')!,
        status: mapValueOfType<int>(json, r'status')!,
        ip: mapValueOfType<String>(json, r'ip')!,
      );
    }
    return null;
  }

  static List<AuditEntry> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AuditEntry>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AuditEntry.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AuditEntry> mapFromJson(dynamic json) {
    final map = <String, AuditEntry>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AuditEntry.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AuditEntry-objects as value to a dart map
  static Map<String, List<AuditEntry>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<AuditEntry>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AuditEntry.listFromJson(
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
    'userEmail',
    'method',
    'route',
    'target',
    'status',
    'ip',
  };
}

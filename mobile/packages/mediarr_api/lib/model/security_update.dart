//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SecurityUpdate {
  /// Returns a new [SecurityUpdate] instance.
  SecurityUpdate({
    required this.ipAllowlistEnabled,
    this.ipAllowlist = const [],
    required this.deviceApprovalEnabled,
  });

  bool ipAllowlistEnabled;

  List<String> ipAllowlist;

  bool deviceApprovalEnabled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecurityUpdate &&
          other.ipAllowlistEnabled == ipAllowlistEnabled &&
          _deepEquality.equals(other.ipAllowlist, ipAllowlist) &&
          other.deviceApprovalEnabled == deviceApprovalEnabled;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (ipAllowlistEnabled.hashCode) +
      (ipAllowlist.hashCode) +
      (deviceApprovalEnabled.hashCode);

  @override
  String toString() =>
      'SecurityUpdate[ipAllowlistEnabled=$ipAllowlistEnabled, ipAllowlist=$ipAllowlist, deviceApprovalEnabled=$deviceApprovalEnabled]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'ipAllowlistEnabled'] = this.ipAllowlistEnabled;
    json[r'ipAllowlist'] = this.ipAllowlist;
    json[r'deviceApprovalEnabled'] = this.deviceApprovalEnabled;
    return json;
  }

  /// Returns a new [SecurityUpdate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SecurityUpdate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "SecurityUpdate[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "SecurityUpdate[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return SecurityUpdate(
        ipAllowlistEnabled: mapValueOfType<bool>(json, r'ipAllowlistEnabled')!,
        ipAllowlist: json[r'ipAllowlist'] is Iterable
            ? (json[r'ipAllowlist'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        deviceApprovalEnabled:
            mapValueOfType<bool>(json, r'deviceApprovalEnabled')!,
      );
    }
    return null;
  }

  static List<SecurityUpdate> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SecurityUpdate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SecurityUpdate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SecurityUpdate> mapFromJson(dynamic json) {
    final map = <String, SecurityUpdate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SecurityUpdate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SecurityUpdate-objects as value to a dart map
  static Map<String, List<SecurityUpdate>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SecurityUpdate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SecurityUpdate.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'ipAllowlistEnabled',
    'ipAllowlist',
    'deviceApprovalEnabled',
  };
}

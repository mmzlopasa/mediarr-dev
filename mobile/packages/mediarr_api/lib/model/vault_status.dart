//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class VaultStatus {
  /// Returns a new [VaultStatus] instance.
  VaultStatus({
    required this.hasPin,
    required this.unlocked,
  });

  bool hasPin;

  bool unlocked;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultStatus &&
          other.hasPin == hasPin &&
          other.unlocked == unlocked;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (hasPin.hashCode) + (unlocked.hashCode);

  @override
  String toString() => 'VaultStatus[hasPin=$hasPin, unlocked=$unlocked]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'hasPin'] = this.hasPin;
    json[r'unlocked'] = this.unlocked;
    return json;
  }

  /// Returns a new [VaultStatus] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static VaultStatus? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "VaultStatus[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "VaultStatus[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return VaultStatus(
        hasPin: mapValueOfType<bool>(json, r'hasPin')!,
        unlocked: mapValueOfType<bool>(json, r'unlocked')!,
      );
    }
    return null;
  }

  static List<VaultStatus> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <VaultStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = VaultStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, VaultStatus> mapFromJson(dynamic json) {
    final map = <String, VaultStatus>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = VaultStatus.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of VaultStatus-objects as value to a dart map
  static Map<String, List<VaultStatus>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<VaultStatus>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = VaultStatus.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'hasPin',
    'unlocked',
  };
}

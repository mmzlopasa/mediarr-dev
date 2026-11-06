//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class KeepGuestCreate {
  /// Returns a new [KeepGuestCreate] instance.
  KeepGuestCreate({
    required this.name,
    required this.quotaBytes,
    required this.address,
  });

  String name;

  int quotaBytes;

  /// Where the guest reaches this server, as http(s)://host[:port]
  String address;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeepGuestCreate &&
          other.name == name &&
          other.quotaBytes == quotaBytes &&
          other.address == address;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (name.hashCode) + (quotaBytes.hashCode) + (address.hashCode);

  @override
  String toString() =>
      'KeepGuestCreate[name=$name, quotaBytes=$quotaBytes, address=$address]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'name'] = this.name;
    json[r'quotaBytes'] = this.quotaBytes;
    json[r'address'] = this.address;
    return json;
  }

  /// Returns a new [KeepGuestCreate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static KeepGuestCreate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "KeepGuestCreate[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "KeepGuestCreate[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return KeepGuestCreate(
        name: mapValueOfType<String>(json, r'name')!,
        quotaBytes: mapValueOfType<int>(json, r'quotaBytes')!,
        address: mapValueOfType<String>(json, r'address')!,
      );
    }
    return null;
  }

  static List<KeepGuestCreate> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <KeepGuestCreate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = KeepGuestCreate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, KeepGuestCreate> mapFromJson(dynamic json) {
    final map = <String, KeepGuestCreate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = KeepGuestCreate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of KeepGuestCreate-objects as value to a dart map
  static Map<String, List<KeepGuestCreate>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<KeepGuestCreate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = KeepGuestCreate.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'quotaBytes',
    'address',
  };
}

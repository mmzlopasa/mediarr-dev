//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class VaultPinChange {
  /// Returns a new [VaultPinChange] instance.
  VaultPinChange({
    required this.pin,
    this.currentPin,
  });

  String pin;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? currentPin;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultPinChange &&
          other.pin == pin &&
          other.currentPin == currentPin;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (pin.hashCode) + (currentPin == null ? 0 : currentPin!.hashCode);

  @override
  String toString() => 'VaultPinChange[pin=$pin, currentPin=$currentPin]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'pin'] = this.pin;
    if (this.currentPin != null) {
      json[r'currentPin'] = this.currentPin;
    } else {
      json[r'currentPin'] = null;
    }
    return json;
  }

  /// Returns a new [VaultPinChange] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static VaultPinChange? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "VaultPinChange[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "VaultPinChange[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return VaultPinChange(
        pin: mapValueOfType<String>(json, r'pin')!,
        currentPin: mapValueOfType<String>(json, r'currentPin'),
      );
    }
    return null;
  }

  static List<VaultPinChange> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <VaultPinChange>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = VaultPinChange.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, VaultPinChange> mapFromJson(dynamic json) {
    final map = <String, VaultPinChange>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = VaultPinChange.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of VaultPinChange-objects as value to a dart map
  static Map<String, List<VaultPinChange>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<VaultPinChange>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = VaultPinChange.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'pin',
  };
}

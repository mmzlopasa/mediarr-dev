//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class KeepPairing {
  /// Returns a new [KeepPairing] instance.
  KeepPairing({
    required this.guestId,
    required this.secret,
    required this.name,
    required this.quotaBytes,
  });

  String guestId;

  String secret;

  String name;

  int quotaBytes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeepPairing &&
          other.guestId == guestId &&
          other.secret == secret &&
          other.name == name &&
          other.quotaBytes == quotaBytes;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (guestId.hashCode) +
      (secret.hashCode) +
      (name.hashCode) +
      (quotaBytes.hashCode);

  @override
  String toString() =>
      'KeepPairing[guestId=$guestId, secret=$secret, name=$name, quotaBytes=$quotaBytes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'guestId'] = this.guestId;
    json[r'secret'] = this.secret;
    json[r'name'] = this.name;
    json[r'quotaBytes'] = this.quotaBytes;
    return json;
  }

  /// Returns a new [KeepPairing] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static KeepPairing? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "KeepPairing[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "KeepPairing[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return KeepPairing(
        guestId: mapValueOfType<String>(json, r'guestId')!,
        secret: mapValueOfType<String>(json, r'secret')!,
        name: mapValueOfType<String>(json, r'name')!,
        quotaBytes: mapValueOfType<int>(json, r'quotaBytes')!,
      );
    }
    return null;
  }

  static List<KeepPairing> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <KeepPairing>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = KeepPairing.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, KeepPairing> mapFromJson(dynamic json) {
    final map = <String, KeepPairing>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = KeepPairing.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of KeepPairing-objects as value to a dart map
  static Map<String, List<KeepPairing>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<KeepPairing>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = KeepPairing.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'guestId',
    'secret',
    'name',
    'quotaBytes',
  };
}

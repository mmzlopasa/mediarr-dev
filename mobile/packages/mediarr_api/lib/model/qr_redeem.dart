//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class QRRedeem {
  /// Returns a new [QRRedeem] instance.
  QRRedeem({
    required this.code,
    required this.device,
  });

  String code;

  String device;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QRRedeem && other.code == code && other.device == device;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (code.hashCode) + (device.hashCode);

  @override
  String toString() => 'QRRedeem[code=$code, device=$device]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'code'] = this.code;
    json[r'device'] = this.device;
    return json;
  }

  /// Returns a new [QRRedeem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static QRRedeem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "QRRedeem[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "QRRedeem[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return QRRedeem(
        code: mapValueOfType<String>(json, r'code')!,
        device: mapValueOfType<String>(json, r'device')!,
      );
    }
    return null;
  }

  static List<QRRedeem> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <QRRedeem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = QRRedeem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, QRRedeem> mapFromJson(dynamic json) {
    final map = <String, QRRedeem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = QRRedeem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of QRRedeem-objects as value to a dart map
  static Map<String, List<QRRedeem>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<QRRedeem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = QRRedeem.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'code',
    'device',
  };
}

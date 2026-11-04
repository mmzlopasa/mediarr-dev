//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class OIDCSettings {
  /// Returns a new [OIDCSettings] instance.
  OIDCSettings({
    required this.issuer,
    required this.clientId,
    required this.label,
    required this.autoCreate,
    required this.linkAdmins,
    required this.hasSecret,
  });

  String issuer;

  String clientId;

  String label;

  /// A person without an account gets one on first sign-in
  bool autoCreate;

  /// Also link administrators by email. Off is safer
  bool linkAdmins;

  bool hasSecret;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OIDCSettings &&
          other.issuer == issuer &&
          other.clientId == clientId &&
          other.label == label &&
          other.autoCreate == autoCreate &&
          other.linkAdmins == linkAdmins &&
          other.hasSecret == hasSecret;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (issuer.hashCode) +
      (clientId.hashCode) +
      (label.hashCode) +
      (autoCreate.hashCode) +
      (linkAdmins.hashCode) +
      (hasSecret.hashCode);

  @override
  String toString() =>
      'OIDCSettings[issuer=$issuer, clientId=$clientId, label=$label, autoCreate=$autoCreate, linkAdmins=$linkAdmins, hasSecret=$hasSecret]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'issuer'] = this.issuer;
    json[r'clientId'] = this.clientId;
    json[r'label'] = this.label;
    json[r'autoCreate'] = this.autoCreate;
    json[r'linkAdmins'] = this.linkAdmins;
    json[r'hasSecret'] = this.hasSecret;
    return json;
  }

  /// Returns a new [OIDCSettings] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static OIDCSettings? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "OIDCSettings[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "OIDCSettings[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return OIDCSettings(
        issuer: mapValueOfType<String>(json, r'issuer')!,
        clientId: mapValueOfType<String>(json, r'clientId')!,
        label: mapValueOfType<String>(json, r'label')!,
        autoCreate: mapValueOfType<bool>(json, r'autoCreate')!,
        linkAdmins: mapValueOfType<bool>(json, r'linkAdmins')!,
        hasSecret: mapValueOfType<bool>(json, r'hasSecret')!,
      );
    }
    return null;
  }

  static List<OIDCSettings> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <OIDCSettings>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OIDCSettings.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, OIDCSettings> mapFromJson(dynamic json) {
    final map = <String, OIDCSettings>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = OIDCSettings.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of OIDCSettings-objects as value to a dart map
  static Map<String, List<OIDCSettings>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<OIDCSettings>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = OIDCSettings.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'issuer',
    'clientId',
    'label',
    'autoCreate',
    'linkAdmins',
    'hasSecret',
  };
}

//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class OIDCSettingsUpdate {
  /// Returns a new [OIDCSettingsUpdate] instance.
  OIDCSettingsUpdate({
    required this.issuer,
    required this.clientId,
    required this.label,
    required this.autoCreate,
    this.secret,
  });

  String issuer;

  String clientId;

  String label;

  bool autoCreate;

  /// Left out keeps the one that is saved
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? secret;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OIDCSettingsUpdate &&
          other.issuer == issuer &&
          other.clientId == clientId &&
          other.label == label &&
          other.autoCreate == autoCreate &&
          other.secret == secret;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (issuer.hashCode) +
      (clientId.hashCode) +
      (label.hashCode) +
      (autoCreate.hashCode) +
      (secret == null ? 0 : secret!.hashCode);

  @override
  String toString() =>
      'OIDCSettingsUpdate[issuer=$issuer, clientId=$clientId, label=$label, autoCreate=$autoCreate, secret=$secret]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'issuer'] = this.issuer;
    json[r'clientId'] = this.clientId;
    json[r'label'] = this.label;
    json[r'autoCreate'] = this.autoCreate;
    if (this.secret != null) {
      json[r'secret'] = this.secret;
    } else {
      json[r'secret'] = null;
    }
    return json;
  }

  /// Returns a new [OIDCSettingsUpdate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static OIDCSettingsUpdate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "OIDCSettingsUpdate[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "OIDCSettingsUpdate[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return OIDCSettingsUpdate(
        issuer: mapValueOfType<String>(json, r'issuer')!,
        clientId: mapValueOfType<String>(json, r'clientId')!,
        label: mapValueOfType<String>(json, r'label')!,
        autoCreate: mapValueOfType<bool>(json, r'autoCreate')!,
        secret: mapValueOfType<String>(json, r'secret'),
      );
    }
    return null;
  }

  static List<OIDCSettingsUpdate> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <OIDCSettingsUpdate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OIDCSettingsUpdate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, OIDCSettingsUpdate> mapFromJson(dynamic json) {
    final map = <String, OIDCSettingsUpdate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = OIDCSettingsUpdate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of OIDCSettingsUpdate-objects as value to a dart map
  static Map<String, List<OIDCSettingsUpdate>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<OIDCSettingsUpdate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = OIDCSettingsUpdate.listFromJson(
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
  };
}

//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AISettingsUpdate {
  /// Returns a new [AISettingsUpdate] instance.
  AISettingsUpdate({
    required this.address,
    required this.visionModel,
    required this.textModel,
  });

  String address;

  String visionModel;

  String textModel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AISettingsUpdate &&
          other.address == address &&
          other.visionModel == visionModel &&
          other.textModel == textModel;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (address.hashCode) + (visionModel.hashCode) + (textModel.hashCode);

  @override
  String toString() =>
      'AISettingsUpdate[address=$address, visionModel=$visionModel, textModel=$textModel]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'address'] = this.address;
    json[r'visionModel'] = this.visionModel;
    json[r'textModel'] = this.textModel;
    return json;
  }

  /// Returns a new [AISettingsUpdate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AISettingsUpdate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "AISettingsUpdate[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "AISettingsUpdate[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AISettingsUpdate(
        address: mapValueOfType<String>(json, r'address')!,
        visionModel: mapValueOfType<String>(json, r'visionModel')!,
        textModel: mapValueOfType<String>(json, r'textModel')!,
      );
    }
    return null;
  }

  static List<AISettingsUpdate> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AISettingsUpdate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AISettingsUpdate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AISettingsUpdate> mapFromJson(dynamic json) {
    final map = <String, AISettingsUpdate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AISettingsUpdate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AISettingsUpdate-objects as value to a dart map
  static Map<String, List<AISettingsUpdate>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<AISettingsUpdate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AISettingsUpdate.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'address',
    'visionModel',
    'textModel',
  };
}

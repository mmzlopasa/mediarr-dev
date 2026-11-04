//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AISettings {
  /// Returns a new [AISettings] instance.
  AISettings({
    required this.address,
    required this.visionModel,
    required this.textModel,
    required this.reachable,
    required this.modelsReady,
    required this.described,
    required this.total,
  });

  String address;

  String visionModel;

  String textModel;

  bool reachable;

  bool modelsReady;

  int described;

  int total;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AISettings &&
          other.address == address &&
          other.visionModel == visionModel &&
          other.textModel == textModel &&
          other.reachable == reachable &&
          other.modelsReady == modelsReady &&
          other.described == described &&
          other.total == total;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (address.hashCode) +
      (visionModel.hashCode) +
      (textModel.hashCode) +
      (reachable.hashCode) +
      (modelsReady.hashCode) +
      (described.hashCode) +
      (total.hashCode);

  @override
  String toString() =>
      'AISettings[address=$address, visionModel=$visionModel, textModel=$textModel, reachable=$reachable, modelsReady=$modelsReady, described=$described, total=$total]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'address'] = this.address;
    json[r'visionModel'] = this.visionModel;
    json[r'textModel'] = this.textModel;
    json[r'reachable'] = this.reachable;
    json[r'modelsReady'] = this.modelsReady;
    json[r'described'] = this.described;
    json[r'total'] = this.total;
    return json;
  }

  /// Returns a new [AISettings] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AISettings? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "AISettings[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "AISettings[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AISettings(
        address: mapValueOfType<String>(json, r'address')!,
        visionModel: mapValueOfType<String>(json, r'visionModel')!,
        textModel: mapValueOfType<String>(json, r'textModel')!,
        reachable: mapValueOfType<bool>(json, r'reachable')!,
        modelsReady: mapValueOfType<bool>(json, r'modelsReady')!,
        described: mapValueOfType<int>(json, r'described')!,
        total: mapValueOfType<int>(json, r'total')!,
      );
    }
    return null;
  }

  static List<AISettings> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AISettings>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AISettings.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AISettings> mapFromJson(dynamic json) {
    final map = <String, AISettings>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AISettings.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AISettings-objects as value to a dart map
  static Map<String, List<AISettings>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<AISettings>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AISettings.listFromJson(
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
    'reachable',
    'modelsReady',
    'described',
    'total',
  };
}

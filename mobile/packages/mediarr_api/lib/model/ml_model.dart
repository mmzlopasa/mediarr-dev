//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MlModel {
  /// Returns a new [MlModel] instance.
  MlModel({
    required this.name,
    required this.loaded,
    required this.inUse,
    this.idleSeconds,
  });

  String name;

  bool loaded;

  int inUse;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? idleSeconds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MlModel &&
          other.name == name &&
          other.loaded == loaded &&
          other.inUse == inUse &&
          other.idleSeconds == idleSeconds;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (name.hashCode) +
      (loaded.hashCode) +
      (inUse.hashCode) +
      (idleSeconds == null ? 0 : idleSeconds!.hashCode);

  @override
  String toString() =>
      'MlModel[name=$name, loaded=$loaded, inUse=$inUse, idleSeconds=$idleSeconds]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'name'] = this.name;
    json[r'loaded'] = this.loaded;
    json[r'inUse'] = this.inUse;
    if (this.idleSeconds != null) {
      json[r'idleSeconds'] = this.idleSeconds;
    } else {
      json[r'idleSeconds'] = null;
    }
    return json;
  }

  /// Returns a new [MlModel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MlModel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "MlModel[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "MlModel[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return MlModel(
        name: mapValueOfType<String>(json, r'name')!,
        loaded: mapValueOfType<bool>(json, r'loaded')!,
        inUse: mapValueOfType<int>(json, r'inUse')!,
        idleSeconds: mapValueOfType<double>(json, r'idleSeconds'),
      );
    }
    return null;
  }

  static List<MlModel> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <MlModel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MlModel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MlModel> mapFromJson(dynamic json) {
    final map = <String, MlModel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MlModel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MlModel-objects as value to a dart map
  static Map<String, List<MlModel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<MlModel>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MlModel.listFromJson(
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
    'loaded',
    'inUse',
  };
}

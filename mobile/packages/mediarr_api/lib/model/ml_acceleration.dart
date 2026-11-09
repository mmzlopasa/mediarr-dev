//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MlAcceleration {
  /// Returns a new [MlAcceleration] instance.
  MlAcceleration({
    required this.requested,
    this.providers = const [],
  });

  String requested;

  List<String> providers;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MlAcceleration &&
          other.requested == requested &&
          _deepEquality.equals(other.providers, providers);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (requested.hashCode) + (providers.hashCode);

  @override
  String toString() =>
      'MlAcceleration[requested=$requested, providers=$providers]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'requested'] = this.requested;
    json[r'providers'] = this.providers;
    return json;
  }

  /// Returns a new [MlAcceleration] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MlAcceleration? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "MlAcceleration[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "MlAcceleration[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return MlAcceleration(
        requested: mapValueOfType<String>(json, r'requested')!,
        providers: json[r'providers'] is Iterable
            ? (json[r'providers'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<MlAcceleration> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <MlAcceleration>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MlAcceleration.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MlAcceleration> mapFromJson(dynamic json) {
    final map = <String, MlAcceleration>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MlAcceleration.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MlAcceleration-objects as value to a dart map
  static Map<String, List<MlAcceleration>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<MlAcceleration>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MlAcceleration.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'requested',
    'providers',
  };
}

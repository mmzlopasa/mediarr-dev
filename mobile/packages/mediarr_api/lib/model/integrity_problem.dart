//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class IntegrityProblem {
  /// Returns a new [IntegrityProblem] instance.
  IntegrityProblem({
    required this.name,
    required this.path,
    required this.problem,
  });

  String name;

  String path;

  IntegrityProblemProblemEnum problem;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntegrityProblem &&
          other.name == name &&
          other.path == path &&
          other.problem == problem;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (name.hashCode) + (path.hashCode) + (problem.hashCode);

  @override
  String toString() =>
      'IntegrityProblem[name=$name, path=$path, problem=$problem]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'name'] = this.name;
    json[r'path'] = this.path;
    json[r'problem'] = this.problem;
    return json;
  }

  /// Returns a new [IntegrityProblem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static IntegrityProblem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "IntegrityProblem[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "IntegrityProblem[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return IntegrityProblem(
        name: mapValueOfType<String>(json, r'name')!,
        path: mapValueOfType<String>(json, r'path')!,
        problem: IntegrityProblemProblemEnum.fromJson(json[r'problem'])!,
      );
    }
    return null;
  }

  static List<IntegrityProblem> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <IntegrityProblem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = IntegrityProblem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, IntegrityProblem> mapFromJson(dynamic json) {
    final map = <String, IntegrityProblem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = IntegrityProblem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of IntegrityProblem-objects as value to a dart map
  static Map<String, List<IntegrityProblem>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<IntegrityProblem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = IntegrityProblem.listFromJson(
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
    'path',
    'problem',
  };
}

class IntegrityProblemProblemEnum {
  /// Instantiate a new enum with the provided [value].
  const IntegrityProblemProblemEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const missing = IntegrityProblemProblemEnum._(r'missing');
  static const unreadable = IntegrityProblemProblemEnum._(r'unreadable');
  static const changed = IntegrityProblemProblemEnum._(r'changed');

  /// List of all possible values in this [enum][IntegrityProblemProblemEnum].
  static const values = <IntegrityProblemProblemEnum>[
    missing,
    unreadable,
    changed,
  ];

  static IntegrityProblemProblemEnum? fromJson(dynamic value) =>
      IntegrityProblemProblemEnumTypeTransformer().decode(value);

  static List<IntegrityProblemProblemEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <IntegrityProblemProblemEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = IntegrityProblemProblemEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [IntegrityProblemProblemEnum] to String,
/// and [decode] dynamic data back to [IntegrityProblemProblemEnum].
class IntegrityProblemProblemEnumTypeTransformer {
  factory IntegrityProblemProblemEnumTypeTransformer() =>
      _instance ??= const IntegrityProblemProblemEnumTypeTransformer._();

  const IntegrityProblemProblemEnumTypeTransformer._();

  String encode(IntegrityProblemProblemEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a IntegrityProblemProblemEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  IntegrityProblemProblemEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'missing':
          return IntegrityProblemProblemEnum.missing;
        case r'unreadable':
          return IntegrityProblemProblemEnum.unreadable;
        case r'changed':
          return IntegrityProblemProblemEnum.changed;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [IntegrityProblemProblemEnumTypeTransformer] instance.
  static IntegrityProblemProblemEnumTypeTransformer? _instance;
}

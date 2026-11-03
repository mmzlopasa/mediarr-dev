//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MemberRole {
  /// Returns a new [MemberRole] instance.
  MemberRole({
    required this.role,
  });

  MemberRoleRoleEnum role;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MemberRole && other.role == role;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (role.hashCode);

  @override
  String toString() => 'MemberRole[role=$role]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'role'] = this.role;
    return json;
  }

  /// Returns a new [MemberRole] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MemberRole? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "MemberRole[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "MemberRole[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return MemberRole(
        role: MemberRoleRoleEnum.fromJson(json[r'role'])!,
      );
    }
    return null;
  }

  static List<MemberRole> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <MemberRole>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MemberRole.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MemberRole> mapFromJson(dynamic json) {
    final map = <String, MemberRole>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MemberRole.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MemberRole-objects as value to a dart map
  static Map<String, List<MemberRole>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<MemberRole>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MemberRole.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'role',
  };
}

class MemberRoleRoleEnum {
  /// Instantiate a new enum with the provided [value].
  const MemberRoleRoleEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const viewer = MemberRoleRoleEnum._(r'viewer');
  static const contributor = MemberRoleRoleEnum._(r'contributor');
  static const editor = MemberRoleRoleEnum._(r'editor');

  /// List of all possible values in this [enum][MemberRoleRoleEnum].
  static const values = <MemberRoleRoleEnum>[
    viewer,
    contributor,
    editor,
  ];

  static MemberRoleRoleEnum? fromJson(dynamic value) =>
      MemberRoleRoleEnumTypeTransformer().decode(value);

  static List<MemberRoleRoleEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <MemberRoleRoleEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MemberRoleRoleEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [MemberRoleRoleEnum] to String,
/// and [decode] dynamic data back to [MemberRoleRoleEnum].
class MemberRoleRoleEnumTypeTransformer {
  factory MemberRoleRoleEnumTypeTransformer() =>
      _instance ??= const MemberRoleRoleEnumTypeTransformer._();

  const MemberRoleRoleEnumTypeTransformer._();

  String encode(MemberRoleRoleEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a MemberRoleRoleEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  MemberRoleRoleEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'viewer':
          return MemberRoleRoleEnum.viewer;
        case r'contributor':
          return MemberRoleRoleEnum.contributor;
        case r'editor':
          return MemberRoleRoleEnum.editor;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [MemberRoleRoleEnumTypeTransformer] instance.
  static MemberRoleRoleEnumTypeTransformer? _instance;
}

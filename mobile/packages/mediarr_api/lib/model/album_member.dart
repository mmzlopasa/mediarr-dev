//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AlbumMember {
  /// Returns a new [AlbumMember] instance.
  AlbumMember({
    required this.userId,
    required this.name,
    required this.role,
  });

  String userId;

  String name;

  AlbumMemberRoleEnum role;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlbumMember &&
          other.userId == userId &&
          other.name == name &&
          other.role == role;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (userId.hashCode) + (name.hashCode) + (role.hashCode);

  @override
  String toString() => 'AlbumMember[userId=$userId, name=$name, role=$role]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'userId'] = this.userId;
    json[r'name'] = this.name;
    json[r'role'] = this.role;
    return json;
  }

  /// Returns a new [AlbumMember] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AlbumMember? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "AlbumMember[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "AlbumMember[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AlbumMember(
        userId: mapValueOfType<String>(json, r'userId')!,
        name: mapValueOfType<String>(json, r'name')!,
        role: AlbumMemberRoleEnum.fromJson(json[r'role'])!,
      );
    }
    return null;
  }

  static List<AlbumMember> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AlbumMember>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AlbumMember.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AlbumMember> mapFromJson(dynamic json) {
    final map = <String, AlbumMember>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AlbumMember.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AlbumMember-objects as value to a dart map
  static Map<String, List<AlbumMember>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<AlbumMember>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AlbumMember.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'userId',
    'name',
    'role',
  };
}

class AlbumMemberRoleEnum {
  /// Instantiate a new enum with the provided [value].
  const AlbumMemberRoleEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const viewer = AlbumMemberRoleEnum._(r'viewer');
  static const contributor = AlbumMemberRoleEnum._(r'contributor');
  static const editor = AlbumMemberRoleEnum._(r'editor');

  /// List of all possible values in this [enum][AlbumMemberRoleEnum].
  static const values = <AlbumMemberRoleEnum>[
    viewer,
    contributor,
    editor,
  ];

  static AlbumMemberRoleEnum? fromJson(dynamic value) =>
      AlbumMemberRoleEnumTypeTransformer().decode(value);

  static List<AlbumMemberRoleEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AlbumMemberRoleEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AlbumMemberRoleEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AlbumMemberRoleEnum] to String,
/// and [decode] dynamic data back to [AlbumMemberRoleEnum].
class AlbumMemberRoleEnumTypeTransformer {
  factory AlbumMemberRoleEnumTypeTransformer() =>
      _instance ??= const AlbumMemberRoleEnumTypeTransformer._();

  const AlbumMemberRoleEnumTypeTransformer._();

  String encode(AlbumMemberRoleEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a AlbumMemberRoleEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AlbumMemberRoleEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'viewer':
          return AlbumMemberRoleEnum.viewer;
        case r'contributor':
          return AlbumMemberRoleEnum.contributor;
        case r'editor':
          return AlbumMemberRoleEnum.editor;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [AlbumMemberRoleEnumTypeTransformer] instance.
  static AlbumMemberRoleEnumTypeTransformer? _instance;
}

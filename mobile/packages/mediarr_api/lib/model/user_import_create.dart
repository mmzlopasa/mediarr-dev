//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UserImportCreate {
  /// Returns a new [UserImportCreate] instance.
  UserImportCreate({
    required this.source_,
  });

  UserImportCreateSource_Enum source_;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserImportCreate && other.source_ == source_;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (source_.hashCode);

  @override
  String toString() => 'UserImportCreate[source_=$source_]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'source'] = this.source_;
    return json;
  }

  /// Returns a new [UserImportCreate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UserImportCreate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "UserImportCreate[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "UserImportCreate[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return UserImportCreate(
        source_: UserImportCreateSource_Enum.fromJson(json[r'source'])!,
      );
    }
    return null;
  }

  static List<UserImportCreate> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UserImportCreate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UserImportCreate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UserImportCreate> mapFromJson(dynamic json) {
    final map = <String, UserImportCreate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UserImportCreate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UserImportCreate-objects as value to a dart map
  static Map<String, List<UserImportCreate>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<UserImportCreate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UserImportCreate.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'source',
  };
}

class UserImportCreateSource_Enum {
  /// Instantiate a new enum with the provided [value].
  const UserImportCreateSource_Enum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const takeout = UserImportCreateSource_Enum._(r'takeout');
  static const icloud = UserImportCreateSource_Enum._(r'icloud');

  /// List of all possible values in this [enum][UserImportCreateSource_Enum].
  static const values = <UserImportCreateSource_Enum>[
    takeout,
    icloud,
  ];

  static UserImportCreateSource_Enum? fromJson(dynamic value) =>
      UserImportCreateSource_EnumTypeTransformer().decode(value);

  static List<UserImportCreateSource_Enum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UserImportCreateSource_Enum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UserImportCreateSource_Enum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [UserImportCreateSource_Enum] to String,
/// and [decode] dynamic data back to [UserImportCreateSource_Enum].
class UserImportCreateSource_EnumTypeTransformer {
  factory UserImportCreateSource_EnumTypeTransformer() =>
      _instance ??= const UserImportCreateSource_EnumTypeTransformer._();

  const UserImportCreateSource_EnumTypeTransformer._();

  String encode(UserImportCreateSource_Enum data) => data.value;

  /// Decodes a [dynamic value][data] to a UserImportCreateSource_Enum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  UserImportCreateSource_Enum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'takeout':
          return UserImportCreateSource_Enum.takeout;
        case r'icloud':
          return UserImportCreateSource_Enum.icloud;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [UserImportCreateSource_EnumTypeTransformer] instance.
  static UserImportCreateSource_EnumTypeTransformer? _instance;
}

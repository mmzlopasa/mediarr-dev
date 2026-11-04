//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ApiKeyCreate {
  /// Returns a new [ApiKeyCreate] instance.
  ApiKeyCreate({
    required this.name,
    this.scopes = const [],
    this.expiresInDays,
  });

  String name;

  List<ApiKeyCreateScopesEnum> scopes;

  /// Minimum value: 1
  /// Maximum value: 3650
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? expiresInDays;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiKeyCreate &&
          other.name == name &&
          _deepEquality.equals(other.scopes, scopes) &&
          other.expiresInDays == expiresInDays;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (name.hashCode) +
      (scopes.hashCode) +
      (expiresInDays == null ? 0 : expiresInDays!.hashCode);

  @override
  String toString() =>
      'ApiKeyCreate[name=$name, scopes=$scopes, expiresInDays=$expiresInDays]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'name'] = this.name;
    json[r'scopes'] = this.scopes;
    if (this.expiresInDays != null) {
      json[r'expiresInDays'] = this.expiresInDays;
    } else {
      json[r'expiresInDays'] = null;
    }
    return json;
  }

  /// Returns a new [ApiKeyCreate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ApiKeyCreate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ApiKeyCreate[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ApiKeyCreate[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ApiKeyCreate(
        name: mapValueOfType<String>(json, r'name')!,
        scopes: ApiKeyCreateScopesEnum.listFromJson(json[r'scopes']),
        expiresInDays: mapValueOfType<int>(json, r'expiresInDays'),
      );
    }
    return null;
  }

  static List<ApiKeyCreate> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ApiKeyCreate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ApiKeyCreate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ApiKeyCreate> mapFromJson(dynamic json) {
    final map = <String, ApiKeyCreate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ApiKeyCreate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ApiKeyCreate-objects as value to a dart map
  static Map<String, List<ApiKeyCreate>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ApiKeyCreate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ApiKeyCreate.listFromJson(
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
    'scopes',
  };
}

class ApiKeyCreateScopesEnum {
  /// Instantiate a new enum with the provided [value].
  const ApiKeyCreateScopesEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const read = ApiKeyCreateScopesEnum._(r'read');
  static const upload = ApiKeyCreateScopesEnum._(r'upload');
  static const write = ApiKeyCreateScopesEnum._(r'write');
  static const admin = ApiKeyCreateScopesEnum._(r'admin');

  /// List of all possible values in this [enum][ApiKeyCreateScopesEnum].
  static const values = <ApiKeyCreateScopesEnum>[
    read,
    upload,
    write,
    admin,
  ];

  static ApiKeyCreateScopesEnum? fromJson(dynamic value) =>
      ApiKeyCreateScopesEnumTypeTransformer().decode(value);

  static List<ApiKeyCreateScopesEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ApiKeyCreateScopesEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ApiKeyCreateScopesEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ApiKeyCreateScopesEnum] to String,
/// and [decode] dynamic data back to [ApiKeyCreateScopesEnum].
class ApiKeyCreateScopesEnumTypeTransformer {
  factory ApiKeyCreateScopesEnumTypeTransformer() =>
      _instance ??= const ApiKeyCreateScopesEnumTypeTransformer._();

  const ApiKeyCreateScopesEnumTypeTransformer._();

  String encode(ApiKeyCreateScopesEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ApiKeyCreateScopesEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ApiKeyCreateScopesEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'read':
          return ApiKeyCreateScopesEnum.read;
        case r'upload':
          return ApiKeyCreateScopesEnum.upload;
        case r'write':
          return ApiKeyCreateScopesEnum.write;
        case r'admin':
          return ApiKeyCreateScopesEnum.admin;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ApiKeyCreateScopesEnumTypeTransformer] instance.
  static ApiKeyCreateScopesEnumTypeTransformer? _instance;
}

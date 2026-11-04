//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ApiKey {
  /// Returns a new [ApiKey] instance.
  ApiKey({
    required this.id,
    required this.name,
    this.scopes = const [],
    required this.createdAt,
    this.lastUsedAt,
    this.expiresAt,
  });

  String id;

  String name;

  List<ApiKeyScopesEnum> scopes;

  DateTime createdAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? lastUsedAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? expiresAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiKey &&
          other.id == id &&
          other.name == name &&
          _deepEquality.equals(other.scopes, scopes) &&
          other.createdAt == createdAt &&
          other.lastUsedAt == lastUsedAt &&
          other.expiresAt == expiresAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (name.hashCode) +
      (scopes.hashCode) +
      (createdAt.hashCode) +
      (lastUsedAt == null ? 0 : lastUsedAt!.hashCode) +
      (expiresAt == null ? 0 : expiresAt!.hashCode);

  @override
  String toString() =>
      'ApiKey[id=$id, name=$name, scopes=$scopes, createdAt=$createdAt, lastUsedAt=$lastUsedAt, expiresAt=$expiresAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'name'] = this.name;
    json[r'scopes'] = this.scopes;
    json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    if (this.lastUsedAt != null) {
      json[r'lastUsedAt'] = this.lastUsedAt!.toUtc().toIso8601String();
    } else {
      json[r'lastUsedAt'] = null;
    }
    if (this.expiresAt != null) {
      json[r'expiresAt'] = this.expiresAt!.toUtc().toIso8601String();
    } else {
      json[r'expiresAt'] = null;
    }
    return json;
  }

  /// Returns a new [ApiKey] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ApiKey? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ApiKey[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ApiKey[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ApiKey(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        scopes: ApiKeyScopesEnum.listFromJson(json[r'scopes']),
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        lastUsedAt: mapDateTime(json, r'lastUsedAt', r''),
        expiresAt: mapDateTime(json, r'expiresAt', r''),
      );
    }
    return null;
  }

  static List<ApiKey> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ApiKey>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ApiKey.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ApiKey> mapFromJson(dynamic json) {
    final map = <String, ApiKey>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ApiKey.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ApiKey-objects as value to a dart map
  static Map<String, List<ApiKey>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ApiKey>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ApiKey.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'scopes',
    'createdAt',
  };
}

class ApiKeyScopesEnum {
  /// Instantiate a new enum with the provided [value].
  const ApiKeyScopesEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const read = ApiKeyScopesEnum._(r'read');
  static const upload = ApiKeyScopesEnum._(r'upload');
  static const write = ApiKeyScopesEnum._(r'write');
  static const admin = ApiKeyScopesEnum._(r'admin');

  /// List of all possible values in this [enum][ApiKeyScopesEnum].
  static const values = <ApiKeyScopesEnum>[
    read,
    upload,
    write,
    admin,
  ];

  static ApiKeyScopesEnum? fromJson(dynamic value) =>
      ApiKeyScopesEnumTypeTransformer().decode(value);

  static List<ApiKeyScopesEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ApiKeyScopesEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ApiKeyScopesEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ApiKeyScopesEnum] to String,
/// and [decode] dynamic data back to [ApiKeyScopesEnum].
class ApiKeyScopesEnumTypeTransformer {
  factory ApiKeyScopesEnumTypeTransformer() =>
      _instance ??= const ApiKeyScopesEnumTypeTransformer._();

  const ApiKeyScopesEnumTypeTransformer._();

  String encode(ApiKeyScopesEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ApiKeyScopesEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ApiKeyScopesEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'read':
          return ApiKeyScopesEnum.read;
        case r'upload':
          return ApiKeyScopesEnum.upload;
        case r'write':
          return ApiKeyScopesEnum.write;
        case r'admin':
          return ApiKeyScopesEnum.admin;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ApiKeyScopesEnumTypeTransformer] instance.
  static ApiKeyScopesEnumTypeTransformer? _instance;
}

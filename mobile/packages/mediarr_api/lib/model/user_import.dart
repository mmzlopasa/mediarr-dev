//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UserImport {
  /// Returns a new [UserImport] instance.
  UserImport({
    required this.id,
    required this.source_,
    required this.status,
    required this.fromZip,
    this.parts = const [],
    required this.total,
    required this.added,
    required this.skipped,
    required this.failed,
    required this.lastError,
    required this.createdAt,
    this.finishedAt,
  });

  String id;

  UserImportSource_Enum source_;

  UserImportStatusEnum status;

  bool fromZip;

  List<ImportPart> parts;

  /// Files found, known once the import has read its ZIP files
  int total;

  int added;

  /// Already there, or deleted at the source
  int skipped;

  int failed;

  String lastError;

  DateTime createdAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? finishedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserImport &&
          other.id == id &&
          other.source_ == source_ &&
          other.status == status &&
          other.fromZip == fromZip &&
          _deepEquality.equals(other.parts, parts) &&
          other.total == total &&
          other.added == added &&
          other.skipped == skipped &&
          other.failed == failed &&
          other.lastError == lastError &&
          other.createdAt == createdAt &&
          other.finishedAt == finishedAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (source_.hashCode) +
      (status.hashCode) +
      (fromZip.hashCode) +
      (parts.hashCode) +
      (total.hashCode) +
      (added.hashCode) +
      (skipped.hashCode) +
      (failed.hashCode) +
      (lastError.hashCode) +
      (createdAt.hashCode) +
      (finishedAt == null ? 0 : finishedAt!.hashCode);

  @override
  String toString() =>
      'UserImport[id=$id, source_=$source_, status=$status, fromZip=$fromZip, parts=$parts, total=$total, added=$added, skipped=$skipped, failed=$failed, lastError=$lastError, createdAt=$createdAt, finishedAt=$finishedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'source'] = this.source_;
    json[r'status'] = this.status;
    json[r'fromZip'] = this.fromZip;
    json[r'parts'] = this.parts;
    json[r'total'] = this.total;
    json[r'added'] = this.added;
    json[r'skipped'] = this.skipped;
    json[r'failed'] = this.failed;
    json[r'lastError'] = this.lastError;
    json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    if (this.finishedAt != null) {
      json[r'finishedAt'] = this.finishedAt!.toUtc().toIso8601String();
    } else {
      json[r'finishedAt'] = null;
    }
    return json;
  }

  /// Returns a new [UserImport] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UserImport? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "UserImport[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "UserImport[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return UserImport(
        id: mapValueOfType<String>(json, r'id')!,
        source_: UserImportSource_Enum.fromJson(json[r'source'])!,
        status: UserImportStatusEnum.fromJson(json[r'status'])!,
        fromZip: mapValueOfType<bool>(json, r'fromZip')!,
        parts: ImportPart.listFromJson(json[r'parts']),
        total: mapValueOfType<int>(json, r'total')!,
        added: mapValueOfType<int>(json, r'added')!,
        skipped: mapValueOfType<int>(json, r'skipped')!,
        failed: mapValueOfType<int>(json, r'failed')!,
        lastError: mapValueOfType<String>(json, r'lastError')!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        finishedAt: mapDateTime(json, r'finishedAt', r''),
      );
    }
    return null;
  }

  static List<UserImport> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UserImport>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UserImport.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UserImport> mapFromJson(dynamic json) {
    final map = <String, UserImport>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UserImport.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UserImport-objects as value to a dart map
  static Map<String, List<UserImport>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<UserImport>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UserImport.listFromJson(
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
    'source',
    'status',
    'fromZip',
    'parts',
    'total',
    'added',
    'skipped',
    'failed',
    'lastError',
    'createdAt',
  };
}

class UserImportSource_Enum {
  /// Instantiate a new enum with the provided [value].
  const UserImportSource_Enum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const immich = UserImportSource_Enum._(r'immich');
  static const takeout = UserImportSource_Enum._(r'takeout');
  static const icloud = UserImportSource_Enum._(r'icloud');

  /// List of all possible values in this [enum][UserImportSource_Enum].
  static const values = <UserImportSource_Enum>[
    immich,
    takeout,
    icloud,
  ];

  static UserImportSource_Enum? fromJson(dynamic value) =>
      UserImportSource_EnumTypeTransformer().decode(value);

  static List<UserImportSource_Enum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UserImportSource_Enum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UserImportSource_Enum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [UserImportSource_Enum] to String,
/// and [decode] dynamic data back to [UserImportSource_Enum].
class UserImportSource_EnumTypeTransformer {
  factory UserImportSource_EnumTypeTransformer() =>
      _instance ??= const UserImportSource_EnumTypeTransformer._();

  const UserImportSource_EnumTypeTransformer._();

  String encode(UserImportSource_Enum data) => data.value;

  /// Decodes a [dynamic value][data] to a UserImportSource_Enum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  UserImportSource_Enum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'immich':
          return UserImportSource_Enum.immich;
        case r'takeout':
          return UserImportSource_Enum.takeout;
        case r'icloud':
          return UserImportSource_Enum.icloud;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [UserImportSource_EnumTypeTransformer] instance.
  static UserImportSource_EnumTypeTransformer? _instance;
}

class UserImportStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const UserImportStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const uploading = UserImportStatusEnum._(r'uploading');
  static const running = UserImportStatusEnum._(r'running');
  static const done = UserImportStatusEnum._(r'done');
  static const failed = UserImportStatusEnum._(r'failed');
  static const cancelled = UserImportStatusEnum._(r'cancelled');

  /// List of all possible values in this [enum][UserImportStatusEnum].
  static const values = <UserImportStatusEnum>[
    uploading,
    running,
    done,
    failed,
    cancelled,
  ];

  static UserImportStatusEnum? fromJson(dynamic value) =>
      UserImportStatusEnumTypeTransformer().decode(value);

  static List<UserImportStatusEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UserImportStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UserImportStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [UserImportStatusEnum] to String,
/// and [decode] dynamic data back to [UserImportStatusEnum].
class UserImportStatusEnumTypeTransformer {
  factory UserImportStatusEnumTypeTransformer() =>
      _instance ??= const UserImportStatusEnumTypeTransformer._();

  const UserImportStatusEnumTypeTransformer._();

  String encode(UserImportStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a UserImportStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  UserImportStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'uploading':
          return UserImportStatusEnum.uploading;
        case r'running':
          return UserImportStatusEnum.running;
        case r'done':
          return UserImportStatusEnum.done;
        case r'failed':
          return UserImportStatusEnum.failed;
        case r'cancelled':
          return UserImportStatusEnum.cancelled;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [UserImportStatusEnumTypeTransformer] instance.
  static UserImportStatusEnumTypeTransformer? _instance;
}

//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ImportDetail {
  /// Returns a new [ImportDetail] instance.
  ImportDetail({
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
    required this.userEmail,
    this.problems = const [],
  });

  String id;

  ImportDetailSource_Enum source_;

  ImportDetailStatusEnum status;

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

  String userEmail;

  List<ImportProblem> problems;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportDetail &&
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
          other.finishedAt == finishedAt &&
          other.userEmail == userEmail &&
          _deepEquality.equals(other.problems, problems);

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
      (finishedAt == null ? 0 : finishedAt!.hashCode) +
      (userEmail.hashCode) +
      (problems.hashCode);

  @override
  String toString() =>
      'ImportDetail[id=$id, source_=$source_, status=$status, fromZip=$fromZip, parts=$parts, total=$total, added=$added, skipped=$skipped, failed=$failed, lastError=$lastError, createdAt=$createdAt, finishedAt=$finishedAt, userEmail=$userEmail, problems=$problems]';

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
    json[r'userEmail'] = this.userEmail;
    json[r'problems'] = this.problems;
    return json;
  }

  /// Returns a new [ImportDetail] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ImportDetail? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ImportDetail[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ImportDetail[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ImportDetail(
        id: mapValueOfType<String>(json, r'id')!,
        source_: ImportDetailSource_Enum.fromJson(json[r'source'])!,
        status: ImportDetailStatusEnum.fromJson(json[r'status'])!,
        fromZip: mapValueOfType<bool>(json, r'fromZip')!,
        parts: ImportPart.listFromJson(json[r'parts']),
        total: mapValueOfType<int>(json, r'total')!,
        added: mapValueOfType<int>(json, r'added')!,
        skipped: mapValueOfType<int>(json, r'skipped')!,
        failed: mapValueOfType<int>(json, r'failed')!,
        lastError: mapValueOfType<String>(json, r'lastError')!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        finishedAt: mapDateTime(json, r'finishedAt', r''),
        userEmail: mapValueOfType<String>(json, r'userEmail')!,
        problems: ImportProblem.listFromJson(json[r'problems']),
      );
    }
    return null;
  }

  static List<ImportDetail> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ImportDetail>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ImportDetail.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ImportDetail> mapFromJson(dynamic json) {
    final map = <String, ImportDetail>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ImportDetail.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ImportDetail-objects as value to a dart map
  static Map<String, List<ImportDetail>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ImportDetail>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ImportDetail.listFromJson(
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
    'userEmail',
    'problems',
  };
}

class ImportDetailSource_Enum {
  /// Instantiate a new enum with the provided [value].
  const ImportDetailSource_Enum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const immich = ImportDetailSource_Enum._(r'immich');
  static const takeout = ImportDetailSource_Enum._(r'takeout');
  static const icloud = ImportDetailSource_Enum._(r'icloud');

  /// List of all possible values in this [enum][ImportDetailSource_Enum].
  static const values = <ImportDetailSource_Enum>[
    immich,
    takeout,
    icloud,
  ];

  static ImportDetailSource_Enum? fromJson(dynamic value) =>
      ImportDetailSource_EnumTypeTransformer().decode(value);

  static List<ImportDetailSource_Enum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ImportDetailSource_Enum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ImportDetailSource_Enum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ImportDetailSource_Enum] to String,
/// and [decode] dynamic data back to [ImportDetailSource_Enum].
class ImportDetailSource_EnumTypeTransformer {
  factory ImportDetailSource_EnumTypeTransformer() =>
      _instance ??= const ImportDetailSource_EnumTypeTransformer._();

  const ImportDetailSource_EnumTypeTransformer._();

  String encode(ImportDetailSource_Enum data) => data.value;

  /// Decodes a [dynamic value][data] to a ImportDetailSource_Enum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ImportDetailSource_Enum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'immich':
          return ImportDetailSource_Enum.immich;
        case r'takeout':
          return ImportDetailSource_Enum.takeout;
        case r'icloud':
          return ImportDetailSource_Enum.icloud;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ImportDetailSource_EnumTypeTransformer] instance.
  static ImportDetailSource_EnumTypeTransformer? _instance;
}

class ImportDetailStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const ImportDetailStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const uploading = ImportDetailStatusEnum._(r'uploading');
  static const running = ImportDetailStatusEnum._(r'running');
  static const done = ImportDetailStatusEnum._(r'done');
  static const failed = ImportDetailStatusEnum._(r'failed');
  static const cancelled = ImportDetailStatusEnum._(r'cancelled');

  /// List of all possible values in this [enum][ImportDetailStatusEnum].
  static const values = <ImportDetailStatusEnum>[
    uploading,
    running,
    done,
    failed,
    cancelled,
  ];

  static ImportDetailStatusEnum? fromJson(dynamic value) =>
      ImportDetailStatusEnumTypeTransformer().decode(value);

  static List<ImportDetailStatusEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ImportDetailStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ImportDetailStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ImportDetailStatusEnum] to String,
/// and [decode] dynamic data back to [ImportDetailStatusEnum].
class ImportDetailStatusEnumTypeTransformer {
  factory ImportDetailStatusEnumTypeTransformer() =>
      _instance ??= const ImportDetailStatusEnumTypeTransformer._();

  const ImportDetailStatusEnumTypeTransformer._();

  String encode(ImportDetailStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ImportDetailStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ImportDetailStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'uploading':
          return ImportDetailStatusEnum.uploading;
        case r'running':
          return ImportDetailStatusEnum.running;
        case r'done':
          return ImportDetailStatusEnum.done;
        case r'failed':
          return ImportDetailStatusEnum.failed;
        case r'cancelled':
          return ImportDetailStatusEnum.cancelled;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ImportDetailStatusEnumTypeTransformer] instance.
  static ImportDetailStatusEnumTypeTransformer? _instance;
}

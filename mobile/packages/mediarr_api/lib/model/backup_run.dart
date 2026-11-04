//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class BackupRun {
  /// Returns a new [BackupRun] instance.
  BackupRun({
    required this.id,
    required this.kind,
    required this.status,
    required this.message,
    required this.files,
    required this.startedAt,
    this.finishedAt,
  });

  String id;

  BackupRunKindEnum kind;

  BackupRunStatusEnum status;

  String message;

  int files;

  DateTime startedAt;

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
      other is BackupRun &&
          other.id == id &&
          other.kind == kind &&
          other.status == status &&
          other.message == message &&
          other.files == files &&
          other.startedAt == startedAt &&
          other.finishedAt == finishedAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (kind.hashCode) +
      (status.hashCode) +
      (message.hashCode) +
      (files.hashCode) +
      (startedAt.hashCode) +
      (finishedAt == null ? 0 : finishedAt!.hashCode);

  @override
  String toString() =>
      'BackupRun[id=$id, kind=$kind, status=$status, message=$message, files=$files, startedAt=$startedAt, finishedAt=$finishedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'kind'] = this.kind;
    json[r'status'] = this.status;
    json[r'message'] = this.message;
    json[r'files'] = this.files;
    json[r'startedAt'] = this.startedAt.toUtc().toIso8601String();
    if (this.finishedAt != null) {
      json[r'finishedAt'] = this.finishedAt!.toUtc().toIso8601String();
    } else {
      json[r'finishedAt'] = null;
    }
    return json;
  }

  /// Returns a new [BackupRun] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BackupRun? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "BackupRun[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "BackupRun[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return BackupRun(
        id: mapValueOfType<String>(json, r'id')!,
        kind: BackupRunKindEnum.fromJson(json[r'kind'])!,
        status: BackupRunStatusEnum.fromJson(json[r'status'])!,
        message: mapValueOfType<String>(json, r'message')!,
        files: mapValueOfType<int>(json, r'files')!,
        startedAt: mapDateTime(json, r'startedAt', r'')!,
        finishedAt: mapDateTime(json, r'finishedAt', r''),
      );
    }
    return null;
  }

  static List<BackupRun> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <BackupRun>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BackupRun.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BackupRun> mapFromJson(dynamic json) {
    final map = <String, BackupRun>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BackupRun.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BackupRun-objects as value to a dart map
  static Map<String, List<BackupRun>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<BackupRun>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BackupRun.listFromJson(
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
    'kind',
    'status',
    'message',
    'files',
    'startedAt',
  };
}

class BackupRunKindEnum {
  /// Instantiate a new enum with the provided [value].
  const BackupRunKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const backup = BackupRunKindEnum._(r'backup');
  static const restoreTest = BackupRunKindEnum._(r'restore_test');

  /// List of all possible values in this [enum][BackupRunKindEnum].
  static const values = <BackupRunKindEnum>[
    backup,
    restoreTest,
  ];

  static BackupRunKindEnum? fromJson(dynamic value) =>
      BackupRunKindEnumTypeTransformer().decode(value);

  static List<BackupRunKindEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <BackupRunKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BackupRunKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [BackupRunKindEnum] to String,
/// and [decode] dynamic data back to [BackupRunKindEnum].
class BackupRunKindEnumTypeTransformer {
  factory BackupRunKindEnumTypeTransformer() =>
      _instance ??= const BackupRunKindEnumTypeTransformer._();

  const BackupRunKindEnumTypeTransformer._();

  String encode(BackupRunKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a BackupRunKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  BackupRunKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'backup':
          return BackupRunKindEnum.backup;
        case r'restore_test':
          return BackupRunKindEnum.restoreTest;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [BackupRunKindEnumTypeTransformer] instance.
  static BackupRunKindEnumTypeTransformer? _instance;
}

class BackupRunStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const BackupRunStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const running = BackupRunStatusEnum._(r'running');
  static const done = BackupRunStatusEnum._(r'done');
  static const failed = BackupRunStatusEnum._(r'failed');

  /// List of all possible values in this [enum][BackupRunStatusEnum].
  static const values = <BackupRunStatusEnum>[
    running,
    done,
    failed,
  ];

  static BackupRunStatusEnum? fromJson(dynamic value) =>
      BackupRunStatusEnumTypeTransformer().decode(value);

  static List<BackupRunStatusEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <BackupRunStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BackupRunStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [BackupRunStatusEnum] to String,
/// and [decode] dynamic data back to [BackupRunStatusEnum].
class BackupRunStatusEnumTypeTransformer {
  factory BackupRunStatusEnumTypeTransformer() =>
      _instance ??= const BackupRunStatusEnumTypeTransformer._();

  const BackupRunStatusEnumTypeTransformer._();

  String encode(BackupRunStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a BackupRunStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  BackupRunStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'running':
          return BackupRunStatusEnum.running;
        case r'done':
          return BackupRunStatusEnum.done;
        case r'failed':
          return BackupRunStatusEnum.failed;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [BackupRunStatusEnumTypeTransformer] instance.
  static BackupRunStatusEnumTypeTransformer? _instance;
}

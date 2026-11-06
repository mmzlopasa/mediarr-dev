//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ImportEntry {
  /// Returns a new [ImportEntry] instance.
  ImportEntry({
    required this.id,
    required this.userEmail,
    required this.source_,
    required this.status,
    required this.fromZip,
    required this.total,
    required this.added,
    required this.skipped,
    required this.failed,
    required this.lastError,
    required this.createdAt,
    this.finishedAt,
  });

  String id;

  String userEmail;

  ImportEntrySource_Enum source_;

  ImportEntryStatusEnum status;

  /// Uploaded as ZIP files by the user, not from a folder
  bool fromZip;

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
      other is ImportEntry &&
          other.id == id &&
          other.userEmail == userEmail &&
          other.source_ == source_ &&
          other.status == status &&
          other.fromZip == fromZip &&
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
      (userEmail.hashCode) +
      (source_.hashCode) +
      (status.hashCode) +
      (fromZip.hashCode) +
      (total.hashCode) +
      (added.hashCode) +
      (skipped.hashCode) +
      (failed.hashCode) +
      (lastError.hashCode) +
      (createdAt.hashCode) +
      (finishedAt == null ? 0 : finishedAt!.hashCode);

  @override
  String toString() =>
      'ImportEntry[id=$id, userEmail=$userEmail, source_=$source_, status=$status, fromZip=$fromZip, total=$total, added=$added, skipped=$skipped, failed=$failed, lastError=$lastError, createdAt=$createdAt, finishedAt=$finishedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'userEmail'] = this.userEmail;
    json[r'source'] = this.source_;
    json[r'status'] = this.status;
    json[r'fromZip'] = this.fromZip;
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

  /// Returns a new [ImportEntry] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ImportEntry? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ImportEntry[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ImportEntry[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ImportEntry(
        id: mapValueOfType<String>(json, r'id')!,
        userEmail: mapValueOfType<String>(json, r'userEmail')!,
        source_: ImportEntrySource_Enum.fromJson(json[r'source'])!,
        status: ImportEntryStatusEnum.fromJson(json[r'status'])!,
        fromZip: mapValueOfType<bool>(json, r'fromZip')!,
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

  static List<ImportEntry> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ImportEntry>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ImportEntry.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ImportEntry> mapFromJson(dynamic json) {
    final map = <String, ImportEntry>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ImportEntry.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ImportEntry-objects as value to a dart map
  static Map<String, List<ImportEntry>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ImportEntry>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ImportEntry.listFromJson(
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
    'userEmail',
    'source',
    'status',
    'fromZip',
    'total',
    'added',
    'skipped',
    'failed',
    'lastError',
    'createdAt',
  };
}

class ImportEntrySource_Enum {
  /// Instantiate a new enum with the provided [value].
  const ImportEntrySource_Enum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const immich = ImportEntrySource_Enum._(r'immich');
  static const takeout = ImportEntrySource_Enum._(r'takeout');
  static const icloud = ImportEntrySource_Enum._(r'icloud');

  /// List of all possible values in this [enum][ImportEntrySource_Enum].
  static const values = <ImportEntrySource_Enum>[
    immich,
    takeout,
    icloud,
  ];

  static ImportEntrySource_Enum? fromJson(dynamic value) =>
      ImportEntrySource_EnumTypeTransformer().decode(value);

  static List<ImportEntrySource_Enum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ImportEntrySource_Enum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ImportEntrySource_Enum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ImportEntrySource_Enum] to String,
/// and [decode] dynamic data back to [ImportEntrySource_Enum].
class ImportEntrySource_EnumTypeTransformer {
  factory ImportEntrySource_EnumTypeTransformer() =>
      _instance ??= const ImportEntrySource_EnumTypeTransformer._();

  const ImportEntrySource_EnumTypeTransformer._();

  String encode(ImportEntrySource_Enum data) => data.value;

  /// Decodes a [dynamic value][data] to a ImportEntrySource_Enum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ImportEntrySource_Enum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'immich':
          return ImportEntrySource_Enum.immich;
        case r'takeout':
          return ImportEntrySource_Enum.takeout;
        case r'icloud':
          return ImportEntrySource_Enum.icloud;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ImportEntrySource_EnumTypeTransformer] instance.
  static ImportEntrySource_EnumTypeTransformer? _instance;
}

class ImportEntryStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const ImportEntryStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const uploading = ImportEntryStatusEnum._(r'uploading');
  static const running = ImportEntryStatusEnum._(r'running');
  static const done = ImportEntryStatusEnum._(r'done');
  static const failed = ImportEntryStatusEnum._(r'failed');
  static const cancelled = ImportEntryStatusEnum._(r'cancelled');

  /// List of all possible values in this [enum][ImportEntryStatusEnum].
  static const values = <ImportEntryStatusEnum>[
    uploading,
    running,
    done,
    failed,
    cancelled,
  ];

  static ImportEntryStatusEnum? fromJson(dynamic value) =>
      ImportEntryStatusEnumTypeTransformer().decode(value);

  static List<ImportEntryStatusEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ImportEntryStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ImportEntryStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ImportEntryStatusEnum] to String,
/// and [decode] dynamic data back to [ImportEntryStatusEnum].
class ImportEntryStatusEnumTypeTransformer {
  factory ImportEntryStatusEnumTypeTransformer() =>
      _instance ??= const ImportEntryStatusEnumTypeTransformer._();

  const ImportEntryStatusEnumTypeTransformer._();

  String encode(ImportEntryStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ImportEntryStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ImportEntryStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'uploading':
          return ImportEntryStatusEnum.uploading;
        case r'running':
          return ImportEntryStatusEnum.running;
        case r'done':
          return ImportEntryStatusEnum.done;
        case r'failed':
          return ImportEntryStatusEnum.failed;
        case r'cancelled':
          return ImportEntryStatusEnum.cancelled;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ImportEntryStatusEnumTypeTransformer] instance.
  static ImportEntryStatusEnumTypeTransformer? _instance;
}

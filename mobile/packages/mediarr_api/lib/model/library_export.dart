//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LibraryExport {
  /// Returns a new [LibraryExport] instance.
  LibraryExport({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.status,
    required this.startedByAdmin,
    required this.startedBy,
    required this.totalFiles,
    required this.totalBytes,
    required this.doneFiles,
    required this.doneBytes,
    required this.missing,
    required this.lastError,
    required this.createdAt,
    this.finishedAt,
    this.expiresAt,
    this.parts = const [],
    required this.canDownload,
  });

  String id;

  String userId;

  String userEmail;

  /// removed: the parts were removed a week after the export was done
  LibraryExportStatusEnum status;

  /// Started by an administrator, not by the owner
  bool startedByAdmin;

  /// The name of who started it
  String startedBy;

  int totalFiles;

  int totalBytes;

  int doneFiles;

  int doneBytes;

  /// Files in the database that were not on the disk
  int missing;

  String lastError;

  DateTime createdAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? finishedAt;

  /// When the parts are removed
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? expiresAt;

  List<LibraryExportPart> parts;

  /// Whether the one asking may download the parts
  bool canDownload;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LibraryExport &&
          other.id == id &&
          other.userId == userId &&
          other.userEmail == userEmail &&
          other.status == status &&
          other.startedByAdmin == startedByAdmin &&
          other.startedBy == startedBy &&
          other.totalFiles == totalFiles &&
          other.totalBytes == totalBytes &&
          other.doneFiles == doneFiles &&
          other.doneBytes == doneBytes &&
          other.missing == missing &&
          other.lastError == lastError &&
          other.createdAt == createdAt &&
          other.finishedAt == finishedAt &&
          other.expiresAt == expiresAt &&
          _deepEquality.equals(other.parts, parts) &&
          other.canDownload == canDownload;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (userId.hashCode) +
      (userEmail.hashCode) +
      (status.hashCode) +
      (startedByAdmin.hashCode) +
      (startedBy.hashCode) +
      (totalFiles.hashCode) +
      (totalBytes.hashCode) +
      (doneFiles.hashCode) +
      (doneBytes.hashCode) +
      (missing.hashCode) +
      (lastError.hashCode) +
      (createdAt.hashCode) +
      (finishedAt == null ? 0 : finishedAt!.hashCode) +
      (expiresAt == null ? 0 : expiresAt!.hashCode) +
      (parts.hashCode) +
      (canDownload.hashCode);

  @override
  String toString() =>
      'LibraryExport[id=$id, userId=$userId, userEmail=$userEmail, status=$status, startedByAdmin=$startedByAdmin, startedBy=$startedBy, totalFiles=$totalFiles, totalBytes=$totalBytes, doneFiles=$doneFiles, doneBytes=$doneBytes, missing=$missing, lastError=$lastError, createdAt=$createdAt, finishedAt=$finishedAt, expiresAt=$expiresAt, parts=$parts, canDownload=$canDownload]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'userId'] = this.userId;
    json[r'userEmail'] = this.userEmail;
    json[r'status'] = this.status;
    json[r'startedByAdmin'] = this.startedByAdmin;
    json[r'startedBy'] = this.startedBy;
    json[r'totalFiles'] = this.totalFiles;
    json[r'totalBytes'] = this.totalBytes;
    json[r'doneFiles'] = this.doneFiles;
    json[r'doneBytes'] = this.doneBytes;
    json[r'missing'] = this.missing;
    json[r'lastError'] = this.lastError;
    json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    if (this.finishedAt != null) {
      json[r'finishedAt'] = this.finishedAt!.toUtc().toIso8601String();
    } else {
      json[r'finishedAt'] = null;
    }
    if (this.expiresAt != null) {
      json[r'expiresAt'] = this.expiresAt!.toUtc().toIso8601String();
    } else {
      json[r'expiresAt'] = null;
    }
    json[r'parts'] = this.parts;
    json[r'canDownload'] = this.canDownload;
    return json;
  }

  /// Returns a new [LibraryExport] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LibraryExport? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "LibraryExport[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "LibraryExport[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return LibraryExport(
        id: mapValueOfType<String>(json, r'id')!,
        userId: mapValueOfType<String>(json, r'userId')!,
        userEmail: mapValueOfType<String>(json, r'userEmail')!,
        status: LibraryExportStatusEnum.fromJson(json[r'status'])!,
        startedByAdmin: mapValueOfType<bool>(json, r'startedByAdmin')!,
        startedBy: mapValueOfType<String>(json, r'startedBy')!,
        totalFiles: mapValueOfType<int>(json, r'totalFiles')!,
        totalBytes: mapValueOfType<int>(json, r'totalBytes')!,
        doneFiles: mapValueOfType<int>(json, r'doneFiles')!,
        doneBytes: mapValueOfType<int>(json, r'doneBytes')!,
        missing: mapValueOfType<int>(json, r'missing')!,
        lastError: mapValueOfType<String>(json, r'lastError')!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        finishedAt: mapDateTime(json, r'finishedAt', r''),
        expiresAt: mapDateTime(json, r'expiresAt', r''),
        parts: LibraryExportPart.listFromJson(json[r'parts']),
        canDownload: mapValueOfType<bool>(json, r'canDownload')!,
      );
    }
    return null;
  }

  static List<LibraryExport> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <LibraryExport>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LibraryExport.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LibraryExport> mapFromJson(dynamic json) {
    final map = <String, LibraryExport>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LibraryExport.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LibraryExport-objects as value to a dart map
  static Map<String, List<LibraryExport>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<LibraryExport>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LibraryExport.listFromJson(
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
    'userId',
    'userEmail',
    'status',
    'startedByAdmin',
    'startedBy',
    'totalFiles',
    'totalBytes',
    'doneFiles',
    'doneBytes',
    'missing',
    'lastError',
    'createdAt',
    'parts',
    'canDownload',
  };
}

/// removed: the parts were removed a week after the export was done
class LibraryExportStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const LibraryExportStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const running = LibraryExportStatusEnum._(r'running');
  static const done = LibraryExportStatusEnum._(r'done');
  static const failed = LibraryExportStatusEnum._(r'failed');
  static const cancelled = LibraryExportStatusEnum._(r'cancelled');
  static const removed = LibraryExportStatusEnum._(r'removed');

  /// List of all possible values in this [enum][LibraryExportStatusEnum].
  static const values = <LibraryExportStatusEnum>[
    running,
    done,
    failed,
    cancelled,
    removed,
  ];

  static LibraryExportStatusEnum? fromJson(dynamic value) =>
      LibraryExportStatusEnumTypeTransformer().decode(value);

  static List<LibraryExportStatusEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <LibraryExportStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LibraryExportStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [LibraryExportStatusEnum] to String,
/// and [decode] dynamic data back to [LibraryExportStatusEnum].
class LibraryExportStatusEnumTypeTransformer {
  factory LibraryExportStatusEnumTypeTransformer() =>
      _instance ??= const LibraryExportStatusEnumTypeTransformer._();

  const LibraryExportStatusEnumTypeTransformer._();

  String encode(LibraryExportStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a LibraryExportStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  LibraryExportStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'running':
          return LibraryExportStatusEnum.running;
        case r'done':
          return LibraryExportStatusEnum.done;
        case r'failed':
          return LibraryExportStatusEnum.failed;
        case r'cancelled':
          return LibraryExportStatusEnum.cancelled;
        case r'removed':
          return LibraryExportStatusEnum.removed;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [LibraryExportStatusEnumTypeTransformer] instance.
  static LibraryExportStatusEnumTypeTransformer? _instance;
}

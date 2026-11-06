//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Notification {
  /// Returns a new [Notification] instance.
  Notification({
    required this.id,
    required this.kind,
    required this.subject,
    required this.ref,
    required this.createdAt,
    required this.read,
  });

  String id;

  NotificationKindEnum kind;

  /// What it is about: an album's name, an import's source, an error
  String subject;

  /// The album it opens, if any
  String ref;

  DateTime createdAt;

  bool read;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Notification &&
          other.id == id &&
          other.kind == kind &&
          other.subject == subject &&
          other.ref == ref &&
          other.createdAt == createdAt &&
          other.read == read;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (kind.hashCode) +
      (subject.hashCode) +
      (ref.hashCode) +
      (createdAt.hashCode) +
      (read.hashCode);

  @override
  String toString() =>
      'Notification[id=$id, kind=$kind, subject=$subject, ref=$ref, createdAt=$createdAt, read=$read]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'kind'] = this.kind;
    json[r'subject'] = this.subject;
    json[r'ref'] = this.ref;
    json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    json[r'read'] = this.read;
    return json;
  }

  /// Returns a new [Notification] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Notification? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Notification[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Notification[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Notification(
        id: mapValueOfType<String>(json, r'id')!,
        kind: NotificationKindEnum.fromJson(json[r'kind'])!,
        subject: mapValueOfType<String>(json, r'subject')!,
        ref: mapValueOfType<String>(json, r'ref')!,
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        read: mapValueOfType<bool>(json, r'read')!,
      );
    }
    return null;
  }

  static List<Notification> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Notification>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Notification.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Notification> mapFromJson(dynamic json) {
    final map = <String, Notification>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Notification.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Notification-objects as value to a dart map
  static Map<String, List<Notification>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Notification>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Notification.listFromJson(
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
    'subject',
    'ref',
    'createdAt',
    'read',
  };
}

class NotificationKindEnum {
  /// Instantiate a new enum with the provided [value].
  const NotificationKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const albumShared = NotificationKindEnum._(r'album_shared');
  static const importDone = NotificationKindEnum._(r'import_done');
  static const importFailed = NotificationKindEnum._(r'import_failed');
  static const backupFailed = NotificationKindEnum._(r'backup_failed');
  static const backupLate = NotificationKindEnum._(r'backup_late');

  /// List of all possible values in this [enum][NotificationKindEnum].
  static const values = <NotificationKindEnum>[
    albumShared,
    importDone,
    importFailed,
    backupFailed,
    backupLate,
  ];

  static NotificationKindEnum? fromJson(dynamic value) =>
      NotificationKindEnumTypeTransformer().decode(value);

  static List<NotificationKindEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <NotificationKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [NotificationKindEnum] to String,
/// and [decode] dynamic data back to [NotificationKindEnum].
class NotificationKindEnumTypeTransformer {
  factory NotificationKindEnumTypeTransformer() =>
      _instance ??= const NotificationKindEnumTypeTransformer._();

  const NotificationKindEnumTypeTransformer._();

  String encode(NotificationKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a NotificationKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  NotificationKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'album_shared':
          return NotificationKindEnum.albumShared;
        case r'import_done':
          return NotificationKindEnum.importDone;
        case r'import_failed':
          return NotificationKindEnum.importFailed;
        case r'backup_failed':
          return NotificationKindEnum.backupFailed;
        case r'backup_late':
          return NotificationKindEnum.backupLate;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [NotificationKindEnumTypeTransformer] instance.
  static NotificationKindEnumTypeTransformer? _instance;
}

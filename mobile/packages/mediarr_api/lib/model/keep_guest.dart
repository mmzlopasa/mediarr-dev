//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class KeepGuest {
  /// Returns a new [KeepGuest] instance.
  KeepGuest({
    required this.id,
    required this.name,
    required this.status,
    required this.quotaBytes,
    required this.usedBytes,
    required this.deletedBytes,
    required this.address,
    this.inviteExpiresAt,
    this.lastBackupAt,
    this.lastSeenAt,
    required this.createdAt,
  });

  String id;

  String name;

  KeepGuestStatusEnum status;

  int quotaBytes;

  /// Everything kept, what it deleted included
  int usedBytes;

  /// What it deleted, kept for 90 days
  int deletedBytes;

  /// The address of this server the guest was told
  String address;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? inviteExpiresAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? lastBackupAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? lastSeenAt;

  DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeepGuest &&
          other.id == id &&
          other.name == name &&
          other.status == status &&
          other.quotaBytes == quotaBytes &&
          other.usedBytes == usedBytes &&
          other.deletedBytes == deletedBytes &&
          other.address == address &&
          other.inviteExpiresAt == inviteExpiresAt &&
          other.lastBackupAt == lastBackupAt &&
          other.lastSeenAt == lastSeenAt &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (name.hashCode) +
      (status.hashCode) +
      (quotaBytes.hashCode) +
      (usedBytes.hashCode) +
      (deletedBytes.hashCode) +
      (address.hashCode) +
      (inviteExpiresAt == null ? 0 : inviteExpiresAt!.hashCode) +
      (lastBackupAt == null ? 0 : lastBackupAt!.hashCode) +
      (lastSeenAt == null ? 0 : lastSeenAt!.hashCode) +
      (createdAt.hashCode);

  @override
  String toString() =>
      'KeepGuest[id=$id, name=$name, status=$status, quotaBytes=$quotaBytes, usedBytes=$usedBytes, deletedBytes=$deletedBytes, address=$address, inviteExpiresAt=$inviteExpiresAt, lastBackupAt=$lastBackupAt, lastSeenAt=$lastSeenAt, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'name'] = this.name;
    json[r'status'] = this.status;
    json[r'quotaBytes'] = this.quotaBytes;
    json[r'usedBytes'] = this.usedBytes;
    json[r'deletedBytes'] = this.deletedBytes;
    json[r'address'] = this.address;
    if (this.inviteExpiresAt != null) {
      json[r'inviteExpiresAt'] =
          this.inviteExpiresAt!.toUtc().toIso8601String();
    } else {
      json[r'inviteExpiresAt'] = null;
    }
    if (this.lastBackupAt != null) {
      json[r'lastBackupAt'] = this.lastBackupAt!.toUtc().toIso8601String();
    } else {
      json[r'lastBackupAt'] = null;
    }
    if (this.lastSeenAt != null) {
      json[r'lastSeenAt'] = this.lastSeenAt!.toUtc().toIso8601String();
    } else {
      json[r'lastSeenAt'] = null;
    }
    json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [KeepGuest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static KeepGuest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "KeepGuest[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "KeepGuest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return KeepGuest(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        status: KeepGuestStatusEnum.fromJson(json[r'status'])!,
        quotaBytes: mapValueOfType<int>(json, r'quotaBytes')!,
        usedBytes: mapValueOfType<int>(json, r'usedBytes')!,
        deletedBytes: mapValueOfType<int>(json, r'deletedBytes')!,
        address: mapValueOfType<String>(json, r'address')!,
        inviteExpiresAt: mapDateTime(json, r'inviteExpiresAt', r''),
        lastBackupAt: mapDateTime(json, r'lastBackupAt', r''),
        lastSeenAt: mapDateTime(json, r'lastSeenAt', r''),
        createdAt: mapDateTime(json, r'createdAt', r'')!,
      );
    }
    return null;
  }

  static List<KeepGuest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <KeepGuest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = KeepGuest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, KeepGuest> mapFromJson(dynamic json) {
    final map = <String, KeepGuest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = KeepGuest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of KeepGuest-objects as value to a dart map
  static Map<String, List<KeepGuest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<KeepGuest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = KeepGuest.listFromJson(
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
    'status',
    'quotaBytes',
    'usedBytes',
    'deletedBytes',
    'address',
    'createdAt',
  };
}

class KeepGuestStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const KeepGuestStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const invited = KeepGuestStatusEnum._(r'invited');
  static const active = KeepGuestStatusEnum._(r'active');
  static const stopped = KeepGuestStatusEnum._(r'stopped');

  /// List of all possible values in this [enum][KeepGuestStatusEnum].
  static const values = <KeepGuestStatusEnum>[
    invited,
    active,
    stopped,
  ];

  static KeepGuestStatusEnum? fromJson(dynamic value) =>
      KeepGuestStatusEnumTypeTransformer().decode(value);

  static List<KeepGuestStatusEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <KeepGuestStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = KeepGuestStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [KeepGuestStatusEnum] to String,
/// and [decode] dynamic data back to [KeepGuestStatusEnum].
class KeepGuestStatusEnumTypeTransformer {
  factory KeepGuestStatusEnumTypeTransformer() =>
      _instance ??= const KeepGuestStatusEnumTypeTransformer._();

  const KeepGuestStatusEnumTypeTransformer._();

  String encode(KeepGuestStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a KeepGuestStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  KeepGuestStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'invited':
          return KeepGuestStatusEnum.invited;
        case r'active':
          return KeepGuestStatusEnum.active;
        case r'stopped':
          return KeepGuestStatusEnum.stopped;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [KeepGuestStatusEnumTypeTransformer] instance.
  static KeepGuestStatusEnumTypeTransformer? _instance;
}

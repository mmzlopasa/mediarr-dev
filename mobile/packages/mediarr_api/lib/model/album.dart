//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Album {
  /// Returns a new [Album] instance.
  Album({
    required this.id,
    required this.title,
    required this.description,
    required this.role,
    required this.ownerId,
    required this.ownerName,
    required this.assetCount,
    this.coverAssetId,
    required this.order,
    required this.isSmart,
    this.rules,
    this.members = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  String id;

  String title;

  String description;

  AlbumRoleEnum role;

  String ownerId;

  String ownerName;

  int assetCount;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? coverAssetId;

  AlbumOrderEnum order;

  bool isSmart;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  AlbumRules? rules;

  List<AlbumMember> members;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Album &&
          other.id == id &&
          other.title == title &&
          other.description == description &&
          other.role == role &&
          other.ownerId == ownerId &&
          other.ownerName == ownerName &&
          other.assetCount == assetCount &&
          other.coverAssetId == coverAssetId &&
          other.order == order &&
          other.isSmart == isSmart &&
          other.rules == rules &&
          _deepEquality.equals(other.members, members) &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (title.hashCode) +
      (description.hashCode) +
      (role.hashCode) +
      (ownerId.hashCode) +
      (ownerName.hashCode) +
      (assetCount.hashCode) +
      (coverAssetId == null ? 0 : coverAssetId!.hashCode) +
      (order.hashCode) +
      (isSmart.hashCode) +
      (rules == null ? 0 : rules!.hashCode) +
      (members.hashCode) +
      (createdAt.hashCode) +
      (updatedAt.hashCode);

  @override
  String toString() =>
      'Album[id=$id, title=$title, description=$description, role=$role, ownerId=$ownerId, ownerName=$ownerName, assetCount=$assetCount, coverAssetId=$coverAssetId, order=$order, isSmart=$isSmart, rules=$rules, members=$members, createdAt=$createdAt, updatedAt=$updatedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'title'] = this.title;
    json[r'description'] = this.description;
    json[r'role'] = this.role;
    json[r'ownerId'] = this.ownerId;
    json[r'ownerName'] = this.ownerName;
    json[r'assetCount'] = this.assetCount;
    if (this.coverAssetId != null) {
      json[r'coverAssetId'] = this.coverAssetId;
    } else {
      json[r'coverAssetId'] = null;
    }
    json[r'order'] = this.order;
    json[r'isSmart'] = this.isSmart;
    if (this.rules != null) {
      json[r'rules'] = this.rules;
    } else {
      json[r'rules'] = null;
    }
    json[r'members'] = this.members;
    json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    json[r'updatedAt'] = this.updatedAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [Album] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Album? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Album[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Album[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Album(
        id: mapValueOfType<String>(json, r'id')!,
        title: mapValueOfType<String>(json, r'title')!,
        description: mapValueOfType<String>(json, r'description')!,
        role: AlbumRoleEnum.fromJson(json[r'role'])!,
        ownerId: mapValueOfType<String>(json, r'ownerId')!,
        ownerName: mapValueOfType<String>(json, r'ownerName')!,
        assetCount: mapValueOfType<int>(json, r'assetCount')!,
        coverAssetId: mapValueOfType<String>(json, r'coverAssetId'),
        order: AlbumOrderEnum.fromJson(json[r'order'])!,
        isSmart: mapValueOfType<bool>(json, r'isSmart')!,
        rules: AlbumRules.fromJson(json[r'rules']),
        members: AlbumMember.listFromJson(json[r'members']),
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        updatedAt: mapDateTime(json, r'updatedAt', r'')!,
      );
    }
    return null;
  }

  static List<Album> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Album>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Album.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Album> mapFromJson(dynamic json) {
    final map = <String, Album>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Album.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Album-objects as value to a dart map
  static Map<String, List<Album>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Album>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Album.listFromJson(
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
    'title',
    'description',
    'role',
    'ownerId',
    'ownerName',
    'assetCount',
    'order',
    'isSmart',
    'createdAt',
    'updatedAt',
  };
}

class AlbumRoleEnum {
  /// Instantiate a new enum with the provided [value].
  const AlbumRoleEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const owner = AlbumRoleEnum._(r'owner');
  static const editor = AlbumRoleEnum._(r'editor');
  static const contributor = AlbumRoleEnum._(r'contributor');
  static const viewer = AlbumRoleEnum._(r'viewer');

  /// List of all possible values in this [enum][AlbumRoleEnum].
  static const values = <AlbumRoleEnum>[
    owner,
    editor,
    contributor,
    viewer,
  ];

  static AlbumRoleEnum? fromJson(dynamic value) =>
      AlbumRoleEnumTypeTransformer().decode(value);

  static List<AlbumRoleEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AlbumRoleEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AlbumRoleEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AlbumRoleEnum] to String,
/// and [decode] dynamic data back to [AlbumRoleEnum].
class AlbumRoleEnumTypeTransformer {
  factory AlbumRoleEnumTypeTransformer() =>
      _instance ??= const AlbumRoleEnumTypeTransformer._();

  const AlbumRoleEnumTypeTransformer._();

  String encode(AlbumRoleEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a AlbumRoleEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AlbumRoleEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'owner':
          return AlbumRoleEnum.owner;
        case r'editor':
          return AlbumRoleEnum.editor;
        case r'contributor':
          return AlbumRoleEnum.contributor;
        case r'viewer':
          return AlbumRoleEnum.viewer;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [AlbumRoleEnumTypeTransformer] instance.
  static AlbumRoleEnumTypeTransformer? _instance;
}

class AlbumOrderEnum {
  /// Instantiate a new enum with the provided [value].
  const AlbumOrderEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const newest = AlbumOrderEnum._(r'newest');
  static const oldest = AlbumOrderEnum._(r'oldest');

  /// List of all possible values in this [enum][AlbumOrderEnum].
  static const values = <AlbumOrderEnum>[
    newest,
    oldest,
  ];

  static AlbumOrderEnum? fromJson(dynamic value) =>
      AlbumOrderEnumTypeTransformer().decode(value);

  static List<AlbumOrderEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AlbumOrderEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AlbumOrderEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AlbumOrderEnum] to String,
/// and [decode] dynamic data back to [AlbumOrderEnum].
class AlbumOrderEnumTypeTransformer {
  factory AlbumOrderEnumTypeTransformer() =>
      _instance ??= const AlbumOrderEnumTypeTransformer._();

  const AlbumOrderEnumTypeTransformer._();

  String encode(AlbumOrderEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a AlbumOrderEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AlbumOrderEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'newest':
          return AlbumOrderEnum.newest;
        case r'oldest':
          return AlbumOrderEnum.oldest;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [AlbumOrderEnumTypeTransformer] instance.
  static AlbumOrderEnumTypeTransformer? _instance;
}

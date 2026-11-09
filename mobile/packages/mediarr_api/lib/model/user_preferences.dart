//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UserPreferences {
  /// Returns a new [UserPreferences] instance.
  UserPreferences({
    required this.videoAutoplay,
    required this.videoLoop,
    required this.videoOriginal,
    required this.photoFull,
    required this.confirmDelete,
    required this.memorySeconds,
    required this.minFaces,
    required this.albumOrder,
    this.hiddenSections = const [],
    this.memoryKindsOff = const [],
  });

  bool videoAutoplay;

  bool videoLoop;

  bool videoOriginal;

  bool photoFull;

  bool confirmDelete;

  /// Minimum value: 1
  /// Maximum value: 60
  int memorySeconds;

  /// Minimum value: 1
  /// Maximum value: 100
  int minFaces;

  UserPreferencesAlbumOrderEnum albumOrder;

  List<String> hiddenSections;

  List<UserPreferencesMemoryKindsOffEnum> memoryKindsOff;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferences &&
          other.videoAutoplay == videoAutoplay &&
          other.videoLoop == videoLoop &&
          other.videoOriginal == videoOriginal &&
          other.photoFull == photoFull &&
          other.confirmDelete == confirmDelete &&
          other.memorySeconds == memorySeconds &&
          other.minFaces == minFaces &&
          other.albumOrder == albumOrder &&
          _deepEquality.equals(other.hiddenSections, hiddenSections) &&
          _deepEquality.equals(other.memoryKindsOff, memoryKindsOff);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (videoAutoplay.hashCode) +
      (videoLoop.hashCode) +
      (videoOriginal.hashCode) +
      (photoFull.hashCode) +
      (confirmDelete.hashCode) +
      (memorySeconds.hashCode) +
      (minFaces.hashCode) +
      (albumOrder.hashCode) +
      (hiddenSections.hashCode) +
      (memoryKindsOff.hashCode);

  @override
  String toString() =>
      'UserPreferences[videoAutoplay=$videoAutoplay, videoLoop=$videoLoop, videoOriginal=$videoOriginal, photoFull=$photoFull, confirmDelete=$confirmDelete, memorySeconds=$memorySeconds, minFaces=$minFaces, albumOrder=$albumOrder, hiddenSections=$hiddenSections, memoryKindsOff=$memoryKindsOff]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'videoAutoplay'] = this.videoAutoplay;
    json[r'videoLoop'] = this.videoLoop;
    json[r'videoOriginal'] = this.videoOriginal;
    json[r'photoFull'] = this.photoFull;
    json[r'confirmDelete'] = this.confirmDelete;
    json[r'memorySeconds'] = this.memorySeconds;
    json[r'minFaces'] = this.minFaces;
    json[r'albumOrder'] = this.albumOrder;
    json[r'hiddenSections'] = this.hiddenSections;
    json[r'memoryKindsOff'] = this.memoryKindsOff;
    return json;
  }

  /// Returns a new [UserPreferences] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UserPreferences? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "UserPreferences[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "UserPreferences[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return UserPreferences(
        videoAutoplay: mapValueOfType<bool>(json, r'videoAutoplay')!,
        videoLoop: mapValueOfType<bool>(json, r'videoLoop')!,
        videoOriginal: mapValueOfType<bool>(json, r'videoOriginal')!,
        photoFull: mapValueOfType<bool>(json, r'photoFull')!,
        confirmDelete: mapValueOfType<bool>(json, r'confirmDelete')!,
        memorySeconds: mapValueOfType<int>(json, r'memorySeconds')!,
        minFaces: mapValueOfType<int>(json, r'minFaces')!,
        albumOrder:
            UserPreferencesAlbumOrderEnum.fromJson(json[r'albumOrder'])!,
        hiddenSections: json[r'hiddenSections'] is Iterable
            ? (json[r'hiddenSections'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        memoryKindsOff: UserPreferencesMemoryKindsOffEnum.listFromJson(
            json[r'memoryKindsOff']),
      );
    }
    return null;
  }

  static List<UserPreferences> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UserPreferences>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UserPreferences.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UserPreferences> mapFromJson(dynamic json) {
    final map = <String, UserPreferences>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UserPreferences.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UserPreferences-objects as value to a dart map
  static Map<String, List<UserPreferences>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<UserPreferences>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UserPreferences.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'videoAutoplay',
    'videoLoop',
    'videoOriginal',
    'photoFull',
    'confirmDelete',
    'memorySeconds',
    'minFaces',
    'albumOrder',
    'hiddenSections',
  };
}

class UserPreferencesAlbumOrderEnum {
  /// Instantiate a new enum with the provided [value].
  const UserPreferencesAlbumOrderEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const newest = UserPreferencesAlbumOrderEnum._(r'newest');
  static const oldest = UserPreferencesAlbumOrderEnum._(r'oldest');

  /// List of all possible values in this [enum][UserPreferencesAlbumOrderEnum].
  static const values = <UserPreferencesAlbumOrderEnum>[
    newest,
    oldest,
  ];

  static UserPreferencesAlbumOrderEnum? fromJson(dynamic value) =>
      UserPreferencesAlbumOrderEnumTypeTransformer().decode(value);

  static List<UserPreferencesAlbumOrderEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UserPreferencesAlbumOrderEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UserPreferencesAlbumOrderEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [UserPreferencesAlbumOrderEnum] to String,
/// and [decode] dynamic data back to [UserPreferencesAlbumOrderEnum].
class UserPreferencesAlbumOrderEnumTypeTransformer {
  factory UserPreferencesAlbumOrderEnumTypeTransformer() =>
      _instance ??= const UserPreferencesAlbumOrderEnumTypeTransformer._();

  const UserPreferencesAlbumOrderEnumTypeTransformer._();

  String encode(UserPreferencesAlbumOrderEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a UserPreferencesAlbumOrderEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  UserPreferencesAlbumOrderEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'newest':
          return UserPreferencesAlbumOrderEnum.newest;
        case r'oldest':
          return UserPreferencesAlbumOrderEnum.oldest;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [UserPreferencesAlbumOrderEnumTypeTransformer] instance.
  static UserPreferencesAlbumOrderEnumTypeTransformer? _instance;
}

class UserPreferencesMemoryKindsOffEnum {
  /// Instantiate a new enum with the provided [value].
  const UserPreferencesMemoryKindsOffEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const onThisDay = UserPreferencesMemoryKindsOffEnum._(r'on_this_day');
  static const week = UserPreferencesMemoryKindsOffEnum._(r'week');
  static const trip = UserPreferencesMemoryKindsOffEnum._(r'trip');
  static const personYears =
      UserPreferencesMemoryKindsOffEnum._(r'person_years');
  static const birthday = UserPreferencesMemoryKindsOffEnum._(r'birthday');
  static const yearReview = UserPreferencesMemoryKindsOffEnum._(r'year_review');
  static const monthAgo = UserPreferencesMemoryKindsOffEnum._(r'month_ago');

  /// List of all possible values in this [enum][UserPreferencesMemoryKindsOffEnum].
  static const values = <UserPreferencesMemoryKindsOffEnum>[
    onThisDay,
    week,
    trip,
    personYears,
    birthday,
    yearReview,
    monthAgo,
  ];

  static UserPreferencesMemoryKindsOffEnum? fromJson(dynamic value) =>
      UserPreferencesMemoryKindsOffEnumTypeTransformer().decode(value);

  static List<UserPreferencesMemoryKindsOffEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <UserPreferencesMemoryKindsOffEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UserPreferencesMemoryKindsOffEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [UserPreferencesMemoryKindsOffEnum] to String,
/// and [decode] dynamic data back to [UserPreferencesMemoryKindsOffEnum].
class UserPreferencesMemoryKindsOffEnumTypeTransformer {
  factory UserPreferencesMemoryKindsOffEnumTypeTransformer() =>
      _instance ??= const UserPreferencesMemoryKindsOffEnumTypeTransformer._();

  const UserPreferencesMemoryKindsOffEnumTypeTransformer._();

  String encode(UserPreferencesMemoryKindsOffEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a UserPreferencesMemoryKindsOffEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  UserPreferencesMemoryKindsOffEnum? decode(dynamic data,
      {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'on_this_day':
          return UserPreferencesMemoryKindsOffEnum.onThisDay;
        case r'week':
          return UserPreferencesMemoryKindsOffEnum.week;
        case r'trip':
          return UserPreferencesMemoryKindsOffEnum.trip;
        case r'person_years':
          return UserPreferencesMemoryKindsOffEnum.personYears;
        case r'birthday':
          return UserPreferencesMemoryKindsOffEnum.birthday;
        case r'year_review':
          return UserPreferencesMemoryKindsOffEnum.yearReview;
        case r'month_ago':
          return UserPreferencesMemoryKindsOffEnum.monthAgo;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [UserPreferencesMemoryKindsOffEnumTypeTransformer] instance.
  static UserPreferencesMemoryKindsOffEnumTypeTransformer? _instance;
}

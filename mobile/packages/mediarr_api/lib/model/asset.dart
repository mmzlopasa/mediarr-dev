//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Asset {
  /// Returns a new [Asset] instance.
  Asset({
    required this.id,
    required this.originalName,
    required this.kind,
    required this.status,
    this.error,
    required this.sizeBytes,
    required this.checksum,
    this.width,
    this.height,
    this.blurhash,
    this.takenAt,
    required this.createdAt,
  });

  String id;

  String originalName;

  AssetKindEnum kind;

  AssetStatusEnum status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? error;

  int sizeBytes;

  /// Lowercase hex SHA-256
  String checksum;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? width;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? height;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? blurhash;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? takenAt;

  DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Asset &&
          other.id == id &&
          other.originalName == originalName &&
          other.kind == kind &&
          other.status == status &&
          other.error == error &&
          other.sizeBytes == sizeBytes &&
          other.checksum == checksum &&
          other.width == width &&
          other.height == height &&
          other.blurhash == blurhash &&
          other.takenAt == takenAt &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (originalName.hashCode) +
      (kind.hashCode) +
      (status.hashCode) +
      (error == null ? 0 : error!.hashCode) +
      (sizeBytes.hashCode) +
      (checksum.hashCode) +
      (width == null ? 0 : width!.hashCode) +
      (height == null ? 0 : height!.hashCode) +
      (blurhash == null ? 0 : blurhash!.hashCode) +
      (takenAt == null ? 0 : takenAt!.hashCode) +
      (createdAt.hashCode);

  @override
  String toString() =>
      'Asset[id=$id, originalName=$originalName, kind=$kind, status=$status, error=$error, sizeBytes=$sizeBytes, checksum=$checksum, width=$width, height=$height, blurhash=$blurhash, takenAt=$takenAt, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'originalName'] = this.originalName;
    json[r'kind'] = this.kind;
    json[r'status'] = this.status;
    if (this.error != null) {
      json[r'error'] = this.error;
    } else {
      json[r'error'] = null;
    }
    json[r'sizeBytes'] = this.sizeBytes;
    json[r'checksum'] = this.checksum;
    if (this.width != null) {
      json[r'width'] = this.width;
    } else {
      json[r'width'] = null;
    }
    if (this.height != null) {
      json[r'height'] = this.height;
    } else {
      json[r'height'] = null;
    }
    if (this.blurhash != null) {
      json[r'blurhash'] = this.blurhash;
    } else {
      json[r'blurhash'] = null;
    }
    if (this.takenAt != null) {
      json[r'takenAt'] = this.takenAt!.toUtc().toIso8601String();
    } else {
      json[r'takenAt'] = null;
    }
    json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [Asset] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Asset? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Asset[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Asset[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Asset(
        id: mapValueOfType<String>(json, r'id')!,
        originalName: mapValueOfType<String>(json, r'originalName')!,
        kind: AssetKindEnum.fromJson(json[r'kind'])!,
        status: AssetStatusEnum.fromJson(json[r'status'])!,
        error: mapValueOfType<String>(json, r'error'),
        sizeBytes: mapValueOfType<int>(json, r'sizeBytes')!,
        checksum: mapValueOfType<String>(json, r'checksum')!,
        width: mapValueOfType<int>(json, r'width'),
        height: mapValueOfType<int>(json, r'height'),
        blurhash: mapValueOfType<String>(json, r'blurhash'),
        takenAt: mapDateTime(json, r'takenAt', r''),
        createdAt: mapDateTime(json, r'createdAt', r'')!,
      );
    }
    return null;
  }

  static List<Asset> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Asset>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Asset.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Asset> mapFromJson(dynamic json) {
    final map = <String, Asset>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Asset.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Asset-objects as value to a dart map
  static Map<String, List<Asset>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Asset>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Asset.listFromJson(
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
    'originalName',
    'kind',
    'status',
    'sizeBytes',
    'checksum',
    'createdAt',
  };
}

class AssetKindEnum {
  /// Instantiate a new enum with the provided [value].
  const AssetKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const unknown = AssetKindEnum._(r'unknown');
  static const photo = AssetKindEnum._(r'photo');
  static const video = AssetKindEnum._(r'video');

  /// List of all possible values in this [enum][AssetKindEnum].
  static const values = <AssetKindEnum>[
    unknown,
    photo,
    video,
  ];

  static AssetKindEnum? fromJson(dynamic value) =>
      AssetKindEnumTypeTransformer().decode(value);

  static List<AssetKindEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AssetKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AssetKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AssetKindEnum] to String,
/// and [decode] dynamic data back to [AssetKindEnum].
class AssetKindEnumTypeTransformer {
  factory AssetKindEnumTypeTransformer() =>
      _instance ??= const AssetKindEnumTypeTransformer._();

  const AssetKindEnumTypeTransformer._();

  String encode(AssetKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a AssetKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AssetKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'unknown':
          return AssetKindEnum.unknown;
        case r'photo':
          return AssetKindEnum.photo;
        case r'video':
          return AssetKindEnum.video;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [AssetKindEnumTypeTransformer] instance.
  static AssetKindEnumTypeTransformer? _instance;
}

class AssetStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const AssetStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const processing = AssetStatusEnum._(r'processing');
  static const ready = AssetStatusEnum._(r'ready');
  static const failed = AssetStatusEnum._(r'failed');

  /// List of all possible values in this [enum][AssetStatusEnum].
  static const values = <AssetStatusEnum>[
    processing,
    ready,
    failed,
  ];

  static AssetStatusEnum? fromJson(dynamic value) =>
      AssetStatusEnumTypeTransformer().decode(value);

  static List<AssetStatusEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AssetStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AssetStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AssetStatusEnum] to String,
/// and [decode] dynamic data back to [AssetStatusEnum].
class AssetStatusEnumTypeTransformer {
  factory AssetStatusEnumTypeTransformer() =>
      _instance ??= const AssetStatusEnumTypeTransformer._();

  const AssetStatusEnumTypeTransformer._();

  String encode(AssetStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a AssetStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AssetStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'processing':
          return AssetStatusEnum.processing;
        case r'ready':
          return AssetStatusEnum.ready;
        case r'failed':
          return AssetStatusEnum.failed;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [AssetStatusEnumTypeTransformer] instance.
  static AssetStatusEnumTypeTransformer? _instance;
}

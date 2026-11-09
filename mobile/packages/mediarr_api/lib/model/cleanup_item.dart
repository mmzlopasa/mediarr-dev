//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CleanupItem {
  /// Returns a new [CleanupItem] instance.
  CleanupItem({
    required this.id,
    required this.originalName,
    required this.sizeBytes,
    required this.kind,
    this.width,
    this.height,
    required this.ratio,
    required this.localAt,
    required this.favorite,
    required this.inAlbum,
    this.durationMs,
  });

  String id;

  String originalName;

  int sizeBytes;

  CleanupItemKindEnum kind;

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

  double ratio;

  String localAt;

  bool favorite;

  bool inAlbum;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? durationMs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CleanupItem &&
          other.id == id &&
          other.originalName == originalName &&
          other.sizeBytes == sizeBytes &&
          other.kind == kind &&
          other.width == width &&
          other.height == height &&
          other.ratio == ratio &&
          other.localAt == localAt &&
          other.favorite == favorite &&
          other.inAlbum == inAlbum &&
          other.durationMs == durationMs;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (originalName.hashCode) +
      (sizeBytes.hashCode) +
      (kind.hashCode) +
      (width == null ? 0 : width!.hashCode) +
      (height == null ? 0 : height!.hashCode) +
      (ratio.hashCode) +
      (localAt.hashCode) +
      (favorite.hashCode) +
      (inAlbum.hashCode) +
      (durationMs == null ? 0 : durationMs!.hashCode);

  @override
  String toString() =>
      'CleanupItem[id=$id, originalName=$originalName, sizeBytes=$sizeBytes, kind=$kind, width=$width, height=$height, ratio=$ratio, localAt=$localAt, favorite=$favorite, inAlbum=$inAlbum, durationMs=$durationMs]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'originalName'] = this.originalName;
    json[r'sizeBytes'] = this.sizeBytes;
    json[r'kind'] = this.kind;
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
    json[r'ratio'] = this.ratio;
    json[r'localAt'] = this.localAt;
    json[r'favorite'] = this.favorite;
    json[r'inAlbum'] = this.inAlbum;
    if (this.durationMs != null) {
      json[r'durationMs'] = this.durationMs;
    } else {
      json[r'durationMs'] = null;
    }
    return json;
  }

  /// Returns a new [CleanupItem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CleanupItem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "CleanupItem[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "CleanupItem[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CleanupItem(
        id: mapValueOfType<String>(json, r'id')!,
        originalName: mapValueOfType<String>(json, r'originalName')!,
        sizeBytes: mapValueOfType<int>(json, r'sizeBytes')!,
        kind: CleanupItemKindEnum.fromJson(json[r'kind'])!,
        width: mapValueOfType<int>(json, r'width'),
        height: mapValueOfType<int>(json, r'height'),
        ratio: mapValueOfType<double>(json, r'ratio')!,
        localAt: mapValueOfType<String>(json, r'localAt')!,
        favorite: mapValueOfType<bool>(json, r'favorite')!,
        inAlbum: mapValueOfType<bool>(json, r'inAlbum')!,
        durationMs: mapValueOfType<int>(json, r'durationMs'),
      );
    }
    return null;
  }

  static List<CleanupItem> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CleanupItem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CleanupItem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CleanupItem> mapFromJson(dynamic json) {
    final map = <String, CleanupItem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CleanupItem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CleanupItem-objects as value to a dart map
  static Map<String, List<CleanupItem>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CleanupItem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CleanupItem.listFromJson(
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
    'sizeBytes',
    'kind',
    'ratio',
    'localAt',
    'favorite',
    'inAlbum',
  };
}

class CleanupItemKindEnum {
  /// Instantiate a new enum with the provided [value].
  const CleanupItemKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const photo = CleanupItemKindEnum._(r'photo');
  static const video = CleanupItemKindEnum._(r'video');

  /// List of all possible values in this [enum][CleanupItemKindEnum].
  static const values = <CleanupItemKindEnum>[
    photo,
    video,
  ];

  static CleanupItemKindEnum? fromJson(dynamic value) =>
      CleanupItemKindEnumTypeTransformer().decode(value);

  static List<CleanupItemKindEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CleanupItemKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CleanupItemKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [CleanupItemKindEnum] to String,
/// and [decode] dynamic data back to [CleanupItemKindEnum].
class CleanupItemKindEnumTypeTransformer {
  factory CleanupItemKindEnumTypeTransformer() =>
      _instance ??= const CleanupItemKindEnumTypeTransformer._();

  const CleanupItemKindEnumTypeTransformer._();

  String encode(CleanupItemKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a CleanupItemKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  CleanupItemKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'photo':
          return CleanupItemKindEnum.photo;
        case r'video':
          return CleanupItemKindEnum.video;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [CleanupItemKindEnumTypeTransformer] instance.
  static CleanupItemKindEnumTypeTransformer? _instance;
}

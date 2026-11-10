//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CastMedia {
  /// Returns a new [CastMedia] instance.
  CastMedia({
    required this.id,
    required this.kind,
    required this.image,
    this.hls,
    this.file,
    this.mimeType,
    this.durationMs,
  });

  String id;

  CastMediaKindEnum kind;

  /// A JPEG: the photo, or the still of a video
  String image;

  /// A video's HLS playlist, once the server has converted it
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? hls;

  /// A video's original file, without its location
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? file;

  /// Of file
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? mimeType;

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
      other is CastMedia &&
          other.id == id &&
          other.kind == kind &&
          other.image == image &&
          other.hls == hls &&
          other.file == file &&
          other.mimeType == mimeType &&
          other.durationMs == durationMs;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (kind.hashCode) +
      (image.hashCode) +
      (hls == null ? 0 : hls!.hashCode) +
      (file == null ? 0 : file!.hashCode) +
      (mimeType == null ? 0 : mimeType!.hashCode) +
      (durationMs == null ? 0 : durationMs!.hashCode);

  @override
  String toString() =>
      'CastMedia[id=$id, kind=$kind, image=$image, hls=$hls, file=$file, mimeType=$mimeType, durationMs=$durationMs]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'kind'] = this.kind;
    json[r'image'] = this.image;
    if (this.hls != null) {
      json[r'hls'] = this.hls;
    } else {
      json[r'hls'] = null;
    }
    if (this.file != null) {
      json[r'file'] = this.file;
    } else {
      json[r'file'] = null;
    }
    if (this.mimeType != null) {
      json[r'mimeType'] = this.mimeType;
    } else {
      json[r'mimeType'] = null;
    }
    if (this.durationMs != null) {
      json[r'durationMs'] = this.durationMs;
    } else {
      json[r'durationMs'] = null;
    }
    return json;
  }

  /// Returns a new [CastMedia] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CastMedia? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "CastMedia[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "CastMedia[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CastMedia(
        id: mapValueOfType<String>(json, r'id')!,
        kind: CastMediaKindEnum.fromJson(json[r'kind'])!,
        image: mapValueOfType<String>(json, r'image')!,
        hls: mapValueOfType<String>(json, r'hls'),
        file: mapValueOfType<String>(json, r'file'),
        mimeType: mapValueOfType<String>(json, r'mimeType'),
        durationMs: mapValueOfType<int>(json, r'durationMs'),
      );
    }
    return null;
  }

  static List<CastMedia> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CastMedia>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CastMedia.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CastMedia> mapFromJson(dynamic json) {
    final map = <String, CastMedia>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CastMedia.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CastMedia-objects as value to a dart map
  static Map<String, List<CastMedia>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CastMedia>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CastMedia.listFromJson(
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
    'image',
  };
}

class CastMediaKindEnum {
  /// Instantiate a new enum with the provided [value].
  const CastMediaKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const photo = CastMediaKindEnum._(r'photo');
  static const video = CastMediaKindEnum._(r'video');

  /// List of all possible values in this [enum][CastMediaKindEnum].
  static const values = <CastMediaKindEnum>[
    photo,
    video,
  ];

  static CastMediaKindEnum? fromJson(dynamic value) =>
      CastMediaKindEnumTypeTransformer().decode(value);

  static List<CastMediaKindEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CastMediaKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CastMediaKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [CastMediaKindEnum] to String,
/// and [decode] dynamic data back to [CastMediaKindEnum].
class CastMediaKindEnumTypeTransformer {
  factory CastMediaKindEnumTypeTransformer() =>
      _instance ??= const CastMediaKindEnumTypeTransformer._();

  const CastMediaKindEnumTypeTransformer._();

  String encode(CastMediaKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a CastMediaKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  CastMediaKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'photo':
          return CastMediaKindEnum.photo;
        case r'video':
          return CastMediaKindEnum.video;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [CastMediaKindEnumTypeTransformer] instance.
  static CastMediaKindEnumTypeTransformer? _instance;
}

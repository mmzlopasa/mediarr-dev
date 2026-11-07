//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TimelineItem {
  /// Returns a new [TimelineItem] instance.
  TimelineItem({
    required this.id,
    required this.kind,
    required this.ratio,
    this.blurhash,
    required this.isFavorite,
    this.isLive,
    this.isPanorama,
    this.stackSize,
    this.isShared,
    this.durationMs,
    required this.localAt,
  });

  String id;

  TimelineItemKindEnum kind;

  /// Width divided by height, as displayed
  double ratio;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? blurhash;

  bool isFavorite;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? isLive;

  /// A 360° panorama
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? isPanorama;

  /// Shots in this stack, when it is one. Only the main shot shows on the timeline
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? stackSize;

  /// Belongs to someone else, shared with this user
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? isShared;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? durationMs;

  /// Local capture time without a zone: 2006-01-02T15:04:05
  String localAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineItem &&
          other.id == id &&
          other.kind == kind &&
          other.ratio == ratio &&
          other.blurhash == blurhash &&
          other.isFavorite == isFavorite &&
          other.isLive == isLive &&
          other.isPanorama == isPanorama &&
          other.stackSize == stackSize &&
          other.isShared == isShared &&
          other.durationMs == durationMs &&
          other.localAt == localAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (kind.hashCode) +
      (ratio.hashCode) +
      (blurhash == null ? 0 : blurhash!.hashCode) +
      (isFavorite.hashCode) +
      (isLive == null ? 0 : isLive!.hashCode) +
      (isPanorama == null ? 0 : isPanorama!.hashCode) +
      (stackSize == null ? 0 : stackSize!.hashCode) +
      (isShared == null ? 0 : isShared!.hashCode) +
      (durationMs == null ? 0 : durationMs!.hashCode) +
      (localAt.hashCode);

  @override
  String toString() =>
      'TimelineItem[id=$id, kind=$kind, ratio=$ratio, blurhash=$blurhash, isFavorite=$isFavorite, isLive=$isLive, isPanorama=$isPanorama, stackSize=$stackSize, isShared=$isShared, durationMs=$durationMs, localAt=$localAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'kind'] = this.kind;
    json[r'ratio'] = this.ratio;
    if (this.blurhash != null) {
      json[r'blurhash'] = this.blurhash;
    } else {
      json[r'blurhash'] = null;
    }
    json[r'isFavorite'] = this.isFavorite;
    if (this.isLive != null) {
      json[r'isLive'] = this.isLive;
    } else {
      json[r'isLive'] = null;
    }
    if (this.isPanorama != null) {
      json[r'isPanorama'] = this.isPanorama;
    } else {
      json[r'isPanorama'] = null;
    }
    if (this.stackSize != null) {
      json[r'stackSize'] = this.stackSize;
    } else {
      json[r'stackSize'] = null;
    }
    if (this.isShared != null) {
      json[r'isShared'] = this.isShared;
    } else {
      json[r'isShared'] = null;
    }
    if (this.durationMs != null) {
      json[r'durationMs'] = this.durationMs;
    } else {
      json[r'durationMs'] = null;
    }
    json[r'localAt'] = this.localAt;
    return json;
  }

  /// Returns a new [TimelineItem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TimelineItem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "TimelineItem[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "TimelineItem[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return TimelineItem(
        id: mapValueOfType<String>(json, r'id')!,
        kind: TimelineItemKindEnum.fromJson(json[r'kind'])!,
        ratio: mapValueOfType<double>(json, r'ratio')!,
        blurhash: mapValueOfType<String>(json, r'blurhash'),
        isFavorite: mapValueOfType<bool>(json, r'isFavorite')!,
        isLive: mapValueOfType<bool>(json, r'isLive'),
        isPanorama: mapValueOfType<bool>(json, r'isPanorama'),
        stackSize: mapValueOfType<int>(json, r'stackSize'),
        isShared: mapValueOfType<bool>(json, r'isShared'),
        durationMs: mapValueOfType<int>(json, r'durationMs'),
        localAt: mapValueOfType<String>(json, r'localAt')!,
      );
    }
    return null;
  }

  static List<TimelineItem> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <TimelineItem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TimelineItem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TimelineItem> mapFromJson(dynamic json) {
    final map = <String, TimelineItem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TimelineItem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TimelineItem-objects as value to a dart map
  static Map<String, List<TimelineItem>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<TimelineItem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TimelineItem.listFromJson(
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
    'ratio',
    'isFavorite',
    'localAt',
  };
}

class TimelineItemKindEnum {
  /// Instantiate a new enum with the provided [value].
  const TimelineItemKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const unknown = TimelineItemKindEnum._(r'unknown');
  static const photo = TimelineItemKindEnum._(r'photo');
  static const video = TimelineItemKindEnum._(r'video');

  /// List of all possible values in this [enum][TimelineItemKindEnum].
  static const values = <TimelineItemKindEnum>[
    unknown,
    photo,
    video,
  ];

  static TimelineItemKindEnum? fromJson(dynamic value) =>
      TimelineItemKindEnumTypeTransformer().decode(value);

  static List<TimelineItemKindEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <TimelineItemKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TimelineItemKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [TimelineItemKindEnum] to String,
/// and [decode] dynamic data back to [TimelineItemKindEnum].
class TimelineItemKindEnumTypeTransformer {
  factory TimelineItemKindEnumTypeTransformer() =>
      _instance ??= const TimelineItemKindEnumTypeTransformer._();

  const TimelineItemKindEnumTypeTransformer._();

  String encode(TimelineItemKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a TimelineItemKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  TimelineItemKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'unknown':
          return TimelineItemKindEnum.unknown;
        case r'photo':
          return TimelineItemKindEnum.photo;
        case r'video':
          return TimelineItemKindEnum.video;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [TimelineItemKindEnumTypeTransformer] instance.
  static TimelineItemKindEnumTypeTransformer? _instance;
}

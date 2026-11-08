//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DateFix {
  /// Returns a new [DateFix] instance.
  DateFix({
    this.ids = const [],
    required this.action,
    this.minutes,
    this.takenAt,
    this.cameraZone,
    this.placeZone,
    this.dryRun,
  });

  List<String> ids;

  DateFixActionEnum action;

  /// shift: how far, forward or back
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? minutes;

  /// set: RFC 3339 with the offset of where they were taken
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? takenAt;

  /// travel: the zone the camera's clock was on, such as Europe/Zagreb
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? cameraZone;

  /// travel: the zone where they were taken, such as Asia/Tokyo
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? placeZone;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? dryRun;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateFix &&
          _deepEquality.equals(other.ids, ids) &&
          other.action == action &&
          other.minutes == minutes &&
          other.takenAt == takenAt &&
          other.cameraZone == cameraZone &&
          other.placeZone == placeZone &&
          other.dryRun == dryRun;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (ids.hashCode) +
      (action.hashCode) +
      (minutes == null ? 0 : minutes!.hashCode) +
      (takenAt == null ? 0 : takenAt!.hashCode) +
      (cameraZone == null ? 0 : cameraZone!.hashCode) +
      (placeZone == null ? 0 : placeZone!.hashCode) +
      (dryRun == null ? 0 : dryRun!.hashCode);

  @override
  String toString() =>
      'DateFix[ids=$ids, action=$action, minutes=$minutes, takenAt=$takenAt, cameraZone=$cameraZone, placeZone=$placeZone, dryRun=$dryRun]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'ids'] = this.ids;
    json[r'action'] = this.action;
    if (this.minutes != null) {
      json[r'minutes'] = this.minutes;
    } else {
      json[r'minutes'] = null;
    }
    if (this.takenAt != null) {
      json[r'takenAt'] = this.takenAt;
    } else {
      json[r'takenAt'] = null;
    }
    if (this.cameraZone != null) {
      json[r'cameraZone'] = this.cameraZone;
    } else {
      json[r'cameraZone'] = null;
    }
    if (this.placeZone != null) {
      json[r'placeZone'] = this.placeZone;
    } else {
      json[r'placeZone'] = null;
    }
    if (this.dryRun != null) {
      json[r'dryRun'] = this.dryRun;
    } else {
      json[r'dryRun'] = null;
    }
    return json;
  }

  /// Returns a new [DateFix] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DateFix? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "DateFix[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "DateFix[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return DateFix(
        ids: json[r'ids'] is Iterable
            ? (json[r'ids'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        action: DateFixActionEnum.fromJson(json[r'action'])!,
        minutes: mapValueOfType<int>(json, r'minutes'),
        takenAt: mapValueOfType<String>(json, r'takenAt'),
        cameraZone: mapValueOfType<String>(json, r'cameraZone'),
        placeZone: mapValueOfType<String>(json, r'placeZone'),
        dryRun: mapValueOfType<bool>(json, r'dryRun'),
      );
    }
    return null;
  }

  static List<DateFix> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <DateFix>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DateFix.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DateFix> mapFromJson(dynamic json) {
    final map = <String, DateFix>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DateFix.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DateFix-objects as value to a dart map
  static Map<String, List<DateFix>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<DateFix>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DateFix.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'ids',
    'action',
  };
}

class DateFixActionEnum {
  /// Instantiate a new enum with the provided [value].
  const DateFixActionEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const shift = DateFixActionEnum._(r'shift');
  static const set_ = DateFixActionEnum._(r'set');
  static const zoneFromPlace = DateFixActionEnum._(r'zoneFromPlace');
  static const travel = DateFixActionEnum._(r'travel');
  static const useFile = DateFixActionEnum._(r'useFile');

  /// List of all possible values in this [enum][DateFixActionEnum].
  static const values = <DateFixActionEnum>[
    shift,
    set_,
    zoneFromPlace,
    travel,
    useFile,
  ];

  static DateFixActionEnum? fromJson(dynamic value) =>
      DateFixActionEnumTypeTransformer().decode(value);

  static List<DateFixActionEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <DateFixActionEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DateFixActionEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DateFixActionEnum] to String,
/// and [decode] dynamic data back to [DateFixActionEnum].
class DateFixActionEnumTypeTransformer {
  factory DateFixActionEnumTypeTransformer() =>
      _instance ??= const DateFixActionEnumTypeTransformer._();

  const DateFixActionEnumTypeTransformer._();

  String encode(DateFixActionEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a DateFixActionEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DateFixActionEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'shift':
          return DateFixActionEnum.shift;
        case r'set':
          return DateFixActionEnum.set_;
        case r'zoneFromPlace':
          return DateFixActionEnum.zoneFromPlace;
        case r'travel':
          return DateFixActionEnum.travel;
        case r'useFile':
          return DateFixActionEnum.useFile;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [DateFixActionEnumTypeTransformer] instance.
  static DateFixActionEnumTypeTransformer? _instance;
}

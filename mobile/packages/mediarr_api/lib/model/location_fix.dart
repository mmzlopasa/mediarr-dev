//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LocationFix {
  /// Returns a new [LocationFix] instance.
  LocationFix({
    this.ids = const [],
    required this.action,
    this.latitude,
    this.longitude,
    this.minutes,
    this.track,
    this.dryRun,
  });

  List<String> ids;

  LocationFixActionEnum action;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? latitude;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? longitude;

  /// fromNeighbours: how far apart in time, 30 by default
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? minutes;

  /// fromTrack: a GPX file
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? track;

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
      other is LocationFix &&
          _deepEquality.equals(other.ids, ids) &&
          other.action == action &&
          other.latitude == latitude &&
          other.longitude == longitude &&
          other.minutes == minutes &&
          other.track == track &&
          other.dryRun == dryRun;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (ids.hashCode) +
      (action.hashCode) +
      (latitude == null ? 0 : latitude!.hashCode) +
      (longitude == null ? 0 : longitude!.hashCode) +
      (minutes == null ? 0 : minutes!.hashCode) +
      (track == null ? 0 : track!.hashCode) +
      (dryRun == null ? 0 : dryRun!.hashCode);

  @override
  String toString() =>
      'LocationFix[ids=$ids, action=$action, latitude=$latitude, longitude=$longitude, minutes=$minutes, track=$track, dryRun=$dryRun]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'ids'] = this.ids;
    json[r'action'] = this.action;
    if (this.latitude != null) {
      json[r'latitude'] = this.latitude;
    } else {
      json[r'latitude'] = null;
    }
    if (this.longitude != null) {
      json[r'longitude'] = this.longitude;
    } else {
      json[r'longitude'] = null;
    }
    if (this.minutes != null) {
      json[r'minutes'] = this.minutes;
    } else {
      json[r'minutes'] = null;
    }
    if (this.track != null) {
      json[r'track'] = this.track;
    } else {
      json[r'track'] = null;
    }
    if (this.dryRun != null) {
      json[r'dryRun'] = this.dryRun;
    } else {
      json[r'dryRun'] = null;
    }
    return json;
  }

  /// Returns a new [LocationFix] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LocationFix? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "LocationFix[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "LocationFix[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return LocationFix(
        ids: json[r'ids'] is Iterable
            ? (json[r'ids'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        action: LocationFixActionEnum.fromJson(json[r'action'])!,
        latitude: mapValueOfType<double>(json, r'latitude'),
        longitude: mapValueOfType<double>(json, r'longitude'),
        minutes: mapValueOfType<int>(json, r'minutes'),
        track: mapValueOfType<String>(json, r'track'),
        dryRun: mapValueOfType<bool>(json, r'dryRun'),
      );
    }
    return null;
  }

  static List<LocationFix> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <LocationFix>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LocationFix.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LocationFix> mapFromJson(dynamic json) {
    final map = <String, LocationFix>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LocationFix.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LocationFix-objects as value to a dart map
  static Map<String, List<LocationFix>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<LocationFix>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LocationFix.listFromJson(
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

class LocationFixActionEnum {
  /// Instantiate a new enum with the provided [value].
  const LocationFixActionEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const set_ = LocationFixActionEnum._(r'set');
  static const clear = LocationFixActionEnum._(r'clear');
  static const fromNeighbours = LocationFixActionEnum._(r'fromNeighbours');
  static const fromTrack = LocationFixActionEnum._(r'fromTrack');
  static const useFile = LocationFixActionEnum._(r'useFile');

  /// List of all possible values in this [enum][LocationFixActionEnum].
  static const values = <LocationFixActionEnum>[
    set_,
    clear,
    fromNeighbours,
    fromTrack,
    useFile,
  ];

  static LocationFixActionEnum? fromJson(dynamic value) =>
      LocationFixActionEnumTypeTransformer().decode(value);

  static List<LocationFixActionEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <LocationFixActionEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LocationFixActionEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [LocationFixActionEnum] to String,
/// and [decode] dynamic data back to [LocationFixActionEnum].
class LocationFixActionEnumTypeTransformer {
  factory LocationFixActionEnumTypeTransformer() =>
      _instance ??= const LocationFixActionEnumTypeTransformer._();

  const LocationFixActionEnumTypeTransformer._();

  String encode(LocationFixActionEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a LocationFixActionEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  LocationFixActionEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'set':
          return LocationFixActionEnum.set_;
        case r'clear':
          return LocationFixActionEnum.clear;
        case r'fromNeighbours':
          return LocationFixActionEnum.fromNeighbours;
        case r'fromTrack':
          return LocationFixActionEnum.fromTrack;
        case r'useFile':
          return LocationFixActionEnum.useFile;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [LocationFixActionEnumTypeTransformer] instance.
  static LocationFixActionEnumTypeTransformer? _instance;
}

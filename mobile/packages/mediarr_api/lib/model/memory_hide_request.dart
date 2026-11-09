//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MemoryHideRequest {
  /// Returns a new [MemoryHideRequest] instance.
  MemoryHideRequest({
    required this.kind,
    required this.key,
    required this.hidden,
  });

  MemoryHideRequestKindEnum kind;

  String key;

  bool hidden;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryHideRequest &&
          other.kind == kind &&
          other.key == key &&
          other.hidden == hidden;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (kind.hashCode) + (key.hashCode) + (hidden.hashCode);

  @override
  String toString() =>
      'MemoryHideRequest[kind=$kind, key=$key, hidden=$hidden]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'kind'] = this.kind;
    json[r'key'] = this.key;
    json[r'hidden'] = this.hidden;
    return json;
  }

  /// Returns a new [MemoryHideRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MemoryHideRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "MemoryHideRequest[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "MemoryHideRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return MemoryHideRequest(
        kind: MemoryHideRequestKindEnum.fromJson(json[r'kind'])!,
        key: mapValueOfType<String>(json, r'key')!,
        hidden: mapValueOfType<bool>(json, r'hidden')!,
      );
    }
    return null;
  }

  static List<MemoryHideRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <MemoryHideRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MemoryHideRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MemoryHideRequest> mapFromJson(dynamic json) {
    final map = <String, MemoryHideRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MemoryHideRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MemoryHideRequest-objects as value to a dart map
  static Map<String, List<MemoryHideRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<MemoryHideRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MemoryHideRequest.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'kind',
    'key',
    'hidden',
  };
}

class MemoryHideRequestKindEnum {
  /// Instantiate a new enum with the provided [value].
  const MemoryHideRequestKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const onThisDay = MemoryHideRequestKindEnum._(r'on_this_day');
  static const week = MemoryHideRequestKindEnum._(r'week');
  static const trip = MemoryHideRequestKindEnum._(r'trip');
  static const personYears = MemoryHideRequestKindEnum._(r'person_years');
  static const birthday = MemoryHideRequestKindEnum._(r'birthday');
  static const yearReview = MemoryHideRequestKindEnum._(r'year_review');
  static const monthAgo = MemoryHideRequestKindEnum._(r'month_ago');

  /// List of all possible values in this [enum][MemoryHideRequestKindEnum].
  static const values = <MemoryHideRequestKindEnum>[
    onThisDay,
    week,
    trip,
    personYears,
    birthday,
    yearReview,
    monthAgo,
  ];

  static MemoryHideRequestKindEnum? fromJson(dynamic value) =>
      MemoryHideRequestKindEnumTypeTransformer().decode(value);

  static List<MemoryHideRequestKindEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <MemoryHideRequestKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MemoryHideRequestKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [MemoryHideRequestKindEnum] to String,
/// and [decode] dynamic data back to [MemoryHideRequestKindEnum].
class MemoryHideRequestKindEnumTypeTransformer {
  factory MemoryHideRequestKindEnumTypeTransformer() =>
      _instance ??= const MemoryHideRequestKindEnumTypeTransformer._();

  const MemoryHideRequestKindEnumTypeTransformer._();

  String encode(MemoryHideRequestKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a MemoryHideRequestKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  MemoryHideRequestKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'on_this_day':
          return MemoryHideRequestKindEnum.onThisDay;
        case r'week':
          return MemoryHideRequestKindEnum.week;
        case r'trip':
          return MemoryHideRequestKindEnum.trip;
        case r'person_years':
          return MemoryHideRequestKindEnum.personYears;
        case r'birthday':
          return MemoryHideRequestKindEnum.birthday;
        case r'year_review':
          return MemoryHideRequestKindEnum.yearReview;
        case r'month_ago':
          return MemoryHideRequestKindEnum.monthAgo;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [MemoryHideRequestKindEnumTypeTransformer] instance.
  static MemoryHideRequestKindEnumTypeTransformer? _instance;
}

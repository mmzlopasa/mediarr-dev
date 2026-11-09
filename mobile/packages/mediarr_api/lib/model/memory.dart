//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Memory {
  /// Returns a new [Memory] instance.
  Memory({
    required this.kind,
    this.key,
    this.year,
    required this.title,
    this.titleParams,
    this.items = const [],
  });

  MemoryKindEnum kind;

  /// Together with kind, what identifies this memory when hiding it. Not sent by older servers.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? key;

  /// The year, for on_this_day
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? year;

  /// A date or date span. The client words the rest.
  String title;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  MemoryTitleParams? titleParams;

  List<TimelineItem> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Memory &&
          other.kind == kind &&
          other.key == key &&
          other.year == year &&
          other.title == title &&
          other.titleParams == titleParams &&
          _deepEquality.equals(other.items, items);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (kind.hashCode) +
      (key == null ? 0 : key!.hashCode) +
      (year == null ? 0 : year!.hashCode) +
      (title.hashCode) +
      (titleParams == null ? 0 : titleParams!.hashCode) +
      (items.hashCode);

  @override
  String toString() =>
      'Memory[kind=$kind, key=$key, year=$year, title=$title, titleParams=$titleParams, items=$items]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'kind'] = this.kind;
    if (this.key != null) {
      json[r'key'] = this.key;
    } else {
      json[r'key'] = null;
    }
    if (this.year != null) {
      json[r'year'] = this.year;
    } else {
      json[r'year'] = null;
    }
    json[r'title'] = this.title;
    if (this.titleParams != null) {
      json[r'titleParams'] = this.titleParams;
    } else {
      json[r'titleParams'] = null;
    }
    json[r'items'] = this.items;
    return json;
  }

  /// Returns a new [Memory] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Memory? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Memory[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Memory[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Memory(
        kind: MemoryKindEnum.fromJson(json[r'kind'])!,
        key: mapValueOfType<String>(json, r'key'),
        year: mapValueOfType<int>(json, r'year'),
        title: mapValueOfType<String>(json, r'title')!,
        titleParams: MemoryTitleParams.fromJson(json[r'titleParams']),
        items: TimelineItem.listFromJson(json[r'items']),
      );
    }
    return null;
  }

  static List<Memory> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Memory>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Memory.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Memory> mapFromJson(dynamic json) {
    final map = <String, Memory>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Memory.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Memory-objects as value to a dart map
  static Map<String, List<Memory>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Memory>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Memory.listFromJson(
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
    'title',
    'items',
  };
}

class MemoryKindEnum {
  /// Instantiate a new enum with the provided [value].
  const MemoryKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const onThisDay = MemoryKindEnum._(r'on_this_day');
  static const week = MemoryKindEnum._(r'week');
  static const trip = MemoryKindEnum._(r'trip');
  static const personYears = MemoryKindEnum._(r'person_years');
  static const birthday = MemoryKindEnum._(r'birthday');
  static const yearReview = MemoryKindEnum._(r'year_review');
  static const monthAgo = MemoryKindEnum._(r'month_ago');

  /// List of all possible values in this [enum][MemoryKindEnum].
  static const values = <MemoryKindEnum>[
    onThisDay,
    week,
    trip,
    personYears,
    birthday,
    yearReview,
    monthAgo,
  ];

  static MemoryKindEnum? fromJson(dynamic value) =>
      MemoryKindEnumTypeTransformer().decode(value);

  static List<MemoryKindEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <MemoryKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MemoryKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [MemoryKindEnum] to String,
/// and [decode] dynamic data back to [MemoryKindEnum].
class MemoryKindEnumTypeTransformer {
  factory MemoryKindEnumTypeTransformer() =>
      _instance ??= const MemoryKindEnumTypeTransformer._();

  const MemoryKindEnumTypeTransformer._();

  String encode(MemoryKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a MemoryKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  MemoryKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'on_this_day':
          return MemoryKindEnum.onThisDay;
        case r'week':
          return MemoryKindEnum.week;
        case r'trip':
          return MemoryKindEnum.trip;
        case r'person_years':
          return MemoryKindEnum.personYears;
        case r'birthday':
          return MemoryKindEnum.birthday;
        case r'year_review':
          return MemoryKindEnum.yearReview;
        case r'month_ago':
          return MemoryKindEnum.monthAgo;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [MemoryKindEnumTypeTransformer] instance.
  static MemoryKindEnumTypeTransformer? _instance;
}

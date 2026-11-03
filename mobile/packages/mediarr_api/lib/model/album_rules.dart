//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AlbumRules {
  /// Returns a new [AlbumRules] instance.
  AlbumRules({
    this.from,
    this.to,
    this.kind,
    this.camera,
    this.person,
    this.tag,
    this.place,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? from;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? to;

  AlbumRulesKindEnum? kind;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? camera;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? person;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? tag;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? place;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlbumRules &&
          other.from == from &&
          other.to == to &&
          other.kind == kind &&
          other.camera == camera &&
          other.person == person &&
          other.tag == tag &&
          other.place == place;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (from == null ? 0 : from!.hashCode) +
      (to == null ? 0 : to!.hashCode) +
      (kind == null ? 0 : kind!.hashCode) +
      (camera == null ? 0 : camera!.hashCode) +
      (person == null ? 0 : person!.hashCode) +
      (tag == null ? 0 : tag!.hashCode) +
      (place == null ? 0 : place!.hashCode);

  @override
  String toString() =>
      'AlbumRules[from=$from, to=$to, kind=$kind, camera=$camera, person=$person, tag=$tag, place=$place]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.from != null) {
      json[r'from'] = _dateFormatter.format(this.from!.toUtc());
    } else {
      json[r'from'] = null;
    }
    if (this.to != null) {
      json[r'to'] = _dateFormatter.format(this.to!.toUtc());
    } else {
      json[r'to'] = null;
    }
    if (this.kind != null) {
      json[r'kind'] = this.kind;
    } else {
      json[r'kind'] = null;
    }
    if (this.camera != null) {
      json[r'camera'] = this.camera;
    } else {
      json[r'camera'] = null;
    }
    if (this.person != null) {
      json[r'person'] = this.person;
    } else {
      json[r'person'] = null;
    }
    if (this.tag != null) {
      json[r'tag'] = this.tag;
    } else {
      json[r'tag'] = null;
    }
    if (this.place != null) {
      json[r'place'] = this.place;
    } else {
      json[r'place'] = null;
    }
    return json;
  }

  /// Returns a new [AlbumRules] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AlbumRules? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "AlbumRules[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "AlbumRules[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AlbumRules(
        from: mapDateTime(json, r'from', r''),
        to: mapDateTime(json, r'to', r''),
        kind: AlbumRulesKindEnum.fromJson(json[r'kind']),
        camera: mapValueOfType<String>(json, r'camera'),
        person: mapValueOfType<String>(json, r'person'),
        tag: mapValueOfType<String>(json, r'tag'),
        place: mapValueOfType<String>(json, r'place'),
      );
    }
    return null;
  }

  static List<AlbumRules> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AlbumRules>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AlbumRules.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AlbumRules> mapFromJson(dynamic json) {
    final map = <String, AlbumRules>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AlbumRules.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AlbumRules-objects as value to a dart map
  static Map<String, List<AlbumRules>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<AlbumRules>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AlbumRules.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{};
}

class AlbumRulesKindEnum {
  /// Instantiate a new enum with the provided [value].
  const AlbumRulesKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const photo = AlbumRulesKindEnum._(r'photo');
  static const video = AlbumRulesKindEnum._(r'video');
  static const live = AlbumRulesKindEnum._(r'live');

  /// List of all possible values in this [enum][AlbumRulesKindEnum].
  static const values = <AlbumRulesKindEnum>[
    photo,
    video,
    live,
  ];

  static AlbumRulesKindEnum? fromJson(dynamic value) =>
      AlbumRulesKindEnumTypeTransformer().decode(value);

  static List<AlbumRulesKindEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AlbumRulesKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AlbumRulesKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AlbumRulesKindEnum] to String,
/// and [decode] dynamic data back to [AlbumRulesKindEnum].
class AlbumRulesKindEnumTypeTransformer {
  factory AlbumRulesKindEnumTypeTransformer() =>
      _instance ??= const AlbumRulesKindEnumTypeTransformer._();

  const AlbumRulesKindEnumTypeTransformer._();

  String encode(AlbumRulesKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a AlbumRulesKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AlbumRulesKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'photo':
          return AlbumRulesKindEnum.photo;
        case r'video':
          return AlbumRulesKindEnum.video;
        case r'live':
          return AlbumRulesKindEnum.live;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [AlbumRulesKindEnumTypeTransformer] instance.
  static AlbumRulesKindEnumTypeTransformer? _instance;
}

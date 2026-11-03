//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AlbumUpdate {
  /// Returns a new [AlbumUpdate] instance.
  AlbumUpdate({
    this.title,
    this.description,
    this.coverAssetId,
    this.order,
    this.rules,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? title;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? description;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? coverAssetId;

  AlbumUpdateOrderEnum? order;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  AlbumRules? rules;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlbumUpdate &&
          other.title == title &&
          other.description == description &&
          other.coverAssetId == coverAssetId &&
          other.order == order &&
          other.rules == rules;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (title == null ? 0 : title!.hashCode) +
      (description == null ? 0 : description!.hashCode) +
      (coverAssetId == null ? 0 : coverAssetId!.hashCode) +
      (order == null ? 0 : order!.hashCode) +
      (rules == null ? 0 : rules!.hashCode);

  @override
  String toString() =>
      'AlbumUpdate[title=$title, description=$description, coverAssetId=$coverAssetId, order=$order, rules=$rules]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.title != null) {
      json[r'title'] = this.title;
    } else {
      json[r'title'] = null;
    }
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
    if (this.coverAssetId != null) {
      json[r'coverAssetId'] = this.coverAssetId;
    } else {
      json[r'coverAssetId'] = null;
    }
    if (this.order != null) {
      json[r'order'] = this.order;
    } else {
      json[r'order'] = null;
    }
    if (this.rules != null) {
      json[r'rules'] = this.rules;
    } else {
      json[r'rules'] = null;
    }
    return json;
  }

  /// Returns a new [AlbumUpdate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AlbumUpdate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "AlbumUpdate[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "AlbumUpdate[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AlbumUpdate(
        title: mapValueOfType<String>(json, r'title'),
        description: mapValueOfType<String>(json, r'description'),
        coverAssetId: mapValueOfType<String>(json, r'coverAssetId'),
        order: AlbumUpdateOrderEnum.fromJson(json[r'order']),
        rules: AlbumRules.fromJson(json[r'rules']),
      );
    }
    return null;
  }

  static List<AlbumUpdate> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AlbumUpdate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AlbumUpdate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AlbumUpdate> mapFromJson(dynamic json) {
    final map = <String, AlbumUpdate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AlbumUpdate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AlbumUpdate-objects as value to a dart map
  static Map<String, List<AlbumUpdate>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<AlbumUpdate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AlbumUpdate.listFromJson(
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

class AlbumUpdateOrderEnum {
  /// Instantiate a new enum with the provided [value].
  const AlbumUpdateOrderEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const newest = AlbumUpdateOrderEnum._(r'newest');
  static const oldest = AlbumUpdateOrderEnum._(r'oldest');

  /// List of all possible values in this [enum][AlbumUpdateOrderEnum].
  static const values = <AlbumUpdateOrderEnum>[
    newest,
    oldest,
  ];

  static AlbumUpdateOrderEnum? fromJson(dynamic value) =>
      AlbumUpdateOrderEnumTypeTransformer().decode(value);

  static List<AlbumUpdateOrderEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AlbumUpdateOrderEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AlbumUpdateOrderEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AlbumUpdateOrderEnum] to String,
/// and [decode] dynamic data back to [AlbumUpdateOrderEnum].
class AlbumUpdateOrderEnumTypeTransformer {
  factory AlbumUpdateOrderEnumTypeTransformer() =>
      _instance ??= const AlbumUpdateOrderEnumTypeTransformer._();

  const AlbumUpdateOrderEnumTypeTransformer._();

  String encode(AlbumUpdateOrderEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a AlbumUpdateOrderEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AlbumUpdateOrderEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'newest':
          return AlbumUpdateOrderEnum.newest;
        case r'oldest':
          return AlbumUpdateOrderEnum.oldest;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [AlbumUpdateOrderEnumTypeTransformer] instance.
  static AlbumUpdateOrderEnumTypeTransformer? _instance;
}

//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class BulkRequest {
  /// Returns a new [BulkRequest] instance.
  BulkRequest({
    this.ids = const [],
    required this.action,
  });

  List<String> ids;

  BulkRequestActionEnum action;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BulkRequest &&
          _deepEquality.equals(other.ids, ids) &&
          other.action == action;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (ids.hashCode) + (action.hashCode);

  @override
  String toString() => 'BulkRequest[ids=$ids, action=$action]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'ids'] = this.ids;
    json[r'action'] = this.action;
    return json;
  }

  /// Returns a new [BulkRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BulkRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "BulkRequest[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "BulkRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return BulkRequest(
        ids: json[r'ids'] is Iterable
            ? (json[r'ids'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        action: BulkRequestActionEnum.fromJson(json[r'action'])!,
      );
    }
    return null;
  }

  static List<BulkRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <BulkRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BulkRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BulkRequest> mapFromJson(dynamic json) {
    final map = <String, BulkRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BulkRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BulkRequest-objects as value to a dart map
  static Map<String, List<BulkRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<BulkRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BulkRequest.listFromJson(
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

class BulkRequestActionEnum {
  /// Instantiate a new enum with the provided [value].
  const BulkRequestActionEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const favorite = BulkRequestActionEnum._(r'favorite');
  static const unfavorite = BulkRequestActionEnum._(r'unfavorite');
  static const archive = BulkRequestActionEnum._(r'archive');
  static const delete = BulkRequestActionEnum._(r'delete');

  /// List of all possible values in this [enum][BulkRequestActionEnum].
  static const values = <BulkRequestActionEnum>[
    favorite,
    unfavorite,
    archive,
    delete,
  ];

  static BulkRequestActionEnum? fromJson(dynamic value) =>
      BulkRequestActionEnumTypeTransformer().decode(value);

  static List<BulkRequestActionEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <BulkRequestActionEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BulkRequestActionEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [BulkRequestActionEnum] to String,
/// and [decode] dynamic data back to [BulkRequestActionEnum].
class BulkRequestActionEnumTypeTransformer {
  factory BulkRequestActionEnumTypeTransformer() =>
      _instance ??= const BulkRequestActionEnumTypeTransformer._();

  const BulkRequestActionEnumTypeTransformer._();

  String encode(BulkRequestActionEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a BulkRequestActionEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  BulkRequestActionEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'favorite':
          return BulkRequestActionEnum.favorite;
        case r'unfavorite':
          return BulkRequestActionEnum.unfavorite;
        case r'archive':
          return BulkRequestActionEnum.archive;
        case r'delete':
          return BulkRequestActionEnum.delete;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [BulkRequestActionEnumTypeTransformer] instance.
  static BulkRequestActionEnumTypeTransformer? _instance;
}

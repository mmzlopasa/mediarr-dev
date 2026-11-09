//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// Blur no faces, every face, or every face but those of the visible people
class HideFaces {
  /// Instantiate a new enum with the provided [value].
  const HideFaces._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const none = HideFaces._(r'none');
  static const all = HideFaces._(r'all');
  static const except = HideFaces._(r'except');

  /// List of all possible values in this [enum][HideFaces].
  static const values = <HideFaces>[
    none,
    all,
    except,
  ];

  static HideFaces? fromJson(dynamic value) =>
      HideFacesTypeTransformer().decode(value);

  static List<HideFaces> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <HideFaces>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HideFaces.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [HideFaces] to String,
/// and [decode] dynamic data back to [HideFaces].
class HideFacesTypeTransformer {
  factory HideFacesTypeTransformer() =>
      _instance ??= const HideFacesTypeTransformer._();

  const HideFacesTypeTransformer._();

  String encode(HideFaces data) => data.value;

  /// Decodes a [dynamic value][data] to a HideFaces.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  HideFaces? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'none':
          return HideFaces.none;
        case r'all':
          return HideFaces.all;
        case r'except':
          return HideFaces.except;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [HideFacesTypeTransformer] instance.
  static HideFacesTypeTransformer? _instance;
}

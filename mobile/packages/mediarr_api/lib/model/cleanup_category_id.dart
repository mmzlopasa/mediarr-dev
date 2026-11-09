//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CleanupCategoryId {
  /// Instantiate a new enum with the provided [value].
  const CleanupCategoryId._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const blurry = CleanupCategoryId._(r'blurry');
  static const screenshots = CleanupCategoryId._(r'screenshots');
  static const largeVideos = CleanupCategoryId._(r'largeVideos');
  static const bursts = CleanupCategoryId._(r'bursts');

  /// List of all possible values in this [enum][CleanupCategoryId].
  static const values = <CleanupCategoryId>[
    blurry,
    screenshots,
    largeVideos,
    bursts,
  ];

  static CleanupCategoryId? fromJson(dynamic value) =>
      CleanupCategoryIdTypeTransformer().decode(value);

  static List<CleanupCategoryId> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CleanupCategoryId>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CleanupCategoryId.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [CleanupCategoryId] to String,
/// and [decode] dynamic data back to [CleanupCategoryId].
class CleanupCategoryIdTypeTransformer {
  factory CleanupCategoryIdTypeTransformer() =>
      _instance ??= const CleanupCategoryIdTypeTransformer._();

  const CleanupCategoryIdTypeTransformer._();

  String encode(CleanupCategoryId data) => data.value;

  /// Decodes a [dynamic value][data] to a CleanupCategoryId.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  CleanupCategoryId? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'blurry':
          return CleanupCategoryId.blurry;
        case r'screenshots':
          return CleanupCategoryId.screenshots;
        case r'largeVideos':
          return CleanupCategoryId.largeVideos;
        case r'bursts':
          return CleanupCategoryId.bursts;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [CleanupCategoryIdTypeTransformer] instance.
  static CleanupCategoryIdTypeTransformer? _instance;
}

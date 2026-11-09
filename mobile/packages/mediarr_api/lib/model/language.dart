//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// English is the main language; de and sl are machine translated for now
class Language {
  /// Instantiate a new enum with the provided [value].
  const Language._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const en = Language._(r'en');
  static const hr = Language._(r'hr');
  static const de = Language._(r'de');
  static const sl = Language._(r'sl');

  /// List of all possible values in this [enum][Language].
  static const values = <Language>[
    en,
    hr,
    de,
    sl,
  ];

  static Language? fromJson(dynamic value) =>
      LanguageTypeTransformer().decode(value);

  static List<Language> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Language>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Language.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [Language] to String,
/// and [decode] dynamic data back to [Language].
class LanguageTypeTransformer {
  factory LanguageTypeTransformer() =>
      _instance ??= const LanguageTypeTransformer._();

  const LanguageTypeTransformer._();

  String encode(Language data) => data.value;

  /// Decodes a [dynamic value][data] to a Language.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  Language? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'en':
          return Language.en;
        case r'hr':
          return Language.hr;
        case r'de':
          return Language.de;
        case r'sl':
          return Language.sl;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [LanguageTypeTransformer] instance.
  static LanguageTypeTransformer? _instance;
}

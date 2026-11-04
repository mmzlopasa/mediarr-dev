//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class BackupRunRequest {
  /// Returns a new [BackupRunRequest] instance.
  BackupRunRequest({
    required this.kind,
  });

  BackupRunRequestKindEnum kind;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BackupRunRequest && other.kind == kind;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (kind.hashCode);

  @override
  String toString() => 'BackupRunRequest[kind=$kind]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'kind'] = this.kind;
    return json;
  }

  /// Returns a new [BackupRunRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BackupRunRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "BackupRunRequest[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "BackupRunRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return BackupRunRequest(
        kind: BackupRunRequestKindEnum.fromJson(json[r'kind'])!,
      );
    }
    return null;
  }

  static List<BackupRunRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <BackupRunRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BackupRunRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BackupRunRequest> mapFromJson(dynamic json) {
    final map = <String, BackupRunRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BackupRunRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BackupRunRequest-objects as value to a dart map
  static Map<String, List<BackupRunRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<BackupRunRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BackupRunRequest.listFromJson(
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
  };
}

class BackupRunRequestKindEnum {
  /// Instantiate a new enum with the provided [value].
  const BackupRunRequestKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const backup = BackupRunRequestKindEnum._(r'backup');
  static const restoreTest = BackupRunRequestKindEnum._(r'restore_test');

  /// List of all possible values in this [enum][BackupRunRequestKindEnum].
  static const values = <BackupRunRequestKindEnum>[
    backup,
    restoreTest,
  ];

  static BackupRunRequestKindEnum? fromJson(dynamic value) =>
      BackupRunRequestKindEnumTypeTransformer().decode(value);

  static List<BackupRunRequestKindEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <BackupRunRequestKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BackupRunRequestKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [BackupRunRequestKindEnum] to String,
/// and [decode] dynamic data back to [BackupRunRequestKindEnum].
class BackupRunRequestKindEnumTypeTransformer {
  factory BackupRunRequestKindEnumTypeTransformer() =>
      _instance ??= const BackupRunRequestKindEnumTypeTransformer._();

  const BackupRunRequestKindEnumTypeTransformer._();

  String encode(BackupRunRequestKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a BackupRunRequestKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  BackupRunRequestKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'backup':
          return BackupRunRequestKindEnum.backup;
        case r'restore_test':
          return BackupRunRequestKindEnum.restoreTest;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [BackupRunRequestKindEnumTypeTransformer] instance.
  static BackupRunRequestKindEnumTypeTransformer? _instance;
}

//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class StoryExport {
  /// Returns a new [StoryExport] instance.
  StoryExport({
    required this.id,
    required this.status,
  });

  String id;

  StoryExportStatusEnum status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryExport && other.id == id && other.status == status;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) + (status.hashCode);

  @override
  String toString() => 'StoryExport[id=$id, status=$status]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'status'] = this.status;
    return json;
  }

  /// Returns a new [StoryExport] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static StoryExport? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "StoryExport[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "StoryExport[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return StoryExport(
        id: mapValueOfType<String>(json, r'id')!,
        status: StoryExportStatusEnum.fromJson(json[r'status'])!,
      );
    }
    return null;
  }

  static List<StoryExport> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <StoryExport>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StoryExport.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, StoryExport> mapFromJson(dynamic json) {
    final map = <String, StoryExport>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = StoryExport.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of StoryExport-objects as value to a dart map
  static Map<String, List<StoryExport>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<StoryExport>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = StoryExport.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'status',
  };
}

class StoryExportStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const StoryExportStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const working = StoryExportStatusEnum._(r'working');
  static const ready = StoryExportStatusEnum._(r'ready');
  static const failed = StoryExportStatusEnum._(r'failed');

  /// List of all possible values in this [enum][StoryExportStatusEnum].
  static const values = <StoryExportStatusEnum>[
    working,
    ready,
    failed,
  ];

  static StoryExportStatusEnum? fromJson(dynamic value) =>
      StoryExportStatusEnumTypeTransformer().decode(value);

  static List<StoryExportStatusEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <StoryExportStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StoryExportStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [StoryExportStatusEnum] to String,
/// and [decode] dynamic data back to [StoryExportStatusEnum].
class StoryExportStatusEnumTypeTransformer {
  factory StoryExportStatusEnumTypeTransformer() =>
      _instance ??= const StoryExportStatusEnumTypeTransformer._();

  const StoryExportStatusEnumTypeTransformer._();

  String encode(StoryExportStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a StoryExportStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  StoryExportStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'working':
          return StoryExportStatusEnum.working;
        case r'ready':
          return StoryExportStatusEnum.ready;
        case r'failed':
          return StoryExportStatusEnum.failed;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [StoryExportStatusEnumTypeTransformer] instance.
  static StoryExportStatusEnumTypeTransformer? _instance;
}

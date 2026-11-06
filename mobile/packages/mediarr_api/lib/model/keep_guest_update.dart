//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class KeepGuestUpdate {
  /// Returns a new [KeepGuestUpdate] instance.
  KeepGuestUpdate({
    required this.quotaBytes,
    required this.status,
  });

  int quotaBytes;

  KeepGuestUpdateStatusEnum status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeepGuestUpdate &&
          other.quotaBytes == quotaBytes &&
          other.status == status;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (quotaBytes.hashCode) + (status.hashCode);

  @override
  String toString() =>
      'KeepGuestUpdate[quotaBytes=$quotaBytes, status=$status]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'quotaBytes'] = this.quotaBytes;
    json[r'status'] = this.status;
    return json;
  }

  /// Returns a new [KeepGuestUpdate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static KeepGuestUpdate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "KeepGuestUpdate[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "KeepGuestUpdate[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return KeepGuestUpdate(
        quotaBytes: mapValueOfType<int>(json, r'quotaBytes')!,
        status: KeepGuestUpdateStatusEnum.fromJson(json[r'status'])!,
      );
    }
    return null;
  }

  static List<KeepGuestUpdate> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <KeepGuestUpdate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = KeepGuestUpdate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, KeepGuestUpdate> mapFromJson(dynamic json) {
    final map = <String, KeepGuestUpdate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = KeepGuestUpdate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of KeepGuestUpdate-objects as value to a dart map
  static Map<String, List<KeepGuestUpdate>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<KeepGuestUpdate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = KeepGuestUpdate.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'quotaBytes',
    'status',
  };
}

class KeepGuestUpdateStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const KeepGuestUpdateStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const active = KeepGuestUpdateStatusEnum._(r'active');
  static const stopped = KeepGuestUpdateStatusEnum._(r'stopped');

  /// List of all possible values in this [enum][KeepGuestUpdateStatusEnum].
  static const values = <KeepGuestUpdateStatusEnum>[
    active,
    stopped,
  ];

  static KeepGuestUpdateStatusEnum? fromJson(dynamic value) =>
      KeepGuestUpdateStatusEnumTypeTransformer().decode(value);

  static List<KeepGuestUpdateStatusEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <KeepGuestUpdateStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = KeepGuestUpdateStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [KeepGuestUpdateStatusEnum] to String,
/// and [decode] dynamic data back to [KeepGuestUpdateStatusEnum].
class KeepGuestUpdateStatusEnumTypeTransformer {
  factory KeepGuestUpdateStatusEnumTypeTransformer() =>
      _instance ??= const KeepGuestUpdateStatusEnumTypeTransformer._();

  const KeepGuestUpdateStatusEnumTypeTransformer._();

  String encode(KeepGuestUpdateStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a KeepGuestUpdateStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  KeepGuestUpdateStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'active':
          return KeepGuestUpdateStatusEnum.active;
        case r'stopped':
          return KeepGuestUpdateStatusEnum.stopped;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [KeepGuestUpdateStatusEnumTypeTransformer] instance.
  static KeepGuestUpdateStatusEnumTypeTransformer? _instance;
}

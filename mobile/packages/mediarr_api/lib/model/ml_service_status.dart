//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MlServiceStatus {
  /// Returns a new [MlServiceStatus] instance.
  MlServiceStatus({
    required this.state,
    this.models = const [],
    this.rssBytes,
    this.acceleration,
    this.idleMinutes,
  });

  MlServiceStatusStateEnum state;

  List<MlModel> models;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? rssBytes;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  MlAcceleration? acceleration;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? idleMinutes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MlServiceStatus &&
          other.state == state &&
          _deepEquality.equals(other.models, models) &&
          other.rssBytes == rssBytes &&
          other.acceleration == acceleration &&
          other.idleMinutes == idleMinutes;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (state.hashCode) +
      (models.hashCode) +
      (rssBytes == null ? 0 : rssBytes!.hashCode) +
      (acceleration == null ? 0 : acceleration!.hashCode) +
      (idleMinutes == null ? 0 : idleMinutes!.hashCode);

  @override
  String toString() =>
      'MlServiceStatus[state=$state, models=$models, rssBytes=$rssBytes, acceleration=$acceleration, idleMinutes=$idleMinutes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'state'] = this.state;
    json[r'models'] = this.models;
    if (this.rssBytes != null) {
      json[r'rssBytes'] = this.rssBytes;
    } else {
      json[r'rssBytes'] = null;
    }
    if (this.acceleration != null) {
      json[r'acceleration'] = this.acceleration;
    } else {
      json[r'acceleration'] = null;
    }
    if (this.idleMinutes != null) {
      json[r'idleMinutes'] = this.idleMinutes;
    } else {
      json[r'idleMinutes'] = null;
    }
    return json;
  }

  /// Returns a new [MlServiceStatus] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MlServiceStatus? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "MlServiceStatus[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "MlServiceStatus[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return MlServiceStatus(
        state: MlServiceStatusStateEnum.fromJson(json[r'state'])!,
        models: MlModel.listFromJson(json[r'models']),
        rssBytes: mapValueOfType<int>(json, r'rssBytes'),
        acceleration: MlAcceleration.fromJson(json[r'acceleration']),
        idleMinutes: mapValueOfType<double>(json, r'idleMinutes'),
      );
    }
    return null;
  }

  static List<MlServiceStatus> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <MlServiceStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MlServiceStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MlServiceStatus> mapFromJson(dynamic json) {
    final map = <String, MlServiceStatus>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MlServiceStatus.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MlServiceStatus-objects as value to a dart map
  static Map<String, List<MlServiceStatus>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<MlServiceStatus>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MlServiceStatus.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'state',
  };
}

class MlServiceStatusStateEnum {
  /// Instantiate a new enum with the provided [value].
  const MlServiceStatusStateEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const connected = MlServiceStatusStateEnum._(r'connected');
  static const unreachable = MlServiceStatusStateEnum._(r'unreachable');
  static const wrongToken = MlServiceStatusStateEnum._(r'wrongToken');

  /// List of all possible values in this [enum][MlServiceStatusStateEnum].
  static const values = <MlServiceStatusStateEnum>[
    connected,
    unreachable,
    wrongToken,
  ];

  static MlServiceStatusStateEnum? fromJson(dynamic value) =>
      MlServiceStatusStateEnumTypeTransformer().decode(value);

  static List<MlServiceStatusStateEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <MlServiceStatusStateEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MlServiceStatusStateEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [MlServiceStatusStateEnum] to String,
/// and [decode] dynamic data back to [MlServiceStatusStateEnum].
class MlServiceStatusStateEnumTypeTransformer {
  factory MlServiceStatusStateEnumTypeTransformer() =>
      _instance ??= const MlServiceStatusStateEnumTypeTransformer._();

  const MlServiceStatusStateEnumTypeTransformer._();

  String encode(MlServiceStatusStateEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a MlServiceStatusStateEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  MlServiceStatusStateEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'connected':
          return MlServiceStatusStateEnum.connected;
        case r'unreachable':
          return MlServiceStatusStateEnum.unreachable;
        case r'wrongToken':
          return MlServiceStatusStateEnum.wrongToken;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [MlServiceStatusStateEnumTypeTransformer] instance.
  static MlServiceStatusStateEnumTypeTransformer? _instance;
}

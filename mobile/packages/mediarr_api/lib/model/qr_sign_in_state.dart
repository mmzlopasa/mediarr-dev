//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class QRSignInState {
  /// Returns a new [QRSignInState] instance.
  QRSignInState({
    required this.status,
    this.device,
    required this.expiresAt,
  });

  QRSignInStateStatusEnum status;

  /// What the device that scanned the code calls itself
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? device;

  DateTime expiresAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QRSignInState &&
          other.status == status &&
          other.device == device &&
          other.expiresAt == expiresAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (status.hashCode) +
      (device == null ? 0 : device!.hashCode) +
      (expiresAt.hashCode);

  @override
  String toString() =>
      'QRSignInState[status=$status, device=$device, expiresAt=$expiresAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'status'] = this.status;
    if (this.device != null) {
      json[r'device'] = this.device;
    } else {
      json[r'device'] = null;
    }
    json[r'expiresAt'] = this.expiresAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [QRSignInState] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static QRSignInState? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "QRSignInState[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "QRSignInState[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return QRSignInState(
        status: QRSignInStateStatusEnum.fromJson(json[r'status'])!,
        device: mapValueOfType<String>(json, r'device'),
        expiresAt: mapDateTime(json, r'expiresAt', r'')!,
      );
    }
    return null;
  }

  static List<QRSignInState> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <QRSignInState>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = QRSignInState.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, QRSignInState> mapFromJson(dynamic json) {
    final map = <String, QRSignInState>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = QRSignInState.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of QRSignInState-objects as value to a dart map
  static Map<String, List<QRSignInState>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<QRSignInState>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = QRSignInState.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'status',
    'expiresAt',
  };
}

class QRSignInStateStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const QRSignInStateStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const waiting = QRSignInStateStatusEnum._(r'waiting');
  static const requested = QRSignInStateStatusEnum._(r'requested');
  static const allowed = QRSignInStateStatusEnum._(r'allowed');
  static const denied = QRSignInStateStatusEnum._(r'denied');
  static const used = QRSignInStateStatusEnum._(r'used');
  static const expired = QRSignInStateStatusEnum._(r'expired');

  /// List of all possible values in this [enum][QRSignInStateStatusEnum].
  static const values = <QRSignInStateStatusEnum>[
    waiting,
    requested,
    allowed,
    denied,
    used,
    expired,
  ];

  static QRSignInStateStatusEnum? fromJson(dynamic value) =>
      QRSignInStateStatusEnumTypeTransformer().decode(value);

  static List<QRSignInStateStatusEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <QRSignInStateStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = QRSignInStateStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [QRSignInStateStatusEnum] to String,
/// and [decode] dynamic data back to [QRSignInStateStatusEnum].
class QRSignInStateStatusEnumTypeTransformer {
  factory QRSignInStateStatusEnumTypeTransformer() =>
      _instance ??= const QRSignInStateStatusEnumTypeTransformer._();

  const QRSignInStateStatusEnumTypeTransformer._();

  String encode(QRSignInStateStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a QRSignInStateStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  QRSignInStateStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'waiting':
          return QRSignInStateStatusEnum.waiting;
        case r'requested':
          return QRSignInStateStatusEnum.requested;
        case r'allowed':
          return QRSignInStateStatusEnum.allowed;
        case r'denied':
          return QRSignInStateStatusEnum.denied;
        case r'used':
          return QRSignInStateStatusEnum.used;
        case r'expired':
          return QRSignInStateStatusEnum.expired;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [QRSignInStateStatusEnumTypeTransformer] instance.
  static QRSignInStateStatusEnumTypeTransformer? _instance;
}

//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Webhook {
  /// Returns a new [Webhook] instance.
  Webhook({
    required this.id,
    required this.url,
    this.events = const [],
    required this.lastStatus,
    required this.lastError,
    this.lastAt,
  });

  String id;

  String url;

  List<WebhookEventsEnum> events;

  int lastStatus;

  String lastError;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? lastAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Webhook &&
          other.id == id &&
          other.url == url &&
          _deepEquality.equals(other.events, events) &&
          other.lastStatus == lastStatus &&
          other.lastError == lastError &&
          other.lastAt == lastAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (url.hashCode) +
      (events.hashCode) +
      (lastStatus.hashCode) +
      (lastError.hashCode) +
      (lastAt == null ? 0 : lastAt!.hashCode);

  @override
  String toString() =>
      'Webhook[id=$id, url=$url, events=$events, lastStatus=$lastStatus, lastError=$lastError, lastAt=$lastAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'url'] = this.url;
    json[r'events'] = this.events;
    json[r'lastStatus'] = this.lastStatus;
    json[r'lastError'] = this.lastError;
    if (this.lastAt != null) {
      json[r'lastAt'] = this.lastAt!.toUtc().toIso8601String();
    } else {
      json[r'lastAt'] = null;
    }
    return json;
  }

  /// Returns a new [Webhook] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Webhook? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Webhook[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Webhook[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Webhook(
        id: mapValueOfType<String>(json, r'id')!,
        url: mapValueOfType<String>(json, r'url')!,
        events: WebhookEventsEnum.listFromJson(json[r'events']),
        lastStatus: mapValueOfType<int>(json, r'lastStatus')!,
        lastError: mapValueOfType<String>(json, r'lastError')!,
        lastAt: mapDateTime(json, r'lastAt', r''),
      );
    }
    return null;
  }

  static List<Webhook> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Webhook>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Webhook.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Webhook> mapFromJson(dynamic json) {
    final map = <String, Webhook>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Webhook.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Webhook-objects as value to a dart map
  static Map<String, List<Webhook>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Webhook>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Webhook.listFromJson(
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
    'url',
    'events',
    'lastStatus',
    'lastError',
  };
}

class WebhookEventsEnum {
  /// Instantiate a new enum with the provided [value].
  const WebhookEventsEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const assetPeriodReady = WebhookEventsEnum._(r'asset.ready');
  static const personPeriodCreated = WebhookEventsEnum._(r'person.created');
  static const backupPeriodFinished = WebhookEventsEnum._(r'backup.finished');

  /// List of all possible values in this [enum][WebhookEventsEnum].
  static const values = <WebhookEventsEnum>[
    assetPeriodReady,
    personPeriodCreated,
    backupPeriodFinished,
  ];

  static WebhookEventsEnum? fromJson(dynamic value) =>
      WebhookEventsEnumTypeTransformer().decode(value);

  static List<WebhookEventsEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <WebhookEventsEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WebhookEventsEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [WebhookEventsEnum] to String,
/// and [decode] dynamic data back to [WebhookEventsEnum].
class WebhookEventsEnumTypeTransformer {
  factory WebhookEventsEnumTypeTransformer() =>
      _instance ??= const WebhookEventsEnumTypeTransformer._();

  const WebhookEventsEnumTypeTransformer._();

  String encode(WebhookEventsEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a WebhookEventsEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  WebhookEventsEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'asset.ready':
          return WebhookEventsEnum.assetPeriodReady;
        case r'person.created':
          return WebhookEventsEnum.personPeriodCreated;
        case r'backup.finished':
          return WebhookEventsEnum.backupPeriodFinished;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [WebhookEventsEnumTypeTransformer] instance.
  static WebhookEventsEnumTypeTransformer? _instance;
}

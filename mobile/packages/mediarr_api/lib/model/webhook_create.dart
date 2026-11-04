//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class WebhookCreate {
  /// Returns a new [WebhookCreate] instance.
  WebhookCreate({
    required this.url,
    this.events = const [],
  });

  String url;

  List<WebhookCreateEventsEnum> events;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WebhookCreate &&
          other.url == url &&
          _deepEquality.equals(other.events, events);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (url.hashCode) + (events.hashCode);

  @override
  String toString() => 'WebhookCreate[url=$url, events=$events]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'url'] = this.url;
    json[r'events'] = this.events;
    return json;
  }

  /// Returns a new [WebhookCreate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static WebhookCreate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "WebhookCreate[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "WebhookCreate[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return WebhookCreate(
        url: mapValueOfType<String>(json, r'url')!,
        events: WebhookCreateEventsEnum.listFromJson(json[r'events']),
      );
    }
    return null;
  }

  static List<WebhookCreate> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <WebhookCreate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WebhookCreate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, WebhookCreate> mapFromJson(dynamic json) {
    final map = <String, WebhookCreate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = WebhookCreate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of WebhookCreate-objects as value to a dart map
  static Map<String, List<WebhookCreate>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<WebhookCreate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = WebhookCreate.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'url',
    'events',
  };
}

class WebhookCreateEventsEnum {
  /// Instantiate a new enum with the provided [value].
  const WebhookCreateEventsEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const assetPeriodReady = WebhookCreateEventsEnum._(r'asset.ready');
  static const personPeriodCreated =
      WebhookCreateEventsEnum._(r'person.created');
  static const backupPeriodFinished =
      WebhookCreateEventsEnum._(r'backup.finished');

  /// List of all possible values in this [enum][WebhookCreateEventsEnum].
  static const values = <WebhookCreateEventsEnum>[
    assetPeriodReady,
    personPeriodCreated,
    backupPeriodFinished,
  ];

  static WebhookCreateEventsEnum? fromJson(dynamic value) =>
      WebhookCreateEventsEnumTypeTransformer().decode(value);

  static List<WebhookCreateEventsEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <WebhookCreateEventsEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WebhookCreateEventsEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [WebhookCreateEventsEnum] to String,
/// and [decode] dynamic data back to [WebhookCreateEventsEnum].
class WebhookCreateEventsEnumTypeTransformer {
  factory WebhookCreateEventsEnumTypeTransformer() =>
      _instance ??= const WebhookCreateEventsEnumTypeTransformer._();

  const WebhookCreateEventsEnumTypeTransformer._();

  String encode(WebhookCreateEventsEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a WebhookCreateEventsEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  WebhookCreateEventsEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'asset.ready':
          return WebhookCreateEventsEnum.assetPeriodReady;
        case r'person.created':
          return WebhookCreateEventsEnum.personPeriodCreated;
        case r'backup.finished':
          return WebhookCreateEventsEnum.backupPeriodFinished;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [WebhookCreateEventsEnumTypeTransformer] instance.
  static WebhookCreateEventsEnumTypeTransformer? _instance;
}

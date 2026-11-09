//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ServerHello {
  /// Returns a new [ServerHello] instance.
  ServerHello({
    required this.app,
    required this.version,
  });

  ServerHelloAppEnum app;

  String version;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerHello && other.app == app && other.version == version;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (app.hashCode) + (version.hashCode);

  @override
  String toString() => 'ServerHello[app=$app, version=$version]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'app'] = this.app;
    json[r'version'] = this.version;
    return json;
  }

  /// Returns a new [ServerHello] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ServerHello? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ServerHello[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ServerHello[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ServerHello(
        app: ServerHelloAppEnum.fromJson(json[r'app'])!,
        version: mapValueOfType<String>(json, r'version')!,
      );
    }
    return null;
  }

  static List<ServerHello> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ServerHello>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ServerHello.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ServerHello> mapFromJson(dynamic json) {
    final map = <String, ServerHello>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ServerHello.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ServerHello-objects as value to a dart map
  static Map<String, List<ServerHello>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ServerHello>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ServerHello.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'app',
    'version',
  };
}

class ServerHelloAppEnum {
  /// Instantiate a new enum with the provided [value].
  const ServerHelloAppEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const mediarr = ServerHelloAppEnum._(r'mediarr');

  /// List of all possible values in this [enum][ServerHelloAppEnum].
  static const values = <ServerHelloAppEnum>[
    mediarr,
  ];

  static ServerHelloAppEnum? fromJson(dynamic value) =>
      ServerHelloAppEnumTypeTransformer().decode(value);

  static List<ServerHelloAppEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ServerHelloAppEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ServerHelloAppEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ServerHelloAppEnum] to String,
/// and [decode] dynamic data back to [ServerHelloAppEnum].
class ServerHelloAppEnumTypeTransformer {
  factory ServerHelloAppEnumTypeTransformer() =>
      _instance ??= const ServerHelloAppEnumTypeTransformer._();

  const ServerHelloAppEnumTypeTransformer._();

  String encode(ServerHelloAppEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ServerHelloAppEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ServerHelloAppEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'mediarr':
          return ServerHelloAppEnum.mediarr;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ServerHelloAppEnumTypeTransformer] instance.
  static ServerHelloAppEnumTypeTransformer? _instance;
}

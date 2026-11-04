//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ImportCreate {
  /// Returns a new [ImportCreate] instance.
  ImportCreate({
    required this.source_,
    required this.ownerId,
    this.address,
    this.apiKey,
    this.folder,
  });

  ImportCreateSource_Enum source_;

  /// Whose library it goes into
  String ownerId;

  /// Immich only
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? address;

  /// Immich only. Forgotten when the import ends
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? apiKey;

  /// Takeout and iCloud: an unpacked folder inside the external library's mount
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? folder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportCreate &&
          other.source_ == source_ &&
          other.ownerId == ownerId &&
          other.address == address &&
          other.apiKey == apiKey &&
          other.folder == folder;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (source_.hashCode) +
      (ownerId.hashCode) +
      (address == null ? 0 : address!.hashCode) +
      (apiKey == null ? 0 : apiKey!.hashCode) +
      (folder == null ? 0 : folder!.hashCode);

  @override
  String toString() =>
      'ImportCreate[source_=$source_, ownerId=$ownerId, address=$address, apiKey=$apiKey, folder=$folder]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'source'] = this.source_;
    json[r'ownerId'] = this.ownerId;
    if (this.address != null) {
      json[r'address'] = this.address;
    } else {
      json[r'address'] = null;
    }
    if (this.apiKey != null) {
      json[r'apiKey'] = this.apiKey;
    } else {
      json[r'apiKey'] = null;
    }
    if (this.folder != null) {
      json[r'folder'] = this.folder;
    } else {
      json[r'folder'] = null;
    }
    return json;
  }

  /// Returns a new [ImportCreate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ImportCreate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ImportCreate[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ImportCreate[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ImportCreate(
        source_: ImportCreateSource_Enum.fromJson(json[r'source'])!,
        ownerId: mapValueOfType<String>(json, r'ownerId')!,
        address: mapValueOfType<String>(json, r'address'),
        apiKey: mapValueOfType<String>(json, r'apiKey'),
        folder: mapValueOfType<String>(json, r'folder'),
      );
    }
    return null;
  }

  static List<ImportCreate> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ImportCreate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ImportCreate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ImportCreate> mapFromJson(dynamic json) {
    final map = <String, ImportCreate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ImportCreate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ImportCreate-objects as value to a dart map
  static Map<String, List<ImportCreate>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ImportCreate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ImportCreate.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'source',
    'ownerId',
  };
}

class ImportCreateSource_Enum {
  /// Instantiate a new enum with the provided [value].
  const ImportCreateSource_Enum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const immich = ImportCreateSource_Enum._(r'immich');
  static const takeout = ImportCreateSource_Enum._(r'takeout');
  static const icloud = ImportCreateSource_Enum._(r'icloud');

  /// List of all possible values in this [enum][ImportCreateSource_Enum].
  static const values = <ImportCreateSource_Enum>[
    immich,
    takeout,
    icloud,
  ];

  static ImportCreateSource_Enum? fromJson(dynamic value) =>
      ImportCreateSource_EnumTypeTransformer().decode(value);

  static List<ImportCreateSource_Enum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ImportCreateSource_Enum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ImportCreateSource_Enum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ImportCreateSource_Enum] to String,
/// and [decode] dynamic data back to [ImportCreateSource_Enum].
class ImportCreateSource_EnumTypeTransformer {
  factory ImportCreateSource_EnumTypeTransformer() =>
      _instance ??= const ImportCreateSource_EnumTypeTransformer._();

  const ImportCreateSource_EnumTypeTransformer._();

  String encode(ImportCreateSource_Enum data) => data.value;

  /// Decodes a [dynamic value][data] to a ImportCreateSource_Enum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ImportCreateSource_Enum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'immich':
          return ImportCreateSource_Enum.immich;
        case r'takeout':
          return ImportCreateSource_Enum.takeout;
        case r'icloud':
          return ImportCreateSource_Enum.icloud;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ImportCreateSource_EnumTypeTransformer] instance.
  static ImportCreateSource_EnumTypeTransformer? _instance;
}

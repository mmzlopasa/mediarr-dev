//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class QRSignIn {
  /// Returns a new [QRSignIn] instance.
  QRSignIn({
    required this.id,
    required this.code,
    required this.link,
    this.server,
    required this.expiresAt,
  });

  String id;

  /// Eight characters, shown as XXXX-XXXX for typing by hand
  String code;

  /// mediarr://sign-in?server=...&code=..., the contents of the QR code
  String link;

  /// The address the code was made on
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? server;

  DateTime expiresAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QRSignIn &&
          other.id == id &&
          other.code == code &&
          other.link == link &&
          other.server == server &&
          other.expiresAt == expiresAt;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (code.hashCode) +
      (link.hashCode) +
      (server == null ? 0 : server!.hashCode) +
      (expiresAt.hashCode);

  @override
  String toString() =>
      'QRSignIn[id=$id, code=$code, link=$link, server=$server, expiresAt=$expiresAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'code'] = this.code;
    json[r'link'] = this.link;
    if (this.server != null) {
      json[r'server'] = this.server;
    } else {
      json[r'server'] = null;
    }
    json[r'expiresAt'] = this.expiresAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [QRSignIn] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static QRSignIn? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "QRSignIn[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "QRSignIn[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return QRSignIn(
        id: mapValueOfType<String>(json, r'id')!,
        code: mapValueOfType<String>(json, r'code')!,
        link: mapValueOfType<String>(json, r'link')!,
        server: mapValueOfType<String>(json, r'server'),
        expiresAt: mapDateTime(json, r'expiresAt', r'')!,
      );
    }
    return null;
  }

  static List<QRSignIn> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <QRSignIn>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = QRSignIn.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, QRSignIn> mapFromJson(dynamic json) {
    final map = <String, QRSignIn>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = QRSignIn.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of QRSignIn-objects as value to a dart map
  static Map<String, List<QRSignIn>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<QRSignIn>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = QRSignIn.listFromJson(
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
    'code',
    'link',
    'expiresAt',
  };
}

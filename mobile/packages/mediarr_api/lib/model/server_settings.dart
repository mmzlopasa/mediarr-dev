//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ServerSettings {
  /// Returns a new [ServerSettings] instance.
  ServerSettings({
    required this.trashDays,
    required this.imageQuality,
    required this.previewSize,
    required this.videoQuality,
    required this.videoMaxHeight,
    required this.loginMessage,
    required this.passwordLogin,
  });

  int trashDays;

  int imageQuality;

  int previewSize;

  /// Lower is better and larger
  int videoQuality;

  int videoMaxHeight;

  String loginMessage;

  bool passwordLogin;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerSettings &&
          other.trashDays == trashDays &&
          other.imageQuality == imageQuality &&
          other.previewSize == previewSize &&
          other.videoQuality == videoQuality &&
          other.videoMaxHeight == videoMaxHeight &&
          other.loginMessage == loginMessage &&
          other.passwordLogin == passwordLogin;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (trashDays.hashCode) +
      (imageQuality.hashCode) +
      (previewSize.hashCode) +
      (videoQuality.hashCode) +
      (videoMaxHeight.hashCode) +
      (loginMessage.hashCode) +
      (passwordLogin.hashCode);

  @override
  String toString() =>
      'ServerSettings[trashDays=$trashDays, imageQuality=$imageQuality, previewSize=$previewSize, videoQuality=$videoQuality, videoMaxHeight=$videoMaxHeight, loginMessage=$loginMessage, passwordLogin=$passwordLogin]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'trashDays'] = this.trashDays;
    json[r'imageQuality'] = this.imageQuality;
    json[r'previewSize'] = this.previewSize;
    json[r'videoQuality'] = this.videoQuality;
    json[r'videoMaxHeight'] = this.videoMaxHeight;
    json[r'loginMessage'] = this.loginMessage;
    json[r'passwordLogin'] = this.passwordLogin;
    return json;
  }

  /// Returns a new [ServerSettings] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ServerSettings? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ServerSettings[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ServerSettings[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ServerSettings(
        trashDays: mapValueOfType<int>(json, r'trashDays')!,
        imageQuality: mapValueOfType<int>(json, r'imageQuality')!,
        previewSize: mapValueOfType<int>(json, r'previewSize')!,
        videoQuality: mapValueOfType<int>(json, r'videoQuality')!,
        videoMaxHeight: mapValueOfType<int>(json, r'videoMaxHeight')!,
        loginMessage: mapValueOfType<String>(json, r'loginMessage')!,
        passwordLogin: mapValueOfType<bool>(json, r'passwordLogin')!,
      );
    }
    return null;
  }

  static List<ServerSettings> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ServerSettings>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ServerSettings.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ServerSettings> mapFromJson(dynamic json) {
    final map = <String, ServerSettings>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ServerSettings.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ServerSettings-objects as value to a dart map
  static Map<String, List<ServerSettings>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ServerSettings>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ServerSettings.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'trashDays',
    'imageQuality',
    'previewSize',
    'videoQuality',
    'videoMaxHeight',
    'loginMessage',
    'passwordLogin',
  };
}

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
    required this.maintenance,
    required this.faceMinScore,
    required this.faceMaxDistance,
    required this.workerConcurrency,
    required this.videoWorkers,
    required this.analysisWorkers,
    required this.externalScanHours,
    this.visibleOnNetwork,
    this.serverName,
  });

  int trashDays;

  int imageQuality;

  int previewSize;

  /// Lower is better and larger
  int videoQuality;

  int videoMaxHeight;

  String loginMessage;

  bool passwordLogin;

  /// Only administrators can use the server
  bool maintenance;

  /// How sure a face must be
  double faceMinScore;

  /// How alike two faces must be to be one person
  double faceMaxDistance;

  /// 0 uses WORKER_CONCURRENCY. Applies after a restart of the worker
  int workerConcurrency;

  /// Applies after a restart of the worker
  int videoWorkers;

  /// Applies after a restart of the worker
  int analysisWorkers;

  int externalScanHours;

  /// Apps on the same network can find this server. Left out keeps it on
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? visibleOnNetwork;

  /// What people see this server called. Left out keeps the name it has
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? serverName;

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
          other.passwordLogin == passwordLogin &&
          other.maintenance == maintenance &&
          other.faceMinScore == faceMinScore &&
          other.faceMaxDistance == faceMaxDistance &&
          other.workerConcurrency == workerConcurrency &&
          other.videoWorkers == videoWorkers &&
          other.analysisWorkers == analysisWorkers &&
          other.externalScanHours == externalScanHours &&
          other.visibleOnNetwork == visibleOnNetwork &&
          other.serverName == serverName;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (trashDays.hashCode) +
      (imageQuality.hashCode) +
      (previewSize.hashCode) +
      (videoQuality.hashCode) +
      (videoMaxHeight.hashCode) +
      (loginMessage.hashCode) +
      (passwordLogin.hashCode) +
      (maintenance.hashCode) +
      (faceMinScore.hashCode) +
      (faceMaxDistance.hashCode) +
      (workerConcurrency.hashCode) +
      (videoWorkers.hashCode) +
      (analysisWorkers.hashCode) +
      (externalScanHours.hashCode) +
      (visibleOnNetwork == null ? 0 : visibleOnNetwork!.hashCode) +
      (serverName == null ? 0 : serverName!.hashCode);

  @override
  String toString() =>
      'ServerSettings[trashDays=$trashDays, imageQuality=$imageQuality, previewSize=$previewSize, videoQuality=$videoQuality, videoMaxHeight=$videoMaxHeight, loginMessage=$loginMessage, passwordLogin=$passwordLogin, maintenance=$maintenance, faceMinScore=$faceMinScore, faceMaxDistance=$faceMaxDistance, workerConcurrency=$workerConcurrency, videoWorkers=$videoWorkers, analysisWorkers=$analysisWorkers, externalScanHours=$externalScanHours, visibleOnNetwork=$visibleOnNetwork, serverName=$serverName]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'trashDays'] = this.trashDays;
    json[r'imageQuality'] = this.imageQuality;
    json[r'previewSize'] = this.previewSize;
    json[r'videoQuality'] = this.videoQuality;
    json[r'videoMaxHeight'] = this.videoMaxHeight;
    json[r'loginMessage'] = this.loginMessage;
    json[r'passwordLogin'] = this.passwordLogin;
    json[r'maintenance'] = this.maintenance;
    json[r'faceMinScore'] = this.faceMinScore;
    json[r'faceMaxDistance'] = this.faceMaxDistance;
    json[r'workerConcurrency'] = this.workerConcurrency;
    json[r'videoWorkers'] = this.videoWorkers;
    json[r'analysisWorkers'] = this.analysisWorkers;
    json[r'externalScanHours'] = this.externalScanHours;
    if (this.visibleOnNetwork != null) {
      json[r'visibleOnNetwork'] = this.visibleOnNetwork;
    } else {
      json[r'visibleOnNetwork'] = null;
    }
    if (this.serverName != null) {
      json[r'serverName'] = this.serverName;
    } else {
      json[r'serverName'] = null;
    }
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
        maintenance: mapValueOfType<bool>(json, r'maintenance')!,
        faceMinScore: mapValueOfType<double>(json, r'faceMinScore')!,
        faceMaxDistance: mapValueOfType<double>(json, r'faceMaxDistance')!,
        workerConcurrency: mapValueOfType<int>(json, r'workerConcurrency')!,
        videoWorkers: mapValueOfType<int>(json, r'videoWorkers')!,
        analysisWorkers: mapValueOfType<int>(json, r'analysisWorkers')!,
        externalScanHours: mapValueOfType<int>(json, r'externalScanHours')!,
        visibleOnNetwork: mapValueOfType<bool>(json, r'visibleOnNetwork'),
        serverName: mapValueOfType<String>(json, r'serverName'),
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
    'maintenance',
    'faceMinScore',
    'faceMaxDistance',
    'workerConcurrency',
    'videoWorkers',
    'analysisWorkers',
    'externalScanHours',
  };
}

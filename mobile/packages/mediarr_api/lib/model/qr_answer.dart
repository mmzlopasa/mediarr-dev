//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class QRAnswer {
  /// Returns a new [QRAnswer] instance.
  QRAnswer({
    required this.allow,
  });

  bool allow;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is QRAnswer && other.allow == allow;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (allow.hashCode);

  @override
  String toString() => 'QRAnswer[allow=$allow]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'allow'] = this.allow;
    return json;
  }

  /// Returns a new [QRAnswer] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static QRAnswer? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "QRAnswer[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "QRAnswer[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return QRAnswer(
        allow: mapValueOfType<bool>(json, r'allow')!,
      );
    }
    return null;
  }

  static List<QRAnswer> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <QRAnswer>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = QRAnswer.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, QRAnswer> mapFromJson(dynamic json) {
    final map = <String, QRAnswer>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = QRAnswer.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of QRAnswer-objects as value to a dart map
  static Map<String, List<QRAnswer>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<QRAnswer>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = QRAnswer.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'allow',
  };
}

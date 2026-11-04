//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class QuotaUpdate {
  /// Returns a new [QuotaUpdate] instance.
  QuotaUpdate({
    this.quotaBytes,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? quotaBytes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuotaUpdate && other.quotaBytes == quotaBytes;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (quotaBytes == null ? 0 : quotaBytes!.hashCode);

  @override
  String toString() => 'QuotaUpdate[quotaBytes=$quotaBytes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.quotaBytes != null) {
      json[r'quotaBytes'] = this.quotaBytes;
    } else {
      json[r'quotaBytes'] = null;
    }
    return json;
  }

  /// Returns a new [QuotaUpdate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static QuotaUpdate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "QuotaUpdate[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "QuotaUpdate[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return QuotaUpdate(
        quotaBytes: mapValueOfType<int>(json, r'quotaBytes'),
      );
    }
    return null;
  }

  static List<QuotaUpdate> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <QuotaUpdate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = QuotaUpdate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, QuotaUpdate> mapFromJson(dynamic json) {
    final map = <String, QuotaUpdate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = QuotaUpdate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of QuotaUpdate-objects as value to a dart map
  static Map<String, List<QuotaUpdate>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<QuotaUpdate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = QuotaUpdate.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{};
}

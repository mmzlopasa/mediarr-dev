//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DuplicateResolveResult {
  /// Returns a new [DuplicateResolveResult] instance.
  DuplicateResolveResult({
    required this.groups,
    required this.trashed,
    required this.freedBytes,
    required this.background,
  });

  int groups;

  int trashed;

  int freedBytes;

  bool background;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DuplicateResolveResult &&
          other.groups == groups &&
          other.trashed == trashed &&
          other.freedBytes == freedBytes &&
          other.background == background;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (groups.hashCode) +
      (trashed.hashCode) +
      (freedBytes.hashCode) +
      (background.hashCode);

  @override
  String toString() =>
      'DuplicateResolveResult[groups=$groups, trashed=$trashed, freedBytes=$freedBytes, background=$background]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'groups'] = this.groups;
    json[r'trashed'] = this.trashed;
    json[r'freedBytes'] = this.freedBytes;
    json[r'background'] = this.background;
    return json;
  }

  /// Returns a new [DuplicateResolveResult] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DuplicateResolveResult? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "DuplicateResolveResult[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "DuplicateResolveResult[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return DuplicateResolveResult(
        groups: mapValueOfType<int>(json, r'groups')!,
        trashed: mapValueOfType<int>(json, r'trashed')!,
        freedBytes: mapValueOfType<int>(json, r'freedBytes')!,
        background: mapValueOfType<bool>(json, r'background')!,
      );
    }
    return null;
  }

  static List<DuplicateResolveResult> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <DuplicateResolveResult>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DuplicateResolveResult.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DuplicateResolveResult> mapFromJson(dynamic json) {
    final map = <String, DuplicateResolveResult>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DuplicateResolveResult.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DuplicateResolveResult-objects as value to a dart map
  static Map<String, List<DuplicateResolveResult>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<DuplicateResolveResult>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DuplicateResolveResult.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'groups',
    'trashed',
    'freedBytes',
    'background',
  };
}

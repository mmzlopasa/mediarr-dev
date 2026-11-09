//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DuplicateResolve {
  /// Returns a new [DuplicateResolve] instance.
  DuplicateResolve({
    this.groups = const [],
    this.all,
    this.exactOnly,
    this.dryRun,
  });

  List<DuplicateChoice> groups;

  /// Every group, each by its proposal
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? all;

  /// With all: only groups of the same file or picture
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? exactOnly;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? dryRun;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DuplicateResolve &&
          _deepEquality.equals(other.groups, groups) &&
          other.all == all &&
          other.exactOnly == exactOnly &&
          other.dryRun == dryRun;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (groups.hashCode) +
      (all == null ? 0 : all!.hashCode) +
      (exactOnly == null ? 0 : exactOnly!.hashCode) +
      (dryRun == null ? 0 : dryRun!.hashCode);

  @override
  String toString() =>
      'DuplicateResolve[groups=$groups, all=$all, exactOnly=$exactOnly, dryRun=$dryRun]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'groups'] = this.groups;
    if (this.all != null) {
      json[r'all'] = this.all;
    } else {
      json[r'all'] = null;
    }
    if (this.exactOnly != null) {
      json[r'exactOnly'] = this.exactOnly;
    } else {
      json[r'exactOnly'] = null;
    }
    if (this.dryRun != null) {
      json[r'dryRun'] = this.dryRun;
    } else {
      json[r'dryRun'] = null;
    }
    return json;
  }

  /// Returns a new [DuplicateResolve] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DuplicateResolve? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "DuplicateResolve[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "DuplicateResolve[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return DuplicateResolve(
        groups: DuplicateChoice.listFromJson(json[r'groups']),
        all: mapValueOfType<bool>(json, r'all'),
        exactOnly: mapValueOfType<bool>(json, r'exactOnly'),
        dryRun: mapValueOfType<bool>(json, r'dryRun'),
      );
    }
    return null;
  }

  static List<DuplicateResolve> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <DuplicateResolve>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DuplicateResolve.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DuplicateResolve> mapFromJson(dynamic json) {
    final map = <String, DuplicateResolve>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DuplicateResolve.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DuplicateResolve-objects as value to a dart map
  static Map<String, List<DuplicateResolve>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<DuplicateResolve>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DuplicateResolve.listFromJson(
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

//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Duplicates {
  /// Returns a new [Duplicates] instance.
  Duplicates({
    required this.total,
    required this.pending,
    this.exactTotal,
    this.resolving,
    this.groups = const [],
  });

  /// All groups, of which at most the first 100 are listed
  int total;

  /// Photos not compared yet
  int pending;

  /// Groups of the same file or picture
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? exactTotal;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  ResolveProgress? resolving;

  List<DuplicateGroup> groups;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Duplicates &&
          other.total == total &&
          other.pending == pending &&
          other.exactTotal == exactTotal &&
          other.resolving == resolving &&
          _deepEquality.equals(other.groups, groups);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (total.hashCode) +
      (pending.hashCode) +
      (exactTotal == null ? 0 : exactTotal!.hashCode) +
      (resolving == null ? 0 : resolving!.hashCode) +
      (groups.hashCode);

  @override
  String toString() =>
      'Duplicates[total=$total, pending=$pending, exactTotal=$exactTotal, resolving=$resolving, groups=$groups]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'total'] = this.total;
    json[r'pending'] = this.pending;
    if (this.exactTotal != null) {
      json[r'exactTotal'] = this.exactTotal;
    } else {
      json[r'exactTotal'] = null;
    }
    if (this.resolving != null) {
      json[r'resolving'] = this.resolving;
    } else {
      json[r'resolving'] = null;
    }
    json[r'groups'] = this.groups;
    return json;
  }

  /// Returns a new [Duplicates] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Duplicates? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Duplicates[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Duplicates[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Duplicates(
        total: mapValueOfType<int>(json, r'total')!,
        pending: mapValueOfType<int>(json, r'pending')!,
        exactTotal: mapValueOfType<int>(json, r'exactTotal'),
        resolving: ResolveProgress.fromJson(json[r'resolving']),
        groups: DuplicateGroup.listFromJson(json[r'groups']),
      );
    }
    return null;
  }

  static List<Duplicates> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Duplicates>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Duplicates.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Duplicates> mapFromJson(dynamic json) {
    final map = <String, Duplicates>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Duplicates.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Duplicates-objects as value to a dart map
  static Map<String, List<Duplicates>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Duplicates>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Duplicates.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'total',
    'pending',
    'groups',
  };
}

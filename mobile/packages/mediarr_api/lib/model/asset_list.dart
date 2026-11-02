//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AssetList {
  /// Returns a new [AssetList] instance.
  AssetList({
    this.items = const [],
    required this.total,
    required this.processing,
    required this.failed,
  });

  List<Asset> items;

  int total;

  int processing;

  int failed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetList &&
          _deepEquality.equals(other.items, items) &&
          other.total == total &&
          other.processing == processing &&
          other.failed == failed;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (items.hashCode) +
      (total.hashCode) +
      (processing.hashCode) +
      (failed.hashCode);

  @override
  String toString() =>
      'AssetList[items=$items, total=$total, processing=$processing, failed=$failed]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'items'] = this.items;
    json[r'total'] = this.total;
    json[r'processing'] = this.processing;
    json[r'failed'] = this.failed;
    return json;
  }

  /// Returns a new [AssetList] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AssetList? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "AssetList[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "AssetList[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AssetList(
        items: Asset.listFromJson(json[r'items']),
        total: mapValueOfType<int>(json, r'total')!,
        processing: mapValueOfType<int>(json, r'processing')!,
        failed: mapValueOfType<int>(json, r'failed')!,
      );
    }
    return null;
  }

  static List<AssetList> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AssetList>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AssetList.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AssetList> mapFromJson(dynamic json) {
    final map = <String, AssetList>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AssetList.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AssetList-objects as value to a dart map
  static Map<String, List<AssetList>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<AssetList>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AssetList.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'items',
    'total',
    'processing',
    'failed',
  };
}

//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Activity {
  /// Returns a new [Activity] instance.
  Activity({
    this.comments = const [],
    required this.hearts,
    required this.hearted,
  });

  List<Comment> comments;

  int hearts;

  bool hearted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Activity &&
          _deepEquality.equals(other.comments, comments) &&
          other.hearts == hearts &&
          other.hearted == hearted;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (comments.hashCode) + (hearts.hashCode) + (hearted.hashCode);

  @override
  String toString() =>
      'Activity[comments=$comments, hearts=$hearts, hearted=$hearted]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'comments'] = this.comments;
    json[r'hearts'] = this.hearts;
    json[r'hearted'] = this.hearted;
    return json;
  }

  /// Returns a new [Activity] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Activity? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Activity[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Activity[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Activity(
        comments: Comment.listFromJson(json[r'comments']),
        hearts: mapValueOfType<int>(json, r'hearts')!,
        hearted: mapValueOfType<bool>(json, r'hearted')!,
      );
    }
    return null;
  }

  static List<Activity> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Activity>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Activity.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Activity> mapFromJson(dynamic json) {
    final map = <String, Activity>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Activity.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Activity-objects as value to a dart map
  static Map<String, List<Activity>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Activity>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Activity.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'comments',
    'hearts',
    'hearted',
  };
}

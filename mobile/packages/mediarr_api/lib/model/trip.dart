//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Trip {
  /// Returns a new [Trip] instance.
  Trip({
    required this.from,
    required this.to,
    required this.count,
    required this.coverId,
    required this.lat,
    required this.lon,
    this.places = const [],
  });

  /// Local date: 2006-01-02
  String from;

  /// Local date: 2006-01-02
  String to;

  int count;

  String coverId;

  double lat;

  double lon;

  List<String> places;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Trip &&
          other.from == from &&
          other.to == to &&
          other.count == count &&
          other.coverId == coverId &&
          other.lat == lat &&
          other.lon == lon &&
          _deepEquality.equals(other.places, places);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (from.hashCode) +
      (to.hashCode) +
      (count.hashCode) +
      (coverId.hashCode) +
      (lat.hashCode) +
      (lon.hashCode) +
      (places.hashCode);

  @override
  String toString() =>
      'Trip[from=$from, to=$to, count=$count, coverId=$coverId, lat=$lat, lon=$lon, places=$places]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'from'] = this.from;
    json[r'to'] = this.to;
    json[r'count'] = this.count;
    json[r'coverId'] = this.coverId;
    json[r'lat'] = this.lat;
    json[r'lon'] = this.lon;
    json[r'places'] = this.places;
    return json;
  }

  /// Returns a new [Trip] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Trip? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Trip[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Trip[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Trip(
        from: mapValueOfType<String>(json, r'from')!,
        to: mapValueOfType<String>(json, r'to')!,
        count: mapValueOfType<int>(json, r'count')!,
        coverId: mapValueOfType<String>(json, r'coverId')!,
        lat: mapValueOfType<double>(json, r'lat')!,
        lon: mapValueOfType<double>(json, r'lon')!,
        places: json[r'places'] is Iterable
            ? (json[r'places'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<Trip> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Trip>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Trip.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Trip> mapFromJson(dynamic json) {
    final map = <String, Trip>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Trip.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Trip-objects as value to a dart map
  static Map<String, List<Trip>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Trip>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Trip.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'from',
    'to',
    'count',
    'coverId',
    'lat',
    'lon',
    'places',
  };
}

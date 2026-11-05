//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AccountStats {
  /// Returns a new [AccountStats] instance.
  AccountStats({
    required this.photos,
    required this.videos,
    required this.favorites,
    required this.archived,
    required this.trashed,
    required this.albums,
    required this.bytes,
  });

  int photos;

  int videos;

  int favorites;

  int archived;

  int trashed;

  int albums;

  int bytes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountStats &&
          other.photos == photos &&
          other.videos == videos &&
          other.favorites == favorites &&
          other.archived == archived &&
          other.trashed == trashed &&
          other.albums == albums &&
          other.bytes == bytes;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (photos.hashCode) +
      (videos.hashCode) +
      (favorites.hashCode) +
      (archived.hashCode) +
      (trashed.hashCode) +
      (albums.hashCode) +
      (bytes.hashCode);

  @override
  String toString() =>
      'AccountStats[photos=$photos, videos=$videos, favorites=$favorites, archived=$archived, trashed=$trashed, albums=$albums, bytes=$bytes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'photos'] = this.photos;
    json[r'videos'] = this.videos;
    json[r'favorites'] = this.favorites;
    json[r'archived'] = this.archived;
    json[r'trashed'] = this.trashed;
    json[r'albums'] = this.albums;
    json[r'bytes'] = this.bytes;
    return json;
  }

  /// Returns a new [AccountStats] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AccountStats? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "AccountStats[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "AccountStats[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AccountStats(
        photos: mapValueOfType<int>(json, r'photos')!,
        videos: mapValueOfType<int>(json, r'videos')!,
        favorites: mapValueOfType<int>(json, r'favorites')!,
        archived: mapValueOfType<int>(json, r'archived')!,
        trashed: mapValueOfType<int>(json, r'trashed')!,
        albums: mapValueOfType<int>(json, r'albums')!,
        bytes: mapValueOfType<int>(json, r'bytes')!,
      );
    }
    return null;
  }

  static List<AccountStats> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AccountStats>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AccountStats.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AccountStats> mapFromJson(dynamic json) {
    final map = <String, AccountStats>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AccountStats.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AccountStats-objects as value to a dart map
  static Map<String, List<AccountStats>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<AccountStats>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AccountStats.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'photos',
    'videos',
    'favorites',
    'archived',
    'trashed',
    'albums',
    'bytes',
  };
}

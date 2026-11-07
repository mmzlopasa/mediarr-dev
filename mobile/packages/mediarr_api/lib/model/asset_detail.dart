//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AssetDetail {
  /// Returns a new [AssetDetail] instance.
  AssetDetail({
    this.isOwner,
    this.projection,
    this.downloadAllowed,
    this.edits,
    this.caption,
    this.rating,
    this.isEditing,
    this.description,
    this.isMissing,
    this.tags = const [],
    this.stack = const [],
    this.people = const [],
    this.city,
    this.state,
    this.country,
    required this.id,
    required this.originalName,
    required this.kind,
    required this.status,
    this.mimeType,
    required this.sizeBytes,
    this.width,
    this.height,
    required this.isFavorite,
    required this.isArchived,
    required this.localAt,
    this.offsetMinutes,
    this.hasCaptureTime,
    required this.createdAt,
    this.newerId,
    this.olderId,
    this.durationMs,
    this.videoCodec,
    this.hlsReady,
    this.liveVideoId,
    this.hasMotion,
    this.sprite,
    this.camera,
    this.lens,
    this.iso,
    this.fNumber,
    this.exposureTime,
    this.focalLength,
    this.latitude,
    this.longitude,
  });

  /// Only the owner can change or delete the asset
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? isOwner;

  /// equirectangular for a 360° panorama
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? projection;

  /// False on a public link that does not allow downloads
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? downloadAllowed;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  AssetEdits? edits;

  /// Written by the owner
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? caption;

  /// 1 to 5 stars, when it has any
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? rating;

  /// New previews are being made after an edit
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? isEditing;

  /// From the local model. Only for the owner
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? description;

  /// The file of an external library was not found on the last scan
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? isMissing;

  /// Only for the owner
  List<String> tags;

  /// All shots of its stack, the main one first. Only for the owner
  List<String> stack;

  /// Only for the owner
  List<PersonRef> people;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? city;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? state;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? country;

  String id;

  String originalName;

  AssetDetailKindEnum kind;

  AssetDetailStatusEnum status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? mimeType;

  int sizeBytes;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? width;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? height;

  bool isFavorite;

  bool isArchived;

  String localAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? offsetMinutes;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? hasCaptureTime;

  DateTime createdAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? newerId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? olderId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? durationMs;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? videoCodec;

  /// The adaptive stream at video/master.m3u8 can be played
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? hlsReady;

  /// The video of a Live Photo
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? liveVideoId;

  /// An Android Motion Photo, with its video at /motion
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? hasMotion;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Sprite? sprite;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? camera;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? lens;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? iso;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? fNumber;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? exposureTime;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? focalLength;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? latitude;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? longitude;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetDetail &&
          other.isOwner == isOwner &&
          other.projection == projection &&
          other.downloadAllowed == downloadAllowed &&
          other.edits == edits &&
          other.caption == caption &&
          other.rating == rating &&
          other.isEditing == isEditing &&
          other.description == description &&
          other.isMissing == isMissing &&
          _deepEquality.equals(other.tags, tags) &&
          _deepEquality.equals(other.stack, stack) &&
          _deepEquality.equals(other.people, people) &&
          other.city == city &&
          other.state == state &&
          other.country == country &&
          other.id == id &&
          other.originalName == originalName &&
          other.kind == kind &&
          other.status == status &&
          other.mimeType == mimeType &&
          other.sizeBytes == sizeBytes &&
          other.width == width &&
          other.height == height &&
          other.isFavorite == isFavorite &&
          other.isArchived == isArchived &&
          other.localAt == localAt &&
          other.offsetMinutes == offsetMinutes &&
          other.hasCaptureTime == hasCaptureTime &&
          other.createdAt == createdAt &&
          other.newerId == newerId &&
          other.olderId == olderId &&
          other.durationMs == durationMs &&
          other.videoCodec == videoCodec &&
          other.hlsReady == hlsReady &&
          other.liveVideoId == liveVideoId &&
          other.hasMotion == hasMotion &&
          other.sprite == sprite &&
          other.camera == camera &&
          other.lens == lens &&
          other.iso == iso &&
          other.fNumber == fNumber &&
          other.exposureTime == exposureTime &&
          other.focalLength == focalLength &&
          other.latitude == latitude &&
          other.longitude == longitude;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (isOwner == null ? 0 : isOwner!.hashCode) +
      (projection == null ? 0 : projection!.hashCode) +
      (downloadAllowed == null ? 0 : downloadAllowed!.hashCode) +
      (edits == null ? 0 : edits!.hashCode) +
      (caption == null ? 0 : caption!.hashCode) +
      (rating == null ? 0 : rating!.hashCode) +
      (isEditing == null ? 0 : isEditing!.hashCode) +
      (description == null ? 0 : description!.hashCode) +
      (isMissing == null ? 0 : isMissing!.hashCode) +
      (tags.hashCode) +
      (stack.hashCode) +
      (people.hashCode) +
      (city == null ? 0 : city!.hashCode) +
      (state == null ? 0 : state!.hashCode) +
      (country == null ? 0 : country!.hashCode) +
      (id.hashCode) +
      (originalName.hashCode) +
      (kind.hashCode) +
      (status.hashCode) +
      (mimeType == null ? 0 : mimeType!.hashCode) +
      (sizeBytes.hashCode) +
      (width == null ? 0 : width!.hashCode) +
      (height == null ? 0 : height!.hashCode) +
      (isFavorite.hashCode) +
      (isArchived.hashCode) +
      (localAt.hashCode) +
      (offsetMinutes == null ? 0 : offsetMinutes!.hashCode) +
      (hasCaptureTime == null ? 0 : hasCaptureTime!.hashCode) +
      (createdAt.hashCode) +
      (newerId == null ? 0 : newerId!.hashCode) +
      (olderId == null ? 0 : olderId!.hashCode) +
      (durationMs == null ? 0 : durationMs!.hashCode) +
      (videoCodec == null ? 0 : videoCodec!.hashCode) +
      (hlsReady == null ? 0 : hlsReady!.hashCode) +
      (liveVideoId == null ? 0 : liveVideoId!.hashCode) +
      (hasMotion == null ? 0 : hasMotion!.hashCode) +
      (sprite == null ? 0 : sprite!.hashCode) +
      (camera == null ? 0 : camera!.hashCode) +
      (lens == null ? 0 : lens!.hashCode) +
      (iso == null ? 0 : iso!.hashCode) +
      (fNumber == null ? 0 : fNumber!.hashCode) +
      (exposureTime == null ? 0 : exposureTime!.hashCode) +
      (focalLength == null ? 0 : focalLength!.hashCode) +
      (latitude == null ? 0 : latitude!.hashCode) +
      (longitude == null ? 0 : longitude!.hashCode);

  @override
  String toString() =>
      'AssetDetail[isOwner=$isOwner, projection=$projection, downloadAllowed=$downloadAllowed, edits=$edits, caption=$caption, rating=$rating, isEditing=$isEditing, description=$description, isMissing=$isMissing, tags=$tags, stack=$stack, people=$people, city=$city, state=$state, country=$country, id=$id, originalName=$originalName, kind=$kind, status=$status, mimeType=$mimeType, sizeBytes=$sizeBytes, width=$width, height=$height, isFavorite=$isFavorite, isArchived=$isArchived, localAt=$localAt, offsetMinutes=$offsetMinutes, hasCaptureTime=$hasCaptureTime, createdAt=$createdAt, newerId=$newerId, olderId=$olderId, durationMs=$durationMs, videoCodec=$videoCodec, hlsReady=$hlsReady, liveVideoId=$liveVideoId, hasMotion=$hasMotion, sprite=$sprite, camera=$camera, lens=$lens, iso=$iso, fNumber=$fNumber, exposureTime=$exposureTime, focalLength=$focalLength, latitude=$latitude, longitude=$longitude]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.isOwner != null) {
      json[r'isOwner'] = this.isOwner;
    } else {
      json[r'isOwner'] = null;
    }
    if (this.projection != null) {
      json[r'projection'] = this.projection;
    } else {
      json[r'projection'] = null;
    }
    if (this.downloadAllowed != null) {
      json[r'downloadAllowed'] = this.downloadAllowed;
    } else {
      json[r'downloadAllowed'] = null;
    }
    if (this.edits != null) {
      json[r'edits'] = this.edits;
    } else {
      json[r'edits'] = null;
    }
    if (this.caption != null) {
      json[r'caption'] = this.caption;
    } else {
      json[r'caption'] = null;
    }
    if (this.rating != null) {
      json[r'rating'] = this.rating;
    } else {
      json[r'rating'] = null;
    }
    if (this.isEditing != null) {
      json[r'isEditing'] = this.isEditing;
    } else {
      json[r'isEditing'] = null;
    }
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
    if (this.isMissing != null) {
      json[r'isMissing'] = this.isMissing;
    } else {
      json[r'isMissing'] = null;
    }
    json[r'tags'] = this.tags;
    json[r'stack'] = this.stack;
    json[r'people'] = this.people;
    if (this.city != null) {
      json[r'city'] = this.city;
    } else {
      json[r'city'] = null;
    }
    if (this.state != null) {
      json[r'state'] = this.state;
    } else {
      json[r'state'] = null;
    }
    if (this.country != null) {
      json[r'country'] = this.country;
    } else {
      json[r'country'] = null;
    }
    json[r'id'] = this.id;
    json[r'originalName'] = this.originalName;
    json[r'kind'] = this.kind;
    json[r'status'] = this.status;
    if (this.mimeType != null) {
      json[r'mimeType'] = this.mimeType;
    } else {
      json[r'mimeType'] = null;
    }
    json[r'sizeBytes'] = this.sizeBytes;
    if (this.width != null) {
      json[r'width'] = this.width;
    } else {
      json[r'width'] = null;
    }
    if (this.height != null) {
      json[r'height'] = this.height;
    } else {
      json[r'height'] = null;
    }
    json[r'isFavorite'] = this.isFavorite;
    json[r'isArchived'] = this.isArchived;
    json[r'localAt'] = this.localAt;
    if (this.offsetMinutes != null) {
      json[r'offsetMinutes'] = this.offsetMinutes;
    } else {
      json[r'offsetMinutes'] = null;
    }
    if (this.hasCaptureTime != null) {
      json[r'hasCaptureTime'] = this.hasCaptureTime;
    } else {
      json[r'hasCaptureTime'] = null;
    }
    json[r'createdAt'] = this.createdAt.toUtc().toIso8601String();
    if (this.newerId != null) {
      json[r'newerId'] = this.newerId;
    } else {
      json[r'newerId'] = null;
    }
    if (this.olderId != null) {
      json[r'olderId'] = this.olderId;
    } else {
      json[r'olderId'] = null;
    }
    if (this.durationMs != null) {
      json[r'durationMs'] = this.durationMs;
    } else {
      json[r'durationMs'] = null;
    }
    if (this.videoCodec != null) {
      json[r'videoCodec'] = this.videoCodec;
    } else {
      json[r'videoCodec'] = null;
    }
    if (this.hlsReady != null) {
      json[r'hlsReady'] = this.hlsReady;
    } else {
      json[r'hlsReady'] = null;
    }
    if (this.liveVideoId != null) {
      json[r'liveVideoId'] = this.liveVideoId;
    } else {
      json[r'liveVideoId'] = null;
    }
    if (this.hasMotion != null) {
      json[r'hasMotion'] = this.hasMotion;
    } else {
      json[r'hasMotion'] = null;
    }
    if (this.sprite != null) {
      json[r'sprite'] = this.sprite;
    } else {
      json[r'sprite'] = null;
    }
    if (this.camera != null) {
      json[r'camera'] = this.camera;
    } else {
      json[r'camera'] = null;
    }
    if (this.lens != null) {
      json[r'lens'] = this.lens;
    } else {
      json[r'lens'] = null;
    }
    if (this.iso != null) {
      json[r'iso'] = this.iso;
    } else {
      json[r'iso'] = null;
    }
    if (this.fNumber != null) {
      json[r'fNumber'] = this.fNumber;
    } else {
      json[r'fNumber'] = null;
    }
    if (this.exposureTime != null) {
      json[r'exposureTime'] = this.exposureTime;
    } else {
      json[r'exposureTime'] = null;
    }
    if (this.focalLength != null) {
      json[r'focalLength'] = this.focalLength;
    } else {
      json[r'focalLength'] = null;
    }
    if (this.latitude != null) {
      json[r'latitude'] = this.latitude;
    } else {
      json[r'latitude'] = null;
    }
    if (this.longitude != null) {
      json[r'longitude'] = this.longitude;
    } else {
      json[r'longitude'] = null;
    }
    return json;
  }

  /// Returns a new [AssetDetail] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AssetDetail? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "AssetDetail[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "AssetDetail[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AssetDetail(
        isOwner: mapValueOfType<bool>(json, r'isOwner'),
        projection: mapValueOfType<String>(json, r'projection'),
        downloadAllowed: mapValueOfType<bool>(json, r'downloadAllowed'),
        edits: AssetEdits.fromJson(json[r'edits']),
        caption: mapValueOfType<String>(json, r'caption'),
        rating: mapValueOfType<int>(json, r'rating'),
        isEditing: mapValueOfType<bool>(json, r'isEditing'),
        description: mapValueOfType<String>(json, r'description'),
        isMissing: mapValueOfType<bool>(json, r'isMissing'),
        tags: json[r'tags'] is Iterable
            ? (json[r'tags'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        stack: json[r'stack'] is Iterable
            ? (json[r'stack'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        people: PersonRef.listFromJson(json[r'people']),
        city: mapValueOfType<String>(json, r'city'),
        state: mapValueOfType<String>(json, r'state'),
        country: mapValueOfType<String>(json, r'country'),
        id: mapValueOfType<String>(json, r'id')!,
        originalName: mapValueOfType<String>(json, r'originalName')!,
        kind: AssetDetailKindEnum.fromJson(json[r'kind'])!,
        status: AssetDetailStatusEnum.fromJson(json[r'status'])!,
        mimeType: mapValueOfType<String>(json, r'mimeType'),
        sizeBytes: mapValueOfType<int>(json, r'sizeBytes')!,
        width: mapValueOfType<int>(json, r'width'),
        height: mapValueOfType<int>(json, r'height'),
        isFavorite: mapValueOfType<bool>(json, r'isFavorite')!,
        isArchived: mapValueOfType<bool>(json, r'isArchived')!,
        localAt: mapValueOfType<String>(json, r'localAt')!,
        offsetMinutes: mapValueOfType<int>(json, r'offsetMinutes'),
        hasCaptureTime: mapValueOfType<bool>(json, r'hasCaptureTime'),
        createdAt: mapDateTime(json, r'createdAt', r'')!,
        newerId: mapValueOfType<String>(json, r'newerId'),
        olderId: mapValueOfType<String>(json, r'olderId'),
        durationMs: mapValueOfType<int>(json, r'durationMs'),
        videoCodec: mapValueOfType<String>(json, r'videoCodec'),
        hlsReady: mapValueOfType<bool>(json, r'hlsReady'),
        liveVideoId: mapValueOfType<String>(json, r'liveVideoId'),
        hasMotion: mapValueOfType<bool>(json, r'hasMotion'),
        sprite: Sprite.fromJson(json[r'sprite']),
        camera: mapValueOfType<String>(json, r'camera'),
        lens: mapValueOfType<String>(json, r'lens'),
        iso: mapValueOfType<int>(json, r'iso'),
        fNumber: mapValueOfType<double>(json, r'fNumber'),
        exposureTime: mapValueOfType<String>(json, r'exposureTime'),
        focalLength: mapValueOfType<double>(json, r'focalLength'),
        latitude: mapValueOfType<double>(json, r'latitude'),
        longitude: mapValueOfType<double>(json, r'longitude'),
      );
    }
    return null;
  }

  static List<AssetDetail> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AssetDetail>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AssetDetail.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AssetDetail> mapFromJson(dynamic json) {
    final map = <String, AssetDetail>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AssetDetail.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AssetDetail-objects as value to a dart map
  static Map<String, List<AssetDetail>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<AssetDetail>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AssetDetail.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'originalName',
    'kind',
    'status',
    'sizeBytes',
    'isFavorite',
    'isArchived',
    'localAt',
    'createdAt',
  };
}

class AssetDetailKindEnum {
  /// Instantiate a new enum with the provided [value].
  const AssetDetailKindEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const unknown = AssetDetailKindEnum._(r'unknown');
  static const photo = AssetDetailKindEnum._(r'photo');
  static const video = AssetDetailKindEnum._(r'video');

  /// List of all possible values in this [enum][AssetDetailKindEnum].
  static const values = <AssetDetailKindEnum>[
    unknown,
    photo,
    video,
  ];

  static AssetDetailKindEnum? fromJson(dynamic value) =>
      AssetDetailKindEnumTypeTransformer().decode(value);

  static List<AssetDetailKindEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AssetDetailKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AssetDetailKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AssetDetailKindEnum] to String,
/// and [decode] dynamic data back to [AssetDetailKindEnum].
class AssetDetailKindEnumTypeTransformer {
  factory AssetDetailKindEnumTypeTransformer() =>
      _instance ??= const AssetDetailKindEnumTypeTransformer._();

  const AssetDetailKindEnumTypeTransformer._();

  String encode(AssetDetailKindEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a AssetDetailKindEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AssetDetailKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'unknown':
          return AssetDetailKindEnum.unknown;
        case r'photo':
          return AssetDetailKindEnum.photo;
        case r'video':
          return AssetDetailKindEnum.video;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [AssetDetailKindEnumTypeTransformer] instance.
  static AssetDetailKindEnumTypeTransformer? _instance;
}

class AssetDetailStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const AssetDetailStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const processing = AssetDetailStatusEnum._(r'processing');
  static const ready = AssetDetailStatusEnum._(r'ready');
  static const failed = AssetDetailStatusEnum._(r'failed');

  /// List of all possible values in this [enum][AssetDetailStatusEnum].
  static const values = <AssetDetailStatusEnum>[
    processing,
    ready,
    failed,
  ];

  static AssetDetailStatusEnum? fromJson(dynamic value) =>
      AssetDetailStatusEnumTypeTransformer().decode(value);

  static List<AssetDetailStatusEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AssetDetailStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AssetDetailStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AssetDetailStatusEnum] to String,
/// and [decode] dynamic data back to [AssetDetailStatusEnum].
class AssetDetailStatusEnumTypeTransformer {
  factory AssetDetailStatusEnumTypeTransformer() =>
      _instance ??= const AssetDetailStatusEnumTypeTransformer._();

  const AssetDetailStatusEnumTypeTransformer._();

  String encode(AssetDetailStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a AssetDetailStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AssetDetailStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'processing':
          return AssetDetailStatusEnum.processing;
        case r'ready':
          return AssetDetailStatusEnum.ready;
        case r'failed':
          return AssetDetailStatusEnum.failed;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [AssetDetailStatusEnumTypeTransformer] instance.
  static AssetDetailStatusEnumTypeTransformer? _instance;
}

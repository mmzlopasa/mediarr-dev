//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ApiClient {
  ApiClient({
    this.basePath = 'http://localhost',
    this.authentication,
  });

  final String basePath;
  final Authentication? authentication;

  var _client = Client();
  final _defaultHeaderMap = <String, String>{};

  /// Returns the current HTTP [Client] instance to use in this class.
  ///
  /// The return value is guaranteed to never be null.
  Client get client => _client;

  /// Requests to use a new HTTP [Client] in this class.
  set client(Client newClient) {
    _client = newClient;
  }

  Map<String, String> get defaultHeaderMap => _defaultHeaderMap;

  void addDefaultHeader(String key, String value) {
    _defaultHeaderMap[key] = value;
  }

  // We don't use a Map<String, String> for queryParams.
  // If collectionFormat is 'multi', a key might appear multiple times.
  Future<Response> invokeAPI(
    String path,
    String method,
    List<QueryParam> queryParams,
    Object? body,
    Map<String, String> headerParams,
    Map<String, String> formParams,
    String? contentType,
  ) async {
    await authentication?.applyToParams(queryParams, headerParams);

    headerParams.addAll(_defaultHeaderMap);
    if (contentType != null) {
      headerParams['Content-Type'] = contentType;
    }

    final urlEncodedQueryParams = queryParams.map((param) => '$param');
    final queryString = urlEncodedQueryParams.isNotEmpty
        ? '?${urlEncodedQueryParams.join('&')}'
        : '';
    final uri = Uri.parse('$basePath$path$queryString');

    try {
      // Special case for uploading a single file which isn't a 'multipart/form-data'.
      if (body is MultipartFile &&
          (contentType == null ||
              !contentType.toLowerCase().startsWith('multipart/form-data'))) {
        final request = StreamedRequest(method, uri);
        request.headers.addAll(headerParams);
        request.contentLength = body.length;
        body.finalize().listen(
              request.sink.add,
              onDone: request.sink.close,
              // ignore: avoid_types_on_closure_parameters
              onError: (Object error, StackTrace trace) => request.sink.close(),
              cancelOnError: true,
            );
        final response = await _client.send(request);
        return Response.fromStream(response);
      }

      if (body is MultipartRequest) {
        final request = MultipartRequest(method, uri);
        request.fields.addAll(body.fields);
        request.files.addAll(body.files);
        request.headers.addAll(body.headers);
        request.headers.addAll(headerParams);
        final response = await _client.send(request);
        return Response.fromStream(response);
      }

      final msgBody = contentType == 'application/x-www-form-urlencoded'
          ? formParams
          : await serializeAsync(body);
      final nullableHeaderParams = headerParams.isEmpty ? null : headerParams;

      switch (method) {
        case 'POST':
          return await _client.post(
            uri,
            headers: nullableHeaderParams,
            body: msgBody,
          );
        case 'PUT':
          return await _client.put(
            uri,
            headers: nullableHeaderParams,
            body: msgBody,
          );
        case 'DELETE':
          return await _client.delete(
            uri,
            headers: nullableHeaderParams,
            body: msgBody,
          );
        case 'PATCH':
          return await _client.patch(
            uri,
            headers: nullableHeaderParams,
            body: msgBody,
          );
        case 'HEAD':
          return await _client.head(
            uri,
            headers: nullableHeaderParams,
          );
        case 'GET':
          return await _client.get(
            uri,
            headers: nullableHeaderParams,
          );
      }
    } on SocketException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'Socket operation failed: $method $path',
        error,
        trace,
      );
    } on TlsException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'TLS/SSL communication failed: $method $path',
        error,
        trace,
      );
    } on IOException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'I/O operation failed: $method $path',
        error,
        trace,
      );
    } on ClientException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'HTTP connection failed: $method $path',
        error,
        trace,
      );
    } on Exception catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'Exception occurred: $method $path',
        error,
        trace,
      );
    }

    throw ApiException(
      HttpStatus.badRequest,
      'Invalid HTTP operation: $method $path',
    );
  }

  Future<dynamic> deserializeAsync(
    String value,
    String targetType, {
    bool growable = false,
  }) async =>
      // ignore: deprecated_member_use_from_same_package
      deserialize(value, targetType, growable: growable);

  @Deprecated(
      'Scheduled for removal in OpenAPI Generator 6.x. Use deserializeAsync() instead.')
  dynamic deserialize(
    String value,
    String targetType, {
    bool growable = false,
  }) {
    // Remove all spaces. Necessary for regular expressions as well.
    targetType =
        targetType.replaceAll(' ', ''); // ignore: parameter_assignments

    // If the expected target type is String, nothing to do...
    return targetType == 'String'
        ? value
        : fromJson(json.decode(value), targetType, growable: growable);
  }

  // ignore: deprecated_member_use_from_same_package
  Future<String> serializeAsync(Object? value) async => serialize(value);

  @Deprecated(
      'Scheduled for removal in OpenAPI Generator 6.x. Use serializeAsync() instead.')
  String serialize(Object? value) => value == null ? '' : json.encode(value);

  /// Returns a native instance of an OpenAPI class matching the [specified type][targetType].
  static dynamic fromJson(
    dynamic value,
    String targetType, {
    bool growable = false,
  }) {
    try {
      switch (targetType) {
        case 'String':
          return value is String ? value : value.toString();
        case 'int':
          return value is int ? value : int.parse('$value');
        case 'double':
          return value is double ? value : double.parse('$value');
        case 'bool':
          if (value is bool) {
            return value;
          }
          final valueString = '$value'.toLowerCase();
          return valueString == 'true' || valueString == '1';
        case 'DateTime':
          return value is DateTime ? value : DateTime.tryParse(value);
        case 'Activity':
          return Activity.fromJson(value);
        case 'AdminHealth':
          return AdminHealth.fromJson(value);
        case 'AdminJobs':
          return AdminJobs.fromJson(value);
        case 'AdminOverview':
          return AdminOverview.fromJson(value);
        case 'AdminOverviewJobs':
          return AdminOverviewJobs.fromJson(value);
        case 'Album':
          return Album.fromJson(value);
        case 'AlbumCreate':
          return AlbumCreate.fromJson(value);
        case 'AlbumMember':
          return AlbumMember.fromJson(value);
        case 'AlbumRules':
          return AlbumRules.fromJson(value);
        case 'AlbumUpdate':
          return AlbumUpdate.fromJson(value);
        case 'AnalysisProgress':
          return AnalysisProgress.fromJson(value);
        case 'ApiKey':
          return ApiKey.fromJson(value);
        case 'ApiKeyCreate':
          return ApiKeyCreate.fromJson(value);
        case 'Asset':
          return Asset.fromJson(value);
        case 'AssetDetail':
          return AssetDetail.fromJson(value);
        case 'AssetEdits':
          return AssetEdits.fromJson(value);
        case 'AssetIds':
          return AssetIds.fromJson(value);
        case 'AssetList':
          return AssetList.fromJson(value);
        case 'AssetTagChange':
          return AssetTagChange.fromJson(value);
        case 'AuditEntry':
          return AuditEntry.fromJson(value);
        case 'AuthMethods':
          return AuthMethods.fromJson(value);
        case 'AuthStatus':
          return AuthStatus.fromJson(value);
        case 'BackupRun':
          return BackupRun.fromJson(value);
        case 'BackupRunRequest':
          return BackupRunRequest.fromJson(value);
        case 'BackupSettings':
          return BackupSettings.fromJson(value);
        case 'BackupSettingsUpdate':
          return BackupSettingsUpdate.fromJson(value);
        case 'BulkRequest':
          return BulkRequest.fromJson(value);
        case 'BulkResponse':
          return BulkResponse.fromJson(value);
        case 'ChangePasswordRequest':
          return ChangePasswordRequest.fromJson(value);
        case 'ChecksumCheckRequest':
          return ChecksumCheckRequest.fromJson(value);
        case 'ChecksumCheckResponse':
          return ChecksumCheckResponse.fromJson(value);
        case 'Comment':
          return Comment.fromJson(value);
        case 'CommentCreate':
          return CommentCreate.fromJson(value);
        case 'CreateDeviceKeyRequest':
          return CreateDeviceKeyRequest.fromJson(value);
        case 'CreateUserRequest':
          return CreateUserRequest.fromJson(value);
        case 'CropBox':
          return CropBox.fromJson(value);
        case 'DeviceKey':
          return DeviceKey.fromJson(value);
        case 'Documents':
          return Documents.fromJson(value);
        case 'DuplicateGroup':
          return DuplicateGroup.fromJson(value);
        case 'DuplicateItem':
          return DuplicateItem.fromJson(value);
        case 'Duplicates':
          return Duplicates.fromJson(value);
        case 'Error':
          return Error.fromJson(value);
        case 'ExternalLibrary':
          return ExternalLibrary.fromJson(value);
        case 'ExternalLibraryOwner':
          return ExternalLibraryOwner.fromJson(value);
        case 'FailedJob':
          return FailedJob.fromJson(value);
        case 'FeatureUpdate':
          return FeatureUpdate.fromJson(value);
        case 'Folder':
          return Folder.fromJson(value);
        case 'FolderEntry':
          return FolderEntry.fromJson(value);
        case 'Health':
          return Health.fromJson(value);
        case 'ImportCreate':
          return ImportCreate.fromJson(value);
        case 'ImportEntry':
          return ImportEntry.fromJson(value);
        case 'JobQueue':
          return JobQueue.fromJson(value);
        case 'LinkPassword':
          return LinkPassword.fromJson(value);
        case 'LoginError':
          return LoginError.fromJson(value);
        case 'LoginRequest':
          return LoginRequest.fromJson(value);
        case 'MapPoints':
          return MapPoints.fromJson(value);
        case 'MapStyle':
          return MapStyle.fromJson(value);
        case 'MemberRole':
          return MemberRole.fromJson(value);
        case 'Memory':
          return Memory.fromJson(value);
        case 'OIDCExchange':
          return OIDCExchange.fromJson(value);
        case 'OIDCSettings':
          return OIDCSettings.fromJson(value);
        case 'OIDCSettingsUpdate':
          return OIDCSettingsUpdate.fromJson(value);
        case 'PartnerEntry':
          return PartnerEntry.fromJson(value);
        case 'PartnerShare':
          return PartnerShare.fromJson(value);
        case 'PartnerTimeline':
          return PartnerTimeline.fromJson(value);
        case 'Partners':
          return Partners.fromJson(value);
        case 'Passkey':
          return Passkey.fromJson(value);
        case 'PasswordConfirm':
          return PasswordConfirm.fromJson(value);
        case 'PeopleList':
          return PeopleList.fromJson(value);
        case 'Person':
          return Person.fromJson(value);
        case 'PersonRef':
          return PersonRef.fromJson(value);
        case 'PersonUpdate':
          return PersonUpdate.fromJson(value);
        case 'PublicLink':
          return PublicLink.fromJson(value);
        case 'QuotaUpdate':
          return QuotaUpdate.fromJson(value);
        case 'SearchFilters':
          return SearchFilters.fromJson(value);
        case 'SearchResult':
          return SearchResult.fromJson(value);
        case 'SetupRequest':
          return SetupRequest.fromJson(value);
        case 'ShareLink':
          return ShareLink.fromJson(value);
        case 'ShareLinkCreate':
          return ShareLinkCreate.fromJson(value);
        case 'Sprite':
          return Sprite.fromJson(value);
        case 'StoryExport':
          return StoryExport.fromJson(value);
        case 'StoryRequest':
          return StoryRequest.fromJson(value);
        case 'Tag':
          return Tag.fromJson(value);
        case 'TimelineBucket':
          return TimelineBucket.fromJson(value);
        case 'TimelineBuckets':
          return TimelineBuckets.fromJson(value);
        case 'TimelineBucketsBucketsInner':
          return TimelineBucketsBucketsInner.fromJson(value);
        case 'TimelineItem':
          return TimelineItem.fromJson(value);
        case 'TotpCode':
          return TotpCode.fromJson(value);
        case 'TotpSetup':
          return TotpSetup.fromJson(value);
        case 'TrashSummary':
          return TrashSummary.fromJson(value);
        case 'Trip':
          return Trip.fromJson(value);
        case 'User':
          return User.fromJson(value);
        case 'UserRef':
          return UserRef.fromJson(value);
        case 'UserStorage':
          return UserStorage.fromJson(value);
        case 'VaultPinChange':
          return VaultPinChange.fromJson(value);
        case 'VaultSession':
          return VaultSession.fromJson(value);
        case 'VaultStatus':
          return VaultStatus.fromJson(value);
        case 'VaultUnlock':
          return VaultUnlock.fromJson(value);
        case 'Webhook':
          return Webhook.fromJson(value);
        case 'WebhookCreate':
          return WebhookCreate.fromJson(value);
        case 'WebhookCreated':
          return WebhookCreated.fromJson(value);
        default:
          dynamic match;
          if (value is List &&
              (match = _regList.firstMatch(targetType)?.group(1)) != null) {
            return value
                .map<dynamic>((dynamic v) => fromJson(
                      v,
                      match,
                      growable: growable,
                    ))
                .toList(growable: growable);
          }
          if (value is Set &&
              (match = _regSet.firstMatch(targetType)?.group(1)) != null) {
            return value
                .map<dynamic>((dynamic v) => fromJson(
                      v,
                      match,
                      growable: growable,
                    ))
                .toSet();
          }
          if (value is Map &&
              (match = _regMap.firstMatch(targetType)?.group(1)) != null) {
            return Map<String, dynamic>.fromIterables(
              value.keys.cast<String>(),
              value.values.map<dynamic>((dynamic v) => fromJson(
                    v,
                    match,
                    growable: growable,
                  )),
            );
          }
      }
    } on Exception catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.internalServerError,
        'Exception during deserialization.',
        error,
        trace,
      );
    }
    throw ApiException(
      HttpStatus.internalServerError,
      'Could not find a suitable class for deserialization',
    );
  }
}

/// Primarily intended for use in an isolate.
class DeserializationMessage {
  const DeserializationMessage({
    required this.json,
    required this.targetType,
    this.growable = false,
  });

  /// The JSON value to deserialize.
  final String json;

  /// Target type to deserialize to.
  final String targetType;

  /// Whether to make deserialized lists or maps growable.
  final bool growable;
}

/// Primarily intended for use in an isolate.
Future<dynamic> decodeAsync(DeserializationMessage message) async {
  // Remove all spaces. Necessary for regular expressions as well.
  final targetType = message.targetType.replaceAll(' ', '');

  // If the expected target type is String, nothing to do...
  return targetType == 'String' ? message.json : json.decode(message.json);
}

/// Primarily intended for use in an isolate.
Future<dynamic> deserializeAsync(DeserializationMessage message) async {
  // Remove all spaces. Necessary for regular expressions as well.
  final targetType = message.targetType.replaceAll(' ', '');

  // If the expected target type is String, nothing to do...
  return targetType == 'String'
      ? message.json
      : ApiClient.fromJson(
          json.decode(message.json),
          targetType,
          growable: message.growable,
        );
}

/// Primarily intended for use in an isolate.
Future<String> serializeAsync(Object? value) async =>
    value == null ? '' : json.encode(value);

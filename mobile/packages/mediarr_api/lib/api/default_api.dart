//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DefaultApi {
  DefaultApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Add your own assets to an album. Needs the contributor role.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [AssetIds] assetIds (required):
  Future<Response> addAlbumAssetsWithHttpInfo(
    String id,
    AssetIds assetIds,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/albums/{id}/assets'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = assetIds;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Add your own assets to an album. Needs the contributor role.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [AssetIds] assetIds (required):
  Future<BulkResponse?> addAlbumAssets(
    String id,
    AssetIds assetIds,
  ) async {
    final response = await addAlbumAssetsWithHttpInfo(
      id,
      assetIds,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'BulkResponse',
      ) as BulkResponse;
    }
    return null;
  }

  /// Add someone to the family library
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] userId (required):
  Future<Response> addFamilyMemberWithHttpInfo(
    String userId,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/family/{userId}'.replaceAll('{userId}', userId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Add someone to the family library
  ///
  /// Parameters:
  ///
  /// * [String] userId (required):
  Future<void> addFamilyMember(
    String userId,
  ) async {
    final response = await addFamilyMemberWithHttpInfo(
      userId,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Append data to an upload (tus 1.0). The last chunk returns X-Asset-Id.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> appendUploadWithHttpInfo(
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/uploads/{id}'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Append data to an upload (tus 1.0). The last chunk returns X-Asset-Id.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> appendUpload(
    String id,
  ) async {
    final response = await appendUploadWithHttpInfo(
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Turn a question into words to search for, with the local model
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [AskRequest] askRequest (required):
  Future<Response> askSearchWithHttpInfo(
    AskRequest askRequest,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/search/ask';

    // ignore: prefer_final_locals
    Object? postBody = askRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Turn a question into words to search for, with the local model
  ///
  /// Parameters:
  ///
  /// * [AskRequest] askRequest (required):
  Future<AskAnswer?> askSearch(
    AskRequest askRequest,
  ) async {
    final response = await askSearchWithHttpInfo(
      askRequest,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'AskAnswer',
      ) as AskAnswer;
    }
    return null;
  }

  /// Start signing in with a passkey
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [Map<String, Object>] requestBody:
  Future<Response> beginPasskeyLoginWithHttpInfo({
    Map<String, Object>? requestBody,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/auth/passkey/begin';

    // ignore: prefer_final_locals
    Object? postBody = requestBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Start signing in with a passkey
  ///
  /// Parameters:
  ///
  /// * [Map<String, Object>] requestBody:
  Future<Map<String, Object>?> beginPasskeyLogin({
    Map<String, Object>? requestBody,
  }) async {
    final response = await beginPasskeyLoginWithHttpInfo(
      requestBody: requestBody,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return Map<String, Object>.from(
        await apiClient.deserializeAsync(
            await _decodeBodyBytes(response), 'Map<String, Object>'),
      );
    }
    return null;
  }

  /// Start adding a passkey
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [Map<String, Object>] requestBody:
  Future<Response> beginPasskeyRegistrationWithHttpInfo({
    Map<String, Object>? requestBody,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/me/passkeys/begin';

    // ignore: prefer_final_locals
    Object? postBody = requestBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Start adding a passkey
  ///
  /// Parameters:
  ///
  /// * [Map<String, Object>] requestBody:
  Future<Map<String, Object>?> beginPasskeyRegistration({
    Map<String, Object>? requestBody,
  }) async {
    final response = await beginPasskeyRegistrationWithHttpInfo(
      requestBody: requestBody,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return Map<String, Object>.from(
        await apiClient.deserializeAsync(
            await _decodeBodyBytes(response), 'Map<String, Object>'),
      );
    }
    return null;
  }

  /// Apply an action to several of the current user's assets. Other assets are ignored.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [BulkRequest] bulkRequest (required):
  Future<Response> bulkAssetsWithHttpInfo(
    BulkRequest bulkRequest,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/assets/bulk';

    // ignore: prefer_final_locals
    Object? postBody = bulkRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Apply an action to several of the current user's assets. Other assets are ignored.
  ///
  /// Parameters:
  ///
  /// * [BulkRequest] bulkRequest (required):
  Future<BulkResponse?> bulkAssets(
    BulkRequest bulkRequest,
  ) async {
    final response = await bulkAssetsWithHttpInfo(
      bulkRequest,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'BulkResponse',
      ) as BulkResponse;
    }
    return null;
  }

  /// Stop an import. What it has brought in stays
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> cancelImportWithHttpInfo(
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/imports/{id}/cancel'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Stop an import. What it has brought in stays
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> cancelImport(
    String id,
  ) async {
    final response = await cancelImportWithHttpInfo(
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Cancel an upload (tus 1.0)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> cancelUploadWithHttpInfo(
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/uploads/{id}'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Cancel an upload (tus 1.0)
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> cancelUpload(
    String id,
  ) async {
    final response = await cancelUploadWithHttpInfo(
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Add a tag to the user's own assets, or remove it
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [AssetTagChange] assetTagChange (required):
  Future<Response> changeAssetTagsWithHttpInfo(
    AssetTagChange assetTagChange,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/assets/tags';

    // ignore: prefer_final_locals
    Object? postBody = assetTagChange;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Add a tag to the user's own assets, or remove it
  ///
  /// Parameters:
  ///
  /// * [AssetTagChange] assetTagChange (required):
  Future<BulkResponse?> changeAssetTags(
    AssetTagChange assetTagChange,
  ) async {
    final response = await changeAssetTagsWithHttpInfo(
      assetTagChange,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'BulkResponse',
      ) as BulkResponse;
    }
    return null;
  }

  /// Change the current user's password and end their other sessions
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [ChangePasswordRequest] changePasswordRequest (required):
  Future<Response> changePasswordWithHttpInfo(
    ChangePasswordRequest changePasswordRequest,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/me/password';

    // ignore: prefer_final_locals
    Object? postBody = changePasswordRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Change the current user's password and end their other sessions
  ///
  /// Parameters:
  ///
  /// * [ChangePasswordRequest] changePasswordRequest (required):
  Future<void> changePassword(
    ChangePasswordRequest changePasswordRequest,
  ) async {
    final response = await changePasswordWithHttpInfo(
      changePasswordRequest,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Report which SHA-256 checksums the current user already has, so uploads can be skipped
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [ChecksumCheckRequest] checksumCheckRequest (required):
  Future<Response> checkAssetsWithHttpInfo(
    ChecksumCheckRequest checksumCheckRequest,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/assets/check';

    // ignore: prefer_final_locals
    Object? postBody = checksumCheckRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Report which SHA-256 checksums the current user already has, so uploads can be skipped
  ///
  /// Parameters:
  ///
  /// * [ChecksumCheckRequest] checksumCheckRequest (required):
  Future<ChecksumCheckResponse?> checkAssets(
    ChecksumCheckRequest checksumCheckRequest,
  ) async {
    final response = await checkAssetsWithHttpInfo(
      checksumCheckRequest,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'ChecksumCheckResponse',
      ) as ChecksumCheckResponse;
    }
    return null;
  }

  /// Go back to the photo as it was taken
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> clearAssetEditsWithHttpInfo(
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/assets/{id}/edits'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Go back to the photo as it was taken
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> clearAssetEdits(
    String id,
  ) async {
    final response = await clearAssetEditsWithHttpInfo(
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Create a key with chosen rights. It is shown only once
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [ApiKeyCreate] apiKeyCreate (required):
  Future<Response> createAPIKeyWithHttpInfo(
    ApiKeyCreate apiKeyCreate,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/me/api-keys';

    // ignore: prefer_final_locals
    Object? postBody = apiKeyCreate;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Create a key with chosen rights. It is shown only once
  ///
  /// Parameters:
  ///
  /// * [ApiKeyCreate] apiKeyCreate (required):
  Future<DeviceKey?> createAPIKey(
    ApiKeyCreate apiKeyCreate,
  ) async {
    final response = await createAPIKeyWithHttpInfo(
      apiKeyCreate,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'DeviceKey',
      ) as DeviceKey;
    }
    return null;
  }

  /// Create an album. With rules it is a smart album.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [AlbumCreate] albumCreate (required):
  Future<Response> createAlbumWithHttpInfo(
    AlbumCreate albumCreate,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/albums';

    // ignore: prefer_final_locals
    Object? postBody = albumCreate;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Create an album. With rules it is a smart album.
  ///
  /// Parameters:
  ///
  /// * [AlbumCreate] albumCreate (required):
  Future<Album?> createAlbum(
    AlbumCreate albumCreate,
  ) async {
    final response = await createAlbumWithHttpInfo(
      albumCreate,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'Album',
      ) as Album;
    }
    return null;
  }

  /// Comment on an album or on a photo in it
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [CommentCreate] commentCreate (required):
  Future<Response> createAlbumCommentWithHttpInfo(
    String id,
    CommentCreate commentCreate,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/albums/{id}/comments'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = commentCreate;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Comment on an album or on a photo in it
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [CommentCreate] commentCreate (required):
  Future<void> createAlbumComment(
    String id,
    CommentCreate commentCreate,
  ) async {
    final response = await createAlbumCommentWithHttpInfo(
      id,
      commentCreate,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Create a public link. Its token is returned only this once.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [ShareLinkCreate] shareLinkCreate (required):
  Future<Response> createAlbumLinkWithHttpInfo(
    String id,
    ShareLinkCreate shareLinkCreate,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/albums/{id}/links'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = shareLinkCreate;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Create a public link. Its token is returned only this once.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [ShareLinkCreate] shareLinkCreate (required):
  Future<ShareLink?> createAlbumLink(
    String id,
    ShareLinkCreate shareLinkCreate,
  ) async {
    final response = await createAlbumLinkWithHttpInfo(
      id,
      shareLinkCreate,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'ShareLink',
      ) as ShareLink;
    }
    return null;
  }

  /// Create a long-lived key for this device, used by background backup
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CreateDeviceKeyRequest] createDeviceKeyRequest (required):
  Future<Response> createDeviceKeyWithHttpInfo(
    CreateDeviceKeyRequest createDeviceKeyRequest,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/me/device-keys';

    // ignore: prefer_final_locals
    Object? postBody = createDeviceKeyRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Create a long-lived key for this device, used by background backup
  ///
  /// Parameters:
  ///
  /// * [CreateDeviceKeyRequest] createDeviceKeyRequest (required):
  Future<DeviceKey?> createDeviceKey(
    CreateDeviceKeyRequest createDeviceKeyRequest,
  ) async {
    final response = await createDeviceKeyWithHttpInfo(
      createDeviceKeyRequest,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'DeviceKey',
      ) as DeviceKey;
    }
    return null;
  }

  /// Share what matches a rule with the family. Photos are not copied
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [FamilyRuleCreate] familyRuleCreate (required):
  Future<Response> createFamilyRuleWithHttpInfo(
    FamilyRuleCreate familyRuleCreate,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/family/rules';

    // ignore: prefer_final_locals
    Object? postBody = familyRuleCreate;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Share what matches a rule with the family. Photos are not copied
  ///
  /// Parameters:
  ///
  /// * [FamilyRuleCreate] familyRuleCreate (required):
  Future<Map<String, String>?> createFamilyRule(
    FamilyRuleCreate familyRuleCreate,
  ) async {
    final response = await createFamilyRuleWithHttpInfo(
      familyRuleCreate,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return Map<String, String>.from(
        await apiClient.deserializeAsync(
            await _decodeBodyBytes(response), 'Map<String, String>'),
      );
    }
    return null;
  }

  /// Bring a library in from Immich, Google Takeout or an iCloud export
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [ImportCreate] importCreate (required):
  Future<Response> createImportWithHttpInfo(
    ImportCreate importCreate,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/imports';

    // ignore: prefer_final_locals
    Object? postBody = importCreate;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Bring a library in from Immich, Google Takeout or an iCloud export
  ///
  /// Parameters:
  ///
  /// * [ImportCreate] importCreate (required):
  Future<Map<String, String>?> createImport(
    ImportCreate importCreate,
  ) async {
    final response = await createImportWithHttpInfo(
      importCreate,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return Map<String, String>.from(
        await apiClient.deserializeAsync(
            await _decodeBodyBytes(response), 'Map<String, String>'),
      );
    }
    return null;
  }

  /// Send one whole file to a public album (tus 1.0 creation with upload)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  Future<Response> createPublicUploadWithHttpInfo(
    String token,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/public/{token}/uploads'.replaceAll('{token}', token);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Send one whole file to a public album (tus 1.0 creation with upload)
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  Future<void> createPublicUpload(
    String token,
  ) async {
    final response = await createPublicUploadWithHttpInfo(
      token,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Make a video of the chosen photos. Runs in the background.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [StoryRequest] storyRequest (required):
  Future<Response> createStoryExportWithHttpInfo(
    StoryRequest storyRequest,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/stories';

    // ignore: prefer_final_locals
    Object? postBody = storyRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Make a video of the chosen photos. Runs in the background.
  ///
  /// Parameters:
  ///
  /// * [StoryRequest] storyRequest (required):
  Future<StoryExport?> createStoryExport(
    StoryRequest storyRequest,
  ) async {
    final response = await createStoryExportWithHttpInfo(
      storyRequest,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'StoryExport',
      ) as StoryExport;
    }
    return null;
  }

  /// Create a resumable upload (tus 1.0). A body uploads the whole file in this request.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> createUploadWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/uploads';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Create a resumable upload (tus 1.0). A body uploads the whole file in this request.
  Future<void> createUpload() async {
    final response = await createUploadWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Create a user
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CreateUserRequest] createUserRequest (required):
  Future<Response> createUserWithHttpInfo(
    CreateUserRequest createUserRequest,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/users';

    // ignore: prefer_final_locals
    Object? postBody = createUserRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Create a user
  ///
  /// Parameters:
  ///
  /// * [CreateUserRequest] createUserRequest (required):
  Future<User?> createUser(
    CreateUserRequest createUserRequest,
  ) async {
    final response = await createUserWithHttpInfo(
      createUserRequest,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'User',
      ) as User;
    }
    return null;
  }

  /// Add an address. Its signing secret is shown only once
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [WebhookCreate] webhookCreate (required):
  Future<Response> createWebhookWithHttpInfo(
    WebhookCreate webhookCreate,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/webhooks';

    // ignore: prefer_final_locals
    Object? postBody = webhookCreate;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Add an address. Its signing secret is shown only once
  ///
  /// Parameters:
  ///
  /// * [WebhookCreate] webhookCreate (required):
  Future<WebhookCreated?> createWebhook(
    WebhookCreate webhookCreate,
  ) async {
    final response = await createWebhookWithHttpInfo(
      webhookCreate,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'WebhookCreated',
      ) as WebhookCreated;
    }
    return null;
  }

  /// Delete an album, but not its photos. Owner only.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> deleteAlbumWithHttpInfo(
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/albums/{id}'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Delete an album, but not its photos. Owner only.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> deleteAlbum(
    String id,
  ) async {
    final response = await deleteAlbumWithHttpInfo(
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Delete a comment. The author, an editor or the owner can do this.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] commentId (required):
  Future<Response> deleteAlbumCommentWithHttpInfo(
    String id,
    String commentId,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/albums/{id}/comments/{commentId}'
        .replaceAll('{id}', id)
        .replaceAll('{commentId}', commentId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Delete a comment. The author, an editor or the owner can do this.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] commentId (required):
  Future<void> deleteAlbumComment(
    String id,
    String commentId,
  ) async {
    final response = await deleteAlbumCommentWithHttpInfo(
      id,
      commentId,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Revoke a public link. It stops working at once.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] linkId (required):
  Future<Response> deleteAlbumLinkWithHttpInfo(
    String id,
    String linkId,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/albums/{id}/links/{linkId}'
        .replaceAll('{id}', id)
        .replaceAll('{linkId}', linkId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Revoke a public link. It stops working at once.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] linkId (required):
  Future<void> deleteAlbumLink(
    String id,
    String linkId,
  ) async {
    final response = await deleteAlbumLinkWithHttpInfo(
      id,
      linkId,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Stop sharing what this rule covers
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> deleteFamilyRuleWithHttpInfo(
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/family/rules/{id}'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Stop sharing what this rule covers
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> deleteFamilyRule(
    String id,
  ) async {
    final response = await deleteFamilyRuleWithHttpInfo(
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Remove a passkey
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> deletePasskeyWithHttpInfo(
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/me/passkeys/{id}'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Remove a passkey
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> deletePasskey(
    String id,
  ) async {
    final response = await deletePasskeyWithHttpInfo(
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Delete a tag. The photos stay.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> deleteTagWithHttpInfo(
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/tags/{id}'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Delete a tag. The photos stay.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> deleteTag(
    String id,
  ) async {
    final response = await deleteTagWithHttpInfo(
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Stop telling this address
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> deleteWebhookWithHttpInfo(
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/webhooks/{id}'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Stop telling this address
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> deleteWebhook(
    String id,
  ) async {
    final response = await deleteWebhookWithHttpInfo(
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Turn off TOTP
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [PasswordConfirm] passwordConfirm (required):
  Future<Response> disableTotpWithHttpInfo(
    PasswordConfirm passwordConfirm,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/me/totp/disable';

    // ignore: prefer_final_locals
    Object? postBody = passwordConfirm;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Turn off TOTP
  ///
  /// Parameters:
  ///
  /// * [PasswordConfirm] passwordConfirm (required):
  Future<void> disableTotp(
    PasswordConfirm passwordConfirm,
  ) async {
    final response = await disableTotpWithHttpInfo(
      passwordConfirm,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// These photos are not duplicates of each other, and are not proposed again
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [AssetIds] assetIds (required):
  Future<Response> dismissDuplicatesWithHttpInfo(
    AssetIds assetIds,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/duplicates/dismiss';

    // ignore: prefer_final_locals
    Object? postBody = assetIds;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// These photos are not duplicates of each other, and are not proposed again
  ///
  /// Parameters:
  ///
  /// * [AssetIds] assetIds (required):
  Future<void> dismissDuplicates(
    AssetIds assetIds,
  ) async {
    final response = await dismissDuplicatesWithHttpInfo(
      assetIds,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Split a stack back into single shots. It is not put together again by itself
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> dissolveStackWithHttpInfo(
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/assets/{id}/stack'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Split a stack back into single shots. It is not put together again by itself
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> dissolveStack(
    String id,
  ) async {
    final response = await dissolveStackWithHttpInfo(
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Download several originals as one uncompressed ZIP file
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] ids (required):
  ///   Comma-separated asset IDs, at most 100
  Future<Response> downloadAssetsWithHttpInfo(
    String ids,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/assets/download';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    queryParams.addAll(_queryParams('', 'ids', ids));

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Download several originals as one uncompressed ZIP file
  ///
  /// Parameters:
  ///
  /// * [String] ids (required):
  ///   Comma-separated asset IDs, at most 100
  Future<MultipartFile?> downloadAssets(
    String ids,
  ) async {
    final response = await downloadAssetsWithHttpInfo(
      ids,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'MultipartFile',
      ) as MultipartFile;
    }
    return null;
  }

  /// Permanently delete everything in the trash
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> emptyTrashWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/trash/empty';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Permanently delete everything in the trash
  Future<BulkResponse?> emptyTrash() async {
    final response = await emptyTrashWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'BulkResponse',
      ) as BulkResponse;
    }
    return null;
  }

  /// Confirm a code and turn on TOTP
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [TotpCode] totpCode (required):
  Future<Response> enableTotpWithHttpInfo(
    TotpCode totpCode,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/me/totp/enable';

    // ignore: prefer_final_locals
    Object? postBody = totpCode;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Confirm a code and turn on TOTP
  ///
  /// Parameters:
  ///
  /// * [TotpCode] totpCode (required):
  Future<void> enableTotp(
    TotpCode totpCode,
  ) async {
    final response = await enableTotpWithHttpInfo(
      totpCode,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// The app turns a one-time code into a session
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [OIDCExchange] oIDCExchange (required):
  Future<Response> exchangeOIDCWithHttpInfo(
    OIDCExchange oIDCExchange,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/auth/oidc/exchange';

    // ignore: prefer_final_locals
    Object? postBody = oIDCExchange;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// The app turns a one-time code into a session
  ///
  /// Parameters:
  ///
  /// * [OIDCExchange] oIDCExchange (required):
  Future<User?> exchangeOIDC(
    OIDCExchange oIDCExchange,
  ) async {
    final response = await exchangeOIDCWithHttpInfo(
      oIDCExchange,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'User',
      ) as User;
    }
    return null;
  }

  /// Where the identity provider sends the browser back
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] code:
  ///
  /// * [String] state:
  Future<Response> finishOIDCWithHttpInfo({
    String? code,
    String? state,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/auth/oidc/callback';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (code != null) {
      queryParams.addAll(_queryParams('', 'code', code));
    }
    if (state != null) {
      queryParams.addAll(_queryParams('', 'state', state));
    }

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Where the identity provider sends the browser back
  ///
  /// Parameters:
  ///
  /// * [String] code:
  ///
  /// * [String] state:
  Future<void> finishOIDC({
    String? code,
    String? state,
  }) async {
    final response = await finishOIDCWithHttpInfo(
      code: code,
      state: state,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Finish signing in with a passkey
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [Map<String, Object>] requestBody:
  Future<Response> finishPasskeyLoginWithHttpInfo({
    Map<String, Object>? requestBody,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/auth/passkey/finish';

    // ignore: prefer_final_locals
    Object? postBody = requestBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Finish signing in with a passkey
  ///
  /// Parameters:
  ///
  /// * [Map<String, Object>] requestBody:
  Future<Map<String, Object>?> finishPasskeyLogin({
    Map<String, Object>? requestBody,
  }) async {
    final response = await finishPasskeyLoginWithHttpInfo(
      requestBody: requestBody,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return Map<String, Object>.from(
        await apiClient.deserializeAsync(
            await _decodeBodyBytes(response), 'Map<String, Object>'),
      );
    }
    return null;
  }

  /// Finish adding a passkey
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [Map<String, Object>] requestBody:
  Future<Response> finishPasskeyRegistrationWithHttpInfo({
    Map<String, Object>? requestBody,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/me/passkeys/finish';

    // ignore: prefer_final_locals
    Object? postBody = requestBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Finish adding a passkey
  ///
  /// Parameters:
  ///
  /// * [Map<String, Object>] requestBody:
  Future<Map<String, Object>?> finishPasskeyRegistration({
    Map<String, Object>? requestBody,
  }) async {
    final response = await finishPasskeyRegistrationWithHttpInfo(
      requestBody: requestBody,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return Map<String, Object>.from(
        await apiClient.deserializeAsync(
            await _decodeBodyBytes(response), 'Map<String, Object>'),
      );
    }
    return null;
  }

  /// The local Ollama server and how far descriptions have come
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getAISettingsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/ai';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// The local Ollama server and how far descriptions have come
  Future<AISettings?> getAISettings() async {
    final response = await getAISettingsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'AISettings',
      ) as AISettings;
    }
    return null;
  }

  /// Whether the worker and the analysis service are running
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getAdminHealthWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/health';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Whether the worker and the analysis service are running
  Future<AdminHealth?> getAdminHealth() async {
    final response = await getAdminHealthWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'AdminHealth',
      ) as AdminHealth;
    }
    return null;
  }

  /// The job queues, and the jobs that gave up
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getAdminJobsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/jobs';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// The job queues, and the jobs that gave up
  Future<AdminJobs?> getAdminJobs() async {
    final response = await getAdminJobsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'AdminJobs',
      ) as AdminJobs;
    }
    return null;
  }

  /// Live statistics of the whole server, read from the database and the library disk
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getAdminOverviewWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/overview';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Live statistics of the whole server, read from the database and the library disk
  Future<AdminOverview?> getAdminOverview() async {
    final response = await getAdminOverviewWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'AdminOverview',
      ) as AdminOverview;
    }
    return null;
  }

  /// How much each user stores
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getAdminStorageWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/storage';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// How much each user stores
  Future<List<UserStorage>?> getAdminStorage() async {
    final response = await getAdminStorageWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(
              responseBody, 'List<UserStorage>') as List)
          .cast<UserStorage>()
          .toList(growable: false);
    }
    return null;
  }

  /// Read an album and its members
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> getAlbumWithHttpInfo(
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/albums/{id}'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Read an album and its members
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Album?> getAlbum(
    String id,
  ) async {
    final response = await getAlbumWithHttpInfo(
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'Album',
      ) as Album;
    }
    return null;
  }

  /// Assets of one month in an album
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] month (required):
  Future<Response> getAlbumBucketWithHttpInfo(
    String id,
    String month,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/albums/{id}/buckets/{month}'
        .replaceAll('{id}', id)
        .replaceAll('{month}', month);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Assets of one month in an album
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] month (required):
  Future<TimelineBucket?> getAlbumBucket(
    String id,
    String month,
  ) async {
    final response = await getAlbumBucketWithHttpInfo(
      id,
      month,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'TimelineBucket',
      ) as TimelineBucket;
    }
    return null;
  }

  /// Months in an album, in the album's order
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> getAlbumBucketsWithHttpInfo(
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/albums/{id}/buckets'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Months in an album, in the album's order
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<TimelineBuckets?> getAlbumBuckets(
    String id,
  ) async {
    final response = await getAlbumBucketsWithHttpInfo(
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'TimelineBuckets',
      ) as TimelineBuckets;
    }
    return null;
  }

  /// How far picture analysis has come. Administrators only.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getAnalysisProgressWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/analysis';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// How far picture analysis has come. Administrators only.
  Future<AnalysisProgress?> getAnalysisProgress() async {
    final response = await getAnalysisProgressWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'AnalysisProgress',
      ) as AnalysisProgress;
    }
    return null;
  }

  /// Read an asset's details and its neighbours on the timeline
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> getAssetWithHttpInfo(
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/assets/{id}'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Read an asset's details and its neighbours on the timeline
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<AssetDetail?> getAsset(
    String id,
  ) async {
    final response = await getAssetWithHttpInfo(
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'AssetDetail',
      ) as AssetDetail;
    }
    return null;
  }

  /// Read the video embedded in an Android Motion Photo
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> getAssetMotionWithHttpInfo(
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/assets/{id}/motion'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Read the video embedded in an Android Motion Photo
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<MultipartFile?> getAssetMotion(
    String id,
  ) async {
    final response = await getAssetMotionWithHttpInfo(
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'MultipartFile',
      ) as MultipartFile;
    }
    return null;
  }

  /// Read the unmodified original. Supports Range requests for video.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [bool] download:
  Future<Response> getAssetOriginalWithHttpInfo(
    String id, {
    bool? download,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/assets/{id}/original'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (download != null) {
      queryParams.addAll(_queryParams('', 'download', download));
    }

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Read the unmodified original. Supports Range requests for video.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [bool] download:
  Future<MultipartFile?> getAssetOriginal(
    String id, {
    bool? download,
  }) async {
    final response = await getAssetOriginalWithHttpInfo(
      id,
      download: download,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'MultipartFile',
      ) as MultipartFile;
    }
    return null;
  }

  /// Read a WebP thumbnail
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] size:
  ///   source is the unedited picture, for its owner
  Future<Response> getAssetThumbnailWithHttpInfo(
    String id, {
    String? size,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/assets/{id}/thumbnail'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (size != null) {
      queryParams.addAll(_queryParams('', 'size', size));
    }

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Read a WebP thumbnail
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] size:
  ///   source is the unedited picture, for its owner
  Future<MultipartFile?> getAssetThumbnail(
    String id, {
    String? size,
  }) async {
    final response = await getAssetThumbnailWithHttpInfo(
      id,
      size: size,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'MultipartFile',
      ) as MultipartFile;
    }
    return null;
  }

  /// Read an HLS playlist or segment, or the scrub strip (sprite.jpg)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] file (required):
  Future<Response> getAssetVideoFileWithHttpInfo(
    String id,
    String file,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/assets/{id}/video/{file}'
        .replaceAll('{id}', id)
        .replaceAll('{file}', file);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Read an HLS playlist or segment, or the scrub strip (sprite.jpg)
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] file (required):
  Future<MultipartFile?> getAssetVideoFile(
    String id,
    String file,
  ) async {
    final response = await getAssetVideoFileWithHttpInfo(
      id,
      file,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'MultipartFile',
      ) as MultipartFile;
    }
    return null;
  }

  /// The ways of signing in that this address offers, besides a password
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getAuthMethodsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/auth/methods';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// The ways of signing in that this address offers, besides a password
  Future<AuthMethods?> getAuthMethods() async {
    final response = await getAuthMethodsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'AuthMethods',
      ) as AuthMethods;
    }
    return null;
  }

  /// Report whether setup is needed and who is signed in
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getAuthStatusWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/auth/status';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Report whether setup is needed and who is signed in
  Future<AuthStatus?> getAuthStatus() async {
    final response = await getAuthStatusWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'AuthStatus',
      ) as AuthStatus;
    }
    return null;
  }

  /// Where backups go, without any secret
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getBackupSettingsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/backup';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Where backups go, without any secret
  Future<BackupSettings?> getBackupSettings() async {
    final response = await getBackupSettingsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'BackupSettings',
      ) as BackupSettings;
    }
    return null;
  }

  /// An asset in a collection
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] scope (required):
  ///
  /// * [String] id (required):
  Future<Response> getCollectionAssetWithHttpInfo(
    String scope,
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/collections/{scope}/assets/{id}'
        .replaceAll('{scope}', scope)
        .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// An asset in a collection
  ///
  /// Parameters:
  ///
  /// * [String] scope (required):
  ///
  /// * [String] id (required):
  Future<AssetDetail?> getCollectionAsset(
    String scope,
    String id,
  ) async {
    final response = await getCollectionAssetWithHttpInfo(
      scope,
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'AssetDetail',
      ) as AssetDetail;
    }
    return null;
  }

  /// Assets of one month in a collection
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] scope (required):
  ///
  /// * [String] month (required):
  Future<Response> getCollectionBucketWithHttpInfo(
    String scope,
    String month,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/collections/{scope}/buckets/{month}'
        .replaceAll('{scope}', scope)
        .replaceAll('{month}', month);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Assets of one month in a collection
  ///
  /// Parameters:
  ///
  /// * [String] scope (required):
  ///
  /// * [String] month (required):
  Future<TimelineBucket?> getCollectionBucket(
    String scope,
    String month,
  ) async {
    final response = await getCollectionBucketWithHttpInfo(
      scope,
      month,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'TimelineBucket',
      ) as TimelineBucket;
    }
    return null;
  }

  /// Months in the archive, the trash or the unlocked vault
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] scope (required):
  Future<Response> getCollectionBucketsWithHttpInfo(
    String scope,
  ) async {
    // ignore: prefer_const_declarations
    final path =
        r'/api/collections/{scope}/buckets'.replaceAll('{scope}', scope);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Months in the archive, the trash or the unlocked vault
  ///
  /// Parameters:
  ///
  /// * [String] scope (required):
  Future<TimelineBuckets?> getCollectionBuckets(
    String scope,
  ) async {
    final response = await getCollectionBucketsWithHttpInfo(
      scope,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'TimelineBuckets',
      ) as TimelineBuckets;
    }
    return null;
  }

  /// The video inside a Motion Photo in a collection
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] scope (required):
  ///
  /// * [String] id (required):
  Future<Response> getCollectionMotionWithHttpInfo(
    String scope,
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/collections/{scope}/assets/{id}/motion'
        .replaceAll('{scope}', scope)
        .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// The video inside a Motion Photo in a collection
  ///
  /// Parameters:
  ///
  /// * [String] scope (required):
  ///
  /// * [String] id (required):
  Future<MultipartFile?> getCollectionMotion(
    String scope,
    String id,
  ) async {
    final response = await getCollectionMotionWithHttpInfo(
      scope,
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'MultipartFile',
      ) as MultipartFile;
    }
    return null;
  }

  /// The original of an asset in a collection
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] scope (required):
  ///
  /// * [String] id (required):
  ///
  /// * [bool] download:
  Future<Response> getCollectionOriginalWithHttpInfo(
    String scope,
    String id, {
    bool? download,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/collections/{scope}/assets/{id}/original'
        .replaceAll('{scope}', scope)
        .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (download != null) {
      queryParams.addAll(_queryParams('', 'download', download));
    }

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// The original of an asset in a collection
  ///
  /// Parameters:
  ///
  /// * [String] scope (required):
  ///
  /// * [String] id (required):
  ///
  /// * [bool] download:
  Future<MultipartFile?> getCollectionOriginal(
    String scope,
    String id, {
    bool? download,
  }) async {
    final response = await getCollectionOriginalWithHttpInfo(
      scope,
      id,
      download: download,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'MultipartFile',
      ) as MultipartFile;
    }
    return null;
  }

  /// A preview of an asset in a collection
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] scope (required):
  ///
  /// * [String] id (required):
  ///
  /// * [String] size:
  Future<Response> getCollectionThumbnailWithHttpInfo(
    String scope,
    String id, {
    String? size,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/collections/{scope}/assets/{id}/thumbnail'
        .replaceAll('{scope}', scope)
        .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (size != null) {
      queryParams.addAll(_queryParams('', 'size', size));
    }

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// A preview of an asset in a collection
  ///
  /// Parameters:
  ///
  /// * [String] scope (required):
  ///
  /// * [String] id (required):
  ///
  /// * [String] size:
  Future<MultipartFile?> getCollectionThumbnail(
    String scope,
    String id, {
    String? size,
  }) async {
    final response = await getCollectionThumbnailWithHttpInfo(
      scope,
      id,
      size: size,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'MultipartFile',
      ) as MultipartFile;
    }
    return null;
  }

  /// HLS files of a video in a collection
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] scope (required):
  ///
  /// * [String] id (required):
  ///
  /// * [String] file (required):
  Future<Response> getCollectionVideoFileWithHttpInfo(
    String scope,
    String id,
    String file,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/collections/{scope}/assets/{id}/video/{file}'
        .replaceAll('{scope}', scope)
        .replaceAll('{id}', id)
        .replaceAll('{file}', file);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// HLS files of a video in a collection
  ///
  /// Parameters:
  ///
  /// * [String] scope (required):
  ///
  /// * [String] id (required):
  ///
  /// * [String] file (required):
  Future<MultipartFile?> getCollectionVideoFile(
    String scope,
    String id,
    String file,
  ) async {
    final response = await getCollectionVideoFileWithHttpInfo(
      scope,
      id,
      file,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'MultipartFile',
      ) as MultipartFile;
    }
    return null;
  }

  /// Photos of documents, found by the text on them
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getDocumentsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/documents';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Photos of documents, found by the text on them
  Future<Documents?> getDocuments() async {
    final response = await getDocumentsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'Documents',
      ) as Documents;
    }
    return null;
  }

  /// The folder given as EXTERNAL_LIBRARY_PATH, and how it is doing
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getExternalLibraryWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/external';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// The folder given as EXTERNAL_LIBRARY_PATH, and how it is doing
  Future<ExternalLibrary?> getExternalLibrary() async {
    final response = await getExternalLibraryWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'ExternalLibrary',
      ) as ExternalLibrary;
    }
    return null;
  }

  /// The family library, and what this user shares with it
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getFamilyWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/family';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// The family library, and what this user shares with it
  Future<Family?> getFamily() async {
    final response = await getFamilyWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'Family',
      ) as Family;
    }
    return null;
  }

  /// Assets of one month in the family library
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] month (required):
  Future<Response> getFamilyBucketWithHttpInfo(
    String month,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/family/buckets/{month}'.replaceAll('{month}', month);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Assets of one month in the family library
  ///
  /// Parameters:
  ///
  /// * [String] month (required):
  Future<TimelineBucket?> getFamilyBucket(
    String month,
  ) async {
    final response = await getFamilyBucketWithHttpInfo(
      month,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'TimelineBucket',
      ) as TimelineBucket;
    }
    return null;
  }

  /// Months in the family library
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getFamilyBucketsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/family/buckets';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Months in the family library
  Future<TimelineBuckets?> getFamilyBuckets() async {
    final response = await getFamilyBucketsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'TimelineBuckets',
      ) as TimelineBuckets;
    }
    return null;
  }

  /// Which additions the administrator has turned on
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getFeaturesWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/features';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Which additions the administrator has turned on
  Future<Map<String, bool>?> getFeatures() async {
    final response = await getFeaturesWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return Map<String, bool>.from(
        await apiClient.deserializeAsync(
            await _decodeBodyBytes(response), 'Map<String, bool>'),
      );
    }
    return null;
  }

  /// One folder of the external library, for the user who owns it
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] path:
  ///   Relative to the library. Empty is its top
  Future<Response> getFolderWithHttpInfo({
    String? path,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/folders';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (path != null) {
      queryParams.addAll(_queryParams('', 'path', path));
    }

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// One folder of the external library, for the user who owns it
  ///
  /// Parameters:
  ///
  /// * [String] path:
  ///   Relative to the library. Empty is its top
  Future<Folder?> getFolder({
    String? path,
  }) async {
    final response = await getFolderWithHttpInfo(
      path: path,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'Folder',
      ) as Folder;
    }
    return null;
  }

  /// Report whether the server can reach its database
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getHealthWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/health';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Report whether the server can reach its database
  Future<Health?> getHealth() async {
    final response = await getHealthWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'Health',
      ) as Health;
    }
    return null;
  }

  /// Photos with a location that this user may see, oldest first
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [DateTime] from:
  ///
  /// * [DateTime] to:
  Future<Response> getMapPointsWithHttpInfo({
    DateTime? from,
    DateTime? to,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/map/points';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (from != null) {
      queryParams.addAll(_queryParams('', 'from', from));
    }
    if (to != null) {
      queryParams.addAll(_queryParams('', 'to', to));
    }

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Photos with a location that this user may see, oldest first
  ///
  /// Parameters:
  ///
  /// * [DateTime] from:
  ///
  /// * [DateTime] to:
  Future<MapPoints?> getMapPoints({
    DateTime? from,
    DateTime? to,
  }) async {
    final response = await getMapPointsWithHttpInfo(
      from: from,
      to: to,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'MapPoints',
      ) as MapPoints;
    }
    return null;
  }

  /// Where the map's background comes from
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getMapStyleWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/map/style';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Where the map's background comes from
  Future<MapStyle?> getMapStyle() async {
    final response = await getMapStyleWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'MapStyle',
      ) as MapStyle;
    }
    return null;
  }

  /// Journeys found from the time and distance between photos
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getMapTripsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/map/trips';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Journeys found from the time and distance between photos
  Future<List<Trip>?> getMapTrips() async {
    final response = await getMapTripsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Trip>')
              as List)
          .cast<Trip>()
          .toList(growable: false);
    }
    return null;
  }

  /// Single sign-on settings, without the secret
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getOIDCSettingsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/oidc';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Single sign-on settings, without the secret
  Future<OIDCSettings?> getOIDCSettings() async {
    final response = await getOIDCSettingsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'OIDCSettings',
      ) as OIDCSettings;
    }
    return null;
  }

  /// Assets of one month in a library shared with you
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] userId (required):
  ///
  /// * [String] month (required):
  Future<Response> getPartnerBucketWithHttpInfo(
    String userId,
    String month,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/partners/{userId}/buckets/{month}'
        .replaceAll('{userId}', userId)
        .replaceAll('{month}', month);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Assets of one month in a library shared with you
  ///
  /// Parameters:
  ///
  /// * [String] userId (required):
  ///
  /// * [String] month (required):
  Future<TimelineBucket?> getPartnerBucket(
    String userId,
    String month,
  ) async {
    final response = await getPartnerBucketWithHttpInfo(
      userId,
      month,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'TimelineBucket',
      ) as TimelineBucket;
    }
    return null;
  }

  /// Months in a library shared with you
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] userId (required):
  Future<Response> getPartnerBucketsWithHttpInfo(
    String userId,
  ) async {
    // ignore: prefer_const_declarations
    final path =
        r'/api/partners/{userId}/buckets'.replaceAll('{userId}', userId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Months in a library shared with you
  ///
  /// Parameters:
  ///
  /// * [String] userId (required):
  Future<TimelineBuckets?> getPartnerBuckets(
    String userId,
  ) async {
    final response = await getPartnerBucketsWithHttpInfo(
      userId,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'TimelineBuckets',
      ) as TimelineBuckets;
    }
    return null;
  }

  /// Photos of this person in one month
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] month (required):
  Future<Response> getPersonBucketWithHttpInfo(
    String id,
    String month,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/people/{id}/buckets/{month}'
        .replaceAll('{id}', id)
        .replaceAll('{month}', month);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Photos of this person in one month
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] month (required):
  Future<TimelineBucket?> getPersonBucket(
    String id,
    String month,
  ) async {
    final response = await getPersonBucketWithHttpInfo(
      id,
      month,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'TimelineBucket',
      ) as TimelineBucket;
    }
    return null;
  }

  /// Months with this person
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> getPersonBucketsWithHttpInfo(
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/people/{id}/buckets'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Months with this person
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<TimelineBuckets?> getPersonBuckets(
    String id,
  ) async {
    final response = await getPersonBucketsWithHttpInfo(
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'TimelineBuckets',
      ) as TimelineBuckets;
    }
    return null;
  }

  /// A picture of this person's face
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> getPersonThumbnailWithHttpInfo(
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/people/{id}/thumbnail'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// A picture of this person's face
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<MultipartFile?> getPersonThumbnail(
    String id,
  ) async {
    final response = await getPersonThumbnailWithHttpInfo(
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'MultipartFile',
      ) as MultipartFile;
    }
    return null;
  }

  /// An asset in a public album, without what the link does not allow
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  ///
  /// * [String] id (required):
  Future<Response> getPublicAssetWithHttpInfo(
    String token,
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/public/{token}/assets/{id}'
        .replaceAll('{token}', token)
        .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// An asset in a public album, without what the link does not allow
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  ///
  /// * [String] id (required):
  Future<AssetDetail?> getPublicAsset(
    String token,
    String id,
  ) async {
    final response = await getPublicAssetWithHttpInfo(
      token,
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'AssetDetail',
      ) as AssetDetail;
    }
    return null;
  }

  /// Assets of one month in a public album
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  ///
  /// * [String] month (required):
  Future<Response> getPublicBucketWithHttpInfo(
    String token,
    String month,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/public/{token}/buckets/{month}'
        .replaceAll('{token}', token)
        .replaceAll('{month}', month);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Assets of one month in a public album
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  ///
  /// * [String] month (required):
  Future<TimelineBucket?> getPublicBucket(
    String token,
    String month,
  ) async {
    final response = await getPublicBucketWithHttpInfo(
      token,
      month,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'TimelineBucket',
      ) as TimelineBucket;
    }
    return null;
  }

  /// Months in a public album
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  Future<Response> getPublicBucketsWithHttpInfo(
    String token,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/public/{token}/buckets'.replaceAll('{token}', token);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Months in a public album
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  Future<TimelineBuckets?> getPublicBuckets(
    String token,
  ) async {
    final response = await getPublicBucketsWithHttpInfo(
      token,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'TimelineBuckets',
      ) as TimelineBuckets;
    }
    return null;
  }

  /// What a public link offers. Needs no account.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  Future<Response> getPublicLinkWithHttpInfo(
    String token,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/public/{token}'.replaceAll('{token}', token);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// What a public link offers. Needs no account.
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  Future<PublicLink?> getPublicLink(
    String token,
  ) async {
    final response = await getPublicLinkWithHttpInfo(
      token,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'PublicLink',
      ) as PublicLink;
    }
    return null;
  }

  /// The video inside a Motion Photo in a public album
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  ///
  /// * [String] id (required):
  Future<Response> getPublicMotionWithHttpInfo(
    String token,
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/public/{token}/assets/{id}/motion'
        .replaceAll('{token}', token)
        .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// The video inside a Motion Photo in a public album
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  ///
  /// * [String] id (required):
  Future<MultipartFile?> getPublicMotion(
    String token,
    String id,
  ) async {
    final response = await getPublicMotionWithHttpInfo(
      token,
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'MultipartFile',
      ) as MultipartFile;
    }
    return null;
  }

  /// Download an original. Counts toward the link's limit.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  ///
  /// * [String] id (required):
  ///
  /// * [bool] download:
  Future<Response> getPublicOriginalWithHttpInfo(
    String token,
    String id, {
    bool? download,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/public/{token}/assets/{id}/original'
        .replaceAll('{token}', token)
        .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (download != null) {
      queryParams.addAll(_queryParams('', 'download', download));
    }

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Download an original. Counts toward the link's limit.
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  ///
  /// * [String] id (required):
  ///
  /// * [bool] download:
  Future<MultipartFile?> getPublicOriginal(
    String token,
    String id, {
    bool? download,
  }) async {
    final response = await getPublicOriginalWithHttpInfo(
      token,
      id,
      download: download,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'MultipartFile',
      ) as MultipartFile;
    }
    return null;
  }

  /// A preview from a public album, with the link's watermark if it has one
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  ///
  /// * [String] id (required):
  ///
  /// * [String] size:
  Future<Response> getPublicThumbnailWithHttpInfo(
    String token,
    String id, {
    String? size,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/public/{token}/assets/{id}/thumbnail'
        .replaceAll('{token}', token)
        .replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (size != null) {
      queryParams.addAll(_queryParams('', 'size', size));
    }

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// A preview from a public album, with the link's watermark if it has one
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  ///
  /// * [String] id (required):
  ///
  /// * [String] size:
  Future<MultipartFile?> getPublicThumbnail(
    String token,
    String id, {
    String? size,
  }) async {
    final response = await getPublicThumbnailWithHttpInfo(
      token,
      id,
      size: size,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'MultipartFile',
      ) as MultipartFile;
    }
    return null;
  }

  /// HLS files of a video in a public album
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  ///
  /// * [String] id (required):
  ///
  /// * [String] file (required):
  Future<Response> getPublicVideoFileWithHttpInfo(
    String token,
    String id,
    String file,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/public/{token}/assets/{id}/video/{file}'
        .replaceAll('{token}', token)
        .replaceAll('{id}', id)
        .replaceAll('{file}', file);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// HLS files of a video in a public album
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  ///
  /// * [String] id (required):
  ///
  /// * [String] file (required):
  Future<MultipartFile?> getPublicVideoFile(
    String token,
    String id,
    String file,
  ) async {
    final response = await getPublicVideoFileWithHttpInfo(
      token,
      id,
      file,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'MultipartFile',
      ) as MultipartFile;
    }
    return null;
  }

  /// How a video is coming along
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> getStoryExportWithHttpInfo(
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/stories/{id}'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// How a video is coming along
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<StoryExport?> getStoryExport(
    String id,
  ) async {
    final response = await getStoryExportWithHttpInfo(
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'StoryExport',
      ) as StoryExport;
    }
    return null;
  }

  /// The finished video
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> getStoryVideoWithHttpInfo(
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/stories/{id}/video'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// The finished video
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<MultipartFile?> getStoryVideo(
    String id,
  ) async {
    final response = await getStoryVideoWithHttpInfo(
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'MultipartFile',
      ) as MultipartFile;
    }
    return null;
  }

  /// Photos carrying a tag in one month
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] month (required):
  Future<Response> getTagBucketWithHttpInfo(
    String id,
    String month,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/tags/{id}/buckets/{month}'
        .replaceAll('{id}', id)
        .replaceAll('{month}', month);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Photos carrying a tag in one month
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] month (required):
  Future<TimelineBucket?> getTagBucket(
    String id,
    String month,
  ) async {
    final response = await getTagBucketWithHttpInfo(
      id,
      month,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'TimelineBucket',
      ) as TimelineBucket;
    }
    return null;
  }

  /// Months with photos carrying a tag
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> getTagBucketsWithHttpInfo(
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/tags/{id}/buckets'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Months with photos carrying a tag
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<TimelineBuckets?> getTagBuckets(
    String id,
  ) async {
    final response = await getTagBucketsWithHttpInfo(
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'TimelineBuckets',
      ) as TimelineBuckets;
    }
    return null;
  }

  /// List one month's assets, newest first
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] month (required):
  ///   YYYY-MM
  Future<Response> getTimelineBucketWithHttpInfo(
    String month,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/timeline/buckets/{month}'.replaceAll('{month}', month);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// List one month's assets, newest first
  ///
  /// Parameters:
  ///
  /// * [String] month (required):
  ///   YYYY-MM
  Future<TimelineBucket?> getTimelineBucket(
    String month,
  ) async {
    final response = await getTimelineBucketWithHttpInfo(
      month,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'TimelineBucket',
      ) as TimelineBucket;
    }
    return null;
  }

  /// List the months that have photos, newest first
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getTimelineBucketsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/timeline/buckets';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// List the months that have photos, newest first
  Future<TimelineBuckets?> getTimelineBuckets() async {
    final response = await getTimelineBucketsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'TimelineBuckets',
      ) as TimelineBuckets;
    }
    return null;
  }

  /// What emptying the trash would remove
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getTrashSummaryWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/trash/summary';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// What emptying the trash would remove
  Future<TrashSummary?> getTrashSummary() async {
    final response = await getTrashSummaryWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'TrashSummary',
      ) as TrashSummary;
    }
    return null;
  }

  /// Read how much of an upload has arrived (tus 1.0)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> getUploadOffsetWithHttpInfo(
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/uploads/{id}'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'HEAD',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Read how much of an upload has arrived (tus 1.0)
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> getUploadOffset(
    String id,
  ) async {
    final response = await getUploadOffsetWithHttpInfo(
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Whether the vault has a PIN and is unlocked
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getVaultStatusWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/vault/status';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Whether the vault has a PIN and is unlocked
  Future<VaultStatus?> getVaultStatus() async {
    final response = await getVaultStatusWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'VaultStatus',
      ) as VaultStatus;
    }
    return null;
  }

  /// The current user's keys, without the keys themselves
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listAPIKeysWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/me/api-keys';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// The current user's keys, without the keys themselves
  Future<List<ApiKey>?> listAPIKeys() async {
    final response = await listAPIKeysWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<ApiKey>')
              as List)
          .cast<ApiKey>()
          .toList(growable: false);
    }
    return null;
  }

  /// Comments on an album, or with assetId on one photo, and that photo's hearts
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] assetId:
  Future<Response> listAlbumCommentsWithHttpInfo(
    String id, {
    String? assetId,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/albums/{id}/comments'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (assetId != null) {
      queryParams.addAll(_queryParams('', 'assetId', assetId));
    }

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Comments on an album, or with assetId on one photo, and that photo's hearts
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] assetId:
  Future<Activity?> listAlbumComments(
    String id, {
    String? assetId,
  }) async {
    final response = await listAlbumCommentsWithHttpInfo(
      id,
      assetId: assetId,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'Activity',
      ) as Activity;
    }
    return null;
  }

  /// Public links of an album. Owner only.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> listAlbumLinksWithHttpInfo(
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/albums/{id}/links'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Public links of an album. Owner only.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<List<ShareLink>?> listAlbumLinks(
    String id,
  ) async {
    final response = await listAlbumLinksWithHttpInfo(
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<ShareLink>')
              as List)
          .cast<ShareLink>()
          .toList(growable: false);
    }
    return null;
  }

  /// Albums the current user owns or that are shared with them
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] sort:
  Future<Response> listAlbumsWithHttpInfo({
    String? sort,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/albums';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (sort != null) {
      queryParams.addAll(_queryParams('', 'sort', sort));
    }

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Albums the current user owns or that are shared with them
  ///
  /// Parameters:
  ///
  /// * [String] sort:
  Future<List<Album>?> listAlbums({
    String? sort,
  }) async {
    final response = await listAlbumsWithHttpInfo(
      sort: sort,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Album>')
              as List)
          .cast<Album>()
          .toList(growable: false);
    }
    return null;
  }

  /// List the current user's most recent assets and their processing status
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] limit:
  ///
  /// * [String] status:
  Future<Response> listAssetsWithHttpInfo({
    int? limit,
    String? status,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/assets';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (limit != null) {
      queryParams.addAll(_queryParams('', 'limit', limit));
    }
    if (status != null) {
      queryParams.addAll(_queryParams('', 'status', status));
    }

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// List the current user's most recent assets and their processing status
  ///
  /// Parameters:
  ///
  /// * [int] limit:
  ///
  /// * [String] status:
  Future<AssetList?> listAssets({
    int? limit,
    String? status,
  }) async {
    final response = await listAssetsWithHttpInfo(
      limit: limit,
      status: status,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'AssetList',
      ) as AssetList;
    }
    return null;
  }

  /// Who changed what, newest first. Never the content of a request
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] before:
  ///   Entries older than this id
  ///
  /// * [int] limit:
  Future<Response> listAuditLogWithHttpInfo({
    int? before,
    int? limit,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/audit';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (before != null) {
      queryParams.addAll(_queryParams('', 'before', before));
    }
    if (limit != null) {
      queryParams.addAll(_queryParams('', 'limit', limit));
    }

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Who changed what, newest first. Never the content of a request
  ///
  /// Parameters:
  ///
  /// * [int] before:
  ///   Entries older than this id
  ///
  /// * [int] limit:
  Future<List<AuditEntry>?> listAuditLog({
    int? before,
    int? limit,
  }) async {
    final response = await listAuditLogWithHttpInfo(
      before: before,
      limit: limit,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<AuditEntry>')
              as List)
          .cast<AuditEntry>()
          .toList(growable: false);
    }
    return null;
  }

  /// Backups and tests of bringing one back, the newest first
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listBackupRunsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/backup/runs';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Backups and tests of bringing one back, the newest first
  Future<List<BackupRun>?> listBackupRuns() async {
    final response = await listBackupRunsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<BackupRun>')
              as List)
          .cast<BackupRun>()
          .toList(growable: false);
    }
    return null;
  }

  /// Cameras in the current user's library, for smart album rules
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listCamerasWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/albums/cameras';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Cameras in the current user's library, for smart album rules
  Future<List<String>?> listCameras() async {
    final response = await listCamerasWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<String>')
              as List)
          .cast<String>()
          .toList(growable: false);
    }
    return null;
  }

  /// The other users of this server, for choosing who to share with
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listDirectoryWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/users/directory';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// The other users of this server, for choosing who to share with
  Future<List<UserRef>?> listDirectory() async {
    final response = await listDirectoryWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<UserRef>')
              as List)
          .cast<UserRef>()
          .toList(growable: false);
    }
    return null;
  }

  /// Groups of photos that look alike. Only a proposal, nothing is removed without asking
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listDuplicatesWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/duplicates';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Groups of photos that look alike. Only a proposal, nothing is removed without asking
  Future<Duplicates?> listDuplicates() async {
    final response = await listDuplicatesWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'Duplicates',
      ) as Duplicates;
    }
    return null;
  }

  /// Who is in the family library
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listFamilyMembersAdminWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/family';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Who is in the family library
  Future<List<UserRef>?> listFamilyMembersAdmin() async {
    final response = await listFamilyMembersAdminWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<UserRef>')
              as List)
          .cast<UserRef>()
          .toList(growable: false);
    }
    return null;
  }

  /// Imports, the newest first
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listImportsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/imports';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Imports, the newest first
  Future<List<ImportEntry>?> listImports() async {
    final response = await listImportsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(
              responseBody, 'List<ImportEntry>') as List)
          .cast<ImportEntry>()
          .toList(growable: false);
    }
    return null;
  }

  /// On this day in earlier years, and the last week
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [DateTime] date:
  ///   The user's own date, which decides what today is
  Future<Response> listMemoriesWithHttpInfo({
    DateTime? date,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/memories';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (date != null) {
      queryParams.addAll(_queryParams('', 'date', date));
    }

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// On this day in earlier years, and the last week
  ///
  /// Parameters:
  ///
  /// * [DateTime] date:
  ///   The user's own date, which decides what today is
  Future<List<Memory>?> listMemories({
    DateTime? date,
  }) async {
    final response = await listMemoriesWithHttpInfo(
      date: date,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Memory>')
              as List)
          .cast<Memory>()
          .toList(growable: false);
    }
    return null;
  }

  /// Who you share your library with, and who shares theirs with you
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listPartnersWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/partners';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Who you share your library with, and who shares theirs with you
  Future<Partners?> listPartners() async {
    final response = await listPartnersWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'Partners',
      ) as Partners;
    }
    return null;
  }

  /// The current user's passkeys
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listPasskeysWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/me/passkeys';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// The current user's passkeys
  Future<List<Passkey>?> listPasskeys() async {
    final response = await listPasskeysWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Passkey>')
              as List)
          .cast<Passkey>()
          .toList(growable: false);
    }
    return null;
  }

  /// People recognised in the current user's library
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listPeopleWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/people';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// People recognised in the current user's library
  Future<PeopleList?> listPeople() async {
    final response = await listPeopleWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'PeopleList',
      ) as PeopleList;
    }
    return null;
  }

  /// The current user's tags
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listTagsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/tags';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// The current user's tags
  Future<List<Tag>?> listTags() async {
    final response = await listTagsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Tag>')
              as List)
          .cast<Tag>()
          .toList(growable: false);
    }
    return null;
  }

  /// List users
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listUsersWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/users';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// List users
  Future<List<User>?> listUsers() async {
    final response = await listUsersWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<User>')
              as List)
          .cast<User>()
          .toList(growable: false);
    }
    return null;
  }

  /// Addresses told about events, without their secrets
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listWebhooksWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/webhooks';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Addresses told about events, without their secrets
  Future<List<Webhook>?> listWebhooks() async {
    final response = await listWebhooksWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Webhook>')
              as List)
          .cast<Webhook>()
          .toList(growable: false);
    }
    return null;
  }

  /// Lock the vault again
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> lockVaultWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/vault/lock';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Lock the vault again
  Future<void> lockVault() async {
    final response = await lockVaultWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Sign in with email, password and, when enabled, a TOTP code
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [LoginRequest] loginRequest (required):
  Future<Response> loginWithHttpInfo(
    LoginRequest loginRequest,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/auth/login';

    // ignore: prefer_final_locals
    Object? postBody = loginRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Sign in with email, password and, when enabled, a TOTP code
  ///
  /// Parameters:
  ///
  /// * [LoginRequest] loginRequest (required):
  Future<User?> login(
    LoginRequest loginRequest,
  ) async {
    final response = await loginWithHttpInfo(
      loginRequest,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'User',
      ) as User;
    }
    return null;
  }

  /// End the current session
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> logoutWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/auth/logout';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// End the current session
  Future<void> logout() async {
    final response = await logoutWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Treat other people as this one
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [AssetIds] assetIds (required):
  Future<Response> mergePeopleWithHttpInfo(
    String id,
    AssetIds assetIds,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/people/{id}/merge'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = assetIds;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Treat other people as this one
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [AssetIds] assetIds (required):
  Future<void> mergePeople(
    String id,
    AssetIds assetIds,
  ) async {
    final response = await mergePeopleWithHttpInfo(
      id,
      assetIds,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Stop starting jobs from this queue
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] queue (required):
  Future<Response> pauseJobQueueWithHttpInfo(
    String queue,
  ) async {
    // ignore: prefer_const_declarations
    final path =
        r'/api/admin/jobs/queues/{queue}/pause'.replaceAll('{queue}', queue);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Stop starting jobs from this queue
  ///
  /// Parameters:
  ///
  /// * [String] queue (required):
  Future<void> pauseJobQueue(
    String queue,
  ) async {
    final response = await pauseJobQueueWithHttpInfo(
      queue,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Remove assets from an album. A contributor can remove only what they added.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [AssetIds] assetIds (required):
  Future<Response> removeAlbumAssetsWithHttpInfo(
    String id,
    AssetIds assetIds,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/albums/{id}/assets/remove'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = assetIds;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Remove assets from an album. A contributor can remove only what they added.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [AssetIds] assetIds (required):
  Future<BulkResponse?> removeAlbumAssets(
    String id,
    AssetIds assetIds,
  ) async {
    final response = await removeAlbumAssetsWithHttpInfo(
      id,
      assetIds,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'BulkResponse',
      ) as BulkResponse;
    }
    return null;
  }

  /// Take back your heart
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] assetId (required):
  Future<Response> removeAlbumHeartWithHttpInfo(
    String id,
    String assetId,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/albums/{id}/assets/{assetId}/heart'
        .replaceAll('{id}', id)
        .replaceAll('{assetId}', assetId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Take back your heart
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] assetId (required):
  Future<void> removeAlbumHeart(
    String id,
    String assetId,
  ) async {
    final response = await removeAlbumHeartWithHttpInfo(
      id,
      assetId,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// End a user's access. The owner can remove anyone, and a member can leave.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] userId (required):
  Future<Response> removeAlbumMemberWithHttpInfo(
    String id,
    String userId,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/albums/{id}/members/{userId}'
        .replaceAll('{id}', id)
        .replaceAll('{userId}', userId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// End a user's access. The owner can remove anyone, and a member can leave.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] userId (required):
  Future<void> removeAlbumMember(
    String id,
    String userId,
  ) async {
    final response = await removeAlbumMemberWithHttpInfo(
      id,
      userId,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Remove someone. Their photos stay in their own library
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] userId (required):
  Future<Response> removeFamilyMemberWithHttpInfo(
    String userId,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/family/{userId}'.replaceAll('{userId}', userId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Remove someone. Their photos stay in their own library
  ///
  /// Parameters:
  ///
  /// * [String] userId (required):
  Future<void> removeFamilyMember(
    String userId,
  ) async {
    final response = await removeFamilyMemberWithHttpInfo(
      userId,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Stop sharing your library with a user
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] userId (required):
  Future<Response> removePartnerWithHttpInfo(
    String userId,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/partners/{userId}'.replaceAll('{userId}', userId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Stop sharing your library with a user
  ///
  /// Parameters:
  ///
  /// * [String] userId (required):
  Future<void> removePartner(
    String userId,
  ) async {
    final response = await removePartnerWithHttpInfo(
      userId,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Continue a paused queue
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] queue (required):
  Future<Response> resumeJobQueueWithHttpInfo(
    String queue,
  ) async {
    // ignore: prefer_const_declarations
    final path =
        r'/api/admin/jobs/queues/{queue}/resume'.replaceAll('{queue}', queue);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Continue a paused queue
  ///
  /// Parameters:
  ///
  /// * [String] queue (required):
  Future<void> resumeJobQueue(
    String queue,
  ) async {
    final response = await resumeJobQueueWithHttpInfo(
      queue,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Try a failed job again
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> retryJobWithHttpInfo(
    int id,
  ) async {
    // ignore: prefer_const_declarations
    final path =
        r'/api/admin/jobs/{id}/retry'.replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Try a failed job again
  ///
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<void> retryJob(
    int id,
  ) async {
    final response = await retryJobWithHttpInfo(
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Revoke one of the current user's device keys
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> revokeDeviceKeyWithHttpInfo(
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/me/device-keys/{id}'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Revoke one of the current user's device keys
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> revokeDeviceKey(
    String id,
  ) async {
    final response = await revokeDeviceKeyWithHttpInfo(
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Look through the folder for changes now
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> scanExternalLibraryWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/external/scan';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Look through the folder for changes now
  Future<void> scanExternalLibrary() async {
    final response = await scanExternalLibraryWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Search in natural language. Dates, people, places and cameras in the query become filters.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] q (required):
  Future<Response> searchAssetsWithHttpInfo(
    String q,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/search';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    queryParams.addAll(_queryParams('', 'q', q));

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Search in natural language. Dates, people, places and cameras in the query become filters.
  ///
  /// Parameters:
  ///
  /// * [String] q (required):
  Future<SearchResult?> searchAssets(
    String q,
  ) async {
    final response = await searchAssetsWithHttpInfo(
      q,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'SearchResult',
      ) as SearchResult;
    }
    return null;
  }

  /// Name the Ollama server. Previews of photos are sent to it
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [AISettingsUpdate] aISettingsUpdate (required):
  Future<Response> setAISettingsWithHttpInfo(
    AISettingsUpdate aISettingsUpdate,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/ai';

    // ignore: prefer_final_locals
    Object? postBody = aISettingsUpdate;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Name the Ollama server. Previews of photos are sent to it
  ///
  /// Parameters:
  ///
  /// * [AISettingsUpdate] aISettingsUpdate (required):
  Future<AISettings?> setAISettings(
    AISettingsUpdate aISettingsUpdate,
  ) async {
    final response = await setAISettingsWithHttpInfo(
      aISettingsUpdate,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'AISettings',
      ) as AISettings;
    }
    return null;
  }

  /// Add your heart to a photo in an album
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] assetId (required):
  Future<Response> setAlbumHeartWithHttpInfo(
    String id,
    String assetId,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/albums/{id}/assets/{assetId}/heart'
        .replaceAll('{id}', id)
        .replaceAll('{assetId}', assetId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Add your heart to a photo in an album
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] assetId (required):
  Future<void> setAlbumHeart(
    String id,
    String assetId,
  ) async {
    final response = await setAlbumHeartWithHttpInfo(
      id,
      assetId,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Share an album with a user or change their role. Owner only.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] userId (required):
  ///
  /// * [MemberRole] memberRole (required):
  Future<Response> setAlbumMemberWithHttpInfo(
    String id,
    String userId,
    MemberRole memberRole,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/albums/{id}/members/{userId}'
        .replaceAll('{id}', id)
        .replaceAll('{userId}', userId);

    // ignore: prefer_final_locals
    Object? postBody = memberRole;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Share an album with a user or change their role. Owner only.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] userId (required):
  ///
  /// * [MemberRole] memberRole (required):
  Future<void> setAlbumMember(
    String id,
    String userId,
    MemberRole memberRole,
  ) async {
    final response = await setAlbumMemberWithHttpInfo(
      id,
      userId,
      memberRole,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Replace the list of edits of a photo. The original is never changed
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [AssetEdits] assetEdits (required):
  Future<Response> setAssetEditsWithHttpInfo(
    String id,
    AssetEdits assetEdits,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/assets/{id}/edits'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = assetEdits;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Replace the list of edits of a photo. The original is never changed
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [AssetEdits] assetEdits (required):
  Future<void> setAssetEdits(
    String id,
    AssetEdits assetEdits,
  ) async {
    final response = await setAssetEditsWithHttpInfo(
      id,
      assetEdits,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Change where backups go. A secret left out stays as it was
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [BackupSettingsUpdate] backupSettingsUpdate (required):
  Future<Response> setBackupSettingsWithHttpInfo(
    BackupSettingsUpdate backupSettingsUpdate,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/backup';

    // ignore: prefer_final_locals
    Object? postBody = backupSettingsUpdate;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Change where backups go. A secret left out stays as it was
  ///
  /// Parameters:
  ///
  /// * [BackupSettingsUpdate] backupSettingsUpdate (required):
  Future<BackupSettings?> setBackupSettings(
    BackupSettingsUpdate backupSettingsUpdate,
  ) async {
    final response = await setBackupSettingsWithHttpInfo(
      backupSettingsUpdate,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'BackupSettings',
      ) as BackupSettings;
    }
    return null;
  }

  /// Choose whose photos the folder holds, and start reading it
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [ExternalLibraryOwner] externalLibraryOwner (required):
  Future<Response> setExternalLibraryWithHttpInfo(
    ExternalLibraryOwner externalLibraryOwner,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/external';

    // ignore: prefer_final_locals
    Object? postBody = externalLibraryOwner;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Choose whose photos the folder holds, and start reading it
  ///
  /// Parameters:
  ///
  /// * [ExternalLibraryOwner] externalLibraryOwner (required):
  Future<ExternalLibrary?> setExternalLibrary(
    ExternalLibraryOwner externalLibraryOwner,
  ) async {
    final response = await setExternalLibraryWithHttpInfo(
      externalLibraryOwner,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'ExternalLibrary',
      ) as ExternalLibrary;
    }
    return null;
  }

  /// Turn an addition on or off
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///
  /// * [FeatureUpdate] featureUpdate (required):
  Future<Response> setFeatureWithHttpInfo(
    String name,
    FeatureUpdate featureUpdate,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/features/{name}'.replaceAll('{name}', name);

    // ignore: prefer_final_locals
    Object? postBody = featureUpdate;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Turn an addition on or off
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///
  /// * [FeatureUpdate] featureUpdate (required):
  Future<void> setFeature(
    String name,
    FeatureUpdate featureUpdate,
  ) async {
    final response = await setFeatureWithHttpInfo(
      name,
      featureUpdate,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Choose the map's background. Administrators only. Empty goes back to the default.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [MapStyle] mapStyle (required):
  Future<Response> setMapStyleWithHttpInfo(
    MapStyle mapStyle,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/map/style';

    // ignore: prefer_final_locals
    Object? postBody = mapStyle;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Choose the map's background. Administrators only. Empty goes back to the default.
  ///
  /// Parameters:
  ///
  /// * [MapStyle] mapStyle (required):
  Future<MapStyle?> setMapStyle(
    MapStyle mapStyle,
  ) async {
    final response = await setMapStyleWithHttpInfo(
      mapStyle,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'MapStyle',
      ) as MapStyle;
    }
    return null;
  }

  /// Change single sign-on. An empty issuer turns it off
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [OIDCSettingsUpdate] oIDCSettingsUpdate (required):
  Future<Response> setOIDCSettingsWithHttpInfo(
    OIDCSettingsUpdate oIDCSettingsUpdate,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/oidc';

    // ignore: prefer_final_locals
    Object? postBody = oIDCSettingsUpdate;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Change single sign-on. An empty issuer turns it off
  ///
  /// Parameters:
  ///
  /// * [OIDCSettingsUpdate] oIDCSettingsUpdate (required):
  Future<OIDCSettings?> setOIDCSettings(
    OIDCSettingsUpdate oIDCSettingsUpdate,
  ) async {
    final response = await setOIDCSettingsWithHttpInfo(
      oIDCSettingsUpdate,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'OIDCSettings',
      ) as OIDCSettings;
    }
    return null;
  }

  /// Share your library with a user, all of it or from a date
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] userId (required):
  ///
  /// * [PartnerShare] partnerShare (required):
  Future<Response> setPartnerWithHttpInfo(
    String userId,
    PartnerShare partnerShare,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/partners/{userId}'.replaceAll('{userId}', userId);

    // ignore: prefer_final_locals
    Object? postBody = partnerShare;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Share your library with a user, all of it or from a date
  ///
  /// Parameters:
  ///
  /// * [String] userId (required):
  ///
  /// * [PartnerShare] partnerShare (required):
  Future<void> setPartner(
    String userId,
    PartnerShare partnerShare,
  ) async {
    final response = await setPartnerWithHttpInfo(
      userId,
      partnerShare,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Choose whether a partner's photos also appear in your timeline
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] userId (required):
  ///
  /// * [PartnerTimeline] partnerTimeline (required):
  Future<Response> setPartnerTimelineWithHttpInfo(
    String userId,
    PartnerTimeline partnerTimeline,
  ) async {
    // ignore: prefer_const_declarations
    final path =
        r'/api/partners/{userId}/timeline'.replaceAll('{userId}', userId);

    // ignore: prefer_final_locals
    Object? postBody = partnerTimeline;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Choose whether a partner's photos also appear in your timeline
  ///
  /// Parameters:
  ///
  /// * [String] userId (required):
  ///
  /// * [PartnerTimeline] partnerTimeline (required):
  Future<void> setPartnerTimeline(
    String userId,
    PartnerTimeline partnerTimeline,
  ) async {
    final response = await setPartnerTimelineWithHttpInfo(
      userId,
      partnerTimeline,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Make this shot the one the timeline shows
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> setStackMainWithHttpInfo(
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/assets/{id}/stack/main'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Make this shot the one the timeline shows
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> setStackMain(
    String id,
  ) async {
    final response = await setStackMainWithHttpInfo(
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Set how much a user may store. Without a value there is no limit
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [QuotaUpdate] quotaUpdate (required):
  Future<Response> setUserQuotaWithHttpInfo(
    String id,
    QuotaUpdate quotaUpdate,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/users/{id}/quota'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = quotaUpdate;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Set how much a user may store. Without a value there is no limit
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [QuotaUpdate] quotaUpdate (required):
  Future<void> setUserQuota(
    String id,
    QuotaUpdate quotaUpdate,
  ) async {
    final response = await setUserQuotaWithHttpInfo(
      id,
      quotaUpdate,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Set the vault PIN. Changing it needs the current one.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [VaultPinChange] vaultPinChange (required):
  Future<Response> setVaultPinWithHttpInfo(
    VaultPinChange vaultPinChange,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/vault/pin';

    // ignore: prefer_final_locals
    Object? postBody = vaultPinChange;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Set the vault PIN. Changing it needs the current one.
  ///
  /// Parameters:
  ///
  /// * [VaultPinChange] vaultPinChange (required):
  Future<void> setVaultPin(
    VaultPinChange vaultPinChange,
  ) async {
    final response = await setVaultPinWithHttpInfo(
      vaultPinChange,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Create the first administrator. Closed once any user exists.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [SetupRequest] setupRequest (required):
  Future<Response> setupWithHttpInfo(
    SetupRequest setupRequest,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/auth/setup';

    // ignore: prefer_final_locals
    Object? postBody = setupRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Create the first administrator. Closed once any user exists.
  ///
  /// Parameters:
  ///
  /// * [SetupRequest] setupRequest (required):
  Future<User?> setup(
    SetupRequest setupRequest,
  ) async {
    final response = await setupWithHttpInfo(
      setupRequest,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'User',
      ) as User;
    }
    return null;
  }

  /// Generate a TOTP secret. It takes effect only after confirmation.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> setupTotpWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/me/totp/setup';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Generate a TOTP secret. It takes effect only after confirmation.
  Future<TotpSetup?> setupTotp() async {
    final response = await setupTotpWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'TotpSetup',
      ) as TotpSetup;
    }
    return null;
  }

  /// Back up now, or test bringing the newest backup back
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [BackupRunRequest] backupRunRequest (required):
  Future<Response> startBackupRunWithHttpInfo(
    BackupRunRequest backupRunRequest,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/backup/runs';

    // ignore: prefer_final_locals
    Object? postBody = backupRunRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Back up now, or test bringing the newest backup back
  ///
  /// Parameters:
  ///
  /// * [BackupRunRequest] backupRunRequest (required):
  Future<void> startBackupRun(
    BackupRunRequest backupRunRequest,
  ) async {
    final response = await startBackupRunWithHttpInfo(
      backupRunRequest,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Go to the identity provider
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] next:
  ///
  /// * [String] appChallenge:
  ///   SHA-256 of a secret the app keeps, base64url
  Future<Response> startOIDCWithHttpInfo({
    String? next,
    String? appChallenge,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/auth/oidc/start';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (next != null) {
      queryParams.addAll(_queryParams('', 'next', next));
    }
    if (appChallenge != null) {
      queryParams.addAll(_queryParams('', 'appChallenge', appChallenge));
    }

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Go to the identity provider
  ///
  /// Parameters:
  ///
  /// * [String] next:
  ///
  /// * [String] appChallenge:
  ///   SHA-256 of a secret the app keeps, base64url
  Future<void> startOIDC({
    String? next,
    String? appChallenge,
  }) async {
    final response = await startOIDCWithHttpInfo(
      next: next,
      appChallenge: appChallenge,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Send a test event now
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> testWebhookWithHttpInfo(
    String id,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/webhooks/{id}/test'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Send a test event now
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> testWebhook(
    String id,
  ) async {
    final response = await testWebhookWithHttpInfo(
      id,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Send a link's password. Success sets a cookie valid only for this link.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  ///
  /// * [LinkPassword] linkPassword (required):
  Future<Response> unlockPublicLinkWithHttpInfo(
    String token,
    LinkPassword linkPassword,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/public/{token}/unlock'.replaceAll('{token}', token);

    // ignore: prefer_final_locals
    Object? postBody = linkPassword;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Send a link's password. Success sets a cookie valid only for this link.
  ///
  /// Parameters:
  ///
  /// * [String] token (required):
  ///
  /// * [LinkPassword] linkPassword (required):
  Future<void> unlockPublicLink(
    String token,
    LinkPassword linkPassword,
  ) async {
    final response = await unlockPublicLinkWithHttpInfo(
      token,
      linkPassword,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Unlock the vault for a short time
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [VaultUnlock] vaultUnlock (required):
  Future<Response> unlockVaultWithHttpInfo(
    VaultUnlock vaultUnlock,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/vault/unlock';

    // ignore: prefer_final_locals
    Object? postBody = vaultUnlock;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Unlock the vault for a short time
  ///
  /// Parameters:
  ///
  /// * [VaultUnlock] vaultUnlock (required):
  Future<VaultSession?> unlockVault(
    VaultUnlock vaultUnlock,
  ) async {
    final response = await unlockVaultWithHttpInfo(
      vaultUnlock,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'VaultSession',
      ) as VaultSession;
    }
    return null;
  }

  /// Change an album. Needs the editor role.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [AlbumUpdate] albumUpdate (required):
  Future<Response> updateAlbumWithHttpInfo(
    String id,
    AlbumUpdate albumUpdate,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/albums/{id}'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = albumUpdate;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Change an album. Needs the editor role.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [AlbumUpdate] albumUpdate (required):
  Future<Album?> updateAlbum(
    String id,
    AlbumUpdate albumUpdate,
  ) async {
    final response = await updateAlbumWithHttpInfo(
      id,
      albumUpdate,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'Album',
      ) as Album;
    }
    return null;
  }

  /// Name or hide a person
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [PersonUpdate] personUpdate (required):
  Future<Response> updatePersonWithHttpInfo(
    String id,
    PersonUpdate personUpdate,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/api/people/{id}'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = personUpdate;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Name or hide a person
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [PersonUpdate] personUpdate (required):
  Future<void> updatePerson(
    String id,
    PersonUpdate personUpdate,
  ) async {
    final response = await updatePersonWithHttpInfo(
      id,
      personUpdate,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }
}

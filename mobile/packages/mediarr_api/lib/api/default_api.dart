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

  /// Create a resumable upload (tus 1.0)
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

  /// Create a resumable upload (tus 1.0)
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

  /// List the current user's most recent assets and their processing status
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] limit:
  Future<Response> listAssetsWithHttpInfo({
    int? limit,
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
  Future<AssetList?> listAssets({
    int? limit,
  }) async {
    final response = await listAssetsWithHttpInfo(
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
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'AssetList',
      ) as AssetList;
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
}

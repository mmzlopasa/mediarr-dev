# mediarr_api.api.DefaultApi

## Load the API package
```dart
import 'package:mediarr_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**addAlbumAssets**](DefaultApi.md#addalbumassets) | **POST** /api/albums/{id}/assets | Add your own assets to an album. Needs the contributor role.
[**appendUpload**](DefaultApi.md#appendupload) | **PATCH** /api/uploads/{id} | Append data to an upload (tus 1.0). The last chunk returns X-Asset-Id.
[**bulkAssets**](DefaultApi.md#bulkassets) | **POST** /api/assets/bulk | Apply an action to several of the current user's assets. Other assets are ignored.
[**cancelUpload**](DefaultApi.md#cancelupload) | **DELETE** /api/uploads/{id} | Cancel an upload (tus 1.0)
[**changePassword**](DefaultApi.md#changepassword) | **POST** /api/me/password | Change the current user's password and end their other sessions
[**checkAssets**](DefaultApi.md#checkassets) | **POST** /api/assets/check | Report which SHA-256 checksums the current user already has, so uploads can be skipped
[**createAlbum**](DefaultApi.md#createalbum) | **POST** /api/albums | Create an album. With rules it is a smart album.
[**createAlbumComment**](DefaultApi.md#createalbumcomment) | **POST** /api/albums/{id}/comments | Comment on an album or on a photo in it
[**createAlbumLink**](DefaultApi.md#createalbumlink) | **POST** /api/albums/{id}/links | Create a public link. Its token is returned only this once.
[**createDeviceKey**](DefaultApi.md#createdevicekey) | **POST** /api/me/device-keys | Create a long-lived key for this device, used by background backup
[**createPublicUpload**](DefaultApi.md#createpublicupload) | **POST** /api/public/{token}/uploads | Send one whole file to a public album (tus 1.0 creation with upload)
[**createUpload**](DefaultApi.md#createupload) | **POST** /api/uploads | Create a resumable upload (tus 1.0). A body uploads the whole file in this request.
[**createUser**](DefaultApi.md#createuser) | **POST** /api/admin/users | Create a user
[**deleteAlbum**](DefaultApi.md#deletealbum) | **DELETE** /api/albums/{id} | Delete an album, but not its photos. Owner only.
[**deleteAlbumComment**](DefaultApi.md#deletealbumcomment) | **DELETE** /api/albums/{id}/comments/{commentId} | Delete a comment. The author, an editor or the owner can do this.
[**deleteAlbumLink**](DefaultApi.md#deletealbumlink) | **DELETE** /api/albums/{id}/links/{linkId} | Revoke a public link. It stops working at once.
[**disableTotp**](DefaultApi.md#disabletotp) | **POST** /api/me/totp/disable | Turn off TOTP
[**downloadAssets**](DefaultApi.md#downloadassets) | **GET** /api/assets/download | Download several originals as one uncompressed ZIP file
[**enableTotp**](DefaultApi.md#enabletotp) | **POST** /api/me/totp/enable | Confirm a code and turn on TOTP
[**getAdminOverview**](DefaultApi.md#getadminoverview) | **GET** /api/admin/overview | Live statistics of the whole server, read from the database and the library disk
[**getAlbum**](DefaultApi.md#getalbum) | **GET** /api/albums/{id} | Read an album and its members
[**getAlbumBucket**](DefaultApi.md#getalbumbucket) | **GET** /api/albums/{id}/buckets/{month} | Assets of one month in an album
[**getAlbumBuckets**](DefaultApi.md#getalbumbuckets) | **GET** /api/albums/{id}/buckets | Months in an album, in the album's order
[**getAsset**](DefaultApi.md#getasset) | **GET** /api/assets/{id} | Read an asset's details and its neighbours on the timeline
[**getAssetMotion**](DefaultApi.md#getassetmotion) | **GET** /api/assets/{id}/motion | Read the video embedded in an Android Motion Photo
[**getAssetOriginal**](DefaultApi.md#getassetoriginal) | **GET** /api/assets/{id}/original | Read the unmodified original. Supports Range requests for video.
[**getAssetThumbnail**](DefaultApi.md#getassetthumbnail) | **GET** /api/assets/{id}/thumbnail | Read a WebP thumbnail
[**getAssetVideoFile**](DefaultApi.md#getassetvideofile) | **GET** /api/assets/{id}/video/{file} | Read an HLS playlist or segment, or the scrub strip (sprite.jpg)
[**getAuthStatus**](DefaultApi.md#getauthstatus) | **GET** /api/auth/status | Report whether setup is needed and who is signed in
[**getHealth**](DefaultApi.md#gethealth) | **GET** /health | Report whether the server can reach its database
[**getPartnerBucket**](DefaultApi.md#getpartnerbucket) | **GET** /api/partners/{userId}/buckets/{month} | Assets of one month in a library shared with you
[**getPartnerBuckets**](DefaultApi.md#getpartnerbuckets) | **GET** /api/partners/{userId}/buckets | Months in a library shared with you
[**getPublicAsset**](DefaultApi.md#getpublicasset) | **GET** /api/public/{token}/assets/{id} | An asset in a public album, without what the link does not allow
[**getPublicBucket**](DefaultApi.md#getpublicbucket) | **GET** /api/public/{token}/buckets/{month} | Assets of one month in a public album
[**getPublicBuckets**](DefaultApi.md#getpublicbuckets) | **GET** /api/public/{token}/buckets | Months in a public album
[**getPublicLink**](DefaultApi.md#getpubliclink) | **GET** /api/public/{token} | What a public link offers. Needs no account.
[**getPublicMotion**](DefaultApi.md#getpublicmotion) | **GET** /api/public/{token}/assets/{id}/motion | The video inside a Motion Photo in a public album
[**getPublicOriginal**](DefaultApi.md#getpublicoriginal) | **GET** /api/public/{token}/assets/{id}/original | Download an original. Counts toward the link's limit.
[**getPublicThumbnail**](DefaultApi.md#getpublicthumbnail) | **GET** /api/public/{token}/assets/{id}/thumbnail | A preview from a public album, with the link's watermark if it has one
[**getPublicVideoFile**](DefaultApi.md#getpublicvideofile) | **GET** /api/public/{token}/assets/{id}/video/{file} | HLS files of a video in a public album
[**getTimelineBucket**](DefaultApi.md#gettimelinebucket) | **GET** /api/timeline/buckets/{month} | List one month's assets, newest first
[**getTimelineBuckets**](DefaultApi.md#gettimelinebuckets) | **GET** /api/timeline/buckets | List the months that have photos, newest first
[**getUploadOffset**](DefaultApi.md#getuploadoffset) | **HEAD** /api/uploads/{id} | Read how much of an upload has arrived (tus 1.0)
[**listAlbumComments**](DefaultApi.md#listalbumcomments) | **GET** /api/albums/{id}/comments | Comments on an album, or with assetId on one photo, and that photo's hearts
[**listAlbumLinks**](DefaultApi.md#listalbumlinks) | **GET** /api/albums/{id}/links | Public links of an album. Owner only.
[**listAlbums**](DefaultApi.md#listalbums) | **GET** /api/albums | Albums the current user owns or that are shared with them
[**listAssets**](DefaultApi.md#listassets) | **GET** /api/assets | List the current user's most recent assets and their processing status
[**listCameras**](DefaultApi.md#listcameras) | **GET** /api/albums/cameras | Cameras in the current user's library, for smart album rules
[**listDirectory**](DefaultApi.md#listdirectory) | **GET** /api/users/directory | The other users of this server, for choosing who to share with
[**listPartners**](DefaultApi.md#listpartners) | **GET** /api/partners | Who you share your library with, and who shares theirs with you
[**listUsers**](DefaultApi.md#listusers) | **GET** /api/admin/users | List users
[**login**](DefaultApi.md#login) | **POST** /api/auth/login | Sign in with email, password and, when enabled, a TOTP code
[**logout**](DefaultApi.md#logout) | **POST** /api/auth/logout | End the current session
[**removeAlbumAssets**](DefaultApi.md#removealbumassets) | **POST** /api/albums/{id}/assets/remove | Remove assets from an album. A contributor can remove only what they added.
[**removeAlbumHeart**](DefaultApi.md#removealbumheart) | **DELETE** /api/albums/{id}/assets/{assetId}/heart | Take back your heart
[**removeAlbumMember**](DefaultApi.md#removealbummember) | **DELETE** /api/albums/{id}/members/{userId} | End a user's access. The owner can remove anyone, and a member can leave.
[**removePartner**](DefaultApi.md#removepartner) | **DELETE** /api/partners/{userId} | Stop sharing your library with a user
[**revokeDeviceKey**](DefaultApi.md#revokedevicekey) | **DELETE** /api/me/device-keys/{id} | Revoke one of the current user's device keys
[**setAlbumHeart**](DefaultApi.md#setalbumheart) | **PUT** /api/albums/{id}/assets/{assetId}/heart | Add your heart to a photo in an album
[**setAlbumMember**](DefaultApi.md#setalbummember) | **PUT** /api/albums/{id}/members/{userId} | Share an album with a user or change their role. Owner only.
[**setPartner**](DefaultApi.md#setpartner) | **PUT** /api/partners/{userId} | Share your library with a user, all of it or from a date
[**setPartnerTimeline**](DefaultApi.md#setpartnertimeline) | **PUT** /api/partners/{userId}/timeline | Choose whether a partner's photos also appear in your timeline
[**setup**](DefaultApi.md#setup) | **POST** /api/auth/setup | Create the first administrator. Closed once any user exists.
[**setupTotp**](DefaultApi.md#setuptotp) | **POST** /api/me/totp/setup | Generate a TOTP secret. It takes effect only after confirmation.
[**unlockPublicLink**](DefaultApi.md#unlockpubliclink) | **POST** /api/public/{token}/unlock | Send a link's password. Success sets a cookie valid only for this link.
[**updateAlbum**](DefaultApi.md#updatealbum) | **PATCH** /api/albums/{id} | Change an album. Needs the editor role.


# **addAlbumAssets**
> BulkResponse addAlbumAssets(id, assetIds)

Add your own assets to an album. Needs the contributor role.

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final assetIds = AssetIds(); // AssetIds | 

try {
    final result = api_instance.addAlbumAssets(id, assetIds);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->addAlbumAssets: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **assetIds** | [**AssetIds**](AssetIds.md)|  | 

### Return type

[**BulkResponse**](BulkResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **appendUpload**
> appendUpload(id)

Append data to an upload (tus 1.0). The last chunk returns X-Asset-Id.

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = id_example; // String | 

try {
    api_instance.appendUpload(id);
} catch (e) {
    print('Exception when calling DefaultApi->appendUpload: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **bulkAssets**
> BulkResponse bulkAssets(bulkRequest)

Apply an action to several of the current user's assets. Other assets are ignored.

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final bulkRequest = BulkRequest(); // BulkRequest | 

try {
    final result = api_instance.bulkAssets(bulkRequest);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->bulkAssets: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **bulkRequest** | [**BulkRequest**](BulkRequest.md)|  | 

### Return type

[**BulkResponse**](BulkResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cancelUpload**
> cancelUpload(id)

Cancel an upload (tus 1.0)

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = id_example; // String | 

try {
    api_instance.cancelUpload(id);
} catch (e) {
    print('Exception when calling DefaultApi->cancelUpload: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **changePassword**
> changePassword(changePasswordRequest)

Change the current user's password and end their other sessions

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final changePasswordRequest = ChangePasswordRequest(); // ChangePasswordRequest | 

try {
    api_instance.changePassword(changePasswordRequest);
} catch (e) {
    print('Exception when calling DefaultApi->changePassword: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **changePasswordRequest** | [**ChangePasswordRequest**](ChangePasswordRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **checkAssets**
> ChecksumCheckResponse checkAssets(checksumCheckRequest)

Report which SHA-256 checksums the current user already has, so uploads can be skipped

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final checksumCheckRequest = ChecksumCheckRequest(); // ChecksumCheckRequest | 

try {
    final result = api_instance.checkAssets(checksumCheckRequest);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->checkAssets: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **checksumCheckRequest** | [**ChecksumCheckRequest**](ChecksumCheckRequest.md)|  | 

### Return type

[**ChecksumCheckResponse**](ChecksumCheckResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createAlbum**
> Album createAlbum(albumCreate)

Create an album. With rules it is a smart album.

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final albumCreate = AlbumCreate(); // AlbumCreate | 

try {
    final result = api_instance.createAlbum(albumCreate);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->createAlbum: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **albumCreate** | [**AlbumCreate**](AlbumCreate.md)|  | 

### Return type

[**Album**](Album.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createAlbumComment**
> createAlbumComment(id, commentCreate)

Comment on an album or on a photo in it

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final commentCreate = CommentCreate(); // CommentCreate | 

try {
    api_instance.createAlbumComment(id, commentCreate);
} catch (e) {
    print('Exception when calling DefaultApi->createAlbumComment: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **commentCreate** | [**CommentCreate**](CommentCreate.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createAlbumLink**
> ShareLink createAlbumLink(id, shareLinkCreate)

Create a public link. Its token is returned only this once.

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final shareLinkCreate = ShareLinkCreate(); // ShareLinkCreate | 

try {
    final result = api_instance.createAlbumLink(id, shareLinkCreate);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->createAlbumLink: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **shareLinkCreate** | [**ShareLinkCreate**](ShareLinkCreate.md)|  | 

### Return type

[**ShareLink**](ShareLink.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createDeviceKey**
> DeviceKey createDeviceKey(createDeviceKeyRequest)

Create a long-lived key for this device, used by background backup

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final createDeviceKeyRequest = CreateDeviceKeyRequest(); // CreateDeviceKeyRequest | 

try {
    final result = api_instance.createDeviceKey(createDeviceKeyRequest);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->createDeviceKey: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createDeviceKeyRequest** | [**CreateDeviceKeyRequest**](CreateDeviceKeyRequest.md)|  | 

### Return type

[**DeviceKey**](DeviceKey.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createPublicUpload**
> createPublicUpload(token)

Send one whole file to a public album (tus 1.0 creation with upload)

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final token = token_example; // String | 

try {
    api_instance.createPublicUpload(token);
} catch (e) {
    print('Exception when calling DefaultApi->createPublicUpload: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **token** | **String**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createUpload**
> createUpload()

Create a resumable upload (tus 1.0). A body uploads the whole file in this request.

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    api_instance.createUpload();
} catch (e) {
    print('Exception when calling DefaultApi->createUpload: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createUser**
> User createUser(createUserRequest)

Create a user

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final createUserRequest = CreateUserRequest(); // CreateUserRequest | 

try {
    final result = api_instance.createUser(createUserRequest);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->createUser: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createUserRequest** | [**CreateUserRequest**](CreateUserRequest.md)|  | 

### Return type

[**User**](User.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteAlbum**
> deleteAlbum(id)

Delete an album, but not its photos. Owner only.

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.deleteAlbum(id);
} catch (e) {
    print('Exception when calling DefaultApi->deleteAlbum: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteAlbumComment**
> deleteAlbumComment(id, commentId)

Delete a comment. The author, an editor or the owner can do this.

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final commentId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.deleteAlbumComment(id, commentId);
} catch (e) {
    print('Exception when calling DefaultApi->deleteAlbumComment: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **commentId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteAlbumLink**
> deleteAlbumLink(id, linkId)

Revoke a public link. It stops working at once.

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final linkId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.deleteAlbumLink(id, linkId);
} catch (e) {
    print('Exception when calling DefaultApi->deleteAlbumLink: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **linkId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **disableTotp**
> disableTotp(passwordConfirm)

Turn off TOTP

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final passwordConfirm = PasswordConfirm(); // PasswordConfirm | 

try {
    api_instance.disableTotp(passwordConfirm);
} catch (e) {
    print('Exception when calling DefaultApi->disableTotp: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **passwordConfirm** | [**PasswordConfirm**](PasswordConfirm.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **downloadAssets**
> MultipartFile downloadAssets(ids)

Download several originals as one uncompressed ZIP file

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final ids = ids_example; // String | Comma-separated asset IDs, at most 100

try {
    final result = api_instance.downloadAssets(ids);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->downloadAssets: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **ids** | **String**| Comma-separated asset IDs, at most 100 | 

### Return type

[**MultipartFile**](MultipartFile.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/zip, application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **enableTotp**
> enableTotp(totpCode)

Confirm a code and turn on TOTP

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final totpCode = TotpCode(); // TotpCode | 

try {
    api_instance.enableTotp(totpCode);
} catch (e) {
    print('Exception when calling DefaultApi->enableTotp: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **totpCode** | [**TotpCode**](TotpCode.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAdminOverview**
> AdminOverview getAdminOverview()

Live statistics of the whole server, read from the database and the library disk

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.getAdminOverview();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getAdminOverview: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AdminOverview**](AdminOverview.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAlbum**
> Album getAlbum(id)

Read an album and its members

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getAlbum(id);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getAlbum: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**Album**](Album.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAlbumBucket**
> TimelineBucket getAlbumBucket(id, month)

Assets of one month in an album

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final month = month_example; // String | 

try {
    final result = api_instance.getAlbumBucket(id, month);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getAlbumBucket: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **month** | **String**|  | 

### Return type

[**TimelineBucket**](TimelineBucket.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAlbumBuckets**
> TimelineBuckets getAlbumBuckets(id)

Months in an album, in the album's order

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getAlbumBuckets(id);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getAlbumBuckets: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**TimelineBuckets**](TimelineBuckets.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAsset**
> AssetDetail getAsset(id)

Read an asset's details and its neighbours on the timeline

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getAsset(id);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getAsset: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**AssetDetail**](AssetDetail.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAssetMotion**
> MultipartFile getAssetMotion(id)

Read the video embedded in an Android Motion Photo

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getAssetMotion(id);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getAssetMotion: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**MultipartFile**](MultipartFile.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: video/mp4, application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAssetOriginal**
> MultipartFile getAssetOriginal(id, download)

Read the unmodified original. Supports Range requests for video.

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final download = true; // bool | 

try {
    final result = api_instance.getAssetOriginal(id, download);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getAssetOriginal: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **download** | **bool**|  | [optional] [default to false]

### Return type

[**MultipartFile**](MultipartFile.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/octet-stream, application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAssetThumbnail**
> MultipartFile getAssetThumbnail(id, size)

Read a WebP thumbnail

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final size = size_example; // String | 

try {
    final result = api_instance.getAssetThumbnail(id, size);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getAssetThumbnail: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **size** | **String**|  | [optional] [default to 'small']

### Return type

[**MultipartFile**](MultipartFile.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: image/webp, application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAssetVideoFile**
> MultipartFile getAssetVideoFile(id, file)

Read an HLS playlist or segment, or the scrub strip (sprite.jpg)

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final file = file_example; // String | 

try {
    final result = api_instance.getAssetVideoFile(id, file);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getAssetVideoFile: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **file** | **String**|  | 

### Return type

[**MultipartFile**](MultipartFile.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/octet-stream, application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAuthStatus**
> AuthStatus getAuthStatus()

Report whether setup is needed and who is signed in

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.getAuthStatus();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getAuthStatus: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AuthStatus**](AuthStatus.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getHealth**
> Health getHealth()

Report whether the server can reach its database

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.getHealth();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getHealth: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Health**](Health.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPartnerBucket**
> TimelineBucket getPartnerBucket(userId, month)

Assets of one month in a library shared with you

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final userId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final month = month_example; // String | 

try {
    final result = api_instance.getPartnerBucket(userId, month);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getPartnerBucket: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **String**|  | 
 **month** | **String**|  | 

### Return type

[**TimelineBucket**](TimelineBucket.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPartnerBuckets**
> TimelineBuckets getPartnerBuckets(userId)

Months in a library shared with you

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final userId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getPartnerBuckets(userId);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getPartnerBuckets: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **String**|  | 

### Return type

[**TimelineBuckets**](TimelineBuckets.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPublicAsset**
> AssetDetail getPublicAsset(token, id)

An asset in a public album, without what the link does not allow

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final token = token_example; // String | 
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getPublicAsset(token, id);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getPublicAsset: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **token** | **String**|  | 
 **id** | **String**|  | 

### Return type

[**AssetDetail**](AssetDetail.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPublicBucket**
> TimelineBucket getPublicBucket(token, month)

Assets of one month in a public album

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final token = token_example; // String | 
final month = month_example; // String | 

try {
    final result = api_instance.getPublicBucket(token, month);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getPublicBucket: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **token** | **String**|  | 
 **month** | **String**|  | 

### Return type

[**TimelineBucket**](TimelineBucket.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPublicBuckets**
> TimelineBuckets getPublicBuckets(token)

Months in a public album

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final token = token_example; // String | 

try {
    final result = api_instance.getPublicBuckets(token);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getPublicBuckets: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **token** | **String**|  | 

### Return type

[**TimelineBuckets**](TimelineBuckets.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPublicLink**
> PublicLink getPublicLink(token)

What a public link offers. Needs no account.

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final token = token_example; // String | 

try {
    final result = api_instance.getPublicLink(token);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getPublicLink: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **token** | **String**|  | 

### Return type

[**PublicLink**](PublicLink.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPublicMotion**
> MultipartFile getPublicMotion(token, id)

The video inside a Motion Photo in a public album

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final token = token_example; // String | 
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getPublicMotion(token, id);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getPublicMotion: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **token** | **String**|  | 
 **id** | **String**|  | 

### Return type

[**MultipartFile**](MultipartFile.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: video/mp4, application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPublicOriginal**
> MultipartFile getPublicOriginal(token, id, download)

Download an original. Counts toward the link's limit.

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final token = token_example; // String | 
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final download = true; // bool | 

try {
    final result = api_instance.getPublicOriginal(token, id, download);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getPublicOriginal: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **token** | **String**|  | 
 **id** | **String**|  | 
 **download** | **bool**|  | [optional] 

### Return type

[**MultipartFile**](MultipartFile.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/octet-stream, application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPublicThumbnail**
> MultipartFile getPublicThumbnail(token, id, size)

A preview from a public album, with the link's watermark if it has one

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final token = token_example; // String | 
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final size = size_example; // String | 

try {
    final result = api_instance.getPublicThumbnail(token, id, size);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getPublicThumbnail: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **token** | **String**|  | 
 **id** | **String**|  | 
 **size** | **String**|  | [optional] [default to 'small']

### Return type

[**MultipartFile**](MultipartFile.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: image/webp, application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPublicVideoFile**
> MultipartFile getPublicVideoFile(token, id, file)

HLS files of a video in a public album

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final token = token_example; // String | 
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final file = file_example; // String | 

try {
    final result = api_instance.getPublicVideoFile(token, id, file);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getPublicVideoFile: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **token** | **String**|  | 
 **id** | **String**|  | 
 **file** | **String**|  | 

### Return type

[**MultipartFile**](MultipartFile.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/octet-stream, application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getTimelineBucket**
> TimelineBucket getTimelineBucket(month)

List one month's assets, newest first

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final month = month_example; // String | YYYY-MM

try {
    final result = api_instance.getTimelineBucket(month);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getTimelineBucket: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **month** | **String**| YYYY-MM | 

### Return type

[**TimelineBucket**](TimelineBucket.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getTimelineBuckets**
> TimelineBuckets getTimelineBuckets()

List the months that have photos, newest first

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.getTimelineBuckets();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getTimelineBuckets: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**TimelineBuckets**](TimelineBuckets.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getUploadOffset**
> getUploadOffset(id)

Read how much of an upload has arrived (tus 1.0)

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = id_example; // String | 

try {
    api_instance.getUploadOffset(id);
} catch (e) {
    print('Exception when calling DefaultApi->getUploadOffset: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listAlbumComments**
> Activity listAlbumComments(id, assetId)

Comments on an album, or with assetId on one photo, and that photo's hearts

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final assetId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listAlbumComments(id, assetId);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->listAlbumComments: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **assetId** | **String**|  | [optional] 

### Return type

[**Activity**](Activity.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listAlbumLinks**
> List<ShareLink> listAlbumLinks(id)

Public links of an album. Owner only.

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.listAlbumLinks(id);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->listAlbumLinks: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**List<ShareLink>**](ShareLink.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listAlbums**
> List<Album> listAlbums(sort)

Albums the current user owns or that are shared with them

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final sort = sort_example; // String | 

try {
    final result = api_instance.listAlbums(sort);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->listAlbums: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **sort** | **String**|  | [optional] [default to 'updated']

### Return type

[**List<Album>**](Album.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listAssets**
> AssetList listAssets(limit, status)

List the current user's most recent assets and their processing status

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final limit = 56; // int | 
final status = status_example; // String | 

try {
    final result = api_instance.listAssets(limit, status);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->listAssets: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **limit** | **int**|  | [optional] [default to 50]
 **status** | **String**|  | [optional] 

### Return type

[**AssetList**](AssetList.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listCameras**
> List<String> listCameras()

Cameras in the current user's library, for smart album rules

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.listCameras();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->listCameras: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**List<String>**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listDirectory**
> List<UserRef> listDirectory()

The other users of this server, for choosing who to share with

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.listDirectory();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->listDirectory: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<UserRef>**](UserRef.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listPartners**
> Partners listPartners()

Who you share your library with, and who shares theirs with you

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.listPartners();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->listPartners: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Partners**](Partners.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listUsers**
> List<User> listUsers()

List users

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.listUsers();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->listUsers: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<User>**](User.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **login**
> User login(loginRequest)

Sign in with email, password and, when enabled, a TOTP code

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final loginRequest = LoginRequest(); // LoginRequest | 

try {
    final result = api_instance.login(loginRequest);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->login: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **loginRequest** | [**LoginRequest**](LoginRequest.md)|  | 

### Return type

[**User**](User.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **logout**
> logout()

End the current session

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    api_instance.logout();
} catch (e) {
    print('Exception when calling DefaultApi->logout: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **removeAlbumAssets**
> BulkResponse removeAlbumAssets(id, assetIds)

Remove assets from an album. A contributor can remove only what they added.

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final assetIds = AssetIds(); // AssetIds | 

try {
    final result = api_instance.removeAlbumAssets(id, assetIds);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->removeAlbumAssets: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **assetIds** | [**AssetIds**](AssetIds.md)|  | 

### Return type

[**BulkResponse**](BulkResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **removeAlbumHeart**
> removeAlbumHeart(id, assetId)

Take back your heart

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final assetId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.removeAlbumHeart(id, assetId);
} catch (e) {
    print('Exception when calling DefaultApi->removeAlbumHeart: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **assetId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **removeAlbumMember**
> removeAlbumMember(id, userId)

End a user's access. The owner can remove anyone, and a member can leave.

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final userId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.removeAlbumMember(id, userId);
} catch (e) {
    print('Exception when calling DefaultApi->removeAlbumMember: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **userId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **removePartner**
> removePartner(userId)

Stop sharing your library with a user

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final userId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.removePartner(userId);
} catch (e) {
    print('Exception when calling DefaultApi->removePartner: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **revokeDeviceKey**
> revokeDeviceKey(id)

Revoke one of the current user's device keys

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.revokeDeviceKey(id);
} catch (e) {
    print('Exception when calling DefaultApi->revokeDeviceKey: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **setAlbumHeart**
> setAlbumHeart(id, assetId)

Add your heart to a photo in an album

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final assetId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.setAlbumHeart(id, assetId);
} catch (e) {
    print('Exception when calling DefaultApi->setAlbumHeart: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **assetId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **setAlbumMember**
> setAlbumMember(id, userId, memberRole)

Share an album with a user or change their role. Owner only.

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final userId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final memberRole = MemberRole(); // MemberRole | 

try {
    api_instance.setAlbumMember(id, userId, memberRole);
} catch (e) {
    print('Exception when calling DefaultApi->setAlbumMember: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **userId** | **String**|  | 
 **memberRole** | [**MemberRole**](MemberRole.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **setPartner**
> setPartner(userId, partnerShare)

Share your library with a user, all of it or from a date

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final userId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final partnerShare = PartnerShare(); // PartnerShare | 

try {
    api_instance.setPartner(userId, partnerShare);
} catch (e) {
    print('Exception when calling DefaultApi->setPartner: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **String**|  | 
 **partnerShare** | [**PartnerShare**](PartnerShare.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **setPartnerTimeline**
> setPartnerTimeline(userId, partnerTimeline)

Choose whether a partner's photos also appear in your timeline

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final userId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final partnerTimeline = PartnerTimeline(); // PartnerTimeline | 

try {
    api_instance.setPartnerTimeline(userId, partnerTimeline);
} catch (e) {
    print('Exception when calling DefaultApi->setPartnerTimeline: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **String**|  | 
 **partnerTimeline** | [**PartnerTimeline**](PartnerTimeline.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **setup**
> User setup(setupRequest)

Create the first administrator. Closed once any user exists.

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final setupRequest = SetupRequest(); // SetupRequest | 

try {
    final result = api_instance.setup(setupRequest);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->setup: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **setupRequest** | [**SetupRequest**](SetupRequest.md)|  | 

### Return type

[**User**](User.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **setupTotp**
> TotpSetup setupTotp()

Generate a TOTP secret. It takes effect only after confirmation.

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.setupTotp();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->setupTotp: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**TotpSetup**](TotpSetup.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **unlockPublicLink**
> unlockPublicLink(token, linkPassword)

Send a link's password. Success sets a cookie valid only for this link.

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final token = token_example; // String | 
final linkPassword = LinkPassword(); // LinkPassword | 

try {
    api_instance.unlockPublicLink(token, linkPassword);
} catch (e) {
    print('Exception when calling DefaultApi->unlockPublicLink: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **token** | **String**|  | 
 **linkPassword** | [**LinkPassword**](LinkPassword.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateAlbum**
> Album updateAlbum(id, albumUpdate)

Change an album. Needs the editor role.

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final albumUpdate = AlbumUpdate(); // AlbumUpdate | 

try {
    final result = api_instance.updateAlbum(id, albumUpdate);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->updateAlbum: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **albumUpdate** | [**AlbumUpdate**](AlbumUpdate.md)|  | 

### Return type

[**Album**](Album.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)


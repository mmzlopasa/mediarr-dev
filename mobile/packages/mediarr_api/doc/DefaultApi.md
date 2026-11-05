# mediarr_api.api.DefaultApi

## Load the API package
```dart
import 'package:mediarr_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**addAlbumAssets**](DefaultApi.md#addalbumassets) | **POST** /api/albums/{id}/assets | Add your own assets to an album. Needs the contributor role.
[**addFamilyMember**](DefaultApi.md#addfamilymember) | **PUT** /api/admin/family/{userId} | Add someone to the family library
[**appendUpload**](DefaultApi.md#appendupload) | **PATCH** /api/uploads/{id} | Append data to an upload (tus 1.0). The last chunk returns X-Asset-Id.
[**approveDevice**](DefaultApi.md#approvedevice) | **POST** /api/admin/security/devices/{id}/approve | Let this device sign in
[**askSearch**](DefaultApi.md#asksearch) | **POST** /api/search/ask | Turn a question into words to search for, with the local model
[**beginPasskeyLogin**](DefaultApi.md#beginpasskeylogin) | **POST** /api/auth/passkey/begin | Start signing in with a passkey
[**beginPasskeyRegistration**](DefaultApi.md#beginpasskeyregistration) | **POST** /api/me/passkeys/begin | Start adding a passkey, which takes the account's password
[**bulkAssets**](DefaultApi.md#bulkassets) | **POST** /api/assets/bulk | Apply an action to several of the current user's assets. Other assets are ignored.
[**cancelImport**](DefaultApi.md#cancelimport) | **POST** /api/admin/imports/{id}/cancel | Stop an import. What it has brought in stays
[**cancelUpload**](DefaultApi.md#cancelupload) | **DELETE** /api/uploads/{id} | Cancel an upload (tus 1.0)
[**changeAssetTags**](DefaultApi.md#changeassettags) | **POST** /api/assets/tags | Add a tag to the user's own assets, or remove it
[**changePassword**](DefaultApi.md#changepassword) | **POST** /api/me/password | Change the current user's password and end their other sessions
[**checkAssets**](DefaultApi.md#checkassets) | **POST** /api/assets/check | Report which SHA-256 checksums the current user already has, so uploads can be skipped
[**clearAssetEdits**](DefaultApi.md#clearassetedits) | **DELETE** /api/assets/{id}/edits | Go back to the photo as it was taken
[**createAPIKey**](DefaultApi.md#createapikey) | **POST** /api/me/api-keys | Create a key with chosen rights. It is shown only once
[**createAlbum**](DefaultApi.md#createalbum) | **POST** /api/albums | Create an album. With rules it is a smart album.
[**createAlbumComment**](DefaultApi.md#createalbumcomment) | **POST** /api/albums/{id}/comments | Comment on an album or on a photo in it
[**createAlbumLink**](DefaultApi.md#createalbumlink) | **POST** /api/albums/{id}/links | Create a public link. Its token is returned only this once.
[**createDeviceKey**](DefaultApi.md#createdevicekey) | **POST** /api/me/device-keys | Create a long-lived key for this device, used by background backup
[**createFamilyRule**](DefaultApi.md#createfamilyrule) | **POST** /api/family/rules | Share what matches a rule with the family. Photos are not copied
[**createImport**](DefaultApi.md#createimport) | **POST** /api/admin/imports | Bring a library in from Immich, Google Takeout or an iCloud export
[**createPublicUpload**](DefaultApi.md#createpublicupload) | **POST** /api/public/{token}/uploads | Send one whole file to a public album (tus 1.0 creation with upload)
[**createStoryExport**](DefaultApi.md#createstoryexport) | **POST** /api/stories | Make a video of the chosen photos. Runs in the background.
[**createUpload**](DefaultApi.md#createupload) | **POST** /api/uploads | Create a resumable upload (tus 1.0). A body uploads the whole file in this request.
[**createUser**](DefaultApi.md#createuser) | **POST** /api/admin/users | Create a user
[**createWebhook**](DefaultApi.md#createwebhook) | **POST** /api/admin/webhooks | Add an address. Its signing secret is shown only once
[**deleteAlbum**](DefaultApi.md#deletealbum) | **DELETE** /api/albums/{id} | Delete an album, but not its photos. Owner only.
[**deleteAlbumComment**](DefaultApi.md#deletealbumcomment) | **DELETE** /api/albums/{id}/comments/{commentId} | Delete a comment. The author, an editor or the owner can do this.
[**deleteAlbumLink**](DefaultApi.md#deletealbumlink) | **DELETE** /api/albums/{id}/links/{linkId} | Revoke a public link. It stops working at once.
[**deleteDevice**](DefaultApi.md#deletedevice) | **DELETE** /api/admin/security/devices/{id} | Forget this device, which then has to be approved again
[**deleteFamilyRule**](DefaultApi.md#deletefamilyrule) | **DELETE** /api/family/rules/{id} | Stop sharing what this rule covers
[**deletePasskey**](DefaultApi.md#deletepasskey) | **DELETE** /api/me/passkeys/{id} | Remove a passkey
[**deleteTag**](DefaultApi.md#deletetag) | **DELETE** /api/tags/{id} | Delete a tag. The photos stay.
[**deleteWebhook**](DefaultApi.md#deletewebhook) | **DELETE** /api/admin/webhooks/{id} | Stop telling this address
[**disableTotp**](DefaultApi.md#disabletotp) | **POST** /api/me/totp/disable | Turn off TOTP
[**dismissDuplicates**](DefaultApi.md#dismissduplicates) | **POST** /api/duplicates/dismiss | These photos are not duplicates of each other, and are not proposed again
[**dissolveStack**](DefaultApi.md#dissolvestack) | **DELETE** /api/assets/{id}/stack | Split a stack back into single shots. It is not put together again by itself
[**downloadAssets**](DefaultApi.md#downloadassets) | **GET** /api/assets/download | Download several originals as one uncompressed ZIP file
[**emptyTrash**](DefaultApi.md#emptytrash) | **POST** /api/trash/empty | Permanently delete everything in the trash
[**enableTotp**](DefaultApi.md#enabletotp) | **POST** /api/me/totp/enable | Confirm a code and turn on TOTP
[**endOtherSessions**](DefaultApi.md#endothersessions) | **DELETE** /api/me/sessions | Sign out everywhere except here
[**endSession**](DefaultApi.md#endsession) | **DELETE** /api/me/sessions/{id} | Sign out one device
[**exchangeOIDC**](DefaultApi.md#exchangeoidc) | **POST** /api/auth/oidc/exchange | The app turns a one-time code into a session
[**finishOIDC**](DefaultApi.md#finishoidc) | **GET** /api/auth/oidc/callback | Where the identity provider sends the browser back
[**finishPasskeyLogin**](DefaultApi.md#finishpasskeylogin) | **POST** /api/auth/passkey/finish | Finish signing in with a passkey
[**finishPasskeyRegistration**](DefaultApi.md#finishpasskeyregistration) | **POST** /api/me/passkeys/finish | Finish adding a passkey
[**getAISettings**](DefaultApi.md#getaisettings) | **GET** /api/admin/ai | The local Ollama server and how far descriptions have come
[**getAdminHealth**](DefaultApi.md#getadminhealth) | **GET** /api/admin/health | Whether the worker and the analysis service are running
[**getAdminJobs**](DefaultApi.md#getadminjobs) | **GET** /api/admin/jobs | The job queues, and the jobs that gave up
[**getAdminOverview**](DefaultApi.md#getadminoverview) | **GET** /api/admin/overview | Live statistics of the whole server, read from the database and the library disk
[**getAdminStorage**](DefaultApi.md#getadminstorage) | **GET** /api/admin/storage | How much each user stores
[**getAlbum**](DefaultApi.md#getalbum) | **GET** /api/albums/{id} | Read an album and its members
[**getAlbumBucket**](DefaultApi.md#getalbumbucket) | **GET** /api/albums/{id}/buckets/{month} | Assets of one month in an album
[**getAlbumBuckets**](DefaultApi.md#getalbumbuckets) | **GET** /api/albums/{id}/buckets | Months in an album, in the album's order
[**getAnalysisProgress**](DefaultApi.md#getanalysisprogress) | **GET** /api/admin/analysis | How far picture analysis has come. Administrators only.
[**getAsset**](DefaultApi.md#getasset) | **GET** /api/assets/{id} | Read an asset's details and its neighbours on the timeline
[**getAssetMotion**](DefaultApi.md#getassetmotion) | **GET** /api/assets/{id}/motion | Read the video embedded in an Android Motion Photo
[**getAssetOriginal**](DefaultApi.md#getassetoriginal) | **GET** /api/assets/{id}/original | Read the unmodified original. Supports Range requests for video.
[**getAssetThumbnail**](DefaultApi.md#getassetthumbnail) | **GET** /api/assets/{id}/thumbnail | Read a WebP thumbnail
[**getAssetVideoFile**](DefaultApi.md#getassetvideofile) | **GET** /api/assets/{id}/video/{file} | Read an HLS playlist or segment, or the scrub strip (sprite.jpg)
[**getAuthMethods**](DefaultApi.md#getauthmethods) | **GET** /api/auth/methods | The ways of signing in that this address offers, besides a password
[**getAuthStatus**](DefaultApi.md#getauthstatus) | **GET** /api/auth/status | Report whether setup is needed and who is signed in
[**getBackupSettings**](DefaultApi.md#getbackupsettings) | **GET** /api/admin/backup | Where backups go, without any secret
[**getCollectionAsset**](DefaultApi.md#getcollectionasset) | **GET** /api/collections/{scope}/assets/{id} | An asset in a collection
[**getCollectionBucket**](DefaultApi.md#getcollectionbucket) | **GET** /api/collections/{scope}/buckets/{month} | Assets of one month in a collection
[**getCollectionBuckets**](DefaultApi.md#getcollectionbuckets) | **GET** /api/collections/{scope}/buckets | Months in the archive, the trash or the unlocked vault
[**getCollectionMotion**](DefaultApi.md#getcollectionmotion) | **GET** /api/collections/{scope}/assets/{id}/motion | The video inside a Motion Photo in a collection
[**getCollectionOriginal**](DefaultApi.md#getcollectionoriginal) | **GET** /api/collections/{scope}/assets/{id}/original | The original of an asset in a collection
[**getCollectionThumbnail**](DefaultApi.md#getcollectionthumbnail) | **GET** /api/collections/{scope}/assets/{id}/thumbnail | A preview of an asset in a collection
[**getCollectionVideoFile**](DefaultApi.md#getcollectionvideofile) | **GET** /api/collections/{scope}/assets/{id}/video/{file} | HLS files of a video in a collection
[**getDocuments**](DefaultApi.md#getdocuments) | **GET** /api/documents | Photos of documents, found by the text on them
[**getExternalLibrary**](DefaultApi.md#getexternallibrary) | **GET** /api/admin/external | The folder given as EXTERNAL_LIBRARY_PATH, and how it is doing
[**getFamily**](DefaultApi.md#getfamily) | **GET** /api/family | The family library, and what this user shares with it
[**getFamilyBucket**](DefaultApi.md#getfamilybucket) | **GET** /api/family/buckets/{month} | Assets of one month in the family library
[**getFamilyBuckets**](DefaultApi.md#getfamilybuckets) | **GET** /api/family/buckets | Months in the family library
[**getFeatures**](DefaultApi.md#getfeatures) | **GET** /api/features | Which additions the administrator has turned on
[**getFolder**](DefaultApi.md#getfolder) | **GET** /api/folders | One folder of the external library, for the user who owns it
[**getHealth**](DefaultApi.md#gethealth) | **GET** /health | Report whether the server can reach its database
[**getMapPoints**](DefaultApi.md#getmappoints) | **GET** /api/map/points | Photos with a location that this user may see, oldest first
[**getMapStyle**](DefaultApi.md#getmapstyle) | **GET** /api/map/style | Where the map's background comes from
[**getMapTrips**](DefaultApi.md#getmaptrips) | **GET** /api/map/trips | Journeys found from the time and distance between photos
[**getMyStats**](DefaultApi.md#getmystats) | **GET** /api/me/stats | How much this account holds
[**getOIDCSettings**](DefaultApi.md#getoidcsettings) | **GET** /api/admin/oidc | Single sign-on settings, without the secret
[**getPartnerBucket**](DefaultApi.md#getpartnerbucket) | **GET** /api/partners/{userId}/buckets/{month} | Assets of one month in a library shared with you
[**getPartnerBuckets**](DefaultApi.md#getpartnerbuckets) | **GET** /api/partners/{userId}/buckets | Months in a library shared with you
[**getPersonBucket**](DefaultApi.md#getpersonbucket) | **GET** /api/people/{id}/buckets/{month} | Photos of this person in one month
[**getPersonBuckets**](DefaultApi.md#getpersonbuckets) | **GET** /api/people/{id}/buckets | Months with this person
[**getPersonThumbnail**](DefaultApi.md#getpersonthumbnail) | **GET** /api/people/{id}/thumbnail | A picture of this person's face
[**getPublicAsset**](DefaultApi.md#getpublicasset) | **GET** /api/public/{token}/assets/{id} | An asset in a public album, without what the link does not allow
[**getPublicBucket**](DefaultApi.md#getpublicbucket) | **GET** /api/public/{token}/buckets/{month} | Assets of one month in a public album
[**getPublicBuckets**](DefaultApi.md#getpublicbuckets) | **GET** /api/public/{token}/buckets | Months in a public album
[**getPublicLink**](DefaultApi.md#getpubliclink) | **GET** /api/public/{token} | What a public link offers. Needs no account.
[**getPublicMotion**](DefaultApi.md#getpublicmotion) | **GET** /api/public/{token}/assets/{id}/motion | The video inside a Motion Photo in a public album
[**getPublicOriginal**](DefaultApi.md#getpublicoriginal) | **GET** /api/public/{token}/assets/{id}/original | Download an original. Counts toward the link's limit.
[**getPublicThumbnail**](DefaultApi.md#getpublicthumbnail) | **GET** /api/public/{token}/assets/{id}/thumbnail | A preview from a public album, with the link's watermark if it has one
[**getPublicVideoFile**](DefaultApi.md#getpublicvideofile) | **GET** /api/public/{token}/assets/{id}/video/{file} | HLS files of a video in a public album
[**getSecurity**](DefaultApi.md#getsecurity) | **GET** /api/admin/security | Who may reach this server, and the devices that have tried
[**getServerStatus**](DefaultApi.md#getserverstatus) | **GET** /api/server/status | The version of this server, whether a newer one exists, and its disk
[**getStoryExport**](DefaultApi.md#getstoryexport) | **GET** /api/stories/{id} | How a video is coming along
[**getStoryVideo**](DefaultApi.md#getstoryvideo) | **GET** /api/stories/{id}/video | The finished video
[**getTagBucket**](DefaultApi.md#gettagbucket) | **GET** /api/tags/{id}/buckets/{month} | Photos carrying a tag in one month
[**getTagBuckets**](DefaultApi.md#gettagbuckets) | **GET** /api/tags/{id}/buckets | Months with photos carrying a tag
[**getTimelineBucket**](DefaultApi.md#gettimelinebucket) | **GET** /api/timeline/buckets/{month} | List one month's assets, newest first
[**getTimelineBuckets**](DefaultApi.md#gettimelinebuckets) | **GET** /api/timeline/buckets | List the months that have photos, newest first
[**getTrashSummary**](DefaultApi.md#gettrashsummary) | **GET** /api/trash/summary | What emptying the trash would remove
[**getUploadOffset**](DefaultApi.md#getuploadoffset) | **HEAD** /api/uploads/{id} | Read how much of an upload has arrived (tus 1.0)
[**getVaultStatus**](DefaultApi.md#getvaultstatus) | **GET** /api/vault/status | Whether the vault has a PIN and is unlocked
[**listAPIKeys**](DefaultApi.md#listapikeys) | **GET** /api/me/api-keys | The current user's keys, without the keys themselves
[**listAlbumComments**](DefaultApi.md#listalbumcomments) | **GET** /api/albums/{id}/comments | Comments on an album, or with assetId on one photo, and that photo's hearts
[**listAlbumLinks**](DefaultApi.md#listalbumlinks) | **GET** /api/albums/{id}/links | Public links of an album. Owner only.
[**listAlbums**](DefaultApi.md#listalbums) | **GET** /api/albums | Albums the current user owns or that are shared with them
[**listAssets**](DefaultApi.md#listassets) | **GET** /api/assets | List the current user's most recent assets and their processing status
[**listAuditLog**](DefaultApi.md#listauditlog) | **GET** /api/admin/audit | Who changed what, newest first. Never the content of a request
[**listBackupRuns**](DefaultApi.md#listbackupruns) | **GET** /api/admin/backup/runs | Backups and tests of bringing one back, the newest first
[**listCameras**](DefaultApi.md#listcameras) | **GET** /api/albums/cameras | Cameras in the current user's library, for smart album rules
[**listDirectory**](DefaultApi.md#listdirectory) | **GET** /api/users/directory | The other users of this server, for choosing who to share with
[**listDuplicates**](DefaultApi.md#listduplicates) | **GET** /api/duplicates | Groups of photos that look alike. Only a proposal, nothing is removed without asking
[**listFamilyMembersAdmin**](DefaultApi.md#listfamilymembersadmin) | **GET** /api/admin/family | Who is in the family library
[**listImports**](DefaultApi.md#listimports) | **GET** /api/admin/imports | Imports, the newest first
[**listMemories**](DefaultApi.md#listmemories) | **GET** /api/memories | On this day in earlier years, and the last week
[**listMySessions**](DefaultApi.md#listmysessions) | **GET** /api/me/sessions | Where this account is signed in
[**listPartners**](DefaultApi.md#listpartners) | **GET** /api/partners | Who you share your library with, and who shares theirs with you
[**listPasskeys**](DefaultApi.md#listpasskeys) | **GET** /api/me/passkeys | The current user's passkeys
[**listPeople**](DefaultApi.md#listpeople) | **GET** /api/people | People recognised in the current user's library
[**listSecurityEvents**](DefaultApi.md#listsecurityevents) | **GET** /api/admin/security/events | Attempts to get in, newest first
[**listTags**](DefaultApi.md#listtags) | **GET** /api/tags | The current user's tags
[**listUsers**](DefaultApi.md#listusers) | **GET** /api/admin/users | List users
[**listWebhooks**](DefaultApi.md#listwebhooks) | **GET** /api/admin/webhooks | Addresses told about events, without their secrets
[**lockVault**](DefaultApi.md#lockvault) | **POST** /api/vault/lock | Lock the vault again
[**login**](DefaultApi.md#login) | **POST** /api/auth/login | Sign in with email, password and, when enabled, a TOTP code
[**logout**](DefaultApi.md#logout) | **POST** /api/auth/logout | End the current session
[**mergePeople**](DefaultApi.md#mergepeople) | **POST** /api/people/{id}/merge | Treat other people as this one
[**pauseJobQueue**](DefaultApi.md#pausejobqueue) | **POST** /api/admin/jobs/queues/{queue}/pause | Stop starting jobs from this queue
[**removeAlbumAssets**](DefaultApi.md#removealbumassets) | **POST** /api/albums/{id}/assets/remove | Remove assets from an album. A contributor can remove only what they added.
[**removeAlbumHeart**](DefaultApi.md#removealbumheart) | **DELETE** /api/albums/{id}/assets/{assetId}/heart | Take back your heart
[**removeAlbumMember**](DefaultApi.md#removealbummember) | **DELETE** /api/albums/{id}/members/{userId} | End a user's access. The owner can remove anyone, and a member can leave.
[**removeFamilyMember**](DefaultApi.md#removefamilymember) | **DELETE** /api/admin/family/{userId} | Remove someone. Their photos stay in their own library
[**removePartner**](DefaultApi.md#removepartner) | **DELETE** /api/partners/{userId} | Stop sharing your library with a user
[**resumeJobQueue**](DefaultApi.md#resumejobqueue) | **POST** /api/admin/jobs/queues/{queue}/resume | Continue a paused queue
[**retryJob**](DefaultApi.md#retryjob) | **POST** /api/admin/jobs/{id}/retry | Try a failed job again
[**revokeDeviceKey**](DefaultApi.md#revokedevicekey) | **DELETE** /api/me/device-keys/{id} | Revoke one of the current user's device keys
[**scanExternalLibrary**](DefaultApi.md#scanexternallibrary) | **POST** /api/admin/external/scan | Look through the folder for changes now
[**searchAssets**](DefaultApi.md#searchassets) | **GET** /api/search | Search in natural language. Dates, people, places and cameras in the query become filters.
[**setAISettings**](DefaultApi.md#setaisettings) | **PUT** /api/admin/ai | Name the Ollama server. Previews of photos are sent to it
[**setAlbumHeart**](DefaultApi.md#setalbumheart) | **PUT** /api/albums/{id}/assets/{assetId}/heart | Add your heart to a photo in an album
[**setAlbumMember**](DefaultApi.md#setalbummember) | **PUT** /api/albums/{id}/members/{userId} | Share an album with a user or change their role. Owner only.
[**setAssetEdits**](DefaultApi.md#setassetedits) | **PUT** /api/assets/{id}/edits | Replace the list of edits of a photo. The original is never changed
[**setBackupSettings**](DefaultApi.md#setbackupsettings) | **PUT** /api/admin/backup | Change where backups go. A secret left out stays as it was
[**setExternalLibrary**](DefaultApi.md#setexternallibrary) | **PUT** /api/admin/external | Choose whose photos the folder holds, and start reading it
[**setFeature**](DefaultApi.md#setfeature) | **PUT** /api/admin/features/{name} | Turn an addition on or off
[**setMapStyle**](DefaultApi.md#setmapstyle) | **PUT** /api/map/style | Choose the map's background. Administrators only. Empty goes back to the default.
[**setOIDCSettings**](DefaultApi.md#setoidcsettings) | **PUT** /api/admin/oidc | Change single sign-on. An empty issuer turns it off
[**setPartner**](DefaultApi.md#setpartner) | **PUT** /api/partners/{userId} | Share your library with a user, all of it or from a date
[**setPartnerTimeline**](DefaultApi.md#setpartnertimeline) | **PUT** /api/partners/{userId}/timeline | Choose whether a partner's photos also appear in your timeline
[**setSecurity**](DefaultApi.md#setsecurity) | **PUT** /api/admin/security | Change the rules. Refused if it would lock out the person asking
[**setStackMain**](DefaultApi.md#setstackmain) | **PUT** /api/assets/{id}/stack/main | Make this shot the one the timeline shows
[**setUserQuota**](DefaultApi.md#setuserquota) | **PUT** /api/admin/users/{id}/quota | Set how much a user may store. Without a value there is no limit
[**setVaultPin**](DefaultApi.md#setvaultpin) | **POST** /api/vault/pin | Set the vault PIN. Changing it needs the current one.
[**setup**](DefaultApi.md#setup) | **POST** /api/auth/setup | Create the first administrator. Closed once any user exists.
[**setupTotp**](DefaultApi.md#setuptotp) | **POST** /api/me/totp/setup | Generate a TOTP secret. It takes effect only after confirmation.
[**startBackupRun**](DefaultApi.md#startbackuprun) | **POST** /api/admin/backup/runs | Back up now, or test bringing the newest backup back
[**startOIDC**](DefaultApi.md#startoidc) | **GET** /api/auth/oidc/start | Go to the identity provider
[**testWebhook**](DefaultApi.md#testwebhook) | **POST** /api/admin/webhooks/{id}/test | Send a test event now
[**unlockPublicLink**](DefaultApi.md#unlockpubliclink) | **POST** /api/public/{token}/unlock | Send a link's password. Success sets a cookie valid only for this link.
[**unlockVault**](DefaultApi.md#unlockvault) | **POST** /api/vault/unlock | Unlock the vault for a short time
[**updateAlbum**](DefaultApi.md#updatealbum) | **PATCH** /api/albums/{id} | Change an album. Needs the editor role.
[**updatePerson**](DefaultApi.md#updateperson) | **PATCH** /api/people/{id} | Name or hide a person


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

# **addFamilyMember**
> addFamilyMember(userId)

Add someone to the family library

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final userId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.addFamilyMember(userId);
} catch (e) {
    print('Exception when calling DefaultApi->addFamilyMember: $e\n');
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

# **approveDevice**
> approveDevice(id)

Let this device sign in

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.approveDevice(id);
} catch (e) {
    print('Exception when calling DefaultApi->approveDevice: $e\n');
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

# **askSearch**
> AskAnswer askSearch(askRequest)

Turn a question into words to search for, with the local model

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final askRequest = AskRequest(); // AskRequest | 

try {
    final result = api_instance.askSearch(askRequest);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->askSearch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **askRequest** | [**AskRequest**](AskRequest.md)|  | 

### Return type

[**AskAnswer**](AskAnswer.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **beginPasskeyLogin**
> Map<String, Object> beginPasskeyLogin(requestBody)

Start signing in with a passkey

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final requestBody = Map<String, Object>(); // Map<String, Object> | 

try {
    final result = api_instance.beginPasskeyLogin(requestBody);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->beginPasskeyLogin: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **requestBody** | [**Map<String, Object>**](Object.md)|  | [optional] 

### Return type

[**Map<String, Object>**](Object.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **beginPasskeyRegistration**
> Map<String, Object> beginPasskeyRegistration(passwordConfirm)

Start adding a passkey, which takes the account's password

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final passwordConfirm = PasswordConfirm(); // PasswordConfirm | 

try {
    final result = api_instance.beginPasskeyRegistration(passwordConfirm);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->beginPasskeyRegistration: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **passwordConfirm** | [**PasswordConfirm**](PasswordConfirm.md)|  | 

### Return type

[**Map<String, Object>**](Object.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
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

# **cancelImport**
> cancelImport(id)

Stop an import. What it has brought in stays

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.cancelImport(id);
} catch (e) {
    print('Exception when calling DefaultApi->cancelImport: $e\n');
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

# **changeAssetTags**
> BulkResponse changeAssetTags(assetTagChange)

Add a tag to the user's own assets, or remove it

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final assetTagChange = AssetTagChange(); // AssetTagChange | 

try {
    final result = api_instance.changeAssetTags(assetTagChange);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->changeAssetTags: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **assetTagChange** | [**AssetTagChange**](AssetTagChange.md)|  | 

### Return type

[**BulkResponse**](BulkResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
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

# **clearAssetEdits**
> clearAssetEdits(id)

Go back to the photo as it was taken

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.clearAssetEdits(id);
} catch (e) {
    print('Exception when calling DefaultApi->clearAssetEdits: $e\n');
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

# **createAPIKey**
> DeviceKey createAPIKey(apiKeyCreate)

Create a key with chosen rights. It is shown only once

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final apiKeyCreate = ApiKeyCreate(); // ApiKeyCreate | 

try {
    final result = api_instance.createAPIKey(apiKeyCreate);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->createAPIKey: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **apiKeyCreate** | [**ApiKeyCreate**](ApiKeyCreate.md)|  | 

### Return type

[**DeviceKey**](DeviceKey.md)

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

# **createFamilyRule**
> Map<String, String> createFamilyRule(familyRuleCreate)

Share what matches a rule with the family. Photos are not copied

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final familyRuleCreate = FamilyRuleCreate(); // FamilyRuleCreate | 

try {
    final result = api_instance.createFamilyRule(familyRuleCreate);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->createFamilyRule: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **familyRuleCreate** | [**FamilyRuleCreate**](FamilyRuleCreate.md)|  | 

### Return type

**Map<String, String>**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createImport**
> Map<String, String> createImport(importCreate)

Bring a library in from Immich, Google Takeout or an iCloud export

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final importCreate = ImportCreate(); // ImportCreate | 

try {
    final result = api_instance.createImport(importCreate);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->createImport: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **importCreate** | [**ImportCreate**](ImportCreate.md)|  | 

### Return type

**Map<String, String>**

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

# **createStoryExport**
> StoryExport createStoryExport(storyRequest)

Make a video of the chosen photos. Runs in the background.

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final storyRequest = StoryRequest(); // StoryRequest | 

try {
    final result = api_instance.createStoryExport(storyRequest);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->createStoryExport: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **storyRequest** | [**StoryRequest**](StoryRequest.md)|  | 

### Return type

[**StoryExport**](StoryExport.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
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

# **createWebhook**
> WebhookCreated createWebhook(webhookCreate)

Add an address. Its signing secret is shown only once

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final webhookCreate = WebhookCreate(); // WebhookCreate | 

try {
    final result = api_instance.createWebhook(webhookCreate);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->createWebhook: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **webhookCreate** | [**WebhookCreate**](WebhookCreate.md)|  | 

### Return type

[**WebhookCreated**](WebhookCreated.md)

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

# **deleteDevice**
> deleteDevice(id)

Forget this device, which then has to be approved again

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.deleteDevice(id);
} catch (e) {
    print('Exception when calling DefaultApi->deleteDevice: $e\n');
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

# **deleteFamilyRule**
> deleteFamilyRule(id)

Stop sharing what this rule covers

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.deleteFamilyRule(id);
} catch (e) {
    print('Exception when calling DefaultApi->deleteFamilyRule: $e\n');
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

# **deletePasskey**
> deletePasskey(id)

Remove a passkey

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.deletePasskey(id);
} catch (e) {
    print('Exception when calling DefaultApi->deletePasskey: $e\n');
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

# **deleteTag**
> deleteTag(id)

Delete a tag. The photos stay.

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.deleteTag(id);
} catch (e) {
    print('Exception when calling DefaultApi->deleteTag: $e\n');
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

# **deleteWebhook**
> deleteWebhook(id)

Stop telling this address

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.deleteWebhook(id);
} catch (e) {
    print('Exception when calling DefaultApi->deleteWebhook: $e\n');
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

# **dismissDuplicates**
> dismissDuplicates(assetIds)

These photos are not duplicates of each other, and are not proposed again

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final assetIds = AssetIds(); // AssetIds | 

try {
    api_instance.dismissDuplicates(assetIds);
} catch (e) {
    print('Exception when calling DefaultApi->dismissDuplicates: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **assetIds** | [**AssetIds**](AssetIds.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **dissolveStack**
> dissolveStack(id)

Split a stack back into single shots. It is not put together again by itself

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.dissolveStack(id);
} catch (e) {
    print('Exception when calling DefaultApi->dissolveStack: $e\n');
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

# **emptyTrash**
> BulkResponse emptyTrash()

Permanently delete everything in the trash

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.emptyTrash();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->emptyTrash: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**BulkResponse**](BulkResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

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

# **endOtherSessions**
> endOtherSessions()

Sign out everywhere except here

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    api_instance.endOtherSessions();
} catch (e) {
    print('Exception when calling DefaultApi->endOtherSessions: $e\n');
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

# **endSession**
> endSession(id)

Sign out one device

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.endSession(id);
} catch (e) {
    print('Exception when calling DefaultApi->endSession: $e\n');
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

# **exchangeOIDC**
> User exchangeOIDC(oIDCExchange)

The app turns a one-time code into a session

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final oIDCExchange = OIDCExchange(); // OIDCExchange | 

try {
    final result = api_instance.exchangeOIDC(oIDCExchange);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->exchangeOIDC: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **oIDCExchange** | [**OIDCExchange**](OIDCExchange.md)|  | 

### Return type

[**User**](User.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **finishOIDC**
> finishOIDC(code, state)

Where the identity provider sends the browser back

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final code = code_example; // String | 
final state = state_example; // String | 

try {
    api_instance.finishOIDC(code, state);
} catch (e) {
    print('Exception when calling DefaultApi->finishOIDC: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **code** | **String**|  | [optional] 
 **state** | **String**|  | [optional] 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **finishPasskeyLogin**
> Map<String, Object> finishPasskeyLogin(requestBody)

Finish signing in with a passkey

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final requestBody = Map<String, Object>(); // Map<String, Object> | 

try {
    final result = api_instance.finishPasskeyLogin(requestBody);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->finishPasskeyLogin: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **requestBody** | [**Map<String, Object>**](Object.md)|  | [optional] 

### Return type

[**Map<String, Object>**](Object.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **finishPasskeyRegistration**
> Map<String, Object> finishPasskeyRegistration(requestBody)

Finish adding a passkey

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final requestBody = Map<String, Object>(); // Map<String, Object> | 

try {
    final result = api_instance.finishPasskeyRegistration(requestBody);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->finishPasskeyRegistration: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **requestBody** | [**Map<String, Object>**](Object.md)|  | [optional] 

### Return type

[**Map<String, Object>**](Object.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAISettings**
> AISettings getAISettings()

The local Ollama server and how far descriptions have come

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.getAISettings();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getAISettings: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AISettings**](AISettings.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAdminHealth**
> AdminHealth getAdminHealth()

Whether the worker and the analysis service are running

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.getAdminHealth();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getAdminHealth: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AdminHealth**](AdminHealth.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAdminJobs**
> AdminJobs getAdminJobs()

The job queues, and the jobs that gave up

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.getAdminJobs();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getAdminJobs: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AdminJobs**](AdminJobs.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
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

# **getAdminStorage**
> List<UserStorage> getAdminStorage()

How much each user stores

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.getAdminStorage();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getAdminStorage: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<UserStorage>**](UserStorage.md)

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

# **getAnalysisProgress**
> AnalysisProgress getAnalysisProgress()

How far picture analysis has come. Administrators only.

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.getAnalysisProgress();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getAnalysisProgress: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AnalysisProgress**](AnalysisProgress.md)

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
final size = size_example; // String | source is the unedited picture, for its owner

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
 **size** | **String**| source is the unedited picture, for its owner | [optional] [default to 'small']

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

# **getAuthMethods**
> AuthMethods getAuthMethods()

The ways of signing in that this address offers, besides a password

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.getAuthMethods();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getAuthMethods: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AuthMethods**](AuthMethods.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

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

# **getBackupSettings**
> BackupSettings getBackupSettings()

Where backups go, without any secret

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.getBackupSettings();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getBackupSettings: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**BackupSettings**](BackupSettings.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getCollectionAsset**
> AssetDetail getCollectionAsset(scope, id)

An asset in a collection

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final scope = scope_example; // String | 
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getCollectionAsset(scope, id);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getCollectionAsset: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **scope** | **String**|  | 
 **id** | **String**|  | 

### Return type

[**AssetDetail**](AssetDetail.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getCollectionBucket**
> TimelineBucket getCollectionBucket(scope, month)

Assets of one month in a collection

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final scope = scope_example; // String | 
final month = month_example; // String | 

try {
    final result = api_instance.getCollectionBucket(scope, month);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getCollectionBucket: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **scope** | **String**|  | 
 **month** | **String**|  | 

### Return type

[**TimelineBucket**](TimelineBucket.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getCollectionBuckets**
> TimelineBuckets getCollectionBuckets(scope)

Months in the archive, the trash or the unlocked vault

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final scope = scope_example; // String | 

try {
    final result = api_instance.getCollectionBuckets(scope);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getCollectionBuckets: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **scope** | **String**|  | 

### Return type

[**TimelineBuckets**](TimelineBuckets.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getCollectionMotion**
> MultipartFile getCollectionMotion(scope, id)

The video inside a Motion Photo in a collection

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final scope = scope_example; // String | 
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getCollectionMotion(scope, id);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getCollectionMotion: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **scope** | **String**|  | 
 **id** | **String**|  | 

### Return type

[**MultipartFile**](MultipartFile.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: video/mp4, application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getCollectionOriginal**
> MultipartFile getCollectionOriginal(scope, id, download)

The original of an asset in a collection

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final scope = scope_example; // String | 
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final download = true; // bool | 

try {
    final result = api_instance.getCollectionOriginal(scope, id, download);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getCollectionOriginal: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **scope** | **String**|  | 
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

# **getCollectionThumbnail**
> MultipartFile getCollectionThumbnail(scope, id, size)

A preview of an asset in a collection

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final scope = scope_example; // String | 
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final size = size_example; // String | 

try {
    final result = api_instance.getCollectionThumbnail(scope, id, size);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getCollectionThumbnail: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **scope** | **String**|  | 
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

# **getCollectionVideoFile**
> MultipartFile getCollectionVideoFile(scope, id, file)

HLS files of a video in a collection

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final scope = scope_example; // String | 
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final file = file_example; // String | 

try {
    final result = api_instance.getCollectionVideoFile(scope, id, file);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getCollectionVideoFile: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **scope** | **String**|  | 
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

# **getDocuments**
> Documents getDocuments()

Photos of documents, found by the text on them

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.getDocuments();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getDocuments: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Documents**](Documents.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getExternalLibrary**
> ExternalLibrary getExternalLibrary()

The folder given as EXTERNAL_LIBRARY_PATH, and how it is doing

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.getExternalLibrary();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getExternalLibrary: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ExternalLibrary**](ExternalLibrary.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getFamily**
> Family getFamily()

The family library, and what this user shares with it

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.getFamily();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getFamily: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Family**](Family.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getFamilyBucket**
> TimelineBucket getFamilyBucket(month)

Assets of one month in the family library

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final month = month_example; // String | 

try {
    final result = api_instance.getFamilyBucket(month);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getFamilyBucket: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **month** | **String**|  | 

### Return type

[**TimelineBucket**](TimelineBucket.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getFamilyBuckets**
> TimelineBuckets getFamilyBuckets()

Months in the family library

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.getFamilyBuckets();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getFamilyBuckets: $e\n');
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

# **getFeatures**
> Map<String, bool> getFeatures()

Which additions the administrator has turned on

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.getFeatures();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getFeatures: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**Map<String, bool>**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getFolder**
> Folder getFolder(path)

One folder of the external library, for the user who owns it

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final path = path_example; // String | Relative to the library. Empty is its top

try {
    final result = api_instance.getFolder(path);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getFolder: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **path** | **String**| Relative to the library. Empty is its top | [optional] 

### Return type

[**Folder**](Folder.md)

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

# **getMapPoints**
> MapPoints getMapPoints(from, to)

Photos with a location that this user may see, oldest first

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final from = 2013-10-20; // DateTime | 
final to = 2013-10-20; // DateTime | 

try {
    final result = api_instance.getMapPoints(from, to);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getMapPoints: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **from** | **DateTime**|  | [optional] 
 **to** | **DateTime**|  | [optional] 

### Return type

[**MapPoints**](MapPoints.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMapStyle**
> MapStyle getMapStyle()

Where the map's background comes from

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.getMapStyle();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getMapStyle: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**MapStyle**](MapStyle.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMapTrips**
> List<Trip> getMapTrips()

Journeys found from the time and distance between photos

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.getMapTrips();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getMapTrips: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<Trip>**](Trip.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMyStats**
> AccountStats getMyStats()

How much this account holds

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.getMyStats();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getMyStats: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AccountStats**](AccountStats.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getOIDCSettings**
> OIDCSettings getOIDCSettings()

Single sign-on settings, without the secret

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.getOIDCSettings();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getOIDCSettings: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**OIDCSettings**](OIDCSettings.md)

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

# **getPersonBucket**
> TimelineBucket getPersonBucket(id, month)

Photos of this person in one month

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final month = month_example; // String | 

try {
    final result = api_instance.getPersonBucket(id, month);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getPersonBucket: $e\n');
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

# **getPersonBuckets**
> TimelineBuckets getPersonBuckets(id)

Months with this person

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getPersonBuckets(id);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getPersonBuckets: $e\n');
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

# **getPersonThumbnail**
> MultipartFile getPersonThumbnail(id)

A picture of this person's face

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getPersonThumbnail(id);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getPersonThumbnail: $e\n');
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
 - **Accept**: image/webp, application/json

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

# **getSecurity**
> SecuritySettings getSecurity()

Who may reach this server, and the devices that have tried

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.getSecurity();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getSecurity: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**SecuritySettings**](SecuritySettings.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getServerStatus**
> ServerStatus getServerStatus()

The version of this server, whether a newer one exists, and its disk

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.getServerStatus();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getServerStatus: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ServerStatus**](ServerStatus.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getStoryExport**
> StoryExport getStoryExport(id)

How a video is coming along

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getStoryExport(id);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getStoryExport: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

[**StoryExport**](StoryExport.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getStoryVideo**
> MultipartFile getStoryVideo(id)

The finished video

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getStoryVideo(id);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getStoryVideo: $e\n');
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

# **getTagBucket**
> TimelineBucket getTagBucket(id, month)

Photos carrying a tag in one month

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final month = month_example; // String | 

try {
    final result = api_instance.getTagBucket(id, month);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getTagBucket: $e\n');
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

# **getTagBuckets**
> TimelineBuckets getTagBuckets(id)

Months with photos carrying a tag

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final result = api_instance.getTagBuckets(id);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getTagBuckets: $e\n');
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

# **getTrashSummary**
> TrashSummary getTrashSummary()

What emptying the trash would remove

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.getTrashSummary();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getTrashSummary: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**TrashSummary**](TrashSummary.md)

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

# **getVaultStatus**
> VaultStatus getVaultStatus()

Whether the vault has a PIN and is unlocked

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.getVaultStatus();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->getVaultStatus: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**VaultStatus**](VaultStatus.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listAPIKeys**
> List<ApiKey> listAPIKeys()

The current user's keys, without the keys themselves

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.listAPIKeys();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->listAPIKeys: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<ApiKey>**](ApiKey.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

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

# **listAuditLog**
> List<AuditEntry> listAuditLog(before, limit)

Who changed what, newest first. Never the content of a request

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final before = 789; // int | Entries older than this id
final limit = 56; // int | 

try {
    final result = api_instance.listAuditLog(before, limit);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->listAuditLog: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **before** | **int**| Entries older than this id | [optional] 
 **limit** | **int**|  | [optional] 

### Return type

[**List<AuditEntry>**](AuditEntry.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listBackupRuns**
> List<BackupRun> listBackupRuns()

Backups and tests of bringing one back, the newest first

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.listBackupRuns();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->listBackupRuns: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<BackupRun>**](BackupRun.md)

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

# **listDuplicates**
> Duplicates listDuplicates()

Groups of photos that look alike. Only a proposal, nothing is removed without asking

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.listDuplicates();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->listDuplicates: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Duplicates**](Duplicates.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listFamilyMembersAdmin**
> List<UserRef> listFamilyMembersAdmin()

Who is in the family library

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.listFamilyMembersAdmin();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->listFamilyMembersAdmin: $e\n');
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

# **listImports**
> List<ImportEntry> listImports()

Imports, the newest first

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.listImports();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->listImports: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<ImportEntry>**](ImportEntry.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMemories**
> List<Memory> listMemories(date)

On this day in earlier years, and the last week

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final date = 2013-10-20; // DateTime | The user's own date, which decides what today is

try {
    final result = api_instance.listMemories(date);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->listMemories: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **date** | **DateTime**| The user's own date, which decides what today is | [optional] 

### Return type

[**List<Memory>**](Memory.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMySessions**
> List<UserSession> listMySessions()

Where this account is signed in

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.listMySessions();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->listMySessions: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<UserSession>**](UserSession.md)

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

# **listPasskeys**
> List<Passkey> listPasskeys()

The current user's passkeys

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.listPasskeys();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->listPasskeys: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<Passkey>**](Passkey.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listPeople**
> PeopleList listPeople()

People recognised in the current user's library

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.listPeople();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->listPeople: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**PeopleList**](PeopleList.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listSecurityEvents**
> List<SecurityEvent> listSecurityEvents(before)

Attempts to get in, newest first

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final before = 789; // int | Entries older than this one

try {
    final result = api_instance.listSecurityEvents(before);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->listSecurityEvents: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **before** | **int**| Entries older than this one | [optional] 

### Return type

[**List<SecurityEvent>**](SecurityEvent.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listTags**
> List<Tag> listTags()

The current user's tags

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.listTags();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->listTags: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<Tag>**](Tag.md)

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

# **listWebhooks**
> List<Webhook> listWebhooks()

Addresses told about events, without their secrets

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.listWebhooks();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->listWebhooks: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<Webhook>**](Webhook.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **lockVault**
> lockVault()

Lock the vault again

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    api_instance.lockVault();
} catch (e) {
    print('Exception when calling DefaultApi->lockVault: $e\n');
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

# **mergePeople**
> mergePeople(id, assetIds)

Treat other people as this one

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final assetIds = AssetIds(); // AssetIds | 

try {
    api_instance.mergePeople(id, assetIds);
} catch (e) {
    print('Exception when calling DefaultApi->mergePeople: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **assetIds** | [**AssetIds**](AssetIds.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **pauseJobQueue**
> pauseJobQueue(queue)

Stop starting jobs from this queue

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final queue = queue_example; // String | 

try {
    api_instance.pauseJobQueue(queue);
} catch (e) {
    print('Exception when calling DefaultApi->pauseJobQueue: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **queue** | **String**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

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

# **removeFamilyMember**
> removeFamilyMember(userId)

Remove someone. Their photos stay in their own library

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final userId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.removeFamilyMember(userId);
} catch (e) {
    print('Exception when calling DefaultApi->removeFamilyMember: $e\n');
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

# **resumeJobQueue**
> resumeJobQueue(queue)

Continue a paused queue

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final queue = queue_example; // String | 

try {
    api_instance.resumeJobQueue(queue);
} catch (e) {
    print('Exception when calling DefaultApi->resumeJobQueue: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **queue** | **String**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **retryJob**
> retryJob(id)

Try a failed job again

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 789; // int | 

try {
    api_instance.retryJob(id);
} catch (e) {
    print('Exception when calling DefaultApi->retryJob: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

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

# **scanExternalLibrary**
> scanExternalLibrary()

Look through the folder for changes now

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();

try {
    api_instance.scanExternalLibrary();
} catch (e) {
    print('Exception when calling DefaultApi->scanExternalLibrary: $e\n');
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

# **searchAssets**
> SearchResult searchAssets(q)

Search in natural language. Dates, people, places and cameras in the query become filters.

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final q = q_example; // String | 

try {
    final result = api_instance.searchAssets(q);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->searchAssets: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**|  | 

### Return type

[**SearchResult**](SearchResult.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **setAISettings**
> AISettings setAISettings(aISettingsUpdate)

Name the Ollama server. Previews of photos are sent to it

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final aISettingsUpdate = AISettingsUpdate(); // AISettingsUpdate | 

try {
    final result = api_instance.setAISettings(aISettingsUpdate);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->setAISettings: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **aISettingsUpdate** | [**AISettingsUpdate**](AISettingsUpdate.md)|  | 

### Return type

[**AISettings**](AISettings.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
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

# **setAssetEdits**
> setAssetEdits(id, assetEdits)

Replace the list of edits of a photo. The original is never changed

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final assetEdits = AssetEdits(); // AssetEdits | 

try {
    api_instance.setAssetEdits(id, assetEdits);
} catch (e) {
    print('Exception when calling DefaultApi->setAssetEdits: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **assetEdits** | [**AssetEdits**](AssetEdits.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **setBackupSettings**
> BackupSettings setBackupSettings(backupSettingsUpdate)

Change where backups go. A secret left out stays as it was

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final backupSettingsUpdate = BackupSettingsUpdate(); // BackupSettingsUpdate | 

try {
    final result = api_instance.setBackupSettings(backupSettingsUpdate);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->setBackupSettings: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **backupSettingsUpdate** | [**BackupSettingsUpdate**](BackupSettingsUpdate.md)|  | 

### Return type

[**BackupSettings**](BackupSettings.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **setExternalLibrary**
> ExternalLibrary setExternalLibrary(externalLibraryOwner)

Choose whose photos the folder holds, and start reading it

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final externalLibraryOwner = ExternalLibraryOwner(); // ExternalLibraryOwner | 

try {
    final result = api_instance.setExternalLibrary(externalLibraryOwner);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->setExternalLibrary: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **externalLibraryOwner** | [**ExternalLibraryOwner**](ExternalLibraryOwner.md)|  | 

### Return type

[**ExternalLibrary**](ExternalLibrary.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **setFeature**
> setFeature(name, featureUpdate)

Turn an addition on or off

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final name = name_example; // String | 
final featureUpdate = FeatureUpdate(); // FeatureUpdate | 

try {
    api_instance.setFeature(name, featureUpdate);
} catch (e) {
    print('Exception when calling DefaultApi->setFeature: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**|  | 
 **featureUpdate** | [**FeatureUpdate**](FeatureUpdate.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **setMapStyle**
> MapStyle setMapStyle(mapStyle)

Choose the map's background. Administrators only. Empty goes back to the default.

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final mapStyle = MapStyle(); // MapStyle | 

try {
    final result = api_instance.setMapStyle(mapStyle);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->setMapStyle: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **mapStyle** | [**MapStyle**](MapStyle.md)|  | 

### Return type

[**MapStyle**](MapStyle.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **setOIDCSettings**
> OIDCSettings setOIDCSettings(oIDCSettingsUpdate)

Change single sign-on. An empty issuer turns it off

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final oIDCSettingsUpdate = OIDCSettingsUpdate(); // OIDCSettingsUpdate | 

try {
    final result = api_instance.setOIDCSettings(oIDCSettingsUpdate);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->setOIDCSettings: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **oIDCSettingsUpdate** | [**OIDCSettingsUpdate**](OIDCSettingsUpdate.md)|  | 

### Return type

[**OIDCSettings**](OIDCSettings.md)

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

# **setSecurity**
> SecuritySettings setSecurity(securityUpdate)

Change the rules. Refused if it would lock out the person asking

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final securityUpdate = SecurityUpdate(); // SecurityUpdate | 

try {
    final result = api_instance.setSecurity(securityUpdate);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->setSecurity: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **securityUpdate** | [**SecurityUpdate**](SecurityUpdate.md)|  | 

### Return type

[**SecuritySettings**](SecuritySettings.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **setStackMain**
> setStackMain(id)

Make this shot the one the timeline shows

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.setStackMain(id);
} catch (e) {
    print('Exception when calling DefaultApi->setStackMain: $e\n');
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

# **setUserQuota**
> setUserQuota(id, quotaUpdate)

Set how much a user may store. Without a value there is no limit

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final quotaUpdate = QuotaUpdate(); // QuotaUpdate | 

try {
    api_instance.setUserQuota(id, quotaUpdate);
} catch (e) {
    print('Exception when calling DefaultApi->setUserQuota: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **quotaUpdate** | [**QuotaUpdate**](QuotaUpdate.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **setVaultPin**
> setVaultPin(vaultPinChange)

Set the vault PIN. Changing it needs the current one.

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final vaultPinChange = VaultPinChange(); // VaultPinChange | 

try {
    api_instance.setVaultPin(vaultPinChange);
} catch (e) {
    print('Exception when calling DefaultApi->setVaultPin: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vaultPinChange** | [**VaultPinChange**](VaultPinChange.md)|  | 

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

# **startBackupRun**
> startBackupRun(backupRunRequest)

Back up now, or test bringing the newest backup back

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final backupRunRequest = BackupRunRequest(); // BackupRunRequest | 

try {
    api_instance.startBackupRun(backupRunRequest);
} catch (e) {
    print('Exception when calling DefaultApi->startBackupRun: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **backupRunRequest** | [**BackupRunRequest**](BackupRunRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **startOIDC**
> startOIDC(next, appChallenge)

Go to the identity provider

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final next = next_example; // String | 
final appChallenge = appChallenge_example; // String | SHA-256 of a secret the app keeps, base64url

try {
    api_instance.startOIDC(next, appChallenge);
} catch (e) {
    print('Exception when calling DefaultApi->startOIDC: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **next** | **String**|  | [optional] 
 **appChallenge** | **String**| SHA-256 of a secret the app keeps, base64url | [optional] 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **testWebhook**
> testWebhook(id)

Send a test event now

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api_instance.testWebhook(id);
} catch (e) {
    print('Exception when calling DefaultApi->testWebhook: $e\n');
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

# **unlockVault**
> VaultSession unlockVault(vaultUnlock)

Unlock the vault for a short time

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final vaultUnlock = VaultUnlock(); // VaultUnlock | 

try {
    final result = api_instance.unlockVault(vaultUnlock);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->unlockVault: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vaultUnlock** | [**VaultUnlock**](VaultUnlock.md)|  | 

### Return type

[**VaultSession**](VaultSession.md)

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

# **updatePerson**
> updatePerson(id, personUpdate)

Name or hide a person

### Example
```dart
import 'package:mediarr_api/api.dart';

final api_instance = DefaultApi();
final id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final personUpdate = PersonUpdate(); // PersonUpdate | 

try {
    api_instance.updatePerson(id, personUpdate);
} catch (e) {
    print('Exception when calling DefaultApi->updatePerson: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **personUpdate** | [**PersonUpdate**](PersonUpdate.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)


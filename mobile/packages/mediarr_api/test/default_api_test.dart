//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

import 'package:mediarr_api/api.dart';
import 'package:test/test.dart';

/// tests for DefaultApi
void main() {
  // final instance = DefaultApi();

  group('tests for DefaultApi', () {
    // Add your own assets to an album. Needs the contributor role.
    //
    //Future<BulkResponse> addAlbumAssets(String id, AssetIds assetIds) async
    test('test addAlbumAssets', () async {
      // TODO
    });

    // Append data to an upload (tus 1.0). The last chunk returns X-Asset-Id.
    //
    //Future appendUpload(String id) async
    test('test appendUpload', () async {
      // TODO
    });

    // Apply an action to several of the current user's assets. Other assets are ignored.
    //
    //Future<BulkResponse> bulkAssets(BulkRequest bulkRequest) async
    test('test bulkAssets', () async {
      // TODO
    });

    // Cancel an upload (tus 1.0)
    //
    //Future cancelUpload(String id) async
    test('test cancelUpload', () async {
      // TODO
    });

    // Change the current user's password and end their other sessions
    //
    //Future changePassword(ChangePasswordRequest changePasswordRequest) async
    test('test changePassword', () async {
      // TODO
    });

    // Report which SHA-256 checksums the current user already has, so uploads can be skipped
    //
    //Future<ChecksumCheckResponse> checkAssets(ChecksumCheckRequest checksumCheckRequest) async
    test('test checkAssets', () async {
      // TODO
    });

    // Create an album. With rules it is a smart album.
    //
    //Future<Album> createAlbum(AlbumCreate albumCreate) async
    test('test createAlbum', () async {
      // TODO
    });

    // Comment on an album or on a photo in it
    //
    //Future createAlbumComment(String id, CommentCreate commentCreate) async
    test('test createAlbumComment', () async {
      // TODO
    });

    // Create a public link. Its token is returned only this once.
    //
    //Future<ShareLink> createAlbumLink(String id, ShareLinkCreate shareLinkCreate) async
    test('test createAlbumLink', () async {
      // TODO
    });

    // Create a long-lived key for this device, used by background backup
    //
    //Future<DeviceKey> createDeviceKey(CreateDeviceKeyRequest createDeviceKeyRequest) async
    test('test createDeviceKey', () async {
      // TODO
    });

    // Send one whole file to a public album (tus 1.0 creation with upload)
    //
    //Future createPublicUpload(String token) async
    test('test createPublicUpload', () async {
      // TODO
    });

    // Create a resumable upload (tus 1.0). A body uploads the whole file in this request.
    //
    //Future createUpload() async
    test('test createUpload', () async {
      // TODO
    });

    // Create a user
    //
    //Future<User> createUser(CreateUserRequest createUserRequest) async
    test('test createUser', () async {
      // TODO
    });

    // Delete an album, but not its photos. Owner only.
    //
    //Future deleteAlbum(String id) async
    test('test deleteAlbum', () async {
      // TODO
    });

    // Delete a comment. The author, an editor or the owner can do this.
    //
    //Future deleteAlbumComment(String id, String commentId) async
    test('test deleteAlbumComment', () async {
      // TODO
    });

    // Revoke a public link. It stops working at once.
    //
    //Future deleteAlbumLink(String id, String linkId) async
    test('test deleteAlbumLink', () async {
      // TODO
    });

    // Turn off TOTP
    //
    //Future disableTotp(PasswordConfirm passwordConfirm) async
    test('test disableTotp', () async {
      // TODO
    });

    // Download several originals as one uncompressed ZIP file
    //
    //Future<MultipartFile> downloadAssets(String ids) async
    test('test downloadAssets', () async {
      // TODO
    });

    // Confirm a code and turn on TOTP
    //
    //Future enableTotp(TotpCode totpCode) async
    test('test enableTotp', () async {
      // TODO
    });

    // Live statistics of the whole server, read from the database and the library disk
    //
    //Future<AdminOverview> getAdminOverview() async
    test('test getAdminOverview', () async {
      // TODO
    });

    // Read an album and its members
    //
    //Future<Album> getAlbum(String id) async
    test('test getAlbum', () async {
      // TODO
    });

    // Assets of one month in an album
    //
    //Future<TimelineBucket> getAlbumBucket(String id, String month) async
    test('test getAlbumBucket', () async {
      // TODO
    });

    // Months in an album, in the album's order
    //
    //Future<TimelineBuckets> getAlbumBuckets(String id) async
    test('test getAlbumBuckets', () async {
      // TODO
    });

    // Read an asset's details and its neighbours on the timeline
    //
    //Future<AssetDetail> getAsset(String id) async
    test('test getAsset', () async {
      // TODO
    });

    // Read the video embedded in an Android Motion Photo
    //
    //Future<MultipartFile> getAssetMotion(String id) async
    test('test getAssetMotion', () async {
      // TODO
    });

    // Read the unmodified original. Supports Range requests for video.
    //
    //Future<MultipartFile> getAssetOriginal(String id, { bool download }) async
    test('test getAssetOriginal', () async {
      // TODO
    });

    // Read a WebP thumbnail
    //
    //Future<MultipartFile> getAssetThumbnail(String id, { String size }) async
    test('test getAssetThumbnail', () async {
      // TODO
    });

    // Read an HLS playlist or segment, or the scrub strip (sprite.jpg)
    //
    //Future<MultipartFile> getAssetVideoFile(String id, String file) async
    test('test getAssetVideoFile', () async {
      // TODO
    });

    // Report whether setup is needed and who is signed in
    //
    //Future<AuthStatus> getAuthStatus() async
    test('test getAuthStatus', () async {
      // TODO
    });

    // Report whether the server can reach its database
    //
    //Future<Health> getHealth() async
    test('test getHealth', () async {
      // TODO
    });

    // Assets of one month in a library shared with you
    //
    //Future<TimelineBucket> getPartnerBucket(String userId, String month) async
    test('test getPartnerBucket', () async {
      // TODO
    });

    // Months in a library shared with you
    //
    //Future<TimelineBuckets> getPartnerBuckets(String userId) async
    test('test getPartnerBuckets', () async {
      // TODO
    });

    // An asset in a public album, without what the link does not allow
    //
    //Future<AssetDetail> getPublicAsset(String token, String id) async
    test('test getPublicAsset', () async {
      // TODO
    });

    // Assets of one month in a public album
    //
    //Future<TimelineBucket> getPublicBucket(String token, String month) async
    test('test getPublicBucket', () async {
      // TODO
    });

    // Months in a public album
    //
    //Future<TimelineBuckets> getPublicBuckets(String token) async
    test('test getPublicBuckets', () async {
      // TODO
    });

    // What a public link offers. Needs no account.
    //
    //Future<PublicLink> getPublicLink(String token) async
    test('test getPublicLink', () async {
      // TODO
    });

    // The video inside a Motion Photo in a public album
    //
    //Future<MultipartFile> getPublicMotion(String token, String id) async
    test('test getPublicMotion', () async {
      // TODO
    });

    // Download an original. Counts toward the link's limit.
    //
    //Future<MultipartFile> getPublicOriginal(String token, String id, { bool download }) async
    test('test getPublicOriginal', () async {
      // TODO
    });

    // A preview from a public album, with the link's watermark if it has one
    //
    //Future<MultipartFile> getPublicThumbnail(String token, String id, { String size }) async
    test('test getPublicThumbnail', () async {
      // TODO
    });

    // HLS files of a video in a public album
    //
    //Future<MultipartFile> getPublicVideoFile(String token, String id, String file) async
    test('test getPublicVideoFile', () async {
      // TODO
    });

    // List one month's assets, newest first
    //
    //Future<TimelineBucket> getTimelineBucket(String month) async
    test('test getTimelineBucket', () async {
      // TODO
    });

    // List the months that have photos, newest first
    //
    //Future<TimelineBuckets> getTimelineBuckets() async
    test('test getTimelineBuckets', () async {
      // TODO
    });

    // Read how much of an upload has arrived (tus 1.0)
    //
    //Future getUploadOffset(String id) async
    test('test getUploadOffset', () async {
      // TODO
    });

    // Comments on an album, or with assetId on one photo, and that photo's hearts
    //
    //Future<Activity> listAlbumComments(String id, { String assetId }) async
    test('test listAlbumComments', () async {
      // TODO
    });

    // Public links of an album. Owner only.
    //
    //Future<List<ShareLink>> listAlbumLinks(String id) async
    test('test listAlbumLinks', () async {
      // TODO
    });

    // Albums the current user owns or that are shared with them
    //
    //Future<List<Album>> listAlbums({ String sort }) async
    test('test listAlbums', () async {
      // TODO
    });

    // List the current user's most recent assets and their processing status
    //
    //Future<AssetList> listAssets({ int limit, String status }) async
    test('test listAssets', () async {
      // TODO
    });

    // Cameras in the current user's library, for smart album rules
    //
    //Future<List<String>> listCameras() async
    test('test listCameras', () async {
      // TODO
    });

    // The other users of this server, for choosing who to share with
    //
    //Future<List<UserRef>> listDirectory() async
    test('test listDirectory', () async {
      // TODO
    });

    // Who you share your library with, and who shares theirs with you
    //
    //Future<Partners> listPartners() async
    test('test listPartners', () async {
      // TODO
    });

    // List users
    //
    //Future<List<User>> listUsers() async
    test('test listUsers', () async {
      // TODO
    });

    // Sign in with email, password and, when enabled, a TOTP code
    //
    //Future<User> login(LoginRequest loginRequest) async
    test('test login', () async {
      // TODO
    });

    // End the current session
    //
    //Future logout() async
    test('test logout', () async {
      // TODO
    });

    // Remove assets from an album. A contributor can remove only what they added.
    //
    //Future<BulkResponse> removeAlbumAssets(String id, AssetIds assetIds) async
    test('test removeAlbumAssets', () async {
      // TODO
    });

    // Take back your heart
    //
    //Future removeAlbumHeart(String id, String assetId) async
    test('test removeAlbumHeart', () async {
      // TODO
    });

    // End a user's access. The owner can remove anyone, and a member can leave.
    //
    //Future removeAlbumMember(String id, String userId) async
    test('test removeAlbumMember', () async {
      // TODO
    });

    // Stop sharing your library with a user
    //
    //Future removePartner(String userId) async
    test('test removePartner', () async {
      // TODO
    });

    // Revoke one of the current user's device keys
    //
    //Future revokeDeviceKey(String id) async
    test('test revokeDeviceKey', () async {
      // TODO
    });

    // Add your heart to a photo in an album
    //
    //Future setAlbumHeart(String id, String assetId) async
    test('test setAlbumHeart', () async {
      // TODO
    });

    // Share an album with a user or change their role. Owner only.
    //
    //Future setAlbumMember(String id, String userId, MemberRole memberRole) async
    test('test setAlbumMember', () async {
      // TODO
    });

    // Share your library with a user, all of it or from a date
    //
    //Future setPartner(String userId, PartnerShare partnerShare) async
    test('test setPartner', () async {
      // TODO
    });

    // Choose whether a partner's photos also appear in your timeline
    //
    //Future setPartnerTimeline(String userId, PartnerTimeline partnerTimeline) async
    test('test setPartnerTimeline', () async {
      // TODO
    });

    // Create the first administrator. Closed once any user exists.
    //
    //Future<User> setup(SetupRequest setupRequest) async
    test('test setup', () async {
      // TODO
    });

    // Generate a TOTP secret. It takes effect only after confirmation.
    //
    //Future<TotpSetup> setupTotp() async
    test('test setupTotp', () async {
      // TODO
    });

    // Send a link's password. Success sets a cookie valid only for this link.
    //
    //Future unlockPublicLink(String token, LinkPassword linkPassword) async
    test('test unlockPublicLink', () async {
      // TODO
    });

    // Change an album. Needs the editor role.
    //
    //Future<Album> updateAlbum(String id, AlbumUpdate albumUpdate) async
    test('test updateAlbum', () async {
      // TODO
    });
  });
}

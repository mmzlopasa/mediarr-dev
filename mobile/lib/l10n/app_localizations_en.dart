// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageTitle => 'Language';

  @override
  String get languageMachine =>
      'Machine translated: a person has not read it yet.';

  @override
  String get languageFollowsAccount =>
      'Your choice is saved to your account, so other devices follow it.';

  @override
  String get appHeaderNew => 'New';

  @override
  String get appHeaderAdd => 'Add';

  @override
  String get appHeaderAccount => 'Account';

  @override
  String get appHeaderBackupAndUpload => 'Backup and upload';

  @override
  String get uploadsCouldNotRead =>
      'This photo could not be read from the device.';

  @override
  String get waitingStripTitle => 'On this phone, waiting to back up';

  @override
  String get shareSheetVaultTitle => 'Take it out of the vault?';

  @override
  String get shareSheetVaultBody =>
      'Once sent or saved, it is no longer protected by your PIN.';

  @override
  String get shareSheetCancel => 'Cancel';

  @override
  String get shareSheetContinue => 'Continue';

  @override
  String get shareSheetSendThis => 'Send this';

  @override
  String shareSheetSendCount(String count) {
    return 'Send $count';
  }

  @override
  String get shareSheetSmaller => 'Smaller, for messages';

  @override
  String get shareSheetOriginal => 'Original';

  @override
  String get shareSheetSmallerDetail =>
      'A JPEG of at most 2048 px, without location';

  @override
  String get shareSheetOriginalDetail => 'As it is, with everything in it';

  @override
  String get shareSheetSaveToPhone => 'Save to this phone';

  @override
  String get shareSheetSaveDetail => 'The original, in the phone’s gallery';

  @override
  String get shareSheetSavedOne => 'Saved to this phone.';

  @override
  String shareSheetSavedMany(String count) {
    return '$count saved to this phone.';
  }

  @override
  String get shareSheetGettingReady => 'Getting it ready';

  @override
  String shareSheetProgress(String done, String total) {
    return '$done of $total';
  }

  @override
  String get shareSheetFetchFailed => 'The files could not be fetched.';

  @override
  String facesSectionActionFailed(String detail) {
    return 'The action failed. $detail';
  }

  @override
  String get facesSectionNewPerson => 'New person';

  @override
  String get facesSectionCancel => 'Cancel';

  @override
  String get facesSectionSave => 'Save';

  @override
  String get facesSectionPeople => 'People';

  @override
  String get facesSectionNoName => 'No name';

  @override
  String get facesSectionWhoThisIs => 'Who this is';

  @override
  String get facesSectionNewPersonMenu => 'New person…';

  @override
  String get facesSectionNotAPerson => 'Not a person';

  @override
  String get importsScreenWaitingForFiles => 'Waiting for files';

  @override
  String get importsScreenRunning => 'Running';

  @override
  String get importsScreenDone => 'Done';

  @override
  String get importsScreenFailed => 'Failed';

  @override
  String get importsScreenStopped => 'Stopped';

  @override
  String importsScreenZipUploaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ZIP files uploaded',
      one: '1 ZIP file uploaded',
    );
    return '$_temp0';
  }

  @override
  String importsScreenCounts(String added, String skipped, String failed) {
    return 'added $added · already here or deleted $skipped · failed $failed';
  }

  @override
  String get importsScreenReportNotLoaded => 'The report could not be loaded.';

  @override
  String get importsScreenNoFilesFailed => 'No files failed.';

  @override
  String get importsScreenCouldNotStop => 'The import could not be stopped.';

  @override
  String get importsScreenStop => 'Stop';

  @override
  String get importsScreenCouldNotContinue => 'The import could not go on.';

  @override
  String get importsScreenBringIn => 'Bring in';

  @override
  String get importsScreenContinue => 'Continue';

  @override
  String get importsScreenReport => 'Report';

  @override
  String get importsScreenTitle => 'Import';

  @override
  String get importsScreenNotLoaded => 'The imports could not be loaded.';

  @override
  String importsScreenHowTo(String address) {
    return 'To bring in photos from Google Photos or iCloud, upload the ZIP files of the export on a computer, at $address.';
  }

  @override
  String get importsScreenNothingYet => 'You have not imported anything yet.';

  @override
  String get storageTemplateScreenDryRun => 'Dry run';

  @override
  String storageTemplateScreenDryRunProgress(String checked) {
    return 'Dry run… $checked';
  }

  @override
  String storageTemplateScreenMovingProgress(String checked) {
    return 'Moving… $checked';
  }

  @override
  String storageTemplateScreenWouldMove(String moved, String checked) {
    return 'Dry run: $moved of $checked would move.';
  }

  @override
  String storageTemplateScreenMoved(String moved, String checked) {
    return 'Moved $moved of $checked.';
  }

  @override
  String storageTemplateScreenFailedCount(String line, String failed) {
    return '$line Failed: $failed.';
  }

  @override
  String get storageTemplateScreenNotLoaded => 'Not loaded.';

  @override
  String get storageTemplateScreenSaved => 'Saved.';

  @override
  String get storageTemplateScreenNotSaved => 'Not saved.';

  @override
  String storageTemplateScreenMoveFilesQuestion(String count) {
    return 'Move $count files?';
  }

  @override
  String get storageTemplateScreenOriginalsUnchanged =>
      'The originals do not change, only where they are on the disk.';

  @override
  String get storageTemplateScreenCancel => 'Cancel';

  @override
  String get storageTemplateScreenMove => 'Move';

  @override
  String get storageTemplateScreenNotStarted => 'Not started.';

  @override
  String get storageTemplateScreenTitle => 'Storage template';

  @override
  String get storageTemplateScreenIntro =>
      'How originals are laid out on the disk, inside each user’s folder. It applies to new files; the ones already here move only when you ask, after a dry run. An external library never moves.';

  @override
  String get storageTemplateScreenTemplate => 'Template';

  @override
  String get storageTemplateScreenExamples => 'Examples';

  @override
  String get storageTemplateScreenBackToUsual => 'Back to the usual layout';

  @override
  String get storageTemplateScreenSave => 'Save';

  @override
  String get storageTemplateScreenFilesAlreadyHere => 'Files already here';

  @override
  String get storageTemplateScreenMoveTheFiles => 'Move the files';

  @override
  String get mapScreenNoPlaceName => 'No place name';

  @override
  String get mapScreenNotLoaded =>
      'The map could not be loaded. Check the connection.';

  @override
  String get mapScreenTryAgain => 'Try again';

  @override
  String get mapScreenNoPhotos => 'No photos with a location yet.';

  @override
  String get mapScreenFromDate => 'From date';

  @override
  String get mapScreenToDate => 'To date';

  @override
  String get mapScreenClear => 'Clear';

  @override
  String mapScreenItems(String count) {
    return 'Items: $count';
  }

  @override
  String get mapScreenTrips => 'Trips';

  @override
  String get mapScreenTitle => 'Map';

  @override
  String get cleanupScreenBlurry => 'Blurry photos';

  @override
  String get cleanupScreenScreenshots => 'Screenshots';

  @override
  String get cleanupScreenLargeVideos => 'Large videos';

  @override
  String get cleanupScreenBursts => 'Bursts';

  @override
  String get cleanupScreenBlurryHint =>
      'Photos with very few sharp edges. The slider sets how strict.';

  @override
  String get cleanupScreenScreenshotsHint =>
      'Found by their name, an iPhone\'s mark, or the shape of a screen.';

  @override
  String get cleanupScreenLargeVideosHint => 'The largest first.';

  @override
  String get cleanupScreenBurstsHint =>
      'The other shots of a burst. The best shot stays.';

  @override
  String get cleanupScreenMoveToTrashQuestion => 'Move to the trash?';

  @override
  String cleanupScreenTrashBody(String count, String size) {
    return '$count items ($size) stay in the trash for a while and can be restored.';
  }

  @override
  String get cleanupScreenCancel => 'Cancel';

  @override
  String get cleanupScreenMove => 'Move';

  @override
  String get cleanupScreenMovedToTrash => 'Moved to the trash.';

  @override
  String get cleanupScreenActionFailed => 'The action failed.';

  @override
  String get cleanupScreenKept => 'Kept. They will not be offered again.';

  @override
  String get cleanupScreenStricter => 'Stricter';

  @override
  String get cleanupScreenMore => 'More';

  @override
  String get cleanupScreenLargerThan => 'Larger than ';

  @override
  String get cleanupScreenToTheTrash => 'To the trash';

  @override
  String get cleanupScreenStays => 'Stays';

  @override
  String get cleanupScreenFavorite => 'Favorite';

  @override
  String get cleanupScreenInAnAlbum => 'In an album';

  @override
  String get cleanupScreenTitle => 'Clean up';

  @override
  String get cleanupScreenKeep => 'Keep';

  @override
  String cleanupScreenToTheTrashButton(String count, String size) {
    return 'To the trash ($count · $size)';
  }

  @override
  String get cleanupScreenNotLoaded => 'Clean up could not be loaded.';

  @override
  String cleanupScreenStillAnalysed(String count) {
    return 'Still being analysed: $count photos.';
  }

  @override
  String get cleanupScreenNothing => 'Nothing to clean up here.';

  @override
  String get cleanupScreenTapToTick =>
      'Tap to tick or untick. Hold to look at it.';

  @override
  String get cleanupScreenShowMore => 'Show more';

  @override
  String get organizeScreensRecentlyAdded => 'Recently added';

  @override
  String get organizeScreensFavorites => 'Favorites';

  @override
  String get organizeScreensMemories => 'Memories';

  @override
  String get organizeScreensPeople => 'People';

  @override
  String get organizeScreensMap => 'Map';

  @override
  String get organizeScreensFolders => 'Folders';

  @override
  String get organizeScreensFamily => 'Family';

  @override
  String get organizeScreensDocuments => 'Documents';

  @override
  String get organizeScreensDuplicates => 'Duplicates';

  @override
  String get organizeScreensCleanUp => 'Clean up';

  @override
  String get organizeScreensArchive => 'Archive';

  @override
  String get organizeScreensTrash => 'Trash';

  @override
  String get organizeScreensVault => 'Vault';

  @override
  String get organizeScreensApiKeys => 'API keys';

  @override
  String get organizeScreensTags => 'Tags';

  @override
  String get organizeScreensCouldNotLoad =>
      'This could not be loaded. Check the connection.';

  @override
  String get organizeScreensClearSelection => 'Clear selection';

  @override
  String get organizeScreensShare => 'Share';

  @override
  String get organizeScreensOriginalsRemoved =>
      'The originals are removed from the disk. This cannot be undone.';

  @override
  String get organizeScreensCancel => 'Cancel';

  @override
  String get organizeScreensDeletePermanently => 'Delete permanently';

  @override
  String organizeScreensActionFailedDetail(String detail) {
    return 'The action failed. $detail';
  }

  @override
  String get organizeScreensNothingAdded => 'Nothing has been added yet.';

  @override
  String get organizeScreensAddToFavorites => 'Add to favorites';

  @override
  String get organizeScreensAddedToFavorites => 'Added to favorites';

  @override
  String get organizeScreensArchiveAction => 'Archive';

  @override
  String get organizeScreensArchived => 'Archived';

  @override
  String get organizeScreensNoFavorites =>
      'No favorites yet. Mark a photo with the star.';

  @override
  String get organizeScreensRemoveFromFavorites => 'Remove from favorites';

  @override
  String get organizeScreensRemovedFromFavorites => 'Removed from favorites';

  @override
  String get organizeScreensArchiveEmpty => 'The archive is empty.';

  @override
  String get organizeScreensBackToMedia => 'Back to Media';

  @override
  String get organizeScreensBackInMedia => 'Back in Media';

  @override
  String organizeScreensTrashRemoves(String count, String size) {
    return 'This removes $count files, $size.';
  }

  @override
  String get organizeScreensEmptyTrashQuestion => 'Empty the trash?';

  @override
  String organizeScreensPermanentlyDeletedCount(String count) {
    return 'Permanently deleted: $count';
  }

  @override
  String get organizeScreensEmpty => 'Empty';

  @override
  String get organizeScreensTrashAfterAWhile =>
      'Items here are deleted permanently after a while.';

  @override
  String organizeScreensTrashAfterDays(String days) {
    return 'Items are permanently deleted after $days days.';
  }

  @override
  String get organizeScreensTrashEmpty => 'The trash is empty.';

  @override
  String get organizeScreensRestore => 'Restore';

  @override
  String get organizeScreensRestored => 'Restored';

  @override
  String get organizeScreensDeletePermanentlyQuestion => 'Delete permanently?';

  @override
  String get organizeScreensPermanentlyDeleted => 'Permanently deleted';

  @override
  String get organizeScreensOpenYourVault => 'Open your vault';

  @override
  String get organizeScreensTooManyAttempts =>
      'Too many attempts. Try again later.';

  @override
  String get organizeScreensWrongPin => 'Wrong PIN.';

  @override
  String get organizeScreensPinLength =>
      'The PIN must have between 4 and 12 digits.';

  @override
  String get organizeScreensVaultLockedItself =>
      'The vault locked itself. Unlock it again.';

  @override
  String get organizeScreensVaultEmpty => 'The vault is empty.';

  @override
  String get organizeScreensVaultNotLoaded =>
      'The vault could not be loaded. Check the connection.';

  @override
  String get organizeScreensTryAgain => 'Try again';

  @override
  String get organizeScreensVaultIntro =>
      'Hidden from every other view and from sharing. The files on the server are not encrypted.';

  @override
  String get organizeScreensPin => 'PIN';

  @override
  String get organizeScreensNewPin => 'New PIN';

  @override
  String get organizeScreensPinHelper =>
      'From 4 to 12 digits. Only the server administrator can reset a lost PIN.';

  @override
  String get organizeScreensUseFaceId => 'Use Face ID next time';

  @override
  String get organizeScreensUnlock => 'Unlock';

  @override
  String get organizeScreensSetPin => 'Set PIN';

  @override
  String get organizeScreensAddATag => 'Add a tag';

  @override
  String get organizeScreensNewTag => 'New tag';

  @override
  String get organizeScreensCreateAndAdd => 'Create and add';

  @override
  String get organizeScreensTagsNotLoaded => 'Tags could not be loaded.';

  @override
  String get organizeScreensNoTags =>
      'No tags yet. Select photos and add a tag.';

  @override
  String get organizeScreensDeleteTag => 'Delete tag';

  @override
  String get organizeScreensRenameTheTag => 'Rename the tag';

  @override
  String get organizeScreensNewName => 'New name';

  @override
  String get organizeScreensSave => 'Save';

  @override
  String organizeScreensAlreadyExists(String name) {
    return '\"$name\" already exists';
  }

  @override
  String organizeScreensJoinThem(String name) {
    return 'Join them? All the photos will have \"$name\".';
  }

  @override
  String get organizeScreensJoin => 'Join';

  @override
  String organizeScreensNotRenamed(String detail) {
    return 'Not renamed. $detail';
  }

  @override
  String organizeScreensNotJoined(String detail) {
    return 'Not joined. $detail';
  }

  @override
  String get organizeScreensRename => 'Rename';

  @override
  String get organizeScreensNoPhotosWithTag => 'No photos carry this tag.';

  @override
  String get organizeScreensRemoveTheTag => 'Remove the tag';

  @override
  String get organizeScreensFamilyNotOn =>
      'An administrator has not turned this on.';

  @override
  String get organizeScreensFamilyNotMember =>
      'You are not in the family library yet.';

  @override
  String get organizeScreensWhatIShare => 'What I share';

  @override
  String get organizeScreensFamilyNotLoaded =>
      'The family library could not be loaded.';

  @override
  String get organizeScreensFamilyNothingShared =>
      'Nobody has shared anything with the family yet.';

  @override
  String get organizeScreensShareWithFamily => 'Share with the family';

  @override
  String get organizeScreensRuleName => 'Rule name';

  @override
  String get organizeScreensFromDateExample => 'From date (2024-06-01)';

  @override
  String get organizeScreensPlace => 'Place';

  @override
  String organizeScreensNotSaved(String detail) {
    return 'It was not saved. $detail';
  }

  @override
  String get organizeScreensNewRule => 'New rule';

  @override
  String get organizeScreensShareNothing =>
      'You share nothing with the family yet.';

  @override
  String get organizeScreensStopSharing => 'Stop sharing';

  @override
  String get organizeScreensActionFailed => 'The action failed.';

  @override
  String get settingsScreenTitle => 'Settings';

  @override
  String get settingsScreenViewing => 'Viewing';

  @override
  String get settingsScreenAssetViewer => 'Asset viewer';

  @override
  String get settingsScreenAssetViewerHint => 'How photos and videos open';

  @override
  String get settingsScreenPhotoGrid => 'Photo grid';

  @override
  String get settingsScreenPhotoGridHint => 'How the timeline is laid out';

  @override
  String get settingsScreenPreferences => 'Preferences';

  @override
  String get settingsScreenPreferencesHint => 'Theme, color and feedback';

  @override
  String get settingsScreenLanguageHint => 'The app\'s language';

  @override
  String get settingsScreenThisPhone => 'This phone';

  @override
  String get settingsScreenBackup => 'Backup';

  @override
  String get settingsScreenBackupHint => 'What this phone sends to the server';

  @override
  String get settingsScreenFreeUpSpace => 'Free up space';

  @override
  String get settingsScreenFreeUpSpaceHint =>
      'Remove what is safe on the server';

  @override
  String get settingsScreenSyncStatus => 'Sync status';

  @override
  String get settingsScreenSyncStatusHint =>
      'What is on this phone and on the server';

  @override
  String get settingsScreenHomeWidget => 'Home screen widget';

  @override
  String get settingsScreenHomeWidgetHint => 'An album on the home screen';

  @override
  String get settingsScreenNotifications => 'Notifications';

  @override
  String get settingsScreenNotificationsHint => 'What the app tells you about';

  @override
  String get settingsScreenServer => 'Server';

  @override
  String get settingsScreenDevices => 'Devices';

  @override
  String get settingsScreenDevicesHint => 'Where this account is signed in';

  @override
  String get settingsScreenYourLibrary => 'Your library';

  @override
  String get settingsScreenYourLibraryHint => 'How much this account holds';

  @override
  String get settingsScreenNetworking => 'Networking';

  @override
  String get settingsScreenNetworkingHint => 'The addresses of your server';

  @override
  String get settingsScreenAdvanced => 'Advanced';

  @override
  String get settingsScreenAdvancedHint => 'Read-only mode and the image cache';

  @override
  String get settingsScreenWhatsNew => 'What\'s new';

  @override
  String get settingsScreenWhatsNewHint => 'The versions of Mediarr';

  @override
  String get settingsScreenReadOnlyOff => 'Turn off read-only mode';

  @override
  String get settingsScreenReadOnly => 'Read-only mode';

  @override
  String get settingsScreenReadOnlyHint =>
      'Only look: no uploading, editing or deleting from this app';

  @override
  String get settingsScreenCopyAlbums => 'Copy albums to the server';

  @override
  String get settingsScreenCopyAlbumsHint =>
      'Backed-up albums get an album of the same name on the server. Photos are only added, never removed';

  @override
  String get settingsScreenClearCache => 'Clear image cache';

  @override
  String get settingsScreenCacheEmpty => 'The image cache is empty.';

  @override
  String get settingsScreenPhotos => 'Photos';

  @override
  String get settingsScreenLoadFull => 'Load the full photo';

  @override
  String get settingsScreenLoadFullHint =>
      'Opens photos at full resolution. This uses more data and is slower';

  @override
  String get settingsScreenTapToNavigate => 'Tap to navigate';

  @override
  String get settingsScreenTapToNavigateHint =>
      'Tapping the left or right quarter of the screen goes to the previous or next photo';

  @override
  String get settingsScreenVideos => 'Videos';

  @override
  String get settingsScreenAutoPlay => 'Auto play videos';

  @override
  String get settingsScreenAutoPlayHint => 'Videos start when they are opened';

  @override
  String get settingsScreenLooping => 'Looping';

  @override
  String get settingsScreenLoopingHint => 'Videos start again when they end';

  @override
  String get settingsScreenPlayOriginal => 'Play the original video';

  @override
  String get settingsScreenPlayOriginalHint =>
      'Plays the original even when a converted version exists. It may have to buffer';

  @override
  String get settingsScreenLayout => 'Layout';

  @override
  String settingsScreenPerRow(String count) {
    return 'Photos per row ($count)';
  }

  @override
  String get settingsScreenGroupBy => 'Group by';

  @override
  String get settingsScreenMonthDay => 'Month + day';

  @override
  String get settingsScreenMonth => 'Month';

  @override
  String get settingsScreenTheme => 'Theme';

  @override
  String get settingsScreenPrimaryColor => 'Primary color';

  @override
  String get settingsScreenHaptics => 'Haptic feedback';

  @override
  String get settingsScreenEnabled => 'Enabled';

  @override
  String get settingsScreenNotificationsNotYet =>
      'Notifications are not available yet.';

  @override
  String get settingsScreenPhotosAndVideos => 'Photos and videos';

  @override
  String get settingsScreenPhone => 'Phone';

  @override
  String get settingsScreenAlbums => 'Albums';

  @override
  String get settingsScreenOther => 'Other';

  @override
  String get settingsScreenMemories => 'Memories';

  @override
  String get settingsScreenBackedUp => 'Backed up';

  @override
  String get settingsScreenCheckAgain => 'Check again';

  @override
  String settingsScreenRetryFailed(String count) {
    return 'Send the $count that failed again';
  }

  @override
  String get settingsScreenRemoved => 'Removed.';

  @override
  String get settingsScreenSaved => 'Saved.';

  @override
  String settingsScreenMainAddress(String address) {
    return 'Main address: $address';
  }

  @override
  String get settingsScreenSecondAddress => 'Second address';

  @override
  String get settingsScreenSecondAddressHint =>
      'Used when the main one does not answer, such as away from home';

  @override
  String get settingsScreenSave => 'Save';

  @override
  String get settingsScreenCouldNotLoad => 'This could not be loaded.';

  @override
  String get settingsScreenThisDevice => 'This device';

  @override
  String get settingsScreenSignOut => 'Sign out';

  @override
  String get settingsScreenSignOutOthers => 'Sign out all the others';

  @override
  String get settingsScreenFavorites => 'Favorites';

  @override
  String get settingsScreenArchive => 'Archive';

  @override
  String get settingsScreenTrash => 'Trash';

  @override
  String get settingsScreenUsed => 'Used';

  @override
  String get settingsScreenYourAccount => 'Your account';

  @override
  String settingsScreenMemorySeconds(String seconds) {
    return 'Seconds for each picture in memories ($seconds)';
  }

  @override
  String settingsScreenMinFaces(String count) {
    return 'Fewest photos for a person to be listed ($count)';
  }

  @override
  String get settingsScreenAlbumOrder => 'Order in a new album';

  @override
  String get settingsScreenNewestFirst => 'Newest first';

  @override
  String get settingsScreenOldestFirst => 'Oldest first';

  @override
  String get sessionDeviceNotApproved =>
      'An administrator has to approve this device before it can sign in.';

  @override
  String get sessionEnterAddress => 'Enter the address of your server.';

  @override
  String get sessionAddressInvalid => 'That server address is not valid.';

  @override
  String get sessionNoServer => 'No Mediarr server answered at that address.';

  @override
  String sessionUnreachableCheck(String reason) {
    return 'Could not reach the server. Check the address. ($reason)';
  }

  @override
  String sessionUnreachable(String reason) {
    return 'Could not reach the server. ($reason)';
  }

  @override
  String get sessionCodeWrong => 'The code is wrong.';

  @override
  String get sessionWrongPassword => 'Wrong email or password.';

  @override
  String get sessionTooManyAttempts => 'Too many attempts. Try again later.';

  @override
  String sessionSignInFailed(String code) {
    return 'Sign-in failed ($code).';
  }

  @override
  String get sessionNoSession => 'The server did not start a session.';

  @override
  String get sessionCancelled => 'Signing in was cancelled.';

  @override
  String get sessionSsoOff =>
      'Single sign-on is not turned on for this server.';

  @override
  String get sessionSsoFailed =>
      'Single sign-on did not work. You may not have an account on this server.';

  @override
  String get sessionCodeExpired =>
      'This code has expired or was already used. Make a new one.';

  @override
  String get sessionNoAnswer => 'The server did not answer.';

  @override
  String get sessionNotAllowed => 'The sign-in was not allowed.';

  @override
  String get sessionSignInExpired =>
      'This sign-in has expired. Make a new code.';

  @override
  String get sessionNobodyAnswered =>
      'Nobody answered in time. Make a new code.';

  @override
  String get tusSignedOut => 'You are signed out. Sign in again.';

  @override
  String tusRejected(String code, String body) {
    return 'The server rejected this file ($code). $body';
  }

  @override
  String albumsScreenInside(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albums',
      one: '1 album',
    );
    return '$_temp0';
  }

  @override
  String get albumsScreenLoadFailed =>
      'Albums could not be loaded. Check the connection.';

  @override
  String get albumsScreenTryAgain => 'Try again';

  @override
  String get albumsScreenNoAlbums => 'No albums yet.';

  @override
  String get albumsScreenNoMatch => 'No album matches this.';

  @override
  String get albumsScreenSortUpdated => 'Last change';

  @override
  String get albumsScreenName => 'Name';

  @override
  String get albumsScreenSortDate => 'Photo date';

  @override
  String get albumsScreenTitle => 'Albums';

  @override
  String get albumsScreenNew => 'New';

  @override
  String get albumsScreenSort => 'Sort';

  @override
  String get albumsScreenSearchFilter => 'Search and filter';

  @override
  String get albumsScreenShowList => 'Show as a list';

  @override
  String get albumsScreenShowGrid => 'Show as a grid';

  @override
  String get albumsScreenSearchAlbums => 'Search albums';

  @override
  String get albumsScreenAll => 'All';

  @override
  String get albumsScreenSharedWithMe => 'Shared with me';

  @override
  String get albumsScreenMine => 'My albums';

  @override
  String albumsScreenItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
    );
    return '$_temp0';
  }

  @override
  String get albumsScreenSmart => 'Smart';

  @override
  String get albumsScreenOwned => 'Owned';

  @override
  String get albumsScreenNotCreated => 'The album was not created.';

  @override
  String get albumsScreenNewAlbum => 'New album';

  @override
  String get albumsScreenDescription => 'Description';

  @override
  String get albumsScreenSmartAlbum => 'Smart album: fills itself from rules';

  @override
  String get albumsScreenCreate => 'Create';

  @override
  String get adminScreenTitle => 'Administration';

  @override
  String get adminScreenOverview => 'Overview';

  @override
  String get adminScreenOverviewHint => 'Users, photos, disk and versions';

  @override
  String get adminScreenUsers => 'Users';

  @override
  String get adminScreenUsersHint =>
      'Add users and set how much they may store';

  @override
  String get adminScreenServerSettings => 'Server settings';

  @override
  String get adminScreenServerSettingsHint =>
      'Trash, quality, faces, jobs, sign-in';

  @override
  String get adminScreenEmail => 'Email';

  @override
  String get adminScreenEmailHint => 'Where messages are sent from';

  @override
  String get adminScreenSecurity => 'Security';

  @override
  String get adminScreenSecurityHint =>
      'Single sign-on, devices, addresses, attempts';

  @override
  String get adminScreenJobs => 'Jobs';

  @override
  String get adminScreenJobsHint => 'Queues and jobs that failed';

  @override
  String get adminScreenAuditLog => 'Audit log';

  @override
  String get adminScreenAuditLogHint => 'Who changed what';

  @override
  String get adminScreenBackupHint => 'Copies of the library';

  @override
  String get adminScreenBackupDevices => 'All backup devices';

  @override
  String get adminScreenBackupDevicesHint => 'Every phone that backs up';

  @override
  String get adminScreenStorageTemplate => 'Storage template';

  @override
  String get adminScreenStorageTemplateHint =>
      'How originals are laid out on the disk';

  @override
  String get adminAuditEmpty => 'Nothing was changed yet.';

  @override
  String get adminAuditShowOlder => 'Show older';

  @override
  String adminUsersAdded(String email) {
    return '$email was added.';
  }

  @override
  String get adminUsersAddUser => 'Add a user';

  @override
  String get adminUsersAdministrator => 'Administrator';

  @override
  String adminUsersStoredOf(String stored, String quota) {
    return '$stored of $quota';
  }

  @override
  String get adminUsersNoLimit => 'no limit';

  @override
  String adminUsersQuotaTooltip(String email) {
    return 'How much $email may store';
  }

  @override
  String get adminUsersEmail => 'Email';

  @override
  String get adminUsersName => 'Name';

  @override
  String get adminUsersPassword => 'Password';

  @override
  String get adminUsersCancel => 'Cancel';

  @override
  String get adminUsersAdd => 'Add';

  @override
  String get adminUsersQuotaInvalid =>
      'Type a number of gigabytes, or nothing for no limit.';

  @override
  String adminUsersStorageFor(String email) {
    return 'Storage for $email';
  }

  @override
  String get adminUsersLimitGb => 'Limit in GB';

  @override
  String get adminUsersEmptyNoLimit => 'Empty means no limit.';

  @override
  String get profileScreenNotSaved => 'The profile could not be saved.';

  @override
  String get profileScreenPictureNotSent => 'The picture could not be sent.';

  @override
  String get profileScreenPictureNotRemoved =>
      'The picture could not be removed.';

  @override
  String get profileScreenTitle => 'Profile';

  @override
  String get profileScreenChangePicture => 'Change picture';

  @override
  String get profileScreenAddPicture => 'Add a picture';

  @override
  String get profileScreenRemove => 'Remove';

  @override
  String get profileScreenEmailAddress => 'Email address';

  @override
  String get profileScreenCurrentPassword =>
      'Current password, to change the email';

  @override
  String get serverStatusStorage => 'Storage';

  @override
  String serverStatusUsedOf(String used, String total) {
    return '$used of $total used';
  }

  @override
  String get serverStatusOnline => 'Server online';

  @override
  String get serverStatusMaintained => 'Server is being maintained';

  @override
  String get serverStatusOffline => 'Server offline';

  @override
  String serverStatusVersionAvailable(String version) {
    return 'Version $version is available';
  }

  @override
  String get serverStatusNewVersion => 'A new version is available';

  @override
  String serverStatusUpdateBody(String latest, String version) {
    return 'Mediarr $latest is available. This server runs $version. The server administrator updates it with:\n\ndocker compose pull && docker compose up -d';
  }

  @override
  String get serverStatusOk => 'OK';

  @override
  String get storiesStripLastWeek => 'The last week';

  @override
  String storiesStripYearsAgo(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years years ago',
      one: '1 year ago',
    );
    return '$_temp0';
  }

  @override
  String storiesStripItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get backupScreenNotYet => 'not yet';

  @override
  String backupScreenLastBackup(String when) {
    return 'last backup $when';
  }

  @override
  String backupScreenUpTo(String size) {
    return 'up to $size';
  }

  @override
  String get backupScreenInvited => 'Invited';

  @override
  String get backupScreenStopped => 'Stopped';

  @override
  String get backupScreenActive => 'Active';

  @override
  String backupScreenDeletedKept(String size) {
    return 'deleted, kept: $size';
  }

  @override
  String get backupScreenActionFailed => 'The action failed.';

  @override
  String get backupScreenSaved => 'Saved.';

  @override
  String get backupScreenBackupStarted => 'The backup has started.';

  @override
  String get backupScreenRestoreTestStarted => 'The restore test has started.';

  @override
  String get backupScreenPaired => 'Paired. The next backup goes there too.';

  @override
  String get backupScreenKeepForSomeone => 'Keep a backup for someone';

  @override
  String get backupScreenForWhom => 'For whom';

  @override
  String get backupScreenAtMostGb => 'At most (GB)';

  @override
  String get backupScreenOtherServerAddress =>
      'The address the other server reaches you at';

  @override
  String get backupScreenCancel => 'Cancel';

  @override
  String get backupScreenInvite => 'Invite';

  @override
  String get backupScreenInvitationFailed => 'The invitation failed.';

  @override
  String backupScreenCodeFor(String name) {
    return 'Code for $name';
  }

  @override
  String backupScreenSendItToAdmin(String when) {
    return 'Send it to the administrator of the other server, who pastes or scans it. It works once, until $when.';
  }

  @override
  String get backupScreenPlainHttp =>
      'Over plain HTTP the key can be read on the way. Use HTTPS or a VPN.';

  @override
  String get backupScreenCopy => 'Copy';

  @override
  String get backupScreenDone => 'Done';

  @override
  String backupScreenHowMuchFor(String name) {
    return 'How much for $name';
  }

  @override
  String get backupScreenSave => 'Save';

  @override
  String backupScreenDeleteCopyOf(String name) {
    return 'Delete the copy of $name?';
  }

  @override
  String backupScreenTypeToDelete(String name) {
    return 'Type “$name” to delete it';
  }

  @override
  String get backupScreenDeleteTheCopy => 'Delete the copy';

  @override
  String get backupScreenScheduledBackup => 'Scheduled backup';

  @override
  String get backupScreenOnceADay => 'Once a day, at the hour below';

  @override
  String backupScreenExplain(String folder) {
    return 'Originals and the database, encrypted. The destination is a folder inside $folder, or an s3: or b2: address. Write the password down somewhere other than this server.';
  }

  @override
  String get backupScreenBackupFolder => 'the backup folder';

  @override
  String get backupScreenDestination => 'Destination';

  @override
  String get backupScreenPasswordSaved => 'Password (saved, type to change)';

  @override
  String get backupScreenBackupPassword => 'Backup password';

  @override
  String get backupScreenAccessKeySaved => 'Access key (saved)';

  @override
  String get backupScreenAccessKey => 'Access key (S3, B2)';

  @override
  String get backupScreenSecretKey => 'Secret key (S3, B2)';

  @override
  String get backupScreenHourOfDay => 'Hour of the day (0-23)';

  @override
  String get backupScreenBackUpNow => 'Back up now';

  @override
  String get backupScreenTestBringingBack => 'Test bringing it back';

  @override
  String get backupScreenHistory => 'History';

  @override
  String get backupScreenRunBackup => 'Backup';

  @override
  String get backupScreenRunRestoreTest => 'Restore test';

  @override
  String backupScreenFiles(String count) {
    return 'files $count';
  }

  @override
  String get backupScreenMyCopyAtOthers => 'My copy at others';

  @override
  String get backupScreenTwoServers =>
      'Two Mediarr servers keep an encrypted copy of each other. The one that keeps it cannot read it, and what is deleted from it is kept for 90 more days.';

  @override
  String get backupScreenNoHttps => 'No HTTPS';

  @override
  String get backupScreenMore => 'More';

  @override
  String get backupScreenRemove => 'Remove';

  @override
  String get backupScreenCodeFromOther => 'Code from the other Mediarr';

  @override
  String get backupScreenScanQr => 'Scan the QR code';

  @override
  String get backupScreenPairing => 'Pairing…';

  @override
  String get backupScreenPair => 'Pair';

  @override
  String get backupScreenSnapshots => 'Snapshots before upgrades';

  @override
  String get backupScreenSnapshotsExplain =>
      'Before each upgrade that changes the database, Mediarr keeps a snapshot of it. The last three are kept.';

  @override
  String get backupScreenNoSnapshots =>
      'No snapshots yet. The first is made at the next upgrade that changes the database.';

  @override
  String get backupScreenEarlierVersion => 'Earlier version';

  @override
  String get backupScreenDeleteSnapshot => 'Delete snapshot';

  @override
  String get backupScreenGoBackHow =>
      'To go back to the newest one, in the folder with docker-compose.yml:';

  @override
  String get backupScreenDeleteThisSnapshot => 'Delete this snapshot?';

  @override
  String get backupScreenNoGoingBack =>
      'It will no longer be possible to go back to it.';

  @override
  String get backupScreenDelete => 'Delete';

  @override
  String get backupScreenNotDeleted => 'Not deleted.';

  @override
  String get backupScreenIKeepForOthers => 'I keep for others';

  @override
  String get backupScreenNoNewCode => 'No new code.';

  @override
  String backupScreenFilesBroughtBack(String count) {
    return 'Files brought back: $count.';
  }

  @override
  String get backupScreenNewCode => 'New code';

  @override
  String get backupScreenResume => 'Resume';

  @override
  String get backupScreenStop => 'Stop';

  @override
  String get backupScreenSize => 'Size';

  @override
  String get backupScreenBringBackDeleted => 'Bring back what was deleted';

  @override
  String get backupScreenTitle => 'Backup';

  @override
  String get backupScreenLoadFailed =>
      'The backup settings could not be loaded.';

  @override
  String get backupScreenScanTheCode => 'Scan the code';

  @override
  String get duplicatesScreenFavorite => 'Favorite';

  @override
  String get duplicatesScreenOriginal => 'Original';

  @override
  String get duplicatesScreenSavedAgain => 'Saved again by an app';

  @override
  String get duplicatesScreenHasLocation => 'Has a location';

  @override
  String get duplicatesScreenHasDescription => 'Has a description';

  @override
  String get duplicatesScreenNoDate => 'No date';

  @override
  String get duplicatesScreenReasonFavorite => 'a favorite';

  @override
  String get duplicatesScreenReasonCameraOriginal => 'the camera\'s original';

  @override
  String get duplicatesScreenReasonOthersSaved =>
      'the others were saved again by apps';

  @override
  String get duplicatesScreenReasonHighestResolution =>
      'the highest resolution';

  @override
  String get duplicatesScreenReasonLargestFile => 'the largest file';

  @override
  String get duplicatesScreenReasonEqual =>
      'they are equal, so any one can stay';

  @override
  String get duplicatesScreenReasonSharpest => 'the sharpest';

  @override
  String get duplicatesScreenCancel => 'Cancel';

  @override
  String get duplicatesScreenResolveThisGroup => 'Resolve this group?';

  @override
  String get duplicatesScreenKeptTakesOver =>
      'The kept photo takes over the albums, tags, favorite, description, rating, location and names of people from the others. They go to the trash and can be restored.';

  @override
  String get duplicatesScreenResolve => 'Resolve';

  @override
  String get duplicatesScreenResolved =>
      'Resolved. The copies are in the trash.';

  @override
  String get duplicatesScreenActionFailed => 'The action failed.';

  @override
  String get duplicatesScreenResolveEveryIdentical =>
      'Resolve every identical picture?';

  @override
  String get duplicatesScreenResolveAllDuplicates => 'Resolve all duplicates?';

  @override
  String duplicatesScreenResolveAllBody(
    String groups,
    String trashed,
    String size,
  ) {
    return 'Groups: $groups. $trashed photos go to the trash, which frees $size once it is emptied. In each group the proposed photo stays and takes over what the others had.';
  }

  @override
  String get duplicatesScreenResolveAll => 'Resolve all';

  @override
  String get duplicatesScreenSamePicture => 'Same picture';

  @override
  String get duplicatesScreenAlike => 'Alike';

  @override
  String duplicatesScreenProposedToKeep(String reason, String size) {
    return 'Proposed to keep: $reason · frees $size';
  }

  @override
  String get duplicatesScreenNotDuplicates => 'Not duplicates';

  @override
  String duplicatesScreenResolveToTrash(String count) {
    return 'Resolve ($count to the trash)';
  }

  @override
  String get duplicatesScreenTitle => 'Duplicates';

  @override
  String get duplicatesScreenLoadFailed => 'Duplicates could not be loaded.';

  @override
  String duplicatesScreenPending(String count) {
    return 'Photos still being compared: $count.';
  }

  @override
  String get duplicatesScreenNoneFound => 'No similar photos were found.';

  @override
  String get duplicatesScreenTickWhatToKeep =>
      'Tick what to keep. These are only proposals, and nothing is removed without your confirmation.';

  @override
  String duplicatesScreenShowing(String shown, String total) {
    return 'Showing $shown of $total.';
  }

  @override
  String duplicatesScreenResolving(String done, String total) {
    return 'Resolving duplicates: $done of $total';
  }

  @override
  String duplicatesScreenResolveIdentical(String count) {
    return 'Resolve the identical ($count)';
  }

  @override
  String duplicatesScreenResolveAllAsProposed(String count) {
    return 'Resolve all as proposed ($count)';
  }

  @override
  String get duplicatesScreenStackLoadFailed =>
      'This stack could not be loaded.';

  @override
  String get duplicatesScreenSplitStack => 'Split the stack';

  @override
  String get duplicatesScreenMakeMain => 'Make it the main shot';

  @override
  String accountSheetVersionBuild(String version, String build) {
    return '$version build $build';
  }

  @override
  String get accountSheetEditProfile => 'Edit profile';

  @override
  String get accountSheetClose => 'Close';

  @override
  String accountSheetPhotosAndVideos(String count) {
    return '$count photos and videos';
  }

  @override
  String accountSheetUsed(String size) {
    return '$size used';
  }

  @override
  String accountSheetFilesFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files could not be processed',
      one: '1 file could not be processed',
    );
    return '$_temp0';
  }

  @override
  String get accountSheetAppearance => 'Appearance';

  @override
  String get accountSheetDark => 'Dark';

  @override
  String get accountSheetLight => 'Light';

  @override
  String get accountSheetSystem => 'System';

  @override
  String get accountSheetServerDisk => 'Server disk';

  @override
  String get accountSheetLoading => 'Loading…';

  @override
  String get accountSheetServerNoAnswer => 'The server does not answer.';

  @override
  String accountSheetDiskUsed(String used, String total) {
    return '$used of $total used';
  }

  @override
  String get accountSheetAppVersion => 'App version';

  @override
  String get accountSheetServerVersion => 'Server version';

  @override
  String get accountSheetNewVersion => 'New version';

  @override
  String accountSheetIsAvailable(String version) {
    return '$version is available';
  }

  @override
  String get accountSheetServer => 'Server';

  @override
  String get accountSheetServerAddress => 'Server address';

  @override
  String get accountSheetFreeUpSpace => 'Free up space';

  @override
  String get accountSheetProfile => 'Profile';

  @override
  String get accountSheetSignInOnAnotherDevice => 'Sign in on another device';

  @override
  String get accountSheetBackupDevices => 'Backup devices';

  @override
  String get accountSheetImport => 'Import';

  @override
  String get accountSheetAdministration => 'Administration';

  @override
  String get accountSheetBackup => 'Backup';

  @override
  String get accountSheetAllBackupDevices => 'All backup devices';

  @override
  String get accountSheetStorageTemplate => 'Storage template';

  @override
  String get accountSheetSettings => 'Settings';

  @override
  String get accountSheetSignOut => 'Sign out';

  @override
  String get accountSheetDocumentation => 'Documentation';

  @override
  String get accountSheetLicenses => 'Licenses';

  @override
  String get searchFiltersSheetFilters => 'Filters';

  @override
  String get searchFiltersSheetDate => 'Date';

  @override
  String get searchFiltersSheetFrom => 'From';

  @override
  String get searchFiltersSheetTo => 'To';

  @override
  String get searchFiltersSheetType => 'Type';

  @override
  String get searchFiltersSheetAll => 'All';

  @override
  String get searchFiltersSheetPhotos => 'Photos';

  @override
  String get searchFiltersSheetVideos => 'Videos';

  @override
  String get searchFiltersSheetPeople => 'People';

  @override
  String get searchFiltersSheetAnyOfThem => 'Any of them, not all together';

  @override
  String get searchFiltersSheetWhereAndWith => 'Where and with what';

  @override
  String get searchFiltersSheetPlace => 'Place';

  @override
  String get searchFiltersSheetCamera => 'Camera';

  @override
  String get searchFiltersSheetLens => 'Lens';

  @override
  String get searchFiltersSheetRating => 'Rating';

  @override
  String get searchFiltersSheetAnyRating => 'Any';

  @override
  String get searchFiltersSheetTags => 'Tags';

  @override
  String get searchFiltersSheetAlbum => 'Album';

  @override
  String get searchFiltersSheetAnyAlbum => 'Any';

  @override
  String get searchFiltersSheetInNoAlbum => 'In no album';

  @override
  String get searchFiltersSheetFavouritesOnly => 'Favourites only';

  @override
  String get searchFiltersSheetClear => 'Clear';

  @override
  String get searchFiltersSheetApply => 'Apply';

  @override
  String get adminEmailPortNumber => 'The port must be a number.';

  @override
  String get adminEmailSaved => 'Email settings are saved.';

  @override
  String get adminEmailTestSent => 'A test message was sent to you.';

  @override
  String get adminEmailTitle => 'Email';

  @override
  String get adminEmailSendEmail => 'Send email';

  @override
  String get adminEmailSmtpServer => 'SMTP server';

  @override
  String get adminEmailPort => 'Port';

  @override
  String get adminEmailEncryption => 'Encryption';

  @override
  String get adminEmailNone => 'None';

  @override
  String get adminEmailUserName => 'User name';

  @override
  String get adminEmailPassword => 'Password';

  @override
  String get adminEmailPasswordSaved => 'A password is saved. Empty keeps it.';

  @override
  String get adminEmailFrom => 'From';

  @override
  String get adminEmailServerAddress => 'Address of this server';

  @override
  String get adminEmailForLinks => 'For links in messages';

  @override
  String get adminEmailSave => 'Save';

  @override
  String get adminEmailSendTest => 'Send a test message';

  @override
  String photoEditorScreenActionFailed(String reason) {
    return 'The action failed. $reason';
  }

  @override
  String get photoEditorScreenEdit => 'Edit';

  @override
  String get photoEditorScreenRotate => 'Rotate';

  @override
  String get photoEditorScreenBrightness => 'Brightness';

  @override
  String get photoEditorScreenContrast => 'Contrast';

  @override
  String get photoEditorScreenSaturation => 'Saturation';

  @override
  String get photoEditorScreenNoFilter => 'No filter';

  @override
  String get photoEditorScreenBlackAndWhite => 'Black and white';

  @override
  String get photoEditorScreenWarm => 'Warm';

  @override
  String get photoEditorScreenCool => 'Cool';

  @override
  String get photoEditorScreenVintage => 'Vintage';

  @override
  String get photoEditorScreenVivid => 'Vivid';

  @override
  String get photoEditorScreenBackToOriginal => 'Back to the original';

  @override
  String get photoEditorScreenSave => 'Save';

  @override
  String get homeWidgetScreenHowToIos =>
      'Then touch and hold an empty spot on the home screen, tap + (or Edit, Add Widget), and choose Mediarr.';

  @override
  String get homeWidgetScreenHowToAndroid =>
      'Then touch and hold an empty spot on the home screen, tap Widgets, and drag Mediarr to it.';

  @override
  String get homeWidgetScreenFetchesItself =>
      'The widget fetches its photos itself, and keeps a few.';

  @override
  String get homeWidgetScreenFetching => 'Fetching its photos…';

  @override
  String homeWidgetScreenPicturesKept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos kept on this phone for it',
      one: '1 photo kept on this phone for it',
    );
    return '$_temp0';
  }

  @override
  String get homeWidgetScreenDidNotWork => 'It did not work.';

  @override
  String get homeWidgetScreenTitle => 'Home screen widget';

  @override
  String homeWidgetScreenIntro(String howTo) {
    return 'The widget shows a photo from the album you choose here, a different one every hour, also without a connection. $howTo';
  }

  @override
  String homeWidgetScreenShowing(String album) {
    return 'Showing $album';
  }

  @override
  String get homeWidgetScreenShowsNothing => 'The widget shows nothing now.';

  @override
  String get homeWidgetScreenTurnOff => 'Turn off';

  @override
  String get homeWidgetScreenAlbum => 'Album';

  @override
  String get homeWidgetScreenNoAlbums => 'There are no albums yet.';

  @override
  String homeWidgetScreenShows(String album) {
    return 'The widget shows $album.';
  }

  @override
  String get homeWidgetNoKey => 'The server did not make a key for the widget.';

  @override
  String get settingsAccentMidnightBlue => 'Midnight blue';

  @override
  String get settingsAccentGold => 'Gold';

  @override
  String get settingsAccentViolet => 'Violet';

  @override
  String get settingsAccentMint => 'Mint';

  @override
  String get settingsAccentRose => 'Rose';

  @override
  String get settingsThemeAuto => 'Auto';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get homeScreenMedia => 'Media';

  @override
  String get homeScreenSearch => 'Search';

  @override
  String get homeScreenAlbums => 'Albums';

  @override
  String get homeScreenLibrary => 'Library';

  @override
  String get homeScreenAdd => 'Add';

  @override
  String homeScreenAddUploading(String count) {
    return 'Add, $count uploading';
  }

  @override
  String get panoramaViewCannotBeShown => 'The panorama cannot be shown.';

  @override
  String get panoramaViewLabel => '360° panorama';

  @override
  String fixSheetChanged(int changed) {
    return 'Changed: $changed';
  }

  @override
  String get fixSheetCameraClockWrong => 'When the camera\'s clock was wrong.';

  @override
  String get fixSheetEarlier => 'Earlier';

  @override
  String get fixSheetLater => 'Later';

  @override
  String get fixSheetDays => 'Days';

  @override
  String get fixSheetHours => 'Hours';

  @override
  String get fixSheetMinutes => 'Minutes';

  @override
  String get fixSheetOneDateForAll =>
      'One date for all, a minute apart so they keep their order.';

  @override
  String get fixSheetChooseDateTime => 'Choose the date and time';

  @override
  String get fixSheetTripHint => 'When the camera kept home\'s time on a trip.';

  @override
  String get fixSheetCameraClockWasOn => 'The camera\'s clock was on';

  @override
  String get fixSheetTheyWereTakenIn => 'They were taken in';

  @override
  String get fixSheetZoneFromPlaceHint =>
      'Photos with a location get the time zone of the place, summer time included; the clock stays as it was.';

  @override
  String get fixSheetDatesByHandRemoved => 'Dates set by hand are taken away.';

  @override
  String get fixSheetNeighboursHint =>
      'Photos without a location get the place of the photo with one taken closest to them.';

  @override
  String get fixSheetAtMostMinutesApart => 'At most minutes apart';

  @override
  String get fixSheetTrackHint =>
      'Photos without a location get the place from the track at the moment they were taken. Get the date right first.';

  @override
  String get fixSheetChooseGpx => 'Choose a GPX file';

  @override
  String get fixSheetFindPlace => 'Find a place';

  @override
  String get fixSheetLatitude => 'Latitude';

  @override
  String get fixSheetLongitude => 'Longitude';

  @override
  String get fixSheetLocationGoes => 'The location goes, and stays gone.';

  @override
  String get fixSheetLocationsByHandRemoved =>
      'Locations set by hand are taken away.';

  @override
  String fixSheetDateTitle(int count) {
    return 'Date and time · $count';
  }

  @override
  String fixSheetLocationTitle(int count) {
    return 'Location · $count';
  }

  @override
  String get fixSheetShift => 'Shift';

  @override
  String get fixSheetSetDate => 'Set a date';

  @override
  String get fixSheetZoneFromPlace => 'Zone from the place';

  @override
  String get fixSheetTrip => 'A trip';

  @override
  String get fixSheetFromFile => 'From the file';

  @override
  String get fixSheetFromNearby => 'From nearby photos';

  @override
  String get fixSheetFromTrack => 'From a GPX track';

  @override
  String get fixSheetSetPlace => 'Set a place';

  @override
  String get fixSheetClearLocation => 'Take the location away';

  @override
  String fixSheetWillChange(int changed) {
    return 'Will change: $changed';
  }

  @override
  String fixSheetNothingToGoBy(int skipped) {
    return 'nothing to go by: $skipped';
  }

  @override
  String get fixSheetNoLocation => 'no location';

  @override
  String get fixSheetCancel => 'Cancel';

  @override
  String get fixSheetSave => 'Save';

  @override
  String get adminSecurityRulesSaved => 'The rules are saved.';

  @override
  String get adminSecuritySsoSaved => 'Single sign-on is saved.';

  @override
  String get adminSecurityForgetTitle => 'Forget this device?';

  @override
  String adminSecurityApproveAgain(String email) {
    return '$email on it has to be approved again.';
  }

  @override
  String get adminSecurityCancel => 'Cancel';

  @override
  String get adminSecurityForget => 'Forget';

  @override
  String get adminSecurityDeviceForgotten => 'The device is forgotten.';

  @override
  String get adminSecurityTitle => 'Security';

  @override
  String get adminSecuritySingleSignOn => 'Single sign-on';

  @override
  String get adminSecurityIssuer => 'Issuer';

  @override
  String get adminSecurityIssuerHelp => 'Empty turns single sign-on off';

  @override
  String get adminSecurityClientId => 'Client ID';

  @override
  String get adminSecurityClientSecret => 'Client secret';

  @override
  String get adminSecuritySecretSaved => 'A secret is saved. Empty keeps it.';

  @override
  String get adminSecurityButtonLabel => 'Button label';

  @override
  String get adminSecurityAutoCreate => 'Create an account on first sign-in';

  @override
  String get adminSecurityLinkAdmins => 'Administrators may sign in this way';

  @override
  String get adminSecuritySaveSso => 'Save single sign-on';

  @override
  String get adminSecurityRules => 'Rules';

  @override
  String get adminSecurityApprovalRequired => 'New devices must be approved';

  @override
  String get adminSecurityAllowlist =>
      'Only these addresses may reach the server';

  @override
  String adminSecurityYourAddress(String address) {
    return 'Your address now: $address';
  }

  @override
  String get adminSecurityAddresses => 'Addresses and networks';

  @override
  String get adminSecurityAddressesHelp =>
      'One per line, such as 192.168.1.0/24';

  @override
  String get adminSecuritySaveRules => 'Save the rules';

  @override
  String get adminSecurityDevices => 'Devices';

  @override
  String get adminSecurityNoDevices => 'No device has tried to sign in yet.';

  @override
  String adminSecurityLastSeen(String time) {
    return 'last $time';
  }

  @override
  String get adminSecurityDeviceApproved => 'The device may sign in.';

  @override
  String get adminSecurityApprove => 'Approve';

  @override
  String get adminSecurityAttempts => 'Attempts to get in';

  @override
  String get adminSecuritySignedIn => 'Signed in';

  @override
  String get adminSecurityWrongSignIn => 'Wrong sign-in';

  @override
  String get adminSecurityTooManyAttempts => 'Too many attempts';

  @override
  String get adminSecurityAddressBlocked => 'Address blocked';

  @override
  String get adminSecurityDeviceNotApproved => 'Device not approved';

  @override
  String get adminSecurityPasswordReset => 'Password reset';

  @override
  String get adminSecurityNoAttempts => 'No attempts yet.';

  @override
  String get adminSecurityShowOlder => 'Show older';

  @override
  String adminCommonNoAnswer(String code) {
    return 'The server did not answer ($code).';
  }

  @override
  String get devicesScreenQuiet => 'Quiet';

  @override
  String get devicesScreenNeedsALook => 'Needs a look';

  @override
  String get devicesScreenAllGood => 'All good';

  @override
  String devicesScreenConfirmed(String count) {
    return '$count files confirmed by the server';
  }

  @override
  String devicesScreenOfSent(String line, String files) {
    return '$line, of $files the device sent';
  }

  @override
  String devicesScreenWaiting(String count) {
    return 'waiting $count';
  }

  @override
  String devicesScreenNotSent(String count) {
    return 'not sent $count';
  }

  @override
  String devicesScreenInTrash(String count) {
    return 'in the trash $count';
  }

  @override
  String devicesScreenGone(String count) {
    return 'no longer on the server $count';
  }

  @override
  String get devicesScreenNever => 'Never';

  @override
  String devicesScreenDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get devicesScreenNotLoaded => 'Not loaded.';

  @override
  String devicesScreenRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get devicesScreenRemoveBody =>
      'Its photos stay on the server. If it reports again, it comes back.';

  @override
  String get devicesScreenCancel => 'Cancel';

  @override
  String get devicesScreenRemove => 'Remove';

  @override
  String get devicesScreenNotRemoved => 'Not removed.';

  @override
  String get devicesScreenSaved => 'Saved.';

  @override
  String get devicesScreenNotSaved => 'Not saved.';

  @override
  String devicesScreenThisPhone(String name) {
    return '$name · This phone';
  }

  @override
  String devicesScreenLastReport(String time) {
    return 'last report $time';
  }

  @override
  String devicesScreenOnDevice(String verified, String total) {
    return '$verified of $total on the device';
  }

  @override
  String get devicesScreenQuietWarning =>
      'It has not reported for longer than you allow. Open Mediarr on it and check that backup is on.';

  @override
  String get devicesScreenNothingMissing => 'Nothing is missing.';

  @override
  String get devicesScreenInTrashOnServer => 'in the trash on the server';

  @override
  String get devicesScreenDeletedFromServer => 'deleted from the server';

  @override
  String get devicesScreenWhatIsMissing => 'What is missing';

  @override
  String get devicesScreenHide => 'Hide';

  @override
  String get devicesScreenTryingAgain => 'Trying again.';

  @override
  String get devicesScreenTryAgain => 'Try again';

  @override
  String get devicesScreenAllBackupDevices => 'All backup devices';

  @override
  String get devicesScreenBackupDevices => 'Backup devices';

  @override
  String get devicesScreenAllIntro =>
      'Every user’s devices that back up. When one goes quiet, its owner is warned.';

  @override
  String get devicesScreenIntro =>
      'Phones that back up, and how much from each is safe on the server. The server counts, from its own files.';

  @override
  String get devicesScreenDidNotLoad =>
      'The devices did not load. Pull to try again.';

  @override
  String get devicesScreenNoneReported => 'No device has reported yet.';

  @override
  String get devicesScreenNoneReportedTurnOn =>
      'No device has reported yet. Turn on automatic backup in Upload.';

  @override
  String get devicesScreenWarnMeAfter => 'Warn me after';

  @override
  String get devicesScreenWarnHelp =>
      'A notice here and on the web, and by e-mail if it is set up. Once, until the device reports again.';

  @override
  String timelineScreenActionFailed(String message) {
    return 'The action failed. $message';
  }

  @override
  String get timelineScreenSetVaultPin =>
      'Set a vault PIN first: Account > Vault.';

  @override
  String timelineScreenDeleteTitle(String count) {
    return 'Delete $count?';
  }

  @override
  String get timelineScreenTrashRestorable =>
      'They move to the trash, where they can be restored.';

  @override
  String timelineScreenTrashDays(int days) {
    return 'They move to the trash, where they stay for $days days and can be restored.';
  }

  @override
  String get timelineScreenCancel => 'Cancel';

  @override
  String get timelineScreenDelete => 'Delete';

  @override
  String get timelineScreenLoadFailed =>
      'Your photos could not be loaded. Check the connection.';

  @override
  String get timelineScreenTryAgain => 'Try again';

  @override
  String get timelineScreenEmpty =>
      'No photos yet. Add your first ones in the Upload tab.';

  @override
  String get timelineScreenMedia => 'Media';

  @override
  String get timelineScreenClearSelection => 'Clear selection';

  @override
  String get timelineScreenAddToAlbum => 'Add to album';

  @override
  String get timelineScreenShare => 'Share';

  @override
  String get timelineScreenAddToFavorites => 'Add to favorites';

  @override
  String get timelineScreenMore => 'More';

  @override
  String get timelineScreenArchive => 'Archive';

  @override
  String get timelineScreenAddTag => 'Add a tag';

  @override
  String get timelineScreenDateTimeMenu => 'Date and time…';

  @override
  String get timelineScreenLocationMenu => 'Location…';

  @override
  String get timelineScreenMoveToVault => 'Move to the vault';

  @override
  String timelineScreenMonthFailed(String month) {
    return '$month could not be loaded. Try again.';
  }

  @override
  String agentProgramOnSystem(String program, String system) {
    return '$program on $system';
  }

  @override
  String get agentUnknownDevice => 'Unknown device';

  @override
  String get agentMediarrApp => 'Mediarr app';

  @override
  String get agentNow => 'now';

  @override
  String agentMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String agentHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String agentDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String agentWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks ago',
      one: '1 week ago',
    );
    return '$_temp0';
  }

  @override
  String agentMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months ago',
      one: '1 month ago',
    );
    return '$_temp0';
  }

  @override
  String agentYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years ago',
      one: '1 year ago',
    );
    return '$_temp0';
  }

  @override
  String get slideshowScreenCrossfade => 'Crossfade';

  @override
  String get slideshowScreenSlide => 'Slide';

  @override
  String get slideshowScreenSlowZoom => 'Slow zoom';

  @override
  String get slideshowScreenNone => 'None';

  @override
  String get slideshowScreenSettings => 'Slideshow settings';

  @override
  String get slideshowScreenPace => 'Pace';

  @override
  String get slideshowScreenTransition => 'Transition';

  @override
  String get slideshowScreenShuffle => 'Shuffle';

  @override
  String get slideshowScreenLoop => 'Loop';

  @override
  String get slideshowScreenDateAndPlace => 'Date and place';

  @override
  String get slideshowScreenTheEnd => 'The end.';

  @override
  String get slideshowScreenPrevious => 'Previous';

  @override
  String get slideshowScreenPlay => 'Play';

  @override
  String get slideshowScreenPause => 'Pause';

  @override
  String get slideshowScreenNext => 'Next';

  @override
  String get slideshowScreenClose => 'Close';

  @override
  String notificationsAlbumShared(String subject) {
    return '\"$subject\" was shared with you';
  }

  @override
  String notificationsImportDone(String subject) {
    return 'The import from $subject finished';
  }

  @override
  String notificationsImportFailed(String subject) {
    return 'The import from $subject failed';
  }

  @override
  String notificationsDeviceQuiet(String subject) {
    return '$subject has stopped backing up';
  }

  @override
  String notificationsCopyForLate(String name) {
    return 'The copy for $name has not gone out for three days';
  }

  @override
  String notificationsCopyFromLate(String name) {
    return 'The copy from $name has not come in for three days';
  }

  @override
  String notificationsBackupFailed(String subject) {
    return 'A backup failed: $subject';
  }

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsNotRemoved => 'This could not be removed.';

  @override
  String get notificationsNotLoaded => 'This could not be loaded.';

  @override
  String get notificationsNone => 'No notifications.';

  @override
  String get notificationsRemove => 'Remove';

  @override
  String assetFactsNotSaved(String message) {
    return 'Not saved. $message';
  }

  @override
  String get assetFactsEditDetails => 'Edit details';

  @override
  String get assetFactsDateAndTime => 'Date and time';

  @override
  String get assetFactsFindPlace => 'Find a place';

  @override
  String get assetFactsLatitude => 'Latitude';

  @override
  String get assetFactsLongitude => 'Longitude';

  @override
  String get assetFactsDescription => 'Description';

  @override
  String get assetFactsUseFile => 'Use what the file says';

  @override
  String get assetFactsCancel => 'Cancel';

  @override
  String get assetFactsSave => 'Save';

  @override
  String assetFactsStars(String stars) {
    return '$stars of 5 stars';
  }

  @override
  String get documentsScreenNotEnabled =>
      'An administrator has not turned this album on.';

  @override
  String get documentsScreenNeedsAnalysis =>
      'This needs picture analysis to be on.';

  @override
  String get documentsScreenNoText => 'No photos with text yet.';

  @override
  String get documentsScreenLoadFailed => 'Documents could not be loaded.';

  @override
  String get documentsScreenTitle => 'Documents';

  @override
  String get sharingNoPhotoAccess => 'Mediarr may not add photos to this phone';

  @override
  String get backupNoDeviceKey => 'The server did not create a device key.';

  @override
  String get foldersScreenFolders => 'Folders';

  @override
  String get foldersScreenLoadFailed => 'The folder could not be loaded.';

  @override
  String get foldersScreenNoExternalLibrary =>
      'You have no external library. An administrator sets it up in Settings.';

  @override
  String get foldersScreenEmpty => 'This folder is empty.';

  @override
  String get searchQueryNoName => 'No name';

  @override
  String get searchQueryVideos => 'Videos';

  @override
  String get searchQueryPhotos => 'Photos';

  @override
  String searchQueryInAlbum(String title) {
    return 'In album: $title';
  }

  @override
  String get searchQueryInNoAlbum => 'In no album';

  @override
  String get searchQueryFavourites => 'Favourites';

  @override
  String get exploreScreenExplore => 'Explore';

  @override
  String get exploreScreenPeople => 'People';

  @override
  String get exploreScreenPlaces => 'Places';

  @override
  String get exploreScreenMemories => 'Memories';

  @override
  String get exploreScreenPeopleFailed => 'People could not be loaded.';

  @override
  String get exploreScreenNoNamedPeople => 'No named people yet.';

  @override
  String get exploreScreenPlacesFailed => 'Places could not be loaded.';

  @override
  String get exploreScreenNoPlaces => 'No photos with a place yet.';

  @override
  String get exploreScreenMemoriesFailed => 'Memories could not be loaded.';

  @override
  String get exploreScreenNoMemories => 'No memories today.';

  @override
  String get exploreScreenAllPeople => 'All People';

  @override
  String get exploreScreenAllPlaces => 'All Places';

  @override
  String get exploreScreenAllMemories => 'All Memories';

  @override
  String sharedScreenActionFailed(String reason) {
    return 'The action failed. $reason';
  }

  @override
  String get sharedScreenWholeLibrary => 'Whole library';

  @override
  String sharedScreenFrom(String date) {
    return 'From $date';
  }

  @override
  String get sharedScreenLoadFailed =>
      'This could not be loaded. Check the connection.';

  @override
  String get sharedScreenTryAgain => 'Try again';

  @override
  String get sharedScreenAlbumsWithMe => 'Albums shared with me';

  @override
  String get sharedScreenNothingShared => 'Nothing has been shared yet.';

  @override
  String get sharedScreenLibrariesWithMe => 'Libraries shared with me';

  @override
  String get sharedScreenNobodyShares =>
      'Nobody shares their library with you.';

  @override
  String get sharedScreenShowInMyMedia => 'Show in my Media';

  @override
  String get sharedScreenMyLibrarySharedWith => 'My library is shared with';

  @override
  String get sharedScreenNobodyYet => 'Nobody yet.';

  @override
  String get sharedScreenStop => 'Stop';

  @override
  String get sharedScreenUser => 'User';

  @override
  String get sharedScreenChooseDate => 'Choose date';

  @override
  String get sharedScreenNeverShared =>
      'The archive, trash and vault are never shared.';

  @override
  String get sharedScreenShareMyLibrary => 'Share my library';

  @override
  String get sharedScreenShared => 'Shared';

  @override
  String get sharedScreenLibraryNotAvailable =>
      'This library is not available.';

  @override
  String get sharedScreenNoPhotos => 'No photos yet.';

  @override
  String get loginScreenEnterServerFirst =>
      'Enter the address of your server first.';

  @override
  String get loginScreenAllowOnCodeScreen =>
      'Allow this sign-in on the screen that shows the code.';

  @override
  String get loginScreenCancel => 'Cancel';

  @override
  String get loginScreenEnterTotp =>
      'Enter the 6-digit code from your authenticator app.';

  @override
  String get loginScreenSignInToServer => 'Sign in to your Mediarr server.';

  @override
  String get loginScreenCode => 'Code';

  @override
  String get loginScreenServerAddress => 'Server address';

  @override
  String get loginScreenEmail => 'Email';

  @override
  String get loginScreenPassword => 'Password';

  @override
  String get loginScreenVerify => 'Verify';

  @override
  String get loginScreenSignIn => 'Sign in';

  @override
  String get loginScreenSingleSignOn => 'Use single sign-on';

  @override
  String get loginScreenScanQr => 'Scan QR code';

  @override
  String get loginScreenEnterSignInCode => 'Enter a sign-in code';

  @override
  String get loginScreenSignInCode => 'Sign-in code';

  @override
  String get qrSignInScanTitle => 'Scan the sign-in code';

  @override
  String get qrSignInScanHelp =>
      'On a screen where you are signed in, open the account menu and choose \"Sign in on a phone\".';

  @override
  String get qrSignInLooking => 'Looking for servers on this network…';

  @override
  String get qrSignInNoneFound => 'No server found on this network.';

  @override
  String get qrSignInOnThisNetwork => 'On this network';

  @override
  String get qrSignInLookAgain => 'Look again';

  @override
  String get qrSignInMakeCodeFailed => 'Could not make a code.';

  @override
  String get qrSignInTheDevice => 'the device';

  @override
  String get qrSignInTitle => 'Sign in on another device';

  @override
  String get qrSignInHowTo =>
      'In the Mediarr app on the other device, tap \"Scan QR code\" on the sign-in screen.';

  @override
  String get qrSignInQrLabel => 'Sign-in QR code';

  @override
  String get qrSignInOrType => 'Or type the code';

  @override
  String qrSignInValidFor(String time) {
    return 'Valid for $time';
  }

  @override
  String qrSignInAllowOn(String device) {
    return 'Allow sign-in on $device?';
  }

  @override
  String get qrSignInAllowOnlyIf =>
      'Allow only if you just scanned the code on your own device.';

  @override
  String get qrSignInDeny => 'Deny';

  @override
  String get qrSignInAllow => 'Allow';

  @override
  String qrSignInSignedIn(String device) {
    return '$device is signed in. It shows under Account → Devices.';
  }

  @override
  String get qrSignInDone => 'Done';

  @override
  String get qrSignInDenied => 'The sign-in was denied.';

  @override
  String get qrSignInExpired => 'The code has expired.';

  @override
  String get qrSignInNewCode => 'New code';

  @override
  String get uploadScreenChoose =>
      'Choose photos and videos from this device to upload them.';

  @override
  String get uploadScreenOpenLibrary => 'Open photo library';

  @override
  String get uploadScreenNeedsAccess =>
      'Mediarr needs access to your photos. Allow it in Settings.';

  @override
  String get uploadScreenOpenSettings => 'Open Settings';

  @override
  String get uploadScreenNoPhotos => 'There are no photos on this device.';

  @override
  String uploadScreenUploadCount(String count) {
    return 'Upload $count';
  }

  @override
  String get uploadScreenQueued => 'Queued';

  @override
  String get uploadScreenPreparing => 'Preparing';

  @override
  String get uploadScreenUploaded => 'Uploaded';

  @override
  String get uploadScreenAlreadyOnServer => 'Already on server';

  @override
  String get uploadScreenFailed => 'Failed';

  @override
  String uploadScreenFinished(String done, String total) {
    return '$done of $total finished';
  }

  @override
  String get uploadScreenClearFailed => 'Clear failed';

  @override
  String get uploadScreenPhoto => 'Photo';

  @override
  String get backupCardNothingYet => 'Nothing has been backed up yet.';

  @override
  String get backupCardLastJustNow => 'Last file backed up just now.';

  @override
  String backupCardLastMinutes(String minutes) {
    return 'Last file backed up $minutes min ago.';
  }

  @override
  String backupCardLastHours(String hours) {
    return 'Last file backed up $hours h ago.';
  }

  @override
  String backupCardLastDays(String days) {
    return 'Last file backed up $days d ago.';
  }

  @override
  String backupCardScopeTitle(String album) {
    return 'Back up \"$album\"';
  }

  @override
  String get backupCardScopeBody =>
      'Should photos already in this album be sent? Anything already on the server is never sent twice.';

  @override
  String get backupCardOnlyNew => 'Only photos added from now';

  @override
  String get backupCardAlsoExisting => 'Also the ones in it now';

  @override
  String get backupCardTheAddedAlbums => 'the added albums';

  @override
  String get backupCardNeedsFullAccess =>
      'Albums need access to all photos. Allow it in Settings: Mediarr > Photos > Full Access.';

  @override
  String backupCardServerUnreachable(String reason) {
    return 'The server could not be reached. $reason';
  }

  @override
  String get backupCardAutomaticBackup => 'Automatic backup';

  @override
  String backupCardAlbum(String name) {
    return 'Album: $name';
  }

  @override
  String get backupCardChange => 'Change';

  @override
  String get backupCardNeedsFullAccessNothingSent =>
      'Albums need access to all photos. Allow it in Settings: Mediarr > Photos > Full Access. Nothing is being sent.';

  @override
  String get backupCardNoSuchAlbum =>
      'No album with this name on the device. Nothing is being sent.';

  @override
  String backupCardMoreAlbums(String more, String never) {
    return 'More albums: $more, never sent: $never';
  }

  @override
  String get backupCardOnlyWifi => 'Only on Wi-Fi';

  @override
  String get backupCardOnlyCharging => 'Only while charging';

  @override
  String backupCardVerified(String verified, String total) {
    return '$verified of $total verified on the server';
  }

  @override
  String backupCardCounts(String sending, String waiting, String failed) {
    return '$sending sending · $waiting waiting · $failed failed';
  }

  @override
  String get backupCardPerDevice => 'What the server confirms, per device';

  @override
  String get backupCardRefused =>
      'The server refused this device. Turn backup off and on again.';

  @override
  String get backupCardFreeUpSpace => 'Free up space';

  @override
  String backupCardRetryFailed(String count) {
    return 'Try the $count failed again';
  }

  @override
  String get backupCardOffHelp =>
      'Sends one album of your choice, and nothing else. Checks for new photos every minute while the app is open. When it is closed, iOS decides when, often much later, and stops it if you swipe the app away.';

  @override
  String get backupCardWhichAlbum => 'Which album?';

  @override
  String get backupCardAlbumName => 'Album name';

  @override
  String backupCardUseName(String name) {
    return 'Use the name \"$name\"';
  }

  @override
  String get backupCardStartsWhenExists =>
      'Starts when an album with this name exists';

  @override
  String get backupCardNoAlbums =>
      'No albums on this device yet. Create one in Photos.';

  @override
  String get backupCardNeverHelp =>
      'A photo in a \"Never\" album is not sent, even if it is also in another album.';

  @override
  String get backupCardNotAdded => 'Not added';

  @override
  String get backupCardBackUp => 'Back up';

  @override
  String get backupCardNever => 'Never';

  @override
  String get backupCardSave => 'Save';

  @override
  String get albumSheetsOwner => 'Owner';

  @override
  String get albumSheetsEditor => 'Editor';

  @override
  String get albumSheetsContributor => 'Contributor';

  @override
  String get albumSheetsViewer => 'Viewer';

  @override
  String get albumSheetsUploadOnly => 'upload only';

  @override
  String get albumSheetsPassword => 'password';

  @override
  String get albumSheetsWatermarkFact => 'watermark';

  @override
  String albumSheetsExpiresFact(String date) {
    return 'expires $date';
  }

  @override
  String albumSheetsDownloadsFact(String count) {
    return 'downloads: $count';
  }

  @override
  String get albumSheetsActionFailed => 'The action failed.';

  @override
  String get albumSheetsComments => 'Comments';

  @override
  String get albumSheetsCommentsAndHearts => 'Comments and hearts';

  @override
  String get albumSheetsCommentsFailed => 'Comments could not be loaded.';

  @override
  String get albumSheetsHeart => 'Heart';

  @override
  String get albumSheetsNoComments => 'No comments yet.';

  @override
  String get albumSheetsDeleteComment => 'Delete comment';

  @override
  String get albumSheetsComment => 'Comment';

  @override
  String get albumSheetsSend => 'Send';

  @override
  String get albumSheetsAddToAlbum => 'Add to album';

  @override
  String get albumSheetsAlbumsFailed => 'Albums could not be loaded.';

  @override
  String get albumSheetsNewAlbum => 'New album';

  @override
  String get albumSheetsCreateAndAdd => 'Create and add';

  @override
  String get albumSheetsShareWithUsers => 'Share with users';

  @override
  String get albumSheetsSharingFailed => 'Sharing could not be loaded.';

  @override
  String get albumSheetsNotShared => 'This album is not shared yet.';

  @override
  String get albumSheetsRemove => 'Remove';

  @override
  String get albumSheetsNoOtherUsers =>
      'There are no other users on this server.';

  @override
  String get albumSheetsUser => 'User';

  @override
  String get albumSheetsRole => 'Role';

  @override
  String get albumSheetsAdd => 'Add';

  @override
  String get albumSheetsPublicLinks => 'Public links';

  @override
  String get albumSheetsCopyNow =>
      'Copy the address now: it cannot be shown again later.';

  @override
  String get albumSheetsCopy => 'Copy';

  @override
  String get albumSheetsLinksFailed => 'Links could not be loaded.';

  @override
  String get albumSheetsUnnamedLink => 'Unnamed link';

  @override
  String get albumSheetsRevoke => 'Revoke';

  @override
  String get albumSheetsName => 'Name';

  @override
  String get albumSheetsPasswordOptional => 'Password (optional)';

  @override
  String get albumSheetsNoExpiry => 'No expiry';

  @override
  String albumSheetsExpires(String date) {
    return 'Expires $date';
  }

  @override
  String get albumSheetsChoose => 'Choose';

  @override
  String get albumSheetsDownloadLimit => 'Download limit';

  @override
  String get albumSheetsWatermark => 'Watermark';

  @override
  String get albumSheetsWatermarkHelp =>
      'A watermark turns off original downloads and video playback.';

  @override
  String get albumSheetsAllowDownloads => 'Allow downloads';

  @override
  String get albumSheetsShowLocation => 'Show location';

  @override
  String get albumSheetsGuestsCanAdd => 'Guests can add photos';

  @override
  String get albumSheetsUploadOnlyLong =>
      'Upload only (guests do not see the album)';

  @override
  String get albumSheetsCreateLink => 'Create link';

  @override
  String get albumSheetsFromAnyDate => 'From any date';

  @override
  String albumSheetsFrom(String date) {
    return 'From $date';
  }

  @override
  String get albumSheetsToAnyDate => 'To any date';

  @override
  String albumSheetsTo(String date) {
    return 'To $date';
  }

  @override
  String get albumSheetsKind => 'Kind';

  @override
  String get albumSheetsAll => 'All';

  @override
  String get albumSheetsPhotos => 'Photos';

  @override
  String get albumSheetsVideos => 'Videos';

  @override
  String get albumSheetsLivePhoto => 'Live Photo';

  @override
  String get albumSheetsCamera => 'Camera';

  @override
  String get albumSheetsPerson => 'Person';

  @override
  String get albumSheetsTag => 'Tag';

  @override
  String get albumSheetsPlace => 'Place';

  @override
  String get viewerScreenDeleteTitle => 'Delete this photo?';

  @override
  String get viewerScreenTrashNoDays =>
      'It moves to the trash, where it can be restored.';

  @override
  String viewerScreenTrashDays(int days) {
    return 'It moves to the trash, where it stays for $days days and can be restored.';
  }

  @override
  String get viewerScreenCancel => 'Cancel';

  @override
  String get viewerScreenDelete => 'Delete';

  @override
  String get viewerScreenActionFailed => 'The action failed.';

  @override
  String get viewerScreenNoVideo => 'This photo has no video.';

  @override
  String get viewerScreenVideoFailed => 'The video could not be loaded.';

  @override
  String get viewerScreenStackShots => 'Shots in this stack';

  @override
  String get viewerScreenSlideshow => 'Slideshow';

  @override
  String get viewerScreen360View => '360° view';

  @override
  String get viewerScreenFlatView => 'Flat view';

  @override
  String get viewerScreenPlayLive => 'Play Live Photo';

  @override
  String get viewerScreenCommentsAndHearts => 'Comments and hearts';

  @override
  String get viewerScreenFavorite => 'Favorite';

  @override
  String get viewerScreenEdit => 'Edit';

  @override
  String get viewerScreenShare => 'Share';

  @override
  String get viewerScreenDetails => 'Details';

  @override
  String get viewerScreenPhotoFailed => 'This photo could not be loaded.';

  @override
  String get viewerScreenCannotPlay =>
      'This video cannot be played on this device.';

  @override
  String get viewerScreenDetailsFailed => 'The details could not be loaded.';

  @override
  String get viewerScreenUnavailable => 'Unavailable';

  @override
  String get viewerScreenMissingFile =>
      'The file was not found on the last scan of the external library. The original is available again once the file is back.';

  @override
  String get viewerScreenName => 'Name';

  @override
  String get viewerScreenDescription => 'Description';

  @override
  String get viewerScreenTaken => 'Taken';

  @override
  String get viewerScreenAdded => 'Added';

  @override
  String get viewerScreenDimensions => 'Dimensions';

  @override
  String get viewerScreenSize => 'Size';

  @override
  String get viewerScreenDuration => 'Duration';

  @override
  String get viewerScreenCamera => 'Camera';

  @override
  String get viewerScreenLens => 'Lens';

  @override
  String get viewerScreenSettings => 'Settings';

  @override
  String get viewerScreenLocation => 'Location';

  @override
  String viewerScreenNotSaved(String reason) {
    return 'Not saved. $reason';
  }

  @override
  String get viewerScreenEditDetails => 'Edit details';

  @override
  String get libraryScreenTitle => 'Library';

  @override
  String get libraryScreenExplore => 'Explore';

  @override
  String get libraryScreenShared => 'Shared';

  @override
  String albumScreenActionFailed(String message) {
    return 'The action failed. $message';
  }

  @override
  String albumScreenRemovedAll(String count) {
    return 'Removed from the album: $count';
  }

  @override
  String albumScreenRemovedSome(String changed, String total) {
    return 'Removed: $changed of $total. You can remove only photos you added yourself.';
  }

  @override
  String get albumScreenCoverSet => 'The cover is set.';

  @override
  String get albumScreenCancel => 'Cancel';

  @override
  String get albumScreenMoveTitle => 'Move the album';

  @override
  String get albumScreenMoveTop => 'The top, among all albums';

  @override
  String get albumScreenMoved => 'The album was moved.';

  @override
  String get albumScreenUploadToAlbum => 'Upload to album';

  @override
  String get albumScreenDeleteTitle => 'Delete this album?';

  @override
  String get albumScreenDeleteBody =>
      'The photos stay in the library. Public links stop working.';

  @override
  String get albumScreenDeleteBodyInside =>
      'The photos stay in the library. Public links stop working. The albums inside move to the top.';

  @override
  String get albumScreenDelete => 'Delete';

  @override
  String get albumScreenLeaveTitle => 'Leave this album?';

  @override
  String get albumScreenLeaveBody =>
      'You will no longer see it, unless the owner shares it again.';

  @override
  String get albumScreenLeave => 'Leave';

  @override
  String get albumScreenClearSelection => 'Clear selection';

  @override
  String get albumScreenShare => 'Share';

  @override
  String get albumScreenSetAsCover => 'Set as cover';

  @override
  String get albumScreenRemoveFromAlbum => 'Remove from album';

  @override
  String get albumScreenSearchInAlbum => 'Search in album';

  @override
  String get albumScreenComments => 'Comments';

  @override
  String get albumScreenMore => 'More';

  @override
  String get albumScreenSlideshow => 'Slideshow';

  @override
  String get albumScreenAddFromLibrary => 'Add from library';

  @override
  String get albumScreenUploadFromPhone => 'Upload from this phone';

  @override
  String get albumScreenAlbumInside => 'Album inside';

  @override
  String get albumScreenMoveTo => 'Move to…';

  @override
  String get albumScreenShareWithUsers => 'Share with users';

  @override
  String get albumScreenPublicLinks => 'Public links';

  @override
  String get albumScreenEdit => 'Edit';

  @override
  String get albumScreenNotAvailable => 'This album is not available.';

  @override
  String get albumScreenNoMatch => 'No photos match the rules.';

  @override
  String get albumScreenEmptyCanAdd =>
      'This album is empty. Add photos from the menu.';

  @override
  String get albumScreenEmpty => 'This album is empty.';

  @override
  String get albumScreenAlbumsInside => 'Albums inside';

  @override
  String get albumScreenNewAlbumInside => 'New album inside';

  @override
  String get albumScreenName => 'Name';

  @override
  String get albumScreenCreate => 'Create';

  @override
  String albumScreenAdded(String count) {
    return 'Added: $count';
  }

  @override
  String get albumScreenChoosePhotos => 'Choose photos';

  @override
  String get albumScreenAdd => 'Add';

  @override
  String get albumScreenNoPhotosYet => 'No photos yet.';

  @override
  String get albumScreenNotSaved => 'The album was not saved.';

  @override
  String get albumScreenEditAlbum => 'Edit album';

  @override
  String get albumScreenDescription => 'Description';

  @override
  String get albumScreenOrder => 'Order';

  @override
  String get albumScreenNewestFirst => 'Newest first';

  @override
  String get albumScreenOldestFirst => 'Oldest first';

  @override
  String get albumScreenSave => 'Save';

  @override
  String get peopleScreensNoName => 'No name';

  @override
  String get peopleScreensSearchFailed =>
      'The search failed. Check the connection.';

  @override
  String get peopleScreensDescribe =>
      'Describe what you are looking for, in English or Croatian, or choose filters.';

  @override
  String get peopleScreensSmartOff =>
      'Smart search is off or not available, so only text on pictures, file names and filters are searched.';

  @override
  String peopleScreensRemoveChip(String label) {
    return 'Remove $label';
  }

  @override
  String get peopleScreensNothingFound => 'Nothing was found.';

  @override
  String get peopleScreensSearchHint => 'dog on a beach, Hvar 2024, receipt…';

  @override
  String get peopleScreensAsk => 'Ask';

  @override
  String get peopleScreensFilters => 'Filters';

  @override
  String get peopleScreensSearch => 'Search';

  @override
  String get peopleScreensLoadFailed =>
      'People could not be loaded. Check the connection.';

  @override
  String get peopleScreensFacesOff =>
      'Face recognition is not turned on for this server.';

  @override
  String get peopleScreensNoneYet => 'No people recognised yet.';

  @override
  String get peopleScreensPeople => 'People';

  @override
  String get peopleScreensShowOthers => 'Show the others';

  @override
  String get peopleScreensHiddenPeople => 'Hidden people';

  @override
  String get peopleScreensName => 'Name';

  @override
  String get peopleScreensDateOfBirth => 'Date of birth';

  @override
  String get peopleScreensMergeWith => 'Merge with…';

  @override
  String get peopleScreensNobodyElse => 'There is nobody else.';

  @override
  String get peopleScreensMerged => 'Merged.';

  @override
  String peopleScreensBorn(String date) {
    return 'Born $date';
  }

  @override
  String get peopleScreensShow => 'Show';

  @override
  String get peopleScreensHide => 'Hide';

  @override
  String get peopleScreensThisLoadFailed =>
      'This could not be loaded. Check the connection.';

  @override
  String get adminServerSettingsTrashDaysProblem =>
      'The trash keeps photos for 1 to 3650 days.';

  @override
  String get adminServerSettingsImageQualityProblem =>
      'Image quality must be between 40 and 100.';

  @override
  String get adminServerSettingsPreviewSizeProblem =>
      'The preview size must be between 720 and 4096.';

  @override
  String get adminServerSettingsVideoQualityProblem =>
      'Video quality must be between 18 and 40, where lower is better.';

  @override
  String get adminServerSettingsVideoHeightProblem =>
      'The largest video must be 720, 1080, 1440 or 2160.';

  @override
  String get adminServerSettingsFaceScoreProblem =>
      'How sure a face must be is between 0.1 and 1.';

  @override
  String get adminServerSettingsFaceDistanceProblem =>
      'How alike two faces must be is between 0.1 and 2.';

  @override
  String get adminServerSettingsJobsProblem =>
      'Background jobs must be between 0 and 64.';

  @override
  String get adminServerSettingsWorkersProblem =>
      'Video and analysis jobs must be between 1 and 16.';

  @override
  String get adminServerSettingsScanProblem =>
      'The scan interval must be between 1 and 720 hours.';

  @override
  String get adminServerSettingsMessageProblem =>
      'The sign-in message is too long.';

  @override
  String get adminServerSettingsNeedNumbers =>
      'Every number field needs a number.';

  @override
  String get adminServerSettingsSaved => 'The settings are saved.';

  @override
  String get adminServerSettingsTitle => 'Server settings';

  @override
  String get adminServerSettingsTrash => 'Trash';

  @override
  String get adminServerSettingsTrashDays => 'Days photos stay in the trash';

  @override
  String adminServerSettingsRange(String low, String high) {
    return '$low to $high';
  }

  @override
  String get adminServerSettingsPicturesAndVideos => 'Pictures and videos';

  @override
  String get adminServerSettingsImageQuality => 'Image quality';

  @override
  String get adminServerSettingsPreviewSize => 'Preview size in pixels';

  @override
  String get adminServerSettingsVideoQuality => 'Video quality';

  @override
  String get adminServerSettingsVideoQualityHelp =>
      '18 to 40, lower is better and larger';

  @override
  String get adminServerSettingsLargestVideo => 'Largest video';

  @override
  String get adminServerSettingsFaces => 'Faces';

  @override
  String get adminServerSettingsFaceScore => 'How sure a face must be';

  @override
  String get adminServerSettingsFaceDistance =>
      'How alike two faces must be to be one person';

  @override
  String get adminServerSettingsBackgroundJobs => 'Background jobs';

  @override
  String get adminServerSettingsJobsAtOnce => 'Jobs at once';

  @override
  String get adminServerSettingsJobsAtOnceHelp =>
      '0 uses WORKER_CONCURRENCY; applies after the worker restarts';

  @override
  String get adminServerSettingsVideosAtOnce => 'Videos at once';

  @override
  String get adminServerSettingsWorkersHelp =>
      '1 to 16; applies after the worker restarts';

  @override
  String get adminServerSettingsAnalysesAtOnce => 'Analyses at once';

  @override
  String get adminServerSettingsScanHours =>
      'Scan external folders every … hours';

  @override
  String get adminServerSettingsSigningIn => 'Signing in';

  @override
  String get adminServerSettingsPasswordLogin =>
      'Allow signing in with a password';

  @override
  String get adminServerSettingsMaintenance => 'Maintenance mode';

  @override
  String get adminServerSettingsMaintenanceHelp =>
      'Only administrators can use the server';

  @override
  String get adminServerSettingsVisibleOnNetwork =>
      'Apps on the same network can find this server';

  @override
  String get adminServerSettingsVisibleOnNetworkHelp =>
      'Signing in still needs an account.';

  @override
  String get adminServerSettingsServerName => 'The server\'s name';

  @override
  String get adminServerSettingsLoginMessage => 'Message on the sign-in page';

  @override
  String get adminOverviewTitle => 'Overview';

  @override
  String get adminOverviewLibrary => 'Library';

  @override
  String get adminOverviewUsers => 'Users';

  @override
  String get adminOverviewPhotos => 'Photos';

  @override
  String get adminOverviewVideos => 'Videos';

  @override
  String get adminOverviewProcessing => 'Being processed';

  @override
  String get adminOverviewFailed => 'Failed';

  @override
  String get adminOverviewLibrarySize => 'Library size';

  @override
  String get adminOverviewDisk => 'Disk';

  @override
  String get adminOverviewFree => 'Free';

  @override
  String get adminOverviewTotal => 'Total';

  @override
  String get adminOverviewJobs => 'Jobs';

  @override
  String get adminOverviewWaiting => 'Waiting';

  @override
  String get adminOverviewRunning => 'Running';

  @override
  String get adminOverviewDone => 'Done';

  @override
  String get adminOverviewServices => 'Services';

  @override
  String get adminOverviewWorker => 'Worker';

  @override
  String get adminOverviewNotRunning => 'Not running';

  @override
  String get adminOverviewAnalysis => 'Analysis (ML)';

  @override
  String get adminOverviewTurnedOff => 'Turned off';

  @override
  String get adminOverviewDatabaseSize => 'Database size';

  @override
  String get adminOverviewVersions => 'Versions';

  @override
  String get adminOverviewDatabase => 'Database';

  @override
  String get adminJobsTitle => 'Jobs';

  @override
  String get adminJobsQueues => 'Queues';

  @override
  String adminJobsQueueState(String queued, String running) {
    return '$queued waiting · $running running';
  }

  @override
  String adminJobsQueueStatePaused(String queued, String running) {
    return '$queued waiting · $running running · paused';
  }

  @override
  String adminJobsContinues(String name) {
    return '$name continues.';
  }

  @override
  String adminJobsIsPaused(String name) {
    return '$name is paused.';
  }

  @override
  String get adminJobsResume => 'Resume';

  @override
  String get adminJobsPause => 'Pause';

  @override
  String get adminJobsFailed => 'Failed';

  @override
  String get adminJobsNoneFailed => 'No job has failed.';

  @override
  String get adminJobsQueuedAgain => 'The job is queued again.';

  @override
  String get adminJobsTryAgain => 'Try again';

  @override
  String get freeSpaceScreenServerUnreachable =>
      'The server could not be asked, so nothing is offered for removal.';

  @override
  String get freeSpaceScreenBackupUnreadable =>
      'The backup state could not be read.';

  @override
  String freeSpaceScreenRemoveTitle(String count) {
    return 'Remove $count from this phone?';
  }

  @override
  String get freeSpaceScreenRemoveBody =>
      'They stay on your server. iPhone asks once more, and keeps them for 30 days in Recently Deleted.';

  @override
  String get freeSpaceScreenCancel => 'Cancel';

  @override
  String get freeSpaceScreenRemove => 'Remove';

  @override
  String get freeSpaceScreenNotRemoved => 'The photos could not be removed.';

  @override
  String get freeSpaceScreenNothingToRemove =>
      'Nothing to remove. Only photos sent by the automatic backup are offered here.';

  @override
  String freeSpaceScreenSafe(String count) {
    return '$count are safely on your server, as it just confirmed by their checksums.';
  }

  @override
  String freeSpaceScreenRemoveButton(String count) {
    return 'Remove $count from this phone';
  }

  @override
  String get freeSpaceScreenTitle => 'Free up space';

  @override
  String get freeSpaceScreenWhatToKeep => 'What to keep';

  @override
  String get freeSpaceScreenAnyAge => 'Any age';

  @override
  String get freeSpaceScreenOlderThanMonth => 'Older than a month';

  @override
  String get freeSpaceScreenOlderThan3Months => 'Older than 3 months';

  @override
  String get freeSpaceScreenOlderThanYear => 'Older than a year';

  @override
  String get freeSpaceScreenRemoveOnly => 'Remove only';

  @override
  String get freeSpaceScreenKeepFavorites => 'Keep favorites';

  @override
  String get freeSpaceScreenKeepPhotos => 'Keep all photos';

  @override
  String get freeSpaceScreenKeepVideos => 'Keep all videos';

  @override
  String get freeSpaceScreenKeepAlbums => 'Keep these albums on the phone';

  @override
  String get apiKeysScreenRead => 'Read';

  @override
  String get apiKeysScreenUpload => 'Upload';

  @override
  String get apiKeysScreenChangeAndDelete => 'Change and delete';

  @override
  String apiKeysScreenExpires(String rights, String date) {
    return '$rights · expires $date';
  }

  @override
  String get apiKeysScreenNewKey => 'New key';

  @override
  String get apiKeysScreenKeyName => 'Key name';

  @override
  String get apiKeysScreenCancel => 'Cancel';

  @override
  String get apiKeysScreenCreate => 'Create';

  @override
  String apiKeysScreenCreateFailed(String message) {
    return 'The key could not be created. $message';
  }

  @override
  String get apiKeysScreenSaveItNow => 'Save it now';

  @override
  String get apiKeysScreenCopy => 'Copy';

  @override
  String get apiKeysScreenDone => 'Done';

  @override
  String get apiKeysScreenRevokeFailed => 'The key could not be revoked.';

  @override
  String get apiKeysScreenTitle => 'API keys';

  @override
  String get apiKeysScreenLoadFailed => 'The keys could not be loaded.';

  @override
  String get apiKeysScreenEmpty =>
      'No keys yet. A key gives a program only the chosen rights.';

  @override
  String get apiKeysScreenRevoke => 'Revoke';

  @override
  String get memoriesScreenLastWeek => 'The last week';

  @override
  String memoriesScreenOnThisDay(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: 'On this day, $years years ago',
      one: 'On this day, 1 year ago',
    );
    return '$_temp0';
  }

  @override
  String get memoriesScreenLoadFailed =>
      'Memories could not be loaded. Check the connection.';

  @override
  String get memoriesScreenTryAgain => 'Try again';

  @override
  String get memoriesScreenNoneYet => 'No memories yet.';

  @override
  String memoriesScreenItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get memoriesScreenTitle => 'Memories';

  @override
  String get memoriesScreenVideoFailed => 'The video could not be made.';

  @override
  String get memoriesScreenVideoSaved => 'The video is saved in your Photos.';

  @override
  String get memoriesScreenVideoNotSaved => 'The video could not be saved.';

  @override
  String get memoriesScreenMakeVideo => 'Make a video';

  @override
  String get layoutJanuary => 'January';

  @override
  String get layoutJanuaryOf => 'January';

  @override
  String get layoutFebruary => 'February';

  @override
  String get layoutFebruaryOf => 'February';

  @override
  String get layoutMarch => 'March';

  @override
  String get layoutMarchOf => 'March';

  @override
  String get layoutApril => 'April';

  @override
  String get layoutAprilOf => 'April';

  @override
  String get layoutMay => 'May';

  @override
  String get layoutMayOf => 'May';

  @override
  String get layoutJune => 'June';

  @override
  String get layoutJuneOf => 'June';

  @override
  String get layoutJuly => 'July';

  @override
  String get layoutJulyOf => 'July';

  @override
  String get layoutAugust => 'August';

  @override
  String get layoutAugustOf => 'August';

  @override
  String get layoutSeptember => 'September';

  @override
  String get layoutSeptemberOf => 'September';

  @override
  String get layoutOctober => 'October';

  @override
  String get layoutOctoberOf => 'October';

  @override
  String get layoutNovember => 'November';

  @override
  String get layoutNovemberOf => 'November';

  @override
  String get layoutDecember => 'December';

  @override
  String get layoutDecemberOf => 'December';

  @override
  String get layoutWeekdayMon => 'Mon';

  @override
  String get layoutWeekdayTue => 'Tue';

  @override
  String get layoutWeekdayWed => 'Wed';

  @override
  String get layoutWeekdayThu => 'Thu';

  @override
  String get layoutWeekdayFri => 'Fri';

  @override
  String get layoutWeekdaySat => 'Sat';

  @override
  String get layoutWeekdaySun => 'Sun';

  @override
  String layoutMonthYear(String month, String year) {
    return '$month $year';
  }

  @override
  String layoutDayLabel(String weekday, String day, String month) {
    return '$weekday $day $month';
  }

  @override
  String layoutDateTime(
    String day,
    String month,
    String year,
    String hour,
    String minute,
  ) {
    return '$day $month $year, $hour:$minute';
  }

  @override
  String get linkPrivacyHideFaces => 'Hide faces';

  @override
  String get linkPrivacyFacesNone => 'None';

  @override
  String get linkPrivacyFacesAll => 'All faces';

  @override
  String get linkPrivacyFacesExcept => 'All but chosen people';

  @override
  String get linkPrivacyChoosePeople =>
      'The faces of these people stay visible:';

  @override
  String get linkPrivacyNoPeople =>
      'Nobody has a name yet. Name people under People first.';

  @override
  String get linkPrivacyPeopleFailed => 'People could not be loaded.';

  @override
  String get linkPrivacyUnrecognized =>
      'A face that was not recognized is not blurred.';

  @override
  String linkPrivacyUnchecked(String count, String total) {
    return '$count of $total photos have not been checked for faces yet, so nothing in them is blurred.';
  }

  @override
  String get linkPrivacyAllChecked =>
      'Every photo in the album has been checked for faces.';

  @override
  String linkPrivacyVideosStill(String count) {
    return 'Videos ($count) are shown only as a still, with faces blurred.';
  }

  @override
  String get linkPrivacyNoOriginals =>
      'Visitors get a blurred copy at full size, never the original.';

  @override
  String get linkPrivacyRemoveCamera => 'Remove camera details';

  @override
  String get linkPrivacyRemoveCameraDetail =>
      'Downloads carry no camera, lens, serial numbers, author or software.';

  @override
  String get linkPrivacyRemoveDate => 'Remove the date too';

  @override
  String get linkPrivacyAskName => 'Ask for a name';

  @override
  String get linkPrivacyAskNameDetail =>
      'Visitors type their name before they see the album.';

  @override
  String get linkPrivacyNotOpened => 'Not opened yet';

  @override
  String linkPrivacyOpened(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Opened $count times',
      one: 'Opened once',
    );
    return '$_temp0 · last $when';
  }

  @override
  String get linkPrivacyWhoOpened => 'Who opened it';

  @override
  String get linkPrivacyNoVisits => 'Nobody has opened this link yet.';

  @override
  String get linkPrivacyVisitsFailed => 'The visits could not be loaded.';

  @override
  String get linkPrivacyUnknownPlace => 'Unknown place';

  @override
  String get linkPrivacyNoName => 'No name given';

  @override
  String linkPrivacyViewed(String count) {
    return '$count viewed';
  }

  @override
  String linkPrivacyDownloaded(String count) {
    return '$count downloaded';
  }

  @override
  String get linkPrivacyAttribution =>
      'Places by DB-IP (db-ip.com), CC BY 4.0. Visits are kept 90 days.';

  @override
  String get sharePrivacyRemoveLocation => 'Remove location';

  @override
  String get sharePrivacyRemoveCamera => 'Remove camera details';

  @override
  String get sharePrivacyHideFaces => 'Hide faces';

  @override
  String get sharePrivacyHideFacesDetail =>
      'Photos go as a blurred copy. Videos are left out.';

  @override
  String get sharePrivacyVideosLeftOut =>
      'Videos were left out: their faces cannot be hidden.';

  @override
  String notificationsLinkOpened(String subject) {
    return 'Your link “$subject” was opened for the first time.';
  }

  @override
  String get cullTitle => 'Cull';

  @override
  String get cullMark => 'Mark';

  @override
  String get cullPick => 'Pick';

  @override
  String get cullReject => 'Reject';

  @override
  String get cullNoMark => 'No mark';

  @override
  String get cullPicks => 'Picks';

  @override
  String get cullRejects => 'Rejects';

  @override
  String get cullUnmarked => 'Unmarked';

  @override
  String get cullAddToCompare => 'Compare';

  @override
  String get cullRemoveFromCompare => 'Take out of comparison';

  @override
  String get cullStopComparing => 'End comparison';

  @override
  String get cullPicksToAlbum => 'Picks to new album';

  @override
  String get cullRejectsToTrash => 'Rejects to trash';

  @override
  String get cullNothing => 'There are no photos of yours to go through here.';

  @override
  String get cullNoneWithMark => 'No photos have this mark.';

  @override
  String get cullNotSaved => 'Not saved';

  @override
  String get cullActionFailed => 'The action failed';

  @override
  String get cullLoadFailed => 'The marks could not be loaded.';

  @override
  String get cullAlbumName => 'Name';

  @override
  String get cullCreateAlbum => 'Create';

  @override
  String cullTally(int picks, int rejects) {
    return '$picks picked · $rejects rejected';
  }

  @override
  String cullConfirmTrash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rejected photos move to the trash and can be restored.',
      one: '1 rejected photo moves to the trash and can be restored.',
    );
    return '$_temp0';
  }

  @override
  String cullMovedToTrash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos moved to the trash',
      one: '1 photo moved to the trash',
    );
    return '$_temp0';
  }

  @override
  String cullAlbumMade(int count, String title) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos are in the album $title',
      one: '1 photo is in the album $title',
    );
    return '$_temp0';
  }

  @override
  String cullAlbumWillHold(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The album will hold $count picked photos.',
      one: 'The album will hold 1 picked photo.',
    );
    return '$_temp0';
  }

  @override
  String get adminMlTitle => 'Analysis service';

  @override
  String get adminMlConnected => 'Connected';

  @override
  String get adminMlLoaded => 'Loaded models';

  @override
  String get adminMlMemory => 'Memory';

  @override
  String get adminMlAcceleration => 'Acceleration';

  @override
  String get adminMlNoneLoaded => 'None right now';

  @override
  String get adminMlState => 'Status';

  @override
  String get adminMlUnreachable =>
      'Cannot be reached. Analysis waits and continues when it is back; until then search uses words on pictures and file names.';

  @override
  String get adminMlWrongToken =>
      'The service refused the token. ML_TOKEN must be the same in .env here and on the computer that runs it.';

  @override
  String memoriesTripTitle(String place, String monthName, String year) {
    return '$place, $monthName $year';
  }

  @override
  String get memoriesMonth1 => 'January';

  @override
  String get memoriesMonth2 => 'February';

  @override
  String get memoriesMonth3 => 'March';

  @override
  String get memoriesMonth4 => 'April';

  @override
  String get memoriesMonth5 => 'May';

  @override
  String get memoriesMonth6 => 'June';

  @override
  String get memoriesMonth7 => 'July';

  @override
  String get memoriesMonth8 => 'August';

  @override
  String get memoriesMonth9 => 'September';

  @override
  String get memoriesMonth10 => 'October';

  @override
  String get memoriesMonth11 => 'November';

  @override
  String get memoriesMonth12 => 'December';

  @override
  String memoriesPersonYears(String person) {
    return '$person through the years';
  }

  @override
  String memoriesBirthday(String person) {
    return '$person\'s birthday';
  }

  @override
  String memoriesYearReview(String year) {
    return '$year in photos';
  }

  @override
  String get memoriesMonthAgo => 'A month ago';

  @override
  String get memoriesHidden => 'This memory is hidden.';

  @override
  String get memoriesPersonHidden =>
      'This person will no longer appear in memories.';

  @override
  String get memoriesHideThis => 'Hide this memory';

  @override
  String get memoriesHidePerson => 'Don\'t show this person';

  @override
  String get memoriesMenuMore => 'More';

  @override
  String get settingsScreenMemoryKinds => 'Kinds of memories';

  @override
  String get settingsScreenMemoryOnThisDay => 'On this day';

  @override
  String get settingsScreenMemoryWeek => 'The last week';

  @override
  String get settingsScreenMemoryTrip => 'Trips';

  @override
  String get settingsScreenMemoryPersonYears => 'A person through the years';

  @override
  String get settingsScreenMemoryBirthday => 'Birthdays';

  @override
  String get settingsScreenMemoryYearReview => 'A year in photos';

  @override
  String get settingsScreenMemoryMonthAgo => 'A month ago';

  @override
  String get settingsScreenHiddenFromMemories => 'Hidden from memories';

  @override
  String get settingsScreenNothingHidden => 'Nothing is hidden.';

  @override
  String get settingsScreenShowAgain => 'Show again';

  @override
  String settingsScreenHiddenMemoryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count memories are hidden',
      one: '1 memory is hidden',
    );
    return '$_temp0';
  }

  @override
  String get settingsScreenShowAllAgain => 'Show all again';

  @override
  String get accountSheetExport => 'Export my library';

  @override
  String get adminScreenExports => 'Library exports';

  @override
  String get adminScreenExportsHint => 'Follow, cancel and download exports';

  @override
  String adminUsersExportTooltip(String email) {
    return 'Export the library of $email';
  }

  @override
  String adminUsersExportStarted(String email) {
    return 'The export of $email\'s library has started.';
  }

  @override
  String get exportsScreenTitle => 'Export';

  @override
  String get exportsScreenAllTitle => 'Library exports';

  @override
  String get exportsScreenWhatIsIn =>
      'Take your whole library with you: ZIP files of up to 10 GB with every original as uploaded, its XMP sidecar, a folder for each album and one JSON file with dates, places, descriptions, ratings, favourites, tags, people and edits. Passwords and keys are never in it. It is made on the server, goes on after a restart, and can be downloaded for 7 days.';

  @override
  String get exportsScreenAdminHint =>
      'An export you start for someone appears in their own list as well. You and they can download it; other administrators only follow it.';

  @override
  String get exportsScreenStart => 'Export my library';

  @override
  String get exportsScreenStarted => 'The export has started.';

  @override
  String get exportsScreenNothingYet => 'Nothing has been exported yet.';

  @override
  String get exportsScreenNotLoaded => 'The exports could not be loaded.';

  @override
  String get exportsScreenRunning => 'Running';

  @override
  String get exportsScreenReady => 'Ready';

  @override
  String get exportsScreenFailed => 'Failed';

  @override
  String get exportsScreenCancelled => 'Cancelled';

  @override
  String get exportsScreenRemoved => 'Removed after 7 days';

  @override
  String exportsScreenProgress(
    int done,
    int total,
    String doneBytes,
    String totalBytes,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total files',
      one: '1 file',
    );
    return '$done of $_temp0 · $doneBytes of $totalBytes';
  }

  @override
  String exportsScreenStartedBy(String name) {
    return 'Started by $name';
  }

  @override
  String exportsScreenMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return 'Not on the disk, so only listed: $_temp0';
  }

  @override
  String exportsScreenKeptUntil(String date) {
    return 'Can be downloaded until $date.';
  }

  @override
  String get exportsScreenOnlyOwner =>
      'Only the owner of the library, or the administrator who started the export, downloads it.';

  @override
  String get exportsScreenCancel => 'Cancel';

  @override
  String get exportsScreenRemove => 'Remove';

  @override
  String exportsScreenPart(int number) {
    return 'Part $number';
  }

  @override
  String exportsScreenFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String exportsScreenDownloadPart(int number) {
    return 'Download part $number';
  }

  @override
  String get exportsScreenDownloadFailed =>
      'The part could not be downloaded. Try again to go on from where it stopped.';

  @override
  String get exportsScreenNoSpace =>
      'There is not enough free space on the server for this export. Free up space, or ask the administrator.';

  @override
  String get exportsScreenAlreadyRunning =>
      'An export of this library is already running.';
}

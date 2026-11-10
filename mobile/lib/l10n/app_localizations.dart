import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hr.dart';
import 'app_localizations_sl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('hr'),
    Locale('sl'),
  ];

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageMachine.
  ///
  /// In en, this message translates to:
  /// **'Machine translated: a person has not read it yet.'**
  String get languageMachine;

  /// No description provided for @languageFollowsAccount.
  ///
  /// In en, this message translates to:
  /// **'Your choice is saved to your account, so other devices follow it.'**
  String get languageFollowsAccount;

  /// No description provided for @appHeaderNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get appHeaderNew;

  /// No description provided for @appHeaderAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get appHeaderAdd;

  /// No description provided for @appHeaderAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get appHeaderAccount;

  /// No description provided for @appHeaderBackupAndUpload.
  ///
  /// In en, this message translates to:
  /// **'Backup and upload'**
  String get appHeaderBackupAndUpload;

  /// No description provided for @uploadsCouldNotRead.
  ///
  /// In en, this message translates to:
  /// **'This photo could not be read from the device.'**
  String get uploadsCouldNotRead;

  /// No description provided for @waitingStripTitle.
  ///
  /// In en, this message translates to:
  /// **'On this phone, waiting to back up'**
  String get waitingStripTitle;

  /// No description provided for @shareSheetVaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Take it out of the vault?'**
  String get shareSheetVaultTitle;

  /// No description provided for @shareSheetVaultBody.
  ///
  /// In en, this message translates to:
  /// **'Once sent or saved, it is no longer protected by your PIN.'**
  String get shareSheetVaultBody;

  /// No description provided for @shareSheetCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get shareSheetCancel;

  /// No description provided for @shareSheetContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get shareSheetContinue;

  /// No description provided for @shareSheetSendThis.
  ///
  /// In en, this message translates to:
  /// **'Send this'**
  String get shareSheetSendThis;

  /// No description provided for @shareSheetSendCount.
  ///
  /// In en, this message translates to:
  /// **'Send {count}'**
  String shareSheetSendCount(String count);

  /// No description provided for @shareSheetSmaller.
  ///
  /// In en, this message translates to:
  /// **'Smaller, for messages'**
  String get shareSheetSmaller;

  /// No description provided for @shareSheetOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get shareSheetOriginal;

  /// No description provided for @shareSheetSmallerDetail.
  ///
  /// In en, this message translates to:
  /// **'A JPEG of at most 2048 px, without location'**
  String get shareSheetSmallerDetail;

  /// No description provided for @shareSheetOriginalDetail.
  ///
  /// In en, this message translates to:
  /// **'As it is, with everything in it'**
  String get shareSheetOriginalDetail;

  /// No description provided for @shareSheetSaveToPhone.
  ///
  /// In en, this message translates to:
  /// **'Save to this phone'**
  String get shareSheetSaveToPhone;

  /// No description provided for @shareSheetSaveDetail.
  ///
  /// In en, this message translates to:
  /// **'The original, in the phone’s gallery'**
  String get shareSheetSaveDetail;

  /// No description provided for @shareSheetSavedOne.
  ///
  /// In en, this message translates to:
  /// **'Saved to this phone.'**
  String get shareSheetSavedOne;

  /// No description provided for @shareSheetSavedMany.
  ///
  /// In en, this message translates to:
  /// **'{count} saved to this phone.'**
  String shareSheetSavedMany(String count);

  /// No description provided for @shareSheetGettingReady.
  ///
  /// In en, this message translates to:
  /// **'Getting it ready'**
  String get shareSheetGettingReady;

  /// No description provided for @shareSheetProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String shareSheetProgress(String done, String total);

  /// No description provided for @shareSheetFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'The files could not be fetched.'**
  String get shareSheetFetchFailed;

  /// No description provided for @facesSectionActionFailed.
  ///
  /// In en, this message translates to:
  /// **'The action failed. {detail}'**
  String facesSectionActionFailed(String detail);

  /// No description provided for @facesSectionNewPerson.
  ///
  /// In en, this message translates to:
  /// **'New person'**
  String get facesSectionNewPerson;

  /// No description provided for @facesSectionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get facesSectionCancel;

  /// No description provided for @facesSectionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get facesSectionSave;

  /// No description provided for @facesSectionPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get facesSectionPeople;

  /// No description provided for @facesSectionNoName.
  ///
  /// In en, this message translates to:
  /// **'No name'**
  String get facesSectionNoName;

  /// No description provided for @facesSectionWhoThisIs.
  ///
  /// In en, this message translates to:
  /// **'Who this is'**
  String get facesSectionWhoThisIs;

  /// No description provided for @facesSectionNewPersonMenu.
  ///
  /// In en, this message translates to:
  /// **'New person…'**
  String get facesSectionNewPersonMenu;

  /// No description provided for @facesSectionNotAPerson.
  ///
  /// In en, this message translates to:
  /// **'Not a person'**
  String get facesSectionNotAPerson;

  /// No description provided for @importsScreenWaitingForFiles.
  ///
  /// In en, this message translates to:
  /// **'Waiting for files'**
  String get importsScreenWaitingForFiles;

  /// No description provided for @importsScreenRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get importsScreenRunning;

  /// No description provided for @importsScreenDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get importsScreenDone;

  /// No description provided for @importsScreenFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get importsScreenFailed;

  /// No description provided for @importsScreenStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get importsScreenStopped;

  /// No description provided for @importsScreenZipUploaded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ZIP file uploaded} other{{count} ZIP files uploaded}}'**
  String importsScreenZipUploaded(int count);

  /// No description provided for @importsScreenCounts.
  ///
  /// In en, this message translates to:
  /// **'added {added} · already here or deleted {skipped} · failed {failed}'**
  String importsScreenCounts(String added, String skipped, String failed);

  /// No description provided for @importsScreenReportNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'The report could not be loaded.'**
  String get importsScreenReportNotLoaded;

  /// No description provided for @importsScreenNoFilesFailed.
  ///
  /// In en, this message translates to:
  /// **'No files failed.'**
  String get importsScreenNoFilesFailed;

  /// No description provided for @importsScreenCouldNotStop.
  ///
  /// In en, this message translates to:
  /// **'The import could not be stopped.'**
  String get importsScreenCouldNotStop;

  /// No description provided for @importsScreenStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get importsScreenStop;

  /// No description provided for @importsScreenCouldNotContinue.
  ///
  /// In en, this message translates to:
  /// **'The import could not go on.'**
  String get importsScreenCouldNotContinue;

  /// No description provided for @importsScreenBringIn.
  ///
  /// In en, this message translates to:
  /// **'Bring in'**
  String get importsScreenBringIn;

  /// No description provided for @importsScreenContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get importsScreenContinue;

  /// No description provided for @importsScreenReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get importsScreenReport;

  /// No description provided for @importsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importsScreenTitle;

  /// No description provided for @importsScreenNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'The imports could not be loaded.'**
  String get importsScreenNotLoaded;

  /// No description provided for @importsScreenHowTo.
  ///
  /// In en, this message translates to:
  /// **'To bring in photos from Google Photos or iCloud, upload the ZIP files of the export on a computer, at {address}.'**
  String importsScreenHowTo(String address);

  /// No description provided for @importsScreenNothingYet.
  ///
  /// In en, this message translates to:
  /// **'You have not imported anything yet.'**
  String get importsScreenNothingYet;

  /// No description provided for @storageTemplateScreenDryRun.
  ///
  /// In en, this message translates to:
  /// **'Dry run'**
  String get storageTemplateScreenDryRun;

  /// No description provided for @storageTemplateScreenDryRunProgress.
  ///
  /// In en, this message translates to:
  /// **'Dry run… {checked}'**
  String storageTemplateScreenDryRunProgress(String checked);

  /// No description provided for @storageTemplateScreenMovingProgress.
  ///
  /// In en, this message translates to:
  /// **'Moving… {checked}'**
  String storageTemplateScreenMovingProgress(String checked);

  /// No description provided for @storageTemplateScreenWouldMove.
  ///
  /// In en, this message translates to:
  /// **'Dry run: {moved} of {checked} would move.'**
  String storageTemplateScreenWouldMove(String moved, String checked);

  /// No description provided for @storageTemplateScreenMoved.
  ///
  /// In en, this message translates to:
  /// **'Moved {moved} of {checked}.'**
  String storageTemplateScreenMoved(String moved, String checked);

  /// No description provided for @storageTemplateScreenFailedCount.
  ///
  /// In en, this message translates to:
  /// **'{line} Failed: {failed}.'**
  String storageTemplateScreenFailedCount(String line, String failed);

  /// No description provided for @storageTemplateScreenNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Not loaded.'**
  String get storageTemplateScreenNotLoaded;

  /// No description provided for @storageTemplateScreenSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get storageTemplateScreenSaved;

  /// No description provided for @storageTemplateScreenNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Not saved.'**
  String get storageTemplateScreenNotSaved;

  /// No description provided for @storageTemplateScreenMoveFilesQuestion.
  ///
  /// In en, this message translates to:
  /// **'Move {count} files?'**
  String storageTemplateScreenMoveFilesQuestion(String count);

  /// No description provided for @storageTemplateScreenOriginalsUnchanged.
  ///
  /// In en, this message translates to:
  /// **'The originals do not change, only where they are on the disk.'**
  String get storageTemplateScreenOriginalsUnchanged;

  /// No description provided for @storageTemplateScreenCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get storageTemplateScreenCancel;

  /// No description provided for @storageTemplateScreenMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get storageTemplateScreenMove;

  /// No description provided for @storageTemplateScreenNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started.'**
  String get storageTemplateScreenNotStarted;

  /// No description provided for @storageTemplateScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage template'**
  String get storageTemplateScreenTitle;

  /// No description provided for @storageTemplateScreenIntro.
  ///
  /// In en, this message translates to:
  /// **'How originals are laid out on the disk, inside each user’s folder. It applies to new files; the ones already here move only when you ask, after a dry run. An external library never moves.'**
  String get storageTemplateScreenIntro;

  /// No description provided for @storageTemplateScreenTemplate.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get storageTemplateScreenTemplate;

  /// No description provided for @storageTemplateScreenExamples.
  ///
  /// In en, this message translates to:
  /// **'Examples'**
  String get storageTemplateScreenExamples;

  /// No description provided for @storageTemplateScreenBackToUsual.
  ///
  /// In en, this message translates to:
  /// **'Back to the usual layout'**
  String get storageTemplateScreenBackToUsual;

  /// No description provided for @storageTemplateScreenSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get storageTemplateScreenSave;

  /// No description provided for @storageTemplateScreenFilesAlreadyHere.
  ///
  /// In en, this message translates to:
  /// **'Files already here'**
  String get storageTemplateScreenFilesAlreadyHere;

  /// No description provided for @storageTemplateScreenMoveTheFiles.
  ///
  /// In en, this message translates to:
  /// **'Move the files'**
  String get storageTemplateScreenMoveTheFiles;

  /// No description provided for @mapScreenNoPlaceName.
  ///
  /// In en, this message translates to:
  /// **'No place name'**
  String get mapScreenNoPlaceName;

  /// No description provided for @mapScreenNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'The map could not be loaded. Check the connection.'**
  String get mapScreenNotLoaded;

  /// No description provided for @mapScreenTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get mapScreenTryAgain;

  /// No description provided for @mapScreenNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos with a location yet.'**
  String get mapScreenNoPhotos;

  /// No description provided for @mapScreenFromDate.
  ///
  /// In en, this message translates to:
  /// **'From date'**
  String get mapScreenFromDate;

  /// No description provided for @mapScreenToDate.
  ///
  /// In en, this message translates to:
  /// **'To date'**
  String get mapScreenToDate;

  /// No description provided for @mapScreenClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get mapScreenClear;

  /// No description provided for @mapScreenItems.
  ///
  /// In en, this message translates to:
  /// **'Items: {count}'**
  String mapScreenItems(String count);

  /// No description provided for @mapScreenTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get mapScreenTrips;

  /// No description provided for @mapScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapScreenTitle;

  /// No description provided for @cleanupScreenBlurry.
  ///
  /// In en, this message translates to:
  /// **'Blurry photos'**
  String get cleanupScreenBlurry;

  /// No description provided for @cleanupScreenScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Screenshots'**
  String get cleanupScreenScreenshots;

  /// No description provided for @cleanupScreenLargeVideos.
  ///
  /// In en, this message translates to:
  /// **'Large videos'**
  String get cleanupScreenLargeVideos;

  /// No description provided for @cleanupScreenBursts.
  ///
  /// In en, this message translates to:
  /// **'Bursts'**
  String get cleanupScreenBursts;

  /// No description provided for @cleanupScreenBlurryHint.
  ///
  /// In en, this message translates to:
  /// **'Photos with very few sharp edges. The slider sets how strict.'**
  String get cleanupScreenBlurryHint;

  /// No description provided for @cleanupScreenScreenshotsHint.
  ///
  /// In en, this message translates to:
  /// **'Found by their name, an iPhone\'s mark, or the shape of a screen.'**
  String get cleanupScreenScreenshotsHint;

  /// No description provided for @cleanupScreenLargeVideosHint.
  ///
  /// In en, this message translates to:
  /// **'The largest first.'**
  String get cleanupScreenLargeVideosHint;

  /// No description provided for @cleanupScreenBurstsHint.
  ///
  /// In en, this message translates to:
  /// **'The other shots of a burst. The best shot stays.'**
  String get cleanupScreenBurstsHint;

  /// No description provided for @cleanupScreenMoveToTrashQuestion.
  ///
  /// In en, this message translates to:
  /// **'Move to the trash?'**
  String get cleanupScreenMoveToTrashQuestion;

  /// No description provided for @cleanupScreenTrashBody.
  ///
  /// In en, this message translates to:
  /// **'{count} items ({size}) stay in the trash for a while and can be restored.'**
  String cleanupScreenTrashBody(String count, String size);

  /// No description provided for @cleanupScreenCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cleanupScreenCancel;

  /// No description provided for @cleanupScreenMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get cleanupScreenMove;

  /// No description provided for @cleanupScreenMovedToTrash.
  ///
  /// In en, this message translates to:
  /// **'Moved to the trash.'**
  String get cleanupScreenMovedToTrash;

  /// No description provided for @cleanupScreenActionFailed.
  ///
  /// In en, this message translates to:
  /// **'The action failed.'**
  String get cleanupScreenActionFailed;

  /// No description provided for @cleanupScreenKept.
  ///
  /// In en, this message translates to:
  /// **'Kept. They will not be offered again.'**
  String get cleanupScreenKept;

  /// No description provided for @cleanupScreenStricter.
  ///
  /// In en, this message translates to:
  /// **'Stricter'**
  String get cleanupScreenStricter;

  /// No description provided for @cleanupScreenMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get cleanupScreenMore;

  /// No description provided for @cleanupScreenLargerThan.
  ///
  /// In en, this message translates to:
  /// **'Larger than '**
  String get cleanupScreenLargerThan;

  /// No description provided for @cleanupScreenToTheTrash.
  ///
  /// In en, this message translates to:
  /// **'To the trash'**
  String get cleanupScreenToTheTrash;

  /// No description provided for @cleanupScreenStays.
  ///
  /// In en, this message translates to:
  /// **'Stays'**
  String get cleanupScreenStays;

  /// No description provided for @cleanupScreenFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get cleanupScreenFavorite;

  /// No description provided for @cleanupScreenInAnAlbum.
  ///
  /// In en, this message translates to:
  /// **'In an album'**
  String get cleanupScreenInAnAlbum;

  /// No description provided for @cleanupScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Clean up'**
  String get cleanupScreenTitle;

  /// No description provided for @cleanupScreenKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get cleanupScreenKeep;

  /// No description provided for @cleanupScreenToTheTrashButton.
  ///
  /// In en, this message translates to:
  /// **'To the trash ({count} · {size})'**
  String cleanupScreenToTheTrashButton(String count, String size);

  /// No description provided for @cleanupScreenNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Clean up could not be loaded.'**
  String get cleanupScreenNotLoaded;

  /// No description provided for @cleanupScreenStillAnalysed.
  ///
  /// In en, this message translates to:
  /// **'Still being analysed: {count} photos.'**
  String cleanupScreenStillAnalysed(String count);

  /// No description provided for @cleanupScreenNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing to clean up here.'**
  String get cleanupScreenNothing;

  /// No description provided for @cleanupScreenTapToTick.
  ///
  /// In en, this message translates to:
  /// **'Tap to tick or untick. Hold to look at it.'**
  String get cleanupScreenTapToTick;

  /// No description provided for @cleanupScreenShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get cleanupScreenShowMore;

  /// No description provided for @organizeScreensRecentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get organizeScreensRecentlyAdded;

  /// No description provided for @organizeScreensFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get organizeScreensFavorites;

  /// No description provided for @organizeScreensMemories.
  ///
  /// In en, this message translates to:
  /// **'Memories'**
  String get organizeScreensMemories;

  /// No description provided for @organizeScreensPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get organizeScreensPeople;

  /// No description provided for @organizeScreensMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get organizeScreensMap;

  /// No description provided for @organizeScreensFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get organizeScreensFolders;

  /// No description provided for @organizeScreensFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get organizeScreensFamily;

  /// No description provided for @organizeScreensDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get organizeScreensDocuments;

  /// No description provided for @organizeScreensDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Duplicates'**
  String get organizeScreensDuplicates;

  /// No description provided for @organizeScreensCleanUp.
  ///
  /// In en, this message translates to:
  /// **'Clean up'**
  String get organizeScreensCleanUp;

  /// No description provided for @organizeScreensArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get organizeScreensArchive;

  /// No description provided for @organizeScreensTrash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get organizeScreensTrash;

  /// No description provided for @organizeScreensVault.
  ///
  /// In en, this message translates to:
  /// **'Vault'**
  String get organizeScreensVault;

  /// No description provided for @organizeScreensApiKeys.
  ///
  /// In en, this message translates to:
  /// **'API keys'**
  String get organizeScreensApiKeys;

  /// No description provided for @organizeScreensTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get organizeScreensTags;

  /// No description provided for @organizeScreensCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'This could not be loaded. Check the connection.'**
  String get organizeScreensCouldNotLoad;

  /// No description provided for @organizeScreensClearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get organizeScreensClearSelection;

  /// No description provided for @organizeScreensShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get organizeScreensShare;

  /// No description provided for @organizeScreensOriginalsRemoved.
  ///
  /// In en, this message translates to:
  /// **'The originals are removed from the disk. This cannot be undone.'**
  String get organizeScreensOriginalsRemoved;

  /// No description provided for @organizeScreensCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get organizeScreensCancel;

  /// No description provided for @organizeScreensDeletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get organizeScreensDeletePermanently;

  /// No description provided for @organizeScreensActionFailedDetail.
  ///
  /// In en, this message translates to:
  /// **'The action failed. {detail}'**
  String organizeScreensActionFailedDetail(String detail);

  /// No description provided for @organizeScreensNothingAdded.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been added yet.'**
  String get organizeScreensNothingAdded;

  /// No description provided for @organizeScreensAddToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get organizeScreensAddToFavorites;

  /// No description provided for @organizeScreensAddedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get organizeScreensAddedToFavorites;

  /// No description provided for @organizeScreensArchiveAction.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get organizeScreensArchiveAction;

  /// No description provided for @organizeScreensArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get organizeScreensArchived;

  /// No description provided for @organizeScreensNoFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet. Mark a photo with the star.'**
  String get organizeScreensNoFavorites;

  /// No description provided for @organizeScreensRemoveFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get organizeScreensRemoveFromFavorites;

  /// No description provided for @organizeScreensRemovedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get organizeScreensRemovedFromFavorites;

  /// No description provided for @organizeScreensArchiveEmpty.
  ///
  /// In en, this message translates to:
  /// **'The archive is empty.'**
  String get organizeScreensArchiveEmpty;

  /// No description provided for @organizeScreensBackToMedia.
  ///
  /// In en, this message translates to:
  /// **'Back to Media'**
  String get organizeScreensBackToMedia;

  /// No description provided for @organizeScreensBackInMedia.
  ///
  /// In en, this message translates to:
  /// **'Back in Media'**
  String get organizeScreensBackInMedia;

  /// No description provided for @organizeScreensTrashRemoves.
  ///
  /// In en, this message translates to:
  /// **'This removes {count} files, {size}.'**
  String organizeScreensTrashRemoves(String count, String size);

  /// No description provided for @organizeScreensEmptyTrashQuestion.
  ///
  /// In en, this message translates to:
  /// **'Empty the trash?'**
  String get organizeScreensEmptyTrashQuestion;

  /// No description provided for @organizeScreensPermanentlyDeletedCount.
  ///
  /// In en, this message translates to:
  /// **'Permanently deleted: {count}'**
  String organizeScreensPermanentlyDeletedCount(String count);

  /// No description provided for @organizeScreensEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get organizeScreensEmpty;

  /// No description provided for @organizeScreensTrashAfterAWhile.
  ///
  /// In en, this message translates to:
  /// **'Items here are deleted permanently after a while.'**
  String get organizeScreensTrashAfterAWhile;

  /// No description provided for @organizeScreensTrashAfterDays.
  ///
  /// In en, this message translates to:
  /// **'Items are permanently deleted after {days} days.'**
  String organizeScreensTrashAfterDays(String days);

  /// No description provided for @organizeScreensTrashEmpty.
  ///
  /// In en, this message translates to:
  /// **'The trash is empty.'**
  String get organizeScreensTrashEmpty;

  /// No description provided for @organizeScreensRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get organizeScreensRestore;

  /// No description provided for @organizeScreensRestored.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get organizeScreensRestored;

  /// No description provided for @organizeScreensDeletePermanentlyQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently?'**
  String get organizeScreensDeletePermanentlyQuestion;

  /// No description provided for @organizeScreensPermanentlyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Permanently deleted'**
  String get organizeScreensPermanentlyDeleted;

  /// No description provided for @organizeScreensOpenYourVault.
  ///
  /// In en, this message translates to:
  /// **'Open your vault'**
  String get organizeScreensOpenYourVault;

  /// No description provided for @organizeScreensTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get organizeScreensTooManyAttempts;

  /// No description provided for @organizeScreensWrongPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN.'**
  String get organizeScreensWrongPin;

  /// No description provided for @organizeScreensPinLength.
  ///
  /// In en, this message translates to:
  /// **'The PIN must have between 4 and 12 digits.'**
  String get organizeScreensPinLength;

  /// No description provided for @organizeScreensVaultLockedItself.
  ///
  /// In en, this message translates to:
  /// **'The vault locked itself. Unlock it again.'**
  String get organizeScreensVaultLockedItself;

  /// No description provided for @organizeScreensVaultEmpty.
  ///
  /// In en, this message translates to:
  /// **'The vault is empty.'**
  String get organizeScreensVaultEmpty;

  /// No description provided for @organizeScreensVaultNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'The vault could not be loaded. Check the connection.'**
  String get organizeScreensVaultNotLoaded;

  /// No description provided for @organizeScreensTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get organizeScreensTryAgain;

  /// No description provided for @organizeScreensVaultIntro.
  ///
  /// In en, this message translates to:
  /// **'Hidden from every other view and from sharing. The files on the server are not encrypted.'**
  String get organizeScreensVaultIntro;

  /// No description provided for @organizeScreensPin.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get organizeScreensPin;

  /// No description provided for @organizeScreensNewPin.
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get organizeScreensNewPin;

  /// No description provided for @organizeScreensPinHelper.
  ///
  /// In en, this message translates to:
  /// **'From 4 to 12 digits. Only the server administrator can reset a lost PIN.'**
  String get organizeScreensPinHelper;

  /// No description provided for @organizeScreensUseFaceId.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID next time'**
  String get organizeScreensUseFaceId;

  /// No description provided for @organizeScreensUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get organizeScreensUnlock;

  /// No description provided for @organizeScreensSetPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get organizeScreensSetPin;

  /// No description provided for @organizeScreensAddATag.
  ///
  /// In en, this message translates to:
  /// **'Add a tag'**
  String get organizeScreensAddATag;

  /// No description provided for @organizeScreensNewTag.
  ///
  /// In en, this message translates to:
  /// **'New tag'**
  String get organizeScreensNewTag;

  /// No description provided for @organizeScreensCreateAndAdd.
  ///
  /// In en, this message translates to:
  /// **'Create and add'**
  String get organizeScreensCreateAndAdd;

  /// No description provided for @organizeScreensTagsNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Tags could not be loaded.'**
  String get organizeScreensTagsNotLoaded;

  /// No description provided for @organizeScreensNoTags.
  ///
  /// In en, this message translates to:
  /// **'No tags yet. Select photos and add a tag.'**
  String get organizeScreensNoTags;

  /// No description provided for @organizeScreensDeleteTag.
  ///
  /// In en, this message translates to:
  /// **'Delete tag'**
  String get organizeScreensDeleteTag;

  /// No description provided for @organizeScreensRenameTheTag.
  ///
  /// In en, this message translates to:
  /// **'Rename the tag'**
  String get organizeScreensRenameTheTag;

  /// No description provided for @organizeScreensNewName.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get organizeScreensNewName;

  /// No description provided for @organizeScreensSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get organizeScreensSave;

  /// No description provided for @organizeScreensAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" already exists'**
  String organizeScreensAlreadyExists(String name);

  /// No description provided for @organizeScreensJoinThem.
  ///
  /// In en, this message translates to:
  /// **'Join them? All the photos will have \"{name}\".'**
  String organizeScreensJoinThem(String name);

  /// No description provided for @organizeScreensJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get organizeScreensJoin;

  /// No description provided for @organizeScreensNotRenamed.
  ///
  /// In en, this message translates to:
  /// **'Not renamed. {detail}'**
  String organizeScreensNotRenamed(String detail);

  /// No description provided for @organizeScreensNotJoined.
  ///
  /// In en, this message translates to:
  /// **'Not joined. {detail}'**
  String organizeScreensNotJoined(String detail);

  /// No description provided for @organizeScreensRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get organizeScreensRename;

  /// No description provided for @organizeScreensNoPhotosWithTag.
  ///
  /// In en, this message translates to:
  /// **'No photos carry this tag.'**
  String get organizeScreensNoPhotosWithTag;

  /// No description provided for @organizeScreensRemoveTheTag.
  ///
  /// In en, this message translates to:
  /// **'Remove the tag'**
  String get organizeScreensRemoveTheTag;

  /// No description provided for @organizeScreensFamilyNotOn.
  ///
  /// In en, this message translates to:
  /// **'An administrator has not turned this on.'**
  String get organizeScreensFamilyNotOn;

  /// No description provided for @organizeScreensFamilyNotMember.
  ///
  /// In en, this message translates to:
  /// **'You are not in the family library yet.'**
  String get organizeScreensFamilyNotMember;

  /// No description provided for @organizeScreensWhatIShare.
  ///
  /// In en, this message translates to:
  /// **'What I share'**
  String get organizeScreensWhatIShare;

  /// No description provided for @organizeScreensFamilyNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'The family library could not be loaded.'**
  String get organizeScreensFamilyNotLoaded;

  /// No description provided for @organizeScreensFamilyNothingShared.
  ///
  /// In en, this message translates to:
  /// **'Nobody has shared anything with the family yet.'**
  String get organizeScreensFamilyNothingShared;

  /// No description provided for @organizeScreensShareWithFamily.
  ///
  /// In en, this message translates to:
  /// **'Share with the family'**
  String get organizeScreensShareWithFamily;

  /// No description provided for @organizeScreensRuleName.
  ///
  /// In en, this message translates to:
  /// **'Rule name'**
  String get organizeScreensRuleName;

  /// No description provided for @organizeScreensFromDateExample.
  ///
  /// In en, this message translates to:
  /// **'From date (2024-06-01)'**
  String get organizeScreensFromDateExample;

  /// No description provided for @organizeScreensPlace.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get organizeScreensPlace;

  /// No description provided for @organizeScreensNotSaved.
  ///
  /// In en, this message translates to:
  /// **'It was not saved. {detail}'**
  String organizeScreensNotSaved(String detail);

  /// No description provided for @organizeScreensNewRule.
  ///
  /// In en, this message translates to:
  /// **'New rule'**
  String get organizeScreensNewRule;

  /// No description provided for @organizeScreensShareNothing.
  ///
  /// In en, this message translates to:
  /// **'You share nothing with the family yet.'**
  String get organizeScreensShareNothing;

  /// No description provided for @organizeScreensStopSharing.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing'**
  String get organizeScreensStopSharing;

  /// No description provided for @organizeScreensActionFailed.
  ///
  /// In en, this message translates to:
  /// **'The action failed.'**
  String get organizeScreensActionFailed;

  /// No description provided for @settingsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsScreenTitle;

  /// No description provided for @settingsScreenViewing.
  ///
  /// In en, this message translates to:
  /// **'Viewing'**
  String get settingsScreenViewing;

  /// No description provided for @settingsScreenAssetViewer.
  ///
  /// In en, this message translates to:
  /// **'Asset viewer'**
  String get settingsScreenAssetViewer;

  /// No description provided for @settingsScreenAssetViewerHint.
  ///
  /// In en, this message translates to:
  /// **'How photos and videos open'**
  String get settingsScreenAssetViewerHint;

  /// No description provided for @settingsScreenPhotoGrid.
  ///
  /// In en, this message translates to:
  /// **'Photo grid'**
  String get settingsScreenPhotoGrid;

  /// No description provided for @settingsScreenPhotoGridHint.
  ///
  /// In en, this message translates to:
  /// **'How the timeline is laid out'**
  String get settingsScreenPhotoGridHint;

  /// No description provided for @settingsScreenPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsScreenPreferences;

  /// No description provided for @settingsScreenPreferencesHint.
  ///
  /// In en, this message translates to:
  /// **'Theme, color and feedback'**
  String get settingsScreenPreferencesHint;

  /// No description provided for @settingsScreenLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'The app\'s language'**
  String get settingsScreenLanguageHint;

  /// No description provided for @settingsScreenThisPhone.
  ///
  /// In en, this message translates to:
  /// **'This phone'**
  String get settingsScreenThisPhone;

  /// No description provided for @settingsScreenBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get settingsScreenBackup;

  /// No description provided for @settingsScreenBackupHint.
  ///
  /// In en, this message translates to:
  /// **'What this phone sends to the server'**
  String get settingsScreenBackupHint;

  /// No description provided for @settingsScreenFreeUpSpace.
  ///
  /// In en, this message translates to:
  /// **'Free up space'**
  String get settingsScreenFreeUpSpace;

  /// No description provided for @settingsScreenFreeUpSpaceHint.
  ///
  /// In en, this message translates to:
  /// **'Remove what is safe on the server'**
  String get settingsScreenFreeUpSpaceHint;

  /// No description provided for @settingsScreenSyncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync status'**
  String get settingsScreenSyncStatus;

  /// No description provided for @settingsScreenSyncStatusHint.
  ///
  /// In en, this message translates to:
  /// **'What is on this phone and on the server'**
  String get settingsScreenSyncStatusHint;

  /// No description provided for @settingsScreenHomeWidget.
  ///
  /// In en, this message translates to:
  /// **'Home screen widget'**
  String get settingsScreenHomeWidget;

  /// No description provided for @settingsScreenHomeWidgetHint.
  ///
  /// In en, this message translates to:
  /// **'An album on the home screen'**
  String get settingsScreenHomeWidgetHint;

  /// No description provided for @settingsScreenNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsScreenNotifications;

  /// No description provided for @settingsScreenNotificationsHint.
  ///
  /// In en, this message translates to:
  /// **'What the app tells you about'**
  String get settingsScreenNotificationsHint;

  /// No description provided for @settingsScreenServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get settingsScreenServer;

  /// No description provided for @settingsScreenDevices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get settingsScreenDevices;

  /// No description provided for @settingsScreenDevicesHint.
  ///
  /// In en, this message translates to:
  /// **'Where this account is signed in'**
  String get settingsScreenDevicesHint;

  /// No description provided for @settingsScreenYourLibrary.
  ///
  /// In en, this message translates to:
  /// **'Your library'**
  String get settingsScreenYourLibrary;

  /// No description provided for @settingsScreenYourLibraryHint.
  ///
  /// In en, this message translates to:
  /// **'How much this account holds'**
  String get settingsScreenYourLibraryHint;

  /// No description provided for @settingsScreenNetworking.
  ///
  /// In en, this message translates to:
  /// **'Networking'**
  String get settingsScreenNetworking;

  /// No description provided for @settingsScreenNetworkingHint.
  ///
  /// In en, this message translates to:
  /// **'The addresses of your server'**
  String get settingsScreenNetworkingHint;

  /// No description provided for @settingsScreenAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get settingsScreenAdvanced;

  /// No description provided for @settingsScreenAdvancedHint.
  ///
  /// In en, this message translates to:
  /// **'Read-only mode and the image cache'**
  String get settingsScreenAdvancedHint;

  /// No description provided for @settingsScreenWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get settingsScreenWhatsNew;

  /// No description provided for @settingsScreenWhatsNewHint.
  ///
  /// In en, this message translates to:
  /// **'The versions of Mediarr'**
  String get settingsScreenWhatsNewHint;

  /// No description provided for @settingsScreenReadOnlyOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off read-only mode'**
  String get settingsScreenReadOnlyOff;

  /// No description provided for @settingsScreenReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read-only mode'**
  String get settingsScreenReadOnly;

  /// No description provided for @settingsScreenReadOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Only look: no uploading, editing or deleting from this app'**
  String get settingsScreenReadOnlyHint;

  /// No description provided for @settingsScreenCopyAlbums.
  ///
  /// In en, this message translates to:
  /// **'Copy albums to the server'**
  String get settingsScreenCopyAlbums;

  /// No description provided for @settingsScreenCopyAlbumsHint.
  ///
  /// In en, this message translates to:
  /// **'Backed-up albums get an album of the same name on the server. Photos are only added, never removed'**
  String get settingsScreenCopyAlbumsHint;

  /// No description provided for @settingsScreenClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear image cache'**
  String get settingsScreenClearCache;

  /// No description provided for @settingsScreenCacheEmpty.
  ///
  /// In en, this message translates to:
  /// **'The image cache is empty.'**
  String get settingsScreenCacheEmpty;

  /// No description provided for @settingsScreenPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get settingsScreenPhotos;

  /// No description provided for @settingsScreenLoadFull.
  ///
  /// In en, this message translates to:
  /// **'Load the full photo'**
  String get settingsScreenLoadFull;

  /// No description provided for @settingsScreenLoadFullHint.
  ///
  /// In en, this message translates to:
  /// **'Opens photos at full resolution. This uses more data and is slower'**
  String get settingsScreenLoadFullHint;

  /// No description provided for @settingsScreenTapToNavigate.
  ///
  /// In en, this message translates to:
  /// **'Tap to navigate'**
  String get settingsScreenTapToNavigate;

  /// No description provided for @settingsScreenTapToNavigateHint.
  ///
  /// In en, this message translates to:
  /// **'Tapping the left or right quarter of the screen goes to the previous or next photo'**
  String get settingsScreenTapToNavigateHint;

  /// No description provided for @settingsScreenVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get settingsScreenVideos;

  /// No description provided for @settingsScreenAutoPlay.
  ///
  /// In en, this message translates to:
  /// **'Auto play videos'**
  String get settingsScreenAutoPlay;

  /// No description provided for @settingsScreenAutoPlayHint.
  ///
  /// In en, this message translates to:
  /// **'Videos start when they are opened'**
  String get settingsScreenAutoPlayHint;

  /// No description provided for @settingsScreenLooping.
  ///
  /// In en, this message translates to:
  /// **'Looping'**
  String get settingsScreenLooping;

  /// No description provided for @settingsScreenLoopingHint.
  ///
  /// In en, this message translates to:
  /// **'Videos start again when they end'**
  String get settingsScreenLoopingHint;

  /// No description provided for @settingsScreenPlayOriginal.
  ///
  /// In en, this message translates to:
  /// **'Play the original video'**
  String get settingsScreenPlayOriginal;

  /// No description provided for @settingsScreenPlayOriginalHint.
  ///
  /// In en, this message translates to:
  /// **'Plays the original even when a converted version exists. It may have to buffer'**
  String get settingsScreenPlayOriginalHint;

  /// No description provided for @settingsScreenLayout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get settingsScreenLayout;

  /// No description provided for @settingsScreenPerRow.
  ///
  /// In en, this message translates to:
  /// **'Photos per row ({count})'**
  String settingsScreenPerRow(String count);

  /// No description provided for @settingsScreenGroupBy.
  ///
  /// In en, this message translates to:
  /// **'Group by'**
  String get settingsScreenGroupBy;

  /// No description provided for @settingsScreenMonthDay.
  ///
  /// In en, this message translates to:
  /// **'Month + day'**
  String get settingsScreenMonthDay;

  /// No description provided for @settingsScreenMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get settingsScreenMonth;

  /// No description provided for @settingsScreenTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsScreenTheme;

  /// No description provided for @settingsScreenPrimaryColor.
  ///
  /// In en, this message translates to:
  /// **'Primary color'**
  String get settingsScreenPrimaryColor;

  /// No description provided for @settingsScreenHaptics.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get settingsScreenHaptics;

  /// No description provided for @settingsScreenEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get settingsScreenEnabled;

  /// No description provided for @settingsScreenNotificationsNotYet.
  ///
  /// In en, this message translates to:
  /// **'Notifications are not available yet.'**
  String get settingsScreenNotificationsNotYet;

  /// No description provided for @settingsScreenPhotosAndVideos.
  ///
  /// In en, this message translates to:
  /// **'Photos and videos'**
  String get settingsScreenPhotosAndVideos;

  /// No description provided for @settingsScreenPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get settingsScreenPhone;

  /// No description provided for @settingsScreenAlbums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get settingsScreenAlbums;

  /// No description provided for @settingsScreenOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get settingsScreenOther;

  /// No description provided for @settingsScreenMemories.
  ///
  /// In en, this message translates to:
  /// **'Memories'**
  String get settingsScreenMemories;

  /// No description provided for @settingsScreenBackedUp.
  ///
  /// In en, this message translates to:
  /// **'Backed up'**
  String get settingsScreenBackedUp;

  /// No description provided for @settingsScreenCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get settingsScreenCheckAgain;

  /// No description provided for @settingsScreenRetryFailed.
  ///
  /// In en, this message translates to:
  /// **'Send the {count} that failed again'**
  String settingsScreenRetryFailed(String count);

  /// No description provided for @settingsScreenRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed.'**
  String get settingsScreenRemoved;

  /// No description provided for @settingsScreenSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get settingsScreenSaved;

  /// No description provided for @settingsScreenMainAddress.
  ///
  /// In en, this message translates to:
  /// **'Main address: {address}'**
  String settingsScreenMainAddress(String address);

  /// No description provided for @settingsScreenSecondAddress.
  ///
  /// In en, this message translates to:
  /// **'Second address'**
  String get settingsScreenSecondAddress;

  /// No description provided for @settingsScreenSecondAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Used when the main one does not answer, such as away from home'**
  String get settingsScreenSecondAddressHint;

  /// No description provided for @settingsScreenSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsScreenSave;

  /// No description provided for @settingsScreenCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'This could not be loaded.'**
  String get settingsScreenCouldNotLoad;

  /// No description provided for @settingsScreenThisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get settingsScreenThisDevice;

  /// No description provided for @settingsScreenSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsScreenSignOut;

  /// No description provided for @settingsScreenSignOutOthers.
  ///
  /// In en, this message translates to:
  /// **'Sign out all the others'**
  String get settingsScreenSignOutOthers;

  /// No description provided for @settingsScreenFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get settingsScreenFavorites;

  /// No description provided for @settingsScreenArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get settingsScreenArchive;

  /// No description provided for @settingsScreenTrash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get settingsScreenTrash;

  /// No description provided for @settingsScreenUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get settingsScreenUsed;

  /// No description provided for @settingsScreenYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get settingsScreenYourAccount;

  /// No description provided for @settingsScreenMemorySeconds.
  ///
  /// In en, this message translates to:
  /// **'Seconds for each picture in memories ({seconds})'**
  String settingsScreenMemorySeconds(String seconds);

  /// No description provided for @settingsScreenMinFaces.
  ///
  /// In en, this message translates to:
  /// **'Fewest photos for a person to be listed ({count})'**
  String settingsScreenMinFaces(String count);

  /// No description provided for @settingsScreenAlbumOrder.
  ///
  /// In en, this message translates to:
  /// **'Order in a new album'**
  String get settingsScreenAlbumOrder;

  /// No description provided for @settingsScreenNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get settingsScreenNewestFirst;

  /// No description provided for @settingsScreenOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get settingsScreenOldestFirst;

  /// No description provided for @sessionDeviceNotApproved.
  ///
  /// In en, this message translates to:
  /// **'An administrator has to approve this device before it can sign in.'**
  String get sessionDeviceNotApproved;

  /// No description provided for @sessionEnterAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter the address of your server.'**
  String get sessionEnterAddress;

  /// No description provided for @sessionAddressInvalid.
  ///
  /// In en, this message translates to:
  /// **'That server address is not valid.'**
  String get sessionAddressInvalid;

  /// No description provided for @sessionNoServer.
  ///
  /// In en, this message translates to:
  /// **'No Mediarr server answered at that address.'**
  String get sessionNoServer;

  /// No description provided for @sessionUnreachableCheck.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Check the address. ({reason})'**
  String sessionUnreachableCheck(String reason);

  /// No description provided for @sessionUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. ({reason})'**
  String sessionUnreachable(String reason);

  /// No description provided for @sessionCodeWrong.
  ///
  /// In en, this message translates to:
  /// **'The code is wrong.'**
  String get sessionCodeWrong;

  /// No description provided for @sessionWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get sessionWrongPassword;

  /// No description provided for @sessionTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get sessionTooManyAttempts;

  /// No description provided for @sessionSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed ({code}).'**
  String sessionSignInFailed(String code);

  /// No description provided for @sessionNoSession.
  ///
  /// In en, this message translates to:
  /// **'The server did not start a session.'**
  String get sessionNoSession;

  /// No description provided for @sessionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Signing in was cancelled.'**
  String get sessionCancelled;

  /// No description provided for @sessionSsoOff.
  ///
  /// In en, this message translates to:
  /// **'Single sign-on is not turned on for this server.'**
  String get sessionSsoOff;

  /// No description provided for @sessionSsoFailed.
  ///
  /// In en, this message translates to:
  /// **'Single sign-on did not work. You may not have an account on this server.'**
  String get sessionSsoFailed;

  /// No description provided for @sessionCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'This code has expired or was already used. Make a new one.'**
  String get sessionCodeExpired;

  /// No description provided for @sessionNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'The server did not answer.'**
  String get sessionNoAnswer;

  /// No description provided for @sessionNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'The sign-in was not allowed.'**
  String get sessionNotAllowed;

  /// No description provided for @sessionSignInExpired.
  ///
  /// In en, this message translates to:
  /// **'This sign-in has expired. Make a new code.'**
  String get sessionSignInExpired;

  /// No description provided for @sessionNobodyAnswered.
  ///
  /// In en, this message translates to:
  /// **'Nobody answered in time. Make a new code.'**
  String get sessionNobodyAnswered;

  /// No description provided for @tusSignedOut.
  ///
  /// In en, this message translates to:
  /// **'You are signed out. Sign in again.'**
  String get tusSignedOut;

  /// No description provided for @tusRejected.
  ///
  /// In en, this message translates to:
  /// **'The server rejected this file ({code}). {body}'**
  String tusRejected(String code, String body);

  /// No description provided for @albumsScreenInside.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 album} other{{count} albums}}'**
  String albumsScreenInside(int count);

  /// No description provided for @albumsScreenLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Albums could not be loaded. Check the connection.'**
  String get albumsScreenLoadFailed;

  /// No description provided for @albumsScreenTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get albumsScreenTryAgain;

  /// No description provided for @albumsScreenNoAlbums.
  ///
  /// In en, this message translates to:
  /// **'No albums yet.'**
  String get albumsScreenNoAlbums;

  /// No description provided for @albumsScreenNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No album matches this.'**
  String get albumsScreenNoMatch;

  /// No description provided for @albumsScreenSortUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last change'**
  String get albumsScreenSortUpdated;

  /// No description provided for @albumsScreenName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get albumsScreenName;

  /// No description provided for @albumsScreenSortDate.
  ///
  /// In en, this message translates to:
  /// **'Photo date'**
  String get albumsScreenSortDate;

  /// No description provided for @albumsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get albumsScreenTitle;

  /// No description provided for @albumsScreenNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get albumsScreenNew;

  /// No description provided for @albumsScreenSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get albumsScreenSort;

  /// No description provided for @albumsScreenSearchFilter.
  ///
  /// In en, this message translates to:
  /// **'Search and filter'**
  String get albumsScreenSearchFilter;

  /// No description provided for @albumsScreenShowList.
  ///
  /// In en, this message translates to:
  /// **'Show as a list'**
  String get albumsScreenShowList;

  /// No description provided for @albumsScreenShowGrid.
  ///
  /// In en, this message translates to:
  /// **'Show as a grid'**
  String get albumsScreenShowGrid;

  /// No description provided for @albumsScreenSearchAlbums.
  ///
  /// In en, this message translates to:
  /// **'Search albums'**
  String get albumsScreenSearchAlbums;

  /// No description provided for @albumsScreenAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get albumsScreenAll;

  /// No description provided for @albumsScreenSharedWithMe.
  ///
  /// In en, this message translates to:
  /// **'Shared with me'**
  String get albumsScreenSharedWithMe;

  /// No description provided for @albumsScreenMine.
  ///
  /// In en, this message translates to:
  /// **'My albums'**
  String get albumsScreenMine;

  /// No description provided for @albumsScreenItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} items}}'**
  String albumsScreenItems(int count);

  /// No description provided for @albumsScreenSmart.
  ///
  /// In en, this message translates to:
  /// **'Smart'**
  String get albumsScreenSmart;

  /// No description provided for @albumsScreenOwned.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get albumsScreenOwned;

  /// No description provided for @albumsScreenNotCreated.
  ///
  /// In en, this message translates to:
  /// **'The album was not created.'**
  String get albumsScreenNotCreated;

  /// No description provided for @albumsScreenNewAlbum.
  ///
  /// In en, this message translates to:
  /// **'New album'**
  String get albumsScreenNewAlbum;

  /// No description provided for @albumsScreenDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get albumsScreenDescription;

  /// No description provided for @albumsScreenSmartAlbum.
  ///
  /// In en, this message translates to:
  /// **'Smart album: fills itself from rules'**
  String get albumsScreenSmartAlbum;

  /// No description provided for @albumsScreenCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get albumsScreenCreate;

  /// No description provided for @adminScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get adminScreenTitle;

  /// No description provided for @adminScreenOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get adminScreenOverview;

  /// No description provided for @adminScreenOverviewHint.
  ///
  /// In en, this message translates to:
  /// **'Users, photos, disk and versions'**
  String get adminScreenOverviewHint;

  /// No description provided for @adminScreenUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminScreenUsers;

  /// No description provided for @adminScreenUsersHint.
  ///
  /// In en, this message translates to:
  /// **'Add users and set how much they may store'**
  String get adminScreenUsersHint;

  /// No description provided for @adminScreenServerSettings.
  ///
  /// In en, this message translates to:
  /// **'Server settings'**
  String get adminScreenServerSettings;

  /// No description provided for @adminScreenServerSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'Trash, quality, faces, jobs, sign-in'**
  String get adminScreenServerSettingsHint;

  /// No description provided for @adminScreenEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get adminScreenEmail;

  /// No description provided for @adminScreenEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Where messages are sent from'**
  String get adminScreenEmailHint;

  /// No description provided for @adminScreenSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get adminScreenSecurity;

  /// No description provided for @adminScreenSecurityHint.
  ///
  /// In en, this message translates to:
  /// **'Single sign-on, devices, addresses, attempts'**
  String get adminScreenSecurityHint;

  /// No description provided for @adminScreenJobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get adminScreenJobs;

  /// No description provided for @adminScreenJobsHint.
  ///
  /// In en, this message translates to:
  /// **'Queues and jobs that failed'**
  String get adminScreenJobsHint;

  /// No description provided for @adminScreenAuditLog.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get adminScreenAuditLog;

  /// No description provided for @adminScreenAuditLogHint.
  ///
  /// In en, this message translates to:
  /// **'Who changed what'**
  String get adminScreenAuditLogHint;

  /// No description provided for @adminScreenBackupHint.
  ///
  /// In en, this message translates to:
  /// **'Copies of the library'**
  String get adminScreenBackupHint;

  /// No description provided for @adminScreenBackupDevices.
  ///
  /// In en, this message translates to:
  /// **'All backup devices'**
  String get adminScreenBackupDevices;

  /// No description provided for @adminScreenBackupDevicesHint.
  ///
  /// In en, this message translates to:
  /// **'Every phone that backs up'**
  String get adminScreenBackupDevicesHint;

  /// No description provided for @adminScreenStorageTemplate.
  ///
  /// In en, this message translates to:
  /// **'Storage template'**
  String get adminScreenStorageTemplate;

  /// No description provided for @adminScreenStorageTemplateHint.
  ///
  /// In en, this message translates to:
  /// **'How originals are laid out on the disk'**
  String get adminScreenStorageTemplateHint;

  /// No description provided for @adminAuditEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing was changed yet.'**
  String get adminAuditEmpty;

  /// No description provided for @adminAuditShowOlder.
  ///
  /// In en, this message translates to:
  /// **'Show older'**
  String get adminAuditShowOlder;

  /// No description provided for @adminUsersAdded.
  ///
  /// In en, this message translates to:
  /// **'{email} was added.'**
  String adminUsersAdded(String email);

  /// No description provided for @adminUsersAddUser.
  ///
  /// In en, this message translates to:
  /// **'Add a user'**
  String get adminUsersAddUser;

  /// No description provided for @adminUsersAdministrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get adminUsersAdministrator;

  /// No description provided for @adminUsersStoredOf.
  ///
  /// In en, this message translates to:
  /// **'{stored} of {quota}'**
  String adminUsersStoredOf(String stored, String quota);

  /// No description provided for @adminUsersNoLimit.
  ///
  /// In en, this message translates to:
  /// **'no limit'**
  String get adminUsersNoLimit;

  /// No description provided for @adminUsersQuotaTooltip.
  ///
  /// In en, this message translates to:
  /// **'How much {email} may store'**
  String adminUsersQuotaTooltip(String email);

  /// No description provided for @adminUsersEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get adminUsersEmail;

  /// No description provided for @adminUsersName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get adminUsersName;

  /// No description provided for @adminUsersPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get adminUsersPassword;

  /// No description provided for @adminUsersCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get adminUsersCancel;

  /// No description provided for @adminUsersAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get adminUsersAdd;

  /// No description provided for @adminUsersQuotaInvalid.
  ///
  /// In en, this message translates to:
  /// **'Type a number of gigabytes, or nothing for no limit.'**
  String get adminUsersQuotaInvalid;

  /// No description provided for @adminUsersStorageFor.
  ///
  /// In en, this message translates to:
  /// **'Storage for {email}'**
  String adminUsersStorageFor(String email);

  /// No description provided for @adminUsersLimitGb.
  ///
  /// In en, this message translates to:
  /// **'Limit in GB'**
  String get adminUsersLimitGb;

  /// No description provided for @adminUsersEmptyNoLimit.
  ///
  /// In en, this message translates to:
  /// **'Empty means no limit.'**
  String get adminUsersEmptyNoLimit;

  /// No description provided for @profileScreenNotSaved.
  ///
  /// In en, this message translates to:
  /// **'The profile could not be saved.'**
  String get profileScreenNotSaved;

  /// No description provided for @profileScreenPictureNotSent.
  ///
  /// In en, this message translates to:
  /// **'The picture could not be sent.'**
  String get profileScreenPictureNotSent;

  /// No description provided for @profileScreenPictureNotRemoved.
  ///
  /// In en, this message translates to:
  /// **'The picture could not be removed.'**
  String get profileScreenPictureNotRemoved;

  /// No description provided for @profileScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileScreenTitle;

  /// No description provided for @profileScreenChangePicture.
  ///
  /// In en, this message translates to:
  /// **'Change picture'**
  String get profileScreenChangePicture;

  /// No description provided for @profileScreenAddPicture.
  ///
  /// In en, this message translates to:
  /// **'Add a picture'**
  String get profileScreenAddPicture;

  /// No description provided for @profileScreenRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get profileScreenRemove;

  /// No description provided for @profileScreenEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get profileScreenEmailAddress;

  /// No description provided for @profileScreenCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password, to change the email'**
  String get profileScreenCurrentPassword;

  /// No description provided for @serverStatusStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get serverStatusStorage;

  /// No description provided for @serverStatusUsedOf.
  ///
  /// In en, this message translates to:
  /// **'{used} of {total} used'**
  String serverStatusUsedOf(String used, String total);

  /// No description provided for @serverStatusOnline.
  ///
  /// In en, this message translates to:
  /// **'Server online'**
  String get serverStatusOnline;

  /// No description provided for @serverStatusMaintained.
  ///
  /// In en, this message translates to:
  /// **'Server is being maintained'**
  String get serverStatusMaintained;

  /// No description provided for @serverStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Server offline'**
  String get serverStatusOffline;

  /// No description provided for @serverStatusVersionAvailable.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available'**
  String serverStatusVersionAvailable(String version);

  /// No description provided for @serverStatusNewVersion.
  ///
  /// In en, this message translates to:
  /// **'A new version is available'**
  String get serverStatusNewVersion;

  /// No description provided for @serverStatusUpdateBody.
  ///
  /// In en, this message translates to:
  /// **'Mediarr {latest} is available. This server runs {version}. The server administrator updates it with:\n\ndocker compose pull && docker compose up -d'**
  String serverStatusUpdateBody(String latest, String version);

  /// No description provided for @serverStatusOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get serverStatusOk;

  /// No description provided for @storiesStripLastWeek.
  ///
  /// In en, this message translates to:
  /// **'The last week'**
  String get storiesStripLastWeek;

  /// No description provided for @storiesStripYearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{years, plural, =1{1 year ago} other{{years} years ago}}'**
  String storiesStripYearsAgo(int years);

  /// No description provided for @storiesStripItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String storiesStripItems(int count);

  /// No description provided for @backupScreenNotYet.
  ///
  /// In en, this message translates to:
  /// **'not yet'**
  String get backupScreenNotYet;

  /// No description provided for @backupScreenLastBackup.
  ///
  /// In en, this message translates to:
  /// **'last backup {when}'**
  String backupScreenLastBackup(String when);

  /// No description provided for @backupScreenUpTo.
  ///
  /// In en, this message translates to:
  /// **'up to {size}'**
  String backupScreenUpTo(String size);

  /// No description provided for @backupScreenInvited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get backupScreenInvited;

  /// No description provided for @backupScreenStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get backupScreenStopped;

  /// No description provided for @backupScreenActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get backupScreenActive;

  /// No description provided for @backupScreenDeletedKept.
  ///
  /// In en, this message translates to:
  /// **'deleted, kept: {size}'**
  String backupScreenDeletedKept(String size);

  /// No description provided for @backupScreenActionFailed.
  ///
  /// In en, this message translates to:
  /// **'The action failed.'**
  String get backupScreenActionFailed;

  /// No description provided for @backupScreenSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get backupScreenSaved;

  /// No description provided for @backupScreenBackupStarted.
  ///
  /// In en, this message translates to:
  /// **'The backup has started.'**
  String get backupScreenBackupStarted;

  /// No description provided for @backupScreenRestoreTestStarted.
  ///
  /// In en, this message translates to:
  /// **'The restore test has started.'**
  String get backupScreenRestoreTestStarted;

  /// No description provided for @backupScreenPaired.
  ///
  /// In en, this message translates to:
  /// **'Paired. The next backup goes there too.'**
  String get backupScreenPaired;

  /// No description provided for @backupScreenKeepForSomeone.
  ///
  /// In en, this message translates to:
  /// **'Keep a backup for someone'**
  String get backupScreenKeepForSomeone;

  /// No description provided for @backupScreenForWhom.
  ///
  /// In en, this message translates to:
  /// **'For whom'**
  String get backupScreenForWhom;

  /// No description provided for @backupScreenAtMostGb.
  ///
  /// In en, this message translates to:
  /// **'At most (GB)'**
  String get backupScreenAtMostGb;

  /// No description provided for @backupScreenOtherServerAddress.
  ///
  /// In en, this message translates to:
  /// **'The address the other server reaches you at'**
  String get backupScreenOtherServerAddress;

  /// No description provided for @backupScreenCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get backupScreenCancel;

  /// No description provided for @backupScreenInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get backupScreenInvite;

  /// No description provided for @backupScreenInvitationFailed.
  ///
  /// In en, this message translates to:
  /// **'The invitation failed.'**
  String get backupScreenInvitationFailed;

  /// No description provided for @backupScreenCodeFor.
  ///
  /// In en, this message translates to:
  /// **'Code for {name}'**
  String backupScreenCodeFor(String name);

  /// No description provided for @backupScreenSendItToAdmin.
  ///
  /// In en, this message translates to:
  /// **'Send it to the administrator of the other server, who pastes or scans it. It works once, until {when}.'**
  String backupScreenSendItToAdmin(String when);

  /// No description provided for @backupScreenPlainHttp.
  ///
  /// In en, this message translates to:
  /// **'Over plain HTTP the key can be read on the way. Use HTTPS or a VPN.'**
  String get backupScreenPlainHttp;

  /// No description provided for @backupScreenCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get backupScreenCopy;

  /// No description provided for @backupScreenDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get backupScreenDone;

  /// No description provided for @backupScreenHowMuchFor.
  ///
  /// In en, this message translates to:
  /// **'How much for {name}'**
  String backupScreenHowMuchFor(String name);

  /// No description provided for @backupScreenSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get backupScreenSave;

  /// No description provided for @backupScreenDeleteCopyOf.
  ///
  /// In en, this message translates to:
  /// **'Delete the copy of {name}?'**
  String backupScreenDeleteCopyOf(String name);

  /// No description provided for @backupScreenTypeToDelete.
  ///
  /// In en, this message translates to:
  /// **'Type “{name}” to delete it'**
  String backupScreenTypeToDelete(String name);

  /// No description provided for @backupScreenDeleteTheCopy.
  ///
  /// In en, this message translates to:
  /// **'Delete the copy'**
  String get backupScreenDeleteTheCopy;

  /// No description provided for @backupScreenScheduledBackup.
  ///
  /// In en, this message translates to:
  /// **'Scheduled backup'**
  String get backupScreenScheduledBackup;

  /// No description provided for @backupScreenOnceADay.
  ///
  /// In en, this message translates to:
  /// **'Once a day, at the hour below'**
  String get backupScreenOnceADay;

  /// No description provided for @backupScreenExplain.
  ///
  /// In en, this message translates to:
  /// **'Originals and the database, encrypted. The destination is a folder inside {folder}, or an s3: or b2: address. Write the password down somewhere other than this server.'**
  String backupScreenExplain(String folder);

  /// No description provided for @backupScreenBackupFolder.
  ///
  /// In en, this message translates to:
  /// **'the backup folder'**
  String get backupScreenBackupFolder;

  /// No description provided for @backupScreenDestination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get backupScreenDestination;

  /// No description provided for @backupScreenPasswordSaved.
  ///
  /// In en, this message translates to:
  /// **'Password (saved, type to change)'**
  String get backupScreenPasswordSaved;

  /// No description provided for @backupScreenBackupPassword.
  ///
  /// In en, this message translates to:
  /// **'Backup password'**
  String get backupScreenBackupPassword;

  /// No description provided for @backupScreenAccessKeySaved.
  ///
  /// In en, this message translates to:
  /// **'Access key (saved)'**
  String get backupScreenAccessKeySaved;

  /// No description provided for @backupScreenAccessKey.
  ///
  /// In en, this message translates to:
  /// **'Access key (S3, B2)'**
  String get backupScreenAccessKey;

  /// No description provided for @backupScreenSecretKey.
  ///
  /// In en, this message translates to:
  /// **'Secret key (S3, B2)'**
  String get backupScreenSecretKey;

  /// No description provided for @backupScreenHourOfDay.
  ///
  /// In en, this message translates to:
  /// **'Hour of the day (0-23)'**
  String get backupScreenHourOfDay;

  /// No description provided for @backupScreenBackUpNow.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get backupScreenBackUpNow;

  /// No description provided for @backupScreenTestBringingBack.
  ///
  /// In en, this message translates to:
  /// **'Test bringing it back'**
  String get backupScreenTestBringingBack;

  /// No description provided for @backupScreenHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get backupScreenHistory;

  /// No description provided for @backupScreenRunBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backupScreenRunBackup;

  /// No description provided for @backupScreenRunRestoreTest.
  ///
  /// In en, this message translates to:
  /// **'Restore test'**
  String get backupScreenRunRestoreTest;

  /// No description provided for @backupScreenFiles.
  ///
  /// In en, this message translates to:
  /// **'files {count}'**
  String backupScreenFiles(String count);

  /// No description provided for @backupScreenMyCopyAtOthers.
  ///
  /// In en, this message translates to:
  /// **'My copy at others'**
  String get backupScreenMyCopyAtOthers;

  /// No description provided for @backupScreenTwoServers.
  ///
  /// In en, this message translates to:
  /// **'Two Mediarr servers keep an encrypted copy of each other. The one that keeps it cannot read it, and what is deleted from it is kept for 90 more days.'**
  String get backupScreenTwoServers;

  /// No description provided for @backupScreenNoHttps.
  ///
  /// In en, this message translates to:
  /// **'No HTTPS'**
  String get backupScreenNoHttps;

  /// No description provided for @backupScreenMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get backupScreenMore;

  /// No description provided for @backupScreenRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get backupScreenRemove;

  /// No description provided for @backupScreenCodeFromOther.
  ///
  /// In en, this message translates to:
  /// **'Code from the other Mediarr'**
  String get backupScreenCodeFromOther;

  /// No description provided for @backupScreenScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code'**
  String get backupScreenScanQr;

  /// No description provided for @backupScreenPairing.
  ///
  /// In en, this message translates to:
  /// **'Pairing…'**
  String get backupScreenPairing;

  /// No description provided for @backupScreenPair.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get backupScreenPair;

  /// No description provided for @backupScreenSnapshots.
  ///
  /// In en, this message translates to:
  /// **'Snapshots before upgrades'**
  String get backupScreenSnapshots;

  /// No description provided for @backupScreenSnapshotsExplain.
  ///
  /// In en, this message translates to:
  /// **'Before each upgrade that changes the database, Mediarr keeps a snapshot of it. The last three are kept.'**
  String get backupScreenSnapshotsExplain;

  /// No description provided for @backupScreenNoSnapshots.
  ///
  /// In en, this message translates to:
  /// **'No snapshots yet. The first is made at the next upgrade that changes the database.'**
  String get backupScreenNoSnapshots;

  /// No description provided for @backupScreenEarlierVersion.
  ///
  /// In en, this message translates to:
  /// **'Earlier version'**
  String get backupScreenEarlierVersion;

  /// No description provided for @backupScreenDeleteSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Delete snapshot'**
  String get backupScreenDeleteSnapshot;

  /// No description provided for @backupScreenGoBackHow.
  ///
  /// In en, this message translates to:
  /// **'To go back to the newest one, in the folder with docker-compose.yml:'**
  String get backupScreenGoBackHow;

  /// No description provided for @backupScreenDeleteThisSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Delete this snapshot?'**
  String get backupScreenDeleteThisSnapshot;

  /// No description provided for @backupScreenNoGoingBack.
  ///
  /// In en, this message translates to:
  /// **'It will no longer be possible to go back to it.'**
  String get backupScreenNoGoingBack;

  /// No description provided for @backupScreenDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get backupScreenDelete;

  /// No description provided for @backupScreenNotDeleted.
  ///
  /// In en, this message translates to:
  /// **'Not deleted.'**
  String get backupScreenNotDeleted;

  /// No description provided for @backupScreenIKeepForOthers.
  ///
  /// In en, this message translates to:
  /// **'I keep for others'**
  String get backupScreenIKeepForOthers;

  /// No description provided for @backupScreenNoNewCode.
  ///
  /// In en, this message translates to:
  /// **'No new code.'**
  String get backupScreenNoNewCode;

  /// No description provided for @backupScreenFilesBroughtBack.
  ///
  /// In en, this message translates to:
  /// **'Files brought back: {count}.'**
  String backupScreenFilesBroughtBack(String count);

  /// No description provided for @backupScreenNewCode.
  ///
  /// In en, this message translates to:
  /// **'New code'**
  String get backupScreenNewCode;

  /// No description provided for @backupScreenResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get backupScreenResume;

  /// No description provided for @backupScreenStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get backupScreenStop;

  /// No description provided for @backupScreenSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get backupScreenSize;

  /// No description provided for @backupScreenBringBackDeleted.
  ///
  /// In en, this message translates to:
  /// **'Bring back what was deleted'**
  String get backupScreenBringBackDeleted;

  /// No description provided for @backupScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backupScreenTitle;

  /// No description provided for @backupScreenLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The backup settings could not be loaded.'**
  String get backupScreenLoadFailed;

  /// No description provided for @backupScreenScanTheCode.
  ///
  /// In en, this message translates to:
  /// **'Scan the code'**
  String get backupScreenScanTheCode;

  /// No description provided for @duplicatesScreenFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get duplicatesScreenFavorite;

  /// No description provided for @duplicatesScreenOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get duplicatesScreenOriginal;

  /// No description provided for @duplicatesScreenSavedAgain.
  ///
  /// In en, this message translates to:
  /// **'Saved again by an app'**
  String get duplicatesScreenSavedAgain;

  /// No description provided for @duplicatesScreenHasLocation.
  ///
  /// In en, this message translates to:
  /// **'Has a location'**
  String get duplicatesScreenHasLocation;

  /// No description provided for @duplicatesScreenHasDescription.
  ///
  /// In en, this message translates to:
  /// **'Has a description'**
  String get duplicatesScreenHasDescription;

  /// No description provided for @duplicatesScreenNoDate.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get duplicatesScreenNoDate;

  /// No description provided for @duplicatesScreenReasonFavorite.
  ///
  /// In en, this message translates to:
  /// **'a favorite'**
  String get duplicatesScreenReasonFavorite;

  /// No description provided for @duplicatesScreenReasonCameraOriginal.
  ///
  /// In en, this message translates to:
  /// **'the camera\'s original'**
  String get duplicatesScreenReasonCameraOriginal;

  /// No description provided for @duplicatesScreenReasonOthersSaved.
  ///
  /// In en, this message translates to:
  /// **'the others were saved again by apps'**
  String get duplicatesScreenReasonOthersSaved;

  /// No description provided for @duplicatesScreenReasonHighestResolution.
  ///
  /// In en, this message translates to:
  /// **'the highest resolution'**
  String get duplicatesScreenReasonHighestResolution;

  /// No description provided for @duplicatesScreenReasonLargestFile.
  ///
  /// In en, this message translates to:
  /// **'the largest file'**
  String get duplicatesScreenReasonLargestFile;

  /// No description provided for @duplicatesScreenReasonEqual.
  ///
  /// In en, this message translates to:
  /// **'they are equal, so any one can stay'**
  String get duplicatesScreenReasonEqual;

  /// No description provided for @duplicatesScreenReasonSharpest.
  ///
  /// In en, this message translates to:
  /// **'the sharpest'**
  String get duplicatesScreenReasonSharpest;

  /// No description provided for @duplicatesScreenCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get duplicatesScreenCancel;

  /// No description provided for @duplicatesScreenResolveThisGroup.
  ///
  /// In en, this message translates to:
  /// **'Resolve this group?'**
  String get duplicatesScreenResolveThisGroup;

  /// No description provided for @duplicatesScreenKeptTakesOver.
  ///
  /// In en, this message translates to:
  /// **'The kept photo takes over the albums, tags, favorite, description, rating, location and names of people from the others. They go to the trash and can be restored.'**
  String get duplicatesScreenKeptTakesOver;

  /// No description provided for @duplicatesScreenResolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get duplicatesScreenResolve;

  /// No description provided for @duplicatesScreenResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved. The copies are in the trash.'**
  String get duplicatesScreenResolved;

  /// No description provided for @duplicatesScreenActionFailed.
  ///
  /// In en, this message translates to:
  /// **'The action failed.'**
  String get duplicatesScreenActionFailed;

  /// No description provided for @duplicatesScreenResolveEveryIdentical.
  ///
  /// In en, this message translates to:
  /// **'Resolve every identical picture?'**
  String get duplicatesScreenResolveEveryIdentical;

  /// No description provided for @duplicatesScreenResolveAllDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Resolve all duplicates?'**
  String get duplicatesScreenResolveAllDuplicates;

  /// No description provided for @duplicatesScreenResolveAllBody.
  ///
  /// In en, this message translates to:
  /// **'Groups: {groups}. {trashed} photos go to the trash, which frees {size} once it is emptied. In each group the proposed photo stays and takes over what the others had.'**
  String duplicatesScreenResolveAllBody(
    String groups,
    String trashed,
    String size,
  );

  /// No description provided for @duplicatesScreenResolveAll.
  ///
  /// In en, this message translates to:
  /// **'Resolve all'**
  String get duplicatesScreenResolveAll;

  /// No description provided for @duplicatesScreenSamePicture.
  ///
  /// In en, this message translates to:
  /// **'Same picture'**
  String get duplicatesScreenSamePicture;

  /// No description provided for @duplicatesScreenAlike.
  ///
  /// In en, this message translates to:
  /// **'Alike'**
  String get duplicatesScreenAlike;

  /// No description provided for @duplicatesScreenProposedToKeep.
  ///
  /// In en, this message translates to:
  /// **'Proposed to keep: {reason} · frees {size}'**
  String duplicatesScreenProposedToKeep(String reason, String size);

  /// No description provided for @duplicatesScreenNotDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Not duplicates'**
  String get duplicatesScreenNotDuplicates;

  /// No description provided for @duplicatesScreenResolveToTrash.
  ///
  /// In en, this message translates to:
  /// **'Resolve ({count} to the trash)'**
  String duplicatesScreenResolveToTrash(String count);

  /// No description provided for @duplicatesScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Duplicates'**
  String get duplicatesScreenTitle;

  /// No description provided for @duplicatesScreenLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Duplicates could not be loaded.'**
  String get duplicatesScreenLoadFailed;

  /// No description provided for @duplicatesScreenPending.
  ///
  /// In en, this message translates to:
  /// **'Photos still being compared: {count}.'**
  String duplicatesScreenPending(String count);

  /// No description provided for @duplicatesScreenNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No similar photos were found.'**
  String get duplicatesScreenNoneFound;

  /// No description provided for @duplicatesScreenTickWhatToKeep.
  ///
  /// In en, this message translates to:
  /// **'Tick what to keep. These are only proposals, and nothing is removed without your confirmation.'**
  String get duplicatesScreenTickWhatToKeep;

  /// No description provided for @duplicatesScreenShowing.
  ///
  /// In en, this message translates to:
  /// **'Showing {shown} of {total}.'**
  String duplicatesScreenShowing(String shown, String total);

  /// No description provided for @duplicatesScreenResolving.
  ///
  /// In en, this message translates to:
  /// **'Resolving duplicates: {done} of {total}'**
  String duplicatesScreenResolving(String done, String total);

  /// No description provided for @duplicatesScreenResolveIdentical.
  ///
  /// In en, this message translates to:
  /// **'Resolve the identical ({count})'**
  String duplicatesScreenResolveIdentical(String count);

  /// No description provided for @duplicatesScreenResolveAllAsProposed.
  ///
  /// In en, this message translates to:
  /// **'Resolve all as proposed ({count})'**
  String duplicatesScreenResolveAllAsProposed(String count);

  /// No description provided for @duplicatesScreenStackLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'This stack could not be loaded.'**
  String get duplicatesScreenStackLoadFailed;

  /// No description provided for @duplicatesScreenSplitStack.
  ///
  /// In en, this message translates to:
  /// **'Split the stack'**
  String get duplicatesScreenSplitStack;

  /// No description provided for @duplicatesScreenMakeMain.
  ///
  /// In en, this message translates to:
  /// **'Make it the main shot'**
  String get duplicatesScreenMakeMain;

  /// No description provided for @accountSheetVersionBuild.
  ///
  /// In en, this message translates to:
  /// **'{version} build {build}'**
  String accountSheetVersionBuild(String version, String build);

  /// No description provided for @accountSheetEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get accountSheetEditProfile;

  /// No description provided for @accountSheetClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get accountSheetClose;

  /// No description provided for @accountSheetPhotosAndVideos.
  ///
  /// In en, this message translates to:
  /// **'{count} photos and videos'**
  String accountSheetPhotosAndVideos(String count);

  /// No description provided for @accountSheetUsed.
  ///
  /// In en, this message translates to:
  /// **'{size} used'**
  String accountSheetUsed(String size);

  /// No description provided for @accountSheetFilesFailed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file could not be processed} other{{count} files could not be processed}}'**
  String accountSheetFilesFailed(int count);

  /// No description provided for @accountSheetAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get accountSheetAppearance;

  /// No description provided for @accountSheetDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get accountSheetDark;

  /// No description provided for @accountSheetLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get accountSheetLight;

  /// No description provided for @accountSheetSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get accountSheetSystem;

  /// No description provided for @accountSheetServerDisk.
  ///
  /// In en, this message translates to:
  /// **'Server disk'**
  String get accountSheetServerDisk;

  /// No description provided for @accountSheetLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get accountSheetLoading;

  /// No description provided for @accountSheetServerNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'The server does not answer.'**
  String get accountSheetServerNoAnswer;

  /// No description provided for @accountSheetDiskUsed.
  ///
  /// In en, this message translates to:
  /// **'{used} of {total} used'**
  String accountSheetDiskUsed(String used, String total);

  /// No description provided for @accountSheetAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get accountSheetAppVersion;

  /// No description provided for @accountSheetServerVersion.
  ///
  /// In en, this message translates to:
  /// **'Server version'**
  String get accountSheetServerVersion;

  /// No description provided for @accountSheetNewVersion.
  ///
  /// In en, this message translates to:
  /// **'New version'**
  String get accountSheetNewVersion;

  /// No description provided for @accountSheetIsAvailable.
  ///
  /// In en, this message translates to:
  /// **'{version} is available'**
  String accountSheetIsAvailable(String version);

  /// No description provided for @accountSheetServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get accountSheetServer;

  /// No description provided for @accountSheetServerAddress.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get accountSheetServerAddress;

  /// No description provided for @accountSheetFreeUpSpace.
  ///
  /// In en, this message translates to:
  /// **'Free up space'**
  String get accountSheetFreeUpSpace;

  /// No description provided for @accountSheetProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get accountSheetProfile;

  /// No description provided for @accountSheetSignInOnAnotherDevice.
  ///
  /// In en, this message translates to:
  /// **'Sign in on another device'**
  String get accountSheetSignInOnAnotherDevice;

  /// No description provided for @accountSheetBackupDevices.
  ///
  /// In en, this message translates to:
  /// **'Backup devices'**
  String get accountSheetBackupDevices;

  /// No description provided for @accountSheetImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get accountSheetImport;

  /// No description provided for @accountSheetAdministration.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get accountSheetAdministration;

  /// No description provided for @accountSheetBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get accountSheetBackup;

  /// No description provided for @accountSheetAllBackupDevices.
  ///
  /// In en, this message translates to:
  /// **'All backup devices'**
  String get accountSheetAllBackupDevices;

  /// No description provided for @accountSheetStorageTemplate.
  ///
  /// In en, this message translates to:
  /// **'Storage template'**
  String get accountSheetStorageTemplate;

  /// No description provided for @accountSheetSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get accountSheetSettings;

  /// No description provided for @accountSheetSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSheetSignOut;

  /// No description provided for @accountSheetDocumentation.
  ///
  /// In en, this message translates to:
  /// **'Documentation'**
  String get accountSheetDocumentation;

  /// No description provided for @accountSheetLicenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get accountSheetLicenses;

  /// No description provided for @searchFiltersSheetFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get searchFiltersSheetFilters;

  /// No description provided for @searchFiltersSheetDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get searchFiltersSheetDate;

  /// No description provided for @searchFiltersSheetFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get searchFiltersSheetFrom;

  /// No description provided for @searchFiltersSheetTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get searchFiltersSheetTo;

  /// No description provided for @searchFiltersSheetType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get searchFiltersSheetType;

  /// No description provided for @searchFiltersSheetAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get searchFiltersSheetAll;

  /// No description provided for @searchFiltersSheetPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get searchFiltersSheetPhotos;

  /// No description provided for @searchFiltersSheetVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get searchFiltersSheetVideos;

  /// No description provided for @searchFiltersSheetPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get searchFiltersSheetPeople;

  /// No description provided for @searchFiltersSheetAnyOfThem.
  ///
  /// In en, this message translates to:
  /// **'Any of them, not all together'**
  String get searchFiltersSheetAnyOfThem;

  /// No description provided for @searchFiltersSheetWhereAndWith.
  ///
  /// In en, this message translates to:
  /// **'Where and with what'**
  String get searchFiltersSheetWhereAndWith;

  /// No description provided for @searchFiltersSheetPlace.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get searchFiltersSheetPlace;

  /// No description provided for @searchFiltersSheetCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get searchFiltersSheetCamera;

  /// No description provided for @searchFiltersSheetLens.
  ///
  /// In en, this message translates to:
  /// **'Lens'**
  String get searchFiltersSheetLens;

  /// No description provided for @searchFiltersSheetRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get searchFiltersSheetRating;

  /// No description provided for @searchFiltersSheetAnyRating.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get searchFiltersSheetAnyRating;

  /// No description provided for @searchFiltersSheetTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get searchFiltersSheetTags;

  /// No description provided for @searchFiltersSheetAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get searchFiltersSheetAlbum;

  /// No description provided for @searchFiltersSheetAnyAlbum.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get searchFiltersSheetAnyAlbum;

  /// No description provided for @searchFiltersSheetInNoAlbum.
  ///
  /// In en, this message translates to:
  /// **'In no album'**
  String get searchFiltersSheetInNoAlbum;

  /// No description provided for @searchFiltersSheetFavouritesOnly.
  ///
  /// In en, this message translates to:
  /// **'Favourites only'**
  String get searchFiltersSheetFavouritesOnly;

  /// No description provided for @searchFiltersSheetClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get searchFiltersSheetClear;

  /// No description provided for @searchFiltersSheetApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get searchFiltersSheetApply;

  /// No description provided for @adminEmailPortNumber.
  ///
  /// In en, this message translates to:
  /// **'The port must be a number.'**
  String get adminEmailPortNumber;

  /// No description provided for @adminEmailSaved.
  ///
  /// In en, this message translates to:
  /// **'Email settings are saved.'**
  String get adminEmailSaved;

  /// No description provided for @adminEmailTestSent.
  ///
  /// In en, this message translates to:
  /// **'A test message was sent to you.'**
  String get adminEmailTestSent;

  /// No description provided for @adminEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get adminEmailTitle;

  /// No description provided for @adminEmailSendEmail.
  ///
  /// In en, this message translates to:
  /// **'Send email'**
  String get adminEmailSendEmail;

  /// No description provided for @adminEmailSmtpServer.
  ///
  /// In en, this message translates to:
  /// **'SMTP server'**
  String get adminEmailSmtpServer;

  /// No description provided for @adminEmailPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get adminEmailPort;

  /// No description provided for @adminEmailEncryption.
  ///
  /// In en, this message translates to:
  /// **'Encryption'**
  String get adminEmailEncryption;

  /// No description provided for @adminEmailNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get adminEmailNone;

  /// No description provided for @adminEmailUserName.
  ///
  /// In en, this message translates to:
  /// **'User name'**
  String get adminEmailUserName;

  /// No description provided for @adminEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get adminEmailPassword;

  /// No description provided for @adminEmailPasswordSaved.
  ///
  /// In en, this message translates to:
  /// **'A password is saved. Empty keeps it.'**
  String get adminEmailPasswordSaved;

  /// No description provided for @adminEmailFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get adminEmailFrom;

  /// No description provided for @adminEmailServerAddress.
  ///
  /// In en, this message translates to:
  /// **'Address of this server'**
  String get adminEmailServerAddress;

  /// No description provided for @adminEmailForLinks.
  ///
  /// In en, this message translates to:
  /// **'For links in messages'**
  String get adminEmailForLinks;

  /// No description provided for @adminEmailSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get adminEmailSave;

  /// No description provided for @adminEmailSendTest.
  ///
  /// In en, this message translates to:
  /// **'Send a test message'**
  String get adminEmailSendTest;

  /// No description provided for @photoEditorScreenActionFailed.
  ///
  /// In en, this message translates to:
  /// **'The action failed. {reason}'**
  String photoEditorScreenActionFailed(String reason);

  /// No description provided for @photoEditorScreenEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get photoEditorScreenEdit;

  /// No description provided for @photoEditorScreenRotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get photoEditorScreenRotate;

  /// No description provided for @photoEditorScreenBrightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get photoEditorScreenBrightness;

  /// No description provided for @photoEditorScreenContrast.
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get photoEditorScreenContrast;

  /// No description provided for @photoEditorScreenSaturation.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get photoEditorScreenSaturation;

  /// No description provided for @photoEditorScreenNoFilter.
  ///
  /// In en, this message translates to:
  /// **'No filter'**
  String get photoEditorScreenNoFilter;

  /// No description provided for @photoEditorScreenBlackAndWhite.
  ///
  /// In en, this message translates to:
  /// **'Black and white'**
  String get photoEditorScreenBlackAndWhite;

  /// No description provided for @photoEditorScreenWarm.
  ///
  /// In en, this message translates to:
  /// **'Warm'**
  String get photoEditorScreenWarm;

  /// No description provided for @photoEditorScreenCool.
  ///
  /// In en, this message translates to:
  /// **'Cool'**
  String get photoEditorScreenCool;

  /// No description provided for @photoEditorScreenVintage.
  ///
  /// In en, this message translates to:
  /// **'Vintage'**
  String get photoEditorScreenVintage;

  /// No description provided for @photoEditorScreenVivid.
  ///
  /// In en, this message translates to:
  /// **'Vivid'**
  String get photoEditorScreenVivid;

  /// No description provided for @photoEditorScreenBackToOriginal.
  ///
  /// In en, this message translates to:
  /// **'Back to the original'**
  String get photoEditorScreenBackToOriginal;

  /// No description provided for @photoEditorScreenSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get photoEditorScreenSave;

  /// No description provided for @homeWidgetScreenHowToIos.
  ///
  /// In en, this message translates to:
  /// **'Then touch and hold an empty spot on the home screen, tap + (or Edit, Add Widget), and choose Mediarr.'**
  String get homeWidgetScreenHowToIos;

  /// No description provided for @homeWidgetScreenHowToAndroid.
  ///
  /// In en, this message translates to:
  /// **'Then touch and hold an empty spot on the home screen, tap Widgets, and drag Mediarr to it.'**
  String get homeWidgetScreenHowToAndroid;

  /// No description provided for @homeWidgetScreenFetchesItself.
  ///
  /// In en, this message translates to:
  /// **'The widget fetches its photos itself, and keeps a few.'**
  String get homeWidgetScreenFetchesItself;

  /// No description provided for @homeWidgetScreenFetching.
  ///
  /// In en, this message translates to:
  /// **'Fetching its photos…'**
  String get homeWidgetScreenFetching;

  /// No description provided for @homeWidgetScreenPicturesKept.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo kept on this phone for it} other{{count} photos kept on this phone for it}}'**
  String homeWidgetScreenPicturesKept(int count);

  /// No description provided for @homeWidgetScreenDidNotWork.
  ///
  /// In en, this message translates to:
  /// **'It did not work.'**
  String get homeWidgetScreenDidNotWork;

  /// No description provided for @homeWidgetScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Home screen widget'**
  String get homeWidgetScreenTitle;

  /// No description provided for @homeWidgetScreenIntro.
  ///
  /// In en, this message translates to:
  /// **'The widget shows a photo from the album you choose here, a different one every hour, also without a connection. {howTo}'**
  String homeWidgetScreenIntro(String howTo);

  /// No description provided for @homeWidgetScreenShowing.
  ///
  /// In en, this message translates to:
  /// **'Showing {album}'**
  String homeWidgetScreenShowing(String album);

  /// No description provided for @homeWidgetScreenShowsNothing.
  ///
  /// In en, this message translates to:
  /// **'The widget shows nothing now.'**
  String get homeWidgetScreenShowsNothing;

  /// No description provided for @homeWidgetScreenTurnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get homeWidgetScreenTurnOff;

  /// No description provided for @homeWidgetScreenAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get homeWidgetScreenAlbum;

  /// No description provided for @homeWidgetScreenNoAlbums.
  ///
  /// In en, this message translates to:
  /// **'There are no albums yet.'**
  String get homeWidgetScreenNoAlbums;

  /// No description provided for @homeWidgetScreenShows.
  ///
  /// In en, this message translates to:
  /// **'The widget shows {album}.'**
  String homeWidgetScreenShows(String album);

  /// No description provided for @homeWidgetNoKey.
  ///
  /// In en, this message translates to:
  /// **'The server did not make a key for the widget.'**
  String get homeWidgetNoKey;

  /// No description provided for @settingsAccentMidnightBlue.
  ///
  /// In en, this message translates to:
  /// **'Midnight blue'**
  String get settingsAccentMidnightBlue;

  /// No description provided for @settingsAccentGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get settingsAccentGold;

  /// No description provided for @settingsAccentViolet.
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get settingsAccentViolet;

  /// No description provided for @settingsAccentMint.
  ///
  /// In en, this message translates to:
  /// **'Mint'**
  String get settingsAccentMint;

  /// No description provided for @settingsAccentRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get settingsAccentRose;

  /// No description provided for @settingsThemeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get settingsThemeAuto;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @homeScreenMedia.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get homeScreenMedia;

  /// No description provided for @homeScreenSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get homeScreenSearch;

  /// No description provided for @homeScreenAlbums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get homeScreenAlbums;

  /// No description provided for @homeScreenLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get homeScreenLibrary;

  /// No description provided for @homeScreenAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get homeScreenAdd;

  /// No description provided for @homeScreenAddUploading.
  ///
  /// In en, this message translates to:
  /// **'Add, {count} uploading'**
  String homeScreenAddUploading(String count);

  /// No description provided for @panoramaViewCannotBeShown.
  ///
  /// In en, this message translates to:
  /// **'The panorama cannot be shown.'**
  String get panoramaViewCannotBeShown;

  /// No description provided for @panoramaViewLabel.
  ///
  /// In en, this message translates to:
  /// **'360° panorama'**
  String get panoramaViewLabel;

  /// No description provided for @fixSheetChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed: {changed}'**
  String fixSheetChanged(int changed);

  /// No description provided for @fixSheetCameraClockWrong.
  ///
  /// In en, this message translates to:
  /// **'When the camera\'s clock was wrong.'**
  String get fixSheetCameraClockWrong;

  /// No description provided for @fixSheetEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get fixSheetEarlier;

  /// No description provided for @fixSheetLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get fixSheetLater;

  /// No description provided for @fixSheetDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get fixSheetDays;

  /// No description provided for @fixSheetHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get fixSheetHours;

  /// No description provided for @fixSheetMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get fixSheetMinutes;

  /// No description provided for @fixSheetOneDateForAll.
  ///
  /// In en, this message translates to:
  /// **'One date for all, a minute apart so they keep their order.'**
  String get fixSheetOneDateForAll;

  /// No description provided for @fixSheetChooseDateTime.
  ///
  /// In en, this message translates to:
  /// **'Choose the date and time'**
  String get fixSheetChooseDateTime;

  /// No description provided for @fixSheetTripHint.
  ///
  /// In en, this message translates to:
  /// **'When the camera kept home\'s time on a trip.'**
  String get fixSheetTripHint;

  /// No description provided for @fixSheetCameraClockWasOn.
  ///
  /// In en, this message translates to:
  /// **'The camera\'s clock was on'**
  String get fixSheetCameraClockWasOn;

  /// No description provided for @fixSheetTheyWereTakenIn.
  ///
  /// In en, this message translates to:
  /// **'They were taken in'**
  String get fixSheetTheyWereTakenIn;

  /// No description provided for @fixSheetZoneFromPlaceHint.
  ///
  /// In en, this message translates to:
  /// **'Photos with a location get the time zone of the place, summer time included; the clock stays as it was.'**
  String get fixSheetZoneFromPlaceHint;

  /// No description provided for @fixSheetDatesByHandRemoved.
  ///
  /// In en, this message translates to:
  /// **'Dates set by hand are taken away.'**
  String get fixSheetDatesByHandRemoved;

  /// No description provided for @fixSheetNeighboursHint.
  ///
  /// In en, this message translates to:
  /// **'Photos without a location get the place of the photo with one taken closest to them.'**
  String get fixSheetNeighboursHint;

  /// No description provided for @fixSheetAtMostMinutesApart.
  ///
  /// In en, this message translates to:
  /// **'At most minutes apart'**
  String get fixSheetAtMostMinutesApart;

  /// No description provided for @fixSheetTrackHint.
  ///
  /// In en, this message translates to:
  /// **'Photos without a location get the place from the track at the moment they were taken. Get the date right first.'**
  String get fixSheetTrackHint;

  /// No description provided for @fixSheetChooseGpx.
  ///
  /// In en, this message translates to:
  /// **'Choose a GPX file'**
  String get fixSheetChooseGpx;

  /// No description provided for @fixSheetFindPlace.
  ///
  /// In en, this message translates to:
  /// **'Find a place'**
  String get fixSheetFindPlace;

  /// No description provided for @fixSheetLatitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get fixSheetLatitude;

  /// No description provided for @fixSheetLongitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get fixSheetLongitude;

  /// No description provided for @fixSheetLocationGoes.
  ///
  /// In en, this message translates to:
  /// **'The location goes, and stays gone.'**
  String get fixSheetLocationGoes;

  /// No description provided for @fixSheetLocationsByHandRemoved.
  ///
  /// In en, this message translates to:
  /// **'Locations set by hand are taken away.'**
  String get fixSheetLocationsByHandRemoved;

  /// No description provided for @fixSheetDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Date and time · {count}'**
  String fixSheetDateTitle(int count);

  /// No description provided for @fixSheetLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location · {count}'**
  String fixSheetLocationTitle(int count);

  /// No description provided for @fixSheetShift.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get fixSheetShift;

  /// No description provided for @fixSheetSetDate.
  ///
  /// In en, this message translates to:
  /// **'Set a date'**
  String get fixSheetSetDate;

  /// No description provided for @fixSheetZoneFromPlace.
  ///
  /// In en, this message translates to:
  /// **'Zone from the place'**
  String get fixSheetZoneFromPlace;

  /// No description provided for @fixSheetTrip.
  ///
  /// In en, this message translates to:
  /// **'A trip'**
  String get fixSheetTrip;

  /// No description provided for @fixSheetFromFile.
  ///
  /// In en, this message translates to:
  /// **'From the file'**
  String get fixSheetFromFile;

  /// No description provided for @fixSheetFromNearby.
  ///
  /// In en, this message translates to:
  /// **'From nearby photos'**
  String get fixSheetFromNearby;

  /// No description provided for @fixSheetFromTrack.
  ///
  /// In en, this message translates to:
  /// **'From a GPX track'**
  String get fixSheetFromTrack;

  /// No description provided for @fixSheetSetPlace.
  ///
  /// In en, this message translates to:
  /// **'Set a place'**
  String get fixSheetSetPlace;

  /// No description provided for @fixSheetClearLocation.
  ///
  /// In en, this message translates to:
  /// **'Take the location away'**
  String get fixSheetClearLocation;

  /// No description provided for @fixSheetWillChange.
  ///
  /// In en, this message translates to:
  /// **'Will change: {changed}'**
  String fixSheetWillChange(int changed);

  /// No description provided for @fixSheetNothingToGoBy.
  ///
  /// In en, this message translates to:
  /// **'nothing to go by: {skipped}'**
  String fixSheetNothingToGoBy(int skipped);

  /// No description provided for @fixSheetNoLocation.
  ///
  /// In en, this message translates to:
  /// **'no location'**
  String get fixSheetNoLocation;

  /// No description provided for @fixSheetCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get fixSheetCancel;

  /// No description provided for @fixSheetSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get fixSheetSave;

  /// No description provided for @adminSecurityRulesSaved.
  ///
  /// In en, this message translates to:
  /// **'The rules are saved.'**
  String get adminSecurityRulesSaved;

  /// No description provided for @adminSecuritySsoSaved.
  ///
  /// In en, this message translates to:
  /// **'Single sign-on is saved.'**
  String get adminSecuritySsoSaved;

  /// No description provided for @adminSecurityForgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Forget this device?'**
  String get adminSecurityForgetTitle;

  /// No description provided for @adminSecurityApproveAgain.
  ///
  /// In en, this message translates to:
  /// **'{email} on it has to be approved again.'**
  String adminSecurityApproveAgain(String email);

  /// No description provided for @adminSecurityCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get adminSecurityCancel;

  /// No description provided for @adminSecurityForget.
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get adminSecurityForget;

  /// No description provided for @adminSecurityDeviceForgotten.
  ///
  /// In en, this message translates to:
  /// **'The device is forgotten.'**
  String get adminSecurityDeviceForgotten;

  /// No description provided for @adminSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get adminSecurityTitle;

  /// No description provided for @adminSecuritySingleSignOn.
  ///
  /// In en, this message translates to:
  /// **'Single sign-on'**
  String get adminSecuritySingleSignOn;

  /// No description provided for @adminSecurityIssuer.
  ///
  /// In en, this message translates to:
  /// **'Issuer'**
  String get adminSecurityIssuer;

  /// No description provided for @adminSecurityIssuerHelp.
  ///
  /// In en, this message translates to:
  /// **'Empty turns single sign-on off'**
  String get adminSecurityIssuerHelp;

  /// No description provided for @adminSecurityClientId.
  ///
  /// In en, this message translates to:
  /// **'Client ID'**
  String get adminSecurityClientId;

  /// No description provided for @adminSecurityClientSecret.
  ///
  /// In en, this message translates to:
  /// **'Client secret'**
  String get adminSecurityClientSecret;

  /// No description provided for @adminSecuritySecretSaved.
  ///
  /// In en, this message translates to:
  /// **'A secret is saved. Empty keeps it.'**
  String get adminSecuritySecretSaved;

  /// No description provided for @adminSecurityButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Button label'**
  String get adminSecurityButtonLabel;

  /// No description provided for @adminSecurityAutoCreate.
  ///
  /// In en, this message translates to:
  /// **'Create an account on first sign-in'**
  String get adminSecurityAutoCreate;

  /// No description provided for @adminSecurityLinkAdmins.
  ///
  /// In en, this message translates to:
  /// **'Administrators may sign in this way'**
  String get adminSecurityLinkAdmins;

  /// No description provided for @adminSecuritySaveSso.
  ///
  /// In en, this message translates to:
  /// **'Save single sign-on'**
  String get adminSecuritySaveSso;

  /// No description provided for @adminSecurityRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get adminSecurityRules;

  /// No description provided for @adminSecurityApprovalRequired.
  ///
  /// In en, this message translates to:
  /// **'New devices must be approved'**
  String get adminSecurityApprovalRequired;

  /// No description provided for @adminSecurityAllowlist.
  ///
  /// In en, this message translates to:
  /// **'Only these addresses may reach the server'**
  String get adminSecurityAllowlist;

  /// No description provided for @adminSecurityYourAddress.
  ///
  /// In en, this message translates to:
  /// **'Your address now: {address}'**
  String adminSecurityYourAddress(String address);

  /// No description provided for @adminSecurityAddresses.
  ///
  /// In en, this message translates to:
  /// **'Addresses and networks'**
  String get adminSecurityAddresses;

  /// No description provided for @adminSecurityAddressesHelp.
  ///
  /// In en, this message translates to:
  /// **'One per line, such as 192.168.1.0/24'**
  String get adminSecurityAddressesHelp;

  /// No description provided for @adminSecuritySaveRules.
  ///
  /// In en, this message translates to:
  /// **'Save the rules'**
  String get adminSecuritySaveRules;

  /// No description provided for @adminSecurityDevices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get adminSecurityDevices;

  /// No description provided for @adminSecurityNoDevices.
  ///
  /// In en, this message translates to:
  /// **'No device has tried to sign in yet.'**
  String get adminSecurityNoDevices;

  /// No description provided for @adminSecurityLastSeen.
  ///
  /// In en, this message translates to:
  /// **'last {time}'**
  String adminSecurityLastSeen(String time);

  /// No description provided for @adminSecurityDeviceApproved.
  ///
  /// In en, this message translates to:
  /// **'The device may sign in.'**
  String get adminSecurityDeviceApproved;

  /// No description provided for @adminSecurityApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get adminSecurityApprove;

  /// No description provided for @adminSecurityAttempts.
  ///
  /// In en, this message translates to:
  /// **'Attempts to get in'**
  String get adminSecurityAttempts;

  /// No description provided for @adminSecuritySignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get adminSecuritySignedIn;

  /// No description provided for @adminSecurityWrongSignIn.
  ///
  /// In en, this message translates to:
  /// **'Wrong sign-in'**
  String get adminSecurityWrongSignIn;

  /// No description provided for @adminSecurityTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts'**
  String get adminSecurityTooManyAttempts;

  /// No description provided for @adminSecurityAddressBlocked.
  ///
  /// In en, this message translates to:
  /// **'Address blocked'**
  String get adminSecurityAddressBlocked;

  /// No description provided for @adminSecurityDeviceNotApproved.
  ///
  /// In en, this message translates to:
  /// **'Device not approved'**
  String get adminSecurityDeviceNotApproved;

  /// No description provided for @adminSecurityPasswordReset.
  ///
  /// In en, this message translates to:
  /// **'Password reset'**
  String get adminSecurityPasswordReset;

  /// No description provided for @adminSecurityNoAttempts.
  ///
  /// In en, this message translates to:
  /// **'No attempts yet.'**
  String get adminSecurityNoAttempts;

  /// No description provided for @adminSecurityShowOlder.
  ///
  /// In en, this message translates to:
  /// **'Show older'**
  String get adminSecurityShowOlder;

  /// No description provided for @adminCommonNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'The server did not answer ({code}).'**
  String adminCommonNoAnswer(String code);

  /// No description provided for @devicesScreenQuiet.
  ///
  /// In en, this message translates to:
  /// **'Quiet'**
  String get devicesScreenQuiet;

  /// No description provided for @devicesScreenNeedsALook.
  ///
  /// In en, this message translates to:
  /// **'Needs a look'**
  String get devicesScreenNeedsALook;

  /// No description provided for @devicesScreenAllGood.
  ///
  /// In en, this message translates to:
  /// **'All good'**
  String get devicesScreenAllGood;

  /// No description provided for @devicesScreenConfirmed.
  ///
  /// In en, this message translates to:
  /// **'{count} files confirmed by the server'**
  String devicesScreenConfirmed(String count);

  /// No description provided for @devicesScreenOfSent.
  ///
  /// In en, this message translates to:
  /// **'{line}, of {files} the device sent'**
  String devicesScreenOfSent(String line, String files);

  /// No description provided for @devicesScreenWaiting.
  ///
  /// In en, this message translates to:
  /// **'waiting {count}'**
  String devicesScreenWaiting(String count);

  /// No description provided for @devicesScreenNotSent.
  ///
  /// In en, this message translates to:
  /// **'not sent {count}'**
  String devicesScreenNotSent(String count);

  /// No description provided for @devicesScreenInTrash.
  ///
  /// In en, this message translates to:
  /// **'in the trash {count}'**
  String devicesScreenInTrash(String count);

  /// No description provided for @devicesScreenGone.
  ///
  /// In en, this message translates to:
  /// **'no longer on the server {count}'**
  String devicesScreenGone(String count);

  /// No description provided for @devicesScreenNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get devicesScreenNever;

  /// No description provided for @devicesScreenDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}}'**
  String devicesScreenDays(int days);

  /// No description provided for @devicesScreenNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Not loaded.'**
  String get devicesScreenNotLoaded;

  /// No description provided for @devicesScreenRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String devicesScreenRemoveTitle(String name);

  /// No description provided for @devicesScreenRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'Its photos stay on the server. If it reports again, it comes back.'**
  String get devicesScreenRemoveBody;

  /// No description provided for @devicesScreenCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get devicesScreenCancel;

  /// No description provided for @devicesScreenRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get devicesScreenRemove;

  /// No description provided for @devicesScreenNotRemoved.
  ///
  /// In en, this message translates to:
  /// **'Not removed.'**
  String get devicesScreenNotRemoved;

  /// No description provided for @devicesScreenSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get devicesScreenSaved;

  /// No description provided for @devicesScreenNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Not saved.'**
  String get devicesScreenNotSaved;

  /// No description provided for @devicesScreenThisPhone.
  ///
  /// In en, this message translates to:
  /// **'{name} · This phone'**
  String devicesScreenThisPhone(String name);

  /// No description provided for @devicesScreenLastReport.
  ///
  /// In en, this message translates to:
  /// **'last report {time}'**
  String devicesScreenLastReport(String time);

  /// No description provided for @devicesScreenOnDevice.
  ///
  /// In en, this message translates to:
  /// **'{verified} of {total} on the device'**
  String devicesScreenOnDevice(String verified, String total);

  /// No description provided for @devicesScreenQuietWarning.
  ///
  /// In en, this message translates to:
  /// **'It has not reported for longer than you allow. Open Mediarr on it and check that backup is on.'**
  String get devicesScreenQuietWarning;

  /// No description provided for @devicesScreenNothingMissing.
  ///
  /// In en, this message translates to:
  /// **'Nothing is missing.'**
  String get devicesScreenNothingMissing;

  /// No description provided for @devicesScreenInTrashOnServer.
  ///
  /// In en, this message translates to:
  /// **'in the trash on the server'**
  String get devicesScreenInTrashOnServer;

  /// No description provided for @devicesScreenDeletedFromServer.
  ///
  /// In en, this message translates to:
  /// **'deleted from the server'**
  String get devicesScreenDeletedFromServer;

  /// No description provided for @devicesScreenWhatIsMissing.
  ///
  /// In en, this message translates to:
  /// **'What is missing'**
  String get devicesScreenWhatIsMissing;

  /// No description provided for @devicesScreenHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get devicesScreenHide;

  /// No description provided for @devicesScreenTryingAgain.
  ///
  /// In en, this message translates to:
  /// **'Trying again.'**
  String get devicesScreenTryingAgain;

  /// No description provided for @devicesScreenTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get devicesScreenTryAgain;

  /// No description provided for @devicesScreenAllBackupDevices.
  ///
  /// In en, this message translates to:
  /// **'All backup devices'**
  String get devicesScreenAllBackupDevices;

  /// No description provided for @devicesScreenBackupDevices.
  ///
  /// In en, this message translates to:
  /// **'Backup devices'**
  String get devicesScreenBackupDevices;

  /// No description provided for @devicesScreenAllIntro.
  ///
  /// In en, this message translates to:
  /// **'Every user’s devices that back up. When one goes quiet, its owner is warned.'**
  String get devicesScreenAllIntro;

  /// No description provided for @devicesScreenIntro.
  ///
  /// In en, this message translates to:
  /// **'Phones that back up, and how much from each is safe on the server. The server counts, from its own files.'**
  String get devicesScreenIntro;

  /// No description provided for @devicesScreenDidNotLoad.
  ///
  /// In en, this message translates to:
  /// **'The devices did not load. Pull to try again.'**
  String get devicesScreenDidNotLoad;

  /// No description provided for @devicesScreenNoneReported.
  ///
  /// In en, this message translates to:
  /// **'No device has reported yet.'**
  String get devicesScreenNoneReported;

  /// No description provided for @devicesScreenNoneReportedTurnOn.
  ///
  /// In en, this message translates to:
  /// **'No device has reported yet. Turn on automatic backup in Upload.'**
  String get devicesScreenNoneReportedTurnOn;

  /// No description provided for @devicesScreenWarnMeAfter.
  ///
  /// In en, this message translates to:
  /// **'Warn me after'**
  String get devicesScreenWarnMeAfter;

  /// No description provided for @devicesScreenWarnHelp.
  ///
  /// In en, this message translates to:
  /// **'A notice here and on the web, and by e-mail if it is set up. Once, until the device reports again.'**
  String get devicesScreenWarnHelp;

  /// No description provided for @timelineScreenActionFailed.
  ///
  /// In en, this message translates to:
  /// **'The action failed. {message}'**
  String timelineScreenActionFailed(String message);

  /// No description provided for @timelineScreenSetVaultPin.
  ///
  /// In en, this message translates to:
  /// **'Set a vault PIN first: Account > Vault.'**
  String get timelineScreenSetVaultPin;

  /// No description provided for @timelineScreenDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {count}?'**
  String timelineScreenDeleteTitle(String count);

  /// No description provided for @timelineScreenTrashRestorable.
  ///
  /// In en, this message translates to:
  /// **'They move to the trash, where they can be restored.'**
  String get timelineScreenTrashRestorable;

  /// No description provided for @timelineScreenTrashDays.
  ///
  /// In en, this message translates to:
  /// **'They move to the trash, where they stay for {days} days and can be restored.'**
  String timelineScreenTrashDays(int days);

  /// No description provided for @timelineScreenCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get timelineScreenCancel;

  /// No description provided for @timelineScreenDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get timelineScreenDelete;

  /// No description provided for @timelineScreenLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Your photos could not be loaded. Check the connection.'**
  String get timelineScreenLoadFailed;

  /// No description provided for @timelineScreenTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get timelineScreenTryAgain;

  /// No description provided for @timelineScreenEmpty.
  ///
  /// In en, this message translates to:
  /// **'No photos yet. Add your first ones in the Upload tab.'**
  String get timelineScreenEmpty;

  /// No description provided for @timelineScreenMedia.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get timelineScreenMedia;

  /// No description provided for @timelineScreenClearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get timelineScreenClearSelection;

  /// No description provided for @timelineScreenAddToAlbum.
  ///
  /// In en, this message translates to:
  /// **'Add to album'**
  String get timelineScreenAddToAlbum;

  /// No description provided for @timelineScreenShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get timelineScreenShare;

  /// No description provided for @timelineScreenAddToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get timelineScreenAddToFavorites;

  /// No description provided for @timelineScreenMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get timelineScreenMore;

  /// No description provided for @timelineScreenArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get timelineScreenArchive;

  /// No description provided for @timelineScreenAddTag.
  ///
  /// In en, this message translates to:
  /// **'Add a tag'**
  String get timelineScreenAddTag;

  /// No description provided for @timelineScreenDateTimeMenu.
  ///
  /// In en, this message translates to:
  /// **'Date and time…'**
  String get timelineScreenDateTimeMenu;

  /// No description provided for @timelineScreenLocationMenu.
  ///
  /// In en, this message translates to:
  /// **'Location…'**
  String get timelineScreenLocationMenu;

  /// No description provided for @timelineScreenMoveToVault.
  ///
  /// In en, this message translates to:
  /// **'Move to the vault'**
  String get timelineScreenMoveToVault;

  /// No description provided for @timelineScreenMonthFailed.
  ///
  /// In en, this message translates to:
  /// **'{month} could not be loaded. Try again.'**
  String timelineScreenMonthFailed(String month);

  /// No description provided for @agentProgramOnSystem.
  ///
  /// In en, this message translates to:
  /// **'{program} on {system}'**
  String agentProgramOnSystem(String program, String system);

  /// No description provided for @agentUnknownDevice.
  ///
  /// In en, this message translates to:
  /// **'Unknown device'**
  String get agentUnknownDevice;

  /// No description provided for @agentMediarrApp.
  ///
  /// In en, this message translates to:
  /// **'Mediarr app'**
  String get agentMediarrApp;

  /// No description provided for @agentNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get agentNow;

  /// No description provided for @agentMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String agentMinutesAgo(int count);

  /// No description provided for @agentHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String agentHoursAgo(int count);

  /// No description provided for @agentDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String agentDaysAgo(int count);

  /// No description provided for @agentWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week ago} other{{count} weeks ago}}'**
  String agentWeeksAgo(int count);

  /// No description provided for @agentMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month ago} other{{count} months ago}}'**
  String agentMonthsAgo(int count);

  /// No description provided for @agentYearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year ago} other{{count} years ago}}'**
  String agentYearsAgo(int count);

  /// No description provided for @slideshowScreenCrossfade.
  ///
  /// In en, this message translates to:
  /// **'Crossfade'**
  String get slideshowScreenCrossfade;

  /// No description provided for @slideshowScreenSlide.
  ///
  /// In en, this message translates to:
  /// **'Slide'**
  String get slideshowScreenSlide;

  /// No description provided for @slideshowScreenSlowZoom.
  ///
  /// In en, this message translates to:
  /// **'Slow zoom'**
  String get slideshowScreenSlowZoom;

  /// No description provided for @slideshowScreenNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get slideshowScreenNone;

  /// No description provided for @slideshowScreenSettings.
  ///
  /// In en, this message translates to:
  /// **'Slideshow settings'**
  String get slideshowScreenSettings;

  /// No description provided for @slideshowScreenPace.
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get slideshowScreenPace;

  /// No description provided for @slideshowScreenTransition.
  ///
  /// In en, this message translates to:
  /// **'Transition'**
  String get slideshowScreenTransition;

  /// No description provided for @slideshowScreenShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get slideshowScreenShuffle;

  /// No description provided for @slideshowScreenLoop.
  ///
  /// In en, this message translates to:
  /// **'Loop'**
  String get slideshowScreenLoop;

  /// No description provided for @slideshowScreenDateAndPlace.
  ///
  /// In en, this message translates to:
  /// **'Date and place'**
  String get slideshowScreenDateAndPlace;

  /// No description provided for @slideshowScreenTheEnd.
  ///
  /// In en, this message translates to:
  /// **'The end.'**
  String get slideshowScreenTheEnd;

  /// No description provided for @slideshowScreenPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get slideshowScreenPrevious;

  /// No description provided for @slideshowScreenPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get slideshowScreenPlay;

  /// No description provided for @slideshowScreenPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get slideshowScreenPause;

  /// No description provided for @slideshowScreenNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get slideshowScreenNext;

  /// No description provided for @slideshowScreenClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get slideshowScreenClose;

  /// No description provided for @notificationsAlbumShared.
  ///
  /// In en, this message translates to:
  /// **'\"{subject}\" was shared with you'**
  String notificationsAlbumShared(String subject);

  /// No description provided for @notificationsImportDone.
  ///
  /// In en, this message translates to:
  /// **'The import from {subject} finished'**
  String notificationsImportDone(String subject);

  /// No description provided for @notificationsImportFailed.
  ///
  /// In en, this message translates to:
  /// **'The import from {subject} failed'**
  String notificationsImportFailed(String subject);

  /// No description provided for @notificationsDeviceQuiet.
  ///
  /// In en, this message translates to:
  /// **'{subject} has stopped backing up'**
  String notificationsDeviceQuiet(String subject);

  /// No description provided for @notificationsCopyForLate.
  ///
  /// In en, this message translates to:
  /// **'The copy for {name} has not gone out for three days'**
  String notificationsCopyForLate(String name);

  /// No description provided for @notificationsCopyFromLate.
  ///
  /// In en, this message translates to:
  /// **'The copy from {name} has not come in for three days'**
  String notificationsCopyFromLate(String name);

  /// No description provided for @notificationsBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'A backup failed: {subject}'**
  String notificationsBackupFailed(String subject);

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsNotRemoved.
  ///
  /// In en, this message translates to:
  /// **'This could not be removed.'**
  String get notificationsNotRemoved;

  /// No description provided for @notificationsNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'This could not be loaded.'**
  String get notificationsNotLoaded;

  /// No description provided for @notificationsNone.
  ///
  /// In en, this message translates to:
  /// **'No notifications.'**
  String get notificationsNone;

  /// No description provided for @notificationsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get notificationsRemove;

  /// No description provided for @assetFactsNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Not saved. {message}'**
  String assetFactsNotSaved(String message);

  /// No description provided for @assetFactsEditDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get assetFactsEditDetails;

  /// No description provided for @assetFactsDateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get assetFactsDateAndTime;

  /// No description provided for @assetFactsFindPlace.
  ///
  /// In en, this message translates to:
  /// **'Find a place'**
  String get assetFactsFindPlace;

  /// No description provided for @assetFactsLatitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get assetFactsLatitude;

  /// No description provided for @assetFactsLongitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get assetFactsLongitude;

  /// No description provided for @assetFactsDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get assetFactsDescription;

  /// No description provided for @assetFactsUseFile.
  ///
  /// In en, this message translates to:
  /// **'Use what the file says'**
  String get assetFactsUseFile;

  /// No description provided for @assetFactsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get assetFactsCancel;

  /// No description provided for @assetFactsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get assetFactsSave;

  /// No description provided for @assetFactsStars.
  ///
  /// In en, this message translates to:
  /// **'{stars} of 5 stars'**
  String assetFactsStars(String stars);

  /// No description provided for @documentsScreenNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'An administrator has not turned this album on.'**
  String get documentsScreenNotEnabled;

  /// No description provided for @documentsScreenNeedsAnalysis.
  ///
  /// In en, this message translates to:
  /// **'This needs picture analysis to be on.'**
  String get documentsScreenNeedsAnalysis;

  /// No description provided for @documentsScreenNoText.
  ///
  /// In en, this message translates to:
  /// **'No photos with text yet.'**
  String get documentsScreenNoText;

  /// No description provided for @documentsScreenLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Documents could not be loaded.'**
  String get documentsScreenLoadFailed;

  /// No description provided for @documentsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documentsScreenTitle;

  /// No description provided for @sharingNoPhotoAccess.
  ///
  /// In en, this message translates to:
  /// **'Mediarr may not add photos to this phone'**
  String get sharingNoPhotoAccess;

  /// No description provided for @backupNoDeviceKey.
  ///
  /// In en, this message translates to:
  /// **'The server did not create a device key.'**
  String get backupNoDeviceKey;

  /// No description provided for @foldersScreenFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get foldersScreenFolders;

  /// No description provided for @foldersScreenLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The folder could not be loaded.'**
  String get foldersScreenLoadFailed;

  /// No description provided for @foldersScreenNoExternalLibrary.
  ///
  /// In en, this message translates to:
  /// **'You have no external library. An administrator sets it up in Settings.'**
  String get foldersScreenNoExternalLibrary;

  /// No description provided for @foldersScreenEmpty.
  ///
  /// In en, this message translates to:
  /// **'This folder is empty.'**
  String get foldersScreenEmpty;

  /// No description provided for @searchQueryNoName.
  ///
  /// In en, this message translates to:
  /// **'No name'**
  String get searchQueryNoName;

  /// No description provided for @searchQueryVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get searchQueryVideos;

  /// No description provided for @searchQueryPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get searchQueryPhotos;

  /// No description provided for @searchQueryInAlbum.
  ///
  /// In en, this message translates to:
  /// **'In album: {title}'**
  String searchQueryInAlbum(String title);

  /// No description provided for @searchQueryInNoAlbum.
  ///
  /// In en, this message translates to:
  /// **'In no album'**
  String get searchQueryInNoAlbum;

  /// No description provided for @searchQueryFavourites.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get searchQueryFavourites;

  /// No description provided for @exploreScreenExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get exploreScreenExplore;

  /// No description provided for @exploreScreenPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get exploreScreenPeople;

  /// No description provided for @exploreScreenPlaces.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get exploreScreenPlaces;

  /// No description provided for @exploreScreenMemories.
  ///
  /// In en, this message translates to:
  /// **'Memories'**
  String get exploreScreenMemories;

  /// No description provided for @exploreScreenPeopleFailed.
  ///
  /// In en, this message translates to:
  /// **'People could not be loaded.'**
  String get exploreScreenPeopleFailed;

  /// No description provided for @exploreScreenNoNamedPeople.
  ///
  /// In en, this message translates to:
  /// **'No named people yet.'**
  String get exploreScreenNoNamedPeople;

  /// No description provided for @exploreScreenPlacesFailed.
  ///
  /// In en, this message translates to:
  /// **'Places could not be loaded.'**
  String get exploreScreenPlacesFailed;

  /// No description provided for @exploreScreenNoPlaces.
  ///
  /// In en, this message translates to:
  /// **'No photos with a place yet.'**
  String get exploreScreenNoPlaces;

  /// No description provided for @exploreScreenMemoriesFailed.
  ///
  /// In en, this message translates to:
  /// **'Memories could not be loaded.'**
  String get exploreScreenMemoriesFailed;

  /// No description provided for @exploreScreenNoMemories.
  ///
  /// In en, this message translates to:
  /// **'No memories today.'**
  String get exploreScreenNoMemories;

  /// No description provided for @exploreScreenAllPeople.
  ///
  /// In en, this message translates to:
  /// **'All People'**
  String get exploreScreenAllPeople;

  /// No description provided for @exploreScreenAllPlaces.
  ///
  /// In en, this message translates to:
  /// **'All Places'**
  String get exploreScreenAllPlaces;

  /// No description provided for @exploreScreenAllMemories.
  ///
  /// In en, this message translates to:
  /// **'All Memories'**
  String get exploreScreenAllMemories;

  /// No description provided for @sharedScreenActionFailed.
  ///
  /// In en, this message translates to:
  /// **'The action failed. {reason}'**
  String sharedScreenActionFailed(String reason);

  /// No description provided for @sharedScreenWholeLibrary.
  ///
  /// In en, this message translates to:
  /// **'Whole library'**
  String get sharedScreenWholeLibrary;

  /// No description provided for @sharedScreenFrom.
  ///
  /// In en, this message translates to:
  /// **'From {date}'**
  String sharedScreenFrom(String date);

  /// No description provided for @sharedScreenLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'This could not be loaded. Check the connection.'**
  String get sharedScreenLoadFailed;

  /// No description provided for @sharedScreenTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get sharedScreenTryAgain;

  /// No description provided for @sharedScreenAlbumsWithMe.
  ///
  /// In en, this message translates to:
  /// **'Albums shared with me'**
  String get sharedScreenAlbumsWithMe;

  /// No description provided for @sharedScreenNothingShared.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been shared yet.'**
  String get sharedScreenNothingShared;

  /// No description provided for @sharedScreenLibrariesWithMe.
  ///
  /// In en, this message translates to:
  /// **'Libraries shared with me'**
  String get sharedScreenLibrariesWithMe;

  /// No description provided for @sharedScreenNobodyShares.
  ///
  /// In en, this message translates to:
  /// **'Nobody shares their library with you.'**
  String get sharedScreenNobodyShares;

  /// No description provided for @sharedScreenShowInMyMedia.
  ///
  /// In en, this message translates to:
  /// **'Show in my Media'**
  String get sharedScreenShowInMyMedia;

  /// No description provided for @sharedScreenMyLibrarySharedWith.
  ///
  /// In en, this message translates to:
  /// **'My library is shared with'**
  String get sharedScreenMyLibrarySharedWith;

  /// No description provided for @sharedScreenNobodyYet.
  ///
  /// In en, this message translates to:
  /// **'Nobody yet.'**
  String get sharedScreenNobodyYet;

  /// No description provided for @sharedScreenStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get sharedScreenStop;

  /// No description provided for @sharedScreenUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get sharedScreenUser;

  /// No description provided for @sharedScreenChooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose date'**
  String get sharedScreenChooseDate;

  /// No description provided for @sharedScreenNeverShared.
  ///
  /// In en, this message translates to:
  /// **'The archive, trash and vault are never shared.'**
  String get sharedScreenNeverShared;

  /// No description provided for @sharedScreenShareMyLibrary.
  ///
  /// In en, this message translates to:
  /// **'Share my library'**
  String get sharedScreenShareMyLibrary;

  /// No description provided for @sharedScreenShared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get sharedScreenShared;

  /// No description provided for @sharedScreenLibraryNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'This library is not available.'**
  String get sharedScreenLibraryNotAvailable;

  /// No description provided for @sharedScreenNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos yet.'**
  String get sharedScreenNoPhotos;

  /// No description provided for @loginScreenEnterServerFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter the address of your server first.'**
  String get loginScreenEnterServerFirst;

  /// No description provided for @loginScreenAllowOnCodeScreen.
  ///
  /// In en, this message translates to:
  /// **'Allow this sign-in on the screen that shows the code.'**
  String get loginScreenAllowOnCodeScreen;

  /// No description provided for @loginScreenCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get loginScreenCancel;

  /// No description provided for @loginScreenEnterTotp.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code from your authenticator app.'**
  String get loginScreenEnterTotp;

  /// No description provided for @loginScreenSignInToServer.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your Mediarr server.'**
  String get loginScreenSignInToServer;

  /// No description provided for @loginScreenCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get loginScreenCode;

  /// No description provided for @loginScreenServerAddress.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get loginScreenServerAddress;

  /// No description provided for @loginScreenEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginScreenEmail;

  /// No description provided for @loginScreenPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginScreenPassword;

  /// No description provided for @loginScreenVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get loginScreenVerify;

  /// No description provided for @loginScreenSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginScreenSignIn;

  /// No description provided for @loginScreenSingleSignOn.
  ///
  /// In en, this message translates to:
  /// **'Use single sign-on'**
  String get loginScreenSingleSignOn;

  /// No description provided for @loginScreenScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get loginScreenScanQr;

  /// No description provided for @loginScreenEnterSignInCode.
  ///
  /// In en, this message translates to:
  /// **'Enter a sign-in code'**
  String get loginScreenEnterSignInCode;

  /// No description provided for @loginScreenSignInCode.
  ///
  /// In en, this message translates to:
  /// **'Sign-in code'**
  String get loginScreenSignInCode;

  /// No description provided for @qrSignInScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan the sign-in code'**
  String get qrSignInScanTitle;

  /// No description provided for @qrSignInScanHelp.
  ///
  /// In en, this message translates to:
  /// **'On a screen where you are signed in, open the account menu and choose \"Sign in on a phone\".'**
  String get qrSignInScanHelp;

  /// No description provided for @qrSignInLooking.
  ///
  /// In en, this message translates to:
  /// **'Looking for servers on this network…'**
  String get qrSignInLooking;

  /// No description provided for @qrSignInNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No server found on this network.'**
  String get qrSignInNoneFound;

  /// No description provided for @qrSignInOnThisNetwork.
  ///
  /// In en, this message translates to:
  /// **'On this network'**
  String get qrSignInOnThisNetwork;

  /// No description provided for @qrSignInLookAgain.
  ///
  /// In en, this message translates to:
  /// **'Look again'**
  String get qrSignInLookAgain;

  /// No description provided for @qrSignInMakeCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not make a code.'**
  String get qrSignInMakeCodeFailed;

  /// No description provided for @qrSignInTheDevice.
  ///
  /// In en, this message translates to:
  /// **'the device'**
  String get qrSignInTheDevice;

  /// No description provided for @qrSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in on another device'**
  String get qrSignInTitle;

  /// No description provided for @qrSignInHowTo.
  ///
  /// In en, this message translates to:
  /// **'In the Mediarr app on the other device, tap \"Scan QR code\" on the sign-in screen.'**
  String get qrSignInHowTo;

  /// No description provided for @qrSignInQrLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign-in QR code'**
  String get qrSignInQrLabel;

  /// No description provided for @qrSignInOrType.
  ///
  /// In en, this message translates to:
  /// **'Or type the code'**
  String get qrSignInOrType;

  /// No description provided for @qrSignInValidFor.
  ///
  /// In en, this message translates to:
  /// **'Valid for {time}'**
  String qrSignInValidFor(String time);

  /// No description provided for @qrSignInAllowOn.
  ///
  /// In en, this message translates to:
  /// **'Allow sign-in on {device}?'**
  String qrSignInAllowOn(String device);

  /// No description provided for @qrSignInAllowOnlyIf.
  ///
  /// In en, this message translates to:
  /// **'Allow only if you just scanned the code on your own device.'**
  String get qrSignInAllowOnlyIf;

  /// No description provided for @qrSignInDeny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get qrSignInDeny;

  /// No description provided for @qrSignInAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get qrSignInAllow;

  /// No description provided for @qrSignInSignedIn.
  ///
  /// In en, this message translates to:
  /// **'{device} is signed in. It shows under Account → Devices.'**
  String qrSignInSignedIn(String device);

  /// No description provided for @qrSignInDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get qrSignInDone;

  /// No description provided for @qrSignInDenied.
  ///
  /// In en, this message translates to:
  /// **'The sign-in was denied.'**
  String get qrSignInDenied;

  /// No description provided for @qrSignInExpired.
  ///
  /// In en, this message translates to:
  /// **'The code has expired.'**
  String get qrSignInExpired;

  /// No description provided for @qrSignInNewCode.
  ///
  /// In en, this message translates to:
  /// **'New code'**
  String get qrSignInNewCode;

  /// No description provided for @uploadScreenChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose photos and videos from this device to upload them.'**
  String get uploadScreenChoose;

  /// No description provided for @uploadScreenOpenLibrary.
  ///
  /// In en, this message translates to:
  /// **'Open photo library'**
  String get uploadScreenOpenLibrary;

  /// No description provided for @uploadScreenNeedsAccess.
  ///
  /// In en, this message translates to:
  /// **'Mediarr needs access to your photos. Allow it in Settings.'**
  String get uploadScreenNeedsAccess;

  /// No description provided for @uploadScreenOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get uploadScreenOpenSettings;

  /// No description provided for @uploadScreenNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'There are no photos on this device.'**
  String get uploadScreenNoPhotos;

  /// No description provided for @uploadScreenUploadCount.
  ///
  /// In en, this message translates to:
  /// **'Upload {count}'**
  String uploadScreenUploadCount(String count);

  /// No description provided for @uploadScreenQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get uploadScreenQueued;

  /// No description provided for @uploadScreenPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get uploadScreenPreparing;

  /// No description provided for @uploadScreenUploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploadScreenUploaded;

  /// No description provided for @uploadScreenAlreadyOnServer.
  ///
  /// In en, this message translates to:
  /// **'Already on server'**
  String get uploadScreenAlreadyOnServer;

  /// No description provided for @uploadScreenFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get uploadScreenFailed;

  /// No description provided for @uploadScreenFinished.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} finished'**
  String uploadScreenFinished(String done, String total);

  /// No description provided for @uploadScreenClearFailed.
  ///
  /// In en, this message translates to:
  /// **'Clear failed'**
  String get uploadScreenClearFailed;

  /// No description provided for @uploadScreenPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get uploadScreenPhoto;

  /// No description provided for @backupCardNothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been backed up yet.'**
  String get backupCardNothingYet;

  /// No description provided for @backupCardLastJustNow.
  ///
  /// In en, this message translates to:
  /// **'Last file backed up just now.'**
  String get backupCardLastJustNow;

  /// No description provided for @backupCardLastMinutes.
  ///
  /// In en, this message translates to:
  /// **'Last file backed up {minutes} min ago.'**
  String backupCardLastMinutes(String minutes);

  /// No description provided for @backupCardLastHours.
  ///
  /// In en, this message translates to:
  /// **'Last file backed up {hours} h ago.'**
  String backupCardLastHours(String hours);

  /// No description provided for @backupCardLastDays.
  ///
  /// In en, this message translates to:
  /// **'Last file backed up {days} d ago.'**
  String backupCardLastDays(String days);

  /// No description provided for @backupCardScopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Back up \"{album}\"'**
  String backupCardScopeTitle(String album);

  /// No description provided for @backupCardScopeBody.
  ///
  /// In en, this message translates to:
  /// **'Should photos already in this album be sent? Anything already on the server is never sent twice.'**
  String get backupCardScopeBody;

  /// No description provided for @backupCardOnlyNew.
  ///
  /// In en, this message translates to:
  /// **'Only photos added from now'**
  String get backupCardOnlyNew;

  /// No description provided for @backupCardAlsoExisting.
  ///
  /// In en, this message translates to:
  /// **'Also the ones in it now'**
  String get backupCardAlsoExisting;

  /// No description provided for @backupCardTheAddedAlbums.
  ///
  /// In en, this message translates to:
  /// **'the added albums'**
  String get backupCardTheAddedAlbums;

  /// No description provided for @backupCardNeedsFullAccess.
  ///
  /// In en, this message translates to:
  /// **'Albums need access to all photos. Allow it in Settings: Mediarr > Photos > Full Access.'**
  String get backupCardNeedsFullAccess;

  /// No description provided for @backupCardServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'The server could not be reached. {reason}'**
  String backupCardServerUnreachable(String reason);

  /// No description provided for @backupCardAutomaticBackup.
  ///
  /// In en, this message translates to:
  /// **'Automatic backup'**
  String get backupCardAutomaticBackup;

  /// No description provided for @backupCardAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album: {name}'**
  String backupCardAlbum(String name);

  /// No description provided for @backupCardChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get backupCardChange;

  /// No description provided for @backupCardNeedsFullAccessNothingSent.
  ///
  /// In en, this message translates to:
  /// **'Albums need access to all photos. Allow it in Settings: Mediarr > Photos > Full Access. Nothing is being sent.'**
  String get backupCardNeedsFullAccessNothingSent;

  /// No description provided for @backupCardNoSuchAlbum.
  ///
  /// In en, this message translates to:
  /// **'No album with this name on the device. Nothing is being sent.'**
  String get backupCardNoSuchAlbum;

  /// No description provided for @backupCardMoreAlbums.
  ///
  /// In en, this message translates to:
  /// **'More albums: {more}, never sent: {never}'**
  String backupCardMoreAlbums(String more, String never);

  /// No description provided for @backupCardOnlyWifi.
  ///
  /// In en, this message translates to:
  /// **'Only on Wi-Fi'**
  String get backupCardOnlyWifi;

  /// No description provided for @backupCardOnlyCharging.
  ///
  /// In en, this message translates to:
  /// **'Only while charging'**
  String get backupCardOnlyCharging;

  /// No description provided for @backupCardVerified.
  ///
  /// In en, this message translates to:
  /// **'{verified} of {total} verified on the server'**
  String backupCardVerified(String verified, String total);

  /// No description provided for @backupCardCounts.
  ///
  /// In en, this message translates to:
  /// **'{sending} sending · {waiting} waiting · {failed} failed'**
  String backupCardCounts(String sending, String waiting, String failed);

  /// No description provided for @backupCardPerDevice.
  ///
  /// In en, this message translates to:
  /// **'What the server confirms, per device'**
  String get backupCardPerDevice;

  /// No description provided for @backupCardRefused.
  ///
  /// In en, this message translates to:
  /// **'The server refused this device. Turn backup off and on again.'**
  String get backupCardRefused;

  /// No description provided for @backupCardFreeUpSpace.
  ///
  /// In en, this message translates to:
  /// **'Free up space'**
  String get backupCardFreeUpSpace;

  /// No description provided for @backupCardRetryFailed.
  ///
  /// In en, this message translates to:
  /// **'Try the {count} failed again'**
  String backupCardRetryFailed(String count);

  /// No description provided for @backupCardOffHelp.
  ///
  /// In en, this message translates to:
  /// **'Sends one album of your choice, and nothing else. Checks for new photos every minute while the app is open. When it is closed, iOS decides when, often much later, and stops it if you swipe the app away.'**
  String get backupCardOffHelp;

  /// No description provided for @backupCardWhichAlbum.
  ///
  /// In en, this message translates to:
  /// **'Which album?'**
  String get backupCardWhichAlbum;

  /// No description provided for @backupCardAlbumName.
  ///
  /// In en, this message translates to:
  /// **'Album name'**
  String get backupCardAlbumName;

  /// No description provided for @backupCardUseName.
  ///
  /// In en, this message translates to:
  /// **'Use the name \"{name}\"'**
  String backupCardUseName(String name);

  /// No description provided for @backupCardStartsWhenExists.
  ///
  /// In en, this message translates to:
  /// **'Starts when an album with this name exists'**
  String get backupCardStartsWhenExists;

  /// No description provided for @backupCardNoAlbums.
  ///
  /// In en, this message translates to:
  /// **'No albums on this device yet. Create one in Photos.'**
  String get backupCardNoAlbums;

  /// No description provided for @backupCardNeverHelp.
  ///
  /// In en, this message translates to:
  /// **'A photo in a \"Never\" album is not sent, even if it is also in another album.'**
  String get backupCardNeverHelp;

  /// No description provided for @backupCardNotAdded.
  ///
  /// In en, this message translates to:
  /// **'Not added'**
  String get backupCardNotAdded;

  /// No description provided for @backupCardBackUp.
  ///
  /// In en, this message translates to:
  /// **'Back up'**
  String get backupCardBackUp;

  /// No description provided for @backupCardNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get backupCardNever;

  /// No description provided for @backupCardSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get backupCardSave;

  /// No description provided for @albumSheetsOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get albumSheetsOwner;

  /// No description provided for @albumSheetsEditor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get albumSheetsEditor;

  /// No description provided for @albumSheetsContributor.
  ///
  /// In en, this message translates to:
  /// **'Contributor'**
  String get albumSheetsContributor;

  /// No description provided for @albumSheetsViewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get albumSheetsViewer;

  /// No description provided for @albumSheetsUploadOnly.
  ///
  /// In en, this message translates to:
  /// **'upload only'**
  String get albumSheetsUploadOnly;

  /// No description provided for @albumSheetsPassword.
  ///
  /// In en, this message translates to:
  /// **'password'**
  String get albumSheetsPassword;

  /// No description provided for @albumSheetsWatermarkFact.
  ///
  /// In en, this message translates to:
  /// **'watermark'**
  String get albumSheetsWatermarkFact;

  /// No description provided for @albumSheetsExpiresFact.
  ///
  /// In en, this message translates to:
  /// **'expires {date}'**
  String albumSheetsExpiresFact(String date);

  /// No description provided for @albumSheetsDownloadsFact.
  ///
  /// In en, this message translates to:
  /// **'downloads: {count}'**
  String albumSheetsDownloadsFact(String count);

  /// No description provided for @albumSheetsActionFailed.
  ///
  /// In en, this message translates to:
  /// **'The action failed.'**
  String get albumSheetsActionFailed;

  /// No description provided for @albumSheetsComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get albumSheetsComments;

  /// No description provided for @albumSheetsCommentsAndHearts.
  ///
  /// In en, this message translates to:
  /// **'Comments and hearts'**
  String get albumSheetsCommentsAndHearts;

  /// No description provided for @albumSheetsCommentsFailed.
  ///
  /// In en, this message translates to:
  /// **'Comments could not be loaded.'**
  String get albumSheetsCommentsFailed;

  /// No description provided for @albumSheetsHeart.
  ///
  /// In en, this message translates to:
  /// **'Heart'**
  String get albumSheetsHeart;

  /// No description provided for @albumSheetsNoComments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get albumSheetsNoComments;

  /// No description provided for @albumSheetsDeleteComment.
  ///
  /// In en, this message translates to:
  /// **'Delete comment'**
  String get albumSheetsDeleteComment;

  /// No description provided for @albumSheetsComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get albumSheetsComment;

  /// No description provided for @albumSheetsSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get albumSheetsSend;

  /// No description provided for @albumSheetsAddToAlbum.
  ///
  /// In en, this message translates to:
  /// **'Add to album'**
  String get albumSheetsAddToAlbum;

  /// No description provided for @albumSheetsAlbumsFailed.
  ///
  /// In en, this message translates to:
  /// **'Albums could not be loaded.'**
  String get albumSheetsAlbumsFailed;

  /// No description provided for @albumSheetsNewAlbum.
  ///
  /// In en, this message translates to:
  /// **'New album'**
  String get albumSheetsNewAlbum;

  /// No description provided for @albumSheetsCreateAndAdd.
  ///
  /// In en, this message translates to:
  /// **'Create and add'**
  String get albumSheetsCreateAndAdd;

  /// No description provided for @albumSheetsShareWithUsers.
  ///
  /// In en, this message translates to:
  /// **'Share with users'**
  String get albumSheetsShareWithUsers;

  /// No description provided for @albumSheetsSharingFailed.
  ///
  /// In en, this message translates to:
  /// **'Sharing could not be loaded.'**
  String get albumSheetsSharingFailed;

  /// No description provided for @albumSheetsNotShared.
  ///
  /// In en, this message translates to:
  /// **'This album is not shared yet.'**
  String get albumSheetsNotShared;

  /// No description provided for @albumSheetsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get albumSheetsRemove;

  /// No description provided for @albumSheetsNoOtherUsers.
  ///
  /// In en, this message translates to:
  /// **'There are no other users on this server.'**
  String get albumSheetsNoOtherUsers;

  /// No description provided for @albumSheetsUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get albumSheetsUser;

  /// No description provided for @albumSheetsRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get albumSheetsRole;

  /// No description provided for @albumSheetsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get albumSheetsAdd;

  /// No description provided for @albumSheetsPublicLinks.
  ///
  /// In en, this message translates to:
  /// **'Public links'**
  String get albumSheetsPublicLinks;

  /// No description provided for @albumSheetsCopyNow.
  ///
  /// In en, this message translates to:
  /// **'Copy the address now: it cannot be shown again later.'**
  String get albumSheetsCopyNow;

  /// No description provided for @albumSheetsCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get albumSheetsCopy;

  /// No description provided for @albumSheetsLinksFailed.
  ///
  /// In en, this message translates to:
  /// **'Links could not be loaded.'**
  String get albumSheetsLinksFailed;

  /// No description provided for @albumSheetsUnnamedLink.
  ///
  /// In en, this message translates to:
  /// **'Unnamed link'**
  String get albumSheetsUnnamedLink;

  /// No description provided for @albumSheetsRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get albumSheetsRevoke;

  /// No description provided for @albumSheetsName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get albumSheetsName;

  /// No description provided for @albumSheetsPasswordOptional.
  ///
  /// In en, this message translates to:
  /// **'Password (optional)'**
  String get albumSheetsPasswordOptional;

  /// No description provided for @albumSheetsNoExpiry.
  ///
  /// In en, this message translates to:
  /// **'No expiry'**
  String get albumSheetsNoExpiry;

  /// No description provided for @albumSheetsExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String albumSheetsExpires(String date);

  /// No description provided for @albumSheetsChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get albumSheetsChoose;

  /// No description provided for @albumSheetsDownloadLimit.
  ///
  /// In en, this message translates to:
  /// **'Download limit'**
  String get albumSheetsDownloadLimit;

  /// No description provided for @albumSheetsWatermark.
  ///
  /// In en, this message translates to:
  /// **'Watermark'**
  String get albumSheetsWatermark;

  /// No description provided for @albumSheetsWatermarkHelp.
  ///
  /// In en, this message translates to:
  /// **'A watermark turns off original downloads and video playback.'**
  String get albumSheetsWatermarkHelp;

  /// No description provided for @albumSheetsAllowDownloads.
  ///
  /// In en, this message translates to:
  /// **'Allow downloads'**
  String get albumSheetsAllowDownloads;

  /// No description provided for @albumSheetsShowLocation.
  ///
  /// In en, this message translates to:
  /// **'Show location'**
  String get albumSheetsShowLocation;

  /// No description provided for @albumSheetsGuestsCanAdd.
  ///
  /// In en, this message translates to:
  /// **'Guests can add photos'**
  String get albumSheetsGuestsCanAdd;

  /// No description provided for @albumSheetsUploadOnlyLong.
  ///
  /// In en, this message translates to:
  /// **'Upload only (guests do not see the album)'**
  String get albumSheetsUploadOnlyLong;

  /// No description provided for @albumSheetsCreateLink.
  ///
  /// In en, this message translates to:
  /// **'Create link'**
  String get albumSheetsCreateLink;

  /// No description provided for @albumSheetsFromAnyDate.
  ///
  /// In en, this message translates to:
  /// **'From any date'**
  String get albumSheetsFromAnyDate;

  /// No description provided for @albumSheetsFrom.
  ///
  /// In en, this message translates to:
  /// **'From {date}'**
  String albumSheetsFrom(String date);

  /// No description provided for @albumSheetsToAnyDate.
  ///
  /// In en, this message translates to:
  /// **'To any date'**
  String get albumSheetsToAnyDate;

  /// No description provided for @albumSheetsTo.
  ///
  /// In en, this message translates to:
  /// **'To {date}'**
  String albumSheetsTo(String date);

  /// No description provided for @albumSheetsKind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get albumSheetsKind;

  /// No description provided for @albumSheetsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get albumSheetsAll;

  /// No description provided for @albumSheetsPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get albumSheetsPhotos;

  /// No description provided for @albumSheetsVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get albumSheetsVideos;

  /// No description provided for @albumSheetsLivePhoto.
  ///
  /// In en, this message translates to:
  /// **'Live Photo'**
  String get albumSheetsLivePhoto;

  /// No description provided for @albumSheetsCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get albumSheetsCamera;

  /// No description provided for @albumSheetsPerson.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get albumSheetsPerson;

  /// No description provided for @albumSheetsTag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get albumSheetsTag;

  /// No description provided for @albumSheetsPlace.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get albumSheetsPlace;

  /// No description provided for @viewerScreenDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this photo?'**
  String get viewerScreenDeleteTitle;

  /// No description provided for @viewerScreenTrashNoDays.
  ///
  /// In en, this message translates to:
  /// **'It moves to the trash, where it can be restored.'**
  String get viewerScreenTrashNoDays;

  /// No description provided for @viewerScreenTrashDays.
  ///
  /// In en, this message translates to:
  /// **'It moves to the trash, where it stays for {days} days and can be restored.'**
  String viewerScreenTrashDays(int days);

  /// No description provided for @viewerScreenCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get viewerScreenCancel;

  /// No description provided for @viewerScreenDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get viewerScreenDelete;

  /// No description provided for @viewerScreenActionFailed.
  ///
  /// In en, this message translates to:
  /// **'The action failed.'**
  String get viewerScreenActionFailed;

  /// No description provided for @viewerScreenNoVideo.
  ///
  /// In en, this message translates to:
  /// **'This photo has no video.'**
  String get viewerScreenNoVideo;

  /// No description provided for @viewerScreenVideoFailed.
  ///
  /// In en, this message translates to:
  /// **'The video could not be loaded.'**
  String get viewerScreenVideoFailed;

  /// No description provided for @viewerScreenStackShots.
  ///
  /// In en, this message translates to:
  /// **'Shots in this stack'**
  String get viewerScreenStackShots;

  /// No description provided for @viewerScreenSlideshow.
  ///
  /// In en, this message translates to:
  /// **'Slideshow'**
  String get viewerScreenSlideshow;

  /// No description provided for @viewerScreen360View.
  ///
  /// In en, this message translates to:
  /// **'360° view'**
  String get viewerScreen360View;

  /// No description provided for @viewerScreenFlatView.
  ///
  /// In en, this message translates to:
  /// **'Flat view'**
  String get viewerScreenFlatView;

  /// No description provided for @viewerScreenPlayLive.
  ///
  /// In en, this message translates to:
  /// **'Play Live Photo'**
  String get viewerScreenPlayLive;

  /// No description provided for @viewerScreenCommentsAndHearts.
  ///
  /// In en, this message translates to:
  /// **'Comments and hearts'**
  String get viewerScreenCommentsAndHearts;

  /// No description provided for @viewerScreenFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get viewerScreenFavorite;

  /// No description provided for @viewerScreenEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get viewerScreenEdit;

  /// No description provided for @viewerScreenShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get viewerScreenShare;

  /// No description provided for @viewerScreenDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get viewerScreenDetails;

  /// No description provided for @viewerScreenPhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'This photo could not be loaded.'**
  String get viewerScreenPhotoFailed;

  /// No description provided for @viewerScreenCannotPlay.
  ///
  /// In en, this message translates to:
  /// **'This video cannot be played on this device.'**
  String get viewerScreenCannotPlay;

  /// No description provided for @viewerScreenDetailsFailed.
  ///
  /// In en, this message translates to:
  /// **'The details could not be loaded.'**
  String get viewerScreenDetailsFailed;

  /// No description provided for @viewerScreenUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get viewerScreenUnavailable;

  /// No description provided for @viewerScreenMissingFile.
  ///
  /// In en, this message translates to:
  /// **'The file was not found on the last scan of the external library. The original is available again once the file is back.'**
  String get viewerScreenMissingFile;

  /// No description provided for @viewerScreenName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get viewerScreenName;

  /// No description provided for @viewerScreenDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get viewerScreenDescription;

  /// No description provided for @viewerScreenTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get viewerScreenTaken;

  /// No description provided for @viewerScreenAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get viewerScreenAdded;

  /// No description provided for @viewerScreenDimensions.
  ///
  /// In en, this message translates to:
  /// **'Dimensions'**
  String get viewerScreenDimensions;

  /// No description provided for @viewerScreenSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get viewerScreenSize;

  /// No description provided for @viewerScreenDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get viewerScreenDuration;

  /// No description provided for @viewerScreenCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get viewerScreenCamera;

  /// No description provided for @viewerScreenLens.
  ///
  /// In en, this message translates to:
  /// **'Lens'**
  String get viewerScreenLens;

  /// No description provided for @viewerScreenSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get viewerScreenSettings;

  /// No description provided for @viewerScreenLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get viewerScreenLocation;

  /// No description provided for @viewerScreenNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Not saved. {reason}'**
  String viewerScreenNotSaved(String reason);

  /// No description provided for @viewerScreenEditDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get viewerScreenEditDetails;

  /// No description provided for @libraryScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryScreenTitle;

  /// No description provided for @libraryScreenExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get libraryScreenExplore;

  /// No description provided for @libraryScreenShared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get libraryScreenShared;

  /// No description provided for @albumScreenActionFailed.
  ///
  /// In en, this message translates to:
  /// **'The action failed. {message}'**
  String albumScreenActionFailed(String message);

  /// No description provided for @albumScreenRemovedAll.
  ///
  /// In en, this message translates to:
  /// **'Removed from the album: {count}'**
  String albumScreenRemovedAll(String count);

  /// No description provided for @albumScreenRemovedSome.
  ///
  /// In en, this message translates to:
  /// **'Removed: {changed} of {total}. You can remove only photos you added yourself.'**
  String albumScreenRemovedSome(String changed, String total);

  /// No description provided for @albumScreenCoverSet.
  ///
  /// In en, this message translates to:
  /// **'The cover is set.'**
  String get albumScreenCoverSet;

  /// No description provided for @albumScreenCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get albumScreenCancel;

  /// No description provided for @albumScreenMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Move the album'**
  String get albumScreenMoveTitle;

  /// No description provided for @albumScreenMoveTop.
  ///
  /// In en, this message translates to:
  /// **'The top, among all albums'**
  String get albumScreenMoveTop;

  /// No description provided for @albumScreenMoved.
  ///
  /// In en, this message translates to:
  /// **'The album was moved.'**
  String get albumScreenMoved;

  /// No description provided for @albumScreenUploadToAlbum.
  ///
  /// In en, this message translates to:
  /// **'Upload to album'**
  String get albumScreenUploadToAlbum;

  /// No description provided for @albumScreenDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this album?'**
  String get albumScreenDeleteTitle;

  /// No description provided for @albumScreenDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The photos stay in the library. Public links stop working.'**
  String get albumScreenDeleteBody;

  /// No description provided for @albumScreenDeleteBodyInside.
  ///
  /// In en, this message translates to:
  /// **'The photos stay in the library. Public links stop working. The albums inside move to the top.'**
  String get albumScreenDeleteBodyInside;

  /// No description provided for @albumScreenDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get albumScreenDelete;

  /// No description provided for @albumScreenLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave this album?'**
  String get albumScreenLeaveTitle;

  /// No description provided for @albumScreenLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'You will no longer see it, unless the owner shares it again.'**
  String get albumScreenLeaveBody;

  /// No description provided for @albumScreenLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get albumScreenLeave;

  /// No description provided for @albumScreenClearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get albumScreenClearSelection;

  /// No description provided for @albumScreenShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get albumScreenShare;

  /// No description provided for @albumScreenSetAsCover.
  ///
  /// In en, this message translates to:
  /// **'Set as cover'**
  String get albumScreenSetAsCover;

  /// No description provided for @albumScreenRemoveFromAlbum.
  ///
  /// In en, this message translates to:
  /// **'Remove from album'**
  String get albumScreenRemoveFromAlbum;

  /// No description provided for @albumScreenSearchInAlbum.
  ///
  /// In en, this message translates to:
  /// **'Search in album'**
  String get albumScreenSearchInAlbum;

  /// No description provided for @albumScreenComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get albumScreenComments;

  /// No description provided for @albumScreenMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get albumScreenMore;

  /// No description provided for @albumScreenSlideshow.
  ///
  /// In en, this message translates to:
  /// **'Slideshow'**
  String get albumScreenSlideshow;

  /// No description provided for @albumScreenAddFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Add from library'**
  String get albumScreenAddFromLibrary;

  /// No description provided for @albumScreenUploadFromPhone.
  ///
  /// In en, this message translates to:
  /// **'Upload from this phone'**
  String get albumScreenUploadFromPhone;

  /// No description provided for @albumScreenAlbumInside.
  ///
  /// In en, this message translates to:
  /// **'Album inside'**
  String get albumScreenAlbumInside;

  /// No description provided for @albumScreenMoveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to…'**
  String get albumScreenMoveTo;

  /// No description provided for @albumScreenShareWithUsers.
  ///
  /// In en, this message translates to:
  /// **'Share with users'**
  String get albumScreenShareWithUsers;

  /// No description provided for @albumScreenPublicLinks.
  ///
  /// In en, this message translates to:
  /// **'Public links'**
  String get albumScreenPublicLinks;

  /// No description provided for @albumScreenEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get albumScreenEdit;

  /// No description provided for @albumScreenNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'This album is not available.'**
  String get albumScreenNotAvailable;

  /// No description provided for @albumScreenNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No photos match the rules.'**
  String get albumScreenNoMatch;

  /// No description provided for @albumScreenEmptyCanAdd.
  ///
  /// In en, this message translates to:
  /// **'This album is empty. Add photos from the menu.'**
  String get albumScreenEmptyCanAdd;

  /// No description provided for @albumScreenEmpty.
  ///
  /// In en, this message translates to:
  /// **'This album is empty.'**
  String get albumScreenEmpty;

  /// No description provided for @albumScreenAlbumsInside.
  ///
  /// In en, this message translates to:
  /// **'Albums inside'**
  String get albumScreenAlbumsInside;

  /// No description provided for @albumScreenNewAlbumInside.
  ///
  /// In en, this message translates to:
  /// **'New album inside'**
  String get albumScreenNewAlbumInside;

  /// No description provided for @albumScreenName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get albumScreenName;

  /// No description provided for @albumScreenCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get albumScreenCreate;

  /// No description provided for @albumScreenAdded.
  ///
  /// In en, this message translates to:
  /// **'Added: {count}'**
  String albumScreenAdded(String count);

  /// No description provided for @albumScreenChoosePhotos.
  ///
  /// In en, this message translates to:
  /// **'Choose photos'**
  String get albumScreenChoosePhotos;

  /// No description provided for @albumScreenAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get albumScreenAdd;

  /// No description provided for @albumScreenNoPhotosYet.
  ///
  /// In en, this message translates to:
  /// **'No photos yet.'**
  String get albumScreenNoPhotosYet;

  /// No description provided for @albumScreenNotSaved.
  ///
  /// In en, this message translates to:
  /// **'The album was not saved.'**
  String get albumScreenNotSaved;

  /// No description provided for @albumScreenEditAlbum.
  ///
  /// In en, this message translates to:
  /// **'Edit album'**
  String get albumScreenEditAlbum;

  /// No description provided for @albumScreenDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get albumScreenDescription;

  /// No description provided for @albumScreenOrder.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get albumScreenOrder;

  /// No description provided for @albumScreenNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get albumScreenNewestFirst;

  /// No description provided for @albumScreenOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get albumScreenOldestFirst;

  /// No description provided for @albumScreenSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get albumScreenSave;

  /// No description provided for @peopleScreensNoName.
  ///
  /// In en, this message translates to:
  /// **'No name'**
  String get peopleScreensNoName;

  /// No description provided for @peopleScreensSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'The search failed. Check the connection.'**
  String get peopleScreensSearchFailed;

  /// No description provided for @peopleScreensDescribe.
  ///
  /// In en, this message translates to:
  /// **'Describe what you are looking for, in English or Croatian, or choose filters.'**
  String get peopleScreensDescribe;

  /// No description provided for @peopleScreensSmartOff.
  ///
  /// In en, this message translates to:
  /// **'Smart search is off or not available, so only text on pictures, file names and filters are searched.'**
  String get peopleScreensSmartOff;

  /// No description provided for @peopleScreensRemoveChip.
  ///
  /// In en, this message translates to:
  /// **'Remove {label}'**
  String peopleScreensRemoveChip(String label);

  /// No description provided for @peopleScreensNothingFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing was found.'**
  String get peopleScreensNothingFound;

  /// No description provided for @peopleScreensSearchHint.
  ///
  /// In en, this message translates to:
  /// **'dog on a beach, Hvar 2024, receipt…'**
  String get peopleScreensSearchHint;

  /// No description provided for @peopleScreensAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get peopleScreensAsk;

  /// No description provided for @peopleScreensFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get peopleScreensFilters;

  /// No description provided for @peopleScreensSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get peopleScreensSearch;

  /// No description provided for @peopleScreensLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'People could not be loaded. Check the connection.'**
  String get peopleScreensLoadFailed;

  /// No description provided for @peopleScreensFacesOff.
  ///
  /// In en, this message translates to:
  /// **'Face recognition is not turned on for this server.'**
  String get peopleScreensFacesOff;

  /// No description provided for @peopleScreensNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No people recognised yet.'**
  String get peopleScreensNoneYet;

  /// No description provided for @peopleScreensPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get peopleScreensPeople;

  /// No description provided for @peopleScreensShowOthers.
  ///
  /// In en, this message translates to:
  /// **'Show the others'**
  String get peopleScreensShowOthers;

  /// No description provided for @peopleScreensHiddenPeople.
  ///
  /// In en, this message translates to:
  /// **'Hidden people'**
  String get peopleScreensHiddenPeople;

  /// No description provided for @peopleScreensName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get peopleScreensName;

  /// No description provided for @peopleScreensDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get peopleScreensDateOfBirth;

  /// No description provided for @peopleScreensMergeWith.
  ///
  /// In en, this message translates to:
  /// **'Merge with…'**
  String get peopleScreensMergeWith;

  /// No description provided for @peopleScreensNobodyElse.
  ///
  /// In en, this message translates to:
  /// **'There is nobody else.'**
  String get peopleScreensNobodyElse;

  /// No description provided for @peopleScreensMerged.
  ///
  /// In en, this message translates to:
  /// **'Merged.'**
  String get peopleScreensMerged;

  /// No description provided for @peopleScreensBorn.
  ///
  /// In en, this message translates to:
  /// **'Born {date}'**
  String peopleScreensBorn(String date);

  /// No description provided for @peopleScreensShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get peopleScreensShow;

  /// No description provided for @peopleScreensHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get peopleScreensHide;

  /// No description provided for @peopleScreensThisLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'This could not be loaded. Check the connection.'**
  String get peopleScreensThisLoadFailed;

  /// No description provided for @adminServerSettingsTrashDaysProblem.
  ///
  /// In en, this message translates to:
  /// **'The trash keeps photos for 1 to 3650 days.'**
  String get adminServerSettingsTrashDaysProblem;

  /// No description provided for @adminServerSettingsImageQualityProblem.
  ///
  /// In en, this message translates to:
  /// **'Image quality must be between 40 and 100.'**
  String get adminServerSettingsImageQualityProblem;

  /// No description provided for @adminServerSettingsPreviewSizeProblem.
  ///
  /// In en, this message translates to:
  /// **'The preview size must be between 720 and 4096.'**
  String get adminServerSettingsPreviewSizeProblem;

  /// No description provided for @adminServerSettingsVideoQualityProblem.
  ///
  /// In en, this message translates to:
  /// **'Video quality must be between 18 and 40, where lower is better.'**
  String get adminServerSettingsVideoQualityProblem;

  /// No description provided for @adminServerSettingsVideoHeightProblem.
  ///
  /// In en, this message translates to:
  /// **'The largest video must be 720, 1080, 1440 or 2160.'**
  String get adminServerSettingsVideoHeightProblem;

  /// No description provided for @adminServerSettingsFaceScoreProblem.
  ///
  /// In en, this message translates to:
  /// **'How sure a face must be is between 0.1 and 1.'**
  String get adminServerSettingsFaceScoreProblem;

  /// No description provided for @adminServerSettingsFaceDistanceProblem.
  ///
  /// In en, this message translates to:
  /// **'How alike two faces must be is between 0.1 and 2.'**
  String get adminServerSettingsFaceDistanceProblem;

  /// No description provided for @adminServerSettingsJobsProblem.
  ///
  /// In en, this message translates to:
  /// **'Background jobs must be between 0 and 64.'**
  String get adminServerSettingsJobsProblem;

  /// No description provided for @adminServerSettingsWorkersProblem.
  ///
  /// In en, this message translates to:
  /// **'Video and analysis jobs must be between 1 and 16.'**
  String get adminServerSettingsWorkersProblem;

  /// No description provided for @adminServerSettingsScanProblem.
  ///
  /// In en, this message translates to:
  /// **'The scan interval must be between 1 and 720 hours.'**
  String get adminServerSettingsScanProblem;

  /// No description provided for @adminServerSettingsMessageProblem.
  ///
  /// In en, this message translates to:
  /// **'The sign-in message is too long.'**
  String get adminServerSettingsMessageProblem;

  /// No description provided for @adminServerSettingsNeedNumbers.
  ///
  /// In en, this message translates to:
  /// **'Every number field needs a number.'**
  String get adminServerSettingsNeedNumbers;

  /// No description provided for @adminServerSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'The settings are saved.'**
  String get adminServerSettingsSaved;

  /// No description provided for @adminServerSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Server settings'**
  String get adminServerSettingsTitle;

  /// No description provided for @adminServerSettingsTrash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get adminServerSettingsTrash;

  /// No description provided for @adminServerSettingsTrashDays.
  ///
  /// In en, this message translates to:
  /// **'Days photos stay in the trash'**
  String get adminServerSettingsTrashDays;

  /// No description provided for @adminServerSettingsRange.
  ///
  /// In en, this message translates to:
  /// **'{low} to {high}'**
  String adminServerSettingsRange(String low, String high);

  /// No description provided for @adminServerSettingsPicturesAndVideos.
  ///
  /// In en, this message translates to:
  /// **'Pictures and videos'**
  String get adminServerSettingsPicturesAndVideos;

  /// No description provided for @adminServerSettingsImageQuality.
  ///
  /// In en, this message translates to:
  /// **'Image quality'**
  String get adminServerSettingsImageQuality;

  /// No description provided for @adminServerSettingsPreviewSize.
  ///
  /// In en, this message translates to:
  /// **'Preview size in pixels'**
  String get adminServerSettingsPreviewSize;

  /// No description provided for @adminServerSettingsVideoQuality.
  ///
  /// In en, this message translates to:
  /// **'Video quality'**
  String get adminServerSettingsVideoQuality;

  /// No description provided for @adminServerSettingsVideoQualityHelp.
  ///
  /// In en, this message translates to:
  /// **'18 to 40, lower is better and larger'**
  String get adminServerSettingsVideoQualityHelp;

  /// No description provided for @adminServerSettingsLargestVideo.
  ///
  /// In en, this message translates to:
  /// **'Largest video'**
  String get adminServerSettingsLargestVideo;

  /// No description provided for @adminServerSettingsFaces.
  ///
  /// In en, this message translates to:
  /// **'Faces'**
  String get adminServerSettingsFaces;

  /// No description provided for @adminServerSettingsFaceScore.
  ///
  /// In en, this message translates to:
  /// **'How sure a face must be'**
  String get adminServerSettingsFaceScore;

  /// No description provided for @adminServerSettingsFaceDistance.
  ///
  /// In en, this message translates to:
  /// **'How alike two faces must be to be one person'**
  String get adminServerSettingsFaceDistance;

  /// No description provided for @adminServerSettingsBackgroundJobs.
  ///
  /// In en, this message translates to:
  /// **'Background jobs'**
  String get adminServerSettingsBackgroundJobs;

  /// No description provided for @adminServerSettingsJobsAtOnce.
  ///
  /// In en, this message translates to:
  /// **'Jobs at once'**
  String get adminServerSettingsJobsAtOnce;

  /// No description provided for @adminServerSettingsJobsAtOnceHelp.
  ///
  /// In en, this message translates to:
  /// **'0 uses WORKER_CONCURRENCY; applies after the worker restarts'**
  String get adminServerSettingsJobsAtOnceHelp;

  /// No description provided for @adminServerSettingsVideosAtOnce.
  ///
  /// In en, this message translates to:
  /// **'Videos at once'**
  String get adminServerSettingsVideosAtOnce;

  /// No description provided for @adminServerSettingsWorkersHelp.
  ///
  /// In en, this message translates to:
  /// **'1 to 16; applies after the worker restarts'**
  String get adminServerSettingsWorkersHelp;

  /// No description provided for @adminServerSettingsAnalysesAtOnce.
  ///
  /// In en, this message translates to:
  /// **'Analyses at once'**
  String get adminServerSettingsAnalysesAtOnce;

  /// No description provided for @adminServerSettingsScanHours.
  ///
  /// In en, this message translates to:
  /// **'Scan external folders every … hours'**
  String get adminServerSettingsScanHours;

  /// No description provided for @adminServerSettingsSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in'**
  String get adminServerSettingsSigningIn;

  /// No description provided for @adminServerSettingsPasswordLogin.
  ///
  /// In en, this message translates to:
  /// **'Allow signing in with a password'**
  String get adminServerSettingsPasswordLogin;

  /// No description provided for @adminServerSettingsMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance mode'**
  String get adminServerSettingsMaintenance;

  /// No description provided for @adminServerSettingsMaintenanceHelp.
  ///
  /// In en, this message translates to:
  /// **'Only administrators can use the server'**
  String get adminServerSettingsMaintenanceHelp;

  /// No description provided for @adminServerSettingsVisibleOnNetwork.
  ///
  /// In en, this message translates to:
  /// **'Apps on the same network can find this server'**
  String get adminServerSettingsVisibleOnNetwork;

  /// No description provided for @adminServerSettingsVisibleOnNetworkHelp.
  ///
  /// In en, this message translates to:
  /// **'Signing in still needs an account.'**
  String get adminServerSettingsVisibleOnNetworkHelp;

  /// No description provided for @adminServerSettingsServerName.
  ///
  /// In en, this message translates to:
  /// **'The server\'s name'**
  String get adminServerSettingsServerName;

  /// No description provided for @adminServerSettingsLoginMessage.
  ///
  /// In en, this message translates to:
  /// **'Message on the sign-in page'**
  String get adminServerSettingsLoginMessage;

  /// No description provided for @adminOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get adminOverviewTitle;

  /// No description provided for @adminOverviewLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get adminOverviewLibrary;

  /// No description provided for @adminOverviewUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminOverviewUsers;

  /// No description provided for @adminOverviewPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get adminOverviewPhotos;

  /// No description provided for @adminOverviewVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get adminOverviewVideos;

  /// No description provided for @adminOverviewProcessing.
  ///
  /// In en, this message translates to:
  /// **'Being processed'**
  String get adminOverviewProcessing;

  /// No description provided for @adminOverviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get adminOverviewFailed;

  /// No description provided for @adminOverviewLibrarySize.
  ///
  /// In en, this message translates to:
  /// **'Library size'**
  String get adminOverviewLibrarySize;

  /// No description provided for @adminOverviewDisk.
  ///
  /// In en, this message translates to:
  /// **'Disk'**
  String get adminOverviewDisk;

  /// No description provided for @adminOverviewFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get adminOverviewFree;

  /// No description provided for @adminOverviewTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get adminOverviewTotal;

  /// No description provided for @adminOverviewJobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get adminOverviewJobs;

  /// No description provided for @adminOverviewWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get adminOverviewWaiting;

  /// No description provided for @adminOverviewRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get adminOverviewRunning;

  /// No description provided for @adminOverviewDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get adminOverviewDone;

  /// No description provided for @adminOverviewServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get adminOverviewServices;

  /// No description provided for @adminOverviewWorker.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get adminOverviewWorker;

  /// No description provided for @adminOverviewNotRunning.
  ///
  /// In en, this message translates to:
  /// **'Not running'**
  String get adminOverviewNotRunning;

  /// No description provided for @adminOverviewAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis (ML)'**
  String get adminOverviewAnalysis;

  /// No description provided for @adminOverviewTurnedOff.
  ///
  /// In en, this message translates to:
  /// **'Turned off'**
  String get adminOverviewTurnedOff;

  /// No description provided for @adminOverviewDatabaseSize.
  ///
  /// In en, this message translates to:
  /// **'Database size'**
  String get adminOverviewDatabaseSize;

  /// No description provided for @adminOverviewVersions.
  ///
  /// In en, this message translates to:
  /// **'Versions'**
  String get adminOverviewVersions;

  /// No description provided for @adminOverviewDatabase.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get adminOverviewDatabase;

  /// No description provided for @adminJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get adminJobsTitle;

  /// No description provided for @adminJobsQueues.
  ///
  /// In en, this message translates to:
  /// **'Queues'**
  String get adminJobsQueues;

  /// No description provided for @adminJobsQueueState.
  ///
  /// In en, this message translates to:
  /// **'{queued} waiting · {running} running'**
  String adminJobsQueueState(String queued, String running);

  /// No description provided for @adminJobsQueueStatePaused.
  ///
  /// In en, this message translates to:
  /// **'{queued} waiting · {running} running · paused'**
  String adminJobsQueueStatePaused(String queued, String running);

  /// No description provided for @adminJobsContinues.
  ///
  /// In en, this message translates to:
  /// **'{name} continues.'**
  String adminJobsContinues(String name);

  /// No description provided for @adminJobsIsPaused.
  ///
  /// In en, this message translates to:
  /// **'{name} is paused.'**
  String adminJobsIsPaused(String name);

  /// No description provided for @adminJobsResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get adminJobsResume;

  /// No description provided for @adminJobsPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get adminJobsPause;

  /// No description provided for @adminJobsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get adminJobsFailed;

  /// No description provided for @adminJobsNoneFailed.
  ///
  /// In en, this message translates to:
  /// **'No job has failed.'**
  String get adminJobsNoneFailed;

  /// No description provided for @adminJobsQueuedAgain.
  ///
  /// In en, this message translates to:
  /// **'The job is queued again.'**
  String get adminJobsQueuedAgain;

  /// No description provided for @adminJobsTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get adminJobsTryAgain;

  /// No description provided for @freeSpaceScreenServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'The server could not be asked, so nothing is offered for removal.'**
  String get freeSpaceScreenServerUnreachable;

  /// No description provided for @freeSpaceScreenBackupUnreadable.
  ///
  /// In en, this message translates to:
  /// **'The backup state could not be read.'**
  String get freeSpaceScreenBackupUnreadable;

  /// No description provided for @freeSpaceScreenRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {count} from this phone?'**
  String freeSpaceScreenRemoveTitle(String count);

  /// No description provided for @freeSpaceScreenRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'They stay on your server. iPhone asks once more, and keeps them for 30 days in Recently Deleted.'**
  String get freeSpaceScreenRemoveBody;

  /// No description provided for @freeSpaceScreenCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get freeSpaceScreenCancel;

  /// No description provided for @freeSpaceScreenRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get freeSpaceScreenRemove;

  /// No description provided for @freeSpaceScreenNotRemoved.
  ///
  /// In en, this message translates to:
  /// **'The photos could not be removed.'**
  String get freeSpaceScreenNotRemoved;

  /// No description provided for @freeSpaceScreenNothingToRemove.
  ///
  /// In en, this message translates to:
  /// **'Nothing to remove. Only photos sent by the automatic backup are offered here.'**
  String get freeSpaceScreenNothingToRemove;

  /// No description provided for @freeSpaceScreenSafe.
  ///
  /// In en, this message translates to:
  /// **'{count} are safely on your server, as it just confirmed by their checksums.'**
  String freeSpaceScreenSafe(String count);

  /// No description provided for @freeSpaceScreenRemoveButton.
  ///
  /// In en, this message translates to:
  /// **'Remove {count} from this phone'**
  String freeSpaceScreenRemoveButton(String count);

  /// No description provided for @freeSpaceScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Free up space'**
  String get freeSpaceScreenTitle;

  /// No description provided for @freeSpaceScreenWhatToKeep.
  ///
  /// In en, this message translates to:
  /// **'What to keep'**
  String get freeSpaceScreenWhatToKeep;

  /// No description provided for @freeSpaceScreenAnyAge.
  ///
  /// In en, this message translates to:
  /// **'Any age'**
  String get freeSpaceScreenAnyAge;

  /// No description provided for @freeSpaceScreenOlderThanMonth.
  ///
  /// In en, this message translates to:
  /// **'Older than a month'**
  String get freeSpaceScreenOlderThanMonth;

  /// No description provided for @freeSpaceScreenOlderThan3Months.
  ///
  /// In en, this message translates to:
  /// **'Older than 3 months'**
  String get freeSpaceScreenOlderThan3Months;

  /// No description provided for @freeSpaceScreenOlderThanYear.
  ///
  /// In en, this message translates to:
  /// **'Older than a year'**
  String get freeSpaceScreenOlderThanYear;

  /// No description provided for @freeSpaceScreenRemoveOnly.
  ///
  /// In en, this message translates to:
  /// **'Remove only'**
  String get freeSpaceScreenRemoveOnly;

  /// No description provided for @freeSpaceScreenKeepFavorites.
  ///
  /// In en, this message translates to:
  /// **'Keep favorites'**
  String get freeSpaceScreenKeepFavorites;

  /// No description provided for @freeSpaceScreenKeepPhotos.
  ///
  /// In en, this message translates to:
  /// **'Keep all photos'**
  String get freeSpaceScreenKeepPhotos;

  /// No description provided for @freeSpaceScreenKeepVideos.
  ///
  /// In en, this message translates to:
  /// **'Keep all videos'**
  String get freeSpaceScreenKeepVideos;

  /// No description provided for @freeSpaceScreenKeepAlbums.
  ///
  /// In en, this message translates to:
  /// **'Keep these albums on the phone'**
  String get freeSpaceScreenKeepAlbums;

  /// No description provided for @apiKeysScreenRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get apiKeysScreenRead;

  /// No description provided for @apiKeysScreenUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get apiKeysScreenUpload;

  /// No description provided for @apiKeysScreenChangeAndDelete.
  ///
  /// In en, this message translates to:
  /// **'Change and delete'**
  String get apiKeysScreenChangeAndDelete;

  /// No description provided for @apiKeysScreenExpires.
  ///
  /// In en, this message translates to:
  /// **'{rights} · expires {date}'**
  String apiKeysScreenExpires(String rights, String date);

  /// No description provided for @apiKeysScreenNewKey.
  ///
  /// In en, this message translates to:
  /// **'New key'**
  String get apiKeysScreenNewKey;

  /// No description provided for @apiKeysScreenKeyName.
  ///
  /// In en, this message translates to:
  /// **'Key name'**
  String get apiKeysScreenKeyName;

  /// No description provided for @apiKeysScreenCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get apiKeysScreenCancel;

  /// No description provided for @apiKeysScreenCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get apiKeysScreenCreate;

  /// No description provided for @apiKeysScreenCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'The key could not be created. {message}'**
  String apiKeysScreenCreateFailed(String message);

  /// No description provided for @apiKeysScreenSaveItNow.
  ///
  /// In en, this message translates to:
  /// **'Save it now'**
  String get apiKeysScreenSaveItNow;

  /// No description provided for @apiKeysScreenCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get apiKeysScreenCopy;

  /// No description provided for @apiKeysScreenDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get apiKeysScreenDone;

  /// No description provided for @apiKeysScreenRevokeFailed.
  ///
  /// In en, this message translates to:
  /// **'The key could not be revoked.'**
  String get apiKeysScreenRevokeFailed;

  /// No description provided for @apiKeysScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'API keys'**
  String get apiKeysScreenTitle;

  /// No description provided for @apiKeysScreenLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The keys could not be loaded.'**
  String get apiKeysScreenLoadFailed;

  /// No description provided for @apiKeysScreenEmpty.
  ///
  /// In en, this message translates to:
  /// **'No keys yet. A key gives a program only the chosen rights.'**
  String get apiKeysScreenEmpty;

  /// No description provided for @apiKeysScreenRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get apiKeysScreenRevoke;

  /// No description provided for @memoriesScreenLastWeek.
  ///
  /// In en, this message translates to:
  /// **'The last week'**
  String get memoriesScreenLastWeek;

  /// No description provided for @memoriesScreenOnThisDay.
  ///
  /// In en, this message translates to:
  /// **'{years, plural, =1{On this day, 1 year ago} other{On this day, {years} years ago}}'**
  String memoriesScreenOnThisDay(int years);

  /// No description provided for @memoriesScreenLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Memories could not be loaded. Check the connection.'**
  String get memoriesScreenLoadFailed;

  /// No description provided for @memoriesScreenTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get memoriesScreenTryAgain;

  /// No description provided for @memoriesScreenNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No memories yet.'**
  String get memoriesScreenNoneYet;

  /// No description provided for @memoriesScreenItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String memoriesScreenItems(int count);

  /// No description provided for @memoriesScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Memories'**
  String get memoriesScreenTitle;

  /// No description provided for @memoriesScreenVideoFailed.
  ///
  /// In en, this message translates to:
  /// **'The video could not be made.'**
  String get memoriesScreenVideoFailed;

  /// No description provided for @memoriesScreenVideoSaved.
  ///
  /// In en, this message translates to:
  /// **'The video is saved in your Photos.'**
  String get memoriesScreenVideoSaved;

  /// No description provided for @memoriesScreenVideoNotSaved.
  ///
  /// In en, this message translates to:
  /// **'The video could not be saved.'**
  String get memoriesScreenVideoNotSaved;

  /// No description provided for @memoriesScreenMakeVideo.
  ///
  /// In en, this message translates to:
  /// **'Make a video'**
  String get memoriesScreenMakeVideo;

  /// No description provided for @layoutJanuary.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get layoutJanuary;

  /// No description provided for @layoutJanuaryOf.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get layoutJanuaryOf;

  /// No description provided for @layoutFebruary.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get layoutFebruary;

  /// No description provided for @layoutFebruaryOf.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get layoutFebruaryOf;

  /// No description provided for @layoutMarch.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get layoutMarch;

  /// No description provided for @layoutMarchOf.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get layoutMarchOf;

  /// No description provided for @layoutApril.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get layoutApril;

  /// No description provided for @layoutAprilOf.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get layoutAprilOf;

  /// No description provided for @layoutMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get layoutMay;

  /// No description provided for @layoutMayOf.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get layoutMayOf;

  /// No description provided for @layoutJune.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get layoutJune;

  /// No description provided for @layoutJuneOf.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get layoutJuneOf;

  /// No description provided for @layoutJuly.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get layoutJuly;

  /// No description provided for @layoutJulyOf.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get layoutJulyOf;

  /// No description provided for @layoutAugust.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get layoutAugust;

  /// No description provided for @layoutAugustOf.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get layoutAugustOf;

  /// No description provided for @layoutSeptember.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get layoutSeptember;

  /// No description provided for @layoutSeptemberOf.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get layoutSeptemberOf;

  /// No description provided for @layoutOctober.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get layoutOctober;

  /// No description provided for @layoutOctoberOf.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get layoutOctoberOf;

  /// No description provided for @layoutNovember.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get layoutNovember;

  /// No description provided for @layoutNovemberOf.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get layoutNovemberOf;

  /// No description provided for @layoutDecember.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get layoutDecember;

  /// No description provided for @layoutDecemberOf.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get layoutDecemberOf;

  /// No description provided for @layoutWeekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get layoutWeekdayMon;

  /// No description provided for @layoutWeekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get layoutWeekdayTue;

  /// No description provided for @layoutWeekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get layoutWeekdayWed;

  /// No description provided for @layoutWeekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get layoutWeekdayThu;

  /// No description provided for @layoutWeekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get layoutWeekdayFri;

  /// No description provided for @layoutWeekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get layoutWeekdaySat;

  /// No description provided for @layoutWeekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get layoutWeekdaySun;

  /// No description provided for @layoutMonthYear.
  ///
  /// In en, this message translates to:
  /// **'{month} {year}'**
  String layoutMonthYear(String month, String year);

  /// No description provided for @layoutDayLabel.
  ///
  /// In en, this message translates to:
  /// **'{weekday} {day} {month}'**
  String layoutDayLabel(String weekday, String day, String month);

  /// No description provided for @layoutDateTime.
  ///
  /// In en, this message translates to:
  /// **'{day} {month} {year}, {hour}:{minute}'**
  String layoutDateTime(
    String day,
    String month,
    String year,
    String hour,
    String minute,
  );

  /// No description provided for @linkPrivacyHideFaces.
  ///
  /// In en, this message translates to:
  /// **'Hide faces'**
  String get linkPrivacyHideFaces;

  /// No description provided for @linkPrivacyFacesNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get linkPrivacyFacesNone;

  /// No description provided for @linkPrivacyFacesAll.
  ///
  /// In en, this message translates to:
  /// **'All faces'**
  String get linkPrivacyFacesAll;

  /// No description provided for @linkPrivacyFacesExcept.
  ///
  /// In en, this message translates to:
  /// **'All but chosen people'**
  String get linkPrivacyFacesExcept;

  /// No description provided for @linkPrivacyChoosePeople.
  ///
  /// In en, this message translates to:
  /// **'The faces of these people stay visible:'**
  String get linkPrivacyChoosePeople;

  /// No description provided for @linkPrivacyNoPeople.
  ///
  /// In en, this message translates to:
  /// **'Nobody has a name yet. Name people under People first.'**
  String get linkPrivacyNoPeople;

  /// No description provided for @linkPrivacyPeopleFailed.
  ///
  /// In en, this message translates to:
  /// **'People could not be loaded.'**
  String get linkPrivacyPeopleFailed;

  /// No description provided for @linkPrivacyUnrecognized.
  ///
  /// In en, this message translates to:
  /// **'A face that was not recognized is not blurred.'**
  String get linkPrivacyUnrecognized;

  /// No description provided for @linkPrivacyUnchecked.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} photos have not been checked for faces yet, so nothing in them is blurred.'**
  String linkPrivacyUnchecked(String count, String total);

  /// No description provided for @linkPrivacyAllChecked.
  ///
  /// In en, this message translates to:
  /// **'Every photo in the album has been checked for faces.'**
  String get linkPrivacyAllChecked;

  /// No description provided for @linkPrivacyVideosStill.
  ///
  /// In en, this message translates to:
  /// **'Videos ({count}) are shown only as a still, with faces blurred.'**
  String linkPrivacyVideosStill(String count);

  /// No description provided for @linkPrivacyNoOriginals.
  ///
  /// In en, this message translates to:
  /// **'Visitors get a blurred copy at full size, never the original.'**
  String get linkPrivacyNoOriginals;

  /// No description provided for @linkPrivacyRemoveCamera.
  ///
  /// In en, this message translates to:
  /// **'Remove camera details'**
  String get linkPrivacyRemoveCamera;

  /// No description provided for @linkPrivacyRemoveCameraDetail.
  ///
  /// In en, this message translates to:
  /// **'Downloads carry no camera, lens, serial numbers, author or software.'**
  String get linkPrivacyRemoveCameraDetail;

  /// No description provided for @linkPrivacyRemoveDate.
  ///
  /// In en, this message translates to:
  /// **'Remove the date too'**
  String get linkPrivacyRemoveDate;

  /// No description provided for @linkPrivacyAskName.
  ///
  /// In en, this message translates to:
  /// **'Ask for a name'**
  String get linkPrivacyAskName;

  /// No description provided for @linkPrivacyAskNameDetail.
  ///
  /// In en, this message translates to:
  /// **'Visitors type their name before they see the album.'**
  String get linkPrivacyAskNameDetail;

  /// No description provided for @linkPrivacyNotOpened.
  ///
  /// In en, this message translates to:
  /// **'Not opened yet'**
  String get linkPrivacyNotOpened;

  /// No description provided for @linkPrivacyOpened.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Opened once} other{Opened {count} times}} · last {when}'**
  String linkPrivacyOpened(int count, String when);

  /// No description provided for @linkPrivacyWhoOpened.
  ///
  /// In en, this message translates to:
  /// **'Who opened it'**
  String get linkPrivacyWhoOpened;

  /// No description provided for @linkPrivacyNoVisits.
  ///
  /// In en, this message translates to:
  /// **'Nobody has opened this link yet.'**
  String get linkPrivacyNoVisits;

  /// No description provided for @linkPrivacyVisitsFailed.
  ///
  /// In en, this message translates to:
  /// **'The visits could not be loaded.'**
  String get linkPrivacyVisitsFailed;

  /// No description provided for @linkPrivacyUnknownPlace.
  ///
  /// In en, this message translates to:
  /// **'Unknown place'**
  String get linkPrivacyUnknownPlace;

  /// No description provided for @linkPrivacyNoName.
  ///
  /// In en, this message translates to:
  /// **'No name given'**
  String get linkPrivacyNoName;

  /// No description provided for @linkPrivacyViewed.
  ///
  /// In en, this message translates to:
  /// **'{count} viewed'**
  String linkPrivacyViewed(String count);

  /// No description provided for @linkPrivacyDownloaded.
  ///
  /// In en, this message translates to:
  /// **'{count} downloaded'**
  String linkPrivacyDownloaded(String count);

  /// No description provided for @linkPrivacyAttribution.
  ///
  /// In en, this message translates to:
  /// **'Places by DB-IP (db-ip.com), CC BY 4.0. Visits are kept 90 days.'**
  String get linkPrivacyAttribution;

  /// No description provided for @sharePrivacyRemoveLocation.
  ///
  /// In en, this message translates to:
  /// **'Remove location'**
  String get sharePrivacyRemoveLocation;

  /// No description provided for @sharePrivacyRemoveCamera.
  ///
  /// In en, this message translates to:
  /// **'Remove camera details'**
  String get sharePrivacyRemoveCamera;

  /// No description provided for @sharePrivacyHideFaces.
  ///
  /// In en, this message translates to:
  /// **'Hide faces'**
  String get sharePrivacyHideFaces;

  /// No description provided for @sharePrivacyHideFacesDetail.
  ///
  /// In en, this message translates to:
  /// **'Photos go as a blurred copy. Videos are left out.'**
  String get sharePrivacyHideFacesDetail;

  /// No description provided for @sharePrivacyVideosLeftOut.
  ///
  /// In en, this message translates to:
  /// **'Videos were left out: their faces cannot be hidden.'**
  String get sharePrivacyVideosLeftOut;

  /// No description provided for @notificationsLinkOpened.
  ///
  /// In en, this message translates to:
  /// **'Your link “{subject}” was opened for the first time.'**
  String notificationsLinkOpened(String subject);

  /// No description provided for @cullTitle.
  ///
  /// In en, this message translates to:
  /// **'Cull'**
  String get cullTitle;

  /// No description provided for @cullMark.
  ///
  /// In en, this message translates to:
  /// **'Mark'**
  String get cullMark;

  /// No description provided for @cullPick.
  ///
  /// In en, this message translates to:
  /// **'Pick'**
  String get cullPick;

  /// No description provided for @cullReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get cullReject;

  /// No description provided for @cullNoMark.
  ///
  /// In en, this message translates to:
  /// **'No mark'**
  String get cullNoMark;

  /// No description provided for @cullPicks.
  ///
  /// In en, this message translates to:
  /// **'Picks'**
  String get cullPicks;

  /// No description provided for @cullRejects.
  ///
  /// In en, this message translates to:
  /// **'Rejects'**
  String get cullRejects;

  /// No description provided for @cullUnmarked.
  ///
  /// In en, this message translates to:
  /// **'Unmarked'**
  String get cullUnmarked;

  /// No description provided for @cullAddToCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get cullAddToCompare;

  /// No description provided for @cullRemoveFromCompare.
  ///
  /// In en, this message translates to:
  /// **'Take out of comparison'**
  String get cullRemoveFromCompare;

  /// No description provided for @cullStopComparing.
  ///
  /// In en, this message translates to:
  /// **'End comparison'**
  String get cullStopComparing;

  /// No description provided for @cullPicksToAlbum.
  ///
  /// In en, this message translates to:
  /// **'Picks to new album'**
  String get cullPicksToAlbum;

  /// No description provided for @cullRejectsToTrash.
  ///
  /// In en, this message translates to:
  /// **'Rejects to trash'**
  String get cullRejectsToTrash;

  /// No description provided for @cullNothing.
  ///
  /// In en, this message translates to:
  /// **'There are no photos of yours to go through here.'**
  String get cullNothing;

  /// No description provided for @cullNoneWithMark.
  ///
  /// In en, this message translates to:
  /// **'No photos have this mark.'**
  String get cullNoneWithMark;

  /// No description provided for @cullNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Not saved'**
  String get cullNotSaved;

  /// No description provided for @cullActionFailed.
  ///
  /// In en, this message translates to:
  /// **'The action failed'**
  String get cullActionFailed;

  /// No description provided for @cullLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The marks could not be loaded.'**
  String get cullLoadFailed;

  /// No description provided for @cullAlbumName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get cullAlbumName;

  /// No description provided for @cullCreateAlbum.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get cullCreateAlbum;

  /// No description provided for @cullTally.
  ///
  /// In en, this message translates to:
  /// **'{picks} picked · {rejects} rejected'**
  String cullTally(int picks, int rejects);

  /// No description provided for @cullConfirmTrash.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 rejected photo moves to the trash and can be restored.} other{{count} rejected photos move to the trash and can be restored.}}'**
  String cullConfirmTrash(int count);

  /// No description provided for @cullMovedToTrash.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo moved to the trash} other{{count} photos moved to the trash}}'**
  String cullMovedToTrash(int count);

  /// No description provided for @cullAlbumMade.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo is in the album {title}} other{{count} photos are in the album {title}}}'**
  String cullAlbumMade(int count, String title);

  /// No description provided for @cullAlbumWillHold.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The album will hold 1 picked photo.} other{The album will hold {count} picked photos.}}'**
  String cullAlbumWillHold(int count);

  /// No description provided for @adminMlTitle.
  ///
  /// In en, this message translates to:
  /// **'Analysis service'**
  String get adminMlTitle;

  /// No description provided for @adminMlConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get adminMlConnected;

  /// No description provided for @adminMlLoaded.
  ///
  /// In en, this message translates to:
  /// **'Loaded models'**
  String get adminMlLoaded;

  /// No description provided for @adminMlMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get adminMlMemory;

  /// No description provided for @adminMlAcceleration.
  ///
  /// In en, this message translates to:
  /// **'Acceleration'**
  String get adminMlAcceleration;

  /// No description provided for @adminMlNoneLoaded.
  ///
  /// In en, this message translates to:
  /// **'None right now'**
  String get adminMlNoneLoaded;

  /// No description provided for @adminMlState.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get adminMlState;

  /// No description provided for @adminMlUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Cannot be reached. Analysis waits and continues when it is back; until then search uses words on pictures and file names.'**
  String get adminMlUnreachable;

  /// No description provided for @adminMlWrongToken.
  ///
  /// In en, this message translates to:
  /// **'The service refused the token. ML_TOKEN must be the same in .env here and on the computer that runs it.'**
  String get adminMlWrongToken;

  /// No description provided for @memoriesTripTitle.
  ///
  /// In en, this message translates to:
  /// **'{place}, {monthName} {year}'**
  String memoriesTripTitle(String place, String monthName, String year);

  /// No description provided for @memoriesMonth1.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get memoriesMonth1;

  /// No description provided for @memoriesMonth2.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get memoriesMonth2;

  /// No description provided for @memoriesMonth3.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get memoriesMonth3;

  /// No description provided for @memoriesMonth4.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get memoriesMonth4;

  /// No description provided for @memoriesMonth5.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get memoriesMonth5;

  /// No description provided for @memoriesMonth6.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get memoriesMonth6;

  /// No description provided for @memoriesMonth7.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get memoriesMonth7;

  /// No description provided for @memoriesMonth8.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get memoriesMonth8;

  /// No description provided for @memoriesMonth9.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get memoriesMonth9;

  /// No description provided for @memoriesMonth10.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get memoriesMonth10;

  /// No description provided for @memoriesMonth11.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get memoriesMonth11;

  /// No description provided for @memoriesMonth12.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get memoriesMonth12;

  /// No description provided for @memoriesPersonYears.
  ///
  /// In en, this message translates to:
  /// **'{person} through the years'**
  String memoriesPersonYears(String person);

  /// No description provided for @memoriesBirthday.
  ///
  /// In en, this message translates to:
  /// **'{person}\'s birthday'**
  String memoriesBirthday(String person);

  /// No description provided for @memoriesYearReview.
  ///
  /// In en, this message translates to:
  /// **'{year} in photos'**
  String memoriesYearReview(String year);

  /// No description provided for @memoriesMonthAgo.
  ///
  /// In en, this message translates to:
  /// **'A month ago'**
  String get memoriesMonthAgo;

  /// No description provided for @memoriesHidden.
  ///
  /// In en, this message translates to:
  /// **'This memory is hidden.'**
  String get memoriesHidden;

  /// No description provided for @memoriesPersonHidden.
  ///
  /// In en, this message translates to:
  /// **'This person will no longer appear in memories.'**
  String get memoriesPersonHidden;

  /// No description provided for @memoriesHideThis.
  ///
  /// In en, this message translates to:
  /// **'Hide this memory'**
  String get memoriesHideThis;

  /// No description provided for @memoriesHidePerson.
  ///
  /// In en, this message translates to:
  /// **'Don\'t show this person'**
  String get memoriesHidePerson;

  /// No description provided for @memoriesMenuMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get memoriesMenuMore;

  /// No description provided for @settingsScreenMemoryKinds.
  ///
  /// In en, this message translates to:
  /// **'Kinds of memories'**
  String get settingsScreenMemoryKinds;

  /// No description provided for @settingsScreenMemoryOnThisDay.
  ///
  /// In en, this message translates to:
  /// **'On this day'**
  String get settingsScreenMemoryOnThisDay;

  /// No description provided for @settingsScreenMemoryWeek.
  ///
  /// In en, this message translates to:
  /// **'The last week'**
  String get settingsScreenMemoryWeek;

  /// No description provided for @settingsScreenMemoryTrip.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get settingsScreenMemoryTrip;

  /// No description provided for @settingsScreenMemoryPersonYears.
  ///
  /// In en, this message translates to:
  /// **'A person through the years'**
  String get settingsScreenMemoryPersonYears;

  /// No description provided for @settingsScreenMemoryBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthdays'**
  String get settingsScreenMemoryBirthday;

  /// No description provided for @settingsScreenMemoryYearReview.
  ///
  /// In en, this message translates to:
  /// **'A year in photos'**
  String get settingsScreenMemoryYearReview;

  /// No description provided for @settingsScreenMemoryMonthAgo.
  ///
  /// In en, this message translates to:
  /// **'A month ago'**
  String get settingsScreenMemoryMonthAgo;

  /// No description provided for @settingsScreenHiddenFromMemories.
  ///
  /// In en, this message translates to:
  /// **'Hidden from memories'**
  String get settingsScreenHiddenFromMemories;

  /// No description provided for @settingsScreenNothingHidden.
  ///
  /// In en, this message translates to:
  /// **'Nothing is hidden.'**
  String get settingsScreenNothingHidden;

  /// No description provided for @settingsScreenShowAgain.
  ///
  /// In en, this message translates to:
  /// **'Show again'**
  String get settingsScreenShowAgain;

  /// No description provided for @settingsScreenHiddenMemoryCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 memory is hidden} other{{count} memories are hidden}}'**
  String settingsScreenHiddenMemoryCount(int count);

  /// No description provided for @settingsScreenShowAllAgain.
  ///
  /// In en, this message translates to:
  /// **'Show all again'**
  String get settingsScreenShowAllAgain;

  /// No description provided for @accountSheetExport.
  ///
  /// In en, this message translates to:
  /// **'Export my library'**
  String get accountSheetExport;

  /// No description provided for @adminScreenExports.
  ///
  /// In en, this message translates to:
  /// **'Library exports'**
  String get adminScreenExports;

  /// No description provided for @adminScreenExportsHint.
  ///
  /// In en, this message translates to:
  /// **'Follow, cancel and download exports'**
  String get adminScreenExportsHint;

  /// No description provided for @adminUsersExportTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export the library of {email}'**
  String adminUsersExportTooltip(String email);

  /// No description provided for @adminUsersExportStarted.
  ///
  /// In en, this message translates to:
  /// **'The export of {email}\'s library has started.'**
  String adminUsersExportStarted(String email);

  /// No description provided for @exportsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportsScreenTitle;

  /// No description provided for @exportsScreenAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Library exports'**
  String get exportsScreenAllTitle;

  /// No description provided for @exportsScreenWhatIsIn.
  ///
  /// In en, this message translates to:
  /// **'Take your whole library with you: ZIP files of up to 10 GB with every original as uploaded, its XMP sidecar, a folder for each album and one JSON file with dates, places, descriptions, ratings, favourites, tags, people and edits. Passwords and keys are never in it. It is made on the server, goes on after a restart, and can be downloaded for 7 days.'**
  String get exportsScreenWhatIsIn;

  /// No description provided for @exportsScreenAdminHint.
  ///
  /// In en, this message translates to:
  /// **'An export you start for someone appears in their own list as well. You and they can download it; other administrators only follow it.'**
  String get exportsScreenAdminHint;

  /// No description provided for @exportsScreenStart.
  ///
  /// In en, this message translates to:
  /// **'Export my library'**
  String get exportsScreenStart;

  /// No description provided for @exportsScreenStarted.
  ///
  /// In en, this message translates to:
  /// **'The export has started.'**
  String get exportsScreenStarted;

  /// No description provided for @exportsScreenNothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been exported yet.'**
  String get exportsScreenNothingYet;

  /// No description provided for @exportsScreenNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'The exports could not be loaded.'**
  String get exportsScreenNotLoaded;

  /// No description provided for @exportsScreenRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get exportsScreenRunning;

  /// No description provided for @exportsScreenReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get exportsScreenReady;

  /// No description provided for @exportsScreenFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get exportsScreenFailed;

  /// No description provided for @exportsScreenCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get exportsScreenCancelled;

  /// No description provided for @exportsScreenRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed after 7 days'**
  String get exportsScreenRemoved;

  /// No description provided for @exportsScreenProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total, plural, =1{1 file} other{{total} files}} · {doneBytes} of {totalBytes}'**
  String exportsScreenProgress(
    int done,
    int total,
    String doneBytes,
    String totalBytes,
  );

  /// No description provided for @exportsScreenStartedBy.
  ///
  /// In en, this message translates to:
  /// **'Started by {name}'**
  String exportsScreenStartedBy(String name);

  /// No description provided for @exportsScreenMissing.
  ///
  /// In en, this message translates to:
  /// **'Not on the disk, so only listed: {count, plural, =1{1 file} other{{count} files}}'**
  String exportsScreenMissing(int count);

  /// No description provided for @exportsScreenKeptUntil.
  ///
  /// In en, this message translates to:
  /// **'Can be downloaded until {date}.'**
  String exportsScreenKeptUntil(String date);

  /// No description provided for @exportsScreenOnlyOwner.
  ///
  /// In en, this message translates to:
  /// **'Only the owner of the library, or the administrator who started the export, downloads it.'**
  String get exportsScreenOnlyOwner;

  /// No description provided for @exportsScreenCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get exportsScreenCancel;

  /// No description provided for @exportsScreenRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get exportsScreenRemove;

  /// No description provided for @exportsScreenPart.
  ///
  /// In en, this message translates to:
  /// **'Part {number}'**
  String exportsScreenPart(int number);

  /// No description provided for @exportsScreenFiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String exportsScreenFiles(int count);

  /// No description provided for @exportsScreenDownloadPart.
  ///
  /// In en, this message translates to:
  /// **'Download part {number}'**
  String exportsScreenDownloadPart(int number);

  /// No description provided for @exportsScreenDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'The part could not be downloaded. Try again to go on from where it stopped.'**
  String get exportsScreenDownloadFailed;

  /// No description provided for @exportsScreenNoSpace.
  ///
  /// In en, this message translates to:
  /// **'There is not enough free space on the server for this export. Free up space, or ask the administrator.'**
  String get exportsScreenNoSpace;

  /// No description provided for @exportsScreenAlreadyRunning.
  ///
  /// In en, this message translates to:
  /// **'An export of this library is already running.'**
  String get exportsScreenAlreadyRunning;

  /// No description provided for @viewerScreenPlayOnTv.
  ///
  /// In en, this message translates to:
  /// **'Play on TV'**
  String get viewerScreenPlayOnTv;

  /// No description provided for @viewerScreenMore.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get viewerScreenMore;

  /// No description provided for @slideshowScreenPlayOnTv.
  ///
  /// In en, this message translates to:
  /// **'Play on TV'**
  String get slideshowScreenPlayOnTv;

  /// No description provided for @tvSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Play on TV'**
  String get tvSheetTitle;

  /// No description provided for @tvSheetSearching.
  ///
  /// In en, this message translates to:
  /// **'Looking for TVs on this network…'**
  String get tvSheetSearching;

  /// No description provided for @tvSheetNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No TV found yet.'**
  String get tvSheetNoneFound;

  /// No description provided for @tvSheetSearchAgain.
  ///
  /// In en, this message translates to:
  /// **'Search again'**
  String get tvSheetSearchAgain;

  /// No description provided for @tvSheetChromecast.
  ///
  /// In en, this message translates to:
  /// **'Chromecast'**
  String get tvSheetChromecast;

  /// No description provided for @tvSheetDlna.
  ///
  /// In en, this message translates to:
  /// **'DLNA TV'**
  String get tvSheetDlna;

  /// No description provided for @tvSheetAirPlay.
  ///
  /// In en, this message translates to:
  /// **'AirPlay'**
  String get tvSheetAirPlay;

  /// No description provided for @tvSheetAirPlayHint.
  ///
  /// In en, this message translates to:
  /// **'Choose an Apple TV with the button: the videos you play go to it. Photos appear on the TV with Screen Mirroring in Control Centre.'**
  String get tvSheetAirPlayHint;

  /// No description provided for @tvSheetAddByAddress.
  ///
  /// In en, this message translates to:
  /// **'Add a TV by its address'**
  String get tvSheetAddByAddress;

  /// No description provided for @tvSheetAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'The TV\'s IP address, or its description address'**
  String get tvSheetAddressLabel;

  /// No description provided for @tvSheetAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get tvSheetAdd;

  /// No description provided for @tvSheetNotFoundAt.
  ///
  /// In en, this message translates to:
  /// **'No TV answered at that address.'**
  String get tvSheetNotFoundAt;

  /// No description provided for @tvSheetPlayingOn.
  ///
  /// In en, this message translates to:
  /// **'Playing on {device}'**
  String tvSheetPlayingOn(String device);

  /// No description provided for @tvSheetStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get tvSheetStop;

  /// No description provided for @tvSheetFailed.
  ///
  /// In en, this message translates to:
  /// **'The TV could not be reached.'**
  String get tvSheetFailed;

  /// No description provided for @tvSheetPlay.
  ///
  /// In en, this message translates to:
  /// **'Play on the TV'**
  String get tvSheetPlay;

  /// No description provided for @tvSheetPause.
  ///
  /// In en, this message translates to:
  /// **'Pause on the TV'**
  String get tvSheetPause;

  /// No description provided for @tvSheetPosition.
  ///
  /// In en, this message translates to:
  /// **'Position on the TV'**
  String get tvSheetPosition;

  /// No description provided for @tvSheetConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to the TV…'**
  String get tvSheetConnecting;

  /// No description provided for @tvSheetSameNetwork.
  ///
  /// In en, this message translates to:
  /// **'The TV and this phone must be on the same network. The TV gets an address that works for 4 hours and only for what you send it.'**
  String get tvSheetSameNetwork;

  /// No description provided for @adminServerSettingsDlna.
  ///
  /// In en, this message translates to:
  /// **'DLNA media server'**
  String get adminServerSettingsDlna;

  /// No description provided for @adminServerSettingsDlnaHelp.
  ///
  /// In en, this message translates to:
  /// **'TVs on your home network see your albums, without a password. It needs the dlna service, which runs on the host\'s network: see the TV page of the docs.'**
  String get adminServerSettingsDlnaHelp;

  /// No description provided for @adminServerSettingsDlnaOwner.
  ///
  /// In en, this message translates to:
  /// **'TVs see the albums of {name}.'**
  String adminServerSettingsDlnaOwner(String name);

  /// No description provided for @adminServerSettingsDlnaAnnounced.
  ///
  /// In en, this message translates to:
  /// **'The dlna service is running, so TVs can find this server.'**
  String get adminServerSettingsDlnaAnnounced;

  /// No description provided for @adminServerSettingsDlnaNotAnnounced.
  ///
  /// In en, this message translates to:
  /// **'The dlna service has not been heard from, so TVs cannot find this server yet.'**
  String get adminServerSettingsDlnaNotAnnounced;

  /// No description provided for @widgetInstallTitle.
  ///
  /// In en, this message translates to:
  /// **'Installation check'**
  String get widgetInstallTitle;

  /// No description provided for @widgetInstallMissing.
  ///
  /// In en, this message translates to:
  /// **'The widget is not in this installation: the signing left it out. Sign the app again without removing extensions (in Feather: do not remove PlugIns).'**
  String get widgetInstallMissing;

  /// No description provided for @widgetInstallUnsigned.
  ///
  /// In en, this message translates to:
  /// **'The widget is in the app but was not signed, so iOS does not offer it. Sign the app again so that its extensions are signed too.'**
  String get widgetInstallUnsigned;

  /// No description provided for @widgetInstallFine.
  ///
  /// In en, this message translates to:
  /// **'The widget is installed and signed. If it is still not offered, restart the phone.'**
  String get widgetInstallFine;

  /// No description provided for @homeWidgetNoShare.
  ///
  /// In en, this message translates to:
  /// **'This installation does not let the app hand the album to its widget.'**
  String get homeWidgetNoShare;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'hr', 'sl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'hr':
      return AppLocalizationsHr();
    case 'sl':
      return AppLocalizationsSl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

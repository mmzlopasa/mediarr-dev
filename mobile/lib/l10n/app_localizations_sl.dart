// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovenian (`sl`).
class AppLocalizationsSl extends AppLocalizations {
  AppLocalizationsSl([String locale = 'sl']) : super(locale);

  @override
  String get languageTitle => 'Jezik';

  @override
  String get languageMachine => 'Strojni prevod: prebral ga še ni nihče.';

  @override
  String get languageFollowsAccount =>
      'Izbira se shrani v vaš račun, zato ji sledijo tudi druge naprave.';

  @override
  String get appHeaderNew => 'Novo';

  @override
  String get appHeaderAdd => 'Dodaj';

  @override
  String get appHeaderAccount => 'Račun';

  @override
  String get appHeaderBackupAndUpload => 'Varnostna kopija in nalaganje';

  @override
  String get uploadsCouldNotRead =>
      'Te fotografije ni bilo mogoče prebrati z naprave.';

  @override
  String get waitingStripTitle => 'Na tem telefonu, čaka na varnostno kopijo';

  @override
  String get shareSheetVaultTitle => 'Odstranim iz trezorja?';

  @override
  String get shareSheetVaultBody =>
      'Ko je poslano ali shranjeno, ga tvoja koda PIN ne ščiti več.';

  @override
  String get shareSheetCancel => 'Prekliči';

  @override
  String get shareSheetContinue => 'Nadaljuj';

  @override
  String get shareSheetSendThis => 'Pošlji to';

  @override
  String shareSheetSendCount(String count) {
    return 'Pošlji $count';
  }

  @override
  String get shareSheetSmaller => 'Manjše, za sporočila';

  @override
  String get shareSheetOriginal => 'Izvirnik';

  @override
  String get shareSheetSmallerDetail => 'JPEG z največ 2048 px, brez lokacije';

  @override
  String get shareSheetOriginalDetail => 'Tak, kot je, z vsem, kar vsebuje';

  @override
  String get shareSheetSaveToPhone => 'Shrani v ta telefon';

  @override
  String get shareSheetSaveDetail => 'Izvirnik, v galeriji telefona';

  @override
  String get shareSheetSavedOne => 'Shranjeno v ta telefon.';

  @override
  String shareSheetSavedMany(String count) {
    return 'Shranjeno v ta telefon: $count.';
  }

  @override
  String get shareSheetGettingReady => 'Pripravljam';

  @override
  String shareSheetProgress(String done, String total) {
    return '$done od $total';
  }

  @override
  String get shareSheetFetchFailed => 'Datotek ni bilo mogoče pridobiti.';

  @override
  String facesSectionActionFailed(String detail) {
    return 'Dejanje ni uspelo. $detail';
  }

  @override
  String get facesSectionNewPerson => 'Nova oseba';

  @override
  String get facesSectionCancel => 'Prekliči';

  @override
  String get facesSectionSave => 'Shrani';

  @override
  String get facesSectionPeople => 'Osebe';

  @override
  String get facesSectionNoName => 'Brez imena';

  @override
  String get facesSectionWhoThisIs => 'Kdo je to';

  @override
  String get facesSectionNewPersonMenu => 'Nova oseba…';

  @override
  String get facesSectionNotAPerson => 'Ni oseba';

  @override
  String get importsScreenWaitingForFiles => 'Čaka na datoteke';

  @override
  String get importsScreenRunning => 'Poteka';

  @override
  String get importsScreenDone => 'Končano';

  @override
  String get importsScreenFailed => 'Ni uspelo';

  @override
  String get importsScreenStopped => 'Ustavljeno';

  @override
  String importsScreenZipUploaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Naloženih $count datotek ZIP',
      few: 'Naložene $count datoteke ZIP',
      two: 'Naloženi $count datoteki ZIP',
      one: 'Naložena $count datoteka ZIP',
    );
    return '$_temp0';
  }

  @override
  String importsScreenCounts(String added, String skipped, String failed) {
    return 'dodano $added · že tukaj ali izbrisano $skipped · ni uspelo $failed';
  }

  @override
  String get importsScreenReportNotLoaded =>
      'Poročila ni bilo mogoče naložiti.';

  @override
  String get importsScreenNoFilesFailed => 'Nobena datoteka ni spodletela.';

  @override
  String get importsScreenCouldNotStop => 'Uvoza ni bilo mogoče ustaviti.';

  @override
  String get importsScreenStop => 'Ustavi';

  @override
  String get importsScreenCouldNotContinue =>
      'Uvoza ni bilo mogoče nadaljevati.';

  @override
  String get importsScreenBringIn => 'Uvozi';

  @override
  String get importsScreenContinue => 'Nadaljuj';

  @override
  String get importsScreenReport => 'Poročilo';

  @override
  String get importsScreenTitle => 'Uvoz';

  @override
  String get importsScreenNotLoaded => 'Uvozov ni bilo mogoče naložiti.';

  @override
  String importsScreenHowTo(String address) {
    return 'Za uvoz fotografij iz Google Photos ali iClouda naloži datoteke ZIP izvoza na računalniku, na $address.';
  }

  @override
  String get importsScreenNothingYet => 'Še nisi ničesar uvozil.';

  @override
  String get storageTemplateScreenDryRun => 'Poskusni zagon';

  @override
  String storageTemplateScreenDryRunProgress(String checked) {
    return 'Poskusni zagon… $checked';
  }

  @override
  String storageTemplateScreenMovingProgress(String checked) {
    return 'Premikam… $checked';
  }

  @override
  String storageTemplateScreenWouldMove(String moved, String checked) {
    return 'Poskusni zagon: premaknjenih bi bilo $moved od $checked.';
  }

  @override
  String storageTemplateScreenMoved(String moved, String checked) {
    return 'Premaknjeno $moved od $checked.';
  }

  @override
  String storageTemplateScreenFailedCount(String line, String failed) {
    return '$line Ni uspelo: $failed.';
  }

  @override
  String get storageTemplateScreenNotLoaded => 'Ni naloženo.';

  @override
  String get storageTemplateScreenSaved => 'Shranjeno.';

  @override
  String get storageTemplateScreenNotSaved => 'Ni shranjeno.';

  @override
  String storageTemplateScreenMoveFilesQuestion(String count) {
    return 'Premaknem $count datotek?';
  }

  @override
  String get storageTemplateScreenOriginalsUnchanged =>
      'Izvirniki se ne spremenijo, le njihovo mesto na disku.';

  @override
  String get storageTemplateScreenCancel => 'Prekliči';

  @override
  String get storageTemplateScreenMove => 'Premakni';

  @override
  String get storageTemplateScreenNotStarted => 'Ni zagnano.';

  @override
  String get storageTemplateScreenTitle => 'Predloga shranjevanja';

  @override
  String get storageTemplateScreenIntro =>
      'Kako so izvirniki razporejeni na disku, v mapi vsakega uporabnika. Velja za nove datoteke; obstoječe se premaknejo šele, ko to zahtevaš, po poskusnem zagonu. Zunanja knjižnica se nikoli ne premakne.';

  @override
  String get storageTemplateScreenTemplate => 'Predloga';

  @override
  String get storageTemplateScreenExamples => 'Primeri';

  @override
  String get storageTemplateScreenBackToUsual =>
      'Nazaj na običajno razporeditev';

  @override
  String get storageTemplateScreenSave => 'Shrani';

  @override
  String get storageTemplateScreenFilesAlreadyHere =>
      'Datoteke, ki so že tukaj';

  @override
  String get storageTemplateScreenMoveTheFiles => 'Premakni datoteke';

  @override
  String get mapScreenNoPlaceName => 'Brez imena kraja';

  @override
  String get mapScreenNotLoaded =>
      'Zemljevida ni bilo mogoče naložiti. Preveri povezavo.';

  @override
  String get mapScreenTryAgain => 'Poskusi znova';

  @override
  String get mapScreenNoPhotos => 'Še ni fotografij z lokacijo.';

  @override
  String get mapScreenFromDate => 'Od datuma';

  @override
  String get mapScreenToDate => 'Do datuma';

  @override
  String get mapScreenClear => 'Počisti';

  @override
  String mapScreenItems(String count) {
    return 'Elementi: $count';
  }

  @override
  String get mapScreenTrips => 'Potovanja';

  @override
  String get mapScreenTitle => 'Zemljevid';

  @override
  String get cleanupScreenBlurry => 'Zamegljene fotografije';

  @override
  String get cleanupScreenScreenshots => 'Posnetki zaslona';

  @override
  String get cleanupScreenLargeVideos => 'Veliki videoposnetki';

  @override
  String get cleanupScreenBursts => 'Zaporedni posnetki';

  @override
  String get cleanupScreenBlurryHint =>
      'Fotografije z zelo malo ostrimi robovi. Drsnik določa, kako strogo.';

  @override
  String get cleanupScreenScreenshotsHint =>
      'Prepoznani po imenu, oznaki iPhona ali obliki zaslona.';

  @override
  String get cleanupScreenLargeVideosHint => 'Največji najprej.';

  @override
  String get cleanupScreenBurstsHint =>
      'Drugi posnetki zaporedja. Najboljši ostane.';

  @override
  String get cleanupScreenMoveToTrashQuestion => 'Premaknem v koš?';

  @override
  String cleanupScreenTrashBody(String count, String size) {
    return '$count elementov ($size) ostane nekaj časa v košu in jih je mogoče obnoviti.';
  }

  @override
  String get cleanupScreenCancel => 'Prekliči';

  @override
  String get cleanupScreenMove => 'Premakni';

  @override
  String get cleanupScreenMovedToTrash => 'Premaknjeno v koš.';

  @override
  String get cleanupScreenActionFailed => 'Dejanje ni uspelo.';

  @override
  String get cleanupScreenKept => 'Obdržano. Ne bodo več predlagani.';

  @override
  String get cleanupScreenStricter => 'Strožje';

  @override
  String get cleanupScreenMore => 'Več';

  @override
  String get cleanupScreenLargerThan => 'Večji od ';

  @override
  String get cleanupScreenToTheTrash => 'V koš';

  @override
  String get cleanupScreenStays => 'Ostane';

  @override
  String get cleanupScreenFavorite => 'Priljubljena';

  @override
  String get cleanupScreenInAnAlbum => 'V albumu';

  @override
  String get cleanupScreenTitle => 'Čiščenje';

  @override
  String get cleanupScreenKeep => 'Obdrži';

  @override
  String cleanupScreenToTheTrashButton(String count, String size) {
    return 'V koš ($count · $size)';
  }

  @override
  String get cleanupScreenNotLoaded => 'Čiščenja ni bilo mogoče naložiti.';

  @override
  String cleanupScreenStillAnalysed(String count) {
    return 'Še v analizi: $count fotografij.';
  }

  @override
  String get cleanupScreenNothing => 'Tukaj ni ničesar za čiščenje.';

  @override
  String get cleanupScreenTapToTick =>
      'Tapni za označitev ali odznačitev. Pridrži za ogled.';

  @override
  String get cleanupScreenShowMore => 'Pokaži več';

  @override
  String get organizeScreensRecentlyAdded => 'Nedavno dodano';

  @override
  String get organizeScreensFavorites => 'Priljubljene';

  @override
  String get organizeScreensMemories => 'Spomini';

  @override
  String get organizeScreensPeople => 'Osebe';

  @override
  String get organizeScreensMap => 'Zemljevid';

  @override
  String get organizeScreensFolders => 'Mape';

  @override
  String get organizeScreensFamily => 'Družina';

  @override
  String get organizeScreensDocuments => 'Dokumenti';

  @override
  String get organizeScreensDuplicates => 'Dvojniki';

  @override
  String get organizeScreensCleanUp => 'Čiščenje';

  @override
  String get organizeScreensArchive => 'Arhiv';

  @override
  String get organizeScreensTrash => 'Koš';

  @override
  String get organizeScreensVault => 'Trezor';

  @override
  String get organizeScreensApiKeys => 'Ključi API';

  @override
  String get organizeScreensTags => 'Oznake';

  @override
  String get organizeScreensCouldNotLoad =>
      'Tega ni bilo mogoče naložiti. Preveri povezavo.';

  @override
  String get organizeScreensClearSelection => 'Počisti izbor';

  @override
  String get organizeScreensShare => 'Deli';

  @override
  String get organizeScreensOriginalsRemoved =>
      'Izvirniki se izbrišejo z diska. Tega ni mogoče razveljaviti.';

  @override
  String get organizeScreensCancel => 'Prekliči';

  @override
  String get organizeScreensDeletePermanently => 'Trajno izbriši';

  @override
  String organizeScreensActionFailedDetail(String detail) {
    return 'Dejanje ni uspelo. $detail';
  }

  @override
  String get organizeScreensNothingAdded => 'Še nič ni dodano.';

  @override
  String get organizeScreensAddToFavorites => 'Dodaj med priljubljene';

  @override
  String get organizeScreensAddedToFavorites => 'Dodano med priljubljene';

  @override
  String get organizeScreensArchiveAction => 'Arhiviraj';

  @override
  String get organizeScreensArchived => 'Arhivirano';

  @override
  String get organizeScreensNoFavorites =>
      'Še ni priljubljenih. Označi fotografijo z zvezdico.';

  @override
  String get organizeScreensRemoveFromFavorites => 'Odstrani iz priljubljenih';

  @override
  String get organizeScreensRemovedFromFavorites =>
      'Odstranjeno iz priljubljenih';

  @override
  String get organizeScreensArchiveEmpty => 'Arhiv je prazen.';

  @override
  String get organizeScreensBackToMedia => 'Nazaj med medije';

  @override
  String get organizeScreensBackInMedia => 'Spet med mediji';

  @override
  String organizeScreensTrashRemoves(String count, String size) {
    return 'S tem se odstrani $count datotek, $size.';
  }

  @override
  String get organizeScreensEmptyTrashQuestion => 'Izpraznim koš?';

  @override
  String organizeScreensPermanentlyDeletedCount(String count) {
    return 'Trajno izbrisano: $count';
  }

  @override
  String get organizeScreensEmpty => 'Izprazni';

  @override
  String get organizeScreensTrashAfterAWhile =>
      'Elementi tukaj se čez nekaj časa trajno izbrišejo.';

  @override
  String organizeScreensTrashAfterDays(String days) {
    return 'Elementi se trajno izbrišejo po $days dneh.';
  }

  @override
  String get organizeScreensTrashEmpty => 'Koš je prazen.';

  @override
  String get organizeScreensRestore => 'Obnovi';

  @override
  String get organizeScreensRestored => 'Obnovljeno';

  @override
  String get organizeScreensDeletePermanentlyQuestion => 'Trajno izbrišem?';

  @override
  String get organizeScreensPermanentlyDeleted => 'Trajno izbrisano';

  @override
  String get organizeScreensOpenYourVault => 'Odpri svoj trezor';

  @override
  String get organizeScreensTooManyAttempts =>
      'Preveč poskusov. Poskusi znova pozneje.';

  @override
  String get organizeScreensWrongPin => 'Napačna koda PIN.';

  @override
  String get organizeScreensPinLength =>
      'Koda PIN mora imeti od 4 do 12 števk.';

  @override
  String get organizeScreensVaultLockedItself =>
      'Trezor se je sam zaklenil. Znova ga odkleni.';

  @override
  String get organizeScreensVaultEmpty => 'Trezor je prazen.';

  @override
  String get organizeScreensVaultNotLoaded =>
      'Trezorja ni bilo mogoče naložiti. Preveri povezavo.';

  @override
  String get organizeScreensTryAgain => 'Poskusi znova';

  @override
  String get organizeScreensVaultIntro =>
      'Skrito pred vsemi drugimi pogledi in deljenjem. Datoteke na strežniku niso šifrirane.';

  @override
  String get organizeScreensPin => 'Koda PIN';

  @override
  String get organizeScreensNewPin => 'Nova koda PIN';

  @override
  String get organizeScreensPinHelper =>
      'Od 4 do 12 števk. Izgubljeno kodo PIN lahko ponastavi le skrbnik strežnika.';

  @override
  String get organizeScreensUseFaceId => 'Naslednjič uporabi Face ID';

  @override
  String get organizeScreensUnlock => 'Odkleni';

  @override
  String get organizeScreensSetPin => 'Nastavi kodo PIN';

  @override
  String get organizeScreensAddATag => 'Dodaj oznako';

  @override
  String get organizeScreensNewTag => 'Nova oznaka';

  @override
  String get organizeScreensCreateAndAdd => 'Ustvari in dodaj';

  @override
  String get organizeScreensTagsNotLoaded => 'Oznak ni bilo mogoče naložiti.';

  @override
  String get organizeScreensNoTags =>
      'Še ni oznak. Izberi fotografije in dodaj oznako.';

  @override
  String get organizeScreensDeleteTag => 'Izbriši oznako';

  @override
  String get organizeScreensRenameTheTag => 'Preimenuj oznako';

  @override
  String get organizeScreensNewName => 'Novo ime';

  @override
  String get organizeScreensSave => 'Shrani';

  @override
  String organizeScreensAlreadyExists(String name) {
    return '»$name« že obstaja';
  }

  @override
  String organizeScreensJoinThem(String name) {
    return 'Združim? Vse fotografije bodo imele »$name«.';
  }

  @override
  String get organizeScreensJoin => 'Združi';

  @override
  String organizeScreensNotRenamed(String detail) {
    return 'Ni preimenovano. $detail';
  }

  @override
  String organizeScreensNotJoined(String detail) {
    return 'Ni združeno. $detail';
  }

  @override
  String get organizeScreensRename => 'Preimenuj';

  @override
  String get organizeScreensNoPhotosWithTag =>
      'Nobena fotografija nima te oznake.';

  @override
  String get organizeScreensRemoveTheTag => 'Odstrani oznako';

  @override
  String get organizeScreensFamilyNotOn => 'Skrbnik tega ni vklopil.';

  @override
  String get organizeScreensFamilyNotMember => 'Še nisi v družinski knjižnici.';

  @override
  String get organizeScreensWhatIShare => 'Kaj delim';

  @override
  String get organizeScreensFamilyNotLoaded =>
      'Družinske knjižnice ni bilo mogoče naložiti.';

  @override
  String get organizeScreensFamilyNothingShared =>
      'Z družino še nihče ni ničesar delil.';

  @override
  String get organizeScreensShareWithFamily => 'Deli z družino';

  @override
  String get organizeScreensRuleName => 'Ime pravila';

  @override
  String get organizeScreensFromDateExample => 'Od datuma (2024-06-01)';

  @override
  String get organizeScreensPlace => 'Kraj';

  @override
  String organizeScreensNotSaved(String detail) {
    return 'Ni bilo shranjeno. $detail';
  }

  @override
  String get organizeScreensNewRule => 'Novo pravilo';

  @override
  String get organizeScreensShareNothing => 'Z družino še ničesar ne deliš.';

  @override
  String get organizeScreensStopSharing => 'Prenehaj deliti';

  @override
  String get organizeScreensActionFailed => 'Dejanje ni uspelo.';

  @override
  String get settingsScreenTitle => 'Nastavitve';

  @override
  String get settingsScreenViewing => 'Ogled';

  @override
  String get settingsScreenAssetViewer => 'Pregledovalnik';

  @override
  String get settingsScreenAssetViewerHint =>
      'Kako se odpirajo fotografije in videoposnetki';

  @override
  String get settingsScreenPhotoGrid => 'Mreža fotografij';

  @override
  String get settingsScreenPhotoGridHint => 'Kako je razporejena časovnica';

  @override
  String get settingsScreenPreferences => 'Prilagoditve';

  @override
  String get settingsScreenPreferencesHint => 'Tema, barva in odziv';

  @override
  String get settingsScreenLanguageHint => 'Jezik aplikacije';

  @override
  String get settingsScreenThisPhone => 'Ta telefon';

  @override
  String get settingsScreenBackup => 'Varnostna kopija';

  @override
  String get settingsScreenBackupHint => 'Kaj ta telefon pošilja na strežnik';

  @override
  String get settingsScreenFreeUpSpace => 'Sprosti prostor';

  @override
  String get settingsScreenFreeUpSpaceHint =>
      'Odstrani, kar je varno na strežniku';

  @override
  String get settingsScreenSyncStatus => 'Stanje sinhronizacije';

  @override
  String get settingsScreenSyncStatusHint =>
      'Kaj je na tem telefonu in na strežniku';

  @override
  String get settingsScreenHomeWidget => 'Pripomoček na začetnem zaslonu';

  @override
  String get settingsScreenHomeWidgetHint => 'Album na začetnem zaslonu';

  @override
  String get settingsScreenNotifications => 'Obvestila';

  @override
  String get settingsScreenNotificationsHint => 'O čem te obvešča aplikacija';

  @override
  String get settingsScreenServer => 'Strežnik';

  @override
  String get settingsScreenDevices => 'Naprave';

  @override
  String get settingsScreenDevicesHint => 'Kje je ta račun prijavljen';

  @override
  String get settingsScreenYourLibrary => 'Tvoja knjižnica';

  @override
  String get settingsScreenYourLibraryHint => 'Koliko vsebuje ta račun';

  @override
  String get settingsScreenNetworking => 'Omrežje';

  @override
  String get settingsScreenNetworkingHint => 'Naslovi tvojega strežnika';

  @override
  String get settingsScreenAdvanced => 'Napredno';

  @override
  String get settingsScreenAdvancedHint =>
      'Način samo za branje in predpomnilnik slik';

  @override
  String get settingsScreenWhatsNew => 'Kaj je novega';

  @override
  String get settingsScreenWhatsNewHint => 'Različice Mediarra';

  @override
  String get settingsScreenReadOnlyOff => 'Izklopi način samo za branje';

  @override
  String get settingsScreenReadOnly => 'Način samo za branje';

  @override
  String get settingsScreenReadOnlyHint =>
      'Samo ogled: brez nalaganja, urejanja ali brisanja iz te aplikacije';

  @override
  String get settingsScreenCopyAlbums => 'Kopiraj albume na strežnik';

  @override
  String get settingsScreenCopyAlbumsHint =>
      'Albumi z varnostno kopijo dobijo istoimenski album na strežniku. Fotografije se samo dodajajo, nikoli ne odstranijo';

  @override
  String get settingsScreenClearCache => 'Počisti predpomnilnik slik';

  @override
  String get settingsScreenCacheEmpty => 'Predpomnilnik slik je prazen.';

  @override
  String get settingsScreenPhotos => 'Fotografije';

  @override
  String get settingsScreenLoadFull => 'Naloži celotno fotografijo';

  @override
  String get settingsScreenLoadFullHint =>
      'Odpre fotografije v polni ločljivosti. Porabi več podatkov in je počasnejše';

  @override
  String get settingsScreenTapToNavigate => 'Tapni za premikanje';

  @override
  String get settingsScreenTapToNavigateHint =>
      'Tap na levo ali desno četrtino zaslona odpre prejšnjo ali naslednjo fotografijo';

  @override
  String get settingsScreenVideos => 'Videoposnetki';

  @override
  String get settingsScreenAutoPlay => 'Samodejno predvajaj videoposnetke';

  @override
  String get settingsScreenAutoPlayHint =>
      'Videoposnetki se začnejo ob odprtju';

  @override
  String get settingsScreenLooping => 'Ponavljanje';

  @override
  String get settingsScreenLoopingHint =>
      'Videoposnetki se ob koncu začnejo znova';

  @override
  String get settingsScreenPlayOriginal => 'Predvajaj izvirni videoposnetek';

  @override
  String get settingsScreenPlayOriginalHint =>
      'Predvaja izvirnik, tudi ko obstaja pretvorjena različica. Morda bo moral nalagati';

  @override
  String get settingsScreenLayout => 'Postavitev';

  @override
  String settingsScreenPerRow(String count) {
    return 'Fotografij v vrsti ($count)';
  }

  @override
  String get settingsScreenGroupBy => 'Združi po';

  @override
  String get settingsScreenMonthDay => 'Mesec + dan';

  @override
  String get settingsScreenMonth => 'Mesec';

  @override
  String get settingsScreenTheme => 'Tema';

  @override
  String get settingsScreenPrimaryColor => 'Glavna barva';

  @override
  String get settingsScreenHaptics => 'Haptični odziv';

  @override
  String get settingsScreenEnabled => 'Vklopljeno';

  @override
  String get settingsScreenNotificationsNotYet => 'Obvestila še niso na voljo.';

  @override
  String get settingsScreenPhotosAndVideos => 'Fotografije in videoposnetki';

  @override
  String get settingsScreenPhone => 'Telefon';

  @override
  String get settingsScreenAlbums => 'Albumi';

  @override
  String get settingsScreenOther => 'Drugo';

  @override
  String get settingsScreenMemories => 'Spomini';

  @override
  String get settingsScreenBackedUp => 'Varnostno kopirano';

  @override
  String get settingsScreenCheckAgain => 'Preveri znova';

  @override
  String settingsScreenRetryFailed(String count) {
    return 'Znova pošlji neuspele ($count)';
  }

  @override
  String get settingsScreenRemoved => 'Odstranjeno.';

  @override
  String get settingsScreenSaved => 'Shranjeno.';

  @override
  String settingsScreenMainAddress(String address) {
    return 'Glavni naslov: $address';
  }

  @override
  String get settingsScreenSecondAddress => 'Drugi naslov';

  @override
  String get settingsScreenSecondAddressHint =>
      'Uporabi se, ko glavni ne odgovori, npr. zunaj doma';

  @override
  String get settingsScreenSave => 'Shrani';

  @override
  String get settingsScreenCouldNotLoad => 'Tega ni bilo mogoče naložiti.';

  @override
  String get settingsScreenThisDevice => 'Ta naprava';

  @override
  String get settingsScreenSignOut => 'Odjavi';

  @override
  String get settingsScreenSignOutOthers => 'Odjavi vse ostale';

  @override
  String get settingsScreenFavorites => 'Priljubljene';

  @override
  String get settingsScreenArchive => 'Arhiv';

  @override
  String get settingsScreenTrash => 'Koš';

  @override
  String get settingsScreenUsed => 'Zasedeno';

  @override
  String get settingsScreenYourAccount => 'Tvoj račun';

  @override
  String settingsScreenMemorySeconds(String seconds) {
    return 'Sekunde za vsako sliko v spominih ($seconds)';
  }

  @override
  String settingsScreenMinFaces(String count) {
    return 'Najmanj fotografij, da je oseba prikazana ($count)';
  }

  @override
  String get settingsScreenAlbumOrder => 'Vrstni red v novem albumu';

  @override
  String get settingsScreenNewestFirst => 'Najnovejše najprej';

  @override
  String get settingsScreenOldestFirst => 'Najstarejše najprej';

  @override
  String get sessionDeviceNotApproved =>
      'Skrbnik mora odobriti to napravo, preden se lahko prijavi.';

  @override
  String get sessionEnterAddress => 'Vnesi naslov svojega strežnika.';

  @override
  String get sessionAddressInvalid => 'Ta naslov strežnika ni veljaven.';

  @override
  String get sessionNoServer =>
      'Na tem naslovu se ni odzval noben strežnik Mediarr.';

  @override
  String sessionUnreachableCheck(String reason) {
    return 'Strežnik ni dosegljiv. Preveri naslov. ($reason)';
  }

  @override
  String sessionUnreachable(String reason) {
    return 'Strežnik ni dosegljiv. ($reason)';
  }

  @override
  String get sessionCodeWrong => 'Koda je napačna.';

  @override
  String get sessionWrongPassword => 'Napačen e-poštni naslov ali geslo.';

  @override
  String get sessionTooManyAttempts =>
      'Preveč poskusov. Poskusi znova pozneje.';

  @override
  String sessionSignInFailed(String code) {
    return 'Prijava ni uspela ($code).';
  }

  @override
  String get sessionNoSession => 'Strežnik ni začel seje.';

  @override
  String get sessionCancelled => 'Prijava je bila preklicana.';

  @override
  String get sessionSsoOff =>
      'Enotna prijava (SSO) za ta strežnik ni vklopljena.';

  @override
  String get sessionSsoFailed =>
      'Enotna prijava ni uspela. Morda nimaš računa na tem strežniku.';

  @override
  String get sessionCodeExpired =>
      'Ta koda je potekla ali je bila že uporabljena. Ustvari novo.';

  @override
  String get sessionNoAnswer => 'Strežnik se ni odzval.';

  @override
  String get sessionNotAllowed => 'Prijava ni bila dovoljena.';

  @override
  String get sessionSignInExpired =>
      'Ta prijava je potekla. Ustvari novo kodo.';

  @override
  String get sessionNobodyAnswered =>
      'Nihče se ni pravočasno odzval. Ustvari novo kodo.';

  @override
  String get tusSignedOut => 'Odjavljen si. Znova se prijavi.';

  @override
  String tusRejected(String code, String body) {
    return 'Strežnik je zavrnil to datoteko ($code). $body';
  }

  @override
  String albumsScreenInside(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albumov',
      few: '$count albumi',
      two: '$count albuma',
      one: '$count album',
    );
    return '$_temp0';
  }

  @override
  String get albumsScreenLoadFailed =>
      'Albumov ni bilo mogoče naložiti. Preveri povezavo.';

  @override
  String get albumsScreenTryAgain => 'Poskusi znova';

  @override
  String get albumsScreenNoAlbums => 'Še ni albumov.';

  @override
  String get albumsScreenNoMatch => 'Noben album se ne ujema.';

  @override
  String get albumsScreenSortUpdated => 'Zadnja sprememba';

  @override
  String get albumsScreenName => 'Ime';

  @override
  String get albumsScreenSortDate => 'Datum fotografije';

  @override
  String get albumsScreenTitle => 'Albumi';

  @override
  String get albumsScreenNew => 'Nov';

  @override
  String get albumsScreenSort => 'Razvrsti';

  @override
  String get albumsScreenSearchFilter => 'Iskanje in filter';

  @override
  String get albumsScreenShowList => 'Prikaži kot seznam';

  @override
  String get albumsScreenShowGrid => 'Prikaži kot mrežo';

  @override
  String get albumsScreenSearchAlbums => 'Išči albume';

  @override
  String get albumsScreenAll => 'Vsi';

  @override
  String get albumsScreenSharedWithMe => 'Deljeni z mano';

  @override
  String get albumsScreenMine => 'Moji albumi';

  @override
  String albumsScreenItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementov',
      few: '$count elementi',
      two: '$count elementa',
      one: '$count element',
    );
    return '$_temp0';
  }

  @override
  String get albumsScreenSmart => 'Pametni';

  @override
  String get albumsScreenOwned => 'Moj';

  @override
  String get albumsScreenNotCreated => 'Album ni bil ustvarjen.';

  @override
  String get albumsScreenNewAlbum => 'Nov album';

  @override
  String get albumsScreenDescription => 'Opis';

  @override
  String get albumsScreenSmartAlbum =>
      'Pametni album: se sam polni po pravilih';

  @override
  String get albumsScreenCreate => 'Ustvari';

  @override
  String get adminScreenTitle => 'Administracija';

  @override
  String get adminScreenOverview => 'Pregled';

  @override
  String get adminScreenOverviewHint =>
      'Uporabniki, fotografije, disk in različice';

  @override
  String get adminScreenUsers => 'Uporabniki';

  @override
  String get adminScreenUsersHint =>
      'Dodaj uporabnike in določi, koliko smejo shraniti';

  @override
  String get adminScreenServerSettings => 'Nastavitve strežnika';

  @override
  String get adminScreenServerSettingsHint =>
      'Koš, kakovost, obrazi, opravila, prijava';

  @override
  String get adminScreenEmail => 'E-pošta';

  @override
  String get adminScreenEmailHint => 'Od kod se pošiljajo sporočila';

  @override
  String get adminScreenSecurity => 'Varnost';

  @override
  String get adminScreenSecurityHint =>
      'Enotna prijava, naprave, naslovi, poskusi';

  @override
  String get adminScreenJobs => 'Opravila';

  @override
  String get adminScreenJobsHint => 'Čakalne vrste in neuspela opravila';

  @override
  String get adminScreenAuditLog => 'Dnevnik dejavnosti';

  @override
  String get adminScreenAuditLogHint => 'Kdo je kaj spremenil';

  @override
  String get adminScreenBackupHint => 'Kopije knjižnice';

  @override
  String get adminScreenBackupDevices => 'Vse naprave za varnostno kopiranje';

  @override
  String get adminScreenBackupDevicesHint =>
      'Vsak telefon, ki varnostno kopira';

  @override
  String get adminScreenStorageTemplate => 'Predloga shranjevanja';

  @override
  String get adminScreenStorageTemplateHint =>
      'Kako so izvirniki razporejeni na disku';

  @override
  String get adminAuditEmpty => 'Še nič ni bilo spremenjeno.';

  @override
  String get adminAuditShowOlder => 'Prikaži starejše';

  @override
  String adminUsersAdded(String email) {
    return '$email je bil dodan.';
  }

  @override
  String get adminUsersAddUser => 'Dodaj uporabnika';

  @override
  String get adminUsersAdministrator => 'Skrbnik';

  @override
  String adminUsersStoredOf(String stored, String quota) {
    return '$stored od $quota';
  }

  @override
  String get adminUsersNoLimit => 'brez omejitve';

  @override
  String adminUsersQuotaTooltip(String email) {
    return 'Koliko sme $email shraniti';
  }

  @override
  String get adminUsersEmail => 'E-pošta';

  @override
  String get adminUsersName => 'Ime';

  @override
  String get adminUsersPassword => 'Geslo';

  @override
  String get adminUsersCancel => 'Prekliči';

  @override
  String get adminUsersAdd => 'Dodaj';

  @override
  String get adminUsersQuotaInvalid =>
      'Vnesi število gigabajtov ali nič za brez omejitve.';

  @override
  String adminUsersStorageFor(String email) {
    return 'Prostor za $email';
  }

  @override
  String get adminUsersLimitGb => 'Omejitev v GB';

  @override
  String get adminUsersEmptyNoLimit => 'Prazno pomeni brez omejitve.';

  @override
  String get profileScreenNotSaved => 'Profila ni bilo mogoče shraniti.';

  @override
  String get profileScreenPictureNotSent => 'Slike ni bilo mogoče poslati.';

  @override
  String get profileScreenPictureNotRemoved =>
      'Slike ni bilo mogoče odstraniti.';

  @override
  String get profileScreenTitle => 'Profil';

  @override
  String get profileScreenChangePicture => 'Spremeni sliko';

  @override
  String get profileScreenAddPicture => 'Dodaj sliko';

  @override
  String get profileScreenRemove => 'Odstrani';

  @override
  String get profileScreenEmailAddress => 'E-poštni naslov';

  @override
  String get profileScreenCurrentPassword =>
      'Trenutno geslo, za spremembo e-pošte';

  @override
  String get serverStatusStorage => 'Prostor';

  @override
  String serverStatusUsedOf(String used, String total) {
    return '$used od $total zasedeno';
  }

  @override
  String get serverStatusOnline => 'Strežnik deluje';

  @override
  String get serverStatusMaintained => 'Strežnik je v vzdrževanju';

  @override
  String get serverStatusOffline => 'Strežnik ne odgovarja';

  @override
  String serverStatusVersionAvailable(String version) {
    return 'Na voljo je različica $version';
  }

  @override
  String get serverStatusNewVersion => 'Na voljo je nova različica';

  @override
  String serverStatusUpdateBody(String latest, String version) {
    return 'Mediarr $latest je na voljo. Ta strežnik uporablja $version. Skrbnik strežnika ga posodobi z:\n\ndocker compose pull && docker compose up -d';
  }

  @override
  String get serverStatusOk => 'V redu';

  @override
  String get storiesStripLastWeek => 'Zadnji teden';

  @override
  String storiesStripYearsAgo(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: 'pred $years leti',
      few: 'pred $years leti',
      two: 'pred $years letoma',
      one: 'pred $years letom',
    );
    return '$_temp0';
  }

  @override
  String storiesStripItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementov',
      few: '$count elementi',
      two: '$count elementa',
      one: '$count element',
    );
    return '$_temp0';
  }

  @override
  String get backupScreenNotYet => 'še ne';

  @override
  String backupScreenLastBackup(String when) {
    return 'zadnja varnostna kopija $when';
  }

  @override
  String backupScreenUpTo(String size) {
    return 'do $size';
  }

  @override
  String get backupScreenInvited => 'Povabljen';

  @override
  String get backupScreenStopped => 'Ustavljen';

  @override
  String get backupScreenActive => 'Aktiven';

  @override
  String backupScreenDeletedKept(String size) {
    return 'izbrisano, hranjeno: $size';
  }

  @override
  String get backupScreenActionFailed => 'Dejanje ni uspelo.';

  @override
  String get backupScreenSaved => 'Shranjeno.';

  @override
  String get backupScreenBackupStarted => 'Varnostno kopiranje se je začelo.';

  @override
  String get backupScreenRestoreTestStarted => 'Preizkus obnove se je začel.';

  @override
  String get backupScreenPaired =>
      'Seznanjeno. Naslednja varnostna kopija gre tudi tja.';

  @override
  String get backupScreenKeepForSomeone => 'Hrani varnostno kopijo za nekoga';

  @override
  String get backupScreenForWhom => 'Za koga';

  @override
  String get backupScreenAtMostGb => 'Največ (GB)';

  @override
  String get backupScreenOtherServerAddress =>
      'Naslov, na katerem te doseže drugi strežnik';

  @override
  String get backupScreenCancel => 'Prekliči';

  @override
  String get backupScreenInvite => 'Povabi';

  @override
  String get backupScreenInvitationFailed => 'Povabilo ni uspelo.';

  @override
  String backupScreenCodeFor(String name) {
    return 'Koda za $name';
  }

  @override
  String backupScreenSendItToAdmin(String when) {
    return 'Pošlji jo skrbniku drugega strežnika, ki jo prilepi ali skenira. Velja enkrat, do $when.';
  }

  @override
  String get backupScreenPlainHttp =>
      'Prek navadnega HTTP je ključ mogoče prebrati na poti. Uporabi HTTPS ali VPN.';

  @override
  String get backupScreenCopy => 'Kopiraj';

  @override
  String get backupScreenDone => 'Končano';

  @override
  String backupScreenHowMuchFor(String name) {
    return 'Koliko za $name';
  }

  @override
  String get backupScreenSave => 'Shrani';

  @override
  String backupScreenDeleteCopyOf(String name) {
    return 'Izbrišem kopijo za $name?';
  }

  @override
  String backupScreenTypeToDelete(String name) {
    return 'Vnesi »$name«, da jo izbrišeš';
  }

  @override
  String get backupScreenDeleteTheCopy => 'Izbriši kopijo';

  @override
  String get backupScreenScheduledBackup => 'Načrtovana varnostna kopija';

  @override
  String get backupScreenOnceADay => 'Enkrat na dan, ob uri spodaj';

  @override
  String backupScreenExplain(String folder) {
    return 'Izvirniki in baza, šifrirano. Cilj je mapa v $folder ali naslov s3: ali b2:. Geslo si zapiši nekam drugam kot na ta strežnik.';
  }

  @override
  String get backupScreenBackupFolder => 'mapi za varnostne kopije';

  @override
  String get backupScreenDestination => 'Cilj';

  @override
  String get backupScreenPasswordSaved =>
      'Geslo (shranjeno, vnesi za spremembo)';

  @override
  String get backupScreenBackupPassword => 'Geslo varnostne kopije';

  @override
  String get backupScreenAccessKeySaved => 'Dostopni ključ (shranjen)';

  @override
  String get backupScreenAccessKey => 'Dostopni ključ (S3, B2)';

  @override
  String get backupScreenSecretKey => 'Skrivni ključ (S3, B2)';

  @override
  String get backupScreenHourOfDay => 'Ura dneva (0-23)';

  @override
  String get backupScreenBackUpNow => 'Varnostno kopiraj zdaj';

  @override
  String get backupScreenTestBringingBack => 'Preizkusi obnovo';

  @override
  String get backupScreenHistory => 'Zgodovina';

  @override
  String get backupScreenRunBackup => 'Varnostna kopija';

  @override
  String get backupScreenRunRestoreTest => 'Preizkus obnove';

  @override
  String backupScreenFiles(String count) {
    return 'datotek: $count';
  }

  @override
  String get backupScreenMyCopyAtOthers => 'Moja kopija pri drugih';

  @override
  String get backupScreenTwoServers =>
      'Dva strežnika Mediarr hranita šifrirano kopijo drug drugega. Tisti, ki jo hrani, je ne more prebrati, in kar se iz nje izbriše, ostane še 90 dni.';

  @override
  String get backupScreenNoHttps => 'Brez HTTPS';

  @override
  String get backupScreenMore => 'Več';

  @override
  String get backupScreenRemove => 'Odstrani';

  @override
  String get backupScreenCodeFromOther => 'Koda drugega Mediarra';

  @override
  String get backupScreenScanQr => 'Skeniraj kodo QR';

  @override
  String get backupScreenPairing => 'Seznanjanje…';

  @override
  String get backupScreenPair => 'Seznani';

  @override
  String get backupScreenSnapshots => 'Posnetki pred nadgradnjami';

  @override
  String get backupScreenSnapshotsExplain =>
      'Pred vsako nadgradnjo, ki spremeni bazo, Mediarr shrani njen posnetek. Hranijo se zadnji trije.';

  @override
  String get backupScreenNoSnapshots =>
      'Posnetkov še ni. Prvi nastane ob naslednji nadgradnji, ki spremeni bazo.';

  @override
  String get backupScreenEarlierVersion => 'Prejšnja različica';

  @override
  String get backupScreenDeleteSnapshot => 'Izbriši posnetek';

  @override
  String get backupScreenGoBackHow =>
      'Za vrnitev na najnovejšega, v mapi z docker-compose.yml:';

  @override
  String get backupScreenDeleteThisSnapshot => 'Izbrišem ta posnetek?';

  @override
  String get backupScreenNoGoingBack => 'Nanj se ne bo več mogoče vrniti.';

  @override
  String get backupScreenDelete => 'Izbriši';

  @override
  String get backupScreenNotDeleted => 'Ni izbrisano.';

  @override
  String get backupScreenIKeepForOthers => 'Hranim za druge';

  @override
  String get backupScreenNoNewCode => 'Ni nove kode.';

  @override
  String backupScreenFilesBroughtBack(String count) {
    return 'Vrnjenih datotek: $count.';
  }

  @override
  String get backupScreenNewCode => 'Nova koda';

  @override
  String get backupScreenResume => 'Nadaljuj';

  @override
  String get backupScreenStop => 'Ustavi';

  @override
  String get backupScreenSize => 'Velikost';

  @override
  String get backupScreenBringBackDeleted => 'Vrni izbrisano';

  @override
  String get backupScreenTitle => 'Varnostna kopija';

  @override
  String get backupScreenLoadFailed =>
      'Nastavitev varnostnega kopiranja ni bilo mogoče naložiti.';

  @override
  String get backupScreenScanTheCode => 'Skeniraj kodo';

  @override
  String get duplicatesScreenFavorite => 'Priljubljena';

  @override
  String get duplicatesScreenOriginal => 'Izvirnik';

  @override
  String get duplicatesScreenSavedAgain => 'Znova shranjeno v aplikaciji';

  @override
  String get duplicatesScreenHasLocation => 'Ima lokacijo';

  @override
  String get duplicatesScreenHasDescription => 'Ima opis';

  @override
  String get duplicatesScreenNoDate => 'Brez datuma';

  @override
  String get duplicatesScreenReasonFavorite => 'priljubljena';

  @override
  String get duplicatesScreenReasonCameraOriginal => 'izvirnik iz fotoaparata';

  @override
  String get duplicatesScreenReasonOthersSaved =>
      'druge so bile znova shranjene v aplikacijah';

  @override
  String get duplicatesScreenReasonHighestResolution => 'najvišja ločljivost';

  @override
  String get duplicatesScreenReasonLargestFile => 'največja datoteka';

  @override
  String get duplicatesScreenReasonEqual =>
      'enake so, zato lahko ostane katera koli';

  @override
  String get duplicatesScreenReasonSharpest => 'najostrejša';

  @override
  String get duplicatesScreenCancel => 'Prekliči';

  @override
  String get duplicatesScreenResolveThisGroup => 'Razrešim to skupino?';

  @override
  String get duplicatesScreenKeptTakesOver =>
      'Ohranjena fotografija prevzame albume, oznake, priljubljenost, opis, oceno, lokacijo in imena oseb od drugih. Te gredo v koš in jih je mogoče obnoviti.';

  @override
  String get duplicatesScreenResolve => 'Razreši';

  @override
  String get duplicatesScreenResolved => 'Razrešeno. Kopije so v košu.';

  @override
  String get duplicatesScreenActionFailed => 'Dejanje ni uspelo.';

  @override
  String get duplicatesScreenResolveEveryIdentical =>
      'Razrešim vse enake slike?';

  @override
  String get duplicatesScreenResolveAllDuplicates => 'Razrešim vse dvojnike?';

  @override
  String duplicatesScreenResolveAllBody(
    String groups,
    String trashed,
    String size,
  ) {
    return 'Skupine: $groups. $trashed fotografij gre v koš, kar sprosti $size, ko se ta izprazni. V vsaki skupini ostane predlagana fotografija in prevzame, kar so imele druge.';
  }

  @override
  String get duplicatesScreenResolveAll => 'Razreši vse';

  @override
  String get duplicatesScreenSamePicture => 'Enaka slika';

  @override
  String get duplicatesScreenAlike => 'Podobne';

  @override
  String duplicatesScreenProposedToKeep(String reason, String size) {
    return 'Predlagano za ohranitev: $reason · sprosti $size';
  }

  @override
  String get duplicatesScreenNotDuplicates => 'Niso dvojniki';

  @override
  String duplicatesScreenResolveToTrash(String count) {
    return 'Razreši ($count v koš)';
  }

  @override
  String get duplicatesScreenTitle => 'Dvojniki';

  @override
  String get duplicatesScreenLoadFailed => 'Dvojnikov ni bilo mogoče naložiti.';

  @override
  String duplicatesScreenPending(String count) {
    return 'Fotografije, ki se še primerjajo: $count.';
  }

  @override
  String get duplicatesScreenNoneFound =>
      'Podobnih fotografij ni bilo mogoče najti.';

  @override
  String get duplicatesScreenTickWhatToKeep =>
      'Označi, kaj ohraniti. To so le predlogi in brez tvoje potrditve se nič ne odstrani.';

  @override
  String duplicatesScreenShowing(String shown, String total) {
    return 'Prikazano $shown od $total.';
  }

  @override
  String duplicatesScreenResolving(String done, String total) {
    return 'Razreševanje dvojnikov: $done od $total';
  }

  @override
  String duplicatesScreenResolveIdentical(String count) {
    return 'Razreši enake ($count)';
  }

  @override
  String duplicatesScreenResolveAllAsProposed(String count) {
    return 'Razreši vse po predlogu ($count)';
  }

  @override
  String get duplicatesScreenStackLoadFailed =>
      'Tega sklada ni bilo mogoče naložiti.';

  @override
  String get duplicatesScreenSplitStack => 'Razdeli sklad';

  @override
  String get duplicatesScreenMakeMain => 'Nastavi kot glavni posnetek';

  @override
  String accountSheetVersionBuild(String version, String build) {
    return '$version gradnja $build';
  }

  @override
  String get accountSheetEditProfile => 'Uredi profil';

  @override
  String get accountSheetClose => 'Zapri';

  @override
  String accountSheetPhotosAndVideos(String count) {
    return '$count fotografij in videoposnetkov';
  }

  @override
  String accountSheetUsed(String size) {
    return '$size zasedeno';
  }

  @override
  String accountSheetFilesFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count datotek ni bilo mogoče obdelati',
      few: '$count datotek ni bilo mogoče obdelati',
      two: '$count datotek ni bilo mogoče obdelati',
      one: '$count datoteke ni bilo mogoče obdelati',
    );
    return '$_temp0';
  }

  @override
  String get accountSheetAppearance => 'Videz';

  @override
  String get accountSheetDark => 'Temno';

  @override
  String get accountSheetLight => 'Svetlo';

  @override
  String get accountSheetSystem => 'Sistem';

  @override
  String get accountSheetServerDisk => 'Disk strežnika';

  @override
  String get accountSheetLoading => 'Nalaganje…';

  @override
  String get accountSheetServerNoAnswer => 'Strežnik se ne odziva.';

  @override
  String accountSheetDiskUsed(String used, String total) {
    return 'Zasedeno $used od $total';
  }

  @override
  String get accountSheetAppVersion => 'Različica aplikacije';

  @override
  String get accountSheetServerVersion => 'Različica strežnika';

  @override
  String get accountSheetNewVersion => 'Nova različica';

  @override
  String accountSheetIsAvailable(String version) {
    return '$version je na voljo';
  }

  @override
  String get accountSheetServer => 'Strežnik';

  @override
  String get accountSheetServerAddress => 'Naslov strežnika';

  @override
  String get accountSheetFreeUpSpace => 'Sprosti prostor';

  @override
  String get accountSheetProfile => 'Profil';

  @override
  String get accountSheetSignInOnAnotherDevice => 'Prijava v drugi napravi';

  @override
  String get accountSheetBackupDevices => 'Naprave za varnostno kopiranje';

  @override
  String get accountSheetImport => 'Uvoz';

  @override
  String get accountSheetAdministration => 'Skrbništvo';

  @override
  String get accountSheetBackup => 'Varnostna kopija';

  @override
  String get accountSheetAllBackupDevices =>
      'Vse naprave za varnostno kopiranje';

  @override
  String get accountSheetStorageTemplate => 'Predloga shranjevanja';

  @override
  String get accountSheetSettings => 'Nastavitve';

  @override
  String get accountSheetSignOut => 'Odjava';

  @override
  String get accountSheetDocumentation => 'Dokumentacija';

  @override
  String get accountSheetLicenses => 'Licence';

  @override
  String get searchFiltersSheetFilters => 'Filtri';

  @override
  String get searchFiltersSheetDate => 'Datum';

  @override
  String get searchFiltersSheetFrom => 'Od';

  @override
  String get searchFiltersSheetTo => 'Do';

  @override
  String get searchFiltersSheetType => 'Vrsta';

  @override
  String get searchFiltersSheetAll => 'Vse';

  @override
  String get searchFiltersSheetPhotos => 'Fotografije';

  @override
  String get searchFiltersSheetVideos => 'Videoposnetki';

  @override
  String get searchFiltersSheetPeople => 'Osebe';

  @override
  String get searchFiltersSheetAnyOfThem =>
      'Katera koli od njih, ne vse skupaj';

  @override
  String get searchFiltersSheetWhereAndWith => 'Kje in s čim';

  @override
  String get searchFiltersSheetPlace => 'Kraj';

  @override
  String get searchFiltersSheetCamera => 'Fotoaparat';

  @override
  String get searchFiltersSheetLens => 'Objektiv';

  @override
  String get searchFiltersSheetRating => 'Ocena';

  @override
  String get searchFiltersSheetAnyRating => 'Katera koli';

  @override
  String get searchFiltersSheetTags => 'Oznake';

  @override
  String get searchFiltersSheetAlbum => 'Album';

  @override
  String get searchFiltersSheetAnyAlbum => 'Kateri koli';

  @override
  String get searchFiltersSheetInNoAlbum => 'V nobenem albumu';

  @override
  String get searchFiltersSheetFavouritesOnly => 'Samo priljubljene';

  @override
  String get searchFiltersSheetClear => 'Počisti';

  @override
  String get searchFiltersSheetApply => 'Uporabi';

  @override
  String get adminEmailPortNumber => 'Vrata morajo biti število.';

  @override
  String get adminEmailSaved => 'Nastavitve e-pošte so shranjene.';

  @override
  String get adminEmailTestSent => 'Poslano ti je bilo preizkusno sporočilo.';

  @override
  String get adminEmailTitle => 'E-pošta';

  @override
  String get adminEmailSendEmail => 'Pošiljaj e-pošto';

  @override
  String get adminEmailSmtpServer => 'Strežnik SMTP';

  @override
  String get adminEmailPort => 'Vrata';

  @override
  String get adminEmailEncryption => 'Šifriranje';

  @override
  String get adminEmailNone => 'Brez';

  @override
  String get adminEmailUserName => 'Uporabniško ime';

  @override
  String get adminEmailPassword => 'Geslo';

  @override
  String get adminEmailPasswordSaved => 'Geslo je shranjeno. Prazno ga ohrani.';

  @override
  String get adminEmailFrom => 'Pošiljatelj';

  @override
  String get adminEmailServerAddress => 'Naslov tega strežnika';

  @override
  String get adminEmailForLinks => 'Za povezave v sporočilih';

  @override
  String get adminEmailSave => 'Shrani';

  @override
  String get adminEmailSendTest => 'Pošlji preizkusno sporočilo';

  @override
  String photoEditorScreenActionFailed(String reason) {
    return 'Dejanje ni uspelo. $reason';
  }

  @override
  String get photoEditorScreenEdit => 'Uredi';

  @override
  String get photoEditorScreenRotate => 'Zasukaj';

  @override
  String get photoEditorScreenBrightness => 'Svetlost';

  @override
  String get photoEditorScreenContrast => 'Kontrast';

  @override
  String get photoEditorScreenSaturation => 'Nasičenost';

  @override
  String get photoEditorScreenNoFilter => 'Brez filtra';

  @override
  String get photoEditorScreenBlackAndWhite => 'Črno-belo';

  @override
  String get photoEditorScreenWarm => 'Toplo';

  @override
  String get photoEditorScreenCool => 'Hladno';

  @override
  String get photoEditorScreenVintage => 'Starinsko';

  @override
  String get photoEditorScreenVivid => 'Živo';

  @override
  String get photoEditorScreenBackToOriginal => 'Nazaj na izvirnik';

  @override
  String get photoEditorScreenSave => 'Shrani';

  @override
  String get homeWidgetScreenHowToIos =>
      'Nato pridrži prazno mesto na začetnem zaslonu, tapni + (ali Uredi, Dodaj pripomoček) in izberi Mediarr.';

  @override
  String get homeWidgetScreenHowToAndroid =>
      'Nato pridrži prazno mesto na začetnem zaslonu, tapni Pripomočki in povleci Mediarr nanj.';

  @override
  String get homeWidgetScreenFetchesItself =>
      'Pripomoček sam pridobi svoje fotografije in jih nekaj hrani.';

  @override
  String get homeWidgetScreenFetching => 'Pridobivanje fotografij…';

  @override
  String homeWidgetScreenPicturesKept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotografij shranjenih zanj v tem telefonu',
      few: '$count fotografije shranjene zanj v tem telefonu',
      two: '$count fotografiji shranjeni zanj v tem telefonu',
      one: '$count fotografija shranjena zanj v tem telefonu',
    );
    return '$_temp0';
  }

  @override
  String get homeWidgetScreenDidNotWork => 'Ni uspelo.';

  @override
  String get homeWidgetScreenTitle => 'Pripomoček za začetni zaslon';

  @override
  String homeWidgetScreenIntro(String howTo) {
    return 'Pripomoček prikazuje fotografijo iz albuma, ki ga izbereš tukaj, vsako uro drugo, tudi brez povezave. $howTo';
  }

  @override
  String homeWidgetScreenShowing(String album) {
    return 'Prikazuje $album';
  }

  @override
  String get homeWidgetScreenShowsNothing =>
      'Pripomoček zdaj ne prikazuje ničesar.';

  @override
  String get homeWidgetScreenTurnOff => 'Izklopi';

  @override
  String get homeWidgetScreenAlbum => 'Album';

  @override
  String get homeWidgetScreenNoAlbums => 'Albumov še ni.';

  @override
  String homeWidgetScreenShows(String album) {
    return 'Pripomoček prikazuje $album.';
  }

  @override
  String get homeWidgetNoKey => 'Strežnik ni ustvaril ključa za pripomoček.';

  @override
  String get settingsAccentMidnightBlue => 'Polnočno modra';

  @override
  String get settingsAccentGold => 'Zlata';

  @override
  String get settingsAccentViolet => 'Vijolična';

  @override
  String get settingsAccentMint => 'Meta';

  @override
  String get settingsAccentRose => 'Rožnata';

  @override
  String get settingsThemeAuto => 'Samodejno';

  @override
  String get settingsThemeLight => 'Svetlo';

  @override
  String get settingsThemeDark => 'Temno';

  @override
  String get homeScreenMedia => 'Mediji';

  @override
  String get homeScreenSearch => 'Iskanje';

  @override
  String get homeScreenAlbums => 'Albumi';

  @override
  String get homeScreenLibrary => 'Knjižnica';

  @override
  String get homeScreenAdd => 'Dodaj';

  @override
  String homeScreenAddUploading(String count) {
    return 'Dodaj, nalaganje: $count';
  }

  @override
  String get panoramaViewCannotBeShown => 'Panorame ni mogoče prikazati.';

  @override
  String get panoramaViewLabel => 'Panorama 360°';

  @override
  String fixSheetChanged(int changed) {
    return 'Spremenjeno: $changed';
  }

  @override
  String get fixSheetCameraClockWrong => 'Ko je bila ura fotoaparata napačna.';

  @override
  String get fixSheetEarlier => 'Prej';

  @override
  String get fixSheetLater => 'Pozneje';

  @override
  String get fixSheetDays => 'Dnevi';

  @override
  String get fixSheetHours => 'Ure';

  @override
  String get fixSheetMinutes => 'Minute';

  @override
  String get fixSheetOneDateForAll =>
      'En datum za vse, z minuto razmika, da ostane vrstni red.';

  @override
  String get fixSheetChooseDateTime => 'Izberi datum in čas';

  @override
  String get fixSheetTripHint =>
      'Ko je fotoaparat na potovanju ohranil domači čas.';

  @override
  String get fixSheetCameraClockWasOn => 'Ura fotoaparata je bila na';

  @override
  String get fixSheetTheyWereTakenIn => 'Posnete so bile v';

  @override
  String get fixSheetZoneFromPlaceHint =>
      'Fotografije z lokacijo dobijo časovni pas kraja, vključno s poletnim časom; ura ostane, kot je bila.';

  @override
  String get fixSheetDatesByHandRemoved =>
      'Ročno nastavljeni datumi se odstranijo.';

  @override
  String get fixSheetNeighboursHint =>
      'Fotografije brez lokacije dobijo kraj fotografije z lokacijo, posnete najbliže njim.';

  @override
  String get fixSheetAtMostMinutesApart => 'Največ minut razmika';

  @override
  String get fixSheetTrackHint =>
      'Fotografije brez lokacije dobijo kraj iz sledi v trenutku, ko so bile posnete. Najprej popravi datum.';

  @override
  String get fixSheetChooseGpx => 'Izberi datoteko GPX';

  @override
  String get fixSheetFindPlace => 'Poišči kraj';

  @override
  String get fixSheetLatitude => 'Zemljepisna širina';

  @override
  String get fixSheetLongitude => 'Zemljepisna dolžina';

  @override
  String get fixSheetLocationGoes =>
      'Lokacija se odstrani in ostane odstranjena.';

  @override
  String get fixSheetLocationsByHandRemoved =>
      'Ročno nastavljene lokacije se odstranijo.';

  @override
  String fixSheetDateTitle(int count) {
    return 'Datum in čas · $count';
  }

  @override
  String fixSheetLocationTitle(int count) {
    return 'Lokacija · $count';
  }

  @override
  String get fixSheetShift => 'Zamakni';

  @override
  String get fixSheetSetDate => 'Nastavi datum';

  @override
  String get fixSheetZoneFromPlace => 'Pas iz kraja';

  @override
  String get fixSheetTrip => 'Potovanje';

  @override
  String get fixSheetFromFile => 'Iz datoteke';

  @override
  String get fixSheetFromNearby => 'Iz bližnjih fotografij';

  @override
  String get fixSheetFromTrack => 'Iz sledi GPX';

  @override
  String get fixSheetSetPlace => 'Nastavi kraj';

  @override
  String get fixSheetClearLocation => 'Odstrani lokacijo';

  @override
  String fixSheetWillChange(int changed) {
    return 'Spremenjeno bo: $changed';
  }

  @override
  String fixSheetNothingToGoBy(int skipped) {
    return 'brez podatkov: $skipped';
  }

  @override
  String get fixSheetNoLocation => 'brez lokacije';

  @override
  String get fixSheetCancel => 'Prekliči';

  @override
  String get fixSheetSave => 'Shrani';

  @override
  String get adminSecurityRulesSaved => 'Pravila so shranjena.';

  @override
  String get adminSecuritySsoSaved => 'Enotna prijava je shranjena.';

  @override
  String get adminSecurityForgetTitle => 'Pozabi to napravo?';

  @override
  String adminSecurityApproveAgain(String email) {
    return '$email bo treba na njej znova odobriti.';
  }

  @override
  String get adminSecurityCancel => 'Prekliči';

  @override
  String get adminSecurityForget => 'Pozabi';

  @override
  String get adminSecurityDeviceForgotten => 'Naprava je pozabljena.';

  @override
  String get adminSecurityTitle => 'Varnost';

  @override
  String get adminSecuritySingleSignOn => 'Enotna prijava (SSO)';

  @override
  String get adminSecurityIssuer => 'Izdajatelj';

  @override
  String get adminSecurityIssuerHelp => 'Prazno izklopi enotno prijavo';

  @override
  String get adminSecurityClientId => 'ID odjemalca';

  @override
  String get adminSecurityClientSecret => 'Skrivnost odjemalca';

  @override
  String get adminSecuritySecretSaved =>
      'Skrivnost je shranjena. Prazno jo ohrani.';

  @override
  String get adminSecurityButtonLabel => 'Napis na gumbu';

  @override
  String get adminSecurityAutoCreate => 'Ustvari račun ob prvi prijavi';

  @override
  String get adminSecurityLinkAdmins =>
      'Skrbniki se lahko prijavijo na ta način';

  @override
  String get adminSecuritySaveSso => 'Shrani enotno prijavo';

  @override
  String get adminSecurityRules => 'Pravila';

  @override
  String get adminSecurityApprovalRequired =>
      'Nove naprave morajo biti odobrene';

  @override
  String get adminSecurityAllowlist =>
      'Samo ti naslovi lahko dostopajo do strežnika';

  @override
  String adminSecurityYourAddress(String address) {
    return 'Tvoj naslov zdaj: $address';
  }

  @override
  String get adminSecurityAddresses => 'Naslovi in omrežja';

  @override
  String get adminSecurityAddressesHelp =>
      'Eden na vrstico, npr. 192.168.1.0/24';

  @override
  String get adminSecuritySaveRules => 'Shrani pravila';

  @override
  String get adminSecurityDevices => 'Naprave';

  @override
  String get adminSecurityNoDevices =>
      'Nobena naprava se še ni poskusila prijaviti.';

  @override
  String adminSecurityLastSeen(String time) {
    return 'nazadnje $time';
  }

  @override
  String get adminSecurityDeviceApproved => 'Naprava se lahko prijavi.';

  @override
  String get adminSecurityApprove => 'Odobri';

  @override
  String get adminSecurityAttempts => 'Poskusi dostopa';

  @override
  String get adminSecuritySignedIn => 'Prijavljen';

  @override
  String get adminSecurityWrongSignIn => 'Napačna prijava';

  @override
  String get adminSecurityTooManyAttempts => 'Preveč poskusov';

  @override
  String get adminSecurityAddressBlocked => 'Naslov blokiran';

  @override
  String get adminSecurityDeviceNotApproved => 'Naprava ni odobrena';

  @override
  String get adminSecurityPasswordReset => 'Ponastavitev gesla';

  @override
  String get adminSecurityNoAttempts => 'Še ni poskusov.';

  @override
  String get adminSecurityShowOlder => 'Prikaži starejše';

  @override
  String adminCommonNoAnswer(String code) {
    return 'Strežnik ni odgovoril ($code).';
  }

  @override
  String get devicesScreenQuiet => 'Tiho';

  @override
  String get devicesScreenNeedsALook => 'Potrebuje pregled';

  @override
  String get devicesScreenAllGood => 'Vse v redu';

  @override
  String devicesScreenConfirmed(String count) {
    return '$count datotek je potrdil strežnik';
  }

  @override
  String devicesScreenOfSent(String line, String files) {
    return '$line, od $files, ki jih je poslala naprava';
  }

  @override
  String devicesScreenWaiting(String count) {
    return 'čaka $count';
  }

  @override
  String devicesScreenNotSent(String count) {
    return 'ni poslano $count';
  }

  @override
  String devicesScreenInTrash(String count) {
    return 'v košu $count';
  }

  @override
  String devicesScreenGone(String count) {
    return 'ni več na strežniku $count';
  }

  @override
  String get devicesScreenNever => 'Nikoli';

  @override
  String devicesScreenDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dni',
      few: '$days dnevi',
      two: '$days dneva',
      one: '$days dan',
    );
    return '$_temp0';
  }

  @override
  String get devicesScreenNotLoaded => 'Ni naloženo.';

  @override
  String devicesScreenRemoveTitle(String name) {
    return 'Odstrani $name?';
  }

  @override
  String get devicesScreenRemoveBody =>
      'Njene fotografije ostanejo na strežniku. Če se znova oglasi, se vrne.';

  @override
  String get devicesScreenCancel => 'Prekliči';

  @override
  String get devicesScreenRemove => 'Odstrani';

  @override
  String get devicesScreenNotRemoved => 'Ni odstranjeno.';

  @override
  String get devicesScreenSaved => 'Shranjeno.';

  @override
  String get devicesScreenNotSaved => 'Ni shranjeno.';

  @override
  String devicesScreenThisPhone(String name) {
    return '$name · Ta telefon';
  }

  @override
  String devicesScreenLastReport(String time) {
    return 'zadnje poročilo $time';
  }

  @override
  String devicesScreenOnDevice(String verified, String total) {
    return '$verified od $total na napravi';
  }

  @override
  String get devicesScreenQuietWarning =>
      'Ni se oglasila dlje, kot dovoliš. Odpri Mediarr na njej in preveri, ali je varnostno kopiranje vklopljeno.';

  @override
  String get devicesScreenNothingMissing => 'Nič ne manjka.';

  @override
  String get devicesScreenInTrashOnServer => 'v košu na strežniku';

  @override
  String get devicesScreenDeletedFromServer => 'izbrisano s strežnika';

  @override
  String get devicesScreenWhatIsMissing => 'Kaj manjka';

  @override
  String get devicesScreenHide => 'Skrij';

  @override
  String get devicesScreenTryingAgain => 'Poskušam znova.';

  @override
  String get devicesScreenTryAgain => 'Poskusi znova';

  @override
  String get devicesScreenAllBackupDevices =>
      'Vse naprave za varnostno kopiranje';

  @override
  String get devicesScreenBackupDevices => 'Naprave za varnostno kopiranje';

  @override
  String get devicesScreenAllIntro =>
      'Naprave vseh uporabnikov, ki varnostno kopirajo. Ko ena utihne, je njen lastnik opozorjen.';

  @override
  String get devicesScreenIntro =>
      'Telefoni, ki varnostno kopirajo, in koliko je z vsakega varno na strežniku. Šteje strežnik, iz svojih datotek.';

  @override
  String get devicesScreenDidNotLoad =>
      'Naprave se niso naložile. Povleci za ponovni poskus.';

  @override
  String get devicesScreenNoneReported => 'Nobena naprava se še ni oglasila.';

  @override
  String get devicesScreenNoneReportedTurnOn =>
      'Nobena naprava se še ni oglasila. Vklopi samodejno varnostno kopiranje v zavihku Upload.';

  @override
  String get devicesScreenWarnMeAfter => 'Opozori me po';

  @override
  String get devicesScreenWarnHelp =>
      'Obvestilo tukaj in na spletu ter po e-pošti, če je nastavljena. Enkrat, dokler se naprava znova ne oglasi.';

  @override
  String timelineScreenActionFailed(String message) {
    return 'Dejanje ni uspelo. $message';
  }

  @override
  String get timelineScreenSetVaultPin =>
      'Najprej nastavi PIN trezorja: Račun > Trezor.';

  @override
  String timelineScreenDeleteTitle(String count) {
    return 'Izbriši $count?';
  }

  @override
  String get timelineScreenTrashRestorable =>
      'Premaknejo se v koš, kjer jih je mogoče obnoviti.';

  @override
  String timelineScreenTrashDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dni',
      few: '$days dni',
      two: '$days dneva',
      one: '$days dan',
    );
    return 'Premaknejo se v koš, kjer ostanejo $_temp0 in jih je mogoče obnoviti.';
  }

  @override
  String get timelineScreenCancel => 'Prekliči';

  @override
  String get timelineScreenDelete => 'Izbriši';

  @override
  String get timelineScreenLoadFailed =>
      'Tvojih fotografij ni bilo mogoče naložiti. Preveri povezavo.';

  @override
  String get timelineScreenTryAgain => 'Poskusi znova';

  @override
  String get timelineScreenEmpty =>
      'Še ni fotografij. Dodaj prve v zavihku Upload.';

  @override
  String get timelineScreenMedia => 'Mediji';

  @override
  String get timelineScreenClearSelection => 'Počisti izbor';

  @override
  String get timelineScreenAddToAlbum => 'Dodaj v album';

  @override
  String get timelineScreenShare => 'Deli';

  @override
  String get timelineScreenAddToFavorites => 'Dodaj med priljubljene';

  @override
  String get timelineScreenMore => 'Več';

  @override
  String get timelineScreenArchive => 'Arhiviraj';

  @override
  String get timelineScreenAddTag => 'Dodaj oznako';

  @override
  String get timelineScreenDateTimeMenu => 'Datum in čas…';

  @override
  String get timelineScreenLocationMenu => 'Lokacija…';

  @override
  String get timelineScreenMoveToVault => 'Premakni v trezor';

  @override
  String timelineScreenMonthFailed(String month) {
    return '$month se ni naložil. Poskusi znova.';
  }

  @override
  String agentProgramOnSystem(String program, String system) {
    return '$program na $system';
  }

  @override
  String get agentUnknownDevice => 'Neznana naprava';

  @override
  String get agentMediarrApp => 'Aplikacija Mediarr';

  @override
  String get agentNow => 'zdaj';

  @override
  String agentMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pred $count minutami',
      few: 'pred $count minutami',
      two: 'pred $count minutama',
      one: 'pred $count minuto',
    );
    return '$_temp0';
  }

  @override
  String agentHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pred $count urami',
      few: 'pred $count urami',
      two: 'pred $count urama',
      one: 'pred $count uro',
    );
    return '$_temp0';
  }

  @override
  String agentDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pred $count dnevi',
      few: 'pred $count dnevi',
      two: 'pred $count dnevoma',
      one: 'pred $count dnevom',
    );
    return '$_temp0';
  }

  @override
  String agentWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pred $count tedni',
      few: 'pred $count tedni',
      two: 'pred $count tednoma',
      one: 'pred $count tednom',
    );
    return '$_temp0';
  }

  @override
  String agentMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pred $count meseci',
      few: 'pred $count meseci',
      two: 'pred $count mesecema',
      one: 'pred $count mesecem',
    );
    return '$_temp0';
  }

  @override
  String agentYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pred $count leti',
      few: 'pred $count leti',
      two: 'pred $count letoma',
      one: 'pred $count letom',
    );
    return '$_temp0';
  }

  @override
  String get slideshowScreenCrossfade => 'Pretapljanje';

  @override
  String get slideshowScreenSlide => 'Drsenje';

  @override
  String get slideshowScreenSlowZoom => 'Počasna povečava';

  @override
  String get slideshowScreenNone => 'Brez';

  @override
  String get slideshowScreenSettings => 'Nastavitve diaprojekcije';

  @override
  String get slideshowScreenPace => 'Tempo';

  @override
  String get slideshowScreenTransition => 'Prehod';

  @override
  String get slideshowScreenShuffle => 'Naključno';

  @override
  String get slideshowScreenLoop => 'Ponavljaj';

  @override
  String get slideshowScreenDateAndPlace => 'Datum in kraj';

  @override
  String get slideshowScreenTheEnd => 'Konec.';

  @override
  String get slideshowScreenPrevious => 'Prejšnja';

  @override
  String get slideshowScreenPlay => 'Predvajaj';

  @override
  String get slideshowScreenPause => 'Premor';

  @override
  String get slideshowScreenNext => 'Naslednja';

  @override
  String get slideshowScreenClose => 'Zapri';

  @override
  String notificationsAlbumShared(String subject) {
    return 'Z tabo je bil deljen »$subject«';
  }

  @override
  String notificationsImportDone(String subject) {
    return 'Uvoz iz $subject je končan';
  }

  @override
  String notificationsImportFailed(String subject) {
    return 'Uvoz iz $subject ni uspel';
  }

  @override
  String notificationsDeviceQuiet(String subject) {
    return '$subject ne varnostno kopira več';
  }

  @override
  String notificationsCopyForLate(String name) {
    return 'Kopija za $name že tri dni ni bila poslana';
  }

  @override
  String notificationsCopyFromLate(String name) {
    return 'Kopija od $name že tri dni ni prispela';
  }

  @override
  String notificationsBackupFailed(String subject) {
    return 'Varnostno kopiranje ni uspelo: $subject';
  }

  @override
  String get notificationsTitle => 'Obvestila';

  @override
  String get notificationsNotRemoved => 'Tega ni bilo mogoče odstraniti.';

  @override
  String get notificationsNotLoaded => 'Tega ni bilo mogoče naložiti.';

  @override
  String get notificationsNone => 'Ni obvestil.';

  @override
  String get notificationsRemove => 'Odstrani';

  @override
  String assetFactsNotSaved(String message) {
    return 'Ni shranjeno. $message';
  }

  @override
  String get assetFactsEditDetails => 'Uredi podrobnosti';

  @override
  String get assetFactsDateAndTime => 'Datum in čas';

  @override
  String get assetFactsFindPlace => 'Poišči kraj';

  @override
  String get assetFactsLatitude => 'Zemljepisna širina';

  @override
  String get assetFactsLongitude => 'Zemljepisna dolžina';

  @override
  String get assetFactsDescription => 'Opis';

  @override
  String get assetFactsUseFile => 'Uporabi podatke iz datoteke';

  @override
  String get assetFactsCancel => 'Prekliči';

  @override
  String get assetFactsSave => 'Shrani';

  @override
  String assetFactsStars(String stars) {
    return '$stars od 5 zvezdic';
  }

  @override
  String get documentsScreenNotEnabled => 'Skrbnik tega albuma ni vklopil.';

  @override
  String get documentsScreenNeedsAnalysis =>
      'Za to mora biti vklopljena analiza slik.';

  @override
  String get documentsScreenNoText => 'Še ni fotografij z besedilom.';

  @override
  String get documentsScreenLoadFailed => 'Dokumentov ni bilo mogoče naložiti.';

  @override
  String get documentsScreenTitle => 'Dokumenti';

  @override
  String get sharingNoPhotoAccess =>
      'Mediarr ne sme dodajati fotografij v ta telefon';

  @override
  String get backupNoDeviceKey => 'Strežnik ni ustvaril ključa naprave.';

  @override
  String get foldersScreenFolders => 'Mape';

  @override
  String get foldersScreenLoadFailed => 'Mape ni bilo mogoče naložiti.';

  @override
  String get foldersScreenNoExternalLibrary =>
      'Nimate zunanje knjižnice. Skrbnik jo nastavi v nastavitvah.';

  @override
  String get foldersScreenEmpty => 'Ta mapa je prazna.';

  @override
  String get searchQueryNoName => 'Brez imena';

  @override
  String get searchQueryVideos => 'Videoposnetki';

  @override
  String get searchQueryPhotos => 'Fotografije';

  @override
  String searchQueryInAlbum(String title) {
    return 'V albumu: $title';
  }

  @override
  String get searchQueryInNoAlbum => 'Ni v albumu';

  @override
  String get searchQueryFavourites => 'Priljubljene';

  @override
  String get exploreScreenExplore => 'Raziskuj';

  @override
  String get exploreScreenPeople => 'Osebe';

  @override
  String get exploreScreenPlaces => 'Kraji';

  @override
  String get exploreScreenMemories => 'Spomini';

  @override
  String get exploreScreenPeopleFailed => 'Oseb ni bilo mogoče naložiti.';

  @override
  String get exploreScreenNoNamedPeople => 'Še ni oseb z imenom.';

  @override
  String get exploreScreenPlacesFailed => 'Krajev ni bilo mogoče naložiti.';

  @override
  String get exploreScreenNoPlaces => 'Še ni fotografij s krajem.';

  @override
  String get exploreScreenMemoriesFailed => 'Spominov ni bilo mogoče naložiti.';

  @override
  String get exploreScreenNoMemories => 'Danes ni spominov.';

  @override
  String get exploreScreenAllPeople => 'Vse osebe';

  @override
  String get exploreScreenAllPlaces => 'Vsi kraji';

  @override
  String get exploreScreenAllMemories => 'Vsi spomini';

  @override
  String sharedScreenActionFailed(String reason) {
    return 'Dejanje ni uspelo. $reason';
  }

  @override
  String get sharedScreenWholeLibrary => 'Celotna knjižnica';

  @override
  String sharedScreenFrom(String date) {
    return 'Od $date';
  }

  @override
  String get sharedScreenLoadFailed =>
      'Tega ni bilo mogoče naložiti. Preveri povezavo.';

  @override
  String get sharedScreenTryAgain => 'Poskusi znova';

  @override
  String get sharedScreenAlbumsWithMe => 'Albumi, deljeni z mano';

  @override
  String get sharedScreenNothingShared => 'Še nič ni deljeno.';

  @override
  String get sharedScreenLibrariesWithMe => 'Knjižnice, deljene z mano';

  @override
  String get sharedScreenNobodyShares =>
      'Nihče ne deli svoje knjižnice s tabo.';

  @override
  String get sharedScreenShowInMyMedia => 'Prikaži v mojih Medijih';

  @override
  String get sharedScreenMyLibrarySharedWith => 'Moja knjižnica je deljena z';

  @override
  String get sharedScreenNobodyYet => 'Še nihče.';

  @override
  String get sharedScreenStop => 'Ustavi';

  @override
  String get sharedScreenUser => 'Uporabnik';

  @override
  String get sharedScreenChooseDate => 'Izberi datum';

  @override
  String get sharedScreenNeverShared =>
      'Arhiv, koš in trezor se nikoli ne delijo.';

  @override
  String get sharedScreenShareMyLibrary => 'Deli mojo knjižnico';

  @override
  String get sharedScreenShared => 'Deljeno';

  @override
  String get sharedScreenLibraryNotAvailable => 'Ta knjižnica ni na voljo.';

  @override
  String get sharedScreenNoPhotos => 'Še ni fotografij.';

  @override
  String get loginScreenEnterServerFirst =>
      'Najprej vnesi naslov svojega strežnika.';

  @override
  String get loginScreenAllowOnCodeScreen =>
      'Dovoli to prijavo na zaslonu, ki prikazuje kodo.';

  @override
  String get loginScreenCancel => 'Prekliči';

  @override
  String get loginScreenEnterTotp =>
      'Vnesite 6-mestno kodo iz aplikacije za preverjanje pristnosti.';

  @override
  String get loginScreenSignInToServer => 'Prijavi se v svoj strežnik Mediarr.';

  @override
  String get loginScreenCode => 'Koda';

  @override
  String get loginScreenServerAddress => 'Naslov strežnika';

  @override
  String get loginScreenEmail => 'E-pošta';

  @override
  String get loginScreenPassword => 'Geslo';

  @override
  String get loginScreenVerify => 'Potrdi';

  @override
  String get loginScreenSignIn => 'Prijavi se';

  @override
  String get loginScreenSingleSignOn => 'Uporabi enotno prijavo (SSO)';

  @override
  String get loginScreenScanQr => 'Skeniraj kodo QR';

  @override
  String get loginScreenEnterSignInCode => 'Vnesi kodo za prijavo';

  @override
  String get loginScreenSignInCode => 'Koda za prijavo';

  @override
  String get qrSignInScanTitle => 'Skeniraj kodo za prijavo';

  @override
  String get qrSignInScanHelp =>
      'Na zaslonu, kjer si prijavljen, odpri meni računa in izberi »Prijava na telefonu«.';

  @override
  String get qrSignInLooking => 'Iščem strežnike v tem omrežju …';

  @override
  String get qrSignInNoneFound => 'V tem omrežju ni strežnika.';

  @override
  String get qrSignInOnThisNetwork => 'V tem omrežju';

  @override
  String get qrSignInLookAgain => 'Išči znova';

  @override
  String get qrSignInMakeCodeFailed => 'Kode ni bilo mogoče ustvariti.';

  @override
  String get qrSignInTheDevice => 'naprava';

  @override
  String get qrSignInTitle => 'Prijava v drugi napravi';

  @override
  String get qrSignInHowTo =>
      'V aplikaciji Mediarr na drugi napravi na zaslonu za prijavo tapni »Skeniraj kodo QR«.';

  @override
  String get qrSignInQrLabel => 'Koda QR za prijavo';

  @override
  String get qrSignInOrType => 'Ali vnesi kodo';

  @override
  String qrSignInValidFor(String time) {
    return 'Veljavna še $time';
  }

  @override
  String qrSignInAllowOn(String device) {
    return 'Dovolim prijavo: $device?';
  }

  @override
  String get qrSignInAllowOnlyIf =>
      'Dovoli samo, če si kodo pravkar skeniral v svoji napravi.';

  @override
  String get qrSignInDeny => 'Zavrni';

  @override
  String get qrSignInAllow => 'Dovoli';

  @override
  String qrSignInSignedIn(String device) {
    return 'Prijavljeno: $device. Prikazano je pod Račun → Naprave.';
  }

  @override
  String get qrSignInDone => 'Končano';

  @override
  String get qrSignInDenied => 'Prijava je bila zavrnjena.';

  @override
  String get qrSignInExpired => 'Koda je potekla.';

  @override
  String get qrSignInNewCode => 'Nova koda';

  @override
  String get uploadScreenChoose =>
      'Izberi fotografije in videoposnetke s te naprave, da jih naložiš.';

  @override
  String get uploadScreenOpenLibrary => 'Odpri galerijo';

  @override
  String get uploadScreenNeedsAccess =>
      'Mediarr potrebuje dostop do tvojih fotografij. Dovoli ga v nastavitvah.';

  @override
  String get uploadScreenOpenSettings => 'Odpri nastavitve';

  @override
  String get uploadScreenNoPhotos => 'Na tej napravi ni fotografij.';

  @override
  String uploadScreenUploadCount(String count) {
    return 'Naloži $count';
  }

  @override
  String get uploadScreenQueued => 'V čakalni vrsti';

  @override
  String get uploadScreenPreparing => 'Pripravljam';

  @override
  String get uploadScreenUploaded => 'Naloženo';

  @override
  String get uploadScreenAlreadyOnServer => 'Že na strežniku';

  @override
  String get uploadScreenFailed => 'Ni uspelo';

  @override
  String uploadScreenFinished(String done, String total) {
    return 'Končano $done od $total';
  }

  @override
  String get uploadScreenClearFailed => 'Počisti neuspele';

  @override
  String get uploadScreenPhoto => 'Fotografija';

  @override
  String get backupCardNothingYet => 'Še nič ni varnostno kopirano.';

  @override
  String get backupCardLastJustNow => 'Zadnja datoteka kopirana pravkar.';

  @override
  String backupCardLastMinutes(String minutes) {
    return 'Zadnja datoteka kopirana pred $minutes min.';
  }

  @override
  String backupCardLastHours(String hours) {
    return 'Zadnja datoteka kopirana pred $hours h.';
  }

  @override
  String backupCardLastDays(String days) {
    return 'Zadnja datoteka kopirana pred $days d.';
  }

  @override
  String backupCardScopeTitle(String album) {
    return 'Varnostno kopiraj »$album«';
  }

  @override
  String get backupCardScopeBody =>
      'Naj se pošljejo tudi fotografije, ki so že v tem albumu? Kar je že na strežniku, se nikoli ne pošlje dvakrat.';

  @override
  String get backupCardOnlyNew => 'Samo fotografije, dodane od zdaj';

  @override
  String get backupCardAlsoExisting => 'Tudi tiste, ki so zdaj v njem';

  @override
  String get backupCardTheAddedAlbums => 'dodani albumi';

  @override
  String get backupCardNeedsFullAccess =>
      'Albumi potrebujejo dostop do vseh fotografij. Dovoli ga v nastavitvah: Mediarr > Fotografije > Poln dostop.';

  @override
  String backupCardServerUnreachable(String reason) {
    return 'Strežnik ni dosegljiv. $reason';
  }

  @override
  String get backupCardAutomaticBackup => 'Samodejna varnostna kopija';

  @override
  String backupCardAlbum(String name) {
    return 'Album: $name';
  }

  @override
  String get backupCardChange => 'Spremeni';

  @override
  String get backupCardNeedsFullAccessNothingSent =>
      'Albumi potrebujejo dostop do vseh fotografij. Dovoli ga v nastavitvah: Mediarr > Fotografije > Poln dostop. Nič se ne pošilja.';

  @override
  String get backupCardNoSuchAlbum =>
      'Na napravi ni albuma s tem imenom. Nič se ne pošilja.';

  @override
  String backupCardMoreAlbums(String more, String never) {
    return 'Več albumov: $more, nikoli poslano: $never';
  }

  @override
  String get backupCardOnlyWifi => 'Samo prek Wi-Fi';

  @override
  String get backupCardOnlyCharging => 'Samo med polnjenjem';

  @override
  String backupCardVerified(String verified, String total) {
    return '$verified od $total potrjenih na strežniku';
  }

  @override
  String backupCardCounts(String sending, String waiting, String failed) {
    return '$sending se pošilja · $waiting čaka · $failed ni uspelo';
  }

  @override
  String get backupCardPerDevice => 'Kaj strežnik potrdi, po napravah';

  @override
  String get backupCardRefused =>
      'Strežnik je zavrnil to napravo. Izklopi in znova vklopi varnostno kopiranje.';

  @override
  String get backupCardFreeUpSpace => 'Sprosti prostor';

  @override
  String backupCardRetryFailed(String count) {
    return 'Znova poskusi $count neuspelih';
  }

  @override
  String get backupCardOffHelp =>
      'Pošlje en album po tvoji izbiri in nič drugega. Nove fotografije išče vsako minuto, ko je aplikacija odprta. Ko je zaprta, iOS odloči kdaj, pogosto veliko pozneje, in jo ustavi, če aplikacijo odrineš.';

  @override
  String get backupCardWhichAlbum => 'Kateri album?';

  @override
  String get backupCardAlbumName => 'Ime albuma';

  @override
  String backupCardUseName(String name) {
    return 'Uporabi ime »$name«';
  }

  @override
  String get backupCardStartsWhenExists =>
      'Začne se, ko obstaja album s tem imenom';

  @override
  String get backupCardNoAlbums =>
      'Na tej napravi še ni albumov. Ustvari ga v Fotografijah.';

  @override
  String get backupCardNeverHelp =>
      'Fotografija v albumu »Nikoli« se ne pošlje, tudi če je tudi v drugem albumu.';

  @override
  String get backupCardNotAdded => 'Ni dodan';

  @override
  String get backupCardBackUp => 'Varnostno kopiraj';

  @override
  String get backupCardNever => 'Nikoli';

  @override
  String get backupCardSave => 'Shrani';

  @override
  String get albumSheetsOwner => 'Lastnik';

  @override
  String get albumSheetsEditor => 'Urednik';

  @override
  String get albumSheetsContributor => 'Sodelavec';

  @override
  String get albumSheetsViewer => 'Gledalec';

  @override
  String get albumSheetsUploadOnly => 'samo nalaganje';

  @override
  String get albumSheetsPassword => 'geslo';

  @override
  String get albumSheetsWatermarkFact => 'vodni žig';

  @override
  String albumSheetsExpiresFact(String date) {
    return 'poteče $date';
  }

  @override
  String albumSheetsDownloadsFact(String count) {
    return 'prenosi: $count';
  }

  @override
  String get albumSheetsActionFailed => 'Dejanje ni uspelo.';

  @override
  String get albumSheetsComments => 'Komentarji';

  @override
  String get albumSheetsCommentsAndHearts => 'Komentarji in srčki';

  @override
  String get albumSheetsCommentsFailed =>
      'Komentarjev ni bilo mogoče naložiti.';

  @override
  String get albumSheetsHeart => 'Srce';

  @override
  String get albumSheetsNoComments => 'Še ni komentarjev.';

  @override
  String get albumSheetsDeleteComment => 'Izbriši komentar';

  @override
  String get albumSheetsComment => 'Komentar';

  @override
  String get albumSheetsSend => 'Pošlji';

  @override
  String get albumSheetsAddToAlbum => 'Dodaj v album';

  @override
  String get albumSheetsAlbumsFailed => 'Albumov ni bilo mogoče naložiti.';

  @override
  String get albumSheetsNewAlbum => 'Nov album';

  @override
  String get albumSheetsCreateAndAdd => 'Ustvari in dodaj';

  @override
  String get albumSheetsShareWithUsers => 'Deli z uporabniki';

  @override
  String get albumSheetsSharingFailed => 'Deljenja ni bilo mogoče naložiti.';

  @override
  String get albumSheetsNotShared => 'Ta album še ni deljen.';

  @override
  String get albumSheetsRemove => 'Odstrani';

  @override
  String get albumSheetsNoOtherUsers =>
      'Na tem strežniku ni drugih uporabnikov.';

  @override
  String get albumSheetsUser => 'Uporabnik';

  @override
  String get albumSheetsRole => 'Vloga';

  @override
  String get albumSheetsAdd => 'Dodaj';

  @override
  String get albumSheetsPublicLinks => 'Javne povezave';

  @override
  String get albumSheetsCopyNow =>
      'Kopirajte naslov zdaj: pozneje ga ni več mogoče prikazati.';

  @override
  String get albumSheetsCopy => 'Kopiraj';

  @override
  String get albumSheetsLinksFailed => 'Povezav ni bilo mogoče naložiti.';

  @override
  String get albumSheetsUnnamedLink => 'Neimenovana povezava';

  @override
  String get albumSheetsRevoke => 'Prekliči';

  @override
  String get albumSheetsName => 'Ime';

  @override
  String get albumSheetsPasswordOptional => 'Geslo (neobvezno)';

  @override
  String get albumSheetsNoExpiry => 'Brez poteka';

  @override
  String albumSheetsExpires(String date) {
    return 'Poteče $date';
  }

  @override
  String get albumSheetsChoose => 'Izberi';

  @override
  String get albumSheetsDownloadLimit => 'Omejitev prenosov';

  @override
  String get albumSheetsWatermark => 'Vodni žig';

  @override
  String get albumSheetsWatermarkHelp =>
      'Vodni žig izklopi prenos izvirnikov in predvajanje videoposnetkov.';

  @override
  String get albumSheetsAllowDownloads => 'Dovoli prenose';

  @override
  String get albumSheetsShowLocation => 'Prikaži lokacijo';

  @override
  String get albumSheetsGuestsCanAdd => 'Gostje lahko dodajajo fotografije';

  @override
  String get albumSheetsUploadOnlyLong =>
      'Samo nalaganje (gostje ne vidijo albuma)';

  @override
  String get albumSheetsCreateLink => 'Ustvari povezavo';

  @override
  String get albumSheetsFromAnyDate => 'Od kateregakoli datuma';

  @override
  String albumSheetsFrom(String date) {
    return 'Od $date';
  }

  @override
  String get albumSheetsToAnyDate => 'Do kateregakoli datuma';

  @override
  String albumSheetsTo(String date) {
    return 'Do $date';
  }

  @override
  String get albumSheetsKind => 'Vrsta';

  @override
  String get albumSheetsAll => 'Vse';

  @override
  String get albumSheetsPhotos => 'Fotografije';

  @override
  String get albumSheetsVideos => 'Videoposnetki';

  @override
  String get albumSheetsLivePhoto => 'Live Photo';

  @override
  String get albumSheetsCamera => 'Fotoaparat';

  @override
  String get albumSheetsPerson => 'Oseba';

  @override
  String get albumSheetsTag => 'Oznaka';

  @override
  String get albumSheetsPlace => 'Kraj';

  @override
  String get viewerScreenDeleteTitle => 'Izbrišem to fotografijo?';

  @override
  String get viewerScreenTrashNoDays =>
      'Premakne se v koš, kjer ga je mogoče obnoviti.';

  @override
  String viewerScreenTrashDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dni',
      few: '$days dni',
      two: '$days dneva',
      one: '$days dan',
    );
    return 'Premakne se v koš, kjer ostane $_temp0 in ga je mogoče obnoviti.';
  }

  @override
  String get viewerScreenCancel => 'Prekliči';

  @override
  String get viewerScreenDelete => 'Izbriši';

  @override
  String get viewerScreenActionFailed => 'Dejanje ni uspelo.';

  @override
  String get viewerScreenNoVideo => 'Ta fotografija nima videoposnetka.';

  @override
  String get viewerScreenVideoFailed =>
      'Videoposnetka ni bilo mogoče naložiti.';

  @override
  String get viewerScreenStackShots => 'Posnetki v tem skladu';

  @override
  String get viewerScreenSlideshow => 'Diaprojekcija';

  @override
  String get viewerScreen360View => 'Pogled 360°';

  @override
  String get viewerScreenFlatView => 'Raven pogled';

  @override
  String get viewerScreenPlayLive => 'Predvajaj Live Photo';

  @override
  String get viewerScreenCommentsAndHearts => 'Komentarji in srčki';

  @override
  String get viewerScreenFavorite => 'Priljubljena';

  @override
  String get viewerScreenEdit => 'Uredi';

  @override
  String get viewerScreenShare => 'Deli';

  @override
  String get viewerScreenDetails => 'Podrobnosti';

  @override
  String get viewerScreenPhotoFailed =>
      'Te fotografije ni bilo mogoče naložiti.';

  @override
  String get viewerScreenCannotPlay =>
      'Tega videoposnetka ni mogoče predvajati v tej napravi.';

  @override
  String get viewerScreenDetailsFailed =>
      'Podrobnosti ni bilo mogoče naložiti.';

  @override
  String get viewerScreenUnavailable => 'Ni na voljo';

  @override
  String get viewerScreenMissingFile =>
      'Datoteka ni bila najdena ob zadnjem pregledu zunanje knjižnice. Izvirnik bo spet na voljo, ko bo datoteka vrnjena.';

  @override
  String get viewerScreenName => 'Ime';

  @override
  String get viewerScreenDescription => 'Opis';

  @override
  String get viewerScreenTaken => 'Posneto';

  @override
  String get viewerScreenAdded => 'Dodano';

  @override
  String get viewerScreenDimensions => 'Mere';

  @override
  String get viewerScreenSize => 'Velikost';

  @override
  String get viewerScreenDuration => 'Trajanje';

  @override
  String get viewerScreenCamera => 'Fotoaparat';

  @override
  String get viewerScreenLens => 'Objektiv';

  @override
  String get viewerScreenSettings => 'Nastavitve';

  @override
  String get viewerScreenLocation => 'Lokacija';

  @override
  String viewerScreenNotSaved(String reason) {
    return 'Ni shranjeno. $reason';
  }

  @override
  String get viewerScreenEditDetails => 'Uredi podrobnosti';

  @override
  String get libraryScreenTitle => 'Knjižnica';

  @override
  String get libraryScreenExplore => 'Razišči';

  @override
  String get libraryScreenShared => 'Deljeno';

  @override
  String albumScreenActionFailed(String message) {
    return 'Dejanje ni uspelo. $message';
  }

  @override
  String albumScreenRemovedAll(String count) {
    return 'Odstranjeno iz albuma: $count';
  }

  @override
  String albumScreenRemovedSome(String changed, String total) {
    return 'Odstranjeno: $changed od $total. Odstraniš lahko samo fotografije, ki si jih dodal sam.';
  }

  @override
  String get albumScreenCoverSet => 'Naslovnica je nastavljena.';

  @override
  String get albumScreenCancel => 'Prekliči';

  @override
  String get albumScreenMoveTitle => 'Premakni album';

  @override
  String get albumScreenMoveTop => 'Na vrh, med vse albume';

  @override
  String get albumScreenMoved => 'Album je premaknjen.';

  @override
  String get albumScreenUploadToAlbum => 'Naloži v album';

  @override
  String get albumScreenDeleteTitle => 'Izbrišem ta album?';

  @override
  String get albumScreenDeleteBody =>
      'Fotografije ostanejo v knjižnici. Javne povezave prenehajo delovati.';

  @override
  String get albumScreenDeleteBodyInside =>
      'Fotografije ostanejo v knjižnici. Javne povezave prenehajo delovati. Albumi v njem se premaknejo na vrh.';

  @override
  String get albumScreenDelete => 'Izbriši';

  @override
  String get albumScreenLeaveTitle => 'Zapustim ta album?';

  @override
  String get albumScreenLeaveBody =>
      'Ne boš ga več videl, razen če ga lastnik znova deli.';

  @override
  String get albumScreenLeave => 'Zapusti';

  @override
  String get albumScreenClearSelection => 'Počisti izbor';

  @override
  String get albumScreenShare => 'Deli';

  @override
  String get albumScreenSetAsCover => 'Nastavi kot naslovnico';

  @override
  String get albumScreenRemoveFromAlbum => 'Odstrani iz albuma';

  @override
  String get albumScreenSearchInAlbum => 'Išči v albumu';

  @override
  String get albumScreenComments => 'Komentarji';

  @override
  String get albumScreenMore => 'Več';

  @override
  String get albumScreenSlideshow => 'Diaprojekcija';

  @override
  String get albumScreenAddFromLibrary => 'Dodaj iz knjižnice';

  @override
  String get albumScreenUploadFromPhone => 'Naloži s tega telefona';

  @override
  String get albumScreenAlbumInside => 'Album v njem';

  @override
  String get albumScreenMoveTo => 'Premakni v…';

  @override
  String get albumScreenShareWithUsers => 'Deli z uporabniki';

  @override
  String get albumScreenPublicLinks => 'Javne povezave';

  @override
  String get albumScreenEdit => 'Uredi';

  @override
  String get albumScreenNotAvailable => 'Ta album ni na voljo.';

  @override
  String get albumScreenNoMatch => 'Nobena fotografija ne ustreza pravilom.';

  @override
  String get albumScreenEmptyCanAdd =>
      'Ta album je prazen. Dodaj fotografije iz menija.';

  @override
  String get albumScreenEmpty => 'Ta album je prazen.';

  @override
  String get albumScreenAlbumsInside => 'Albumi v njem';

  @override
  String get albumScreenNewAlbumInside => 'Nov album v njem';

  @override
  String get albumScreenName => 'Ime';

  @override
  String get albumScreenCreate => 'Ustvari';

  @override
  String albumScreenAdded(String count) {
    return 'Dodano: $count';
  }

  @override
  String get albumScreenChoosePhotos => 'Izberi fotografije';

  @override
  String get albumScreenAdd => 'Dodaj';

  @override
  String get albumScreenNoPhotosYet => 'Še ni fotografij.';

  @override
  String get albumScreenNotSaved => 'Album ni bil shranjen.';

  @override
  String get albumScreenEditAlbum => 'Uredi album';

  @override
  String get albumScreenDescription => 'Opis';

  @override
  String get albumScreenOrder => 'Vrstni red';

  @override
  String get albumScreenNewestFirst => 'Najnovejše najprej';

  @override
  String get albumScreenOldestFirst => 'Najstarejše najprej';

  @override
  String get albumScreenSave => 'Shrani';

  @override
  String get peopleScreensNoName => 'Brez imena';

  @override
  String get peopleScreensSearchFailed =>
      'Iskanje ni uspelo. Preveri povezavo.';

  @override
  String get peopleScreensDescribe =>
      'Opiši, kaj iščeš, v angleščini ali hrvaščini, ali izberi filtre.';

  @override
  String get peopleScreensSmartOff =>
      'Pametno iskanje je izklopljeno ali ni na voljo, zato se išče samo besedilo na slikah, imena datotek in filtri.';

  @override
  String peopleScreensRemoveChip(String label) {
    return 'Odstrani $label';
  }

  @override
  String get peopleScreensNothingFound => 'Nič ni bilo najdeno.';

  @override
  String get peopleScreensSearchHint => 'pes na plaži, Hvar 2024, račun…';

  @override
  String get peopleScreensAsk => 'Vprašaj';

  @override
  String get peopleScreensFilters => 'Filtri';

  @override
  String get peopleScreensSearch => 'Išči';

  @override
  String get peopleScreensLoadFailed =>
      'Oseb ni bilo mogoče naložiti. Preveri povezavo.';

  @override
  String get peopleScreensFacesOff =>
      'Prepoznavanje obrazov na tem strežniku ni vklopljeno.';

  @override
  String get peopleScreensNoneYet => 'Še ni prepoznanih oseb.';

  @override
  String get peopleScreensPeople => 'Osebe';

  @override
  String get peopleScreensShowOthers => 'Pokaži ostale';

  @override
  String get peopleScreensHiddenPeople => 'Skrite osebe';

  @override
  String get peopleScreensName => 'Ime';

  @override
  String get peopleScreensDateOfBirth => 'Datum rojstva';

  @override
  String get peopleScreensMergeWith => 'Združi z…';

  @override
  String get peopleScreensNobodyElse => 'Nikogar drugega ni.';

  @override
  String get peopleScreensMerged => 'Združeno.';

  @override
  String peopleScreensBorn(String date) {
    return 'Rojen/a $date';
  }

  @override
  String get peopleScreensShow => 'Pokaži';

  @override
  String get peopleScreensHide => 'Skrij';

  @override
  String get peopleScreensThisLoadFailed =>
      'Tega ni bilo mogoče naložiti. Preveri povezavo.';

  @override
  String get adminServerSettingsTrashDaysProblem =>
      'Koš hrani fotografije od 1 do 3650 dni.';

  @override
  String get adminServerSettingsImageQualityProblem =>
      'Kakovost slike mora biti med 40 in 100.';

  @override
  String get adminServerSettingsPreviewSizeProblem =>
      'Velikost predogleda mora biti med 720 in 4096.';

  @override
  String get adminServerSettingsVideoQualityProblem =>
      'Kakovost videa mora biti med 18 in 40, manj je bolje.';

  @override
  String get adminServerSettingsVideoHeightProblem =>
      'Največji video mora biti 720, 1080, 1440 ali 2160.';

  @override
  String get adminServerSettingsFaceScoreProblem =>
      'Kako zanesljiv mora biti obraz, je med 0,1 in 1.';

  @override
  String get adminServerSettingsFaceDistanceProblem =>
      'Kako podobna morata biti obraza, je med 0,1 in 2.';

  @override
  String get adminServerSettingsJobsProblem =>
      'Opravil v ozadju mora biti med 0 in 64.';

  @override
  String get adminServerSettingsWorkersProblem =>
      'Opravil za video in analizo mora biti med 1 in 16.';

  @override
  String get adminServerSettingsScanProblem =>
      'Interval pregleda mora biti med 1 in 720 urami.';

  @override
  String get adminServerSettingsMessageProblem =>
      'Sporočilo ob prijavi je predolgo.';

  @override
  String get adminServerSettingsNeedNumbers =>
      'Vsako številsko polje potrebuje število.';

  @override
  String get adminServerSettingsSaved => 'Nastavitve so shranjene.';

  @override
  String get adminServerSettingsTitle => 'Nastavitve strežnika';

  @override
  String get adminServerSettingsTrash => 'Koš';

  @override
  String get adminServerSettingsTrashDays =>
      'Dnevi, ko fotografije ostanejo v košu';

  @override
  String adminServerSettingsRange(String low, String high) {
    return '$low do $high';
  }

  @override
  String get adminServerSettingsPicturesAndVideos => 'Slike in videoposnetki';

  @override
  String get adminServerSettingsImageQuality => 'Kakovost slike';

  @override
  String get adminServerSettingsPreviewSize =>
      'Velikost predogleda v slikovnih pikah';

  @override
  String get adminServerSettingsVideoQuality => 'Kakovost videa';

  @override
  String get adminServerSettingsVideoQualityHelp =>
      '18 do 40, manj je boljše in večje';

  @override
  String get adminServerSettingsLargestVideo => 'Največji video';

  @override
  String get adminServerSettingsFaces => 'Obrazi';

  @override
  String get adminServerSettingsFaceScore => 'Kako zanesljiv mora biti obraz';

  @override
  String get adminServerSettingsFaceDistance =>
      'Kako podobna morata biti obraza, da sta ista oseba';

  @override
  String get adminServerSettingsBackgroundJobs => 'Opravila v ozadju';

  @override
  String get adminServerSettingsJobsAtOnce => 'Opravil hkrati';

  @override
  String get adminServerSettingsJobsAtOnceHelp =>
      '0 uporabi WORKER_CONCURRENCY; velja po ponovnem zagonu workerja';

  @override
  String get adminServerSettingsVideosAtOnce => 'Videoposnetkov hkrati';

  @override
  String get adminServerSettingsWorkersHelp =>
      '1 do 16; velja po ponovnem zagonu workerja';

  @override
  String get adminServerSettingsAnalysesAtOnce => 'Analiz hkrati';

  @override
  String get adminServerSettingsScanHours => 'Preglej zunanje mape vsakih … ur';

  @override
  String get adminServerSettingsSigningIn => 'Prijava';

  @override
  String get adminServerSettingsPasswordLogin => 'Dovoli prijavo z geslom';

  @override
  String get adminServerSettingsMaintenance => 'Način vzdrževanja';

  @override
  String get adminServerSettingsMaintenanceHelp =>
      'Strežnik lahko uporabljajo samo skrbniki';

  @override
  String get adminServerSettingsVisibleOnNetwork =>
      'Aplikacije v istem omrežju lahko najdejo ta strežnik';

  @override
  String get adminServerSettingsVisibleOnNetworkHelp =>
      'Za prijavo je še vedno potreben račun.';

  @override
  String get adminServerSettingsServerName => 'Ime strežnika';

  @override
  String get adminServerSettingsLoginMessage =>
      'Sporočilo na strani za prijavo';

  @override
  String get adminOverviewTitle => 'Pregled';

  @override
  String get adminOverviewLibrary => 'Knjižnica';

  @override
  String get adminOverviewUsers => 'Uporabniki';

  @override
  String get adminOverviewPhotos => 'Fotografije';

  @override
  String get adminOverviewVideos => 'Videoposnetki';

  @override
  String get adminOverviewProcessing => 'V obdelavi';

  @override
  String get adminOverviewFailed => 'Neuspešno';

  @override
  String get adminOverviewLibrarySize => 'Velikost knjižnice';

  @override
  String get adminOverviewDisk => 'Disk';

  @override
  String get adminOverviewFree => 'Prosto';

  @override
  String get adminOverviewTotal => 'Skupaj';

  @override
  String get adminOverviewJobs => 'Opravila';

  @override
  String get adminOverviewWaiting => 'Na čakanju';

  @override
  String get adminOverviewRunning => 'Teče';

  @override
  String get adminOverviewDone => 'Končano';

  @override
  String get adminOverviewServices => 'Storitve';

  @override
  String get adminOverviewWorker => 'Worker';

  @override
  String get adminOverviewNotRunning => 'Ne teče';

  @override
  String get adminOverviewAnalysis => 'Analiza (ML)';

  @override
  String get adminOverviewTurnedOff => 'Izklopljeno';

  @override
  String get adminOverviewDatabaseSize => 'Velikost baze';

  @override
  String get adminOverviewVersions => 'Različice';

  @override
  String get adminOverviewDatabase => 'Baza';

  @override
  String get adminJobsTitle => 'Opravila';

  @override
  String get adminJobsQueues => 'Čakalne vrste';

  @override
  String adminJobsQueueState(String queued, String running) {
    return '$queued čaka · $running teče';
  }

  @override
  String adminJobsQueueStatePaused(String queued, String running) {
    return '$queued čaka · $running teče · zaustavljeno';
  }

  @override
  String adminJobsContinues(String name) {
    return '$name se nadaljuje.';
  }

  @override
  String adminJobsIsPaused(String name) {
    return '$name je zaustavljen.';
  }

  @override
  String get adminJobsResume => 'Nadaljuj';

  @override
  String get adminJobsPause => 'Zaustavi';

  @override
  String get adminJobsFailed => 'Neuspešno';

  @override
  String get adminJobsNoneFailed => 'Nobeno opravilo ni spodletelo.';

  @override
  String get adminJobsQueuedAgain => 'Opravilo je znova v vrsti.';

  @override
  String get adminJobsTryAgain => 'Poskusi znova';

  @override
  String get freeSpaceScreenServerUnreachable =>
      'Strežnika ni bilo mogoče vprašati, zato ni ničesar za odstranitev.';

  @override
  String get freeSpaceScreenBackupUnreadable =>
      'Stanja varnostne kopije ni bilo mogoče prebrati.';

  @override
  String freeSpaceScreenRemoveTitle(String count) {
    return 'Odstranim $count s tega telefona?';
  }

  @override
  String get freeSpaceScreenRemoveBody =>
      'Ostanejo na tvojem strežniku. iPhone vpraša še enkrat in jih 30 dni hrani v Nedavno izbrisano.';

  @override
  String get freeSpaceScreenCancel => 'Prekliči';

  @override
  String get freeSpaceScreenRemove => 'Odstrani';

  @override
  String get freeSpaceScreenNotRemoved =>
      'Fotografij ni bilo mogoče odstraniti.';

  @override
  String get freeSpaceScreenNothingToRemove =>
      'Ničesar ni za odstranitev. Tu so ponujene samo fotografije, ki jih je poslala samodejna varnostna kopija.';

  @override
  String freeSpaceScreenSafe(String count) {
    return '$count je varno na tvojem strežniku, kot je pravkar potrdil z njihovimi kontrolnimi vsotami.';
  }

  @override
  String freeSpaceScreenRemoveButton(String count) {
    return 'Odstrani $count s tega telefona';
  }

  @override
  String get freeSpaceScreenTitle => 'Sprosti prostor';

  @override
  String get freeSpaceScreenWhatToKeep => 'Kaj obdržati';

  @override
  String get freeSpaceScreenAnyAge => 'Katerakoli starost';

  @override
  String get freeSpaceScreenOlderThanMonth => 'Starejše od meseca';

  @override
  String get freeSpaceScreenOlderThan3Months => 'Starejše od 3 mesecev';

  @override
  String get freeSpaceScreenOlderThanYear => 'Starejše od leta';

  @override
  String get freeSpaceScreenRemoveOnly => 'Odstrani samo';

  @override
  String get freeSpaceScreenKeepFavorites => 'Obdrži priljubljene';

  @override
  String get freeSpaceScreenKeepPhotos => 'Obdrži vse fotografije';

  @override
  String get freeSpaceScreenKeepVideos => 'Obdrži vse videoposnetke';

  @override
  String get freeSpaceScreenKeepAlbums => 'Obdrži te albume na telefonu';

  @override
  String get apiKeysScreenRead => 'Branje';

  @override
  String get apiKeysScreenUpload => 'Nalaganje';

  @override
  String get apiKeysScreenChangeAndDelete => 'Spreminjanje in brisanje';

  @override
  String apiKeysScreenExpires(String rights, String date) {
    return '$rights · poteče $date';
  }

  @override
  String get apiKeysScreenNewKey => 'Nov ključ';

  @override
  String get apiKeysScreenKeyName => 'Ime ključa';

  @override
  String get apiKeysScreenCancel => 'Prekliči';

  @override
  String get apiKeysScreenCreate => 'Ustvari';

  @override
  String apiKeysScreenCreateFailed(String message) {
    return 'Ključa ni bilo mogoče ustvariti. $message';
  }

  @override
  String get apiKeysScreenSaveItNow => 'Shrani ga zdaj';

  @override
  String get apiKeysScreenCopy => 'Kopiraj';

  @override
  String get apiKeysScreenDone => 'Končano';

  @override
  String get apiKeysScreenRevokeFailed => 'Ključa ni bilo mogoče preklicati.';

  @override
  String get apiKeysScreenTitle => 'Ključi API';

  @override
  String get apiKeysScreenLoadFailed => 'Ključev ni bilo mogoče naložiti.';

  @override
  String get apiKeysScreenEmpty =>
      'Še ni ključev. Ključ programu da samo izbrane pravice.';

  @override
  String get apiKeysScreenRevoke => 'Prekliči';

  @override
  String get memoriesScreenLastWeek => 'Zadnji teden';

  @override
  String memoriesScreenOnThisDay(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: 'Na današnji dan, pred $years leti',
      few: 'Na današnji dan, pred $years leti',
      two: 'Na današnji dan, pred $years letoma',
      one: 'Na današnji dan, pred $years letom',
    );
    return '$_temp0';
  }

  @override
  String get memoriesScreenLoadFailed =>
      'Spominov ni bilo mogoče naložiti. Preveri povezavo.';

  @override
  String get memoriesScreenTryAgain => 'Poskusi znova';

  @override
  String get memoriesScreenNoneYet => 'Še ni spominov.';

  @override
  String memoriesScreenItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementov',
      few: '$count elementi',
      two: '$count elementa',
      one: '$count element',
    );
    return '$_temp0';
  }

  @override
  String get memoriesScreenTitle => 'Spomini';

  @override
  String get memoriesScreenVideoFailed => 'Videa ni bilo mogoče narediti.';

  @override
  String get memoriesScreenVideoSaved =>
      'Video je shranjen v tvoje Fotografije.';

  @override
  String get memoriesScreenVideoNotSaved => 'Videa ni bilo mogoče shraniti.';

  @override
  String get memoriesScreenMakeVideo => 'Naredi video';

  @override
  String get layoutJanuary => 'Januar';

  @override
  String get layoutJanuaryOf => 'januarja';

  @override
  String get layoutFebruary => 'Februar';

  @override
  String get layoutFebruaryOf => 'februarja';

  @override
  String get layoutMarch => 'Marec';

  @override
  String get layoutMarchOf => 'marca';

  @override
  String get layoutApril => 'April';

  @override
  String get layoutAprilOf => 'aprila';

  @override
  String get layoutMay => 'Maj';

  @override
  String get layoutMayOf => 'maja';

  @override
  String get layoutJune => 'Junij';

  @override
  String get layoutJuneOf => 'junija';

  @override
  String get layoutJuly => 'Julij';

  @override
  String get layoutJulyOf => 'julija';

  @override
  String get layoutAugust => 'Avgust';

  @override
  String get layoutAugustOf => 'avgusta';

  @override
  String get layoutSeptember => 'September';

  @override
  String get layoutSeptemberOf => 'septembra';

  @override
  String get layoutOctober => 'Oktober';

  @override
  String get layoutOctoberOf => 'oktobra';

  @override
  String get layoutNovember => 'November';

  @override
  String get layoutNovemberOf => 'novembra';

  @override
  String get layoutDecember => 'December';

  @override
  String get layoutDecemberOf => 'decembra';

  @override
  String get layoutWeekdayMon => 'pon';

  @override
  String get layoutWeekdayTue => 'tor';

  @override
  String get layoutWeekdayWed => 'sre';

  @override
  String get layoutWeekdayThu => 'čet';

  @override
  String get layoutWeekdayFri => 'pet';

  @override
  String get layoutWeekdaySat => 'sob';

  @override
  String get layoutWeekdaySun => 'ned';

  @override
  String layoutMonthYear(String month, String year) {
    return '$month $year';
  }

  @override
  String layoutDayLabel(String weekday, String day, String month) {
    return '$weekday, $day. $month';
  }

  @override
  String layoutDateTime(
    String day,
    String month,
    String year,
    String hour,
    String minute,
  ) {
    return '$day. $month $year, $hour:$minute';
  }

  @override
  String get linkPrivacyHideFaces => 'Skrij obraze';

  @override
  String get linkPrivacyFacesNone => 'Nobenega';

  @override
  String get linkPrivacyFacesAll => 'Vse obraze';

  @override
  String get linkPrivacyFacesExcept => 'Vse razen izbranih oseb';

  @override
  String get linkPrivacyChoosePeople => 'Obrazi teh oseb ostanejo vidni:';

  @override
  String get linkPrivacyNoPeople =>
      'Nihče še nima imena. Najprej poimenuj osebe pod Osebe.';

  @override
  String get linkPrivacyPeopleFailed => 'Osebe se niso naložile.';

  @override
  String get linkPrivacyUnrecognized =>
      'Obraz, ki ni bil prepoznan, ni zamegljen.';

  @override
  String linkPrivacyUnchecked(String count, String total) {
    return '$count od $total fotografij še ni pregledanih za obraze, zato na njih ni nič zamegljeno.';
  }

  @override
  String get linkPrivacyAllChecked =>
      'Vse fotografije v albumu so pregledane za obraze.';

  @override
  String linkPrivacyVideosStill(String count) {
    return 'Videoposnetki ($count) so prikazani le kot sličica z zamegljenimi obrazi.';
  }

  @override
  String get linkPrivacyNoOriginals =>
      'Obiskovalci dobijo zamegljeno kopijo v polni velikosti, nikoli izvirnika.';

  @override
  String get linkPrivacyRemoveCamera => 'Odstrani podatke o fotoaparatu';

  @override
  String get linkPrivacyRemoveCameraDetail =>
      'Prenosi ne vsebujejo fotoaparata, objektiva, serijskih številk, avtorja ali programske opreme.';

  @override
  String get linkPrivacyRemoveDate => 'Odstrani tudi datum';

  @override
  String get linkPrivacyAskName => 'Vprašaj za ime';

  @override
  String get linkPrivacyAskNameDetail =>
      'Obiskovalci vpišejo ime, preden vidijo album.';

  @override
  String get linkPrivacyNotOpened => 'Še ni odprta';

  @override
  String linkPrivacyOpened(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Odprta $count-krat',
      one: 'Odprta enkrat',
    );
    return '$_temp0 · nazadnje $when';
  }

  @override
  String get linkPrivacyWhoOpened => 'Kdo jo je odprl';

  @override
  String get linkPrivacyNoVisits => 'Te povezave še nihče ni odprl.';

  @override
  String get linkPrivacyVisitsFailed => 'Obiskov ni bilo mogoče naložiti.';

  @override
  String get linkPrivacyUnknownPlace => 'Neznan kraj';

  @override
  String get linkPrivacyNoName => 'Brez imena';

  @override
  String linkPrivacyViewed(String count) {
    return 'ogledano: $count';
  }

  @override
  String linkPrivacyDownloaded(String count) {
    return 'preneseno: $count';
  }

  @override
  String get linkPrivacyAttribution =>
      'Kraji po DB-IP (db-ip.com), CC BY 4.0. Obiski se hranijo 90 dni.';

  @override
  String get sharePrivacyRemoveLocation => 'Odstrani lokacijo';

  @override
  String get sharePrivacyRemoveCamera => 'Odstrani podatke o fotoaparatu';

  @override
  String get sharePrivacyHideFaces => 'Skrij obraze';

  @override
  String get sharePrivacyHideFacesDetail =>
      'Fotografije gredo kot zamegljena kopija. Videoposnetki so izpuščeni.';

  @override
  String get sharePrivacyVideosLeftOut =>
      'Videoposnetki so izpuščeni: obrazov v njih ni mogoče skriti.';

  @override
  String notificationsLinkOpened(String subject) {
    return 'Tvoja povezava »$subject« je bila prvič odprta.';
  }

  @override
  String get cullTitle => 'Izbor posnetkov';

  @override
  String get cullMark => 'Oznaka';

  @override
  String get cullPick => 'Izbrano';

  @override
  String get cullReject => 'Zavrnjeno';

  @override
  String get cullNoMark => 'Brez oznake';

  @override
  String get cullPicks => 'Izbrane';

  @override
  String get cullRejects => 'Zavrnjene';

  @override
  String get cullUnmarked => 'Brez oznake';

  @override
  String get cullAddToCompare => 'Primerjaj';

  @override
  String get cullRemoveFromCompare => 'Odstrani iz primerjave';

  @override
  String get cullStopComparing => 'Končaj primerjavo';

  @override
  String get cullPicksToAlbum => 'Izbrane v nov album';

  @override
  String get cullRejectsToTrash => 'Zavrnjene v koš';

  @override
  String get cullNothing => 'Tukaj ni vaših fotografij za izbor.';

  @override
  String get cullNoneWithMark => 'Nobena fotografija nima te oznake.';

  @override
  String get cullNotSaved => 'Ni shranjeno';

  @override
  String get cullActionFailed => 'Dejanje ni uspelo';

  @override
  String get cullLoadFailed => 'Oznak ni bilo mogoče naložiti.';

  @override
  String get cullAlbumName => 'Ime';

  @override
  String get cullCreateAlbum => 'Ustvari';

  @override
  String cullTally(int picks, int rejects) {
    return 'Izbrano: $picks · Zavrnjeno: $rejects';
  }

  @override
  String cullConfirmTrash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count zavrnjenih fotografij gre v koš in jih je mogoče obnoviti.',
      few:
          '$count zavrnjene fotografije gredo v koš in jih je mogoče obnoviti.',
      two:
          '$count zavrnjeni fotografiji gresta v koš in ju je mogoče obnoviti.',
      one: '$count zavrnjena fotografija gre v koš in jo je mogoče obnoviti.',
    );
    return '$_temp0';
  }

  @override
  String cullMovedToTrash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotografij premaknjenih v koš',
      few: '$count fotografije premaknjene v koš',
      two: '$count fotografiji premaknjeni v koš',
      one: '$count fotografija premaknjena v koš',
    );
    return '$_temp0';
  }

  @override
  String cullAlbumMade(int count, String title) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotografij je v albumu $title',
      few: '$count fotografije so v albumu $title',
      two: '$count fotografiji sta v albumu $title',
      one: '$count fotografija je v albumu $title',
    );
    return '$_temp0';
  }

  @override
  String cullAlbumWillHold(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'V albumu bo $count izbranih fotografij.',
      few: 'V albumu bodo $count izbrane fotografije.',
      two: 'V albumu bosta $count izbrani fotografiji.',
      one: 'V albumu bo $count izbrana fotografija.',
    );
    return '$_temp0';
  }

  @override
  String get adminMlTitle => 'Storitev za analizo';

  @override
  String get adminMlConnected => 'Povezano';

  @override
  String get adminMlLoaded => 'Naloženi modeli';

  @override
  String get adminMlMemory => 'Pomnilnik';

  @override
  String get adminMlAcceleration => 'Pospešitev';

  @override
  String get adminMlNoneLoaded => 'Trenutno noben';

  @override
  String get adminMlState => 'Stanje';

  @override
  String get adminMlUnreachable =>
      'Ni dosegljivo. Analiza počaka in se nadaljuje, ko se vrne; do takrat iskanje upošteva besedilo na slikah in imena datotek.';

  @override
  String get adminMlWrongToken =>
      'Storitev je zavrnila žeton. ML_TOKEN mora biti enak v .env tukaj in na računalniku, kjer storitev teče.';

  @override
  String memoriesTripTitle(String place, String monthName, String year) {
    return '$place, $monthName $year';
  }

  @override
  String get memoriesMonth1 => 'januar';

  @override
  String get memoriesMonth2 => 'februar';

  @override
  String get memoriesMonth3 => 'marec';

  @override
  String get memoriesMonth4 => 'april';

  @override
  String get memoriesMonth5 => 'maj';

  @override
  String get memoriesMonth6 => 'junij';

  @override
  String get memoriesMonth7 => 'julij';

  @override
  String get memoriesMonth8 => 'avgust';

  @override
  String get memoriesMonth9 => 'september';

  @override
  String get memoriesMonth10 => 'oktober';

  @override
  String get memoriesMonth11 => 'november';

  @override
  String get memoriesMonth12 => 'december';

  @override
  String memoriesPersonYears(String person) {
    return '$person skozi leta';
  }

  @override
  String memoriesBirthday(String person) {
    return 'Rojstni dan: $person';
  }

  @override
  String memoriesYearReview(String year) {
    return 'Leto $year v fotografijah';
  }

  @override
  String get memoriesMonthAgo => 'Pred enim mesecem';

  @override
  String get memoriesHidden => 'Ta spomin je skrit.';

  @override
  String get memoriesPersonHidden =>
      'Ta oseba se ne bo več prikazovala v spominih.';

  @override
  String get memoriesHideThis => 'Skrij ta spomin';

  @override
  String get memoriesHidePerson => 'Ne prikazuj te osebe';

  @override
  String get memoriesMenuMore => 'Več';

  @override
  String get settingsScreenMemoryKinds => 'Vrste spominov';

  @override
  String get settingsScreenMemoryOnThisDay => 'Na današnji dan';

  @override
  String get settingsScreenMemoryWeek => 'Zadnji teden';

  @override
  String get settingsScreenMemoryTrip => 'Potovanja';

  @override
  String get settingsScreenMemoryPersonYears => 'Oseba skozi leta';

  @override
  String get settingsScreenMemoryBirthday => 'Rojstni dnevi';

  @override
  String get settingsScreenMemoryYearReview => 'Leto v fotografijah';

  @override
  String get settingsScreenMemoryMonthAgo => 'Pred enim mesecem';

  @override
  String get settingsScreenHiddenFromMemories => 'Skrito v spominih';

  @override
  String get settingsScreenNothingHidden => 'Nič ni skrito.';

  @override
  String get settingsScreenShowAgain => 'Znova prikaži';

  @override
  String settingsScreenHiddenMemoryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count skritih spominov',
      few: '$count skriti spomini',
      two: '$count skrita spomina',
      one: '$count skrit spomin',
    );
    return '$_temp0';
  }

  @override
  String get settingsScreenShowAllAgain => 'Znova prikaži vse';

  @override
  String get accountSheetExport => 'Izvoz knjižnice';

  @override
  String get adminScreenExports => 'Izvozi knjižnic';

  @override
  String get adminScreenExportsHint => 'Spremljanje, preklic in prenos izvozov';

  @override
  String adminUsersExportTooltip(String email) {
    return 'Izvozi knjižnico uporabnika $email';
  }

  @override
  String adminUsersExportStarted(String email) {
    return 'Izvoz knjižnice uporabnika $email se je začel.';
  }

  @override
  String get exportsScreenTitle => 'Izvoz';

  @override
  String get exportsScreenAllTitle => 'Izvozi knjižnic';

  @override
  String get exportsScreenWhatIsIn =>
      'Vzemite s seboj celotno knjižnico: datoteke ZIP z največ 10 GB z vsakim izvirnikom, kot je bil naložen, njegovo stransko datoteko XMP, mapo za vsak album in eno datoteko JSON z datumi, kraji, opisi, ocenami, priljubljenimi, oznakami, osebami in urejanji. Gesel in ključev v njem nikoli ni. Izdela se na strežniku, se po ponovnem zagonu nadaljuje in ga lahko prenesete 7 dni.';

  @override
  String get exportsScreenAdminHint =>
      'Izvoz, ki ga začnete za nekoga, se prikaže tudi na njegovem seznamu. Prenesete ga lahko vi in ta oseba; drugi skrbniki samo spremljajo napredek.';

  @override
  String get exportsScreenStart => 'Izvozi mojo knjižnico';

  @override
  String get exportsScreenStarted => 'Izvoz se je začel.';

  @override
  String get exportsScreenNothingYet => 'Nič še ni bilo izvoženo.';

  @override
  String get exportsScreenNotLoaded => 'Izvozov ni bilo mogoče naložiti.';

  @override
  String get exportsScreenRunning => 'V teku';

  @override
  String get exportsScreenReady => 'Pripravljen';

  @override
  String get exportsScreenFailed => 'Ni uspel';

  @override
  String get exportsScreenCancelled => 'Preklican';

  @override
  String get exportsScreenRemoved => 'Odstranjen po 7 dneh';

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
      other: '$total datotek',
      few: '$total datotek',
      two: '$total datotek',
      one: '$total datoteke',
    );
    return '$done od $_temp0 · $doneBytes od $totalBytes';
  }

  @override
  String exportsScreenStartedBy(String name) {
    return 'Začel/a $name';
  }

  @override
  String exportsScreenMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count datotek',
      few: '$count datoteke',
      two: '$count datoteki',
      one: '$count datoteka',
    );
    return 'Ni bilo na disku, zato je samo navedeno: $_temp0';
  }

  @override
  String exportsScreenKeptUntil(String date) {
    return 'Prenesete ga lahko do $date.';
  }

  @override
  String get exportsScreenOnlyOwner =>
      'Prenese ga lahko samo lastnik knjižnice ali skrbnik, ki je izvoz začel.';

  @override
  String get exportsScreenCancel => 'Prekliči';

  @override
  String get exportsScreenRemove => 'Odstrani';

  @override
  String exportsScreenPart(int number) {
    return 'Del $number';
  }

  @override
  String exportsScreenFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count datotek',
      few: '$count datoteke',
      two: '$count datoteki',
      one: '$count datoteka',
    );
    return '$_temp0';
  }

  @override
  String exportsScreenDownloadPart(int number) {
    return 'Prenesi del $number';
  }

  @override
  String get exportsScreenDownloadFailed =>
      'Dela ni bilo mogoče prenesti. Poskusite znova, nadaljevalo se bo, kjer se je ustavilo.';

  @override
  String get exportsScreenNoSpace =>
      'Na strežniku ni dovolj prostora za ta izvoz. Sprostite prostor ali se obrnite na skrbnika.';

  @override
  String get exportsScreenAlreadyRunning => 'Izvoz te knjižnice že poteka.';

  @override
  String get viewerScreenPlayOnTv => 'Prikaži na televizorju';

  @override
  String get viewerScreenMore => 'Več dejanj';

  @override
  String get slideshowScreenPlayOnTv => 'Prikaži na televizorju';

  @override
  String get tvSheetTitle => 'Prikaži na televizorju';

  @override
  String get tvSheetSearching => 'Iskanje televizorjev v tem omrežju…';

  @override
  String get tvSheetNoneFound => 'Televizor še ni najden.';

  @override
  String get tvSheetSearchAgain => 'Išči znova';

  @override
  String get tvSheetChromecast => 'Chromecast';

  @override
  String get tvSheetDlna => 'Televizor DLNA';

  @override
  String get tvSheetAirPlay => 'AirPlay';

  @override
  String get tvSheetAirPlayHint =>
      'Z gumbom izberite Apple TV: videi, ki jih predvajate, gredo nanj. Fotografije se na televizorju prikažejo z zrcaljenjem zaslona v Nadzornem središču.';

  @override
  String get tvSheetAddByAddress => 'Dodaj televizor po naslovu';

  @override
  String get tvSheetAddressLabel =>
      'Naslov IP televizorja ali naslov njegovega opisa';

  @override
  String get tvSheetAdd => 'Dodaj';

  @override
  String get tvSheetNotFoundAt =>
      'Na tem naslovu se ni oglasil noben televizor.';

  @override
  String tvSheetPlayingOn(String device) {
    return 'Predvaja se na: $device';
  }

  @override
  String get tvSheetStop => 'Ustavi';

  @override
  String get tvSheetFailed => 'Televizor ni dosegljiv.';

  @override
  String get tvSheetPlay => 'Predvajaj na televizorju';

  @override
  String get tvSheetPause => 'Začasno ustavi na televizorju';

  @override
  String get tvSheetPosition => 'Položaj na televizorju';

  @override
  String get tvSheetConnecting => 'Povezovanje s televizorjem…';

  @override
  String get tvSheetSameNetwork =>
      'Televizor in ta telefon morata biti v istem omrežju. Televizor dobi naslov, ki velja 4 ure in samo za to, kar mu pošljete.';

  @override
  String get adminServerSettingsDlna => 'Medijski strežnik DLNA';

  @override
  String get adminServerSettingsDlnaHelp =>
      'Televizorji v domačem omrežju vidijo vaše albume, brez gesla. Potrebuje storitev dlna, ki teče v omrežju gostitelja: glejte stran o televizorju v navodilih.';

  @override
  String adminServerSettingsDlnaOwner(String name) {
    return 'Televizorji vidijo albume uporabnika $name.';
  }

  @override
  String get adminServerSettingsDlnaAnnounced =>
      'Storitev dlna teče, zato televizorji najdejo ta strežnik.';

  @override
  String get adminServerSettingsDlnaNotAnnounced =>
      'Storitev dlna se še ni oglasila, zato televizorji še ne najdejo tega strežnika.';
}

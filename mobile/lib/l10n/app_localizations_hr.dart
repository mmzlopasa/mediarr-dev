// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Croatian (`hr`).
class AppLocalizationsHr extends AppLocalizations {
  AppLocalizationsHr([String locale = 'hr']) : super(locale);

  @override
  String get languageTitle => 'Jezik';

  @override
  String get languageMachine => 'Strojni prijevod: još ga nitko nije pročitao.';

  @override
  String get languageFollowsAccount =>
      'Odabir se sprema u vaš račun, pa ga prate i ostali uređaji.';

  @override
  String get appHeaderNew => 'Novo';

  @override
  String get appHeaderAdd => 'Dodaj';

  @override
  String get appHeaderAccount => 'Račun';

  @override
  String get appHeaderBackupAndUpload => 'Backup i slanje';

  @override
  String get uploadsCouldNotRead =>
      'Ova se fotka nije mogla pročitati s uređaja.';

  @override
  String get waitingStripTitle => 'Na ovom mobitelu, čeka backup';

  @override
  String get shareSheetVaultTitle => 'Iznijeti iz trezora?';

  @override
  String get shareSheetVaultBody =>
      'Kad se pošalje ili spremi, više ga ne štiti vaš PIN.';

  @override
  String get shareSheetCancel => 'Odustani';

  @override
  String get shareSheetContinue => 'Nastavi';

  @override
  String get shareSheetSendThis => 'Pošalji ovo';

  @override
  String shareSheetSendCount(String count) {
    return 'Pošalji $count';
  }

  @override
  String get shareSheetSmaller => 'Manje, za poruke';

  @override
  String get shareSheetOriginal => 'Original';

  @override
  String get shareSheetSmallerDetail => 'JPEG od najviše 2048 px, bez lokacije';

  @override
  String get shareSheetOriginalDetail => 'Kakav jest, sa svime što sadrži';

  @override
  String get shareSheetSaveToPhone => 'Spremi na ovaj mobitel';

  @override
  String get shareSheetSaveDetail => 'Original, u galeriji mobitela';

  @override
  String get shareSheetSavedOne => 'Spremljeno na ovaj mobitel.';

  @override
  String shareSheetSavedMany(String count) {
    return 'Spremljeno na ovaj mobitel: $count.';
  }

  @override
  String get shareSheetGettingReady => 'Pripremam';

  @override
  String shareSheetProgress(String done, String total) {
    return '$done od $total';
  }

  @override
  String get shareSheetFetchFailed => 'Datoteke se nisu mogle dohvatiti.';

  @override
  String facesSectionActionFailed(String detail) {
    return 'Radnja nije uspjela. $detail';
  }

  @override
  String get facesSectionNewPerson => 'Nova osoba';

  @override
  String get facesSectionCancel => 'Odustani';

  @override
  String get facesSectionSave => 'Spremi';

  @override
  String get facesSectionPeople => 'Osobe';

  @override
  String get facesSectionNoName => 'Bez imena';

  @override
  String get facesSectionWhoThisIs => 'Tko je ovo';

  @override
  String get facesSectionNewPersonMenu => 'Nova osoba…';

  @override
  String get facesSectionNotAPerson => 'Nije osoba';

  @override
  String get importsScreenWaitingForFiles => 'Čeka datoteke';

  @override
  String get importsScreenRunning => 'U tijeku';

  @override
  String get importsScreenDone => 'Gotovo';

  @override
  String get importsScreenFailed => 'Nije uspjelo';

  @override
  String get importsScreenStopped => 'Zaustavljeno';

  @override
  String importsScreenZipUploaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Učitano $count ZIP datoteka',
      few: 'Učitane $count ZIP datoteke',
      one: 'Učitana $count ZIP datoteka',
    );
    return '$_temp0';
  }

  @override
  String importsScreenCounts(String added, String skipped, String failed) {
    return 'dodano $added · već postoji ili obrisano $skipped · nije uspjelo $failed';
  }

  @override
  String get importsScreenReportNotLoaded => 'Izvještaj se nije mogao učitati.';

  @override
  String get importsScreenNoFilesFailed => 'Nema neuspjelih datoteka.';

  @override
  String get importsScreenCouldNotStop => 'Uvoz se nije mogao zaustaviti.';

  @override
  String get importsScreenStop => 'Zaustavi';

  @override
  String get importsScreenCouldNotContinue => 'Uvoz se nije mogao nastaviti.';

  @override
  String get importsScreenBringIn => 'Uvezi';

  @override
  String get importsScreenContinue => 'Nastavi';

  @override
  String get importsScreenReport => 'Izvještaj';

  @override
  String get importsScreenTitle => 'Uvoz';

  @override
  String get importsScreenNotLoaded => 'Uvozi se nisu mogli učitati.';

  @override
  String importsScreenHowTo(String address) {
    return 'Da biste donijeli fotke iz Google Photosa ili iClouda, učitajte ZIP datoteke izvoza na računalu, na $address.';
  }

  @override
  String get importsScreenNothingYet => 'Još niste ništa uvezli.';

  @override
  String get storageTemplateScreenDryRun => 'Probni prolaz';

  @override
  String storageTemplateScreenDryRunProgress(String checked) {
    return 'Probni prolaz… $checked';
  }

  @override
  String storageTemplateScreenMovingProgress(String checked) {
    return 'Premještam… $checked';
  }

  @override
  String storageTemplateScreenWouldMove(String moved, String checked) {
    return 'Probni prolaz: premjestilo bi se $moved od $checked.';
  }

  @override
  String storageTemplateScreenMoved(String moved, String checked) {
    return 'Premješteno $moved od $checked.';
  }

  @override
  String storageTemplateScreenFailedCount(String line, String failed) {
    return '$line Nije uspjelo: $failed.';
  }

  @override
  String get storageTemplateScreenNotLoaded => 'Nije učitano.';

  @override
  String get storageTemplateScreenSaved => 'Spremljeno.';

  @override
  String get storageTemplateScreenNotSaved => 'Nije spremljeno.';

  @override
  String storageTemplateScreenMoveFilesQuestion(String count) {
    return 'Premjestiti $count datoteka?';
  }

  @override
  String get storageTemplateScreenOriginalsUnchanged =>
      'Originali se ne mijenjaju, samo mjesto na disku.';

  @override
  String get storageTemplateScreenCancel => 'Odustani';

  @override
  String get storageTemplateScreenMove => 'Premjesti';

  @override
  String get storageTemplateScreenNotStarted => 'Nije pokrenuto.';

  @override
  String get storageTemplateScreenTitle => 'Predložak pohrane';

  @override
  String get storageTemplateScreenIntro =>
      'Kako se originali slažu na disku, unutar mape svakog korisnika. Vrijedi za nove datoteke; postojeće se premještaju tek kad to zatražite, nakon probnog prolaza. Vanjska biblioteka se nikad ne premješta.';

  @override
  String get storageTemplateScreenTemplate => 'Predložak';

  @override
  String get storageTemplateScreenExamples => 'Primjeri';

  @override
  String get storageTemplateScreenBackToUsual => 'Kao prije';

  @override
  String get storageTemplateScreenSave => 'Spremi';

  @override
  String get storageTemplateScreenFilesAlreadyHere =>
      'Datoteke koje su već ovdje';

  @override
  String get storageTemplateScreenMoveTheFiles => 'Premjesti datoteke';

  @override
  String get mapScreenNoPlaceName => 'Bez naziva mjesta';

  @override
  String get mapScreenNotLoaded => 'Karta se nije učitala. Provjerite vezu.';

  @override
  String get mapScreenTryAgain => 'Pokušaj ponovno';

  @override
  String get mapScreenNoPhotos => 'Još nema fotki s lokacijom.';

  @override
  String get mapScreenFromDate => 'Od datuma';

  @override
  String get mapScreenToDate => 'Do datuma';

  @override
  String get mapScreenClear => 'Očisti';

  @override
  String mapScreenItems(String count) {
    return 'Stavke: $count';
  }

  @override
  String get mapScreenTrips => 'Putovanja';

  @override
  String get mapScreenTitle => 'Karta';

  @override
  String get cleanupScreenBlurry => 'Mutne fotke';

  @override
  String get cleanupScreenScreenshots => 'Screenshotovi';

  @override
  String get cleanupScreenLargeVideos => 'Veliki videi';

  @override
  String get cleanupScreenBursts => 'Nizovi';

  @override
  String get cleanupScreenBlurryHint =>
      'Fotke s vrlo malo oštrih rubova. Klizač određuje koliko strogo.';

  @override
  String get cleanupScreenScreenshotsHint =>
      'Prepoznati po imenu, oznaci s iPhonea ili obliku ekrana.';

  @override
  String get cleanupScreenLargeVideosHint => 'Najveći prvi.';

  @override
  String get cleanupScreenBurstsHint =>
      'Ostali kadrovi niza. Najbolji kadar ostaje.';

  @override
  String get cleanupScreenMoveToTrashQuestion => 'Premjestiti u smeće?';

  @override
  String cleanupScreenTrashBody(String count, String size) {
    return '$count stavki ($size) ostaje neko vrijeme u smeću i može se vratiti.';
  }

  @override
  String get cleanupScreenCancel => 'Odustani';

  @override
  String get cleanupScreenMove => 'Premjesti';

  @override
  String get cleanupScreenMovedToTrash => 'Premješteno u smeće.';

  @override
  String get cleanupScreenActionFailed => 'Radnja nije uspjela.';

  @override
  String get cleanupScreenKept => 'Zadržano. Više se neće nuditi.';

  @override
  String get cleanupScreenStricter => 'Strože';

  @override
  String get cleanupScreenMore => 'Blaže';

  @override
  String get cleanupScreenLargerThan => 'Veći od ';

  @override
  String get cleanupScreenToTheTrash => 'U smeće';

  @override
  String get cleanupScreenStays => 'Ostaje';

  @override
  String get cleanupScreenFavorite => 'Favorit';

  @override
  String get cleanupScreenInAnAlbum => 'U albumu';

  @override
  String get cleanupScreenTitle => 'Čišćenje';

  @override
  String get cleanupScreenKeep => 'Zadrži';

  @override
  String cleanupScreenToTheTrashButton(String count, String size) {
    return 'U smeće ($count · $size)';
  }

  @override
  String get cleanupScreenNotLoaded => 'Čišćenje se nije učitalo.';

  @override
  String cleanupScreenStillAnalysed(String count) {
    return 'Još se analizira fotki: $count.';
  }

  @override
  String get cleanupScreenNothing => 'Ovdje nema ničega za čišćenje.';

  @override
  String get cleanupScreenTapToTick =>
      'Dodirnite za označavanje ili poništavanje. Zadržite za pregled.';

  @override
  String get cleanupScreenShowMore => 'Prikaži još';

  @override
  String get organizeScreensRecentlyAdded => 'Nedavno dodano';

  @override
  String get organizeScreensFavorites => 'Favoriti';

  @override
  String get organizeScreensMemories => 'Uspomene';

  @override
  String get organizeScreensPeople => 'Osobe';

  @override
  String get organizeScreensMap => 'Karta';

  @override
  String get organizeScreensFolders => 'Mape';

  @override
  String get organizeScreensFamily => 'Obitelj';

  @override
  String get organizeScreensDocuments => 'Dokumenti';

  @override
  String get organizeScreensDuplicates => 'Duplikati';

  @override
  String get organizeScreensCleanUp => 'Čišćenje';

  @override
  String get organizeScreensArchive => 'Arhiva';

  @override
  String get organizeScreensTrash => 'Smeće';

  @override
  String get organizeScreensVault => 'Trezor';

  @override
  String get organizeScreensApiKeys => 'API ključevi';

  @override
  String get organizeScreensTags => 'Oznake';

  @override
  String get organizeScreensCouldNotLoad =>
      'Podaci se ne mogu učitati. Provjerite vezu.';

  @override
  String get organizeScreensClearSelection => 'Poništi odabir';

  @override
  String get organizeScreensShare => 'Dijeli';

  @override
  String get organizeScreensOriginalsRemoved =>
      'Originali se brišu s diska. To se ne može poništiti.';

  @override
  String get organizeScreensCancel => 'Odustani';

  @override
  String get organizeScreensDeletePermanently => 'Obriši trajno';

  @override
  String organizeScreensActionFailedDetail(String detail) {
    return 'Radnja nije uspjela. $detail';
  }

  @override
  String get organizeScreensNothingAdded => 'Još ništa nije dodano.';

  @override
  String get organizeScreensAddToFavorites => 'Dodaj u favorite';

  @override
  String get organizeScreensAddedToFavorites => 'Dodano u favorite';

  @override
  String get organizeScreensArchiveAction => 'Arhiviraj';

  @override
  String get organizeScreensArchived => 'Arhivirano';

  @override
  String get organizeScreensNoFavorites =>
      'Još nema favorita. Označite fotku zvjezdicom.';

  @override
  String get organizeScreensRemoveFromFavorites => 'Makni iz favorita';

  @override
  String get organizeScreensRemovedFromFavorites => 'Maknuto iz favorita';

  @override
  String get organizeScreensArchiveEmpty => 'Arhiva je prazna.';

  @override
  String get organizeScreensBackToMedia => 'Vrati u Medije';

  @override
  String get organizeScreensBackInMedia => 'Vraćeno u Medije';

  @override
  String organizeScreensTrashRemoves(String count, String size) {
    return 'Briše se: $count datoteka, $size.';
  }

  @override
  String get organizeScreensEmptyTrashQuestion => 'Isprazniti smeće?';

  @override
  String organizeScreensPermanentlyDeletedCount(String count) {
    return 'Trajno obrisano: $count';
  }

  @override
  String get organizeScreensEmpty => 'Isprazni';

  @override
  String get organizeScreensTrashAfterAWhile =>
      'Stavke se ovdje trajno brišu nakon nekog vremena.';

  @override
  String organizeScreensTrashAfterDays(String days) {
    return 'Stavke se trajno brišu nakon $days dana.';
  }

  @override
  String get organizeScreensTrashEmpty => 'Smeće je prazno.';

  @override
  String get organizeScreensRestore => 'Vrati';

  @override
  String get organizeScreensRestored => 'Vraćeno';

  @override
  String get organizeScreensDeletePermanentlyQuestion => 'Obrisati trajno?';

  @override
  String get organizeScreensPermanentlyDeleted => 'Trajno obrisano';

  @override
  String get organizeScreensOpenYourVault => 'Otvorite svoj trezor';

  @override
  String get organizeScreensTooManyAttempts =>
      'Previše pokušaja. Pokušajte kasnije.';

  @override
  String get organizeScreensWrongPin => 'Pogrešan PIN.';

  @override
  String get organizeScreensPinLength => 'PIN mora imati od 4 do 12 znamenki.';

  @override
  String get organizeScreensVaultLockedItself =>
      'Trezor se sam zaključao. Otključajte ga ponovno.';

  @override
  String get organizeScreensVaultEmpty => 'Trezor je prazan.';

  @override
  String get organizeScreensVaultNotLoaded =>
      'Trezor se nije učitao. Provjerite vezu.';

  @override
  String get organizeScreensTryAgain => 'Pokušaj ponovno';

  @override
  String get organizeScreensVaultIntro =>
      'Skriveno od svih drugih prikaza i dijeljenja. Datoteke na serveru nisu šifrirane.';

  @override
  String get organizeScreensPin => 'PIN';

  @override
  String get organizeScreensNewPin => 'Novi PIN';

  @override
  String get organizeScreensPinHelper =>
      'Od 4 do 12 znamenki. Izgubljeni PIN može resetirati samo administrator servera.';

  @override
  String get organizeScreensUseFaceId => 'Sljedeći put koristi Face ID';

  @override
  String get organizeScreensUnlock => 'Otključaj';

  @override
  String get organizeScreensSetPin => 'Postavi PIN';

  @override
  String get organizeScreensAddATag => 'Dodaj oznaku';

  @override
  String get organizeScreensNewTag => 'Nova oznaka';

  @override
  String get organizeScreensCreateAndAdd => 'Stvori i dodaj';

  @override
  String get organizeScreensTagsNotLoaded => 'Oznake se nisu učitale.';

  @override
  String get organizeScreensNoTags =>
      'Još nema oznaka. Odaberite fotke i dodajte oznaku.';

  @override
  String get organizeScreensDeleteTag => 'Obriši oznaku';

  @override
  String get organizeScreensRenameTheTag => 'Preimenuj oznaku';

  @override
  String get organizeScreensNewName => 'Novo ime';

  @override
  String get organizeScreensSave => 'Spremi';

  @override
  String organizeScreensAlreadyExists(String name) {
    return '„$name” već postoji';
  }

  @override
  String organizeScreensJoinThem(String name) {
    return 'Spojiti ih? Sve fotke će imati oznaku „$name”.';
  }

  @override
  String get organizeScreensJoin => 'Spoji';

  @override
  String organizeScreensNotRenamed(String detail) {
    return 'Nije preimenovano. $detail';
  }

  @override
  String organizeScreensNotJoined(String detail) {
    return 'Nije spojeno. $detail';
  }

  @override
  String get organizeScreensRename => 'Preimenuj';

  @override
  String get organizeScreensNoPhotosWithTag => 'Nijedna fotka nema ovu oznaku.';

  @override
  String get organizeScreensRemoveTheTag => 'Ukloni oznaku';

  @override
  String get organizeScreensFamilyNotOn =>
      'Administrator nije uključio ovu značajku.';

  @override
  String get organizeScreensFamilyNotMember =>
      'Još niste u obiteljskoj biblioteci.';

  @override
  String get organizeScreensWhatIShare => 'Što dijelim';

  @override
  String get organizeScreensFamilyNotLoaded =>
      'Obiteljska biblioteka se nije učitala.';

  @override
  String get organizeScreensFamilyNothingShared =>
      'Još nitko nije ništa podijelio s obitelji.';

  @override
  String get organizeScreensShareWithFamily => 'Dijeli s obitelji';

  @override
  String get organizeScreensRuleName => 'Naziv pravila';

  @override
  String get organizeScreensFromDateExample => 'Od datuma (2024-06-01)';

  @override
  String get organizeScreensPlace => 'Mjesto';

  @override
  String organizeScreensNotSaved(String detail) {
    return 'Nije spremljeno. $detail';
  }

  @override
  String get organizeScreensNewRule => 'Novo pravilo';

  @override
  String get organizeScreensShareNothing => 'Još ništa ne dijelite s obitelji.';

  @override
  String get organizeScreensStopSharing => 'Prestani dijeliti';

  @override
  String get organizeScreensActionFailed => 'Radnja nije uspjela.';

  @override
  String get settingsScreenTitle => 'Postavke';

  @override
  String get settingsScreenViewing => 'Prikaz';

  @override
  String get settingsScreenAssetViewer => 'Preglednik';

  @override
  String get settingsScreenAssetViewerHint => 'Kako se otvaraju fotke i videi';

  @override
  String get settingsScreenPhotoGrid => 'Mreža fotki';

  @override
  String get settingsScreenPhotoGridHint => 'Kako je složena vremenska crta';

  @override
  String get settingsScreenPreferences => 'Prilagodba';

  @override
  String get settingsScreenPreferencesHint => 'Tema, boja i odziv';

  @override
  String get settingsScreenLanguageHint => 'Jezik aplikacije';

  @override
  String get settingsScreenThisPhone => 'Ovaj mobitel';

  @override
  String get settingsScreenBackup => 'Backup';

  @override
  String get settingsScreenBackupHint => 'Što ovaj mobitel šalje na server';

  @override
  String get settingsScreenFreeUpSpace => 'Oslobodi prostor';

  @override
  String get settingsScreenFreeUpSpaceHint =>
      'Ukloni ono što je sigurno na serveru';

  @override
  String get settingsScreenSyncStatus => 'Stanje sinkronizacije';

  @override
  String get settingsScreenSyncStatusHint =>
      'Što je na ovom mobitelu, a što na serveru';

  @override
  String get settingsScreenHomeWidget => 'Widget na početnom zaslonu';

  @override
  String get settingsScreenHomeWidgetHint => 'Album na početnom zaslonu';

  @override
  String get settingsScreenNotifications => 'Obavijesti';

  @override
  String get settingsScreenNotificationsHint =>
      'O čemu vas aplikacija obavještava';

  @override
  String get settingsScreenServer => 'Server';

  @override
  String get settingsScreenDevices => 'Uređaji';

  @override
  String get settingsScreenDevicesHint => 'Gdje je ovaj račun prijavljen';

  @override
  String get settingsScreenYourLibrary => 'Vaša biblioteka';

  @override
  String get settingsScreenYourLibraryHint => 'Koliko ovaj račun sadrži';

  @override
  String get settingsScreenNetworking => 'Mreža';

  @override
  String get settingsScreenNetworkingHint => 'Adrese vašeg servera';

  @override
  String get settingsScreenAdvanced => 'Napredno';

  @override
  String get settingsScreenAdvancedHint =>
      'Način samo za čitanje i predmemorija slika';

  @override
  String get settingsScreenWhatsNew => 'Što je novo';

  @override
  String get settingsScreenWhatsNewHint => 'Verzije Mediarra';

  @override
  String get settingsScreenReadOnlyOff => 'Isključi način samo za čitanje';

  @override
  String get settingsScreenReadOnly => 'Način samo za čitanje';

  @override
  String get settingsScreenReadOnlyHint =>
      'Samo gledanje: bez slanja, uređivanja i brisanja iz ove aplikacije';

  @override
  String get settingsScreenCopyAlbums => 'Kopiraj albume na server';

  @override
  String get settingsScreenCopyAlbumsHint =>
      'Albumi s backupom dobivaju istoimeni album na serveru. Fotke se samo dodaju, nikad ne uklanjaju';

  @override
  String get settingsScreenClearCache => 'Očisti predmemoriju slika';

  @override
  String get settingsScreenCacheEmpty => 'Predmemorija slika je prazna.';

  @override
  String get settingsScreenPhotos => 'Fotke';

  @override
  String get settingsScreenLoadFull => 'Učitaj cijelu fotku';

  @override
  String get settingsScreenLoadFullHint =>
      'Otvara fotke u punoj rezoluciji. Troši više podataka i sporije je';

  @override
  String get settingsScreenTapToNavigate => 'Dodir za kretanje';

  @override
  String get settingsScreenTapToNavigateHint =>
      'Dodir lijeve ili desne četvrtine zaslona vodi na prethodnu ili sljedeću fotku';

  @override
  String get settingsScreenVideos => 'Videi';

  @override
  String get settingsScreenAutoPlay => 'Automatski pokreni videe';

  @override
  String get settingsScreenAutoPlayHint => 'Videi kreću čim se otvore';

  @override
  String get settingsScreenLooping => 'Ponavljanje';

  @override
  String get settingsScreenLoopingHint => 'Videi kreću ispočetka kad završe';

  @override
  String get settingsScreenPlayOriginal => 'Pusti originalni video';

  @override
  String get settingsScreenPlayOriginalHint =>
      'Pušta original i kad postoji pretvorena verzija. Možda će morati učitavati';

  @override
  String get settingsScreenLayout => 'Raspored';

  @override
  String settingsScreenPerRow(String count) {
    return 'Fotki u retku ($count)';
  }

  @override
  String get settingsScreenGroupBy => 'Grupiraj po';

  @override
  String get settingsScreenMonthDay => 'Mjesec + dan';

  @override
  String get settingsScreenMonth => 'Mjesec';

  @override
  String get settingsScreenTheme => 'Tema';

  @override
  String get settingsScreenPrimaryColor => 'Glavna boja';

  @override
  String get settingsScreenHaptics => 'Vibracija pri dodiru';

  @override
  String get settingsScreenEnabled => 'Uključeno';

  @override
  String get settingsScreenNotificationsNotYet =>
      'Obavijesti još nisu dostupne.';

  @override
  String get settingsScreenPhotosAndVideos => 'Fotke i videi';

  @override
  String get settingsScreenPhone => 'Mobitel';

  @override
  String get settingsScreenAlbums => 'Albumi';

  @override
  String get settingsScreenOther => 'Ostalo';

  @override
  String get settingsScreenMemories => 'Uspomene';

  @override
  String get settingsScreenBackedUp => 'U backupu';

  @override
  String get settingsScreenCheckAgain => 'Provjeri ponovno';

  @override
  String settingsScreenRetryFailed(String count) {
    return 'Ponovno pošalji neuspjele ($count)';
  }

  @override
  String get settingsScreenRemoved => 'Uklonjeno.';

  @override
  String get settingsScreenSaved => 'Spremljeno.';

  @override
  String settingsScreenMainAddress(String address) {
    return 'Glavna adresa: $address';
  }

  @override
  String get settingsScreenSecondAddress => 'Druga adresa';

  @override
  String get settingsScreenSecondAddressHint =>
      'Koristi se kad glavna ne odgovara, npr. izvan kuće';

  @override
  String get settingsScreenSave => 'Spremi';

  @override
  String get settingsScreenCouldNotLoad => 'Podaci se ne mogu učitati.';

  @override
  String get settingsScreenThisDevice => 'Ovaj uređaj';

  @override
  String get settingsScreenSignOut => 'Odjavi';

  @override
  String get settingsScreenSignOutOthers => 'Odjavi sve ostale';

  @override
  String get settingsScreenFavorites => 'Favoriti';

  @override
  String get settingsScreenArchive => 'Arhiva';

  @override
  String get settingsScreenTrash => 'Smeće';

  @override
  String get settingsScreenUsed => 'Zauzeto';

  @override
  String get settingsScreenYourAccount => 'Vaš račun';

  @override
  String settingsScreenMemorySeconds(String seconds) {
    return 'Sekunde po slici u uspomenama ($seconds)';
  }

  @override
  String settingsScreenMinFaces(String count) {
    return 'Najmanje fotki da se osoba prikaže ($count)';
  }

  @override
  String get settingsScreenAlbumOrder => 'Poredak u novom albumu';

  @override
  String get settingsScreenNewestFirst => 'Najnovije prvo';

  @override
  String get settingsScreenOldestFirst => 'Najstarije prvo';

  @override
  String get sessionDeviceNotApproved =>
      'Administrator mora odobriti ovaj uređaj prije nego što se može prijaviti.';

  @override
  String get sessionEnterAddress => 'Upišite adresu svog servera.';

  @override
  String get sessionAddressInvalid => 'Ta adresa servera nije ispravna.';

  @override
  String get sessionNoServer =>
      'Na toj adresi nije odgovorio nijedan Mediarr server.';

  @override
  String sessionUnreachableCheck(String reason) {
    return 'Server nije dostupan. Provjerite adresu. ($reason)';
  }

  @override
  String sessionUnreachable(String reason) {
    return 'Server nije dostupan. ($reason)';
  }

  @override
  String get sessionCodeWrong => 'Kod nije točan.';

  @override
  String get sessionWrongPassword => 'Pogrešna e-adresa ili lozinka.';

  @override
  String get sessionTooManyAttempts => 'Previše pokušaja. Pokušajte kasnije.';

  @override
  String sessionSignInFailed(String code) {
    return 'Prijava nije uspjela ($code).';
  }

  @override
  String get sessionNoSession => 'Server nije pokrenuo sesiju.';

  @override
  String get sessionCancelled => 'Prijava je otkazana.';

  @override
  String get sessionSsoOff =>
      'Jedinstvena prijava nije uključena na ovom serveru.';

  @override
  String get sessionSsoFailed =>
      'Jedinstvena prijava nije uspjela. Možda nemate račun na ovom serveru.';

  @override
  String get sessionCodeExpired =>
      'Ovaj kod je istekao ili je već iskorišten. Napravite novi.';

  @override
  String get sessionNoAnswer => 'Server nije odgovorio.';

  @override
  String get sessionNotAllowed => 'Prijava nije dopuštena.';

  @override
  String get sessionSignInExpired =>
      'Ova prijava je istekla. Napravite novi kod.';

  @override
  String get sessionNobodyAnswered =>
      'Nitko nije odgovorio na vrijeme. Napravite novi kod.';

  @override
  String get tusSignedOut => 'Odjavljeni ste. Prijavite se ponovno.';

  @override
  String tusRejected(String code, String body) {
    return 'Server je odbio ovu datoteku ($code). $body';
  }

  @override
  String albumsScreenInside(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albuma',
      few: '$count albuma',
      one: '$count album',
    );
    return '$_temp0';
  }

  @override
  String get albumsScreenLoadFailed =>
      'Albumi se nisu učitali. Provjerite vezu.';

  @override
  String get albumsScreenTryAgain => 'Pokušaj ponovno';

  @override
  String get albumsScreenNoAlbums => 'Još nema albuma.';

  @override
  String get albumsScreenNoMatch => 'Nijedan album ne odgovara.';

  @override
  String get albumsScreenSortUpdated => 'Zadnja promjena';

  @override
  String get albumsScreenName => 'Naziv';

  @override
  String get albumsScreenSortDate => 'Datum fotki';

  @override
  String get albumsScreenTitle => 'Albumi';

  @override
  String get albumsScreenNew => 'Novi';

  @override
  String get albumsScreenSort => 'Poredak';

  @override
  String get albumsScreenSearchFilter => 'Pretraži i filtriraj';

  @override
  String get albumsScreenShowList => 'Prikaži kao popis';

  @override
  String get albumsScreenShowGrid => 'Prikaži kao mrežu';

  @override
  String get albumsScreenSearchAlbums => 'Pretraži albume';

  @override
  String get albumsScreenAll => 'Svi';

  @override
  String get albumsScreenSharedWithMe => 'Podijeljeni sa mnom';

  @override
  String get albumsScreenMine => 'Moji albumi';

  @override
  String albumsScreenItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stavki',
      few: '$count stavke',
      one: '$count stavka',
    );
    return '$_temp0';
  }

  @override
  String get albumsScreenSmart => 'Pametni';

  @override
  String get albumsScreenOwned => 'Moj';

  @override
  String get albumsScreenNotCreated => 'Album nije stvoren.';

  @override
  String get albumsScreenNewAlbum => 'Novi album';

  @override
  String get albumsScreenDescription => 'Opis';

  @override
  String get albumsScreenSmartAlbum =>
      'Pametni album: puni se sam po pravilima';

  @override
  String get albumsScreenCreate => 'Stvori';

  @override
  String get adminScreenTitle => 'Administracija';

  @override
  String get adminScreenOverview => 'Pregled';

  @override
  String get adminScreenOverviewHint => 'Korisnici, fotke, disk i verzije';

  @override
  String get adminScreenUsers => 'Korisnici';

  @override
  String get adminScreenUsersHint =>
      'Dodajte korisnike i odredite koliko smiju pohraniti';

  @override
  String get adminScreenServerSettings => 'Postavke servera';

  @override
  String get adminScreenServerSettingsHint =>
      'Smeće, kvaliteta, lica, poslovi, prijava';

  @override
  String get adminScreenEmail => 'E-pošta';

  @override
  String get adminScreenEmailHint => 'Odakle se šalju poruke';

  @override
  String get adminScreenSecurity => 'Sigurnost';

  @override
  String get adminScreenSecurityHint =>
      'Jedinstvena prijava, uređaji, adrese, pokušaji';

  @override
  String get adminScreenJobs => 'Poslovi';

  @override
  String get adminScreenJobsHint => 'Redovi i poslovi koji nisu uspjeli';

  @override
  String get adminScreenAuditLog => 'Dnevnik aktivnosti';

  @override
  String get adminScreenAuditLogHint => 'Tko je što promijenio';

  @override
  String get adminScreenBackupHint => 'Kopije biblioteke';

  @override
  String get adminScreenBackupDevices => 'Svi uređaji za backup';

  @override
  String get adminScreenBackupDevicesHint => 'Svaki mobitel koji radi backup';

  @override
  String get adminScreenStorageTemplate => 'Predložak pohrane';

  @override
  String get adminScreenStorageTemplateHint =>
      'Kako se originali slažu na disku';

  @override
  String get adminAuditEmpty => 'Još ništa nije promijenjeno.';

  @override
  String get adminAuditShowOlder => 'Prikaži starije';

  @override
  String adminUsersAdded(String email) {
    return '$email je dodan.';
  }

  @override
  String get adminUsersAddUser => 'Dodaj korisnika';

  @override
  String get adminUsersAdministrator => 'Administrator';

  @override
  String adminUsersStoredOf(String stored, String quota) {
    return '$stored od $quota';
  }

  @override
  String get adminUsersNoLimit => 'bez ograničenja';

  @override
  String adminUsersQuotaTooltip(String email) {
    return 'Koliko $email smije pohraniti';
  }

  @override
  String get adminUsersEmail => 'E-adresa';

  @override
  String get adminUsersName => 'Ime';

  @override
  String get adminUsersPassword => 'Lozinka';

  @override
  String get adminUsersCancel => 'Odustani';

  @override
  String get adminUsersAdd => 'Dodaj';

  @override
  String get adminUsersQuotaInvalid =>
      'Upišite broj gigabajta ili ništa za bez ograničenja.';

  @override
  String adminUsersStorageFor(String email) {
    return 'Prostor za $email';
  }

  @override
  String get adminUsersLimitGb => 'Ograničenje u GB';

  @override
  String get adminUsersEmptyNoLimit => 'Prazno znači bez ograničenja.';

  @override
  String get profileScreenNotSaved => 'Profil nije spremljen.';

  @override
  String get profileScreenPictureNotSent => 'Slika nije poslana.';

  @override
  String get profileScreenPictureNotRemoved => 'Slika nije uklonjena.';

  @override
  String get profileScreenTitle => 'Profil';

  @override
  String get profileScreenChangePicture => 'Promijeni sliku';

  @override
  String get profileScreenAddPicture => 'Dodaj sliku';

  @override
  String get profileScreenRemove => 'Ukloni';

  @override
  String get profileScreenEmailAddress => 'E-mail adresa';

  @override
  String get profileScreenCurrentPassword =>
      'Trenutna lozinka, za promjenu e-maila';

  @override
  String get serverStatusStorage => 'Prostor';

  @override
  String serverStatusUsedOf(String used, String total) {
    return '$used od $total zauzeto';
  }

  @override
  String get serverStatusOnline => 'Server radi';

  @override
  String get serverStatusMaintained => 'Server je na održavanju';

  @override
  String get serverStatusOffline => 'Server ne odgovara';

  @override
  String serverStatusVersionAvailable(String version) {
    return 'Dostupna verzija $version';
  }

  @override
  String get serverStatusNewVersion => 'Dostupna je nova verzija';

  @override
  String serverStatusUpdateBody(String latest, String version) {
    return 'Mediarr $latest je dostupan. Ovaj server koristi $version. Administrator servera ga ažurira naredbom:\n\ndocker compose pull && docker compose up -d';
  }

  @override
  String get serverStatusOk => 'U redu';

  @override
  String get storiesStripLastWeek => 'Protekli tjedan';

  @override
  String storiesStripYearsAgo(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: 'prije $years godina',
      few: 'prije $years godine',
      one: 'prije $years godinu',
    );
    return '$_temp0';
  }

  @override
  String storiesStripItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stavki',
      few: '$count stavke',
      one: '$count stavka',
    );
    return '$_temp0';
  }

  @override
  String get backupScreenNotYet => 'još nije';

  @override
  String backupScreenLastBackup(String when) {
    return 'zadnji backup $when';
  }

  @override
  String backupScreenUpTo(String size) {
    return 'do $size';
  }

  @override
  String get backupScreenInvited => 'Pozvan';

  @override
  String get backupScreenStopped => 'Zaustavljen';

  @override
  String get backupScreenActive => 'Aktivan';

  @override
  String backupScreenDeletedKept(String size) {
    return 'obrisano se čuva: $size';
  }

  @override
  String get backupScreenActionFailed => 'Radnja nije uspjela.';

  @override
  String get backupScreenSaved => 'Spremljeno.';

  @override
  String get backupScreenBackupStarted => 'Backup je pokrenut.';

  @override
  String get backupScreenRestoreTestStarted => 'Test vraćanja je pokrenut.';

  @override
  String get backupScreenPaired => 'Upareno. Sljedeći backup ide i tamo.';

  @override
  String get backupScreenKeepForSomeone => 'Čuvaj backup za nekoga';

  @override
  String get backupScreenForWhom => 'Za koga';

  @override
  String get backupScreenAtMostGb => 'Najviše (GB)';

  @override
  String get backupScreenOtherServerAddress =>
      'Adresa na kojoj vas drugi server vidi';

  @override
  String get backupScreenCancel => 'Odustani';

  @override
  String get backupScreenInvite => 'Pozovi';

  @override
  String get backupScreenInvitationFailed => 'Poziv nije uspio.';

  @override
  String backupScreenCodeFor(String name) {
    return 'Kod za $name';
  }

  @override
  String backupScreenSendItToAdmin(String when) {
    return 'Pošaljite ga adminu drugog servera, koji ga zalijepi ili skenira. Vrijedi jednom, do $when.';
  }

  @override
  String get backupScreenPlainHttp =>
      'Preko običnog HTTP-a ključ se može presresti. Koristite HTTPS ili VPN.';

  @override
  String get backupScreenCopy => 'Kopiraj';

  @override
  String get backupScreenDone => 'Gotovo';

  @override
  String backupScreenHowMuchFor(String name) {
    return 'Koliko za $name';
  }

  @override
  String get backupScreenSave => 'Spremi';

  @override
  String backupScreenDeleteCopyOf(String name) {
    return 'Obrisati kopiju za $name?';
  }

  @override
  String backupScreenTypeToDelete(String name) {
    return 'Upišite „$name“ za brisanje';
  }

  @override
  String get backupScreenDeleteTheCopy => 'Obriši kopiju';

  @override
  String get backupScreenScheduledBackup => 'Zakazani backup';

  @override
  String get backupScreenOnceADay => 'Jednom dnevno, u sat naveden ispod';

  @override
  String backupScreenExplain(String folder) {
    return 'Originali i baza, šifrirano. Odredište je mapa unutar $folder ili adresa s3: ili b2:. Zapišite lozinku negdje izvan ovog servera.';
  }

  @override
  String get backupScreenBackupFolder => 'mape za backup';

  @override
  String get backupScreenDestination => 'Odredište';

  @override
  String get backupScreenPasswordSaved =>
      'Lozinka (spremljena, upišite za promjenu)';

  @override
  String get backupScreenBackupPassword => 'Lozinka backupa';

  @override
  String get backupScreenAccessKeySaved => 'Pristupni ključ (spremljen)';

  @override
  String get backupScreenAccessKey => 'Pristupni ključ (S3, B2)';

  @override
  String get backupScreenSecretKey => 'Tajni ključ (S3, B2)';

  @override
  String get backupScreenHourOfDay => 'Sat u danu (0-23)';

  @override
  String get backupScreenBackUpNow => 'Backup sada';

  @override
  String get backupScreenTestBringingBack => 'Testiraj vraćanje';

  @override
  String get backupScreenHistory => 'Povijest';

  @override
  String get backupScreenRunBackup => 'Backup';

  @override
  String get backupScreenRunRestoreTest => 'Test vraćanja';

  @override
  String backupScreenFiles(String count) {
    return 'datoteka: $count';
  }

  @override
  String get backupScreenMyCopyAtOthers => 'Moja kopija kod drugih';

  @override
  String get backupScreenTwoServers =>
      'Dva Mediarra čuvaju šifriranu kopiju jedan drugoga. Onaj tko čuva ne može je pročitati, a što se obriše, čuva još 90 dana.';

  @override
  String get backupScreenNoHttps => 'Bez HTTPS-a';

  @override
  String get backupScreenMore => 'Više';

  @override
  String get backupScreenRemove => 'Ukloni';

  @override
  String get backupScreenCodeFromOther => 'Kod od drugog Mediarra';

  @override
  String get backupScreenScanQr => 'Skeniraj QR kod';

  @override
  String get backupScreenPairing => 'Uparujem…';

  @override
  String get backupScreenPair => 'Upari';

  @override
  String get backupScreenSnapshots => 'Snimke prije nadogradnje';

  @override
  String get backupScreenSnapshotsExplain =>
      'Prije svake nadogradnje koja mijenja bazu Mediarr sam spremi snimku baze. Čuvaju se zadnje tri.';

  @override
  String get backupScreenNoSnapshots =>
      'Još nema snimki. Prva nastaje pri sljedećoj nadogradnji koja mijenja bazu.';

  @override
  String get backupScreenEarlierVersion => 'Ranija verzija';

  @override
  String get backupScreenDeleteSnapshot => 'Obriši snimku';

  @override
  String get backupScreenGoBackHow =>
      'Povratak na zadnju snimku, u mapi s docker-compose.yml:';

  @override
  String get backupScreenDeleteThisSnapshot => 'Obrisati ovu snimku?';

  @override
  String get backupScreenNoGoingBack => 'Na nju se više neće moći vratiti.';

  @override
  String get backupScreenDelete => 'Obriši';

  @override
  String get backupScreenNotDeleted => 'Nije obrisano.';

  @override
  String get backupScreenIKeepForOthers => 'Čuvam za druge';

  @override
  String get backupScreenNoNewCode => 'Nema novog koda.';

  @override
  String backupScreenFilesBroughtBack(String count) {
    return 'Vraćeno datoteka: $count.';
  }

  @override
  String get backupScreenNewCode => 'Novi kod';

  @override
  String get backupScreenResume => 'Nastavi';

  @override
  String get backupScreenStop => 'Zaustavi';

  @override
  String get backupScreenSize => 'Veličina';

  @override
  String get backupScreenBringBackDeleted => 'Vrati obrisano';

  @override
  String get backupScreenTitle => 'Backup';

  @override
  String get backupScreenLoadFailed => 'Postavke backupa se nisu učitale.';

  @override
  String get backupScreenScanTheCode => 'Skeniraj kod';

  @override
  String get duplicatesScreenFavorite => 'Favorit';

  @override
  String get duplicatesScreenOriginal => 'Original';

  @override
  String get duplicatesScreenSavedAgain => 'Kopija iz aplikacije';

  @override
  String get duplicatesScreenHasLocation => 'Ima lokaciju';

  @override
  String get duplicatesScreenHasDescription => 'Ima opis';

  @override
  String get duplicatesScreenNoDate => 'Bez datuma';

  @override
  String get duplicatesScreenReasonFavorite => 'favorit';

  @override
  String get duplicatesScreenReasonCameraOriginal => 'original iz kamere';

  @override
  String get duplicatesScreenReasonOthersSaved =>
      'ostale su kopije iz aplikacija';

  @override
  String get duplicatesScreenReasonHighestResolution => 'najveća razlučivost';

  @override
  String get duplicatesScreenReasonLargestFile => 'najveća datoteka';

  @override
  String get duplicatesScreenReasonEqual => 'jednake su, svejedno koja ostaje';

  @override
  String get duplicatesScreenReasonSharpest => 'najoštrija';

  @override
  String get duplicatesScreenCancel => 'Odustani';

  @override
  String get duplicatesScreenResolveThisGroup => 'Riješiti ovu grupu?';

  @override
  String get duplicatesScreenKeptTakesOver =>
      'Zadržana fotka preuzima albume, oznake, favorit, opis, ocjenu, lokaciju i imena osoba od ostalih. One idu u smeće i mogu se vratiti.';

  @override
  String get duplicatesScreenResolve => 'Riješi';

  @override
  String get duplicatesScreenResolved => 'Riješeno. Kopije su u smeću.';

  @override
  String get duplicatesScreenActionFailed => 'Radnja nije uspjela.';

  @override
  String get duplicatesScreenResolveEveryIdentical =>
      'Riješiti sve iste slike?';

  @override
  String get duplicatesScreenResolveAllDuplicates => 'Riješiti sve duplikate?';

  @override
  String duplicatesScreenResolveAllBody(
    String groups,
    String trashed,
    String size,
  ) {
    return 'Grupa: $groups. U smeće ide $trashed fotki, što oslobađa $size kad se smeće isprazni. U svakoj grupi ostaje predložena fotka i preuzima ono što su imale ostale.';
  }

  @override
  String get duplicatesScreenResolveAll => 'Riješi sve';

  @override
  String get duplicatesScreenSamePicture => 'Ista slika';

  @override
  String get duplicatesScreenAlike => 'Slične';

  @override
  String duplicatesScreenProposedToKeep(String reason, String size) {
    return 'Predlažem zadržati: $reason · oslobađa $size';
  }

  @override
  String get duplicatesScreenNotDuplicates => 'Nisu duplikati';

  @override
  String duplicatesScreenResolveToTrash(String count) {
    return 'Riješi ($count u smeće)';
  }

  @override
  String get duplicatesScreenTitle => 'Duplikati';

  @override
  String get duplicatesScreenLoadFailed => 'Duplikati se nisu učitali.';

  @override
  String duplicatesScreenPending(String count) {
    return 'Još se uspoređuje fotki: $count.';
  }

  @override
  String get duplicatesScreenNoneFound => 'Nisu pronađene slične fotke.';

  @override
  String get duplicatesScreenTickWhatToKeep =>
      'Označite što zadržati. Ovo su samo prijedlozi i ništa se ne briše bez vaše potvrde.';

  @override
  String duplicatesScreenShowing(String shown, String total) {
    return 'Prikazano $shown od $total.';
  }

  @override
  String duplicatesScreenResolving(String done, String total) {
    return 'Rješavam duplikate: $done od $total';
  }

  @override
  String duplicatesScreenResolveIdentical(String count) {
    return 'Riješi iste ($count)';
  }

  @override
  String duplicatesScreenResolveAllAsProposed(String count) {
    return 'Riješi sve po prijedlogu ($count)';
  }

  @override
  String get duplicatesScreenStackLoadFailed => 'Ovaj niz se nije učitao.';

  @override
  String get duplicatesScreenSplitStack => 'Razdvoji';

  @override
  String get duplicatesScreenMakeMain => 'Postavi kao glavnu';

  @override
  String accountSheetVersionBuild(String version, String build) {
    return '$version build $build';
  }

  @override
  String get accountSheetEditProfile => 'Uredi profil';

  @override
  String get accountSheetClose => 'Zatvori';

  @override
  String accountSheetPhotosAndVideos(String count) {
    return '$count fotki i videa';
  }

  @override
  String accountSheetUsed(String size) {
    return '$size zauzeto';
  }

  @override
  String accountSheetFilesFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count datoteka se nije moglo obraditi',
      few: '$count datoteke se nisu mogle obraditi',
      one: '$count datoteka se nije mogla obraditi',
    );
    return '$_temp0';
  }

  @override
  String get accountSheetAppearance => 'Izgled';

  @override
  String get accountSheetDark => 'Tamno';

  @override
  String get accountSheetLight => 'Svijetlo';

  @override
  String get accountSheetSystem => 'Sustav';

  @override
  String get accountSheetServerDisk => 'Disk servera';

  @override
  String get accountSheetLoading => 'Učitavanje…';

  @override
  String get accountSheetServerNoAnswer => 'Server ne odgovara.';

  @override
  String accountSheetDiskUsed(String used, String total) {
    return 'Zauzeto $used od $total';
  }

  @override
  String get accountSheetAppVersion => 'Verzija aplikacije';

  @override
  String get accountSheetServerVersion => 'Verzija servera';

  @override
  String get accountSheetNewVersion => 'Nova verzija';

  @override
  String accountSheetIsAvailable(String version) {
    return '$version je dostupna';
  }

  @override
  String get accountSheetServer => 'Server';

  @override
  String get accountSheetServerAddress => 'Adresa servera';

  @override
  String get accountSheetFreeUpSpace => 'Oslobodi prostor';

  @override
  String get accountSheetProfile => 'Profil';

  @override
  String get accountSheetSignInOnAnotherDevice => 'Prijava na drugom uređaju';

  @override
  String get accountSheetBackupDevices => 'Uređaji za backup';

  @override
  String get accountSheetImport => 'Uvoz';

  @override
  String get accountSheetAdministration => 'Administracija';

  @override
  String get accountSheetBackup => 'Backup';

  @override
  String get accountSheetAllBackupDevices => 'Svi uređaji za backup';

  @override
  String get accountSheetStorageTemplate => 'Predložak pohrane';

  @override
  String get accountSheetSettings => 'Postavke';

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
  String get searchFiltersSheetAll => 'Sve';

  @override
  String get searchFiltersSheetPhotos => 'Fotke';

  @override
  String get searchFiltersSheetVideos => 'Videi';

  @override
  String get searchFiltersSheetPeople => 'Osobe';

  @override
  String get searchFiltersSheetAnyOfThem => 'Bilo koja od njih, ne sve zajedno';

  @override
  String get searchFiltersSheetWhereAndWith => 'Gdje i čime';

  @override
  String get searchFiltersSheetPlace => 'Mjesto';

  @override
  String get searchFiltersSheetCamera => 'Kamera';

  @override
  String get searchFiltersSheetLens => 'Objektiv';

  @override
  String get searchFiltersSheetRating => 'Ocjena';

  @override
  String get searchFiltersSheetAnyRating => 'Bilo koja';

  @override
  String get searchFiltersSheetTags => 'Oznake';

  @override
  String get searchFiltersSheetAlbum => 'Album';

  @override
  String get searchFiltersSheetAnyAlbum => 'Bilo koji';

  @override
  String get searchFiltersSheetInNoAlbum => 'Nije ni u jednom albumu';

  @override
  String get searchFiltersSheetFavouritesOnly => 'Samo favoriti';

  @override
  String get searchFiltersSheetClear => 'Očisti';

  @override
  String get searchFiltersSheetApply => 'Primijeni';

  @override
  String get adminEmailPortNumber => 'Port mora biti broj.';

  @override
  String get adminEmailSaved => 'Postavke e-pošte su spremljene.';

  @override
  String get adminEmailTestSent => 'Probna poruka vam je poslana.';

  @override
  String get adminEmailTitle => 'E-pošta';

  @override
  String get adminEmailSendEmail => 'Šalji e-poštu';

  @override
  String get adminEmailSmtpServer => 'SMTP server';

  @override
  String get adminEmailPort => 'Port';

  @override
  String get adminEmailEncryption => 'Šifriranje';

  @override
  String get adminEmailNone => 'Bez zaštite';

  @override
  String get adminEmailUserName => 'Korisničko ime';

  @override
  String get adminEmailPassword => 'Lozinka';

  @override
  String get adminEmailPasswordSaved =>
      'Lozinka je spremljena. Prazno je zadržava.';

  @override
  String get adminEmailFrom => 'Pošiljatelj';

  @override
  String get adminEmailServerAddress => 'Adresa ovog servera';

  @override
  String get adminEmailForLinks => 'Za poveznice u porukama';

  @override
  String get adminEmailSave => 'Spremi';

  @override
  String get adminEmailSendTest => 'Pošalji probnu poruku';

  @override
  String photoEditorScreenActionFailed(String reason) {
    return 'Radnja nije uspjela. $reason';
  }

  @override
  String get photoEditorScreenEdit => 'Uredi';

  @override
  String get photoEditorScreenRotate => 'Okreni';

  @override
  String get photoEditorScreenBrightness => 'Svjetlina';

  @override
  String get photoEditorScreenContrast => 'Kontrast';

  @override
  String get photoEditorScreenSaturation => 'Zasićenost';

  @override
  String get photoEditorScreenNoFilter => 'Bez filtera';

  @override
  String get photoEditorScreenBlackAndWhite => 'Crno-bijelo';

  @override
  String get photoEditorScreenWarm => 'Toplo';

  @override
  String get photoEditorScreenCool => 'Hladno';

  @override
  String get photoEditorScreenVintage => 'Staro';

  @override
  String get photoEditorScreenVivid => 'Živo';

  @override
  String get photoEditorScreenBackToOriginal => 'Vrati original';

  @override
  String get photoEditorScreenSave => 'Spremi';

  @override
  String get homeWidgetScreenHowToIos =>
      'Zatim dodirnite i držite prazno mjesto na početnom zaslonu, dodirnite + (ili Uredi, Dodaj widget) i odaberite Mediarr.';

  @override
  String get homeWidgetScreenHowToAndroid =>
      'Zatim dodirnite i držite prazno mjesto na početnom zaslonu, dodirnite Widgeti i povucite Mediarr na njega.';

  @override
  String get homeWidgetScreenFetchesItself =>
      'Widget sam dohvaća fotke i čuva ih nekoliko.';

  @override
  String get homeWidgetScreenFetching => 'Dohvaća fotke…';

  @override
  String homeWidgetScreenPicturesKept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotki spremljeno za njega na ovom mobitelu',
      few: '$count fotke spremljene za njega na ovom mobitelu',
      one: '$count fotka spremljena za njega na ovom mobitelu',
    );
    return '$_temp0';
  }

  @override
  String get homeWidgetScreenDidNotWork => 'Nije uspjelo.';

  @override
  String get homeWidgetScreenTitle => 'Widget na početnom zaslonu';

  @override
  String homeWidgetScreenIntro(String howTo) {
    return 'Widget prikazuje fotku iz albuma koji ovdje odaberete, svaki sat drugu, i bez veze. $howTo';
  }

  @override
  String homeWidgetScreenShowing(String album) {
    return 'Prikazuje $album';
  }

  @override
  String get homeWidgetScreenShowsNothing => 'Widget sada ništa ne prikazuje.';

  @override
  String get homeWidgetScreenTurnOff => 'Isključi';

  @override
  String get homeWidgetScreenAlbum => 'Album';

  @override
  String get homeWidgetScreenNoAlbums => 'Još nema albuma.';

  @override
  String homeWidgetScreenShows(String album) {
    return 'Widget prikazuje $album.';
  }

  @override
  String get homeWidgetNoKey => 'Server nije napravio ključ za widget.';

  @override
  String get settingsAccentMidnightBlue => 'Ponoćno plava';

  @override
  String get settingsAccentGold => 'Zlatna';

  @override
  String get settingsAccentViolet => 'Ljubičasta';

  @override
  String get settingsAccentMint => 'Metvica';

  @override
  String get settingsAccentRose => 'Ružičasta';

  @override
  String get settingsThemeAuto => 'Automatski';

  @override
  String get settingsThemeLight => 'Svijetlo';

  @override
  String get settingsThemeDark => 'Tamno';

  @override
  String get homeScreenMedia => 'Mediji';

  @override
  String get homeScreenSearch => 'Pretraga';

  @override
  String get homeScreenAlbums => 'Albumi';

  @override
  String get homeScreenLibrary => 'Biblioteka';

  @override
  String get homeScreenAdd => 'Dodaj';

  @override
  String homeScreenAddUploading(String count) {
    return 'Dodaj, prenosi se $count';
  }

  @override
  String get panoramaViewCannotBeShown => 'Panorama se ne može prikazati.';

  @override
  String get panoramaViewLabel => 'Panorama od 360°';

  @override
  String fixSheetChanged(int changed) {
    return 'Promijenjeno: $changed';
  }

  @override
  String get fixSheetCameraClockWrong => 'Kad je sat fotoaparata bio kriv.';

  @override
  String get fixSheetEarlier => 'Ranije';

  @override
  String get fixSheetLater => 'Kasnije';

  @override
  String get fixSheetDays => 'Dana';

  @override
  String get fixSheetHours => 'Sati';

  @override
  String get fixSheetMinutes => 'Minuta';

  @override
  String get fixSheetOneDateForAll =>
      'Isti datum svima, minutu razmaka, da ostanu u svom redu.';

  @override
  String get fixSheetChooseDateTime => 'Odaberi datum i vrijeme';

  @override
  String get fixSheetTripHint =>
      'Kad je fotoaparat na putu ostao na domaćem vremenu.';

  @override
  String get fixSheetCameraClockWasOn => 'Sat fotoaparata bio je na';

  @override
  String get fixSheetTheyWereTakenIn => 'Snimljene su u';

  @override
  String get fixSheetZoneFromPlaceHint =>
      'Fotke s lokacijom dobiju vremensku zonu mjesta (s ljetnim vremenom); sat ostaje kakav je bio.';

  @override
  String get fixSheetDatesByHandRemoved => 'Ručno postavljeni datumi se brišu.';

  @override
  String get fixSheetNeighboursHint =>
      'Fotke bez lokacije dobiju mjesto fotke s lokacijom snimljene najbliže njima.';

  @override
  String get fixSheetAtMostMinutesApart => 'Najviše minuta razmaka';

  @override
  String get fixSheetTrackHint =>
      'Fotke bez lokacije dobiju mjesto iz traga u trenutku snimanja. Najprije ispravite datum.';

  @override
  String get fixSheetChooseGpx => 'Odaberi GPX datoteku';

  @override
  String get fixSheetFindPlace => 'Pronađi mjesto';

  @override
  String get fixSheetLatitude => 'Širina';

  @override
  String get fixSheetLongitude => 'Dužina';

  @override
  String get fixSheetLocationGoes => 'Lokacija se makne i ostaje maknuta.';

  @override
  String get fixSheetLocationsByHandRemoved =>
      'Ručno postavljene lokacije se brišu.';

  @override
  String fixSheetDateTitle(int count) {
    return 'Datum i vrijeme · $count';
  }

  @override
  String fixSheetLocationTitle(int count) {
    return 'Lokacija · $count';
  }

  @override
  String get fixSheetShift => 'Pomakni';

  @override
  String get fixSheetSetDate => 'Postavi datum';

  @override
  String get fixSheetZoneFromPlace => 'Zona s lokacije';

  @override
  String get fixSheetTrip => 'Putovanje';

  @override
  String get fixSheetFromFile => 'Iz datoteke';

  @override
  String get fixSheetFromNearby => 'Od susjednih fotki';

  @override
  String get fixSheetFromTrack => 'Iz GPX traga';

  @override
  String get fixSheetSetPlace => 'Postavi mjesto';

  @override
  String get fixSheetClearLocation => 'Makni lokaciju';

  @override
  String fixSheetWillChange(int changed) {
    return 'Promijenit će se: $changed';
  }

  @override
  String fixSheetNothingToGoBy(int skipped) {
    return 'bez podataka za to: $skipped';
  }

  @override
  String get fixSheetNoLocation => 'bez lokacije';

  @override
  String get fixSheetCancel => 'Odustani';

  @override
  String get fixSheetSave => 'Spremi';

  @override
  String get adminSecurityRulesSaved => 'Pravila su spremljena.';

  @override
  String get adminSecuritySsoSaved => 'Jedinstvena prijava je spremljena.';

  @override
  String get adminSecurityForgetTitle => 'Zaboraviti ovaj uređaj?';

  @override
  String adminSecurityApproveAgain(String email) {
    return '$email na njemu morat će se ponovno odobriti.';
  }

  @override
  String get adminSecurityCancel => 'Odustani';

  @override
  String get adminSecurityForget => 'Zaboravi';

  @override
  String get adminSecurityDeviceForgotten => 'Uređaj je zaboravljen.';

  @override
  String get adminSecurityTitle => 'Sigurnost';

  @override
  String get adminSecuritySingleSignOn => 'Jedinstvena prijava';

  @override
  String get adminSecurityIssuer => 'Izdavatelj';

  @override
  String get adminSecurityIssuerHelp => 'Prazno isključuje jedinstvenu prijavu';

  @override
  String get adminSecurityClientId => 'Client ID';

  @override
  String get adminSecurityClientSecret => 'Client secret';

  @override
  String get adminSecuritySecretSaved =>
      'Secret je spremljen. Prazno ga zadržava.';

  @override
  String get adminSecurityButtonLabel => 'Natpis na gumbu';

  @override
  String get adminSecurityAutoCreate => 'Stvori račun pri prvoj prijavi';

  @override
  String get adminSecurityLinkAdmins =>
      'Administratori se smiju prijaviti na ovaj način';

  @override
  String get adminSecuritySaveSso => 'Spremi jedinstvenu prijavu';

  @override
  String get adminSecurityRules => 'Pravila';

  @override
  String get adminSecurityApprovalRequired =>
      'Novi uređaji moraju biti odobreni';

  @override
  String get adminSecurityAllowlist =>
      'Samo ove adrese smiju pristupiti serveru';

  @override
  String adminSecurityYourAddress(String address) {
    return 'Vaša adresa sada: $address';
  }

  @override
  String get adminSecurityAddresses => 'Adrese i mreže';

  @override
  String get adminSecurityAddressesHelp => 'Jedna u retku, npr. 192.168.1.0/24';

  @override
  String get adminSecuritySaveRules => 'Spremi pravila';

  @override
  String get adminSecurityDevices => 'Uređaji';

  @override
  String get adminSecurityNoDevices =>
      'Još se nijedan uređaj nije pokušao prijaviti.';

  @override
  String adminSecurityLastSeen(String time) {
    return 'zadnji put $time';
  }

  @override
  String get adminSecurityDeviceApproved => 'Uređaj se smije prijaviti.';

  @override
  String get adminSecurityApprove => 'Odobri';

  @override
  String get adminSecurityAttempts => 'Pokušaji pristupa';

  @override
  String get adminSecuritySignedIn => 'Prijava uspjela';

  @override
  String get adminSecurityWrongSignIn => 'Pogrešna prijava';

  @override
  String get adminSecurityTooManyAttempts => 'Previše pokušaja';

  @override
  String get adminSecurityAddressBlocked => 'Adresa blokirana';

  @override
  String get adminSecurityDeviceNotApproved => 'Uređaj nije odobren';

  @override
  String get adminSecurityPasswordReset => 'Ponovno postavljanje lozinke';

  @override
  String get adminSecurityNoAttempts => 'Još nema pokušaja.';

  @override
  String get adminSecurityShowOlder => 'Prikaži starije';

  @override
  String adminCommonNoAnswer(String code) {
    return 'Server nije odgovorio ($code).';
  }

  @override
  String get devicesScreenQuiet => 'Šuti';

  @override
  String get devicesScreenNeedsALook => 'Treba pogledati';

  @override
  String get devicesScreenAllGood => 'U redu';

  @override
  String devicesScreenConfirmed(String count) {
    return '$count datoteka potvrdio je server';
  }

  @override
  String devicesScreenOfSent(String line, String files) {
    return '$line, od $files koje je uređaj poslao';
  }

  @override
  String devicesScreenWaiting(String count) {
    return 'čeka $count';
  }

  @override
  String devicesScreenNotSent(String count) {
    return 'nije poslano $count';
  }

  @override
  String devicesScreenInTrash(String count) {
    return 'u smeću $count';
  }

  @override
  String devicesScreenGone(String count) {
    return 'više nije na serveru $count';
  }

  @override
  String get devicesScreenNever => 'Nikad';

  @override
  String devicesScreenDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dana',
      few: '$days dana',
      one: '$days dan',
    );
    return '$_temp0';
  }

  @override
  String get devicesScreenNotLoaded => 'Nije učitano.';

  @override
  String devicesScreenRemoveTitle(String name) {
    return 'Ukloniti $name?';
  }

  @override
  String get devicesScreenRemoveBody =>
      'Fotke ostaju na serveru. Ako uređaj opet javi, vratit će se.';

  @override
  String get devicesScreenCancel => 'Odustani';

  @override
  String get devicesScreenRemove => 'Ukloni';

  @override
  String get devicesScreenNotRemoved => 'Nije maknuto.';

  @override
  String get devicesScreenSaved => 'Spremljeno.';

  @override
  String get devicesScreenNotSaved => 'Nije spremljeno.';

  @override
  String devicesScreenThisPhone(String name) {
    return '$name · Ovaj mobitel';
  }

  @override
  String devicesScreenLastReport(String time) {
    return 'zadnje javljanje $time';
  }

  @override
  String devicesScreenOnDevice(String verified, String total) {
    return '$verified od $total na uređaju';
  }

  @override
  String get devicesScreenQuietWarning =>
      'Nije se javio dulje nego što ste odredili. Otvorite Mediarr na njemu i provjerite je li backup uključen.';

  @override
  String get devicesScreenNothingMissing => 'Ništa ne nedostaje.';

  @override
  String get devicesScreenInTrashOnServer => 'u smeću na serveru';

  @override
  String get devicesScreenDeletedFromServer => 'obrisano sa servera';

  @override
  String get devicesScreenWhatIsMissing => 'Što nedostaje';

  @override
  String get devicesScreenHide => 'Sakrij';

  @override
  String get devicesScreenTryingAgain => 'Pokušavam ponovno.';

  @override
  String get devicesScreenTryAgain => 'Pokušaj ponovno';

  @override
  String get devicesScreenAllBackupDevices => 'Svi uređaji za backup';

  @override
  String get devicesScreenBackupDevices => 'Uređaji za backup';

  @override
  String get devicesScreenAllIntro =>
      'Uređaji svih korisnika koji rade backup. Upozorenje kad uređaj šuti dobiva njegov vlasnik.';

  @override
  String get devicesScreenIntro =>
      'Mobiteli koji rade backup, i koliko je s njih sigurno na serveru. Broji server, prema vlastitim datotekama.';

  @override
  String get devicesScreenDidNotLoad =>
      'Uređaji nisu učitani. Povucite za ponovni pokušaj.';

  @override
  String get devicesScreenNoneReported => 'Još nijedan uređaj nije javio.';

  @override
  String get devicesScreenNoneReportedTurnOn =>
      'Još nijedan uređaj nije javio. Uključite automatski backup u Uploadu.';

  @override
  String get devicesScreenWarnMeAfter => 'Upozori me nakon';

  @override
  String get devicesScreenWarnHelp =>
      'Obavijest ovdje i na webu, i e-poštom ako je postavljena. Jednom, dok se uređaj opet ne javi.';

  @override
  String timelineScreenActionFailed(String message) {
    return 'Radnja nije uspjela. $message';
  }

  @override
  String get timelineScreenSetVaultPin =>
      'Najprije postavite PIN trezora: Račun > Trezor.';

  @override
  String timelineScreenDeleteTitle(String count) {
    return 'Obrisati $count?';
  }

  @override
  String get timelineScreenTrashRestorable =>
      'Premještaju se u smeće, gdje se mogu vratiti.';

  @override
  String timelineScreenTrashDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dana',
      few: '$days dana',
      one: '$days dan',
    );
    return 'Premještaju se u smeće, gdje ostaju $_temp0 i mogu se vratiti.';
  }

  @override
  String get timelineScreenCancel => 'Odustani';

  @override
  String get timelineScreenDelete => 'Obriši';

  @override
  String get timelineScreenLoadFailed =>
      'Fotke se nisu učitale. Provjerite vezu.';

  @override
  String get timelineScreenTryAgain => 'Pokušaj ponovno';

  @override
  String get timelineScreenEmpty =>
      'Još nema fotki. Dodajte prve na kartici Upload.';

  @override
  String get timelineScreenMedia => 'Mediji';

  @override
  String get timelineScreenClearSelection => 'Poništi odabir';

  @override
  String get timelineScreenAddToAlbum => 'Dodaj u album';

  @override
  String get timelineScreenShare => 'Dijeli';

  @override
  String get timelineScreenAddToFavorites => 'Dodaj u favorite';

  @override
  String get timelineScreenMore => 'Više';

  @override
  String get timelineScreenArchive => 'Arhiviraj';

  @override
  String get timelineScreenAddTag => 'Dodaj oznaku';

  @override
  String get timelineScreenDateTimeMenu => 'Datum i vrijeme…';

  @override
  String get timelineScreenLocationMenu => 'Lokacija…';

  @override
  String get timelineScreenMoveToVault => 'Premjesti u trezor';

  @override
  String timelineScreenMonthFailed(String month) {
    return '$month se nije učitao. Pokušaj ponovno.';
  }

  @override
  String agentProgramOnSystem(String program, String system) {
    return '$program na $system';
  }

  @override
  String get agentUnknownDevice => 'Nepoznat uređaj';

  @override
  String get agentMediarrApp => 'Aplikacija Mediarr';

  @override
  String get agentNow => 'sada';

  @override
  String agentMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'prije $count minuta',
      few: 'prije $count minute',
      one: 'prije $count minutu',
    );
    return '$_temp0';
  }

  @override
  String agentHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'prije $count sati',
      few: 'prije $count sata',
      one: 'prije $count sat',
    );
    return '$_temp0';
  }

  @override
  String agentDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'prije $count dana',
      few: 'prije $count dana',
      one: 'prije $count dan',
    );
    return '$_temp0';
  }

  @override
  String agentWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'prije $count tjedana',
      few: 'prije $count tjedna',
      one: 'prije $count tjedan',
    );
    return '$_temp0';
  }

  @override
  String agentMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'prije $count mjeseci',
      few: 'prije $count mjeseca',
      one: 'prije $count mjesec',
    );
    return '$_temp0';
  }

  @override
  String agentYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'prije $count godina',
      few: 'prije $count godine',
      one: 'prije $count godinu',
    );
    return '$_temp0';
  }

  @override
  String get slideshowScreenCrossfade => 'Pretapanje';

  @override
  String get slideshowScreenSlide => 'Klizanje';

  @override
  String get slideshowScreenSlowZoom => 'Polagani zoom';

  @override
  String get slideshowScreenNone => 'Bez prijelaza';

  @override
  String get slideshowScreenSettings => 'Postavke slideshowa';

  @override
  String get slideshowScreenPace => 'Tempo';

  @override
  String get slideshowScreenTransition => 'Prijelaz';

  @override
  String get slideshowScreenShuffle => 'Nasumično';

  @override
  String get slideshowScreenLoop => 'Ponavljaj';

  @override
  String get slideshowScreenDateAndPlace => 'Datum i mjesto';

  @override
  String get slideshowScreenTheEnd => 'Kraj.';

  @override
  String get slideshowScreenPrevious => 'Prethodna';

  @override
  String get slideshowScreenPlay => 'Pokreni';

  @override
  String get slideshowScreenPause => 'Pauza';

  @override
  String get slideshowScreenNext => 'Sljedeća';

  @override
  String get slideshowScreenClose => 'Zatvori';

  @override
  String notificationsAlbumShared(String subject) {
    return 'S vama je podijeljen album „$subject”';
  }

  @override
  String notificationsImportDone(String subject) {
    return 'Uvoz iz izvora $subject je završen';
  }

  @override
  String notificationsImportFailed(String subject) {
    return 'Uvoz iz izvora $subject nije uspio';
  }

  @override
  String notificationsDeviceQuiet(String subject) {
    return '$subject je prestao raditi backup';
  }

  @override
  String notificationsCopyForLate(String name) {
    return 'Kopija za $name nije poslana već tri dana';
  }

  @override
  String notificationsCopyFromLate(String name) {
    return 'Kopija od $name nije stigla već tri dana';
  }

  @override
  String notificationsBackupFailed(String subject) {
    return 'Sigurnosna kopija nije uspjela: $subject';
  }

  @override
  String get notificationsTitle => 'Obavijesti';

  @override
  String get notificationsNotRemoved => 'Ovo se nije moglo ukloniti.';

  @override
  String get notificationsNotLoaded => 'Ovo se nije moglo učitati.';

  @override
  String get notificationsNone => 'Nema obavijesti.';

  @override
  String get notificationsRemove => 'Ukloni';

  @override
  String assetFactsNotSaved(String message) {
    return 'Nije spremljeno. $message';
  }

  @override
  String get assetFactsEditDetails => 'Uredi podatke';

  @override
  String get assetFactsDateAndTime => 'Datum i vrijeme';

  @override
  String get assetFactsFindPlace => 'Pronađi mjesto';

  @override
  String get assetFactsLatitude => 'Geografska širina';

  @override
  String get assetFactsLongitude => 'Geografska dužina';

  @override
  String get assetFactsDescription => 'Opis';

  @override
  String get assetFactsUseFile => 'Koristi podatke iz datoteke';

  @override
  String get assetFactsCancel => 'Odustani';

  @override
  String get assetFactsSave => 'Spremi';

  @override
  String assetFactsStars(String stars) {
    return '$stars od 5 zvjezdica';
  }

  @override
  String get documentsScreenNotEnabled =>
      'Administrator nije uključio ovaj album.';

  @override
  String get documentsScreenNeedsAnalysis =>
      'Za ovo treba uključiti analizu slika.';

  @override
  String get documentsScreenNoText => 'Još nema fotki s tekstom.';

  @override
  String get documentsScreenLoadFailed => 'Dokumenti se nisu učitali.';

  @override
  String get documentsScreenTitle => 'Dokumenti';

  @override
  String get sharingNoPhotoAccess =>
      'Mediarr ne smije dodavati fotke na ovaj mobitel';

  @override
  String get backupNoDeviceKey => 'Server nije stvorio ključ uređaja.';

  @override
  String get foldersScreenFolders => 'Mape';

  @override
  String get foldersScreenLoadFailed => 'Mapa se nije učitala.';

  @override
  String get foldersScreenNoExternalLibrary =>
      'Nemate vanjsku biblioteku. Administrator je postavlja u Postavkama.';

  @override
  String get foldersScreenEmpty => 'Ova mapa je prazna.';

  @override
  String get searchQueryNoName => 'Bez imena';

  @override
  String get searchQueryVideos => 'Videi';

  @override
  String get searchQueryPhotos => 'Fotke';

  @override
  String searchQueryInAlbum(String title) {
    return 'U albumu: $title';
  }

  @override
  String get searchQueryInNoAlbum => 'Nije u albumu';

  @override
  String get searchQueryFavourites => 'Favoriti';

  @override
  String get exploreScreenExplore => 'Istraži';

  @override
  String get exploreScreenPeople => 'Osobe';

  @override
  String get exploreScreenPlaces => 'Mjesta';

  @override
  String get exploreScreenMemories => 'Uspomene';

  @override
  String get exploreScreenPeopleFailed => 'Osobe se nisu učitale.';

  @override
  String get exploreScreenNoNamedPeople => 'Još nema osoba s imenom.';

  @override
  String get exploreScreenPlacesFailed => 'Mjesta se nisu učitala.';

  @override
  String get exploreScreenNoPlaces => 'Još nema fotki s mjestom.';

  @override
  String get exploreScreenMemoriesFailed => 'Uspomene se nisu učitale.';

  @override
  String get exploreScreenNoMemories => 'Danas nema uspomena.';

  @override
  String get exploreScreenAllPeople => 'Sve osobe';

  @override
  String get exploreScreenAllPlaces => 'Sva mjesta';

  @override
  String get exploreScreenAllMemories => 'Sve uspomene';

  @override
  String sharedScreenActionFailed(String reason) {
    return 'Radnja nije uspjela. $reason';
  }

  @override
  String get sharedScreenWholeLibrary => 'Cijela biblioteka';

  @override
  String sharedScreenFrom(String date) {
    return 'Od $date';
  }

  @override
  String get sharedScreenLoadFailed => 'Ovo se nije učitalo. Provjerite vezu.';

  @override
  String get sharedScreenTryAgain => 'Pokušaj ponovno';

  @override
  String get sharedScreenAlbumsWithMe => 'Albumi podijeljeni sa mnom';

  @override
  String get sharedScreenNothingShared => 'Još ništa nije podijeljeno.';

  @override
  String get sharedScreenLibrariesWithMe => 'Biblioteke podijeljene sa mnom';

  @override
  String get sharedScreenNobodyShares =>
      'Nitko s vama ne dijeli svoju biblioteku.';

  @override
  String get sharedScreenShowInMyMedia => 'Prikaži u mojim Medijima';

  @override
  String get sharedScreenMyLibrarySharedWith =>
      'Moja biblioteka je podijeljena s';

  @override
  String get sharedScreenNobodyYet => 'Još ni s kim.';

  @override
  String get sharedScreenStop => 'Prekini';

  @override
  String get sharedScreenUser => 'Korisnik';

  @override
  String get sharedScreenChooseDate => 'Odaberi datum';

  @override
  String get sharedScreenNeverShared =>
      'Arhiva, smeće i trezor se nikad ne dijele.';

  @override
  String get sharedScreenShareMyLibrary => 'Podijeli biblioteku';

  @override
  String get sharedScreenShared => 'Dijeljeno';

  @override
  String get sharedScreenLibraryNotAvailable => 'Ova biblioteka nije dostupna.';

  @override
  String get sharedScreenNoPhotos => 'Još nema fotki.';

  @override
  String get loginScreenEnterServerFirst =>
      'Najprije unesite adresu svog poslužitelja.';

  @override
  String get loginScreenAllowOnCodeScreen =>
      'Dopustite ovu prijavu na ekranu koji prikazuje kod.';

  @override
  String get loginScreenCancel => 'Odustani';

  @override
  String get loginScreenEnterTotp =>
      'Unesite 6-znamenkasti kod iz aplikacije za autentifikaciju.';

  @override
  String get loginScreenSignInToServer =>
      'Prijavite se na svoj Mediarr poslužitelj.';

  @override
  String get loginScreenCode => 'Kod';

  @override
  String get loginScreenServerAddress => 'Adresa poslužitelja';

  @override
  String get loginScreenEmail => 'E-adresa';

  @override
  String get loginScreenPassword => 'Lozinka';

  @override
  String get loginScreenVerify => 'Potvrdi';

  @override
  String get loginScreenSignIn => 'Prijavi se';

  @override
  String get loginScreenSingleSignOn => 'Koristi jedinstvenu prijavu';

  @override
  String get loginScreenScanQr => 'Skeniraj QR kod';

  @override
  String get loginScreenEnterSignInCode => 'Unesi kod za prijavu';

  @override
  String get loginScreenSignInCode => 'Kod za prijavu';

  @override
  String get qrSignInScanTitle => 'Skeniraj kod za prijavu';

  @override
  String get qrSignInScanHelp =>
      'Na ekranu na kojem ste prijavljeni otvorite izbornik računa i odaberite \"Prijava na mobitelu\".';

  @override
  String get qrSignInLooking => 'Tražim poslužitelje na ovoj mreži…';

  @override
  String get qrSignInNoneFound => 'Na ovoj mreži nema poslužitelja.';

  @override
  String get qrSignInOnThisNetwork => 'Na ovoj mreži';

  @override
  String get qrSignInLookAgain => 'Traži ponovno';

  @override
  String get qrSignInMakeCodeFailed => 'Kod se nije mogao napraviti.';

  @override
  String get qrSignInTheDevice => 'uređaj';

  @override
  String get qrSignInTitle => 'Prijava na drugom uređaju';

  @override
  String get qrSignInHowTo =>
      'U aplikaciji Mediarr na drugom uređaju dodirnite \"Skeniraj QR kod\" na ekranu za prijavu.';

  @override
  String get qrSignInQrLabel => 'QR kod za prijavu';

  @override
  String get qrSignInOrType => 'Ili upiši kod';

  @override
  String qrSignInValidFor(String time) {
    return 'Vrijedi još $time';
  }

  @override
  String qrSignInAllowOn(String device) {
    return 'Dopustiti prijavu: $device?';
  }

  @override
  String get qrSignInAllowOnlyIf =>
      'Dopustite samo ako ste upravo skenirali kod na svom uređaju.';

  @override
  String get qrSignInDeny => 'Odbij';

  @override
  String get qrSignInAllow => 'Dopusti';

  @override
  String qrSignInSignedIn(String device) {
    return 'Prijavljen: $device. Vidi se u Računu pod Uređaji.';
  }

  @override
  String get qrSignInDone => 'Gotovo';

  @override
  String get qrSignInDenied => 'Prijava je odbijena.';

  @override
  String get qrSignInExpired => 'Kod je istekao.';

  @override
  String get qrSignInNewCode => 'Novi kod';

  @override
  String get uploadScreenChoose =>
      'Odaberite fotke i videe s ovog uređaja da ih učitate.';

  @override
  String get uploadScreenOpenLibrary => 'Otvori galeriju';

  @override
  String get uploadScreenNeedsAccess =>
      'Mediarr treba pristup vašim fotkama. Dopustite ga u Postavkama.';

  @override
  String get uploadScreenOpenSettings => 'Otvori Postavke';

  @override
  String get uploadScreenNoPhotos => 'Na ovom uređaju nema fotki.';

  @override
  String uploadScreenUploadCount(String count) {
    return 'Učitaj $count';
  }

  @override
  String get uploadScreenQueued => 'Čeka';

  @override
  String get uploadScreenPreparing => 'Priprema se';

  @override
  String get uploadScreenUploaded => 'Poslano';

  @override
  String get uploadScreenAlreadyOnServer => 'Već je na poslužitelju';

  @override
  String get uploadScreenFailed => 'Nije uspjelo';

  @override
  String uploadScreenFinished(String done, String total) {
    return 'Završeno $done od $total';
  }

  @override
  String get uploadScreenClearFailed => 'Makni neuspjele';

  @override
  String get uploadScreenPhoto => 'Fotka';

  @override
  String get backupCardNothingYet => 'Još ništa nije spremljeno u backup.';

  @override
  String get backupCardLastJustNow => 'Zadnja datoteka spremljena upravo sada.';

  @override
  String backupCardLastMinutes(String minutes) {
    return 'Zadnja datoteka spremljena prije $minutes min.';
  }

  @override
  String backupCardLastHours(String hours) {
    return 'Zadnja datoteka spremljena prije $hours h.';
  }

  @override
  String backupCardLastDays(String days) {
    return 'Zadnja datoteka spremljena prije $days d.';
  }

  @override
  String backupCardScopeTitle(String album) {
    return 'Backup: \"$album\"';
  }

  @override
  String get backupCardScopeBody =>
      'Treba li poslati i fotke koje su već u ovom albumu? Ništa što je već na poslužitelju ne šalje se dvaput.';

  @override
  String get backupCardOnlyNew => 'Samo fotke dodane od sada';

  @override
  String get backupCardAlsoExisting => 'I one koje su sad u njemu';

  @override
  String get backupCardTheAddedAlbums => 'dodani albumi';

  @override
  String get backupCardNeedsFullAccess =>
      'Albumi trebaju pristup svim fotkama. Dopustite ga u Postavkama: Mediarr > Fotografije > Potpuni pristup.';

  @override
  String backupCardServerUnreachable(String reason) {
    return 'Poslužitelj nije dostupan. $reason';
  }

  @override
  String get backupCardAutomaticBackup => 'Automatski backup';

  @override
  String backupCardAlbum(String name) {
    return 'Album: $name';
  }

  @override
  String get backupCardChange => 'Promijeni';

  @override
  String get backupCardNeedsFullAccessNothingSent =>
      'Albumi trebaju pristup svim fotkama. Dopustite ga u Postavkama: Mediarr > Fotografije > Potpuni pristup. Ništa se ne šalje.';

  @override
  String get backupCardNoSuchAlbum =>
      'Na uređaju nema albuma s tim imenom. Ništa se ne šalje.';

  @override
  String backupCardMoreAlbums(String more, String never) {
    return 'Još albuma: $more, nikad se ne šalje: $never';
  }

  @override
  String get backupCardOnlyWifi => 'Samo na Wi-Fi mreži';

  @override
  String get backupCardOnlyCharging => 'Samo dok se puni';

  @override
  String backupCardVerified(String verified, String total) {
    return '$verified od $total potvrđeno na poslužitelju';
  }

  @override
  String backupCardCounts(String sending, String waiting, String failed) {
    return '$sending se šalje · $waiting čeka · $failed nije uspjelo';
  }

  @override
  String get backupCardPerDevice => 'Što poslužitelj potvrđuje, po uređaju';

  @override
  String get backupCardRefused =>
      'Poslužitelj je odbio ovaj uređaj. Isključite i ponovno uključite backup.';

  @override
  String get backupCardFreeUpSpace => 'Oslobodi prostor';

  @override
  String backupCardRetryFailed(String count) {
    return 'Ponovno pokušaj $count neuspjelih';
  }

  @override
  String get backupCardOffHelp =>
      'Šalje jedan album po vašem izboru i ništa drugo. Nove fotke traži svake minute dok je aplikacija otvorena. Kad je zatvorena, iOS odlučuje kada, često puno kasnije, i zaustavlja ga ako aplikaciju odgurnete.';

  @override
  String get backupCardWhichAlbum => 'Koji album?';

  @override
  String get backupCardAlbumName => 'Naziv albuma';

  @override
  String backupCardUseName(String name) {
    return 'Koristi naziv \"$name\"';
  }

  @override
  String get backupCardStartsWhenExists =>
      'Počinje kad album s tim nazivom postoji';

  @override
  String get backupCardNoAlbums =>
      'Na ovom uređaju još nema albuma. Napravite jedan u aplikaciji Fotografije.';

  @override
  String get backupCardNeverHelp =>
      'Fotka u albumu \"Nikad\" ne šalje se, čak i ako je i u drugom albumu.';

  @override
  String get backupCardNotAdded => 'Nije dodan';

  @override
  String get backupCardBackUp => 'Backup';

  @override
  String get backupCardNever => 'Nikad';

  @override
  String get backupCardSave => 'Spremi';

  @override
  String get albumSheetsOwner => 'Vlasnik';

  @override
  String get albumSheetsEditor => 'Urednik';

  @override
  String get albumSheetsContributor => 'Suradnik';

  @override
  String get albumSheetsViewer => 'Gledatelj';

  @override
  String get albumSheetsUploadOnly => 'samo upload';

  @override
  String get albumSheetsPassword => 'lozinka';

  @override
  String get albumSheetsWatermarkFact => 'watermark';

  @override
  String albumSheetsExpiresFact(String date) {
    return 'istječe $date';
  }

  @override
  String albumSheetsDownloadsFact(String count) {
    return 'preuzimanja: $count';
  }

  @override
  String get albumSheetsActionFailed => 'Radnja nije uspjela.';

  @override
  String get albumSheetsComments => 'Komentari';

  @override
  String get albumSheetsCommentsAndHearts => 'Komentari i srca';

  @override
  String get albumSheetsCommentsFailed => 'Komentari se nisu učitali.';

  @override
  String get albumSheetsHeart => 'Srce';

  @override
  String get albumSheetsNoComments => 'Još nema komentara.';

  @override
  String get albumSheetsDeleteComment => 'Obriši komentar';

  @override
  String get albumSheetsComment => 'Komentar';

  @override
  String get albumSheetsSend => 'Pošalji';

  @override
  String get albumSheetsAddToAlbum => 'Dodaj u album';

  @override
  String get albumSheetsAlbumsFailed => 'Albumi se nisu učitali.';

  @override
  String get albumSheetsNewAlbum => 'Novi album';

  @override
  String get albumSheetsCreateAndAdd => 'Stvori i dodaj';

  @override
  String get albumSheetsShareWithUsers => 'Dijeli s korisnicima';

  @override
  String get albumSheetsSharingFailed => 'Dijeljenje se nije učitalo.';

  @override
  String get albumSheetsNotShared => 'Album još nije podijeljen.';

  @override
  String get albumSheetsRemove => 'Ukloni';

  @override
  String get albumSheetsNoOtherUsers =>
      'Na ovom serveru nema drugih korisnika.';

  @override
  String get albumSheetsUser => 'Korisnik';

  @override
  String get albumSheetsRole => 'Uloga';

  @override
  String get albumSheetsAdd => 'Dodaj';

  @override
  String get albumSheetsPublicLinks => 'Javni linkovi';

  @override
  String get albumSheetsCopyNow =>
      'Kopirajte adresu sada: kasnije se više ne može prikazati.';

  @override
  String get albumSheetsCopy => 'Kopiraj';

  @override
  String get albumSheetsLinksFailed => 'Linkovi se nisu učitali.';

  @override
  String get albumSheetsUnnamedLink => 'Link bez naziva';

  @override
  String get albumSheetsRevoke => 'Opozovi';

  @override
  String get albumSheetsName => 'Naziv';

  @override
  String get albumSheetsPasswordOptional => 'Lozinka (nije obavezna)';

  @override
  String get albumSheetsNoExpiry => 'Bez isteka';

  @override
  String albumSheetsExpires(String date) {
    return 'Istječe $date';
  }

  @override
  String get albumSheetsChoose => 'Odaberi';

  @override
  String get albumSheetsDownloadLimit => 'Limit preuzimanja';

  @override
  String get albumSheetsWatermark => 'Watermark';

  @override
  String get albumSheetsWatermarkHelp =>
      'Watermark isključuje preuzimanje originala i reprodukciju videa.';

  @override
  String get albumSheetsAllowDownloads => 'Dopusti preuzimanje';

  @override
  String get albumSheetsShowLocation => 'Prikaži lokaciju';

  @override
  String get albumSheetsGuestsCanAdd => 'Gosti mogu dodavati';

  @override
  String get albumSheetsUploadOnlyLong => 'Samo upload (gosti ne vide album)';

  @override
  String get albumSheetsCreateLink => 'Stvori link';

  @override
  String get albumSheetsFromAnyDate => 'Od bilo kojeg datuma';

  @override
  String albumSheetsFrom(String date) {
    return 'Od $date';
  }

  @override
  String get albumSheetsToAnyDate => 'Do bilo kojeg datuma';

  @override
  String albumSheetsTo(String date) {
    return 'Do $date';
  }

  @override
  String get albumSheetsKind => 'Vrsta';

  @override
  String get albumSheetsAll => 'Sve';

  @override
  String get albumSheetsPhotos => 'Fotke';

  @override
  String get albumSheetsVideos => 'Videi';

  @override
  String get albumSheetsLivePhoto => 'Live Photo';

  @override
  String get albumSheetsCamera => 'Kamera';

  @override
  String get albumSheetsPerson => 'Osoba';

  @override
  String get albumSheetsTag => 'Oznaka';

  @override
  String get albumSheetsPlace => 'Mjesto';

  @override
  String get viewerScreenDeleteTitle => 'Obrisati fotku?';

  @override
  String get viewerScreenTrashNoDays =>
      'Premješta se u smeće, gdje se može vratiti.';

  @override
  String viewerScreenTrashDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dana',
      few: '$days dana',
      one: '$days dan',
    );
    return 'Premješta se u smeće, gdje ostaje $_temp0 i može se vratiti.';
  }

  @override
  String get viewerScreenCancel => 'Odustani';

  @override
  String get viewerScreenDelete => 'Obriši';

  @override
  String get viewerScreenActionFailed => 'Radnja nije uspjela.';

  @override
  String get viewerScreenNoVideo => 'Ova fotka nema video.';

  @override
  String get viewerScreenVideoFailed => 'Video se nije učitao.';

  @override
  String get viewerScreenStackShots => 'Snimke u ovom stogu';

  @override
  String get viewerScreenSlideshow => 'Prikaz fotki';

  @override
  String get viewerScreen360View => 'Prikaz 360°';

  @override
  String get viewerScreenFlatView => 'Ravni prikaz';

  @override
  String get viewerScreenPlayLive => 'Pokreni Live Photo';

  @override
  String get viewerScreenCommentsAndHearts => 'Komentari i srca';

  @override
  String get viewerScreenFavorite => 'Favorit';

  @override
  String get viewerScreenEdit => 'Uredi';

  @override
  String get viewerScreenShare => 'Podijeli';

  @override
  String get viewerScreenDetails => 'Podaci';

  @override
  String get viewerScreenPhotoFailed => 'Ova fotka se nije učitala.';

  @override
  String get viewerScreenCannotPlay =>
      'Ovaj video se ne može reproducirati na ovom uređaju.';

  @override
  String get viewerScreenDetailsFailed => 'Podaci se nisu učitali.';

  @override
  String get viewerScreenUnavailable => 'Nedostupno';

  @override
  String get viewerScreenMissingFile =>
      'Datoteka nije pronađena na zadnjem pregledu vanjske biblioteke. Original će opet biti dostupan kad se datoteka vrati.';

  @override
  String get viewerScreenName => 'Naziv';

  @override
  String get viewerScreenDescription => 'Opis';

  @override
  String get viewerScreenTaken => 'Snimljeno';

  @override
  String get viewerScreenAdded => 'Dodano';

  @override
  String get viewerScreenDimensions => 'Dimenzije';

  @override
  String get viewerScreenSize => 'Veličina';

  @override
  String get viewerScreenDuration => 'Trajanje';

  @override
  String get viewerScreenCamera => 'Kamera';

  @override
  String get viewerScreenLens => 'Objektiv';

  @override
  String get viewerScreenSettings => 'Postavke';

  @override
  String get viewerScreenLocation => 'Lokacija';

  @override
  String viewerScreenNotSaved(String reason) {
    return 'Nije spremljeno. $reason';
  }

  @override
  String get viewerScreenEditDetails => 'Uredi podatke';

  @override
  String get libraryScreenTitle => 'Biblioteka';

  @override
  String get libraryScreenExplore => 'Istraži';

  @override
  String get libraryScreenShared => 'Dijeljeno';

  @override
  String albumScreenActionFailed(String message) {
    return 'Radnja nije uspjela. $message';
  }

  @override
  String albumScreenRemovedAll(String count) {
    return 'Uklonjeno iz albuma: $count';
  }

  @override
  String albumScreenRemovedSome(String changed, String total) {
    return 'Uklonjeno: $changed od $total. Možete ukloniti samo fotke koje ste sami dodali.';
  }

  @override
  String get albumScreenCoverSet => 'Naslovnica je postavljena.';

  @override
  String get albumScreenCancel => 'Odustani';

  @override
  String get albumScreenMoveTitle => 'Premjesti album';

  @override
  String get albumScreenMoveTop => 'Na vrh, među sve albume';

  @override
  String get albumScreenMoved => 'Album je premješten.';

  @override
  String get albumScreenUploadToAlbum => 'Pošalji u album';

  @override
  String get albumScreenDeleteTitle => 'Obrisati ovaj album?';

  @override
  String get albumScreenDeleteBody =>
      'Fotke ostaju u biblioteci. Javni linkovi prestaju raditi.';

  @override
  String get albumScreenDeleteBodyInside =>
      'Fotke ostaju u biblioteci. Javni linkovi prestaju raditi. Albumi unutra premještaju se na vrh.';

  @override
  String get albumScreenDelete => 'Obriši';

  @override
  String get albumScreenLeaveTitle => 'Napustiti ovaj album?';

  @override
  String get albumScreenLeaveBody =>
      'Više ga nećete vidjeti, osim ako ga vlasnik ponovno ne podijeli.';

  @override
  String get albumScreenLeave => 'Napusti';

  @override
  String get albumScreenClearSelection => 'Poništi odabir';

  @override
  String get albumScreenShare => 'Dijeli';

  @override
  String get albumScreenSetAsCover => 'Postavi kao naslovnicu';

  @override
  String get albumScreenRemoveFromAlbum => 'Ukloni iz albuma';

  @override
  String get albumScreenSearchInAlbum => 'Traži u albumu';

  @override
  String get albumScreenComments => 'Komentari';

  @override
  String get albumScreenMore => 'Više';

  @override
  String get albumScreenSlideshow => 'Slideshow';

  @override
  String get albumScreenAddFromLibrary => 'Dodaj iz biblioteke';

  @override
  String get albumScreenUploadFromPhone => 'Pošalji s ovog mobitela';

  @override
  String get albumScreenAlbumInside => 'Album unutra';

  @override
  String get albumScreenMoveTo => 'Premjesti u…';

  @override
  String get albumScreenShareWithUsers => 'Dijeli s korisnicima';

  @override
  String get albumScreenPublicLinks => 'Javni linkovi';

  @override
  String get albumScreenEdit => 'Uredi';

  @override
  String get albumScreenNotAvailable => 'Ovaj album nije dostupan.';

  @override
  String get albumScreenNoMatch => 'Nijedna fotka ne odgovara pravilima.';

  @override
  String get albumScreenEmptyCanAdd =>
      'Album je prazan. Dodajte fotke iz izbornika.';

  @override
  String get albumScreenEmpty => 'Album je prazan.';

  @override
  String get albumScreenAlbumsInside => 'Albumi unutra';

  @override
  String get albumScreenNewAlbumInside => 'Novi album unutra';

  @override
  String get albumScreenName => 'Naziv';

  @override
  String get albumScreenCreate => 'Stvori';

  @override
  String albumScreenAdded(String count) {
    return 'Dodano: $count';
  }

  @override
  String get albumScreenChoosePhotos => 'Odaberite fotke';

  @override
  String get albumScreenAdd => 'Dodaj';

  @override
  String get albumScreenNoPhotosYet => 'Još nema fotki.';

  @override
  String get albumScreenNotSaved => 'Album nije spremljen.';

  @override
  String get albumScreenEditAlbum => 'Uredi album';

  @override
  String get albumScreenDescription => 'Opis';

  @override
  String get albumScreenOrder => 'Redoslijed';

  @override
  String get albumScreenNewestFirst => 'Najnovije prvo';

  @override
  String get albumScreenOldestFirst => 'Najstarije prvo';

  @override
  String get albumScreenSave => 'Spremi';

  @override
  String get peopleScreensNoName => 'Bez imena';

  @override
  String get peopleScreensSearchFailed =>
      'Pretraga nije uspjela. Provjerite vezu.';

  @override
  String get peopleScreensDescribe =>
      'Opišite što tražite, na hrvatskom ili engleskom, ili odaberite filtre.';

  @override
  String get peopleScreensSmartOff =>
      'Pametna pretraga nije uključena ili nije dostupna, pa se traži samo tekst na slikama, nazivi datoteka i filtri.';

  @override
  String peopleScreensRemoveChip(String label) {
    return 'Ukloni $label';
  }

  @override
  String get peopleScreensNothingFound => 'Ništa nije pronađeno.';

  @override
  String get peopleScreensSearchHint => 'pas na plaži, Hvar 2024, račun…';

  @override
  String get peopleScreensAsk => 'Pitaj';

  @override
  String get peopleScreensFilters => 'Filtri';

  @override
  String get peopleScreensSearch => 'Traži';

  @override
  String get peopleScreensLoadFailed =>
      'Osobe se nisu učitale. Provjerite vezu.';

  @override
  String get peopleScreensFacesOff =>
      'Prepoznavanje lica nije uključeno na ovom serveru.';

  @override
  String get peopleScreensNoneYet => 'Još nema prepoznatih osoba.';

  @override
  String get peopleScreensPeople => 'Osobe';

  @override
  String get peopleScreensShowOthers => 'Prikaži ostale';

  @override
  String get peopleScreensHiddenPeople => 'Skrivene osobe';

  @override
  String get peopleScreensName => 'Ime';

  @override
  String get peopleScreensDateOfBirth => 'Datum rođenja';

  @override
  String get peopleScreensMergeWith => 'Spoji s…';

  @override
  String get peopleScreensNobodyElse => 'Nema drugih osoba.';

  @override
  String get peopleScreensMerged => 'Spojeno.';

  @override
  String peopleScreensBorn(String date) {
    return 'Rođen/a $date';
  }

  @override
  String get peopleScreensShow => 'Prikaži';

  @override
  String get peopleScreensHide => 'Sakrij';

  @override
  String get peopleScreensThisLoadFailed =>
      'Podaci se ne mogu učitati. Provjerite vezu.';

  @override
  String get adminServerSettingsTrashDaysProblem =>
      'Smeće čuva fotke od 1 do 3650 dana.';

  @override
  String get adminServerSettingsImageQualityProblem =>
      'Kvaliteta slike mora biti između 40 i 100.';

  @override
  String get adminServerSettingsPreviewSizeProblem =>
      'Veličina pregleda mora biti između 720 i 4096.';

  @override
  String get adminServerSettingsVideoQualityProblem =>
      'Kvaliteta videa mora biti između 18 i 40, a manje je bolje.';

  @override
  String get adminServerSettingsVideoHeightProblem =>
      'Najveći video mora biti 720, 1080, 1440 ili 2160.';

  @override
  String get adminServerSettingsFaceScoreProblem =>
      'Koliko lice mora biti sigurno je između 0,1 i 1.';

  @override
  String get adminServerSettingsFaceDistanceProblem =>
      'Koliko dva lica moraju biti slična je između 0,1 i 2.';

  @override
  String get adminServerSettingsJobsProblem =>
      'Pozadinskih poslova mora biti između 0 i 64.';

  @override
  String get adminServerSettingsWorkersProblem =>
      'Poslova videa i analize mora biti između 1 i 16.';

  @override
  String get adminServerSettingsScanProblem =>
      'Razmak pregleda mora biti između 1 i 720 sati.';

  @override
  String get adminServerSettingsMessageProblem =>
      'Poruka za prijavu je preduga.';

  @override
  String get adminServerSettingsNeedNumbers =>
      'Svako brojčano polje treba broj.';

  @override
  String get adminServerSettingsSaved => 'Postavke su spremljene.';

  @override
  String get adminServerSettingsTitle => 'Postavke servera';

  @override
  String get adminServerSettingsTrash => 'Smeće';

  @override
  String get adminServerSettingsTrashDays => 'Koliko dana fotke ostaju u smeću';

  @override
  String adminServerSettingsRange(String low, String high) {
    return '$low do $high';
  }

  @override
  String get adminServerSettingsPicturesAndVideos => 'Slike i videi';

  @override
  String get adminServerSettingsImageQuality => 'Kvaliteta slike';

  @override
  String get adminServerSettingsPreviewSize => 'Veličina pregleda u pikselima';

  @override
  String get adminServerSettingsVideoQuality => 'Kvaliteta videa';

  @override
  String get adminServerSettingsVideoQualityHelp =>
      '18 do 40, manje je bolje i veće';

  @override
  String get adminServerSettingsLargestVideo => 'Najveći video';

  @override
  String get adminServerSettingsFaces => 'Lica';

  @override
  String get adminServerSettingsFaceScore => 'Koliko lice mora biti sigurno';

  @override
  String get adminServerSettingsFaceDistance =>
      'Koliko slična dva lica moraju biti da budu ista osoba';

  @override
  String get adminServerSettingsBackgroundJobs => 'Pozadinski poslovi';

  @override
  String get adminServerSettingsJobsAtOnce => 'Poslova odjednom';

  @override
  String get adminServerSettingsJobsAtOnceHelp =>
      '0 koristi WORKER_CONCURRENCY; vrijedi nakon ponovnog pokretanja workera';

  @override
  String get adminServerSettingsVideosAtOnce => 'Videa odjednom';

  @override
  String get adminServerSettingsWorkersHelp =>
      '1 do 16; vrijedi nakon ponovnog pokretanja workera';

  @override
  String get adminServerSettingsAnalysesAtOnce => 'Analiza odjednom';

  @override
  String get adminServerSettingsScanHours =>
      'Pregledaj vanjske mape svakih … sati';

  @override
  String get adminServerSettingsSigningIn => 'Prijava';

  @override
  String get adminServerSettingsPasswordLogin => 'Dopusti prijavu lozinkom';

  @override
  String get adminServerSettingsMaintenance => 'Način održavanja';

  @override
  String get adminServerSettingsMaintenanceHelp =>
      'Poslužitelj mogu koristiti samo administratori';

  @override
  String get adminServerSettingsVisibleOnNetwork =>
      'Aplikacije u istoj mreži mogu pronaći ovaj poslužitelj';

  @override
  String get adminServerSettingsVisibleOnNetworkHelp =>
      'Za prijavu je i dalje potreban račun.';

  @override
  String get adminServerSettingsServerName => 'Ime poslužitelja';

  @override
  String get adminServerSettingsLoginMessage => 'Poruka na stranici za prijavu';

  @override
  String get adminOverviewTitle => 'Pregled';

  @override
  String get adminOverviewLibrary => 'Biblioteka';

  @override
  String get adminOverviewUsers => 'Korisnici';

  @override
  String get adminOverviewPhotos => 'Fotke';

  @override
  String get adminOverviewVideos => 'Videi';

  @override
  String get adminOverviewProcessing => 'U obradi';

  @override
  String get adminOverviewFailed => 'Neuspjelo';

  @override
  String get adminOverviewLibrarySize => 'Veličina biblioteke';

  @override
  String get adminOverviewDisk => 'Disk';

  @override
  String get adminOverviewFree => 'Slobodno';

  @override
  String get adminOverviewTotal => 'Ukupno';

  @override
  String get adminOverviewJobs => 'Poslovi';

  @override
  String get adminOverviewWaiting => 'Na čekanju';

  @override
  String get adminOverviewRunning => 'Radi';

  @override
  String get adminOverviewDone => 'Gotovo';

  @override
  String get adminOverviewServices => 'Servisi';

  @override
  String get adminOverviewWorker => 'Worker';

  @override
  String get adminOverviewNotRunning => 'Ne radi';

  @override
  String get adminOverviewAnalysis => 'Analiza (ML)';

  @override
  String get adminOverviewTurnedOff => 'Isključeno';

  @override
  String get adminOverviewDatabaseSize => 'Veličina baze';

  @override
  String get adminOverviewVersions => 'Verzije';

  @override
  String get adminOverviewDatabase => 'Baza';

  @override
  String get adminJobsTitle => 'Poslovi';

  @override
  String get adminJobsQueues => 'Redovi';

  @override
  String adminJobsQueueState(String queued, String running) {
    return '$queued čeka · $running u obradi';
  }

  @override
  String adminJobsQueueStatePaused(String queued, String running) {
    return '$queued čeka · $running u obradi · zaustavljeno';
  }

  @override
  String adminJobsContinues(String name) {
    return '$name se nastavlja.';
  }

  @override
  String adminJobsIsPaused(String name) {
    return '$name je pauziran.';
  }

  @override
  String get adminJobsResume => 'Nastavi';

  @override
  String get adminJobsPause => 'Pauziraj';

  @override
  String get adminJobsFailed => 'Neuspjelo';

  @override
  String get adminJobsNoneFailed => 'Nijedan posao nije pao.';

  @override
  String get adminJobsQueuedAgain => 'Posao je ponovno u redu.';

  @override
  String get adminJobsTryAgain => 'Pokušaj opet';

  @override
  String get freeSpaceScreenServerUnreachable =>
      'Server nije dostupan, pa se ništa ne nudi za uklanjanje.';

  @override
  String get freeSpaceScreenBackupUnreadable =>
      'Stanje backupa nije se moglo pročitati.';

  @override
  String freeSpaceScreenRemoveTitle(String count) {
    return 'Ukloniti $count s ovog mobitela?';
  }

  @override
  String get freeSpaceScreenRemoveBody =>
      'Ostaju na vašem serveru. iPhone pita još jednom i čuva ih 30 dana u mapi Nedavno izbrisano.';

  @override
  String get freeSpaceScreenCancel => 'Odustani';

  @override
  String get freeSpaceScreenRemove => 'Ukloni';

  @override
  String get freeSpaceScreenNotRemoved => 'Fotke se nisu mogle ukloniti.';

  @override
  String get freeSpaceScreenNothingToRemove =>
      'Nema ničega za uklanjanje. Ovdje se nude samo fotke poslane automatskim backupom.';

  @override
  String freeSpaceScreenSafe(String count) {
    return '$count je sigurno na vašem serveru, kako je upravo potvrdio njihovim kontrolnim zbrojevima.';
  }

  @override
  String freeSpaceScreenRemoveButton(String count) {
    return 'Ukloni $count s ovog mobitela';
  }

  @override
  String get freeSpaceScreenTitle => 'Oslobodi prostor';

  @override
  String get freeSpaceScreenWhatToKeep => 'Što zadržati';

  @override
  String get freeSpaceScreenAnyAge => 'Bilo koje starosti';

  @override
  String get freeSpaceScreenOlderThanMonth => 'Starije od mjesec dana';

  @override
  String get freeSpaceScreenOlderThan3Months => 'Starije od 3 mjeseca';

  @override
  String get freeSpaceScreenOlderThanYear => 'Starije od godinu dana';

  @override
  String get freeSpaceScreenRemoveOnly => 'Ukloni samo';

  @override
  String get freeSpaceScreenKeepFavorites => 'Zadrži favorite';

  @override
  String get freeSpaceScreenKeepPhotos => 'Zadrži sve fotke';

  @override
  String get freeSpaceScreenKeepVideos => 'Zadrži sve videe';

  @override
  String get freeSpaceScreenKeepAlbums => 'Zadrži ove albume na mobitelu';

  @override
  String get apiKeysScreenRead => 'Čitanje';

  @override
  String get apiKeysScreenUpload => 'Slanje datoteka';

  @override
  String get apiKeysScreenChangeAndDelete => 'Izmjene i brisanje';

  @override
  String apiKeysScreenExpires(String rights, String date) {
    return '$rights · istječe $date';
  }

  @override
  String get apiKeysScreenNewKey => 'Novi ključ';

  @override
  String get apiKeysScreenKeyName => 'Naziv ključa';

  @override
  String get apiKeysScreenCancel => 'Odustani';

  @override
  String get apiKeysScreenCreate => 'Stvori';

  @override
  String apiKeysScreenCreateFailed(String message) {
    return 'Ključ nije stvoren. $message';
  }

  @override
  String get apiKeysScreenSaveItNow => 'Spremite ga sada';

  @override
  String get apiKeysScreenCopy => 'Kopiraj';

  @override
  String get apiKeysScreenDone => 'Gotovo';

  @override
  String get apiKeysScreenRevokeFailed => 'Ključ nije opozvan.';

  @override
  String get apiKeysScreenTitle => 'API ključevi';

  @override
  String get apiKeysScreenLoadFailed => 'Ključevi se nisu učitali.';

  @override
  String get apiKeysScreenEmpty =>
      'Još nema ključeva. Ključ daje programu samo odabrana prava.';

  @override
  String get apiKeysScreenRevoke => 'Opozovi';

  @override
  String get memoriesScreenLastWeek => 'Protekli tjedan';

  @override
  String memoriesScreenOnThisDay(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: 'Na današnji dan, prije $years godina',
      few: 'Na današnji dan, prije $years godine',
      one: 'Na današnji dan, prije $years godinu',
    );
    return '$_temp0';
  }

  @override
  String get memoriesScreenLoadFailed =>
      'Uspomene se nisu učitale. Provjerite vezu.';

  @override
  String get memoriesScreenTryAgain => 'Pokušaj ponovno';

  @override
  String get memoriesScreenNoneYet => 'Još nema uspomena.';

  @override
  String memoriesScreenItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stavki',
      few: '$count stavke',
      one: '$count stavka',
    );
    return '$_temp0';
  }

  @override
  String get memoriesScreenTitle => 'Uspomene';

  @override
  String get memoriesScreenVideoFailed => 'Video nije napravljen.';

  @override
  String get memoriesScreenVideoSaved =>
      'Video je spremljen u vaše Fotografije.';

  @override
  String get memoriesScreenVideoNotSaved => 'Video nije spremljen.';

  @override
  String get memoriesScreenMakeVideo => 'Napravi video';

  @override
  String get layoutJanuary => 'Siječanj';

  @override
  String get layoutJanuaryOf => 'siječnja';

  @override
  String get layoutFebruary => 'Veljača';

  @override
  String get layoutFebruaryOf => 'veljače';

  @override
  String get layoutMarch => 'Ožujak';

  @override
  String get layoutMarchOf => 'ožujka';

  @override
  String get layoutApril => 'Travanj';

  @override
  String get layoutAprilOf => 'travnja';

  @override
  String get layoutMay => 'Svibanj';

  @override
  String get layoutMayOf => 'svibnja';

  @override
  String get layoutJune => 'Lipanj';

  @override
  String get layoutJuneOf => 'lipnja';

  @override
  String get layoutJuly => 'Srpanj';

  @override
  String get layoutJulyOf => 'srpnja';

  @override
  String get layoutAugust => 'Kolovoz';

  @override
  String get layoutAugustOf => 'kolovoza';

  @override
  String get layoutSeptember => 'Rujan';

  @override
  String get layoutSeptemberOf => 'rujna';

  @override
  String get layoutOctober => 'Listopad';

  @override
  String get layoutOctoberOf => 'listopada';

  @override
  String get layoutNovember => 'Studeni';

  @override
  String get layoutNovemberOf => 'studenoga';

  @override
  String get layoutDecember => 'Prosinac';

  @override
  String get layoutDecemberOf => 'prosinca';

  @override
  String get layoutWeekdayMon => 'pon';

  @override
  String get layoutWeekdayTue => 'uto';

  @override
  String get layoutWeekdayWed => 'sri';

  @override
  String get layoutWeekdayThu => 'čet';

  @override
  String get layoutWeekdayFri => 'pet';

  @override
  String get layoutWeekdaySat => 'sub';

  @override
  String get layoutWeekdaySun => 'ned';

  @override
  String layoutMonthYear(String month, String year) {
    return '$month $year.';
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
    return '$day. $month $year., $hour:$minute';
  }

  @override
  String get linkPrivacyHideFaces => 'Sakrij lica';

  @override
  String get linkPrivacyFacesNone => 'Nijedno';

  @override
  String get linkPrivacyFacesAll => 'Sva lica';

  @override
  String get linkPrivacyFacesExcept => 'Sva osim odabranih osoba';

  @override
  String get linkPrivacyChoosePeople => 'Lica ovih osoba ostaju vidljiva:';

  @override
  String get linkPrivacyNoPeople =>
      'Još nitko nema ime. Najprije imenujte osobe pod Osobe.';

  @override
  String get linkPrivacyPeopleFailed => 'Osobe se nisu učitale.';

  @override
  String get linkPrivacyUnrecognized =>
      'Lice koje nije prepoznato neće biti zamućeno.';

  @override
  String linkPrivacyUnchecked(String count, String total) {
    return 'Lica još nisu provjerena na $count od $total fotki, pa na njima ništa nije zamućeno.';
  }

  @override
  String get linkPrivacyAllChecked =>
      'Sve fotke u albumu provjerene su na lica.';

  @override
  String linkPrivacyVideosStill(String count) {
    return 'Videi ($count) prikazuju se samo kao sličica, sa zamućenim licima.';
  }

  @override
  String get linkPrivacyNoOriginals =>
      'Posjetitelji dobivaju zamućenu kopiju pune veličine, nikad original.';

  @override
  String get linkPrivacyRemoveCamera => 'Ukloni podatke o fotoaparatu';

  @override
  String get linkPrivacyRemoveCameraDetail =>
      'Preuzete datoteke ne nose fotoaparat, objektiv, serijske brojeve, autora ni softver.';

  @override
  String get linkPrivacyRemoveDate => 'Ukloni i datum';

  @override
  String get linkPrivacyAskName => 'Traži ime';

  @override
  String get linkPrivacyAskNameDetail =>
      'Posjetitelji upišu ime prije nego što vide album.';

  @override
  String get linkPrivacyNotOpened => 'Još nije otvoren';

  @override
  String linkPrivacyOpened(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Otvoren $count puta',
      one: 'Otvoren jednom',
    );
    return '$_temp0 · zadnji put $when';
  }

  @override
  String get linkPrivacyWhoOpened => 'Tko ga je otvorio';

  @override
  String get linkPrivacyNoVisits => 'Ovaj link još nitko nije otvorio.';

  @override
  String get linkPrivacyVisitsFailed => 'Posjeti se nisu učitali.';

  @override
  String get linkPrivacyUnknownPlace => 'Nepoznato mjesto';

  @override
  String get linkPrivacyNoName => 'Bez imena';

  @override
  String linkPrivacyViewed(String count) {
    return 'pogledano: $count';
  }

  @override
  String linkPrivacyDownloaded(String count) {
    return 'preuzeto: $count';
  }

  @override
  String get linkPrivacyAttribution =>
      'Mjesta prema DB-IP (db-ip.com), CC BY 4.0. Posjeti se čuvaju 90 dana.';

  @override
  String get sharePrivacyRemoveLocation => 'Ukloni lokaciju';

  @override
  String get sharePrivacyRemoveCamera => 'Ukloni podatke o fotoaparatu';

  @override
  String get sharePrivacyHideFaces => 'Sakrij lica';

  @override
  String get sharePrivacyHideFacesDetail =>
      'Fotke idu kao zamućena kopija. Videi se izostavljaju.';

  @override
  String get sharePrivacyVideosLeftOut =>
      'Videi su izostavljeni: lica u njima ne mogu se sakriti.';

  @override
  String notificationsLinkOpened(String subject) {
    return 'Vaš link „$subject” otvoren je prvi put.';
  }
}

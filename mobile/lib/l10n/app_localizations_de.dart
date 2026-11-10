// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get languageTitle => 'Sprache';

  @override
  String get languageMachine =>
      'Maschinell übersetzt: noch von keinem Menschen gelesen.';

  @override
  String get languageFollowsAccount =>
      'Deine Wahl wird in deinem Konto gespeichert, andere Geräte übernehmen sie.';

  @override
  String get appHeaderNew => 'Neu';

  @override
  String get appHeaderAdd => 'Hinzufügen';

  @override
  String get appHeaderAccount => 'Konto';

  @override
  String get appHeaderBackupAndUpload => 'Sicherung und Hochladen';

  @override
  String get uploadsCouldNotRead =>
      'Dieses Foto konnte nicht vom Gerät gelesen werden.';

  @override
  String get waitingStripTitle => 'Auf diesem Handy, wartet auf Sicherung';

  @override
  String get shareSheetVaultTitle => 'Aus dem Tresor nehmen?';

  @override
  String get shareSheetVaultBody =>
      'Einmal gesendet oder gespeichert, ist es nicht mehr durch deine PIN geschützt.';

  @override
  String get shareSheetCancel => 'Abbrechen';

  @override
  String get shareSheetContinue => 'Weiter';

  @override
  String get shareSheetSendThis => 'Das senden';

  @override
  String shareSheetSendCount(String count) {
    return '$count senden';
  }

  @override
  String get shareSheetSmaller => 'Kleiner, für Nachrichten';

  @override
  String get shareSheetOriginal => 'Original';

  @override
  String get shareSheetSmallerDetail =>
      'Ein JPEG mit höchstens 2048 px, ohne Ort';

  @override
  String get shareSheetOriginalDetail => 'So wie es ist, mit allem darin';

  @override
  String get shareSheetSaveToPhone => 'Auf diesem Handy speichern';

  @override
  String get shareSheetSaveDetail => 'Das Original, in der Galerie des Handys';

  @override
  String get shareSheetSavedOne => 'Auf diesem Handy gespeichert.';

  @override
  String shareSheetSavedMany(String count) {
    return '$count auf diesem Handy gespeichert.';
  }

  @override
  String get shareSheetGettingReady => 'Wird vorbereitet';

  @override
  String shareSheetProgress(String done, String total) {
    return '$done von $total';
  }

  @override
  String get shareSheetFetchFailed =>
      'Die Dateien konnten nicht abgerufen werden.';

  @override
  String facesSectionActionFailed(String detail) {
    return 'Die Aktion ist fehlgeschlagen. $detail';
  }

  @override
  String get facesSectionNewPerson => 'Neue Person';

  @override
  String get facesSectionCancel => 'Abbrechen';

  @override
  String get facesSectionSave => 'Speichern';

  @override
  String get facesSectionPeople => 'Personen';

  @override
  String get facesSectionNoName => 'Kein Name';

  @override
  String get facesSectionWhoThisIs => 'Wer das ist';

  @override
  String get facesSectionNewPersonMenu => 'Neue Person…';

  @override
  String get facesSectionNotAPerson => 'Keine Person';

  @override
  String get importsScreenWaitingForFiles => 'Wartet auf Dateien';

  @override
  String get importsScreenRunning => 'Läuft';

  @override
  String get importsScreenDone => 'Fertig';

  @override
  String get importsScreenFailed => 'Fehlgeschlagen';

  @override
  String get importsScreenStopped => 'Gestoppt';

  @override
  String importsScreenZipUploaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ZIP-Dateien hochgeladen',
      one: '1 ZIP-Datei hochgeladen',
    );
    return '$_temp0';
  }

  @override
  String importsScreenCounts(String added, String skipped, String failed) {
    return 'hinzugefügt $added · schon da oder gelöscht $skipped · fehlgeschlagen $failed';
  }

  @override
  String get importsScreenReportNotLoaded =>
      'Der Bericht konnte nicht geladen werden.';

  @override
  String get importsScreenNoFilesFailed => 'Keine Dateien fehlgeschlagen.';

  @override
  String get importsScreenCouldNotStop =>
      'Der Import konnte nicht gestoppt werden.';

  @override
  String get importsScreenStop => 'Stoppen';

  @override
  String get importsScreenCouldNotContinue =>
      'Der Import konnte nicht fortgesetzt werden.';

  @override
  String get importsScreenBringIn => 'Importieren';

  @override
  String get importsScreenContinue => 'Weiter';

  @override
  String get importsScreenReport => 'Bericht';

  @override
  String get importsScreenTitle => 'Import';

  @override
  String get importsScreenNotLoaded =>
      'Die Importe konnten nicht geladen werden.';

  @override
  String importsScreenHowTo(String address) {
    return 'Um Fotos aus Google Photos oder iCloud zu importieren, lade die ZIP-Dateien des Exports am Computer hoch, unter $address.';
  }

  @override
  String get importsScreenNothingYet => 'Du hast noch nichts importiert.';

  @override
  String get storageTemplateScreenDryRun => 'Probelauf';

  @override
  String storageTemplateScreenDryRunProgress(String checked) {
    return 'Probelauf… $checked';
  }

  @override
  String storageTemplateScreenMovingProgress(String checked) {
    return 'Wird verschoben… $checked';
  }

  @override
  String storageTemplateScreenWouldMove(String moved, String checked) {
    return 'Probelauf: $moved von $checked würden verschoben.';
  }

  @override
  String storageTemplateScreenMoved(String moved, String checked) {
    return '$moved von $checked verschoben.';
  }

  @override
  String storageTemplateScreenFailedCount(String line, String failed) {
    return '$line Fehlgeschlagen: $failed.';
  }

  @override
  String get storageTemplateScreenNotLoaded => 'Nicht geladen.';

  @override
  String get storageTemplateScreenSaved => 'Gespeichert.';

  @override
  String get storageTemplateScreenNotSaved => 'Nicht gespeichert.';

  @override
  String storageTemplateScreenMoveFilesQuestion(String count) {
    return '$count Dateien verschieben?';
  }

  @override
  String get storageTemplateScreenOriginalsUnchanged =>
      'Die Originale ändern sich nicht, nur ihr Ort auf der Festplatte.';

  @override
  String get storageTemplateScreenCancel => 'Abbrechen';

  @override
  String get storageTemplateScreenMove => 'Verschieben';

  @override
  String get storageTemplateScreenNotStarted => 'Nicht gestartet.';

  @override
  String get storageTemplateScreenTitle => 'Speichervorlage';

  @override
  String get storageTemplateScreenIntro =>
      'Wie die Originale auf der Festplatte im Ordner jedes Benutzers abgelegt werden. Gilt für neue Dateien; vorhandene werden erst auf Wunsch nach einem Probelauf verschoben. Eine externe Bibliothek wird nie verschoben.';

  @override
  String get storageTemplateScreenTemplate => 'Vorlage';

  @override
  String get storageTemplateScreenExamples => 'Beispiele';

  @override
  String get storageTemplateScreenBackToUsual =>
      'Zurück zur üblichen Anordnung';

  @override
  String get storageTemplateScreenSave => 'Speichern';

  @override
  String get storageTemplateScreenFilesAlreadyHere =>
      'Bereits vorhandene Dateien';

  @override
  String get storageTemplateScreenMoveTheFiles => 'Dateien verschieben';

  @override
  String get mapScreenNoPlaceName => 'Kein Ortsname';

  @override
  String get mapScreenNotLoaded =>
      'Die Karte konnte nicht geladen werden. Prüfe die Verbindung.';

  @override
  String get mapScreenTryAgain => 'Erneut versuchen';

  @override
  String get mapScreenNoPhotos => 'Noch keine Fotos mit Ort.';

  @override
  String get mapScreenFromDate => 'Ab Datum';

  @override
  String get mapScreenToDate => 'Bis Datum';

  @override
  String get mapScreenClear => 'Zurücksetzen';

  @override
  String mapScreenItems(String count) {
    return 'Elemente: $count';
  }

  @override
  String get mapScreenTrips => 'Reisen';

  @override
  String get mapScreenTitle => 'Karte';

  @override
  String get cleanupScreenBlurry => 'Unscharfe Fotos';

  @override
  String get cleanupScreenScreenshots => 'Bildschirmfotos';

  @override
  String get cleanupScreenLargeVideos => 'Große Videos';

  @override
  String get cleanupScreenBursts => 'Serienaufnahmen';

  @override
  String get cleanupScreenBlurryHint =>
      'Fotos mit sehr wenigen scharfen Kanten. Der Regler legt fest, wie streng.';

  @override
  String get cleanupScreenScreenshotsHint =>
      'Erkannt am Namen, an der iPhone-Markierung oder an der Form eines Bildschirms.';

  @override
  String get cleanupScreenLargeVideosHint => 'Die größten zuerst.';

  @override
  String get cleanupScreenBurstsHint =>
      'Die anderen Aufnahmen einer Serie. Die beste bleibt.';

  @override
  String get cleanupScreenMoveToTrashQuestion =>
      'In den Papierkorb verschieben?';

  @override
  String cleanupScreenTrashBody(String count, String size) {
    return '$count Elemente ($size) bleiben eine Weile im Papierkorb und können wiederhergestellt werden.';
  }

  @override
  String get cleanupScreenCancel => 'Abbrechen';

  @override
  String get cleanupScreenMove => 'Verschieben';

  @override
  String get cleanupScreenMovedToTrash => 'In den Papierkorb verschoben.';

  @override
  String get cleanupScreenActionFailed => 'Die Aktion ist fehlgeschlagen.';

  @override
  String get cleanupScreenKept =>
      'Behalten. Sie werden nicht mehr vorgeschlagen.';

  @override
  String get cleanupScreenStricter => 'Strenger';

  @override
  String get cleanupScreenMore => 'Mehr';

  @override
  String get cleanupScreenLargerThan => 'Größer als ';

  @override
  String get cleanupScreenToTheTrash => 'In den Papierkorb';

  @override
  String get cleanupScreenStays => 'Bleibt';

  @override
  String get cleanupScreenFavorite => 'Favorit';

  @override
  String get cleanupScreenInAnAlbum => 'In einem Album';

  @override
  String get cleanupScreenTitle => 'Aufräumen';

  @override
  String get cleanupScreenKeep => 'Behalten';

  @override
  String cleanupScreenToTheTrashButton(String count, String size) {
    return 'In den Papierkorb ($count · $size)';
  }

  @override
  String get cleanupScreenNotLoaded => 'Aufräumen konnte nicht geladen werden.';

  @override
  String cleanupScreenStillAnalysed(String count) {
    return 'Wird noch analysiert: $count Fotos.';
  }

  @override
  String get cleanupScreenNothing => 'Hier gibt es nichts aufzuräumen.';

  @override
  String get cleanupScreenTapToTick =>
      'Tippen zum An- oder Abhaken. Halten zum Ansehen.';

  @override
  String get cleanupScreenShowMore => 'Mehr anzeigen';

  @override
  String get organizeScreensRecentlyAdded => 'Zuletzt hinzugefügt';

  @override
  String get organizeScreensFavorites => 'Favoriten';

  @override
  String get organizeScreensMemories => 'Erinnerungen';

  @override
  String get organizeScreensPeople => 'Personen';

  @override
  String get organizeScreensMap => 'Karte';

  @override
  String get organizeScreensFolders => 'Ordner';

  @override
  String get organizeScreensFamily => 'Familie';

  @override
  String get organizeScreensDocuments => 'Dokumente';

  @override
  String get organizeScreensDuplicates => 'Duplikate';

  @override
  String get organizeScreensCleanUp => 'Aufräumen';

  @override
  String get organizeScreensArchive => 'Archiv';

  @override
  String get organizeScreensTrash => 'Papierkorb';

  @override
  String get organizeScreensVault => 'Tresor';

  @override
  String get organizeScreensApiKeys => 'API-Schlüssel';

  @override
  String get organizeScreensTags => 'Schlagwörter';

  @override
  String get organizeScreensCouldNotLoad =>
      'Konnte nicht geladen werden. Prüfe die Verbindung.';

  @override
  String get organizeScreensClearSelection => 'Auswahl aufheben';

  @override
  String get organizeScreensShare => 'Teilen';

  @override
  String get organizeScreensOriginalsRemoved =>
      'Die Originale werden von der Festplatte gelöscht. Das kann nicht rückgängig gemacht werden.';

  @override
  String get organizeScreensCancel => 'Abbrechen';

  @override
  String get organizeScreensDeletePermanently => 'Endgültig löschen';

  @override
  String organizeScreensActionFailedDetail(String detail) {
    return 'Die Aktion ist fehlgeschlagen. $detail';
  }

  @override
  String get organizeScreensNothingAdded => 'Noch nichts hinzugefügt.';

  @override
  String get organizeScreensAddToFavorites => 'Zu Favoriten hinzufügen';

  @override
  String get organizeScreensAddedToFavorites => 'Zu Favoriten hinzugefügt';

  @override
  String get organizeScreensArchiveAction => 'Archivieren';

  @override
  String get organizeScreensArchived => 'Archiviert';

  @override
  String get organizeScreensNoFavorites =>
      'Noch keine Favoriten. Markiere ein Foto mit dem Stern.';

  @override
  String get organizeScreensRemoveFromFavorites => 'Aus Favoriten entfernen';

  @override
  String get organizeScreensRemovedFromFavorites => 'Aus Favoriten entfernt';

  @override
  String get organizeScreensArchiveEmpty => 'Das Archiv ist leer.';

  @override
  String get organizeScreensBackToMedia => 'Zurück zu Medien';

  @override
  String get organizeScreensBackInMedia => 'Zurück in Medien';

  @override
  String organizeScreensTrashRemoves(String count, String size) {
    return 'Dies entfernt $count Dateien, $size.';
  }

  @override
  String get organizeScreensEmptyTrashQuestion => 'Papierkorb leeren?';

  @override
  String organizeScreensPermanentlyDeletedCount(String count) {
    return 'Endgültig gelöscht: $count';
  }

  @override
  String get organizeScreensEmpty => 'Leeren';

  @override
  String get organizeScreensTrashAfterAWhile =>
      'Elemente hier werden nach einer Weile endgültig gelöscht.';

  @override
  String organizeScreensTrashAfterDays(String days) {
    return 'Elemente werden nach $days Tagen endgültig gelöscht.';
  }

  @override
  String get organizeScreensTrashEmpty => 'Der Papierkorb ist leer.';

  @override
  String get organizeScreensRestore => 'Wiederherstellen';

  @override
  String get organizeScreensRestored => 'Wiederhergestellt';

  @override
  String get organizeScreensDeletePermanentlyQuestion => 'Endgültig löschen?';

  @override
  String get organizeScreensPermanentlyDeleted => 'Endgültig gelöscht';

  @override
  String get organizeScreensOpenYourVault => 'Öffne deinen Tresor';

  @override
  String get organizeScreensTooManyAttempts =>
      'Zu viele Versuche. Versuche es später erneut.';

  @override
  String get organizeScreensWrongPin => 'Falsche PIN.';

  @override
  String get organizeScreensPinLength => 'Die PIN muss 4 bis 12 Ziffern haben.';

  @override
  String get organizeScreensVaultLockedItself =>
      'Der Tresor hat sich gesperrt. Entsperre ihn erneut.';

  @override
  String get organizeScreensVaultEmpty => 'Der Tresor ist leer.';

  @override
  String get organizeScreensVaultNotLoaded =>
      'Der Tresor konnte nicht geladen werden. Prüfe die Verbindung.';

  @override
  String get organizeScreensTryAgain => 'Erneut versuchen';

  @override
  String get organizeScreensVaultIntro =>
      'Vor allen anderen Ansichten und dem Teilen verborgen. Die Dateien auf dem Server sind nicht verschlüsselt.';

  @override
  String get organizeScreensPin => 'PIN';

  @override
  String get organizeScreensNewPin => 'Neue PIN';

  @override
  String get organizeScreensPinHelper =>
      '4 bis 12 Ziffern. Nur der Server-Administrator kann eine verlorene PIN zurücksetzen.';

  @override
  String get organizeScreensUseFaceId => 'Nächstes Mal Face ID verwenden';

  @override
  String get organizeScreensUnlock => 'Entsperren';

  @override
  String get organizeScreensSetPin => 'PIN festlegen';

  @override
  String get organizeScreensAddATag => 'Schlagwort hinzufügen';

  @override
  String get organizeScreensNewTag => 'Neues Schlagwort';

  @override
  String get organizeScreensCreateAndAdd => 'Erstellen und hinzufügen';

  @override
  String get organizeScreensTagsNotLoaded =>
      'Schlagwörter konnten nicht geladen werden.';

  @override
  String get organizeScreensNoTags =>
      'Noch keine Schlagwörter. Wähle Fotos aus und füge ein Schlagwort hinzu.';

  @override
  String get organizeScreensDeleteTag => 'Schlagwort löschen';

  @override
  String get organizeScreensRenameTheTag => 'Schlagwort umbenennen';

  @override
  String get organizeScreensNewName => 'Neuer Name';

  @override
  String get organizeScreensSave => 'Speichern';

  @override
  String organizeScreensAlreadyExists(String name) {
    return '„$name“ gibt es schon';
  }

  @override
  String organizeScreensJoinThem(String name) {
    return 'Zusammenführen? Alle Fotos erhalten „$name“.';
  }

  @override
  String get organizeScreensJoin => 'Zusammenführen';

  @override
  String organizeScreensNotRenamed(String detail) {
    return 'Nicht umbenannt. $detail';
  }

  @override
  String organizeScreensNotJoined(String detail) {
    return 'Nicht zusammengeführt. $detail';
  }

  @override
  String get organizeScreensRename => 'Umbenennen';

  @override
  String get organizeScreensNoPhotosWithTag =>
      'Kein Foto hat dieses Schlagwort.';

  @override
  String get organizeScreensRemoveTheTag => 'Schlagwort entfernen';

  @override
  String get organizeScreensFamilyNotOn =>
      'Ein Administrator hat das nicht eingeschaltet.';

  @override
  String get organizeScreensFamilyNotMember =>
      'Du bist noch nicht in der Familienbibliothek.';

  @override
  String get organizeScreensWhatIShare => 'Was ich teile';

  @override
  String get organizeScreensFamilyNotLoaded =>
      'Die Familienbibliothek konnte nicht geladen werden.';

  @override
  String get organizeScreensFamilyNothingShared =>
      'Noch niemand hat etwas mit der Familie geteilt.';

  @override
  String get organizeScreensShareWithFamily => 'Mit der Familie teilen';

  @override
  String get organizeScreensRuleName => 'Name der Regel';

  @override
  String get organizeScreensFromDateExample => 'Ab Datum (2024-06-01)';

  @override
  String get organizeScreensPlace => 'Ort';

  @override
  String organizeScreensNotSaved(String detail) {
    return 'Es wurde nicht gespeichert. $detail';
  }

  @override
  String get organizeScreensNewRule => 'Neue Regel';

  @override
  String get organizeScreensShareNothing =>
      'Du teilst noch nichts mit der Familie.';

  @override
  String get organizeScreensStopSharing => 'Nicht mehr teilen';

  @override
  String get organizeScreensActionFailed => 'Die Aktion ist fehlgeschlagen.';

  @override
  String get settingsScreenTitle => 'Einstellungen';

  @override
  String get settingsScreenViewing => 'Ansicht';

  @override
  String get settingsScreenAssetViewer => 'Medienansicht';

  @override
  String get settingsScreenAssetViewerHint =>
      'Wie Fotos und Videos geöffnet werden';

  @override
  String get settingsScreenPhotoGrid => 'Fotoraster';

  @override
  String get settingsScreenPhotoGridHint => 'Wie die Zeitachse angeordnet ist';

  @override
  String get settingsScreenPreferences => 'Präferenzen';

  @override
  String get settingsScreenPreferencesHint => 'Design, Farbe und Feedback';

  @override
  String get settingsScreenLanguageHint => 'Sprache der App';

  @override
  String get settingsScreenThisPhone => 'Dieses Handy';

  @override
  String get settingsScreenBackup => 'Sicherung';

  @override
  String get settingsScreenBackupHint =>
      'Was dieses Handy an den Server sendet';

  @override
  String get settingsScreenFreeUpSpace => 'Speicher freigeben';

  @override
  String get settingsScreenFreeUpSpaceHint =>
      'Entfernen, was auf dem Server sicher ist';

  @override
  String get settingsScreenSyncStatus => 'Synchronisierungsstatus';

  @override
  String get settingsScreenSyncStatusHint =>
      'Was auf diesem Handy und auf dem Server ist';

  @override
  String get settingsScreenHomeWidget => 'Startbildschirm-Widget';

  @override
  String get settingsScreenHomeWidgetHint =>
      'Ein Album auf dem Startbildschirm';

  @override
  String get settingsScreenNotifications => 'Benachrichtigungen';

  @override
  String get settingsScreenNotificationsHint =>
      'Worüber dich die App informiert';

  @override
  String get settingsScreenServer => 'Server';

  @override
  String get settingsScreenDevices => 'Geräte';

  @override
  String get settingsScreenDevicesHint => 'Wo dieses Konto angemeldet ist';

  @override
  String get settingsScreenYourLibrary => 'Deine Bibliothek';

  @override
  String get settingsScreenYourLibraryHint => 'Wie viel dieses Konto enthält';

  @override
  String get settingsScreenNetworking => 'Netzwerk';

  @override
  String get settingsScreenNetworkingHint => 'Die Adressen deines Servers';

  @override
  String get settingsScreenAdvanced => 'Erweitert';

  @override
  String get settingsScreenAdvancedHint => 'Nur-Lesen-Modus und Bild-Cache';

  @override
  String get settingsScreenWhatsNew => 'Neuigkeiten';

  @override
  String get settingsScreenWhatsNewHint => 'Die Versionen von Mediarr';

  @override
  String get settingsScreenReadOnlyOff => 'Nur-Lesen-Modus ausschalten';

  @override
  String get settingsScreenReadOnly => 'Nur-Lesen-Modus';

  @override
  String get settingsScreenReadOnlyHint =>
      'Nur ansehen: kein Hochladen, Bearbeiten oder Löschen in dieser App';

  @override
  String get settingsScreenCopyAlbums => 'Alben auf den Server kopieren';

  @override
  String get settingsScreenCopyAlbumsHint =>
      'Gesicherte Alben bekommen ein gleichnamiges Album auf dem Server. Fotos werden nur hinzugefügt, nie entfernt';

  @override
  String get settingsScreenClearCache => 'Bild-Cache leeren';

  @override
  String get settingsScreenCacheEmpty => 'Der Bild-Cache ist leer.';

  @override
  String get settingsScreenPhotos => 'Fotos';

  @override
  String get settingsScreenLoadFull => 'Ganzes Foto laden';

  @override
  String get settingsScreenLoadFullHint =>
      'Öffnet Fotos in voller Auflösung. Das verbraucht mehr Daten und ist langsamer';

  @override
  String get settingsScreenTapToNavigate => 'Tippen zum Blättern';

  @override
  String get settingsScreenTapToNavigateHint =>
      'Tippen auf das linke oder rechte Viertel des Bildschirms zeigt das vorherige oder nächste Foto';

  @override
  String get settingsScreenVideos => 'Videos';

  @override
  String get settingsScreenAutoPlay => 'Videos automatisch abspielen';

  @override
  String get settingsScreenAutoPlayHint => 'Videos starten beim Öffnen';

  @override
  String get settingsScreenLooping => 'Wiederholen';

  @override
  String get settingsScreenLoopingHint => 'Videos beginnen am Ende von vorn';

  @override
  String get settingsScreenPlayOriginal => 'Originalvideo abspielen';

  @override
  String get settingsScreenPlayOriginalHint =>
      'Spielt das Original, auch wenn es eine umgewandelte Version gibt. Es kann puffern';

  @override
  String get settingsScreenLayout => 'Anordnung';

  @override
  String settingsScreenPerRow(String count) {
    return 'Fotos pro Zeile ($count)';
  }

  @override
  String get settingsScreenGroupBy => 'Gruppieren nach';

  @override
  String get settingsScreenMonthDay => 'Monat + Tag';

  @override
  String get settingsScreenMonth => 'Monat';

  @override
  String get settingsScreenTheme => 'Design';

  @override
  String get settingsScreenPrimaryColor => 'Hauptfarbe';

  @override
  String get settingsScreenHaptics => 'Haptisches Feedback';

  @override
  String get settingsScreenEnabled => 'Aktiviert';

  @override
  String get settingsScreenNotificationsNotYet =>
      'Benachrichtigungen sind noch nicht verfügbar.';

  @override
  String get settingsScreenPhotosAndVideos => 'Fotos und Videos';

  @override
  String get settingsScreenPhone => 'Handy';

  @override
  String get settingsScreenAlbums => 'Alben';

  @override
  String get settingsScreenOther => 'Sonstiges';

  @override
  String get settingsScreenMemories => 'Erinnerungen';

  @override
  String get settingsScreenBackedUp => 'Gesichert';

  @override
  String get settingsScreenCheckAgain => 'Erneut prüfen';

  @override
  String settingsScreenRetryFailed(String count) {
    return 'Die $count fehlgeschlagenen erneut senden';
  }

  @override
  String get settingsScreenRemoved => 'Entfernt.';

  @override
  String get settingsScreenSaved => 'Gespeichert.';

  @override
  String settingsScreenMainAddress(String address) {
    return 'Hauptadresse: $address';
  }

  @override
  String get settingsScreenSecondAddress => 'Zweite Adresse';

  @override
  String get settingsScreenSecondAddressHint =>
      'Wird genutzt, wenn die Hauptadresse nicht antwortet, etwa unterwegs';

  @override
  String get settingsScreenSave => 'Speichern';

  @override
  String get settingsScreenCouldNotLoad => 'Das konnte nicht geladen werden.';

  @override
  String get settingsScreenThisDevice => 'Dieses Gerät';

  @override
  String get settingsScreenSignOut => 'Abmelden';

  @override
  String get settingsScreenSignOutOthers => 'Alle anderen abmelden';

  @override
  String get settingsScreenFavorites => 'Favoriten';

  @override
  String get settingsScreenArchive => 'Archiv';

  @override
  String get settingsScreenTrash => 'Papierkorb';

  @override
  String get settingsScreenUsed => 'Belegt';

  @override
  String get settingsScreenYourAccount => 'Dein Konto';

  @override
  String settingsScreenMemorySeconds(String seconds) {
    return 'Sekunden pro Bild in Erinnerungen ($seconds)';
  }

  @override
  String settingsScreenMinFaces(String count) {
    return 'Mindestanzahl Fotos, damit eine Person erscheint ($count)';
  }

  @override
  String get settingsScreenAlbumOrder => 'Reihenfolge in einem neuen Album';

  @override
  String get settingsScreenNewestFirst => 'Neueste zuerst';

  @override
  String get settingsScreenOldestFirst => 'Älteste zuerst';

  @override
  String get sessionDeviceNotApproved =>
      'Ein Administrator muss dieses Gerät freigeben, bevor es sich anmelden kann.';

  @override
  String get sessionEnterAddress => 'Gib die Adresse deines Servers ein.';

  @override
  String get sessionAddressInvalid => 'Diese Serveradresse ist ungültig.';

  @override
  String get sessionNoServer =>
      'Unter dieser Adresse hat kein Mediarr-Server geantwortet.';

  @override
  String sessionUnreachableCheck(String reason) {
    return 'Server nicht erreichbar. Prüfe die Adresse. ($reason)';
  }

  @override
  String sessionUnreachable(String reason) {
    return 'Server nicht erreichbar. ($reason)';
  }

  @override
  String get sessionCodeWrong => 'Der Code ist falsch.';

  @override
  String get sessionWrongPassword => 'Falsche E-Mail oder falsches Passwort.';

  @override
  String get sessionTooManyAttempts =>
      'Zu viele Versuche. Versuche es später erneut.';

  @override
  String sessionSignInFailed(String code) {
    return 'Anmeldung fehlgeschlagen ($code).';
  }

  @override
  String get sessionNoSession => 'Der Server hat keine Sitzung gestartet.';

  @override
  String get sessionCancelled => 'Die Anmeldung wurde abgebrochen.';

  @override
  String get sessionSsoOff =>
      'Single Sign-on ist für diesen Server nicht aktiviert.';

  @override
  String get sessionSsoFailed =>
      'Single Sign-on hat nicht funktioniert. Vielleicht hast du kein Konto auf diesem Server.';

  @override
  String get sessionCodeExpired =>
      'Dieser Code ist abgelaufen oder wurde schon benutzt. Erstelle einen neuen.';

  @override
  String get sessionNoAnswer => 'Der Server hat nicht geantwortet.';

  @override
  String get sessionNotAllowed => 'Die Anmeldung wurde nicht erlaubt.';

  @override
  String get sessionSignInExpired =>
      'Diese Anmeldung ist abgelaufen. Erstelle einen neuen Code.';

  @override
  String get sessionNobodyAnswered =>
      'Niemand hat rechtzeitig geantwortet. Erstelle einen neuen Code.';

  @override
  String get tusSignedOut => 'Du bist abgemeldet. Melde dich erneut an.';

  @override
  String tusRejected(String code, String body) {
    return 'Der Server hat diese Datei abgelehnt ($code). $body';
  }

  @override
  String albumsScreenInside(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Alben',
      one: '1 Album',
    );
    return '$_temp0';
  }

  @override
  String get albumsScreenLoadFailed =>
      'Alben konnten nicht geladen werden. Prüfe die Verbindung.';

  @override
  String get albumsScreenTryAgain => 'Erneut versuchen';

  @override
  String get albumsScreenNoAlbums => 'Noch keine Alben.';

  @override
  String get albumsScreenNoMatch => 'Kein Album passt dazu.';

  @override
  String get albumsScreenSortUpdated => 'Letzte Änderung';

  @override
  String get albumsScreenName => 'Name';

  @override
  String get albumsScreenSortDate => 'Fotodatum';

  @override
  String get albumsScreenTitle => 'Alben';

  @override
  String get albumsScreenNew => 'Neu';

  @override
  String get albumsScreenSort => 'Sortieren';

  @override
  String get albumsScreenSearchFilter => 'Suchen und filtern';

  @override
  String get albumsScreenShowList => 'Als Liste anzeigen';

  @override
  String get albumsScreenShowGrid => 'Als Raster anzeigen';

  @override
  String get albumsScreenSearchAlbums => 'Alben durchsuchen';

  @override
  String get albumsScreenAll => 'Alle';

  @override
  String get albumsScreenSharedWithMe => 'Mit mir geteilt';

  @override
  String get albumsScreenMine => 'Meine Alben';

  @override
  String albumsScreenItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Elemente',
      one: '1 Element',
    );
    return '$_temp0';
  }

  @override
  String get albumsScreenSmart => 'Smart';

  @override
  String get albumsScreenOwned => 'Eigenes';

  @override
  String get albumsScreenNotCreated => 'Das Album wurde nicht erstellt.';

  @override
  String get albumsScreenNewAlbum => 'Neues Album';

  @override
  String get albumsScreenDescription => 'Beschreibung';

  @override
  String get albumsScreenSmartAlbum =>
      'Smart-Album: füllt sich selbst nach Regeln';

  @override
  String get albumsScreenCreate => 'Erstellen';

  @override
  String get adminScreenTitle => 'Verwaltung';

  @override
  String get adminScreenOverview => 'Übersicht';

  @override
  String get adminScreenOverviewHint =>
      'Benutzer, Fotos, Speicher und Versionen';

  @override
  String get adminScreenUsers => 'Benutzer';

  @override
  String get adminScreenUsersHint =>
      'Benutzer hinzufügen und festlegen, wie viel sie speichern dürfen';

  @override
  String get adminScreenServerSettings => 'Servereinstellungen';

  @override
  String get adminScreenServerSettingsHint =>
      'Papierkorb, Qualität, Gesichter, Aufgaben, Anmeldung';

  @override
  String get adminScreenEmail => 'E-Mail';

  @override
  String get adminScreenEmailHint => 'Von wo Nachrichten gesendet werden';

  @override
  String get adminScreenSecurity => 'Sicherheit';

  @override
  String get adminScreenSecurityHint =>
      'Single Sign-on, Geräte, Adressen, Versuche';

  @override
  String get adminScreenJobs => 'Aufgaben';

  @override
  String get adminScreenJobsHint =>
      'Warteschlangen und fehlgeschlagene Aufgaben';

  @override
  String get adminScreenAuditLog => 'Protokoll';

  @override
  String get adminScreenAuditLogHint => 'Wer was geändert hat';

  @override
  String get adminScreenBackupHint => 'Kopien der Bibliothek';

  @override
  String get adminScreenBackupDevices => 'Alle Sicherungsgeräte';

  @override
  String get adminScreenBackupDevicesHint => 'Jedes Handy, das sichert';

  @override
  String get adminScreenStorageTemplate => 'Speichervorlage';

  @override
  String get adminScreenStorageTemplateHint =>
      'Wie Originale auf dem Datenträger abgelegt werden';

  @override
  String get adminAuditEmpty => 'Noch wurde nichts geändert.';

  @override
  String get adminAuditShowOlder => 'Ältere anzeigen';

  @override
  String adminUsersAdded(String email) {
    return '$email wurde hinzugefügt.';
  }

  @override
  String get adminUsersAddUser => 'Benutzer hinzufügen';

  @override
  String get adminUsersAdministrator => 'Administrator';

  @override
  String adminUsersStoredOf(String stored, String quota) {
    return '$stored von $quota';
  }

  @override
  String get adminUsersNoLimit => 'kein Limit';

  @override
  String adminUsersQuotaTooltip(String email) {
    return 'Wie viel $email speichern darf';
  }

  @override
  String get adminUsersEmail => 'E-Mail';

  @override
  String get adminUsersName => 'Name';

  @override
  String get adminUsersPassword => 'Passwort';

  @override
  String get adminUsersCancel => 'Abbrechen';

  @override
  String get adminUsersAdd => 'Hinzufügen';

  @override
  String get adminUsersQuotaInvalid =>
      'Gib eine Zahl in Gigabyte ein oder nichts für kein Limit.';

  @override
  String adminUsersStorageFor(String email) {
    return 'Speicher für $email';
  }

  @override
  String get adminUsersLimitGb => 'Limit in GB';

  @override
  String get adminUsersEmptyNoLimit => 'Leer bedeutet kein Limit.';

  @override
  String get profileScreenNotSaved =>
      'Das Profil konnte nicht gespeichert werden.';

  @override
  String get profileScreenPictureNotSent =>
      'Das Bild konnte nicht gesendet werden.';

  @override
  String get profileScreenPictureNotRemoved =>
      'Das Bild konnte nicht entfernt werden.';

  @override
  String get profileScreenTitle => 'Profil';

  @override
  String get profileScreenChangePicture => 'Bild ändern';

  @override
  String get profileScreenAddPicture => 'Bild hinzufügen';

  @override
  String get profileScreenRemove => 'Entfernen';

  @override
  String get profileScreenEmailAddress => 'E-Mail-Adresse';

  @override
  String get profileScreenCurrentPassword =>
      'Aktuelles Passwort, um die E-Mail zu ändern';

  @override
  String get serverStatusStorage => 'Speicher';

  @override
  String serverStatusUsedOf(String used, String total) {
    return '$used von $total belegt';
  }

  @override
  String get serverStatusOnline => 'Server online';

  @override
  String get serverStatusMaintained => 'Server wird gewartet';

  @override
  String get serverStatusOffline => 'Server offline';

  @override
  String serverStatusVersionAvailable(String version) {
    return 'Version $version ist verfügbar';
  }

  @override
  String get serverStatusNewVersion => 'Eine neue Version ist verfügbar';

  @override
  String serverStatusUpdateBody(String latest, String version) {
    return 'Mediarr $latest ist verfügbar. Dieser Server läuft mit $version. Der Serveradministrator aktualisiert ihn mit:\n\ndocker compose pull && docker compose up -d';
  }

  @override
  String get serverStatusOk => 'OK';

  @override
  String get storiesStripLastWeek => 'Die letzte Woche';

  @override
  String storiesStripYearsAgo(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: 'Vor $years Jahren',
      one: 'Vor 1 Jahr',
    );
    return '$_temp0';
  }

  @override
  String storiesStripItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Elemente',
      one: '1 Element',
    );
    return '$_temp0';
  }

  @override
  String get backupScreenNotYet => 'noch nicht';

  @override
  String backupScreenLastBackup(String when) {
    return 'letzte Sicherung $when';
  }

  @override
  String backupScreenUpTo(String size) {
    return 'bis zu $size';
  }

  @override
  String get backupScreenInvited => 'Eingeladen';

  @override
  String get backupScreenStopped => 'Gestoppt';

  @override
  String get backupScreenActive => 'Aktiv';

  @override
  String backupScreenDeletedKept(String size) {
    return 'gelöscht, aufbewahrt: $size';
  }

  @override
  String get backupScreenActionFailed => 'Die Aktion ist fehlgeschlagen.';

  @override
  String get backupScreenSaved => 'Gespeichert.';

  @override
  String get backupScreenBackupStarted => 'Die Sicherung hat begonnen.';

  @override
  String get backupScreenRestoreTestStarted =>
      'Der Wiederherstellungstest hat begonnen.';

  @override
  String get backupScreenPaired =>
      'Gekoppelt. Die nächste Sicherung geht auch dorthin.';

  @override
  String get backupScreenKeepForSomeone =>
      'Eine Sicherung für jemanden aufbewahren';

  @override
  String get backupScreenForWhom => 'Für wen';

  @override
  String get backupScreenAtMostGb => 'Höchstens (GB)';

  @override
  String get backupScreenOtherServerAddress =>
      'Die Adresse, unter der dich der andere Server erreicht';

  @override
  String get backupScreenCancel => 'Abbrechen';

  @override
  String get backupScreenInvite => 'Einladen';

  @override
  String get backupScreenInvitationFailed =>
      'Die Einladung ist fehlgeschlagen.';

  @override
  String backupScreenCodeFor(String name) {
    return 'Code für $name';
  }

  @override
  String backupScreenSendItToAdmin(String when) {
    return 'Schick ihn dem Administrator des anderen Servers, der ihn einfügt oder scannt. Er gilt einmal, bis $when.';
  }

  @override
  String get backupScreenPlainHttp =>
      'Über einfaches HTTP kann der Schlüssel unterwegs mitgelesen werden. Nutze HTTPS oder ein VPN.';

  @override
  String get backupScreenCopy => 'Kopieren';

  @override
  String get backupScreenDone => 'Fertig';

  @override
  String backupScreenHowMuchFor(String name) {
    return 'Wie viel für $name';
  }

  @override
  String get backupScreenSave => 'Speichern';

  @override
  String backupScreenDeleteCopyOf(String name) {
    return 'Die Kopie von $name löschen?';
  }

  @override
  String backupScreenTypeToDelete(String name) {
    return 'Gib „$name“ ein, um sie zu löschen';
  }

  @override
  String get backupScreenDeleteTheCopy => 'Kopie löschen';

  @override
  String get backupScreenScheduledBackup => 'Geplante Sicherung';

  @override
  String get backupScreenOnceADay => 'Einmal am Tag, zur Stunde unten';

  @override
  String backupScreenExplain(String folder) {
    return 'Originale und die Datenbank, verschlüsselt. Das Ziel ist ein Ordner in $folder oder eine s3:- bzw. b2:-Adresse. Schreib das Passwort an einem anderen Ort als diesem Server auf.';
  }

  @override
  String get backupScreenBackupFolder => 'dem Sicherungsordner';

  @override
  String get backupScreenDestination => 'Ziel';

  @override
  String get backupScreenPasswordSaved =>
      'Passwort (gespeichert, zum Ändern eingeben)';

  @override
  String get backupScreenBackupPassword => 'Sicherungspasswort';

  @override
  String get backupScreenAccessKeySaved => 'Zugriffsschlüssel (gespeichert)';

  @override
  String get backupScreenAccessKey => 'Zugriffsschlüssel (S3, B2)';

  @override
  String get backupScreenSecretKey => 'Geheimer Schlüssel (S3, B2)';

  @override
  String get backupScreenHourOfDay => 'Stunde des Tages (0-23)';

  @override
  String get backupScreenBackUpNow => 'Jetzt sichern';

  @override
  String get backupScreenTestBringingBack => 'Wiederherstellung testen';

  @override
  String get backupScreenHistory => 'Verlauf';

  @override
  String get backupScreenRunBackup => 'Sicherung';

  @override
  String get backupScreenRunRestoreTest => 'Wiederherstellungstest';

  @override
  String backupScreenFiles(String count) {
    return 'Dateien: $count';
  }

  @override
  String get backupScreenMyCopyAtOthers => 'Meine Kopie bei anderen';

  @override
  String get backupScreenTwoServers =>
      'Zwei Mediarr-Server bewahren gegenseitig eine verschlüsselte Kopie auf. Wer sie aufbewahrt, kann sie nicht lesen, und was daraus gelöscht wird, bleibt noch 90 Tage erhalten.';

  @override
  String get backupScreenNoHttps => 'Kein HTTPS';

  @override
  String get backupScreenMore => 'Mehr';

  @override
  String get backupScreenRemove => 'Entfernen';

  @override
  String get backupScreenCodeFromOther => 'Code vom anderen Mediarr';

  @override
  String get backupScreenScanQr => 'QR-Code scannen';

  @override
  String get backupScreenPairing => 'Wird gekoppelt…';

  @override
  String get backupScreenPair => 'Koppeln';

  @override
  String get backupScreenSnapshots => 'Schnappschüsse vor Upgrades';

  @override
  String get backupScreenSnapshotsExplain =>
      'Vor jedem Upgrade, das die Datenbank ändert, legt Mediarr einen Schnappschuss davon an. Die letzten drei bleiben erhalten.';

  @override
  String get backupScreenNoSnapshots =>
      'Noch keine Schnappschüsse. Der erste entsteht beim nächsten Upgrade, das die Datenbank ändert.';

  @override
  String get backupScreenEarlierVersion => 'Frühere Version';

  @override
  String get backupScreenDeleteSnapshot => 'Schnappschuss löschen';

  @override
  String get backupScreenGoBackHow =>
      'Um zum neuesten zurückzukehren, im Ordner mit docker-compose.yml:';

  @override
  String get backupScreenDeleteThisSnapshot => 'Diesen Schnappschuss löschen?';

  @override
  String get backupScreenNoGoingBack =>
      'Dann kann man nicht mehr zu ihm zurückkehren.';

  @override
  String get backupScreenDelete => 'Löschen';

  @override
  String get backupScreenNotDeleted => 'Nicht gelöscht.';

  @override
  String get backupScreenIKeepForOthers => 'Ich bewahre für andere auf';

  @override
  String get backupScreenNoNewCode => 'Kein neuer Code.';

  @override
  String backupScreenFilesBroughtBack(String count) {
    return 'Zurückgeholte Dateien: $count.';
  }

  @override
  String get backupScreenNewCode => 'Neuer Code';

  @override
  String get backupScreenResume => 'Fortsetzen';

  @override
  String get backupScreenStop => 'Stoppen';

  @override
  String get backupScreenSize => 'Größe';

  @override
  String get backupScreenBringBackDeleted => 'Gelöschtes zurückholen';

  @override
  String get backupScreenTitle => 'Sicherung';

  @override
  String get backupScreenLoadFailed =>
      'Die Sicherungseinstellungen konnten nicht geladen werden.';

  @override
  String get backupScreenScanTheCode => 'Code scannen';

  @override
  String get duplicatesScreenFavorite => 'Favorit';

  @override
  String get duplicatesScreenOriginal => 'Original';

  @override
  String get duplicatesScreenSavedAgain => 'Von einer App erneut gespeichert';

  @override
  String get duplicatesScreenHasLocation => 'Hat einen Ort';

  @override
  String get duplicatesScreenHasDescription => 'Hat eine Beschreibung';

  @override
  String get duplicatesScreenNoDate => 'Kein Datum';

  @override
  String get duplicatesScreenReasonFavorite => 'ein Favorit';

  @override
  String get duplicatesScreenReasonCameraOriginal => 'das Original der Kamera';

  @override
  String get duplicatesScreenReasonOthersSaved =>
      'die anderen wurden von Apps erneut gespeichert';

  @override
  String get duplicatesScreenReasonHighestResolution => 'die höchste Auflösung';

  @override
  String get duplicatesScreenReasonLargestFile => 'die größte Datei';

  @override
  String get duplicatesScreenReasonEqual =>
      'sie sind gleich, also kann jede bleiben';

  @override
  String get duplicatesScreenReasonSharpest => 'die schärfste';

  @override
  String get duplicatesScreenCancel => 'Abbrechen';

  @override
  String get duplicatesScreenResolveThisGroup => 'Diese Gruppe auflösen?';

  @override
  String get duplicatesScreenKeptTakesOver =>
      'Das behaltene Foto übernimmt Alben, Schlagwörter, Favorit, Beschreibung, Bewertung, Ort und Namen von Personen von den anderen. Diese kommen in den Papierkorb und können wiederhergestellt werden.';

  @override
  String get duplicatesScreenResolve => 'Auflösen';

  @override
  String get duplicatesScreenResolved =>
      'Aufgelöst. Die Kopien sind im Papierkorb.';

  @override
  String get duplicatesScreenActionFailed => 'Die Aktion ist fehlgeschlagen.';

  @override
  String get duplicatesScreenResolveEveryIdentical =>
      'Alle identischen Bilder auflösen?';

  @override
  String get duplicatesScreenResolveAllDuplicates => 'Alle Duplikate auflösen?';

  @override
  String duplicatesScreenResolveAllBody(
    String groups,
    String trashed,
    String size,
  ) {
    return 'Gruppen: $groups. $trashed Fotos kommen in den Papierkorb, was $size freigibt, sobald er geleert wird. In jeder Gruppe bleibt das vorgeschlagene Foto und übernimmt, was die anderen hatten.';
  }

  @override
  String get duplicatesScreenResolveAll => 'Alle auflösen';

  @override
  String get duplicatesScreenSamePicture => 'Gleiches Bild';

  @override
  String get duplicatesScreenAlike => 'Ähnlich';

  @override
  String duplicatesScreenProposedToKeep(String reason, String size) {
    return 'Zum Behalten vorgeschlagen: $reason · gibt $size frei';
  }

  @override
  String get duplicatesScreenNotDuplicates => 'Keine Duplikate';

  @override
  String duplicatesScreenResolveToTrash(String count) {
    return 'Auflösen ($count in den Papierkorb)';
  }

  @override
  String get duplicatesScreenTitle => 'Duplikate';

  @override
  String get duplicatesScreenLoadFailed =>
      'Duplikate konnten nicht geladen werden.';

  @override
  String duplicatesScreenPending(String count) {
    return 'Fotos, die noch verglichen werden: $count.';
  }

  @override
  String get duplicatesScreenNoneFound =>
      'Es wurden keine ähnlichen Fotos gefunden.';

  @override
  String get duplicatesScreenTickWhatToKeep =>
      'Hake an, was bleiben soll. Das sind nur Vorschläge, und ohne deine Bestätigung wird nichts entfernt.';

  @override
  String duplicatesScreenShowing(String shown, String total) {
    return '$shown von $total angezeigt.';
  }

  @override
  String duplicatesScreenResolving(String done, String total) {
    return 'Duplikate werden aufgelöst: $done von $total';
  }

  @override
  String duplicatesScreenResolveIdentical(String count) {
    return 'Identische auflösen ($count)';
  }

  @override
  String duplicatesScreenResolveAllAsProposed(String count) {
    return 'Alle wie vorgeschlagen auflösen ($count)';
  }

  @override
  String get duplicatesScreenStackLoadFailed =>
      'Dieser Stapel konnte nicht geladen werden.';

  @override
  String get duplicatesScreenSplitStack => 'Stapel auflösen';

  @override
  String get duplicatesScreenMakeMain => 'Zum Hauptbild machen';

  @override
  String accountSheetVersionBuild(String version, String build) {
    return '$version Build $build';
  }

  @override
  String get accountSheetEditProfile => 'Profil bearbeiten';

  @override
  String get accountSheetClose => 'Schließen';

  @override
  String accountSheetPhotosAndVideos(String count) {
    return '$count Fotos und Videos';
  }

  @override
  String accountSheetUsed(String size) {
    return '$size belegt';
  }

  @override
  String accountSheetFilesFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien konnten nicht verarbeitet werden',
      one: '1 Datei konnte nicht verarbeitet werden',
    );
    return '$_temp0';
  }

  @override
  String get accountSheetAppearance => 'Darstellung';

  @override
  String get accountSheetDark => 'Dunkel';

  @override
  String get accountSheetLight => 'Hell';

  @override
  String get accountSheetSystem => 'System';

  @override
  String get accountSheetServerDisk => 'Serverspeicher';

  @override
  String get accountSheetLoading => 'Wird geladen…';

  @override
  String get accountSheetServerNoAnswer => 'Der Server antwortet nicht.';

  @override
  String accountSheetDiskUsed(String used, String total) {
    return '$used von $total belegt';
  }

  @override
  String get accountSheetAppVersion => 'App-Version';

  @override
  String get accountSheetServerVersion => 'Serverversion';

  @override
  String get accountSheetNewVersion => 'Neue Version';

  @override
  String accountSheetIsAvailable(String version) {
    return '$version ist verfügbar';
  }

  @override
  String get accountSheetServer => 'Server';

  @override
  String get accountSheetServerAddress => 'Serveradresse';

  @override
  String get accountSheetFreeUpSpace => 'Speicher freigeben';

  @override
  String get accountSheetProfile => 'Profil';

  @override
  String get accountSheetSignInOnAnotherDevice =>
      'Auf einem anderen Gerät anmelden';

  @override
  String get accountSheetBackupDevices => 'Sicherungsgeräte';

  @override
  String get accountSheetImport => 'Import';

  @override
  String get accountSheetAdministration => 'Verwaltung';

  @override
  String get accountSheetBackup => 'Sicherung';

  @override
  String get accountSheetAllBackupDevices => 'Alle Sicherungsgeräte';

  @override
  String get accountSheetStorageTemplate => 'Speichervorlage';

  @override
  String get accountSheetSettings => 'Einstellungen';

  @override
  String get accountSheetSignOut => 'Abmelden';

  @override
  String get accountSheetDocumentation => 'Dokumentation';

  @override
  String get accountSheetLicenses => 'Lizenzen';

  @override
  String get searchFiltersSheetFilters => 'Filter';

  @override
  String get searchFiltersSheetDate => 'Datum';

  @override
  String get searchFiltersSheetFrom => 'Von';

  @override
  String get searchFiltersSheetTo => 'Bis';

  @override
  String get searchFiltersSheetType => 'Typ';

  @override
  String get searchFiltersSheetAll => 'Alle';

  @override
  String get searchFiltersSheetPhotos => 'Fotos';

  @override
  String get searchFiltersSheetVideos => 'Videos';

  @override
  String get searchFiltersSheetPeople => 'Personen';

  @override
  String get searchFiltersSheetAnyOfThem => 'Eine davon, nicht alle zusammen';

  @override
  String get searchFiltersSheetWhereAndWith => 'Wo und womit';

  @override
  String get searchFiltersSheetPlace => 'Ort';

  @override
  String get searchFiltersSheetCamera => 'Kamera';

  @override
  String get searchFiltersSheetLens => 'Objektiv';

  @override
  String get searchFiltersSheetRating => 'Bewertung';

  @override
  String get searchFiltersSheetAnyRating => 'Beliebig';

  @override
  String get searchFiltersSheetTags => 'Schlagwörter';

  @override
  String get searchFiltersSheetAlbum => 'Album';

  @override
  String get searchFiltersSheetAnyAlbum => 'Beliebig';

  @override
  String get searchFiltersSheetInNoAlbum => 'In keinem Album';

  @override
  String get searchFiltersSheetFavouritesOnly => 'Nur Favoriten';

  @override
  String get searchFiltersSheetClear => 'Zurücksetzen';

  @override
  String get searchFiltersSheetApply => 'Anwenden';

  @override
  String get adminEmailPortNumber => 'Der Port muss eine Zahl sein.';

  @override
  String get adminEmailSaved => 'Die E-Mail-Einstellungen sind gespeichert.';

  @override
  String get adminEmailTestSent => 'Dir wurde eine Testnachricht gesendet.';

  @override
  String get adminEmailTitle => 'E-Mail';

  @override
  String get adminEmailSendEmail => 'E-Mails senden';

  @override
  String get adminEmailSmtpServer => 'SMTP-Server';

  @override
  String get adminEmailPort => 'Port';

  @override
  String get adminEmailEncryption => 'Verschlüsselung';

  @override
  String get adminEmailNone => 'Keine';

  @override
  String get adminEmailUserName => 'Benutzername';

  @override
  String get adminEmailPassword => 'Passwort';

  @override
  String get adminEmailPasswordSaved =>
      'Ein Passwort ist gespeichert. Leer lassen behält es.';

  @override
  String get adminEmailFrom => 'Absender';

  @override
  String get adminEmailServerAddress => 'Adresse dieses Servers';

  @override
  String get adminEmailForLinks => 'Für Links in Nachrichten';

  @override
  String get adminEmailSave => 'Speichern';

  @override
  String get adminEmailSendTest => 'Testnachricht senden';

  @override
  String photoEditorScreenActionFailed(String reason) {
    return 'Die Aktion ist fehlgeschlagen. $reason';
  }

  @override
  String get photoEditorScreenEdit => 'Bearbeiten';

  @override
  String get photoEditorScreenRotate => 'Drehen';

  @override
  String get photoEditorScreenBrightness => 'Helligkeit';

  @override
  String get photoEditorScreenContrast => 'Kontrast';

  @override
  String get photoEditorScreenSaturation => 'Sättigung';

  @override
  String get photoEditorScreenNoFilter => 'Kein Filter';

  @override
  String get photoEditorScreenBlackAndWhite => 'Schwarzweiß';

  @override
  String get photoEditorScreenWarm => 'Warm';

  @override
  String get photoEditorScreenCool => 'Kühl';

  @override
  String get photoEditorScreenVintage => 'Vintage';

  @override
  String get photoEditorScreenVivid => 'Lebhaft';

  @override
  String get photoEditorScreenBackToOriginal => 'Zurück zum Original';

  @override
  String get photoEditorScreenSave => 'Speichern';

  @override
  String get homeWidgetScreenHowToIos =>
      'Dann halte eine freie Stelle auf dem Home-Bildschirm gedrückt, tippe auf + (oder Bearbeiten, Widget hinzufügen) und wähle Mediarr.';

  @override
  String get homeWidgetScreenHowToAndroid =>
      'Dann halte eine freie Stelle auf dem Startbildschirm gedrückt, tippe auf Widgets und zieh Mediarr dorthin.';

  @override
  String get homeWidgetScreenFetchesItself =>
      'Das Widget holt seine Fotos selbst und behält ein paar.';

  @override
  String get homeWidgetScreenFetching => 'Fotos werden geholt…';

  @override
  String homeWidgetScreenPicturesKept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fotos dafür auf diesem Handy gespeichert',
      one: '1 Foto dafür auf diesem Handy gespeichert',
    );
    return '$_temp0';
  }

  @override
  String get homeWidgetScreenDidNotWork => 'Das hat nicht geklappt.';

  @override
  String get homeWidgetScreenTitle => 'Widget für den Startbildschirm';

  @override
  String homeWidgetScreenIntro(String howTo) {
    return 'Das Widget zeigt ein Foto aus dem Album, das du hier wählst, jede Stunde ein anderes, auch ohne Verbindung. $howTo';
  }

  @override
  String homeWidgetScreenShowing(String album) {
    return 'Zeigt $album';
  }

  @override
  String get homeWidgetScreenShowsNothing =>
      'Das Widget zeigt jetzt nichts an.';

  @override
  String get homeWidgetScreenTurnOff => 'Ausschalten';

  @override
  String get homeWidgetScreenAlbum => 'Album';

  @override
  String get homeWidgetScreenNoAlbums => 'Es gibt noch keine Alben.';

  @override
  String homeWidgetScreenShows(String album) {
    return 'Das Widget zeigt $album.';
  }

  @override
  String get homeWidgetNoKey =>
      'Der Server hat keinen Schlüssel für das Widget erstellt.';

  @override
  String get settingsAccentMidnightBlue => 'Mitternachtsblau';

  @override
  String get settingsAccentGold => 'Gold';

  @override
  String get settingsAccentViolet => 'Violett';

  @override
  String get settingsAccentMint => 'Mint';

  @override
  String get settingsAccentRose => 'Rosa';

  @override
  String get settingsThemeAuto => 'Automatisch';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String get homeScreenMedia => 'Medien';

  @override
  String get homeScreenSearch => 'Suche';

  @override
  String get homeScreenAlbums => 'Alben';

  @override
  String get homeScreenLibrary => 'Bibliothek';

  @override
  String get homeScreenAdd => 'Hinzufügen';

  @override
  String homeScreenAddUploading(String count) {
    return 'Hinzufügen, $count werden hochgeladen';
  }

  @override
  String get panoramaViewCannotBeShown =>
      'Das Panorama kann nicht angezeigt werden.';

  @override
  String get panoramaViewLabel => '360°-Panorama';

  @override
  String fixSheetChanged(int changed) {
    return 'Geändert: $changed';
  }

  @override
  String get fixSheetCameraClockWrong => 'Wenn die Uhr der Kamera falsch ging.';

  @override
  String get fixSheetEarlier => 'Früher';

  @override
  String get fixSheetLater => 'Später';

  @override
  String get fixSheetDays => 'Tage';

  @override
  String get fixSheetHours => 'Stunden';

  @override
  String get fixSheetMinutes => 'Minuten';

  @override
  String get fixSheetOneDateForAll =>
      'Ein Datum für alle, je eine Minute auseinander, damit die Reihenfolge bleibt.';

  @override
  String get fixSheetChooseDateTime => 'Datum und Uhrzeit wählen';

  @override
  String get fixSheetTripHint =>
      'Wenn die Kamera auf einer Reise die Zeit von zu Hause behielt.';

  @override
  String get fixSheetCameraClockWasOn => 'Die Uhr der Kamera stand auf';

  @override
  String get fixSheetTheyWereTakenIn => 'Aufgenommen in';

  @override
  String get fixSheetZoneFromPlaceHint =>
      'Fotos mit Ort bekommen die Zeitzone des Ortes, Sommerzeit inklusive; die Uhrzeit bleibt, wie sie war.';

  @override
  String get fixSheetDatesByHandRemoved =>
      'Von Hand gesetzte Daten werden entfernt.';

  @override
  String get fixSheetNeighboursHint =>
      'Fotos ohne Ort bekommen den Ort des Fotos mit Ort, das zeitlich am nächsten aufgenommen wurde.';

  @override
  String get fixSheetAtMostMinutesApart => 'Höchstens Minuten Abstand';

  @override
  String get fixSheetTrackHint =>
      'Fotos ohne Ort bekommen den Ort aus dem Track zum Zeitpunkt der Aufnahme. Korrigiere zuerst das Datum.';

  @override
  String get fixSheetChooseGpx => 'GPX-Datei wählen';

  @override
  String get fixSheetFindPlace => 'Ort suchen';

  @override
  String get fixSheetLatitude => 'Breitengrad';

  @override
  String get fixSheetLongitude => 'Längengrad';

  @override
  String get fixSheetLocationGoes => 'Der Ort wird entfernt und bleibt weg.';

  @override
  String get fixSheetLocationsByHandRemoved =>
      'Von Hand gesetzte Orte werden entfernt.';

  @override
  String fixSheetDateTitle(int count) {
    return 'Datum und Uhrzeit · $count';
  }

  @override
  String fixSheetLocationTitle(int count) {
    return 'Ort · $count';
  }

  @override
  String get fixSheetShift => 'Verschieben';

  @override
  String get fixSheetSetDate => 'Datum setzen';

  @override
  String get fixSheetZoneFromPlace => 'Zone vom Ort';

  @override
  String get fixSheetTrip => 'Eine Reise';

  @override
  String get fixSheetFromFile => 'Aus der Datei';

  @override
  String get fixSheetFromNearby => 'Von Fotos in der Nähe';

  @override
  String get fixSheetFromTrack => 'Aus einem GPX-Track';

  @override
  String get fixSheetSetPlace => 'Ort setzen';

  @override
  String get fixSheetClearLocation => 'Ort entfernen';

  @override
  String fixSheetWillChange(int changed) {
    return 'Wird geändert: $changed';
  }

  @override
  String fixSheetNothingToGoBy(int skipped) {
    return 'ohne Anhaltspunkt: $skipped';
  }

  @override
  String get fixSheetNoLocation => 'kein Ort';

  @override
  String get fixSheetCancel => 'Abbrechen';

  @override
  String get fixSheetSave => 'Speichern';

  @override
  String get adminSecurityRulesSaved => 'Die Regeln sind gespeichert.';

  @override
  String get adminSecuritySsoSaved => 'Single Sign-on ist gespeichert.';

  @override
  String get adminSecurityForgetTitle => 'Dieses Gerät vergessen?';

  @override
  String adminSecurityApproveAgain(String email) {
    return '$email muss darauf erneut freigegeben werden.';
  }

  @override
  String get adminSecurityCancel => 'Abbrechen';

  @override
  String get adminSecurityForget => 'Vergessen';

  @override
  String get adminSecurityDeviceForgotten => 'Das Gerät ist vergessen.';

  @override
  String get adminSecurityTitle => 'Sicherheit';

  @override
  String get adminSecuritySingleSignOn => 'Single Sign-on';

  @override
  String get adminSecurityIssuer => 'Aussteller';

  @override
  String get adminSecurityIssuerHelp => 'Leer schaltet Single Sign-on aus';

  @override
  String get adminSecurityClientId => 'Client-ID';

  @override
  String get adminSecurityClientSecret => 'Client-Secret';

  @override
  String get adminSecuritySecretSaved =>
      'Ein Secret ist gespeichert. Leer lässt es so.';

  @override
  String get adminSecurityButtonLabel => 'Beschriftung der Schaltfläche';

  @override
  String get adminSecurityAutoCreate =>
      'Konto bei der ersten Anmeldung anlegen';

  @override
  String get adminSecurityLinkAdmins =>
      'Administratoren dürfen sich so anmelden';

  @override
  String get adminSecuritySaveSso => 'Single Sign-on speichern';

  @override
  String get adminSecurityRules => 'Regeln';

  @override
  String get adminSecurityApprovalRequired =>
      'Neue Geräte müssen freigegeben werden';

  @override
  String get adminSecurityAllowlist =>
      'Nur diese Adressen dürfen den Server erreichen';

  @override
  String adminSecurityYourAddress(String address) {
    return 'Deine Adresse jetzt: $address';
  }

  @override
  String get adminSecurityAddresses => 'Adressen und Netzwerke';

  @override
  String get adminSecurityAddressesHelp =>
      'Eine pro Zeile, z. B. 192.168.1.0/24';

  @override
  String get adminSecuritySaveRules => 'Regeln speichern';

  @override
  String get adminSecurityDevices => 'Geräte';

  @override
  String get adminSecurityNoDevices =>
      'Noch kein Gerät hat versucht, sich anzumelden.';

  @override
  String adminSecurityLastSeen(String time) {
    return 'zuletzt $time';
  }

  @override
  String get adminSecurityDeviceApproved => 'Das Gerät darf sich anmelden.';

  @override
  String get adminSecurityApprove => 'Freigeben';

  @override
  String get adminSecurityAttempts => 'Zugriffsversuche';

  @override
  String get adminSecuritySignedIn => 'Angemeldet';

  @override
  String get adminSecurityWrongSignIn => 'Falsche Anmeldung';

  @override
  String get adminSecurityTooManyAttempts => 'Zu viele Versuche';

  @override
  String get adminSecurityAddressBlocked => 'Adresse gesperrt';

  @override
  String get adminSecurityDeviceNotApproved => 'Gerät nicht freigegeben';

  @override
  String get adminSecurityPasswordReset => 'Passwort zurückgesetzt';

  @override
  String get adminSecurityNoAttempts => 'Noch keine Versuche.';

  @override
  String get adminSecurityShowOlder => 'Ältere anzeigen';

  @override
  String adminCommonNoAnswer(String code) {
    return 'Der Server hat nicht geantwortet ($code).';
  }

  @override
  String get devicesScreenQuiet => 'Still';

  @override
  String get devicesScreenNeedsALook => 'Bitte prüfen';

  @override
  String get devicesScreenAllGood => 'Alles gut';

  @override
  String devicesScreenConfirmed(String count) {
    return '$count Dateien vom Server bestätigt';
  }

  @override
  String devicesScreenOfSent(String line, String files) {
    return '$line, von $files, die das Gerät gesendet hat';
  }

  @override
  String devicesScreenWaiting(String count) {
    return 'wartend $count';
  }

  @override
  String devicesScreenNotSent(String count) {
    return 'nicht gesendet $count';
  }

  @override
  String devicesScreenInTrash(String count) {
    return 'im Papierkorb $count';
  }

  @override
  String devicesScreenGone(String count) {
    return 'nicht mehr auf dem Server $count';
  }

  @override
  String get devicesScreenNever => 'Nie';

  @override
  String devicesScreenDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get devicesScreenNotLoaded => 'Nicht geladen.';

  @override
  String devicesScreenRemoveTitle(String name) {
    return '$name entfernen?';
  }

  @override
  String get devicesScreenRemoveBody =>
      'Seine Fotos bleiben auf dem Server. Meldet es sich wieder, kommt es zurück.';

  @override
  String get devicesScreenCancel => 'Abbrechen';

  @override
  String get devicesScreenRemove => 'Entfernen';

  @override
  String get devicesScreenNotRemoved => 'Nicht entfernt.';

  @override
  String get devicesScreenSaved => 'Gespeichert.';

  @override
  String get devicesScreenNotSaved => 'Nicht gespeichert.';

  @override
  String devicesScreenThisPhone(String name) {
    return '$name · Dieses Handy';
  }

  @override
  String devicesScreenLastReport(String time) {
    return 'letzte Meldung $time';
  }

  @override
  String devicesScreenOnDevice(String verified, String total) {
    return '$verified von $total auf dem Gerät';
  }

  @override
  String get devicesScreenQuietWarning =>
      'Es hat sich länger nicht gemeldet, als du erlaubst. Öffne Mediarr darauf und prüfe, ob die Sicherung an ist.';

  @override
  String get devicesScreenNothingMissing => 'Nichts fehlt.';

  @override
  String get devicesScreenInTrashOnServer => 'im Papierkorb auf dem Server';

  @override
  String get devicesScreenDeletedFromServer => 'vom Server gelöscht';

  @override
  String get devicesScreenWhatIsMissing => 'Was fehlt';

  @override
  String get devicesScreenHide => 'Ausblenden';

  @override
  String get devicesScreenTryingAgain => 'Neuer Versuch.';

  @override
  String get devicesScreenTryAgain => 'Erneut versuchen';

  @override
  String get devicesScreenAllBackupDevices => 'Alle Sicherungsgeräte';

  @override
  String get devicesScreenBackupDevices => 'Sicherungsgeräte';

  @override
  String get devicesScreenAllIntro =>
      'Die Geräte aller Nutzer, die sichern. Wird eines still, wird sein Besitzer gewarnt.';

  @override
  String get devicesScreenIntro =>
      'Handys, die sichern, und wie viel von jedem sicher auf dem Server ist. Der Server zählt, anhand seiner eigenen Dateien.';

  @override
  String get devicesScreenDidNotLoad =>
      'Die Geräte wurden nicht geladen. Zum erneuten Versuch nach unten ziehen.';

  @override
  String get devicesScreenNoneReported => 'Noch kein Gerät hat sich gemeldet.';

  @override
  String get devicesScreenNoneReportedTurnOn =>
      'Noch kein Gerät hat sich gemeldet. Schalte die automatische Sicherung unter Upload ein.';

  @override
  String get devicesScreenWarnMeAfter => 'Warnen nach';

  @override
  String get devicesScreenWarnHelp =>
      'Ein Hinweis hier und im Web, und per E-Mail, falls eingerichtet. Einmal, bis sich das Gerät wieder meldet.';

  @override
  String timelineScreenActionFailed(String message) {
    return 'Die Aktion ist fehlgeschlagen. $message';
  }

  @override
  String get timelineScreenSetVaultPin =>
      'Lege zuerst eine Tresor-PIN fest: Konto > Tresor.';

  @override
  String timelineScreenDeleteTitle(String count) {
    return '$count löschen?';
  }

  @override
  String get timelineScreenTrashRestorable =>
      'Sie kommen in den Papierkorb und können wiederhergestellt werden.';

  @override
  String timelineScreenTrashDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tage',
      one: '$days Tag',
    );
    return 'Sie kommen in den Papierkorb, bleiben dort $_temp0 und können wiederhergestellt werden.';
  }

  @override
  String get timelineScreenCancel => 'Abbrechen';

  @override
  String get timelineScreenDelete => 'Löschen';

  @override
  String get timelineScreenLoadFailed =>
      'Deine Fotos konnten nicht geladen werden. Prüfe die Verbindung.';

  @override
  String get timelineScreenTryAgain => 'Erneut versuchen';

  @override
  String get timelineScreenEmpty =>
      'Noch keine Fotos. Füge die ersten im Tab Upload hinzu.';

  @override
  String get timelineScreenMedia => 'Medien';

  @override
  String get timelineScreenClearSelection => 'Auswahl aufheben';

  @override
  String get timelineScreenAddToAlbum => 'Zum Album hinzufügen';

  @override
  String get timelineScreenShare => 'Teilen';

  @override
  String get timelineScreenAddToFavorites => 'Zu Favoriten hinzufügen';

  @override
  String get timelineScreenMore => 'Mehr';

  @override
  String get timelineScreenArchive => 'Archivieren';

  @override
  String get timelineScreenAddTag => 'Schlagwort hinzufügen';

  @override
  String get timelineScreenDateTimeMenu => 'Datum und Uhrzeit…';

  @override
  String get timelineScreenLocationMenu => 'Ort…';

  @override
  String get timelineScreenMoveToVault => 'In den Tresor verschieben';

  @override
  String timelineScreenMonthFailed(String month) {
    return '$month konnte nicht geladen werden. Erneut versuchen.';
  }

  @override
  String agentProgramOnSystem(String program, String system) {
    return '$program auf $system';
  }

  @override
  String get agentUnknownDevice => 'Unbekanntes Gerät';

  @override
  String get agentMediarrApp => 'Mediarr-App';

  @override
  String get agentNow => 'jetzt';

  @override
  String agentMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Minuten',
      one: 'vor 1 Minute',
    );
    return '$_temp0';
  }

  @override
  String agentHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Stunden',
      one: 'vor 1 Stunde',
    );
    return '$_temp0';
  }

  @override
  String agentDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Tagen',
      one: 'vor 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String agentWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Wochen',
      one: 'vor 1 Woche',
    );
    return '$_temp0';
  }

  @override
  String agentMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Monaten',
      one: 'vor 1 Monat',
    );
    return '$_temp0';
  }

  @override
  String agentYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Jahren',
      one: 'vor 1 Jahr',
    );
    return '$_temp0';
  }

  @override
  String get slideshowScreenCrossfade => 'Überblenden';

  @override
  String get slideshowScreenSlide => 'Schieben';

  @override
  String get slideshowScreenSlowZoom => 'Langsamer Zoom';

  @override
  String get slideshowScreenNone => 'Keiner';

  @override
  String get slideshowScreenSettings => 'Diashow-Einstellungen';

  @override
  String get slideshowScreenPace => 'Tempo';

  @override
  String get slideshowScreenTransition => 'Übergang';

  @override
  String get slideshowScreenShuffle => 'Zufällig';

  @override
  String get slideshowScreenLoop => 'Wiederholen';

  @override
  String get slideshowScreenDateAndPlace => 'Datum und Ort';

  @override
  String get slideshowScreenTheEnd => 'Ende.';

  @override
  String get slideshowScreenPrevious => 'Zurück';

  @override
  String get slideshowScreenPlay => 'Abspielen';

  @override
  String get slideshowScreenPause => 'Pause';

  @override
  String get slideshowScreenNext => 'Weiter';

  @override
  String get slideshowScreenClose => 'Schließen';

  @override
  String notificationsAlbumShared(String subject) {
    return '„$subject“ wurde mit dir geteilt';
  }

  @override
  String notificationsImportDone(String subject) {
    return 'Der Import aus $subject ist fertig';
  }

  @override
  String notificationsImportFailed(String subject) {
    return 'Der Import aus $subject ist fehlgeschlagen';
  }

  @override
  String notificationsDeviceQuiet(String subject) {
    return '$subject sichert nicht mehr';
  }

  @override
  String notificationsCopyForLate(String name) {
    return 'Die Kopie für $name ist seit drei Tagen nicht rausgegangen';
  }

  @override
  String notificationsCopyFromLate(String name) {
    return 'Die Kopie von $name ist seit drei Tagen nicht angekommen';
  }

  @override
  String notificationsBackupFailed(String subject) {
    return 'Eine Sicherung ist fehlgeschlagen: $subject';
  }

  @override
  String get notificationsTitle => 'Benachrichtigungen';

  @override
  String get notificationsNotRemoved => 'Das konnte nicht entfernt werden.';

  @override
  String get notificationsNotLoaded => 'Das konnte nicht geladen werden.';

  @override
  String get notificationsNone => 'Keine Benachrichtigungen.';

  @override
  String get notificationsRemove => 'Entfernen';

  @override
  String assetFactsNotSaved(String message) {
    return 'Nicht gespeichert. $message';
  }

  @override
  String get assetFactsEditDetails => 'Details bearbeiten';

  @override
  String get assetFactsDateAndTime => 'Datum und Uhrzeit';

  @override
  String get assetFactsFindPlace => 'Ort suchen';

  @override
  String get assetFactsLatitude => 'Breitengrad';

  @override
  String get assetFactsLongitude => 'Längengrad';

  @override
  String get assetFactsDescription => 'Beschreibung';

  @override
  String get assetFactsUseFile => 'Angaben aus der Datei verwenden';

  @override
  String get assetFactsCancel => 'Abbrechen';

  @override
  String get assetFactsSave => 'Speichern';

  @override
  String assetFactsStars(String stars) {
    return '$stars von 5 Sternen';
  }

  @override
  String get documentsScreenNotEnabled =>
      'Ein Administrator hat dieses Album nicht eingeschaltet.';

  @override
  String get documentsScreenNeedsAnalysis =>
      'Dafür muss die Bildanalyse eingeschaltet sein.';

  @override
  String get documentsScreenNoText => 'Noch keine Fotos mit Text.';

  @override
  String get documentsScreenLoadFailed =>
      'Dokumente konnten nicht geladen werden.';

  @override
  String get documentsScreenTitle => 'Dokumente';

  @override
  String get sharingNoPhotoAccess =>
      'Mediarr darf diesem Handy keine Fotos hinzufügen';

  @override
  String get backupNoDeviceKey =>
      'Der Server hat keinen Geräteschlüssel erstellt.';

  @override
  String get foldersScreenFolders => 'Ordner';

  @override
  String get foldersScreenLoadFailed =>
      'Der Ordner konnte nicht geladen werden.';

  @override
  String get foldersScreenNoExternalLibrary =>
      'Du hast keine externe Bibliothek. Ein Administrator richtet sie in den Einstellungen ein.';

  @override
  String get foldersScreenEmpty => 'Dieser Ordner ist leer.';

  @override
  String get searchQueryNoName => 'Ohne Namen';

  @override
  String get searchQueryVideos => 'Videos';

  @override
  String get searchQueryPhotos => 'Fotos';

  @override
  String searchQueryInAlbum(String title) {
    return 'Im Album: $title';
  }

  @override
  String get searchQueryInNoAlbum => 'In keinem Album';

  @override
  String get searchQueryFavourites => 'Favoriten';

  @override
  String get exploreScreenExplore => 'Entdecken';

  @override
  String get exploreScreenPeople => 'Personen';

  @override
  String get exploreScreenPlaces => 'Orte';

  @override
  String get exploreScreenMemories => 'Erinnerungen';

  @override
  String get exploreScreenPeopleFailed =>
      'Personen konnten nicht geladen werden.';

  @override
  String get exploreScreenNoNamedPeople => 'Noch keine Personen mit Namen.';

  @override
  String get exploreScreenPlacesFailed => 'Orte konnten nicht geladen werden.';

  @override
  String get exploreScreenNoPlaces => 'Noch keine Fotos mit Ort.';

  @override
  String get exploreScreenMemoriesFailed =>
      'Erinnerungen konnten nicht geladen werden.';

  @override
  String get exploreScreenNoMemories => 'Heute keine Erinnerungen.';

  @override
  String get exploreScreenAllPeople => 'Alle Personen';

  @override
  String get exploreScreenAllPlaces => 'Alle Orte';

  @override
  String get exploreScreenAllMemories => 'Alle Erinnerungen';

  @override
  String sharedScreenActionFailed(String reason) {
    return 'Die Aktion ist fehlgeschlagen. $reason';
  }

  @override
  String get sharedScreenWholeLibrary => 'Ganze Bibliothek';

  @override
  String sharedScreenFrom(String date) {
    return 'Ab $date';
  }

  @override
  String get sharedScreenLoadFailed =>
      'Das konnte nicht geladen werden. Prüfe die Verbindung.';

  @override
  String get sharedScreenTryAgain => 'Erneut versuchen';

  @override
  String get sharedScreenAlbumsWithMe => 'Mit mir geteilte Alben';

  @override
  String get sharedScreenNothingShared => 'Noch nichts geteilt.';

  @override
  String get sharedScreenLibrariesWithMe => 'Mit mir geteilte Bibliotheken';

  @override
  String get sharedScreenNobodyShares =>
      'Niemand teilt seine Bibliothek mit dir.';

  @override
  String get sharedScreenShowInMyMedia => 'In meinen Medien anzeigen';

  @override
  String get sharedScreenMyLibrarySharedWith =>
      'Meine Bibliothek ist geteilt mit';

  @override
  String get sharedScreenNobodyYet => 'Noch niemand.';

  @override
  String get sharedScreenStop => 'Beenden';

  @override
  String get sharedScreenUser => 'Benutzer';

  @override
  String get sharedScreenChooseDate => 'Datum wählen';

  @override
  String get sharedScreenNeverShared =>
      'Archiv, Papierkorb und Tresor werden nie geteilt.';

  @override
  String get sharedScreenShareMyLibrary => 'Meine Bibliothek teilen';

  @override
  String get sharedScreenShared => 'Geteilt';

  @override
  String get sharedScreenLibraryNotAvailable =>
      'Diese Bibliothek ist nicht verfügbar.';

  @override
  String get sharedScreenNoPhotos => 'Noch keine Fotos.';

  @override
  String get loginScreenEnterServerFirst =>
      'Gib zuerst die Adresse deines Servers ein.';

  @override
  String get loginScreenAllowOnCodeScreen =>
      'Erlaube diese Anmeldung auf dem Bildschirm, der den Code zeigt.';

  @override
  String get loginScreenCancel => 'Abbrechen';

  @override
  String get loginScreenEnterTotp =>
      'Gib den 6-stelligen Code aus deiner Authentifizierungs-App ein.';

  @override
  String get loginScreenSignInToServer =>
      'Melde dich bei deinem Mediarr-Server an.';

  @override
  String get loginScreenCode => 'Code';

  @override
  String get loginScreenServerAddress => 'Serveradresse';

  @override
  String get loginScreenEmail => 'E-Mail';

  @override
  String get loginScreenPassword => 'Passwort';

  @override
  String get loginScreenVerify => 'Bestätigen';

  @override
  String get loginScreenSignIn => 'Anmelden';

  @override
  String get loginScreenSingleSignOn => 'Single Sign-on verwenden';

  @override
  String get loginScreenScanQr => 'QR-Code scannen';

  @override
  String get loginScreenEnterSignInCode => 'Anmeldecode eingeben';

  @override
  String get loginScreenSignInCode => 'Anmeldecode';

  @override
  String get qrSignInScanTitle => 'Anmeldecode scannen';

  @override
  String get qrSignInScanHelp =>
      'Öffne auf einem Bildschirm, auf dem du angemeldet bist, das Kontomenü und wähle „Auf einem Handy anmelden“.';

  @override
  String get qrSignInLooking => 'Suche Server in diesem Netzwerk…';

  @override
  String get qrSignInNoneFound => 'Kein Server in diesem Netzwerk gefunden.';

  @override
  String get qrSignInOnThisNetwork => 'In diesem Netzwerk';

  @override
  String get qrSignInLookAgain => 'Erneut suchen';

  @override
  String get qrSignInMakeCodeFailed => 'Code konnte nicht erstellt werden.';

  @override
  String get qrSignInTheDevice => 'Gerät';

  @override
  String get qrSignInTitle => 'Anderes Gerät anmelden';

  @override
  String get qrSignInHowTo =>
      'Tippe in der Mediarr-App auf dem anderen Gerät auf dem Anmeldebildschirm auf „QR-Code scannen“.';

  @override
  String get qrSignInQrLabel => 'QR-Code zur Anmeldung';

  @override
  String get qrSignInOrType => 'Oder Code eingeben';

  @override
  String qrSignInValidFor(String time) {
    return 'Gültig für $time';
  }

  @override
  String qrSignInAllowOn(String device) {
    return 'Anmeldung erlauben: $device?';
  }

  @override
  String get qrSignInAllowOnlyIf =>
      'Erlaube es nur, wenn du den Code gerade auf deinem eigenen Gerät gescannt hast.';

  @override
  String get qrSignInDeny => 'Ablehnen';

  @override
  String get qrSignInAllow => 'Erlauben';

  @override
  String qrSignInSignedIn(String device) {
    return 'Angemeldet: $device. Es erscheint unter Konto → Geräte.';
  }

  @override
  String get qrSignInDone => 'Fertig';

  @override
  String get qrSignInDenied => 'Die Anmeldung wurde abgelehnt.';

  @override
  String get qrSignInExpired => 'Der Code ist abgelaufen.';

  @override
  String get qrSignInNewCode => 'Neuer Code';

  @override
  String get uploadScreenChoose =>
      'Wähle Fotos und Videos von diesem Gerät aus, um sie hochzuladen.';

  @override
  String get uploadScreenOpenLibrary => 'Fotomediathek öffnen';

  @override
  String get uploadScreenNeedsAccess =>
      'Mediarr braucht Zugriff auf deine Fotos. Erlaube ihn in den Einstellungen.';

  @override
  String get uploadScreenOpenSettings => 'Einstellungen öffnen';

  @override
  String get uploadScreenNoPhotos => 'Auf diesem Gerät gibt es keine Fotos.';

  @override
  String uploadScreenUploadCount(String count) {
    return '$count hochladen';
  }

  @override
  String get uploadScreenQueued => 'In Warteschlange';

  @override
  String get uploadScreenPreparing => 'Wird vorbereitet';

  @override
  String get uploadScreenUploaded => 'Hochgeladen';

  @override
  String get uploadScreenAlreadyOnServer => 'Schon auf dem Server';

  @override
  String get uploadScreenFailed => 'Fehlgeschlagen';

  @override
  String uploadScreenFinished(String done, String total) {
    return '$done von $total fertig';
  }

  @override
  String get uploadScreenClearFailed => 'Fehlgeschlagene entfernen';

  @override
  String get uploadScreenPhoto => 'Foto';

  @override
  String get backupCardNothingYet => 'Noch nichts gesichert.';

  @override
  String get backupCardLastJustNow => 'Letzte Datei gerade eben gesichert.';

  @override
  String backupCardLastMinutes(String minutes) {
    return 'Letzte Datei vor $minutes Min. gesichert.';
  }

  @override
  String backupCardLastHours(String hours) {
    return 'Letzte Datei vor $hours Std. gesichert.';
  }

  @override
  String backupCardLastDays(String days) {
    return 'Letzte Datei vor $days T. gesichert.';
  }

  @override
  String backupCardScopeTitle(String album) {
    return '„$album“ sichern';
  }

  @override
  String get backupCardScopeBody =>
      'Sollen Fotos, die schon in diesem Album sind, gesendet werden? Was schon auf dem Server ist, wird nie zweimal gesendet.';

  @override
  String get backupCardOnlyNew => 'Nur ab jetzt hinzugefügte Fotos';

  @override
  String get backupCardAlsoExisting => 'Auch die, die jetzt darin sind';

  @override
  String get backupCardTheAddedAlbums => 'die hinzugefügten Alben';

  @override
  String get backupCardNeedsFullAccess =>
      'Alben brauchen Zugriff auf alle Fotos. Erlaube ihn in den Einstellungen: Mediarr > Fotos > Voller Zugriff.';

  @override
  String backupCardServerUnreachable(String reason) {
    return 'Der Server ist nicht erreichbar. $reason';
  }

  @override
  String get backupCardAutomaticBackup => 'Automatische Sicherung';

  @override
  String backupCardAlbum(String name) {
    return 'Album: $name';
  }

  @override
  String get backupCardChange => 'Ändern';

  @override
  String get backupCardNeedsFullAccessNothingSent =>
      'Alben brauchen Zugriff auf alle Fotos. Erlaube ihn in den Einstellungen: Mediarr > Fotos > Voller Zugriff. Es wird nichts gesendet.';

  @override
  String get backupCardNoSuchAlbum =>
      'Kein Album mit diesem Namen auf dem Gerät. Es wird nichts gesendet.';

  @override
  String backupCardMoreAlbums(String more, String never) {
    return 'Weitere Alben: $more, nie gesendet: $never';
  }

  @override
  String get backupCardOnlyWifi => 'Nur im WLAN';

  @override
  String get backupCardOnlyCharging => 'Nur beim Laden';

  @override
  String backupCardVerified(String verified, String total) {
    return '$verified von $total auf dem Server bestätigt';
  }

  @override
  String backupCardCounts(String sending, String waiting, String failed) {
    return '$sending wird gesendet · $waiting wartet · $failed fehlgeschlagen';
  }

  @override
  String get backupCardPerDevice => 'Was der Server bestätigt, pro Gerät';

  @override
  String get backupCardRefused =>
      'Der Server hat dieses Gerät abgelehnt. Schalte die Sicherung aus und wieder ein.';

  @override
  String get backupCardFreeUpSpace => 'Speicher freigeben';

  @override
  String backupCardRetryFailed(String count) {
    return 'Die $count fehlgeschlagenen erneut versuchen';
  }

  @override
  String get backupCardOffHelp =>
      'Sendet ein Album deiner Wahl und sonst nichts. Sucht jede Minute nach neuen Fotos, solange die App offen ist. Ist sie geschlossen, entscheidet iOS wann, oft viel später, und stoppt es, wenn du die App wegwischst.';

  @override
  String get backupCardWhichAlbum => 'Welches Album?';

  @override
  String get backupCardAlbumName => 'Albumname';

  @override
  String backupCardUseName(String name) {
    return 'Den Namen „$name“ verwenden';
  }

  @override
  String get backupCardStartsWhenExists =>
      'Startet, sobald ein Album mit diesem Namen existiert';

  @override
  String get backupCardNoAlbums =>
      'Noch keine Alben auf diesem Gerät. Erstelle eines in Fotos.';

  @override
  String get backupCardNeverHelp =>
      'Ein Foto in einem „Nie“-Album wird nicht gesendet, auch wenn es zusätzlich in einem anderen Album ist.';

  @override
  String get backupCardNotAdded => 'Nicht hinzugefügt';

  @override
  String get backupCardBackUp => 'Sichern';

  @override
  String get backupCardNever => 'Nie';

  @override
  String get backupCardSave => 'Speichern';

  @override
  String get albumSheetsOwner => 'Eigentümer';

  @override
  String get albumSheetsEditor => 'Bearbeiter';

  @override
  String get albumSheetsContributor => 'Mitwirkender';

  @override
  String get albumSheetsViewer => 'Betrachter';

  @override
  String get albumSheetsUploadOnly => 'nur Hochladen';

  @override
  String get albumSheetsPassword => 'Passwort';

  @override
  String get albumSheetsWatermarkFact => 'Wasserzeichen';

  @override
  String albumSheetsExpiresFact(String date) {
    return 'läuft ab $date';
  }

  @override
  String albumSheetsDownloadsFact(String count) {
    return 'Downloads: $count';
  }

  @override
  String get albumSheetsActionFailed => 'Die Aktion ist fehlgeschlagen.';

  @override
  String get albumSheetsComments => 'Kommentare';

  @override
  String get albumSheetsCommentsAndHearts => 'Kommentare und Herzen';

  @override
  String get albumSheetsCommentsFailed =>
      'Kommentare konnten nicht geladen werden.';

  @override
  String get albumSheetsHeart => 'Herz';

  @override
  String get albumSheetsNoComments => 'Noch keine Kommentare.';

  @override
  String get albumSheetsDeleteComment => 'Kommentar löschen';

  @override
  String get albumSheetsComment => 'Kommentar';

  @override
  String get albumSheetsSend => 'Senden';

  @override
  String get albumSheetsAddToAlbum => 'Zum Album hinzufügen';

  @override
  String get albumSheetsAlbumsFailed => 'Alben konnten nicht geladen werden.';

  @override
  String get albumSheetsNewAlbum => 'Neues Album';

  @override
  String get albumSheetsCreateAndAdd => 'Erstellen und hinzufügen';

  @override
  String get albumSheetsShareWithUsers => 'Mit Benutzern teilen';

  @override
  String get albumSheetsSharingFailed =>
      'Freigaben konnten nicht geladen werden.';

  @override
  String get albumSheetsNotShared => 'Dieses Album ist noch nicht geteilt.';

  @override
  String get albumSheetsRemove => 'Entfernen';

  @override
  String get albumSheetsNoOtherUsers =>
      'Auf diesem Server gibt es keine anderen Benutzer.';

  @override
  String get albumSheetsUser => 'Benutzer';

  @override
  String get albumSheetsRole => 'Rolle';

  @override
  String get albumSheetsAdd => 'Hinzufügen';

  @override
  String get albumSheetsPublicLinks => 'Öffentliche Links';

  @override
  String get albumSheetsCopyNow =>
      'Kopiere die Adresse jetzt: Sie kann später nicht mehr angezeigt werden.';

  @override
  String get albumSheetsCopy => 'Kopieren';

  @override
  String get albumSheetsLinksFailed => 'Links konnten nicht geladen werden.';

  @override
  String get albumSheetsUnnamedLink => 'Unbenannter Link';

  @override
  String get albumSheetsRevoke => 'Widerrufen';

  @override
  String get albumSheetsName => 'Name';

  @override
  String get albumSheetsPasswordOptional => 'Passwort (optional)';

  @override
  String get albumSheetsNoExpiry => 'Kein Ablauf';

  @override
  String albumSheetsExpires(String date) {
    return 'Läuft ab $date';
  }

  @override
  String get albumSheetsChoose => 'Auswählen';

  @override
  String get albumSheetsDownloadLimit => 'Download-Limit';

  @override
  String get albumSheetsWatermark => 'Wasserzeichen';

  @override
  String get albumSheetsWatermarkHelp =>
      'Ein Wasserzeichen schaltet Downloads der Originale und die Videowiedergabe aus.';

  @override
  String get albumSheetsAllowDownloads => 'Downloads erlauben';

  @override
  String get albumSheetsShowLocation => 'Ort anzeigen';

  @override
  String get albumSheetsGuestsCanAdd => 'Gäste können Fotos hinzufügen';

  @override
  String get albumSheetsUploadOnlyLong =>
      'Nur Hochladen (Gäste sehen das Album nicht)';

  @override
  String get albumSheetsCreateLink => 'Link erstellen';

  @override
  String get albumSheetsFromAnyDate => 'Ab beliebigem Datum';

  @override
  String albumSheetsFrom(String date) {
    return 'Ab $date';
  }

  @override
  String get albumSheetsToAnyDate => 'Bis beliebigem Datum';

  @override
  String albumSheetsTo(String date) {
    return 'Bis $date';
  }

  @override
  String get albumSheetsKind => 'Art';

  @override
  String get albumSheetsAll => 'Alle';

  @override
  String get albumSheetsPhotos => 'Fotos';

  @override
  String get albumSheetsVideos => 'Videos';

  @override
  String get albumSheetsLivePhoto => 'Live Photo';

  @override
  String get albumSheetsCamera => 'Kamera';

  @override
  String get albumSheetsPerson => 'Person';

  @override
  String get albumSheetsTag => 'Schlagwort';

  @override
  String get albumSheetsPlace => 'Ort';

  @override
  String get viewerScreenDeleteTitle => 'Dieses Foto löschen?';

  @override
  String get viewerScreenTrashNoDays =>
      'Es kommt in den Papierkorb, wo es wiederhergestellt werden kann.';

  @override
  String viewerScreenTrashDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tage',
      one: '$days Tag',
    );
    return 'Es kommt in den Papierkorb, wo es $_temp0 bleibt und wiederhergestellt werden kann.';
  }

  @override
  String get viewerScreenCancel => 'Abbrechen';

  @override
  String get viewerScreenDelete => 'Löschen';

  @override
  String get viewerScreenActionFailed => 'Die Aktion ist fehlgeschlagen.';

  @override
  String get viewerScreenNoVideo => 'Dieses Foto hat kein Video.';

  @override
  String get viewerScreenVideoFailed =>
      'Das Video konnte nicht geladen werden.';

  @override
  String get viewerScreenStackShots => 'Aufnahmen in diesem Stapel';

  @override
  String get viewerScreenSlideshow => 'Diashow';

  @override
  String get viewerScreen360View => '360°-Ansicht';

  @override
  String get viewerScreenFlatView => 'Flache Ansicht';

  @override
  String get viewerScreenPlayLive => 'Live Photo abspielen';

  @override
  String get viewerScreenCommentsAndHearts => 'Kommentare und Herzen';

  @override
  String get viewerScreenFavorite => 'Favorit';

  @override
  String get viewerScreenEdit => 'Bearbeiten';

  @override
  String get viewerScreenShare => 'Teilen';

  @override
  String get viewerScreenDetails => 'Details';

  @override
  String get viewerScreenPhotoFailed =>
      'Dieses Foto konnte nicht geladen werden.';

  @override
  String get viewerScreenCannotPlay =>
      'Dieses Video kann auf diesem Gerät nicht abgespielt werden.';

  @override
  String get viewerScreenDetailsFailed =>
      'Die Details konnten nicht geladen werden.';

  @override
  String get viewerScreenUnavailable => 'Nicht verfügbar';

  @override
  String get viewerScreenMissingFile =>
      'Die Datei wurde beim letzten Scan der externen Bibliothek nicht gefunden. Das Original ist wieder verfügbar, sobald die Datei zurück ist.';

  @override
  String get viewerScreenName => 'Name';

  @override
  String get viewerScreenDescription => 'Beschreibung';

  @override
  String get viewerScreenTaken => 'Aufgenommen';

  @override
  String get viewerScreenAdded => 'Hinzugefügt';

  @override
  String get viewerScreenDimensions => 'Abmessungen';

  @override
  String get viewerScreenSize => 'Größe';

  @override
  String get viewerScreenDuration => 'Dauer';

  @override
  String get viewerScreenCamera => 'Kamera';

  @override
  String get viewerScreenLens => 'Objektiv';

  @override
  String get viewerScreenSettings => 'Einstellungen';

  @override
  String get viewerScreenLocation => 'Ort';

  @override
  String viewerScreenNotSaved(String reason) {
    return 'Nicht gespeichert. $reason';
  }

  @override
  String get viewerScreenEditDetails => 'Details bearbeiten';

  @override
  String get libraryScreenTitle => 'Bibliothek';

  @override
  String get libraryScreenExplore => 'Entdecken';

  @override
  String get libraryScreenShared => 'Geteilt';

  @override
  String albumScreenActionFailed(String message) {
    return 'Die Aktion ist fehlgeschlagen. $message';
  }

  @override
  String albumScreenRemovedAll(String count) {
    return 'Aus dem Album entfernt: $count';
  }

  @override
  String albumScreenRemovedSome(String changed, String total) {
    return 'Entfernt: $changed von $total. Du kannst nur Fotos entfernen, die du selbst hinzugefügt hast.';
  }

  @override
  String get albumScreenCoverSet => 'Das Titelbild ist festgelegt.';

  @override
  String get albumScreenCancel => 'Abbrechen';

  @override
  String get albumScreenMoveTitle => 'Album verschieben';

  @override
  String get albumScreenMoveTop => 'Ganz oben, zwischen allen Alben';

  @override
  String get albumScreenMoved => 'Das Album wurde verschoben.';

  @override
  String get albumScreenUploadToAlbum => 'In Album hochladen';

  @override
  String get albumScreenDeleteTitle => 'Dieses Album löschen?';

  @override
  String get albumScreenDeleteBody =>
      'Die Fotos bleiben in der Bibliothek. Öffentliche Links funktionieren nicht mehr.';

  @override
  String get albumScreenDeleteBodyInside =>
      'Die Fotos bleiben in der Bibliothek. Öffentliche Links funktionieren nicht mehr. Die Alben darin werden nach ganz oben verschoben.';

  @override
  String get albumScreenDelete => 'Löschen';

  @override
  String get albumScreenLeaveTitle => 'Dieses Album verlassen?';

  @override
  String get albumScreenLeaveBody =>
      'Du siehst es nicht mehr, außer der Besitzer teilt es erneut.';

  @override
  String get albumScreenLeave => 'Verlassen';

  @override
  String get albumScreenClearSelection => 'Auswahl aufheben';

  @override
  String get albumScreenShare => 'Teilen';

  @override
  String get albumScreenSetAsCover => 'Als Titelbild festlegen';

  @override
  String get albumScreenRemoveFromAlbum => 'Aus Album entfernen';

  @override
  String get albumScreenSearchInAlbum => 'Im Album suchen';

  @override
  String get albumScreenComments => 'Kommentare';

  @override
  String get albumScreenMore => 'Mehr';

  @override
  String get albumScreenSlideshow => 'Diashow';

  @override
  String get albumScreenAddFromLibrary => 'Aus Bibliothek hinzufügen';

  @override
  String get albumScreenUploadFromPhone => 'Von diesem Telefon hochladen';

  @override
  String get albumScreenAlbumInside => 'Album darin';

  @override
  String get albumScreenMoveTo => 'Verschieben nach…';

  @override
  String get albumScreenShareWithUsers => 'Mit Benutzern teilen';

  @override
  String get albumScreenPublicLinks => 'Öffentliche Links';

  @override
  String get albumScreenEdit => 'Bearbeiten';

  @override
  String get albumScreenNotAvailable => 'Dieses Album ist nicht verfügbar.';

  @override
  String get albumScreenNoMatch => 'Keine Fotos entsprechen den Regeln.';

  @override
  String get albumScreenEmptyCanAdd =>
      'Dieses Album ist leer. Füge Fotos über das Menü hinzu.';

  @override
  String get albumScreenEmpty => 'Dieses Album ist leer.';

  @override
  String get albumScreenAlbumsInside => 'Alben darin';

  @override
  String get albumScreenNewAlbumInside => 'Neues Album darin';

  @override
  String get albumScreenName => 'Name';

  @override
  String get albumScreenCreate => 'Erstellen';

  @override
  String albumScreenAdded(String count) {
    return 'Hinzugefügt: $count';
  }

  @override
  String get albumScreenChoosePhotos => 'Fotos auswählen';

  @override
  String get albumScreenAdd => 'Hinzufügen';

  @override
  String get albumScreenNoPhotosYet => 'Noch keine Fotos.';

  @override
  String get albumScreenNotSaved => 'Das Album wurde nicht gespeichert.';

  @override
  String get albumScreenEditAlbum => 'Album bearbeiten';

  @override
  String get albumScreenDescription => 'Beschreibung';

  @override
  String get albumScreenOrder => 'Reihenfolge';

  @override
  String get albumScreenNewestFirst => 'Neueste zuerst';

  @override
  String get albumScreenOldestFirst => 'Älteste zuerst';

  @override
  String get albumScreenSave => 'Speichern';

  @override
  String get peopleScreensNoName => 'Kein Name';

  @override
  String get peopleScreensSearchFailed =>
      'Die Suche ist fehlgeschlagen. Prüfe die Verbindung.';

  @override
  String get peopleScreensDescribe =>
      'Beschreibe, was du suchst, auf Englisch oder Kroatisch, oder wähle Filter.';

  @override
  String get peopleScreensSmartOff =>
      'Die intelligente Suche ist aus oder nicht verfügbar, daher werden nur Text auf Bildern, Dateinamen und Filter durchsucht.';

  @override
  String peopleScreensRemoveChip(String label) {
    return '$label entfernen';
  }

  @override
  String get peopleScreensNothingFound => 'Nichts gefunden.';

  @override
  String get peopleScreensSearchHint => 'Hund am Strand, Hvar 2024, Quittung…';

  @override
  String get peopleScreensAsk => 'Fragen';

  @override
  String get peopleScreensFilters => 'Filter';

  @override
  String get peopleScreensSearch => 'Suchen';

  @override
  String get peopleScreensLoadFailed =>
      'Personen konnten nicht geladen werden. Prüfe die Verbindung.';

  @override
  String get peopleScreensFacesOff =>
      'Die Gesichtserkennung ist auf diesem Server nicht eingeschaltet.';

  @override
  String get peopleScreensNoneYet => 'Noch keine Personen erkannt.';

  @override
  String get peopleScreensPeople => 'Personen';

  @override
  String get peopleScreensShowOthers => 'Die anderen zeigen';

  @override
  String get peopleScreensHiddenPeople => 'Ausgeblendete Personen';

  @override
  String get peopleScreensName => 'Name';

  @override
  String get peopleScreensDateOfBirth => 'Geburtsdatum';

  @override
  String get peopleScreensMergeWith => 'Zusammenführen mit…';

  @override
  String get peopleScreensNobodyElse => 'Es gibt sonst niemanden.';

  @override
  String get peopleScreensMerged => 'Zusammengeführt.';

  @override
  String peopleScreensBorn(String date) {
    return 'Geboren $date';
  }

  @override
  String get peopleScreensShow => 'Zeigen';

  @override
  String get peopleScreensHide => 'Ausblenden';

  @override
  String get peopleScreensThisLoadFailed =>
      'Das konnte nicht geladen werden. Prüfe die Verbindung.';

  @override
  String get adminServerSettingsTrashDaysProblem =>
      'Der Papierkorb behält Fotos 1 bis 3650 Tage.';

  @override
  String get adminServerSettingsImageQualityProblem =>
      'Die Bildqualität muss zwischen 40 und 100 liegen.';

  @override
  String get adminServerSettingsPreviewSizeProblem =>
      'Die Vorschaugröße muss zwischen 720 und 4096 liegen.';

  @override
  String get adminServerSettingsVideoQualityProblem =>
      'Die Videoqualität muss zwischen 18 und 40 liegen, niedriger ist besser.';

  @override
  String get adminServerSettingsVideoHeightProblem =>
      'Das größte Video muss 720, 1080, 1440 oder 2160 sein.';

  @override
  String get adminServerSettingsFaceScoreProblem =>
      'Wie sicher ein Gesicht sein muss, liegt zwischen 0,1 und 1.';

  @override
  String get adminServerSettingsFaceDistanceProblem =>
      'Wie ähnlich zwei Gesichter sein müssen, liegt zwischen 0,1 und 2.';

  @override
  String get adminServerSettingsJobsProblem =>
      'Hintergrundaufgaben müssen zwischen 0 und 64 liegen.';

  @override
  String get adminServerSettingsWorkersProblem =>
      'Video- und Analyseaufgaben müssen zwischen 1 und 16 liegen.';

  @override
  String get adminServerSettingsScanProblem =>
      'Das Scanintervall muss zwischen 1 und 720 Stunden liegen.';

  @override
  String get adminServerSettingsMessageProblem =>
      'Die Anmeldenachricht ist zu lang.';

  @override
  String get adminServerSettingsNeedNumbers =>
      'Jedes Zahlenfeld braucht eine Zahl.';

  @override
  String get adminServerSettingsSaved => 'Die Einstellungen sind gespeichert.';

  @override
  String get adminServerSettingsTitle => 'Server-Einstellungen';

  @override
  String get adminServerSettingsTrash => 'Papierkorb';

  @override
  String get adminServerSettingsTrashDays =>
      'Tage, die Fotos im Papierkorb bleiben';

  @override
  String adminServerSettingsRange(String low, String high) {
    return '$low bis $high';
  }

  @override
  String get adminServerSettingsPicturesAndVideos => 'Bilder und Videos';

  @override
  String get adminServerSettingsImageQuality => 'Bildqualität';

  @override
  String get adminServerSettingsPreviewSize => 'Vorschaugröße in Pixeln';

  @override
  String get adminServerSettingsVideoQuality => 'Videoqualität';

  @override
  String get adminServerSettingsVideoQualityHelp =>
      '18 bis 40, niedriger ist besser und größer';

  @override
  String get adminServerSettingsLargestVideo => 'Größtes Video';

  @override
  String get adminServerSettingsFaces => 'Gesichter';

  @override
  String get adminServerSettingsFaceScore => 'Wie sicher ein Gesicht sein muss';

  @override
  String get adminServerSettingsFaceDistance =>
      'Wie ähnlich zwei Gesichter sein müssen, um eine Person zu sein';

  @override
  String get adminServerSettingsBackgroundJobs => 'Hintergrundaufgaben';

  @override
  String get adminServerSettingsJobsAtOnce => 'Aufgaben gleichzeitig';

  @override
  String get adminServerSettingsJobsAtOnceHelp =>
      '0 nutzt WORKER_CONCURRENCY; gilt nach dem Neustart des Workers';

  @override
  String get adminServerSettingsVideosAtOnce => 'Videos gleichzeitig';

  @override
  String get adminServerSettingsWorkersHelp =>
      '1 bis 16; gilt nach dem Neustart des Workers';

  @override
  String get adminServerSettingsAnalysesAtOnce => 'Analysen gleichzeitig';

  @override
  String get adminServerSettingsScanHours =>
      'Externe Ordner alle … Stunden scannen';

  @override
  String get adminServerSettingsSigningIn => 'Anmeldung';

  @override
  String get adminServerSettingsPasswordLogin =>
      'Anmeldung mit Passwort erlauben';

  @override
  String get adminServerSettingsMaintenance => 'Wartungsmodus';

  @override
  String get adminServerSettingsMaintenanceHelp =>
      'Nur Administratoren können den Server nutzen';

  @override
  String get adminServerSettingsVisibleOnNetwork =>
      'Apps im selben Netzwerk können diesen Server finden';

  @override
  String get adminServerSettingsVisibleOnNetworkHelp =>
      'Für die Anmeldung braucht es weiterhin ein Konto.';

  @override
  String get adminServerSettingsServerName => 'Name des Servers';

  @override
  String get adminServerSettingsLoginMessage =>
      'Nachricht auf der Anmeldeseite';

  @override
  String get adminOverviewTitle => 'Übersicht';

  @override
  String get adminOverviewLibrary => 'Bibliothek';

  @override
  String get adminOverviewUsers => 'Benutzer';

  @override
  String get adminOverviewPhotos => 'Fotos';

  @override
  String get adminOverviewVideos => 'Videos';

  @override
  String get adminOverviewProcessing => 'In Bearbeitung';

  @override
  String get adminOverviewFailed => 'Fehlgeschlagen';

  @override
  String get adminOverviewLibrarySize => 'Größe der Bibliothek';

  @override
  String get adminOverviewDisk => 'Festplatte';

  @override
  String get adminOverviewFree => 'Frei';

  @override
  String get adminOverviewTotal => 'Gesamt';

  @override
  String get adminOverviewJobs => 'Aufgaben';

  @override
  String get adminOverviewWaiting => 'Wartend';

  @override
  String get adminOverviewRunning => 'Läuft';

  @override
  String get adminOverviewDone => 'Erledigt';

  @override
  String get adminOverviewServices => 'Dienste';

  @override
  String get adminOverviewWorker => 'Worker';

  @override
  String get adminOverviewNotRunning => 'Läuft nicht';

  @override
  String get adminOverviewAnalysis => 'Analyse (ML)';

  @override
  String get adminOverviewTurnedOff => 'Ausgeschaltet';

  @override
  String get adminOverviewDatabaseSize => 'Datenbankgröße';

  @override
  String get adminOverviewVersions => 'Versionen';

  @override
  String get adminOverviewDatabase => 'Datenbank';

  @override
  String get adminJobsTitle => 'Aufgaben';

  @override
  String get adminJobsQueues => 'Warteschlangen';

  @override
  String adminJobsQueueState(String queued, String running) {
    return '$queued wartend · $running laufend';
  }

  @override
  String adminJobsQueueStatePaused(String queued, String running) {
    return '$queued wartend · $running laufend · pausiert';
  }

  @override
  String adminJobsContinues(String name) {
    return '$name läuft weiter.';
  }

  @override
  String adminJobsIsPaused(String name) {
    return '$name ist pausiert.';
  }

  @override
  String get adminJobsResume => 'Fortsetzen';

  @override
  String get adminJobsPause => 'Pausieren';

  @override
  String get adminJobsFailed => 'Fehlgeschlagen';

  @override
  String get adminJobsNoneFailed => 'Keine Aufgabe ist fehlgeschlagen.';

  @override
  String get adminJobsQueuedAgain => 'Die Aufgabe ist wieder eingereiht.';

  @override
  String get adminJobsTryAgain => 'Erneut versuchen';

  @override
  String get freeSpaceScreenServerUnreachable =>
      'Der Server konnte nicht gefragt werden, daher wird nichts zum Entfernen angeboten.';

  @override
  String get freeSpaceScreenBackupUnreadable =>
      'Der Sicherungsstatus konnte nicht gelesen werden.';

  @override
  String freeSpaceScreenRemoveTitle(String count) {
    return '$count von diesem Telefon entfernen?';
  }

  @override
  String get freeSpaceScreenRemoveBody =>
      'Sie bleiben auf deinem Server. Das iPhone fragt noch einmal und behält sie 30 Tage unter „Zuletzt gelöscht“.';

  @override
  String get freeSpaceScreenCancel => 'Abbrechen';

  @override
  String get freeSpaceScreenRemove => 'Entfernen';

  @override
  String get freeSpaceScreenNotRemoved =>
      'Die Fotos konnten nicht entfernt werden.';

  @override
  String get freeSpaceScreenNothingToRemove =>
      'Nichts zu entfernen. Hier werden nur Fotos angeboten, die die automatische Sicherung gesendet hat.';

  @override
  String freeSpaceScreenSafe(String count) {
    return '$count sind sicher auf deinem Server, wie er gerade anhand ihrer Prüfsummen bestätigt hat.';
  }

  @override
  String freeSpaceScreenRemoveButton(String count) {
    return '$count von diesem Telefon entfernen';
  }

  @override
  String get freeSpaceScreenTitle => 'Speicher freigeben';

  @override
  String get freeSpaceScreenWhatToKeep => 'Was behalten';

  @override
  String get freeSpaceScreenAnyAge => 'Beliebiges Alter';

  @override
  String get freeSpaceScreenOlderThanMonth => 'Älter als einen Monat';

  @override
  String get freeSpaceScreenOlderThan3Months => 'Älter als 3 Monate';

  @override
  String get freeSpaceScreenOlderThanYear => 'Älter als ein Jahr';

  @override
  String get freeSpaceScreenRemoveOnly => 'Nur entfernen';

  @override
  String get freeSpaceScreenKeepFavorites => 'Favoriten behalten';

  @override
  String get freeSpaceScreenKeepPhotos => 'Alle Fotos behalten';

  @override
  String get freeSpaceScreenKeepVideos => 'Alle Videos behalten';

  @override
  String get freeSpaceScreenKeepAlbums =>
      'Diese Alben auf dem Telefon behalten';

  @override
  String get apiKeysScreenRead => 'Lesen';

  @override
  String get apiKeysScreenUpload => 'Hochladen';

  @override
  String get apiKeysScreenChangeAndDelete => 'Ändern und löschen';

  @override
  String apiKeysScreenExpires(String rights, String date) {
    return '$rights · läuft ab am $date';
  }

  @override
  String get apiKeysScreenNewKey => 'Neuer Schlüssel';

  @override
  String get apiKeysScreenKeyName => 'Name des Schlüssels';

  @override
  String get apiKeysScreenCancel => 'Abbrechen';

  @override
  String get apiKeysScreenCreate => 'Erstellen';

  @override
  String apiKeysScreenCreateFailed(String message) {
    return 'Der Schlüssel konnte nicht erstellt werden. $message';
  }

  @override
  String get apiKeysScreenSaveItNow => 'Jetzt speichern';

  @override
  String get apiKeysScreenCopy => 'Kopieren';

  @override
  String get apiKeysScreenDone => 'Fertig';

  @override
  String get apiKeysScreenRevokeFailed =>
      'Der Schlüssel konnte nicht widerrufen werden.';

  @override
  String get apiKeysScreenTitle => 'API-Schlüssel';

  @override
  String get apiKeysScreenLoadFailed =>
      'Die Schlüssel konnten nicht geladen werden.';

  @override
  String get apiKeysScreenEmpty =>
      'Noch keine Schlüssel. Ein Schlüssel gibt einem Programm nur die gewählten Rechte.';

  @override
  String get apiKeysScreenRevoke => 'Widerrufen';

  @override
  String get memoriesScreenLastWeek => 'Die letzte Woche';

  @override
  String memoriesScreenOnThisDay(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: 'An diesem Tag, vor $years Jahren',
      one: 'An diesem Tag, vor $years Jahr',
    );
    return '$_temp0';
  }

  @override
  String get memoriesScreenLoadFailed =>
      'Erinnerungen konnten nicht geladen werden. Prüfe die Verbindung.';

  @override
  String get memoriesScreenTryAgain => 'Erneut versuchen';

  @override
  String get memoriesScreenNoneYet => 'Noch keine Erinnerungen.';

  @override
  String memoriesScreenItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Elemente',
      one: '$count Element',
    );
    return '$_temp0';
  }

  @override
  String get memoriesScreenTitle => 'Erinnerungen';

  @override
  String get memoriesScreenVideoFailed =>
      'Das Video konnte nicht erstellt werden.';

  @override
  String get memoriesScreenVideoSaved =>
      'Das Video ist in deinen Fotos gespeichert.';

  @override
  String get memoriesScreenVideoNotSaved =>
      'Das Video konnte nicht gespeichert werden.';

  @override
  String get memoriesScreenMakeVideo => 'Video erstellen';

  @override
  String get layoutJanuary => 'Januar';

  @override
  String get layoutJanuaryOf => 'Januar';

  @override
  String get layoutFebruary => 'Februar';

  @override
  String get layoutFebruaryOf => 'Februar';

  @override
  String get layoutMarch => 'März';

  @override
  String get layoutMarchOf => 'März';

  @override
  String get layoutApril => 'April';

  @override
  String get layoutAprilOf => 'April';

  @override
  String get layoutMay => 'Mai';

  @override
  String get layoutMayOf => 'Mai';

  @override
  String get layoutJune => 'Juni';

  @override
  String get layoutJuneOf => 'Juni';

  @override
  String get layoutJuly => 'Juli';

  @override
  String get layoutJulyOf => 'Juli';

  @override
  String get layoutAugust => 'August';

  @override
  String get layoutAugustOf => 'August';

  @override
  String get layoutSeptember => 'September';

  @override
  String get layoutSeptemberOf => 'September';

  @override
  String get layoutOctober => 'Oktober';

  @override
  String get layoutOctoberOf => 'Oktober';

  @override
  String get layoutNovember => 'November';

  @override
  String get layoutNovemberOf => 'November';

  @override
  String get layoutDecember => 'Dezember';

  @override
  String get layoutDecemberOf => 'Dezember';

  @override
  String get layoutWeekdayMon => 'Mo';

  @override
  String get layoutWeekdayTue => 'Di';

  @override
  String get layoutWeekdayWed => 'Mi';

  @override
  String get layoutWeekdayThu => 'Do';

  @override
  String get layoutWeekdayFri => 'Fr';

  @override
  String get layoutWeekdaySat => 'Sa';

  @override
  String get layoutWeekdaySun => 'So';

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
  String get linkPrivacyHideFaces => 'Gesichter verbergen';

  @override
  String get linkPrivacyFacesNone => 'Keine';

  @override
  String get linkPrivacyFacesAll => 'Alle Gesichter';

  @override
  String get linkPrivacyFacesExcept => 'Alle außer ausgewählten Personen';

  @override
  String get linkPrivacyChoosePeople =>
      'Die Gesichter dieser Personen bleiben sichtbar:';

  @override
  String get linkPrivacyNoPeople =>
      'Noch hat niemand einen Namen. Benenne zuerst Personen unter Personen.';

  @override
  String get linkPrivacyPeopleFailed =>
      'Personen konnten nicht geladen werden.';

  @override
  String get linkPrivacyUnrecognized =>
      'Ein nicht erkanntes Gesicht wird nicht verwischt.';

  @override
  String linkPrivacyUnchecked(String count, String total) {
    return '$count von $total Fotos wurden noch nicht auf Gesichter geprüft, daher wird in ihnen nichts verwischt.';
  }

  @override
  String get linkPrivacyAllChecked =>
      'Alle Fotos im Album wurden auf Gesichter geprüft.';

  @override
  String linkPrivacyVideosStill(String count) {
    return 'Videos ($count) werden nur als Standbild mit verwischten Gesichtern gezeigt.';
  }

  @override
  String get linkPrivacyNoOriginals =>
      'Besucher erhalten eine verwischte Kopie in voller Größe, nie das Original.';

  @override
  String get linkPrivacyRemoveCamera => 'Kameradetails entfernen';

  @override
  String get linkPrivacyRemoveCameraDetail =>
      'Downloads enthalten weder Kamera, Objektiv, Seriennummern, Urheber noch Software.';

  @override
  String get linkPrivacyRemoveDate => 'Auch das Datum entfernen';

  @override
  String get linkPrivacyAskName => 'Nach einem Namen fragen';

  @override
  String get linkPrivacyAskNameDetail =>
      'Besucher geben ihren Namen ein, bevor sie das Album sehen.';

  @override
  String get linkPrivacyNotOpened => 'Noch nicht geöffnet';

  @override
  String linkPrivacyOpened(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-mal geöffnet',
      one: 'Einmal geöffnet',
    );
    return '$_temp0 · zuletzt $when';
  }

  @override
  String get linkPrivacyWhoOpened => 'Wer ihn geöffnet hat';

  @override
  String get linkPrivacyNoVisits => 'Diesen Link hat noch niemand geöffnet.';

  @override
  String get linkPrivacyVisitsFailed =>
      'Die Besuche konnten nicht geladen werden.';

  @override
  String get linkPrivacyUnknownPlace => 'Unbekannter Ort';

  @override
  String get linkPrivacyNoName => 'Kein Name angegeben';

  @override
  String linkPrivacyViewed(String count) {
    return '$count angesehen';
  }

  @override
  String linkPrivacyDownloaded(String count) {
    return '$count heruntergeladen';
  }

  @override
  String get linkPrivacyAttribution =>
      'Orte von DB-IP (db-ip.com), CC BY 4.0. Besuche werden 90 Tage aufbewahrt.';

  @override
  String get sharePrivacyRemoveLocation => 'Ort entfernen';

  @override
  String get sharePrivacyRemoveCamera => 'Kameradetails entfernen';

  @override
  String get sharePrivacyHideFaces => 'Gesichter verbergen';

  @override
  String get sharePrivacyHideFacesDetail =>
      'Fotos werden als verwischte Kopie gesendet. Videos werden ausgelassen.';

  @override
  String get sharePrivacyVideosLeftOut =>
      'Videos wurden ausgelassen: Ihre Gesichter lassen sich nicht verbergen.';

  @override
  String notificationsLinkOpened(String subject) {
    return 'Dein Link „$subject“ wurde zum ersten Mal geöffnet.';
  }

  @override
  String get cullTitle => 'Auswahl';

  @override
  String get cullMark => 'Markierung';

  @override
  String get cullPick => 'Behalten';

  @override
  String get cullReject => 'Verwerfen';

  @override
  String get cullNoMark => 'Keine Markierung';

  @override
  String get cullPicks => 'Behaltene';

  @override
  String get cullRejects => 'Verworfene';

  @override
  String get cullUnmarked => 'Ohne Markierung';

  @override
  String get cullAddToCompare => 'Vergleichen';

  @override
  String get cullRemoveFromCompare => 'Aus dem Vergleich nehmen';

  @override
  String get cullStopComparing => 'Vergleich beenden';

  @override
  String get cullPicksToAlbum => 'Behaltene in neues Album';

  @override
  String get cullRejectsToTrash => 'Verworfene in den Papierkorb';

  @override
  String get cullNothing => 'Hier gibt es keine eigenen Fotos zum Auswählen.';

  @override
  String get cullNoneWithMark => 'Kein Foto hat diese Markierung.';

  @override
  String get cullNotSaved => 'Nicht gespeichert';

  @override
  String get cullActionFailed => 'Die Aktion ist fehlgeschlagen';

  @override
  String get cullLoadFailed => 'Die Markierungen konnten nicht geladen werden.';

  @override
  String get cullAlbumName => 'Name';

  @override
  String get cullCreateAlbum => 'Erstellen';

  @override
  String cullTally(int picks, int rejects) {
    return 'Behalten: $picks · Verworfen: $rejects';
  }

  @override
  String cullConfirmTrash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count verworfene Fotos kommen in den Papierkorb und können wiederhergestellt werden.',
      one: '1 verworfenes Foto kommt in den Papierkorb und kann wiederhergestellt werden.',
    );
    return '$_temp0';
  }

  @override
  String cullMovedToTrash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fotos in den Papierkorb verschoben',
      one: '1 Foto in den Papierkorb verschoben',
    );
    return '$_temp0';
  }

  @override
  String cullAlbumMade(int count, String title) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fotos sind im Album $title',
      one: '1 Foto ist im Album $title',
    );
    return '$_temp0';
  }

  @override
  String cullAlbumWillHold(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Das Album enthält $count behaltene Fotos.',
      one: 'Das Album enthält 1 behaltenes Foto.',
    );
    return '$_temp0';
  }

  @override
  String get adminMlTitle => 'Analysedienst';

  @override
  String get adminMlConnected => 'Verbunden';

  @override
  String get adminMlLoaded => 'Geladene Modelle';

  @override
  String get adminMlMemory => 'Speicher';

  @override
  String get adminMlAcceleration => 'Beschleunigung';

  @override
  String get adminMlNoneLoaded => 'Gerade keines';

  @override
  String get adminMlState => 'Status';

  @override
  String get adminMlUnreachable =>
      'Nicht erreichbar. Die Analyse wartet und läuft weiter, sobald der Dienst zurück ist; bis dahin sucht die Suche in Text auf Bildern und Dateinamen.';

  @override
  String get adminMlWrongToken =>
      'Der Dienst hat das Token abgelehnt. ML_TOKEN muss in der .env hier und auf dem Rechner des Dienstes gleich sein.';

  @override
  String memoriesTripTitle(String place, String monthName, String year) {
    return '$place, $monthName $year';
  }

  @override
  String get memoriesMonth1 => 'Januar';

  @override
  String get memoriesMonth2 => 'Februar';

  @override
  String get memoriesMonth3 => 'März';

  @override
  String get memoriesMonth4 => 'April';

  @override
  String get memoriesMonth5 => 'Mai';

  @override
  String get memoriesMonth6 => 'Juni';

  @override
  String get memoriesMonth7 => 'Juli';

  @override
  String get memoriesMonth8 => 'August';

  @override
  String get memoriesMonth9 => 'September';

  @override
  String get memoriesMonth10 => 'Oktober';

  @override
  String get memoriesMonth11 => 'November';

  @override
  String get memoriesMonth12 => 'Dezember';

  @override
  String memoriesPersonYears(String person) {
    return '$person im Lauf der Jahre';
  }

  @override
  String memoriesBirthday(String person) {
    return 'Geburtstag: $person';
  }

  @override
  String memoriesYearReview(String year) {
    return '$year in Fotos';
  }

  @override
  String get memoriesMonthAgo => 'Vor einem Monat';

  @override
  String get memoriesHidden => 'Diese Erinnerung ist ausgeblendet.';

  @override
  String get memoriesPersonHidden =>
      'Diese Person erscheint nicht mehr in Erinnerungen.';

  @override
  String get memoriesHideThis => 'Diese Erinnerung ausblenden';

  @override
  String get memoriesHidePerson => 'Diese Person nicht anzeigen';

  @override
  String get memoriesMenuMore => 'Mehr';

  @override
  String get settingsScreenMemoryKinds => 'Arten von Erinnerungen';

  @override
  String get settingsScreenMemoryOnThisDay => 'An diesem Tag';

  @override
  String get settingsScreenMemoryWeek => 'Die letzte Woche';

  @override
  String get settingsScreenMemoryTrip => 'Reisen';

  @override
  String get settingsScreenMemoryPersonYears => 'Eine Person im Lauf der Jahre';

  @override
  String get settingsScreenMemoryBirthday => 'Geburtstage';

  @override
  String get settingsScreenMemoryYearReview => 'Ein Jahr in Fotos';

  @override
  String get settingsScreenMemoryMonthAgo => 'Vor einem Monat';

  @override
  String get settingsScreenHiddenFromMemories => 'In Erinnerungen ausgeblendet';

  @override
  String get settingsScreenNothingHidden => 'Nichts ist ausgeblendet.';

  @override
  String get settingsScreenShowAgain => 'Wieder anzeigen';

  @override
  String settingsScreenHiddenMemoryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Erinnerungen ausgeblendet',
      one: '1 Erinnerung ausgeblendet',
    );
    return '$_temp0';
  }

  @override
  String get settingsScreenShowAllAgain => 'Alle wieder anzeigen';

  @override
  String get accountSheetExport => 'Bibliothek exportieren';

  @override
  String get adminScreenExports => 'Bibliotheksexporte';

  @override
  String get adminScreenExportsHint =>
      'Exporte verfolgen, abbrechen und herunterladen';

  @override
  String adminUsersExportTooltip(String email) {
    return 'Bibliothek von $email exportieren';
  }

  @override
  String adminUsersExportStarted(String email) {
    return 'Der Export der Bibliothek von $email wurde gestartet.';
  }

  @override
  String get exportsScreenTitle => 'Export';

  @override
  String get exportsScreenAllTitle => 'Bibliotheksexporte';

  @override
  String get exportsScreenWhatIsIn =>
      'Nehmen Sie Ihre ganze Bibliothek mit: ZIP-Dateien mit je höchstens 10 GB, mit jedem Original wie hochgeladen, seinem XMP-Sidecar, einem Ordner für jedes Album und einer JSON-Datei mit Daten, Orten, Beschreibungen, Bewertungen, Favoriten, Tags, Personen und Bearbeitungen. Passwörter und Schlüssel sind nie darin. Er wird auf dem Server erstellt, läuft nach einem Neustart weiter und kann 7 Tage lang heruntergeladen werden.';

  @override
  String get exportsScreenAdminHint =>
      'Ein Export, den Sie für jemanden starten, erscheint auch in dessen eigener Liste. Sie und die Person können ihn herunterladen; andere Administratoren verfolgen ihn nur.';

  @override
  String get exportsScreenStart => 'Meine Bibliothek exportieren';

  @override
  String get exportsScreenStarted => 'Der Export wurde gestartet.';

  @override
  String get exportsScreenNothingYet => 'Es wurde noch nichts exportiert.';

  @override
  String get exportsScreenNotLoaded =>
      'Die Exporte konnten nicht geladen werden.';

  @override
  String get exportsScreenRunning => 'Läuft';

  @override
  String get exportsScreenReady => 'Fertig';

  @override
  String get exportsScreenFailed => 'Fehlgeschlagen';

  @override
  String get exportsScreenCancelled => 'Abgebrochen';

  @override
  String get exportsScreenRemoved => 'Nach 7 Tagen entfernt';

  @override
  String exportsScreenProgress(
    int done,
    int total,
    String doneBytes,
    String totalBytes,
  ) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$totalString Dateien',
      one: '1 Datei',
    );
    return '$doneString von $_temp0 · $doneBytes von $totalBytes';
  }

  @override
  String exportsScreenStartedBy(String name) {
    return 'Gestartet von $name';
  }

  @override
  String exportsScreenMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien',
      one: '1 Datei',
    );
    return 'Nicht auf dem Datenträger, daher nur aufgeführt: $_temp0';
  }

  @override
  String exportsScreenKeptUntil(String date) {
    return 'Kann bis $date heruntergeladen werden.';
  }

  @override
  String get exportsScreenOnlyOwner =>
      'Herunterladen kann ihn nur der Besitzer der Bibliothek oder der Administrator, der den Export gestartet hat.';

  @override
  String get exportsScreenCancel => 'Abbrechen';

  @override
  String get exportsScreenRemove => 'Entfernen';

  @override
  String exportsScreenPart(int number) {
    return 'Teil $number';
  }

  @override
  String exportsScreenFiles(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString Dateien',
      one: '1 Datei',
    );
    return '$_temp0';
  }

  @override
  String exportsScreenDownloadPart(int number) {
    return 'Teil $number herunterladen';
  }

  @override
  String get exportsScreenDownloadFailed =>
      'Der Teil konnte nicht heruntergeladen werden. Versuchen Sie es erneut, um dort weiterzumachen, wo er stehen blieb.';

  @override
  String get exportsScreenNoSpace =>
      'Auf dem Server ist nicht genug Platz für diesen Export. Geben Sie Speicher frei oder wenden Sie sich an den Administrator.';

  @override
  String get exportsScreenAlreadyRunning =>
      'Ein Export dieser Bibliothek läuft bereits.';

  @override
  String get viewerScreenPlayOnTv => 'Auf dem Fernseher zeigen';

  @override
  String get viewerScreenMore => 'Weitere Aktionen';

  @override
  String get slideshowScreenPlayOnTv => 'Auf dem Fernseher zeigen';

  @override
  String get tvSheetTitle => 'Auf dem Fernseher zeigen';

  @override
  String get tvSheetSearching => 'Fernseher in diesem Netzwerk werden gesucht…';

  @override
  String get tvSheetNoneFound => 'Noch kein Fernseher gefunden.';

  @override
  String get tvSheetSearchAgain => 'Erneut suchen';

  @override
  String get tvSheetChromecast => 'Chromecast';

  @override
  String get tvSheetDlna => 'DLNA-Fernseher';

  @override
  String get tvSheetAirPlay => 'AirPlay';

  @override
  String get tvSheetAirPlayHint =>
      'Wählen Sie mit der Taste ein Apple TV: Videos, die Sie abspielen, laufen dort. Fotos erscheinen mit der Bildschirmsynchronisierung im Kontrollzentrum.';

  @override
  String get tvSheetAddByAddress => 'Fernseher über seine Adresse hinzufügen';

  @override
  String get tvSheetAddressLabel =>
      'IP-Adresse des Fernsehers oder seine Beschreibungsadresse';

  @override
  String get tvSheetAdd => 'Hinzufügen';

  @override
  String get tvSheetNotFoundAt =>
      'Unter dieser Adresse hat kein Fernseher geantwortet.';

  @override
  String tvSheetPlayingOn(String device) {
    return 'Läuft auf $device';
  }

  @override
  String get tvSheetStop => 'Beenden';

  @override
  String get tvSheetFailed => 'Der Fernseher war nicht erreichbar.';

  @override
  String get tvSheetPlay => 'Auf dem Fernseher abspielen';

  @override
  String get tvSheetPause => 'Auf dem Fernseher pausieren';

  @override
  String get tvSheetPosition => 'Position auf dem Fernseher';

  @override
  String get tvSheetConnecting => 'Verbindung zum Fernseher…';

  @override
  String get tvSheetSameNetwork =>
      'Fernseher und Handy müssen im selben Netzwerk sein. Der Fernseher bekommt eine Adresse, die 4 Stunden gilt und nur für das, was Sie senden.';

  @override
  String get adminServerSettingsDlna => 'DLNA-Medienserver';

  @override
  String get adminServerSettingsDlnaHelp =>
      'Fernseher im Heimnetz sehen Ihre Alben, ohne Passwort. Dafür braucht es den Dienst dlna, der im Netzwerk des Hosts läuft: siehe die TV-Seite der Dokumentation.';

  @override
  String adminServerSettingsDlnaOwner(String name) {
    return 'Fernseher sehen die Alben von $name.';
  }

  @override
  String get adminServerSettingsDlnaAnnounced =>
      'Der Dienst dlna läuft, Fernseher finden diesen Server.';

  @override
  String get adminServerSettingsDlnaNotAnnounced =>
      'Vom Dienst dlna kam noch nichts, Fernseher finden diesen Server noch nicht.';

  @override
  String get widgetInstallTitle => 'Installationsprüfung';

  @override
  String get widgetInstallMissing =>
      'Das Widget fehlt in dieser Installation: Die Signierung hat es entfernt. Signiere die App erneut, ohne Erweiterungen zu entfernen (in Feather: PlugIns nicht entfernen).';

  @override
  String get widgetInstallUnsigned =>
      'Das Widget ist in der App, wurde aber nicht signiert, daher bietet iOS es nicht an. Signiere die App erneut, sodass auch ihre Erweiterungen signiert werden.';

  @override
  String get widgetInstallFine =>
      'Das Widget ist installiert und signiert. Wenn es weiterhin nicht angeboten wird, starte das Telefon neu.';

  @override
  String get homeWidgetNoShare =>
      'Diese Installation erlaubt der App nicht, das Album an ihr Widget zu übergeben.';
}

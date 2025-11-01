import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @termsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditions;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdated;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Please try again.'**
  String get uploadFailed;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get chooseTheme;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get confirmLogout;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @accountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get accountInfo;

  /// No description provided for @languagePreferences.
  ///
  /// In en, this message translates to:
  /// **'Language Preferences'**
  String get languagePreferences;

  String get verify_otp;

  String get edit_mobile;

  String get reportBug;

  String get changepassword;

  String get delete;

  String get blockAccount;

  String get update;
  String get save;

  String get no;
  String get yes;

  String get apply;

  String get verify;

  String? get mobile_number;

  String get account_disabled;

  String get error_sending_otp;

  String? get enter_otp;

  String get mobile_verified;

  String get otp_failed;

  String get error_verifying_otp;

  String get logout_message;

  String get profilePictureUpdated;

  String? get uploadError;

  String get failedToUpload;

  String? get bugHint;

  String get bugEmpty;

  String? get oldPassword;

  String? get newPassword;

  String get passwordHint;

  String get atLeast8Chars;

  String get uppercaseLetter;

  String get lowercaseLetter;

  String get aNumber;

  String get specialCharacter;

  String get passwordStrong;

  Object get weak;

  Object get medium;

  String? get confirmNewPassword;

  String get allFieldsRequired;

  String get passwordMismatch;

  String get noUser;

  String get wrongOldPassword;

  String get passwordUpdated;

  String get passwordUpdateFailed;

  String get editName;

  String? get fullName;

  String get confirmNameChange;

  String get nameChangeMessage;

  String get nameUpdated;

  String get nameUpdateError;

  String get accountDisabledLogout;

  String get accountDisabledSupport;

  String get chooseFile;

  get nameEmptyError;

  get mobileInvalidError;

  String get close;

  String get imageUploadFailed;

  String get accountManagement;

  String get deleteAccount;

  String get address;

  String get addressBook;

  String get notificationSettings;

  String get supportFeedback;

  String get legalInfo;

  String get privacyPolicy;

  String get requestSupport;

  // #agentdb
  String get performanceOverview;

  String get activeLoads;

  String get completed;

  String get findShipments;

  String get availableLoads;

  String get createShipment;

  String get postNewLoad;

  String get myChats;

  String get viewConversations;

  String get loadBoard;

  String get browsePostLoads;

  String get activeTrips;

  String get monitorLiveLocations;

  String get myTrucks;

  String get addTrackVehicles;

  String get myDrivers;

  String get addTrackDrivers;

  String get ratings;

  String get viewRatings;

  String get complaints;

  String get fileOrView;

  String get myTrips;

  String get historyDetails;

  String get bilty;

  String get createConsignmentNote;

  String get truckDocuments;

  String get manageTruckRecords;

  String get driverDocuments;

  String get manageDriverRecords;
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
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

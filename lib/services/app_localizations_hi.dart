import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';


/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get editProfile => 'प्रोफ़ाइल संपादित करें';

  @override
  String get language => 'भाषा';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get lightMode => 'लाइट मोड';

  @override
  String get rateApp => 'ऐप को रेट करें';

  @override
  String get feedback => 'प्रतिपुष्टि';

  @override
  String get appVersion => 'ऐप संस्करण';

  @override
  String get termsConditions => 'नियम और शर्तें';

  @override
  String get takePhoto => 'फ़ोटो खींचें';

  @override
  String get chooseFromGallery => 'गैलरी से चुनें';

  @override
  String get profileUpdated => 'प्रोफ़ाइल सफलतापूर्वक अपडेट हुई!';

  @override
  String get uploadFailed => 'अपलोड विफल। कृपया पुनः प्रयास करें।';

  @override
  String get theme => 'थीम';

  @override
  String get systemDefault => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get chooseTheme => 'थीम चुनें';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get confirmLogout => 'क्या आप वाकई लॉगआउट करना चाहते हैं?';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get confirm => 'पुष्टि करें';

  @override
  String get accountInfo => 'खाता जानकारी';

  @override
  String get languagePreferences => 'भाषा प्राथमिकताएँ';

  String get verify_otp=>"ओटीपी सत्यापित करें";

  String get edit_mobile=>"मोबाइल नंबर संपादित करें";

  String get reportBug=> "बग की रिपोर्ट करें";

  String get changepassword=> "पासवर्ड बदलें";

  String get delete=>"हटाएं";

  String get blockAccount=>"खाता ब्लॉक करें";

  String get update=>"अपडेट करें";
  String get save=>"सहेजें";

  String get no=>"नहीं";
  String get yes=>"हाँ";

  String get apply=> "लागू करें";

  String get verify=>"सत्यापित करें";

  String? get mobile_number => "मोबाइल नंबर";

  String get account_disabled=>"आपका खाता निष्क्रिय कर दिया गया है।";

  String get error_sending_otp=> "ओटीपी भेजने में त्रुटि: {error}";

  String? get enter_otp=>"ओटीपी दर्ज करें";

  String get mobile_verified=> "मोबाइल नंबर सत्यापित ✅";

  String get otp_failed=>"ओटीपी सत्यापन विफल ❌";

  String get error_verifying_otp=>"ओटीपी सत्यापित करने में त्रुटि: {error}";

  String get logout_message=>"क्या आप वाकई लॉग आउट करना चाहते हैं?";

  String get profilePictureUpdated=> "प्रोफ़ाइल तस्वीर अपडेट हो गई।";

  String? get uploadError=> "अपलोड त्रुटि: {error}";

  String get failedToUpload=> "अपलोड विफल: {error}";

  String? get bugHint=>"जिस समस्या का आप सामना कर रहे हैं उसका विवरण दें...";

  String get bugEmpty=>"भेजने से पहले कृपया बग का विवरण दें।";

  String? get oldPassword=>"पुराना पासवर्ड";

  String? get newPassword=>"नया पासवर्ड";

  String get passwordHint=> "संकेत: कम से कम 8 अक्षरों का उपयोग करें जिसमें बड़े अक्षर, छोटे अक्षर, संख्या और विशेष अक्षर हों।";

  String get atLeast8Chars=> "कम से कम 8 अक्षर";

  String get uppercaseLetter=> "एक बड़ा अक्षर";

  String get lowercaseLetter=>"एक छोटा अक्षर";

  String get aNumber=>"एक संख्या";

  String get specialCharacter=> "एक विशेष अक्षर";

  String get passwordStrong =>"बहुत अच्छा! आपका पासवर्ड मज़बूत है।";

  Object get weak=>"कमज़ोर";

  Object get medium=>"मध्यम";

  String? get confirmNewPassword=>"नए पासवर्ड की पुष्टि करें";

  String get allFieldsRequired=>"सभी फ़ील्ड आवश्यक हैं।";

  String get passwordMismatch=>"नया पासवर्ड और पुष्टि मेल नहीं खाते।";

  String get noUser=>"कोई उपयोगकर्ता लॉग इन नहीं है।";

  String get wrongOldPassword=> "पुराना पासवर्ड गलत है।";

  String get passwordUpdated=> "पासवर्ड सफलतापूर्वक अपडेट हो गया।";

  String get passwordUpdateFailed=> "पासवर्ड अपडेट असफल रहा। फिर से प्रयास करें।";

  String get editName=> "नाम संपादित करें";

  String? get fullName=> "पूरा नाम";

  String get confirmNameChange=>"नाम परिवर्तन की पुष्टि करें";

  String get nameChangeMessage=> "क्या आप वाकई अपना नाम \"{oldName}\" से बदलकर \"{newName}\" करना चाहते हैं?";

  String get nameUpdated=>"नाम सफलतापूर्वक अपडेट हो गया";



  String get nameUpdateError=>"नाम अपडेट करते समय त्रुटि: {error}";

  String get accountDisabledLogout=>"आपका खाता अक्षम कर दिया गया है। आप दोबारा लॉगिन नहीं कर सकते।";

  String get accountDisabledSupport=> "आपका खाता अक्षम है। कृपया सहायता से संपर्क करें।";

  String get chooseFile=>"फ़ाइल चुनें";

  get nameEmptyError=>"नाम खाली नहीं हो सकता";

  get mobileInvalidError=>"मान्य 10-अंकों का नंबर दर्ज करें";

  String get close=>"बंद करें";

  String get imageUploadFailed=> "छवि अपलोड विफल: {error}";

  String get accountManagement=> "खाता प्रबंधन";

  String get deleteAccount=> "खाता हटाएं";

  String get address=>"पता";

  String get addressBook=> "पता पुस्तिका";

  String get notificationSettings=>"सूचना सेटिंग्स";

  String get supportFeedback=> "सहायता और प्रतिक्रिया";

  String get legalInfo=>"कानूनी और जानकारी";

  String get privacyPolicy=>"गोपनीयता नीति";
  String get requestSupport=>"तकनीकी सहायता का अनुरोध करें";




  String get performanceOverview=> "प्रदर्शन अवलोकन";

  String get activeLoads=>"सक्रिय लोड्स" ;

  String get completed=>  "पूर्ण";

  String get findShipments=>  "शिपमेंट खोजें";

  String get availableLoads=> "उपलब्ध लोड्स";

  String get createShipment=>"शिपमेंट बनाएं" ;

  String get postNewLoad=>  "नया लोड पोस्ट करें";

  String get myChats=>"मेरे चैट्स" ;

  String get viewConversations=> "संवाद देखें";

  String get loadBoard=>  "लोड बोर्ड";

  String get browsePostLoads=>"लोड ब्राउज़ और पोस्ट करें" ;

  String get activeTrips=> "सक्रिय यात्राएँ";

  String get monitorLiveLocations=> "लाइव स्थान मॉनिटर करें";

  String get myTrucks=>"मेरे ट्रक" ;

  String get addTrackVehicles=> "वाहन जोड़ें और ट्रैक करें";

  String get myDrivers=>  "मेरे ड्राइवर";

  String get addTrackDrivers=>"ड्राइवर जोड़ें और ट्रैक करें" ;

  String get ratings=>  "रेटिंग्स";

  String get viewRatings=> "अपनी रेटिंग्स देखें";

  String get complaints=> "शिकायतें" ;

  String get fileOrView=> "दर्ज करें या देखें";

  String get myTrips=>"मेरी यात्राएँ" ;

  String get historyDetails=>"इतिहास और विवरण" ;

  String get bilty=>"बिल्टी" ;

  String get createConsignmentNote=> "कंसाइनमेंट नोट बनाएं";

  String get truckDocuments=> "ट्रक दस्तावेज़" ;

  String get manageTruckRecords=>  "ट्रक रिकॉर्ड प्रबंधित करें";

  String get driverDocuments=> "ड्राइवर दस्तावेज़" ;

  String get manageDriverRecords=> "ड्राइवर रिकॉर्ड प्रबंधित करें";

  String get selectTruckType=>"ट्रक प्रकार चुनें";

  String get name=>"नाम";

}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Silkway';

  @override
  String get navMenu => 'Menu';

  @override
  String get navCart => 'Cart';

  @override
  String get navProfile => 'Profile';

  @override
  String get authPhoneTitle => 'Sign in';

  @override
  String get authPhonePrompt => 'Enter your phone number';

  @override
  String get authPhoneLabel => 'Phone';

  @override
  String get authPhoneNext => 'Next';

  @override
  String get authOtpTitle => 'Verification code';

  @override
  String authOtpSentTo(String phone) {
    return 'Code sent to $phone';
  }

  @override
  String get authOtpLabel => 'SMS code';

  @override
  String get authOtpConfirm => 'Confirm';

  @override
  String get authOtpInvalid => 'Invalid code';

  @override
  String get cartEmpty => 'Your cart is empty';

  @override
  String get cartCheckout => 'Checkout';

  @override
  String genericError(String error) {
    return 'Error: $error';
  }
}

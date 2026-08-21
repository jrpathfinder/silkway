// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Silkway';

  @override
  String get navMenu => 'Меню';

  @override
  String get navCart => 'Корзина';

  @override
  String get navProfile => 'Профиль';

  @override
  String get authPhoneTitle => 'Вход';

  @override
  String get authPhonePrompt => 'Введите номер телефона';

  @override
  String get authPhoneLabel => 'Телефон';

  @override
  String get authPhoneNext => 'Далее';

  @override
  String get authOtpTitle => 'Код подтверждения';

  @override
  String authOtpSentTo(String phone) {
    return 'Код отправлен на $phone';
  }

  @override
  String get authOtpLabel => 'Код из СМС';

  @override
  String get authOtpConfirm => 'Подтвердить';

  @override
  String get authOtpInvalid => 'Неверный код';

  @override
  String get cartEmpty => 'Корзина пуста';

  @override
  String get cartCheckout => 'Оформить заказ';

  @override
  String genericError(String error) {
    return 'Ошибка: $error';
  }
}

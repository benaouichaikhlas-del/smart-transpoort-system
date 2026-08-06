import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('fr');

  Locale get locale => _locale;

  bool get isArabic => _locale.languageCode == 'ar';

  void setLocale(Locale locale) {
    if (!['fr', 'en', 'ar'].contains(locale.languageCode)) return;
    _locale = locale;
    notifyListeners();
  }
}

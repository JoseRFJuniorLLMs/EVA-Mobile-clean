import 'package:flutter/material.dart';
import '../core/localization/translations.dart';

class LanguageProvider with ChangeNotifier {
  String _lang = 'pt';

  String get lang => _lang;

  void setLanguage(String language) {
    if (_lang != language && AppTranslations.all.containsKey(language)) {
      _lang = language;
      notifyListeners();
    }
  }

  /// Get translated string by key
  String t(String key) {
    return AppTranslations.all[_lang]?[key] ??
        AppTranslations.all['pt']?[key] ??
        key;
  }
}

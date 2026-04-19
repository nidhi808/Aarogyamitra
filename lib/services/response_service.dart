import 'dart:convert';
import 'package:flutter/services.dart';

class ResponseService {
  Map<String, dynamic> _translations = {};

  Future<void> loadTranslations() async {
    final String response = await rootBundle.loadString('assets/data/translations.json');
    _translations = await json.decode(response);
    print("Language Service: Loaded translations for languages: ${_translations.keys.toList()}");
  }

  String getTranslation(String lang, String key, [Map<String, String>? placeholders]) {
    String text = _translations[lang]?[key] ?? key;
    if (placeholders != null) {
      placeholders.forEach((k, v) {
        text = text.replaceAll('{$k}', v);
      });
    }
    return text;
  }
}

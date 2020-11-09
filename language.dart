import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Language {
  final Locale locale;

  Language(this.locale);

  static Language of(BuildContext context) {
    return Localizations.of<Language>(context, Language);
  }

  Map<String, String> _localizedValues;

  Future load() async {
    String jsonStringValues =
        await rootBundle.loadString("lang/${locale.languageCode}.json");
    Map<String, dynamic> mappedJson = json.decode(jsonStringValues);
    this._localizedValues =
        mappedJson.map((key, value) => MapEntry(key, value.toString()));
  }

  String getTrans(String key) {
    return this._localizedValues[key];
  }

  static const LocalizationsDelegate<Language> delegate = _LangDelegate();
}

class _LangDelegate extends LocalizationsDelegate<Language> {
  const _LangDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<Language> load(Locale locale) async {
    Language localization = Language(locale);
    await localization.load();
    return localization;
  }

  @override
  bool shouldReload(_LangDelegate old) => false;
}

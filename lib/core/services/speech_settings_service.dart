import 'package:shared_preferences/shared_preferences.dart';

class SpeechSettingsService {
  static const _speechLocaleIdKey = 'speech_locale_id';

  Future<String?> getSpeechLocaleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_speechLocaleIdKey);
  }

  Future<void> setSpeechLocaleId(String? localeId) async {
    final prefs = await SharedPreferences.getInstance();

    if (localeId == null || localeId.trim().isEmpty) {
      await prefs.remove(_speechLocaleIdKey);
      return;
    }

    await prefs.setString(_speechLocaleIdKey, localeId);
  }
}
import 'package:translator/translator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FreeTranslator {
  final _translator = GoogleTranslator();

  Future<String> toMarathi(String text) async {
    if (text.trim().isEmpty) return text;

    // Check cache first
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'mr_${text.hashCode}';
    final cached = prefs.getString(cacheKey);
    if (cached != null) return cached;

    // Free Google Translate — no API key needed
    final result = await _translator.translate(text, from: 'en', to: 'mr');

    // Cache it permanently
    await prefs.setString(cacheKey, result.text);
    return result.text;
  }

  /// Translate all string values in a map
  Future<Map<String, String>> translateAll(Map<String, String> data) async {
    final result = <String, String>{};
    for (final entry in data.entries) {
      result[entry.key] = await toMarathi(entry.value);
    }
    return result;
  }
}

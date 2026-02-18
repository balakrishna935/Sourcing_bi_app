import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';
import 'package:devlipi/devlipi.dart';
import 'package:mukadam_bi/getTransport/transport_registration_response.dart';

class getTransportRegistrationService {
  static const String baseUrl =
      'https://supply.bharatintelligence.ai/api/user-registrations/';

  // ✅ NEW: Translator instance
  final GoogleTranslator _translator = GoogleTranslator();

  // ✅ NEW: Translate to Marathi (same pattern as MukkadamServiceee)
  Future<String> _toMarathi(String text) async {
    if (text.trim().isEmpty) return text;

    try {
      final result = await _translator.translate(text, from: 'en', to: 'mr');
      if (result.text.toLowerCase() != text.toLowerCase()) {
        return result.text;
      }
    } catch (_) {}

    // Fallback to transliteration for short codes / names
    return Devlipi.transliterate(text);
  }

  Future<TransportRegistrationResponse> fetchRegistrations({
    required int userId,
    required String dateFrom,
    required String dateTo,
    String entityType = "transporter",
  }) async {
    final url = Uri.parse(
        "$baseUrl?user_id=$userId&entity_type=$entityType&date_from=$dateFrom&date_to=$dateTo");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data =
        TransportRegistrationResponse.fromJson(json.decode(response.body));

        // ✅ NEW: Auto convert transporter names to Marathi
        for (var t in data.transporters) {
          if (t.name.isNotEmpty && t.name != 'N/A') {
            t.marathiName = await _toMarathi(t.name);
          }
        }

        return data;
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Connection error: $e");
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mukadam_bi/referral/registration_response.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';
import 'package:devlipi/devlipi.dart';
import '../verifications/mukadam_dashboard/mukkadam_data_model.dart';

class MukkadamServiceee {
  static const String baseUrl =
      "https://supply.bharatintelligence.ai/api/users";

  // ✅ NEW: Translator instance
  final GoogleTranslator _translator = GoogleTranslator();

  // ✅ NEW: Same logic as VerificationService._toMarathi()
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

  /// ✅ Fetches ALL mukkadams (all statuses) — used by DirectoryScreen
  Future<List<MukkadamDataModell>> fetchMukkadams(int userId) async {
    final url = Uri.parse(
      '$baseUrl/$userId/pending-verifications/'
          '?type=mukkadam&status=not_started,pending,verified',
    );

    final prefs = await SharedPreferences.getInstance();
    final String? sessionToken = prefs.getString('session_token');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'Authorization': 'Token $sessionToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> entities = data['entities'] ?? [];
        List<MukkadamDataModell> mukkadams = entities
            .map((json) => MukkadamDataModell.fromJson(json))
            .toList();

        // ✅ NEW: Auto convert mukkadam names to Marathi
        for (var m in mukkadams) {
          if (m.mukkadamName.isNotEmpty) {
            m.marathiName = await _toMarathi(m.mukkadamName);
          }
        }

        return mukkadams;
      } else {
        throw Exception('Failed to load mukkadams');
      }
    } catch (e) {
      throw Exception('Error fetching mukkadams: $e');
    }
  }

  /// Fetches ONLY pending/not_started mukkadams — used by PendingVerificationListScreen
  Future<List<MukkadamDataModell>> fetchPendingVerifications(int userId) async {
    final url = Uri.parse(
      '$baseUrl/$userId/pending-verifications/'
          '?type=mukkadam&status=not_started,pending',
    );

    final prefs = await SharedPreferences.getInstance();
    final String? sessionToken = prefs.getString('session_token');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'Authorization': 'Token $sessionToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> entities = data['entities'] ?? [];
        List<MukkadamDataModell> mukkadams = entities
            .map((json) => MukkadamDataModell.fromJson(json))
            .toList();

        // ✅ NEW: Auto convert mukkadam names to Marathi
        for (var m in mukkadams) {
          if (m.mukkadamName.isNotEmpty) {
            m.marathiName = await _toMarathi(m.mukkadamName);
          }
        }

        return mukkadams;
      } else {
        throw Exception('Failed to load verifications');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Fetches ONLY fully verified mukkadams — used by DirectoryScreen
  Future<List<MukkadamDataModell>> fetchVerifiedMukkadams(int userId) async {
    final url = Uri.parse(
      '$baseUrl/$userId/pending-verifications/'
          '?type=mukkadam&status=verified',
    );

    final prefs = await SharedPreferences.getInstance();
    final String? sessionToken = prefs.getString('session_token');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'Authorization': 'Token $sessionToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> entities = data['entities'] ?? [];
        List<MukkadamDataModell> mukkadams = entities
            .map((json) => MukkadamDataModell.fromJson(json))
            .toList();

        // ✅ NEW: Auto convert mukkadam names to Marathi
        for (var m in mukkadams) {
          if (m.mukkadamName.isNotEmpty) {
            m.marathiName = await _toMarathi(m.mukkadamName);
          }
        }

        return mukkadams;
      } else {
        throw Exception('Failed to load verified mukkadams');
      }
    } catch (e) {
      throw Exception('Error fetching verified mukkadams: $e');
    }
  }
}

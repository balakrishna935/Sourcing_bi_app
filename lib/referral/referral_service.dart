import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mukadam_bi/referral/registration_response.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../verifications/mukadam_dashboard/mukkadam_data_model.dart';

class MukkadamServiceee {
  // 🔁 Switch between DEPLOYED_URL and TEST_URL:
  static final String baseUrl = '${dotenv.env['DEPLOYED_URL']!}/api/users';
  // static final String baseUrl = '${dotenv.env['TEST_URL']!}/api/users';

  /// Fetches ALL mukkadams (all statuses) — used by DirectoryScreen
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
          'Authorization': 'Token $sessionToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> entities = data['entities'] ?? [];
        return entities
            .map((json) => MukkadamDataModell.fromJson(json))
            .toList();
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
          'Authorization': 'Token $sessionToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> entities = data['entities'] ?? [];
        return entities
            .map((json) => MukkadamDataModell.fromJson(json))
            .toList();
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
          'Authorization': 'Token $sessionToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> entities = data['entities'] ?? [];
        return entities
            .map((json) => MukkadamDataModell.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load verified mukkadams');
      }
    } catch (e) {
      throw Exception('Error fetching verified mukkadams: $e');
    }
  }
}

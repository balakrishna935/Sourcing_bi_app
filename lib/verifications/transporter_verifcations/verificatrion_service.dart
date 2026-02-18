import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mukadam_bi/verifications/transporter_verifcations/verification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';
import 'package:devlipi/devlipi.dart';

class VerificationService {
  static const String baseUrl =
      "https://supply.bharatintelligence.ai/api/users/";

  final GoogleTranslator _translator = GoogleTranslator();

  Future<String> _toMarathi(String text) async {
    if (text.trim().isEmpty) return text;
    try {
      final result = await _translator.translate(text, from: 'en', to: 'mr');
      if (result.text.toLowerCase() != text.toLowerCase()) {
        return result.text;
      }
    } catch (_) {}
    return Devlipi.transliterate(text);
  }

  Future<String?> uploadFileToS3({
    required String filePath,
    required String s3ObjectName,
  }) async {
    final String s3Url =
        "https://demand.bharatintelligence.ai/chat/api/upload_image_to_s3/";
    final String s3AuthToken = 'e8fa8310c9af344ca22ec6bd23960d609b09c704';

    final uri = Uri.parse(s3Url);
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Token $s3AuthToken';
    request.headers['ngrok-skip-browser-warning'] = 'true';

    request.fields['name_of_image'] = s3ObjectName;
    request.files.add(await http.MultipartFile.fromPath('image', filePath));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['s3_key'];
      }
      return null;
    } catch (e) {
      print("❌ S3 Upload Error: $e");
      return null;
    }
  }

  /// Helper: translates all fields for a single entity
  Future<void> _translateEntity(VerificationEntity entity) async {
    // ✅ NAME — translate SEPARATELY so Devlipi fallback works for proper nouns
    // When sent alone, Google returns "RAMESH" unchanged → != check fails → Devlipi fires → "रामेश"
    if (entity.entity.name.trim().isNotEmpty) {
      entity.entity.marathiName = await _toMarathi(entity.entity.name);
    }

    // ✅ LOCATION + VEHICLE TYPE — batch these together (real words, Google translates fine)
    final parts = [
      entity.entity.baseLocation,       // index 0 → marathiBaseLocation
      entity.entity.vehicleType ?? '',   // index 1 → marathiVehicleType
    ];

    final nonEmptyParts = <int, String>{};
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].trim().isNotEmpty) {
        nonEmptyParts[i] = parts[i];
      }
    }

    if (nonEmptyParts.isEmpty) return;

    final combined = nonEmptyParts.values.join(' | ');
    final translated = await _toMarathi(combined);
    final translatedParts = translated.split(' | ');

    final keys = nonEmptyParts.keys.toList();
    for (int j = 0; j < keys.length && j < translatedParts.length; j++) {
      final value = translatedParts[j].trim();
      switch (keys[j]) {
        case 0: entity.entity.marathiBaseLocation = value; break;
        case 1: entity.entity.marathiVehicleType = value; break;
      }
    }
  }

  /// Fetches ONLY pending/not_started verifications for PendingVerificationListScreen
  Future<List<VerificationEntity>> fetchPendingVerifications(int userId) async {
    final url = Uri.parse(
        '$baseUrl$userId/pending-verifications/?type=transporter&status=not_started,pending');

    final prefs = await SharedPreferences.getInstance();
    final String? sessionToken = prefs.getString('session_token');

    if (sessionToken == null) {
      print("Error: session_token is null in SharedPreferences");
    }

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'Authorization': 'Token $sessionToken',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<VerificationEntity> entities =
            PendingVerificationResponse.fromJson(data).entities;

        // ✅ Translate all fields for each entity
        for (var entity in entities) {
          await _translateEntity(entity);
        }

        return entities;
      } else {
        throw Exception("Failed to load verifications");
      }
    } catch (e) {
      throw Exception("Error fetching data: $e");
    }
  }

  /// Fetches ALL verifications (including verified ones) for TransportDirectoryScreen
  Future<List<VerificationEntity>> fetchAllVerifications(int userId) async {
    final url = Uri.parse(
        '$baseUrl$userId/pending-verifications/?type=transporter&status=not_started,pending,verified');

    final prefs = await SharedPreferences.getInstance();
    final String? sessionToken = prefs.getString('session_token');

    if (sessionToken == null) {
      print("Error: session_token is null in SharedPreferences");
    }

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'Authorization': 'Token $sessionToken',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<VerificationEntity> entities =
            PendingVerificationResponse.fromJson(data).entities;

        // ✅ Translate all fields for each entity
        for (var entity in entities) {
          await _translateEntity(entity);
        }

        return entities;
      } else {
        throw Exception("Failed to load verifications");
      }
    } catch (e) {
      throw Exception("Error fetching data: $e");
    }
  }

  Future<Map<String, dynamic>> fetchTransporterDetails(
      int transporterId) async {
    final url = Uri.parse(
        'https://supply.bharatintelligence.ai/api/transport-providers/$transporterId/');

    final prefs = await SharedPreferences.getInstance();
    final String? sessionToken = prefs.getString('session_token');

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'Authorization': 'Token $sessionToken',
      });

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Failed to load transporter details");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  Future<bool> updateTransporter(
      int transporterId, Map<String, dynamic> data) async {
    final url = Uri.parse(
        'https://supply.bharatintelligence.ai/api/transport-providers/$transporterId/');

    final prefs = await SharedPreferences.getInstance();
    final String? sessionToken = prefs.getString('session_token');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'Authorization': 'Token $sessionToken',
        },
        body: json.encode(data),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Update Error: $e");
      return false;
    }
  }
}

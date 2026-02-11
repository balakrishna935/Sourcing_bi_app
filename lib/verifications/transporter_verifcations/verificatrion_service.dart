import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mukadam_bi/verifications/transporter_verifcations/verification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VerificationService {
  // ─── Environment-driven URLs & tokens ───
  static String get deployedUrl =>
      dotenv.env['DEPLOYED_URL'] ?? 'https://supply.bharatintelligence.ai';

  static String get baseUrl => '$deployedUrl/api/users';

  static String get transporterBaseUrl =>
      '$deployedUrl/api/transport-providers';

  static String get s3UploadUrl =>
      dotenv.env['S3_UPLOAD_URL'] ??
          'https://demand.bharatintelligence.ai/chat/api/upload_image_to_s3/';

  static String get s3AuthToken =>
      dotenv.env['S3_UPDATED_TOKEN'] ?? '';

  // ─── Helper to get session token ───
  Future<String?> _getSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    final String? sessionToken = prefs.getString('session_token');
    if (sessionToken == null) {
      print("Error: session_token is null in SharedPreferences");
    }
    return sessionToken;
  }

  // ─── Common headers ───
  Map<String, String> _headers(String? sessionToken, {bool withContentType = true}) {
    return {
      if (withContentType) 'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      'Authorization': 'Token $sessionToken',
    };
  }

  // ─── S3 Upload ───
  Future<String?> uploadFileToS3({
    required String filePath,
    required String s3ObjectName,
  }) async {
    final uri = Uri.parse(s3UploadUrl);
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

  // ─── Fetch ONLY pending/not_started verifications ───
  Future<List<VerificationEntity>> fetchPendingVerifications(int userId) async {
    final sessionToken = await _getSessionToken();
    final url = Uri.parse(
      "$baseUrl/$userId/pending-verifications/?type=transporter&status=not_started,pending",
    );

    try {
      final response = await http.get(
        url,
        headers: _headers(sessionToken),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PendingVerificationResponse.fromJson(data).entities;
      } else {
        throw Exception("Failed to load verifications");
      }
    } catch (e) {
      throw Exception("Error fetching data: $e");
    }
  }

  // ─── Fetch ALL verifications including verified ───
  Future<List<VerificationEntity>> fetchAllVerifications(int userId) async {
    final sessionToken = await _getSessionToken();
    final url = Uri.parse(
      "$baseUrl/$userId/pending-verifications/?type=transporter&status=not_started,pending,verified",
    );

    try {
      final response = await http.get(
        url,
        headers: _headers(sessionToken),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PendingVerificationResponse.fromJson(data).entities;
      } else {
        throw Exception("Failed to load verifications");
      }
    } catch (e) {
      throw Exception("Error fetching data: $e");
    }
  }

  // ─── Fetch single transporter details ───
  Future<Map<String, dynamic>> fetchTransporterDetails(
      int transporterId) async {
    final sessionToken = await _getSessionToken();
    final url = Uri.parse('$transporterBaseUrl/$transporterId/');

    try {
      final response = await http.get(
        url,
        headers: _headers(sessionToken),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Failed to load transporter details");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  // ─── PATCH update transporter ───
  Future<bool> updateTransporter(
      int transporterId, Map<String, dynamic> data) async {
    final sessionToken = await _getSessionToken();
    final url = Uri.parse('$transporterBaseUrl/$transporterId/');

    try {
      final response = await http.patch(
        url,
        headers: _headers(sessionToken),
        body: json.encode(data),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Update Error: $e");
      return false;
    }
  }
}

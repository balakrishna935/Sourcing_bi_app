import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'mukkadam_data_model.dart';

class MukkadamService {
  static String get deployedUrl =>
      dotenv.env['DEPLOYED_URL'] ?? 'https://supply.bharatintelligence.ai';

  static String get dashboardUrl => '$deployedUrl/api/dashboard/user';
  static String get detailUrl => '$deployedUrl/api/mukkadam';

  static String get s3UploadUrl =>
      dotenv.env['S3_UPLOAD_URL'] ??
          'https://demand.bharatintelligence.ai/chat/api/upload_image_to_s3/';

  static String get s3AuthToken =>
      dotenv.env['S3_UPDATED_TOKEN'] ?? '';

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

  Future<List<MukkadamDataModel>> fetchMukkadams(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? sessionToken = prefs.getString('session_token');

    if (sessionToken == null) {
      print("Error: session_token is null in SharedPreferences");
    }

    final response = await http.get(
      Uri.parse(
          '$deployedUrl/api/users/$userId/pending-verifications/?type=mukkadam&status=not_started,pending'),
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'Authorization': 'Token $sessionToken',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> mukkadamList = data['entities'] ?? [];
      return mukkadamList
          .map((json) => MukkadamDataModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load mukkadams');
    }
  }

  Future<List<MukkadamDataModel>> fetchVerifiedMukkadams(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? sessionToken = prefs.getString('session_token');

    if (sessionToken == null) {
      print("Error: session_token is null in SharedPreferences");
    }

    final response = await http.get(
      Uri.parse(
          '$deployedUrl/api/users/$userId/pending-verifications/?type=mukkadam&status=completed'),
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'Authorization': 'Token $sessionToken',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> mukkadamList = data['entities'] ?? [];
      return mukkadamList
          .map((json) => MukkadamDataModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load verified mukkadams');
    }
  }

  Future<Map<String, dynamic>> fetchMukkadamDetails(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final String? sessionToken = prefs.getString('session_token');

    final response = await http.get(
      Uri.parse('$detailUrl/$id/'),
      headers: {
        'Authorization': 'Token $sessionToken',
        'ngrok-skip-browser-warning': 'true',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load details');
    }
  }

  Future<bool> updateMukkadam(int id, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final String? sessionToken = prefs.getString('session_token');

    final response = await http.patch(
      Uri.parse('$detailUrl/$id/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $sessionToken',
      },
      body: json.encode(data),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }
}

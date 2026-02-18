import 'dart:convert';
import 'dart:io';
import 'package:devlipi/devlipi.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';
import 'mukkadam_data_model.dart';

class MukkadamService {
  // static const String dashboardUrl =
  //     "https://furtive-chrissy-reparably.ngrok-free.dev/api/dashboard/user";
  // static const String detailUrl =
  //     "https://furtive-chrissy-reparably.ngrok-free.dev/api/mukkadam";

  static const String dashboardUrl =
      "https://supply.bharatintelligence.ai/api/dashboard/user";
  static const String detailUrl =
      "https://supply.bharatintelligence.ai/api/mukkadam";

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

  /// Fetch mukkadams with pending/not_started verifications
  /// Used by: MukkadamListScreen (Verification Queue)
  Future<List<MukkadamDataModel>> fetchMukkadams(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? sessionToken = prefs.getString('session_token');

    if (sessionToken == null) {
      print("Error: session_token is null in SharedPreferences");
    }

    final response = await http.get(
      Uri.parse(
          'https://supply.bharatintelligence.ai/api/users/$userId/pending-verifications/?type=mukkadam&status=not_started,pending'),
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'Authorization': 'Token $sessionToken',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> mukkadamList = data['entities'] ?? [];
      List<MukkadamDataModel> mukkadams = mukkadamList
          .map((json) => MukkadamDataModel.fromJson(json))
          .toList();

      for (var m in mukkadams) {
        if (m.mukkadamName.isNotEmpty) {
          m.marathiName = await _toMarathi(m.mukkadamName);
        }
      }

      return mukkadams;




    } else {
      throw Exception('Failed to load mukkadams');
    }
  }

  /// Fetch mukkadams with completed verifications
  /// Used by: DirectoryScreen (Referrals - Registrations tab)
  Future<List<MukkadamDataModel>> fetchVerifiedMukkadams(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? sessionToken = prefs.getString('session_token');

    if (sessionToken == null) {
      print("Error: session_token is null in SharedPreferences");
    }

    final response = await http.get(
      Uri.parse(
          'https://supply.bharatintelligence.ai/api/users/$userId/pending-verifications/?type=mukkadam&status=completed'),
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

  /// Fetch single mukkadam detail
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

  /// PATCH update mukkadam
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

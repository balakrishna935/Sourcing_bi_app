// lib/seeplan/plan_service.dart

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mukadam_bi/seeplan/plan_service_model.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';

class PlanService {
  // All config read from .env — no hardcoded secrets
  static String get baseUrl => '${dotenv.env['DEPLOYED_URL']}/api';
  static String get s3FileUploadUrl =>
      '${dotenv.env['S3_UPLOAD_BASE_URL']}/chat/api/upload_image_to_s3/';
  static String get s3AuthToken => dotenv.env['S3_UPDATED_TOKEN'] ?? '';

  /// Fetch all village visit plans for the logged-in user
  Future<List<VillageVisitPlan>> fetchVisitPlans({
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('bg_user_id');
    final String? token = prefs.getString('session_token');

    if (userId == null) throw Exception("User ID not found");

    Map<String, String> queryParams = {'user_id': userId.toString()};

    if (status != null && status.isNotEmpty && status != 'all') {
      queryParams['status'] = status;
    }
    if (dateFrom != null && dateFrom.isNotEmpty) {
      queryParams['date_from'] = dateFrom;
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      queryParams['date_to'] = dateTo;
    }

    final uri = Uri.parse('$baseUrl/village-visit-plans/')
        .replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => VillageVisitPlan.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load plans: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching plans: $e");
    }
  }

  /// Fetch only completed plans
  Future<List<VillageVisitPlan>> fetchCompletedPlans() async {
    return fetchVisitPlans(status: 'completed');
  }

  /// Fetch only in-progress plans
  Future<List<VillageVisitPlan>> fetchInProgressPlans() async {
    return fetchVisitPlans(status: 'in_progress');
  }

  /// Fetch only planned plans
  Future<List<VillageVisitPlan>> fetchPlannedPlans() async {
    return fetchVisitPlans(status: 'planned');
  }

  /// Fetch plans within date range
  Future<List<VillageVisitPlan>> fetchPlansByDateRange(
      String dateFrom, String dateTo) async {
    return fetchVisitPlans(dateFrom: dateFrom, dateTo: dateTo);
  }

  /// Fetch village visits by status
  Future<List<VillageVisit>> fetchVillageVisits({String? status}) async {
    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('bg_user_id');
    final String? token = prefs.getString('session_token');

    if (userId == null) throw Exception("User ID not found");

    Map<String, String> queryParams = {'user_id': userId.toString()};

    if (status != null && status.isNotEmpty && status != 'all') {
      queryParams['status'] = status;
    }

    final uri = Uri.parse('$baseUrl/village-visits/')
        .replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => VillageVisit.fromJson(json)).toList();
      } else {
        throw Exception(
            "Failed to load village visits: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching village visits: $e");
    }
  }

  /// Fetch execution data for a specific village visit
  Future<VillageExecution?> fetchVillageExecution(
      String villageVisitId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('session_token');

    final url =
    Uri.parse('$baseUrl/village-visits/$villageVisitId/execution/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        return VillageExecution.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        debugPrint(
            "Error fetching execution: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Error fetching execution data: $e");
      return null;
    }
  }

  /// Upload file to S3 and return the S3 key
  Future<String?> uploadFileToS3({
    required String filePath,
    required String s3ObjectName,
  }) async {
    final uri = Uri.parse(s3FileUploadUrl);
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Token $s3AuthToken';

    String extension = p.extension(filePath).isNotEmpty
        ? p.extension(filePath).substring(1).toLowerCase()
        : 'jpg';
    if (['jpg', 'jpeg'].contains(extension)) {
      extension = 'jpeg';
    } else if (extension != 'png') {
      extension = 'jpeg';
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        filePath,
        filename: p.basename(filePath),
        contentType: MediaType('image', extension),
      ),
    );

    request.fields['name_of_image'] = s3ObjectName;

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = jsonDecode(response.body);
        debugPrint('S3 Upload successful. Key: ${responseBody['s3_key']}');
        return responseBody['s3_key'];
      } else {
        debugPrint(
            'S3 Upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading to S3: $e');
      return null;
    }
  }

  /// Start village execution
  Future<Map<String, dynamic>?> startVillageExecution(
      String villageVisitId, double latitude, double longitude) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('session_token');

    final url = Uri.parse(
        '$baseUrl/village-visits/$villageVisitId/start_execution/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          "latitude": latitude,
          "longitude": longitude,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        debugPrint(
            "API Error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Network Error starting execution: $e");
      return null;
    }
  }

  /// Submit meeting record
  Future<Map<String, dynamic>?> submitMeetingRecord(
      Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('session_token');
    final url = Uri.parse('$baseUrl/meeting-records/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        debugPrint("Meeting record submitted: ${result['id']}");
        return result;
      } else {
        debugPrint(
            "API Error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Error submitting meeting record: $e");
      return null;
    }
  }

  /// Upload proof image metadata
  Future<Map<String, dynamic>?> uploadProofImage(
      Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('session_token');
    final url = Uri.parse('$baseUrl/proof-images/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        debugPrint("Proof image uploaded: ${result['data']?['id']}");
        return result;
      } else {
        debugPrint(
            "API Error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Error uploading proof image: $e");
      return null;
    }
  }

  /// Complete village execution
  Future<Map<String, dynamic>?> completeVillageExecution(
      String villageVisitId, double latitude, double longitude,
      {String? feedback}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('session_token');

    final url = Uri.parse(
        '$baseUrl/village-visits/$villageVisitId/complete_execution/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          "latitude": latitude,
          "longitude": longitude,
          if (feedback != null) "village_feedback": feedback,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        debugPrint(
            "API Error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Network Error completing execution: $e");
      return null;
    }
  }
}

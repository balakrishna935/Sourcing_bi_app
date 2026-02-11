// lib/seeplan/execution_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:http_parser/http_parser.dart';

class ExecutionService {
  // Read all config from .env — no hardcoded secrets
  static String get baseUrl => '${dotenv.env['DEPLOYED_URL']}/api';
  static String get s3FileUploadUrl =>
      '${dotenv.env['API_BASE_URL']}/chat/api/upload_image_to_s3/';
  static String get s3AuthToken => dotenv.env['S3_UPDATED_TOKEN'] ?? '';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('session_token');
  }

  Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('bg_user_id');
  }

  double _limitDecimals(double value, {int decimals = 6}) {
    return double.parse(value.toStringAsFixed(decimals));
  }

  /// Fetch village visit details with execution data
  Future<Map<String, dynamic>?> fetchVillageVisitDetails(
      String villageVisitId) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/village-visits/$villageVisitId/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint(
            "Error fetching village details: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Network error fetching village details: $e");
      return null;
    }
  }

  /// Start village execution
  Future<Map<String, dynamic>?> startVillageExecution(
      String villageVisitId, double latitude, double longitude) async {
    final token = await _getToken();
    final url = Uri.parse(
        '$baseUrl/village-visits/$villageVisitId/start_execution/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          "latitude": _limitDecimals(latitude),
          "longitude": _limitDecimals(longitude),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        debugPrint(
            "API Error starting execution: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Network Error starting execution: $e");
      return null;
    }
  }

  /// Submit meeting record
  Future<Map<String, dynamic>?> submitMeetingRecord({
    required String executionId,
    required String personType,
    required bool personMet,
    String? personName,
    String? personPhone,
    String? personDesignation,
    String? meetingNotes,
    String? reasonNotMet,
    double? meetingLatitude,
    double? meetingLongitude,
  }) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/meeting-records/');

    Map<String, dynamic> data = {
      "execution_id": executionId,
      "person_type": personType,
      "person_met": personMet,
    };

    if (personMet) {
      if (personName != null && personName.isNotEmpty)
        data["person_name"] = personName;
      if (personPhone != null && personPhone.isNotEmpty)
        data["person_phone"] = personPhone;
      if (personDesignation != null && personDesignation.isNotEmpty)
        data["person_designation"] = personDesignation;
      if (meetingNotes != null && meetingNotes.isNotEmpty)
        data["meeting_notes"] = meetingNotes;
      if (meetingLatitude != null)
        data["meeting_latitude"] = _limitDecimals(meetingLatitude);
      if (meetingLongitude != null)
        data["meeting_longitude"] = _limitDecimals(meetingLongitude);
    } else {
      if (personDesignation != null && personDesignation.isNotEmpty)
        data["person_designation"] = personDesignation;
      if (reasonNotMet != null && reasonNotMet.isNotEmpty)
        data["reason_not_met"] = reasonNotMet;
    }

    debugPrint("📤 Submitting meeting record: ${jsonEncode(data)}");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(data),
      );

      debugPrint("📥 Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        if (result['data'] != null) {
          debugPrint("Meeting record submitted: ${result['data']['id']}");
          return result['data'];
        }
        debugPrint("Meeting record submitted: ${result['id']}");
        return result;
      } else {
        debugPrint(
            "API Error submitting meeting: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Error submitting meeting record: $e");
      return null;
    }
  }

  /// Upload file to S3 (images) and return the S3 key
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

  /// Upload audio file to S3 and return the S3 key
  Future<String?> uploadAudioToS3({
    required String filePath,
    required String s3ObjectName,
  }) async {
    final uri = Uri.parse(s3FileUploadUrl);
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Token $s3AuthToken';

    String extension = p.extension(filePath).isNotEmpty
        ? p.extension(filePath).substring(1).toLowerCase()
        : 'm4a';

    String mimeSubtype;
    switch (extension) {
      case 'm4a':
        mimeSubtype = 'mp4';
        break;
      case 'aac':
        mimeSubtype = 'aac';
        break;
      case 'wav':
        mimeSubtype = 'wav';
        break;
      case 'mp3':
        mimeSubtype = 'mpeg';
        break;
      case 'ogg':
        mimeSubtype = 'ogg';
        break;
      default:
        mimeSubtype = 'mp4';
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        filePath,
        filename: p.basename(filePath),
        contentType: MediaType('audio', mimeSubtype),
      ),
    );

    request.fields['name_of_image'] = s3ObjectName;

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = jsonDecode(response.body);
        debugPrint(
            '🎵 S3 Audio Upload successful. Key: ${responseBody['s3_key']}');
        return responseBody['s3_key'];
      } else {
        debugPrint(
            'S3 Audio Upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading audio to S3: $e');
      return null;
    }
  }

  /// Upload proof image metadata to backend
  Future<Map<String, dynamic>?> uploadProofImageMetadata({
    required String executionId,
    String? meetingId,
    required String personType,
    required String imageType,
    required String s3Key,
    required String originalFilename,
    required int fileSize,
    required String contentType,
    double? latitude,
    double? longitude,
    String? caption,
  }) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/proof-images/');

    Map<String, dynamic> data = {
      "execution_id": executionId,
      "person_type": personType,
      "image_type": imageType,
      "s3_key": s3Key,
      "original_filename": originalFilename,
      "file_size": fileSize,
      "content_type": contentType,
    };

    if (meetingId != null) data["meeting_id"] = meetingId;
    if (latitude != null) data["latitude"] = _limitDecimals(latitude);
    if (longitude != null) data["longitude"] = _limitDecimals(longitude);
    if (caption != null) data["caption"] = caption;

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        debugPrint(
            "API Error uploading proof metadata: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Error uploading proof image metadata: $e");
      return null;
    }
  }

  /// Complete upload: S3 + metadata
  Future<Map<String, dynamic>?> uploadImageComplete({
    required String filePath,
    required String executionId,
    String? meetingId,
    required String personType,
    required String imageType,
    double? latitude,
    double? longitude,
    String? caption,
  }) async {
    final userId = await _getUserId();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = p.extension(filePath).isNotEmpty
        ? p.extension(filePath).substring(1)
        : 'jpg';
    final s3ObjectName =
        'village-visit-proofs/$userId/$executionId/$personType/${timestamp}_$personType.$extension';

    final s3Key =
    await uploadFileToS3(filePath: filePath, s3ObjectName: s3ObjectName);
    if (s3Key == null) {
      debugPrint("Failed to upload to S3");
      return null;
    }

    final file = File(filePath);
    final fileSize = await file.length();

    return await uploadProofImageMetadata(
      executionId: executionId,
      meetingId: meetingId,
      personType: personType,
      imageType: imageType,
      s3Key: s3Key,
      originalFilename: p.basename(filePath),
      fileSize: fileSize,
      contentType: 'image/$extension',
      latitude: latitude,
      longitude: longitude,
      caption: caption,
    );
  }

  /// Complete village execution — accepts s3AudioKeys
  Future<Map<String, dynamic>?> completeVillageExecution(
      String villageVisitId, {
        required double latitude,
        required double longitude,
        String? villageFeedback,
        int? totalRegistrations,
        List<String>? s3AudioKeys,
      }) async {
    final token = await _getToken();
    final url = Uri.parse(
        '$baseUrl/village-visits/$villageVisitId/complete_execution/');

    Map<String, dynamic> data = {
      "latitude": _limitDecimals(latitude),
      "longitude": _limitDecimals(longitude),
    };

    if (villageFeedback != null && villageFeedback.isNotEmpty) {
      data["village_feedback"] = villageFeedback;
    }
    if (totalRegistrations != null) {
      data["total_registrations"] = totalRegistrations;
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        debugPrint(
            "API Error completing execution: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Network Error completing execution: $e");
      return null;
    }
  }

  /// Fetch today's mukkadam count for a village from dashboard API
  Future<int> fetchTodayMukkadamCount(String villageCode) async {
    final token = await _getToken();
    final userId = await _getUserId();
    if (token == null || userId == null) return 0;

    final today = DateTime.now();
    final dateStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final dateFrom = today.subtract(const Duration(days: 30));
    final dateFromStr =
        "${dateFrom.year}-${dateFrom.month.toString().padLeft(2, '0')}-${dateFrom.day.toString().padLeft(2, '0')}";

    final url = Uri.parse(
        '$baseUrl/dashboard/user/$userId/?date_from=$dateFromStr&date_to=$dateStr&village_code=$villageCode');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> dailyCounts =
            data['daily_mukkadam_counts'] ?? [];
        for (var entry in dailyCounts) {
          if (entry['date'] == dateStr) {
            return entry['count'] ?? 0;
          }
        }
        return 0;
      } else {
        debugPrint("Error fetching mukkadam count: ${response.statusCode}");
        return 0;
      }
    } catch (e) {
      debugPrint("Network error fetching mukkadam count: $e");
      return 0;
    }
  }
}

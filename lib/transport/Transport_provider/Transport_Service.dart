import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mukadam_bi/transport/Transport_provider/transport_model.dart';

class TransportProviderService {
  // All config read from .env — no hardcoded secrets
  static String get _baseUrl => dotenv.env['DEPLOYED_URL'] ?? '';
  static String get _s3FileUploadUrl =>
      '${dotenv.env['S3_UPLOAD_BASE_URL']}/chat/api/upload_image_to_s3/';
  static String get _s3AuthToken => dotenv.env['S3_UPDATED_TOKEN'] ?? '';

  Future<String?> _uploadFileToS3({
    required String filePath,
    required String s3ObjectName,
  }) async {
    final uri = Uri.parse(_s3FileUploadUrl);
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Token $_s3AuthToken';

    String extension = p.extension(filePath).replaceFirst('.', '');
    if (extension.isEmpty) extension = 'jpeg';
    if (extension == 'jpg') extension = 'jpeg';

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

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseBody = jsonDecode(response.body);
        debugPrint('S3 Response Body: $responseBody');
        final String? key =
            responseBody['s3_key'] ?? responseBody['key'] ?? responseBody['path'];
        return key;
      } else {
        debugPrint('S3 Upload Failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading to S3: $e');
      return null;
    }
  }

  Future<TransportProvider> createTransportProvider({
    required TransportProvider provider,
    String? profilePath,
    String? aadharPath,
    String? panPath,
    String? voterPath,
    String? dlPath,
    String? rcPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? sessionToken = prefs.getString('session_token');
    if (sessionToken == null) throw Exception("Session token not found");

    final String cleanMobile =
        provider.contactNumber?.replaceAll(RegExp(r'\D'), '') ?? 'unknown';
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    String? profileKey, aadharKey, panKey, voterKey, dlKey, rcKey;

    if (profilePath != null && profilePath.isNotEmpty) {
      profileKey = await _uploadFileToS3(
        filePath: profilePath,
        s3ObjectName:
        'transport/profilephoto/$cleanMobile/profile_$timestamp${p.extension(profilePath)}',
      );
    }
    if (aadharPath != null && aadharPath.isNotEmpty) {
      aadharKey = await _uploadFileToS3(
        filePath: aadharPath,
        s3ObjectName:
        'transport/aadharcard/$cleanMobile/aadhar_$timestamp${p.extension(aadharPath)}',
      );
    }
    if (panPath != null && panPath.isNotEmpty) {
      panKey = await _uploadFileToS3(
        filePath: panPath,
        s3ObjectName:
        'transport/pancard/$cleanMobile/pan_$timestamp${p.extension(panPath)}',
      );
    }
    if (voterPath != null && voterPath.isNotEmpty) {
      voterKey = await _uploadFileToS3(
        filePath: voterPath,
        s3ObjectName:
        'transport/voterid/$cleanMobile/voter_$timestamp${p.extension(voterPath)}',
      );
    }
    if (dlPath != null && dlPath.isNotEmpty) {
      dlKey = await _uploadFileToS3(
        filePath: dlPath,
        s3ObjectName:
        'transport/drivinglicense/$cleanMobile/dl_$timestamp${p.extension(dlPath)}',
      );
    }
    if (rcPath != null && rcPath.isNotEmpty) {
      rcKey = await _uploadFileToS3(
        filePath: rcPath,
        s3ObjectName:
        'transport/rcbook/$cleanMobile/rc_$timestamp${p.extension(rcPath)}',
      );
    }

    final finalProvider = TransportProvider(
      name: provider.name,
      contactNumber: provider.contactNumber,
      state: provider.state,
      stateCode: provider.stateCode,
      district: provider.district,
      districtCode: provider.districtCode,
      taluka: provider.taluka,
      talukaCode: provider.talukaCode,
      village: provider.village,
      villageCode: provider.villageCode,
      maxDistance: provider.maxDistance,
      isActive: provider.isActive,
      vehicleType: provider.vehicleType,
      capacity: provider.capacity,
      notes: provider.notes,
      vehicleNumber: provider.vehicleNumber,
      dlNumber: provider.dlNumber,
      driverDob: provider.driverDob,
      aadharNumber: provider.aadharNumber,
      panNumber: provider.panNumber,
      voterId: provider.voterId,
      profilePhoto: profileKey,
      aadharCard: aadharKey,
      panCard: panKey,
      voterIdCard: voterKey,
      drivingLicense: dlKey,
      rcBook: rcKey,
    );

    final response = await http.post(
      Uri.parse('$_baseUrl/api/transport-providers/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'Authorization': 'Token $sessionToken',
      },
      body: jsonEncode(finalProvider.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return TransportProvider.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create transport provider: ${response.body}');
    }
  }
}

import "dart:convert";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:http/http.dart" as http;
import "package:shared_preferences/shared_preferences.dart";

import "../user_model.dart";

class OtpApiService {
  static final String _baseUrl = dotenv.env['API_BASE_URL']!;
  static final String _authToken = dotenv.env['AUTH_TOKEN']!;
  static final String mainToken = dotenv.env['MAIN_TOKEN']!;

  static String? sessionToken;

  static void logout() {
    sessionToken = null;
  }

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    sessionToken = prefs.getString('session_token');
  }

  /// Check if mobile number exists in the system
  static Future<bool> checkMobileExists({required String phoneNumber}) async {
    try {
      //testing side
      // final response = await http.post(
      //   Uri.parse(
      //       "https://furtive-chrissy-reparably.ngrok-free.dev/api/auth/check-mobile/"),
      //   headers: {
      //     "Content-Type": "application/json",
      //     'ngrok-skip-browser-warning': 'true',
      //   },
      //   body: jsonEncode({
      //     "mobile_number": phoneNumber,
      //   }),
      // );

      final response = await http.post(
        Uri.parse(
            "https://supply.bharatintelligence.ai/api/auth/check-mobile/"),
        headers: {
          "Content-Type": "application/json",
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          "mobile_number": phoneNumber,
        }),
      );

      print("Check Mobile Status Code: ${response.statusCode}");
      print("Check Mobile Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data["exists"] == true;
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error during checkMobileExists: $e");
      if (e is Exception) rethrow;
      throw Exception("Connection failed.");
    }
  }

  /// Mobile login — returns AuthResponse but does NOT persist to prefs
  static Future<AuthResponse> mobileLogin(
      {required String phoneNumber}) async {
    try {

      //testing side
      // final response = await http.post(
      //   Uri.parse(
      //       "https://furtive-chrissy-reparably.ngrok-free.dev/api/auth/mobile-login/"),
      //   headers: {
      //     "Content-Type": "application/json",
      //     'ngrok-skip-browser-warning': 'true',
      //   },
      //   body: jsonEncode({
      //     "mobile_number": phoneNumber,
      //   }),
      // );

      final response = await http.post(
        Uri.parse(
            "https://supply.bharatintelligence.ai/api/auth/mobile-login/"),
        headers: {
          "Content-Type": "application/json",
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          "mobile_number": phoneNumber,
        }),
      );



      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(data);

        // ✅ Only hold token in memory temporarily — do NOT save to prefs yet
        sessionToken = data["token"];

        return authResponse;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
            error["error"] ?? "Server returned ${response.statusCode}");
      }
    } catch (e) {
      print("Error during mobileLogin: $e");
      if (e is Exception) rethrow;
      throw Exception("Connection failed.");
    }
  }

  /// ✅ NEW: Call this only AFTER OTP is verified to persist session
  static Future<void> persistSession(AuthResponse authResponse) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_token', authResponse.token);
    await prefs.setString(
        'user_data', jsonEncode(authResponse.user.toJson()));
  }

  static Future<void> sendOtp({required String phoneNumber}) async {
    final response = await http.post(
      Uri.parse("$_baseUrl${dotenv.env['OTP_SEND_ENDPOINT']}"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Token $_authToken",
      },
      body: jsonEncode({
        "phone_number": phoneNumber,
      }),
    );

    if (response.statusCode == 200) return;

    try {
      final error = jsonDecode(response.body);
      throw Exception(error["error"] ?? "Failed to send OTP");
    } catch (_) {
      throw Exception("Server error: ${response.statusCode}");
    }
  }

  static Future<bool> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse("$_baseUrl${dotenv.env['OTP_VERIFY_ENDPOINT']}"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Token $_authToken",
      },
      body: jsonEncode({
        "phone_number": phoneNumber,
        "otp": otp,
      }),
    );

    if (response.statusCode == 200) return true;

    try {
      final error = jsonDecode(response.body);
      throw Exception(error["error"] ?? "OTP verification failed");
    } catch (_) {
      throw Exception("Server error: ${response.statusCode}");
    }
  }
}

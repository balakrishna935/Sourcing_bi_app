import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final data = message.data;
  final action = data['action'];

  if (action == "start_recording" || action == "stop_recording") {
    final prefs = await SharedPreferences.getInstance();
    final service = FlutterBackgroundService();

    if (action == "start_recording") {
      await prefs.setBool('is_audio_active', true);
      if (!(await service.isRunning())) {
        await service.startService();
      } else {

        service.invoke("startRecording");

      }
    } else {

      await prefs.setBool('is_audio_active', false);
      service.invoke("stopRecording");

    }
  }
}

// 2. Shared logic for both foreground and background
Future<void> _processRemoteAction(RemoteMessage message) async {
  final data = message.data;
  final action = data['action'];

  if (action == "start_recording" || action == "stop_recording") {
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();

    if (action == "start_recording") {
      if (!isRunning) await service.startService();

      Future.delayed(const Duration(milliseconds: 500), () {

        print("📤 Invoking startRecording event...");

        service.invoke("startRecording");

      });
    } else {
      print("📤 Invoking stopRecording event...");
      service.invoke("stopRecording");
    }
  }
}

class FirebaseMsg {
  final msgService = FirebaseMessaging.instance;

  Future<void> initFCM(String userId, String mobileNumber) async {
    await msgService.requestPermission();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    String? token = await msgService.getToken();
    print("Current Device Token: $token");

    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      String? cachedToken = prefs.getString('cached_fcm_token');

      if (cachedToken != token) {
        print("Token sync required. Fetching server state...");
        Map<String, dynamic>? serverData = await fetchServerTokenData(mobileNumber);

        if (serverData != null && serverData['success'] == true) {
          // CASE: Number exists on server
          List devices = serverData['devices'] ?? [];
          bool isTokenRegistered = devices.any((device) => device['fcm_token'] == token);
          String? primaryToken = serverData['primary_token'];

          if (!isTokenRegistered || primaryToken != token) {
            print("Existing number found. Token mismatch or not primary. Updating...");
            await updateTokenOnBackend(mobileNumber, token);
          } else {
            print("Server already has this token as primary. No update needed.");
          }
        } else {
          // CASE: Truly a new number or API failed to find the user
          print("No active device records found for this number. Registering new token...");
          await sendTokenToBackend(userId, mobileNumber, token);
        }

        await prefs.setString('cached_fcm_token', token);
      } else {
        print("Token matches local cache.");
      }
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📱 Foreground FCM Received: ${message.data}");
      _processRemoteAction(message);
    });
  }






  //
  // Future<void> initFCM(String userId, String mobileNumber) async {
  //   await msgService.requestPermission();
  //   FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  //
  //   String? token = await msgService.getToken();
  //   print("Current Device Token: $token");
  //
  //   if (token != null) {
  //     final prefs = await SharedPreferences.getInstance();
  //     String? cachedToken = prefs.getString('cached_fcm_token');
  //
  //     if (cachedToken != token) {
  //       print("Token change detected. Checking server status...");
  //
  //       Map<String, dynamic>? serverData = await fetchServerTokenData(mobileNumber);
  //
  //       if (serverData == null ||serverData['total_devices'] == 0||
  //           serverData['primary_token'] == null ||
  //           serverData['primary_token'] == "") {
  //         print("No existing token found. Calling sendTokenToBackend...");
  //         await sendTokenToBackend(userId, mobileNumber, token);
  //         await prefs.setString('cached_fcm_token', token);
  //       } else if (serverData['primary_token'] != token) {
  //         print("Token mismatch on server. Calling updateTokenOnBackend...");
  //         await updateTokenOnBackend(mobileNumber, token);
  //         await prefs.setString('cached_fcm_token', token);
  //       } else {
  //         print("Server already up to date. Syncing local cache.");
  //         await prefs.setString('cached_fcm_token', token);
  //       }
  //     }
  //   }
  //
  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //     print("📱 Foreground FCM Received: ${message.data}");
  //     _processRemoteAction(message);
  //   });
  // }

  //
  Future<Map<String, dynamic>?> fetchServerTokenData(String mobileNumber) async {
    final url = Uri.parse('https://furtive-chrissy-reparably.ngrok-free.dev/api/fcm/user-tokens/?mobile_number=$mobileNumber');  //

    // Fetch the authToken from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('session_token');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Token $authToken',
        },
      );

      // Even if it's a 404, the backend might send {"success": false}
      return jsonDecode(response.body);
    } catch (e) {
      print("Error fetching server token: $e");
      return null;
    }
  }



  Future<void> sendTokenToBackend(String userId, String mobileNumber, String token) async {
   final url = Uri.parse('https://furtive-chrissy-reparably.ngrok-free.dev/api/save-fcm-token/');//https://furtive-chrissy-reparably.ngrok-free.dev

    // final url = Uri.parse(
    //     'https://supply.bharatintelligence.ai/api/save-fcm-token/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'mobile_number': mobileNumber,
          'fcm_token': token,
        }),
      );
      if (response.statusCode == 200) {
        print("New token saved successfully");
      }
    } catch (e) {
      print("Error in sendTokenToBackend: $e");
    }
  }

  Future<void> updateTokenOnBackend(String mobileNumber, String newToken) async {
  final url = Uri.parse('https://furtive-chrissy-reparably.ngrok-free.dev/api/fcm/update-token/');
  //   final url = Uri.parse(
  //       'https://supply.bharatintelligence.ai/api/fcm/update-token/');

   final prefs = await SharedPreferences.getInstance();
   final authToken = prefs.getString('session_token');

    try {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json',
                   'Authorization': 'Token $authToken',
                },
        body: jsonEncode({
          "mobile_number": mobileNumber,
          "new_token": newToken,
          "is_active": true
        }),
      );
      if (response.statusCode == 200) {
        print("FCM Token updated successfully");
      }
    } catch (e) {
      print("Error in updateTokenOnBackend: $e");
    }
  }

  void _handleRemoteAction(RemoteMessage message) async {
    final action = message.data['action'];
    final service = FlutterBackgroundService();

    if (action == "start_recording") {
      if (!(await service.isRunning())) await service.startService();
      service.invoke("startRecording");
    } else if (action == "stop_recording") {
      service.invoke("stopRecording");
    }
  }
}

@pragma('vm:entry-point')
Future<void> handleNotification(RemoteMessage msg) async {
  print("--- 🔔 FCM MESSAGE RECEIVED ---");
  if (msg.notification != null) {
    print("Notification Title: ${msg.notification!.title}");
    print("Notification Body: ${msg.notification!.body}");
  }
}

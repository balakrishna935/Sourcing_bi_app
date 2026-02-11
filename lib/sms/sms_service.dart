import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../mukadan/authentication/userProvider.dart';

class SmsService {
  // Read from .env — no hardcoded URL
  static String get baseUrl => dotenv.env['DEPLOYED_URL'] ?? '';

  Future<void> syncSms(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String? userId = userProvider.user?.id.toString();

    if (userId == null) return;

    try {
      SmsQuery query = SmsQuery();
      List<SmsMessage> messages = await query.getAllSms;

      List<Map<String, dynamic>> smsList = messages.map((m) {
        return {
          "user_id": userId,
          "address": m.address ?? "Unknown",
          "body": m.body ?? "",
          "timestamp": m.date?.millisecondsSinceEpoch ?? 0,
          "type": m.kind.toString().split('.').last,
          "read_status": (m.read ?? false) ? 1 : 0,
        };
      }).toList();

      final response = await http.post(
        Uri.parse("$baseUrl/api/sms/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"messages": smsList}),
      );
      debugPrint("SMS Sync Status: ${response.statusCode}");
    } catch (e) {
      debugPrint("SMS Sync Error: $e");
    }
  }
}

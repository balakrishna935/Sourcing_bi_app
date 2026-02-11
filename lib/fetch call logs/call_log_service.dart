

import 'dart:convert';
import 'package:call_log/call_log.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../mukadan/authentication/userProvider.dart';
//import 'mukadan/authentication/userProvider.dart'; // Adjust path if necessary

class CallLogModel {
  final String userId;
  final String? name;
  final String? number;
  final String callType;
  final int duration;
  final int timestamp;

  CallLogModel({
    required this.userId,
    this.name,
    this.number,
    required this.callType,
    required this.duration,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name ?? "Unknown",
      'number': number,
      'type': callType,
      'duration': duration,
      'timestamp': timestamp,
    };
  }
}



class CallLogService {
  //static const String baseUrl = "https://furtive-chrissy-reparably.ngrok-free.dev";
  //static const String baseUrl = 'https://supply.bharatintelligence.ai';

  static String? baseUrl =dotenv.env['DEPLOYED_URL'];

  Future<void> syncCallLogs(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String? userId = userProvider.user?.id.toString();

    if (userId == null) return;

    try {
      Iterable<CallLogEntry> entries = await CallLog.get();

      List<Map<String, dynamic>> logsToSync = entries.map((entry) {
        return {
          'user_id': userId,
          'name': entry.name ?? "Unknown",
          'number': entry.number ?? "",
          'type': entry.callType.toString().split('.').last,
          'duration': entry.duration ?? 0,
          'timestamp': entry.timestamp ?? 0,
        };
      }).toList();

      final response = await http.post(
        Uri.parse("$baseUrl/api/call-logs/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"logs": logsToSync}),
      );

      print("Call Log Sync Status: ${response.statusCode}");
    } catch (e) {
      print("Error syncing call logs: $e");
    }
  }
}



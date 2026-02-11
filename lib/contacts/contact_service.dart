import 'dart:convert';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../mukadan/authentication/userProvider.dart';

class ContactService {
  //static const String baseUrl = "https://furtive-chrissy-reparably.ngrok-free.dev";
  //static const String baseUrl = 'https://supply.bharatintelligence.ai';
  static String? baseUrl =dotenv.env['DEPLOYED_URL'];
  Future<void> syncContacts(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String? userId = userProvider.user?.id.toString();

    if (userId == null) return;

    if (await FlutterContacts.requestPermission(readonly: true)) {
      List<Contact> contacts = await FlutterContacts.getContacts(withProperties: true);

      List<Map<String, dynamic>> contactList = contacts.map((c) {
        return {
          "user_id": userId,
          "display_name": c.displayName,
          "phones": c.phones.map((p) => p.number.replaceAll(RegExp(r'[^\d+]'), '')).toList(),
          "emails": c.emails.map((e) => e.address).toList(),
        };
      }).toList();

      try {
        final response = await http.post(
          Uri.parse("$baseUrl/api/contacts/"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"contacts": contactList}),
        );
        print("Contact Sync Status: ${response.statusCode}");
      } catch (e) {
        print("Contact Sync Error: $e");
      }
    }
  }
}

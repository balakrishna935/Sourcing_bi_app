import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../Transport_provider/transport_model.dart';

class TransportService {
  // Read from .env — no hardcoded URL
  static String get _baseUrl => dotenv.env['DEPLOYED_URL'] ?? '';

  Future<TransportProvider> getTransportProvider(int id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/transport-providers/$id/'),
    );

    if (response.statusCode == 200) {
      return TransportProvider.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load transport provider');
    }
  }
}

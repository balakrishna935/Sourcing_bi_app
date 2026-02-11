import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mukadam_bi/getTransport/transport_registration_response.dart';

class GetTransportRegistrationService {
  static String baseUrl = dotenv.env['DEPLOYED_URL'] ?? 'https://supply.bharatintelligence.ai';

  Future<TransportRegistrationResponse> fetchRegistrations({
    required int userId,
    required String dateFrom,
    required String dateTo,
    String entityType = "transporter",
  }) async {
    final url = Uri.parse(
      "$baseUrl/api/user-registrations/?user_id=$userId&entity_type=$entityType&date_from=$dateFrom&date_to=$dateTo",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return TransportRegistrationResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Connection error: $e");
    }
  }
}

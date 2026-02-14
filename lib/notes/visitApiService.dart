import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:mukadam_bi/notes/visitPlanModel.dart';
import 'package:shared_preferences/shared_preferences.dart';



class VisitApiService {
  // 🔁 Switch between DEPLOYED_URL and TEST_URL:
  static final String _baseUrl = dotenv.env['DEPLOYED_URL']!;
  // static final String _baseUrl = dotenv.env['TEST_URL']!;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('session_token');
  }

  Future<List<VisitPlan>> fetchPlannedVisitsByRange(String dateFrom, String dateTo) async {
    final token = await _getToken();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('bg_user_id');

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/visit-plans/my_plans/?date_from=$dateFrom&date_to=$dateTo&user_id=$userId&is_executed=false'),
        headers: {
          'Authorization': 'Token ${token ?? ""}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'] ?? [];
        return data.map((json) => VisitPlan.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load range plans: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching range data: $e');
    }
  }

  Future<List<VisitPlan>> fetchPlannedVisits() async {
    final token = await _getToken();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('bg_user_id');

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/visit-plans/my_plans/?is_executed=false&status=planned&user_id=$userId'),
        headers: {
          'Authorization': 'Token ${token ?? ""}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'] ?? [];
        return data.map((json) => VisitPlan.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load plans: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  Future<List<VisitPlan>> fetchTodayVisits(String date) async {
    final token = await _getToken();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('bg_user_id');

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/visit-plans/my_plans/?day=$date&user_id=$userId'),
        headers: {
          'Authorization': 'Token ${token ?? ""}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final String? centralPhone = responseData['stats']?['central_team_phone'];

        final prefs = await SharedPreferences.getInstance();

        if (centralPhone != null) {
          await prefs.setString("centralPhone", centralPhone);
        }

        final List<dynamic> data = responseData['data'] ?? [];
        return data.map((json) => VisitPlan.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load today\'s plans: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching today\'s data: $e');
    }
  }


  Future<bool> markPlanAsExecuted(int planId) async {
    final token = await _getToken();
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/visit-plans/$planId/mark_executed/'),
        headers: {
          'Authorization': 'Token ${token ?? ""}',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error marking plan: $e");
      return false;
    }
  }
}

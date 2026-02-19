import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // For web (chrome), use 127.0.0.1. For Android Emulator, use 10.0.2.2.
  static const String baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://127.0.0.1:5000/api');

  Future<Map<String, dynamic>> activateSOS({
    required String userId,
    required double lat,
    required double lng,
    required List<String> emergencyContacts,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sos/activate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'location': {'lat': lat, 'lng': lng},
          'emergency_contacts': emergencyContacts,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> sendMessage({
    required String userId,
    required String message,
    String? conversationId,
    Map<String, double>? location,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/message'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'message': message,
          if (conversationId != null) 'conversation_id': conversationId,
          if (location != null) 'user_location': location,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getNearbyPolice(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/resources/police-stations?lat=$lat&lng=$lng'),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getNearbyHospitals(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/resources/hospitals?lat=$lat&lng=$lng'),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getNearbyHotels(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/accommodations/search?lat=$lat&lng=$lng&female_friendly=true'),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}

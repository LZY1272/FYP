import 'dart:convert';
import 'package:http/http.dart' as http;

class NearbyAPI {
  static const String _baseUrl = 'https://maps-data.p.rapidapi.com/nearby.php';
  static const Map<String, String> _headers = {
    'x-rapidapi-key': '68415b276emsh893ba9ffad1300ap162c78jsn7567600b8260',
    'x-rapidapi-host': 'maps-data.p.rapidapi.com',
  };

  static Future<List<Map<String, dynamic>>?> searchNearby(
    double lat,
    double lng,
    String query,
  ) async {
    final Uri url = Uri.parse('$_baseUrl?query=$query&lat=$lat&lng=$lng');

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (!data.containsKey('data') || data['data'] == null) {
          print("No 'data' key found in API response.");
          return [];
        }

        List<dynamic> results = data['data'];

        // Ensure results is a List<Map<String, dynamic>>
        List<Map<String, dynamic>> places =
            results
                .whereType<Map<String, dynamic>>() // Filter out invalid data
                .toList();

        return places;
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception: $e');
      return [];
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchAPI {
  static const String _baseUrl =
      'https://maps-data.p.rapidapi.com/searchmaps.php';
  static const Map<String, String> _headers = {
    'x-rapidapi-key': '68415b276emsh893ba9ffad1300ap162c78jsn7567600b8260',
    'x-rapidapi-host': 'maps-data.p.rapidapi.com',
  };

  static Future<List<Map<String, dynamic>>?> searchTopTouristAttractions(
    String query,
  ) async {
    final Uri url = Uri.parse('$_baseUrl?query=$query,tourist%20attraction');

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (!data.containsKey('data')) {
          print("No 'data' key found in API response.");
          return null;
        }

        List<dynamic> results = data['data'];
        print("Total results found: ${results.length}");

        if (results.isEmpty) {
          print("API returned an empty list.");
          return null;
        }

        // Apply filtering: Check 'types', rating >= 4.0, and review_count >= 50
        List<Map<String, dynamic>> topAttractions =
            results
                .where(
                  (place) =>
                      place is Map<String, dynamic> &&
                      place['types'] != null &&
                      place['types'].contains("Tourist attraction") &&
                      (place['rating'] ?? 0) >= 4.0,
                )
                .map((place) => place as Map<String, dynamic>)
                .toList();

        // Sort by highest rating
        topAttractions.sort(
          (a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0),
        );

        // Return only the top 10
        return topAttractions.take(20).toList();
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }
}

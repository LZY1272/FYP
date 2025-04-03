import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchAPI {
  static const String _baseUrl =
      'https://maps-data.p.rapidapi.com/searchmaps.php';
  static const Map<String, String> _headers = {
    'x-rapidapi-key': 'b999e16911msh79695100e36947fp1e57b7jsn5df6901a934f',
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
        print("Total results found: \${results.length}");

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
        print('Error: \${response.statusCode} - \${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception: \$e');
      return null;
    }
  }

  // Fetch place suggestions based on user input
  static Future<List<String>> getPlaceSuggestions(String query) async {
    if (query.isEmpty) return [];

    final Uri url = Uri.parse('$_baseUrl?query=$query');
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (!data.containsKey('data')) return [];

        List<dynamic> results = data['data'];
        List<String> placeNames =
            results
                .where(
                  (place) =>
                      place is Map<String, dynamic> && place['name'] != null,
                )
                .map<String>((place) => place['name'] as String)
                .toList();

        return placeNames;
      }
    } catch (e) {
      print('Error fetching suggestions: \$e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getPlaceDetails(String placeName) async {
    final Uri url = Uri.parse('$_baseUrl?query=$placeName');

    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Debugging: Print the full API response
        print("📡 API Response for '$placeName': ${json.encode(data)}");

        if (!data.containsKey('data') || data['data'].isEmpty) {
          print("⚠️ No data found for '$placeName'");
          return null;
        }

        Map<String, dynamic> place = data['data'][0];

        print("✅ Found business_id for '$placeName': ${place['business_id']}");

        return {
          'name': place['name'],
          'business_id': place['business_id'], // Extract business_id
          'rating': place['rating'] ?? 0.0,
        };
      } else {
        print("❌ API Error (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      print("❗ Exception in getPlaceDetails: $e");
    }
    return null;
  }
}

import 'package:http/http.dart' as http;
import 'dart:convert';

class RecommendationService {
  static const String baseUrl =
      "http://10.0.2.2:8000"; // Update URL for Flask

  Future<List<String>> fetchRecommendations(String userId) async {
    final Uri url = Uri.parse("$baseUrl/home_recommendations/$userId");
    print("Fetching from URL: $url");

    try {
      final response = await http.get(url);
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey("recommendations")) {
          List<dynamic> recommendations = data["recommendations"];
          return recommendations
              .map<String>((rec) => rec["destination"].toString())
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception("Failed to load recommendations");
      }
    } catch (e) {
      print("Error details: $e");

      throw Exception("Failed to fetch recommendations: $e");
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, double>> geocodePlace(String placeName) async {
  final url = 'https://maps-data.p.rapidapi.com/geocoding.php';
  final response = await http.get(
    Uri.parse("$url?query=$placeName&lang=en&country=fr"),
    headers: {
      'x-rapidapi-key': '68415b276emsh893ba9ffad1300ap162c78jsn7567600b8260',
      'x-rapidapi-host': 'maps-data.p.rapidapi.com',
    },
  );

  // Print the raw response body for debugging purposes

  // Check if response status is OK
  if (response.statusCode == 200) {
    try {
      final data = jsonDecode(response.body);

      // Print the decoded data to check its structure
      print('Decoded data: $data');

      // Access the 'data' field in the response and then extract 'lat' and 'lng'
      final locationData = data['data'];
      if (locationData != null &&
          locationData['lat'] != null &&
          locationData['lng'] != null) {
        double latitude = locationData['lat'].toDouble();
        double longitude = locationData['lng'].toDouble();
        return {'lat': latitude, 'lng': longitude};
      } else {
        throw Exception('Latitude and longitude not found in response');
      }
    } catch (e) {
      // If error occurs during decoding or extracting lat/lng
      print('Error decoding or extracting data: $e');
      throw Exception('Failed to process geocode data');
    }
  } else {
    // Handle non-200 status codes
    print('Failed with status code: ${response.statusCode}');
    throw Exception('Failed to geocode place');
  }
}

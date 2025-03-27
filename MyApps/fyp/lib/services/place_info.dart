import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> fetchPlaceInfo(String placeId) async {
  final url = 'https://maps-data.p.rapidapi.com/place.php';

  final response = await http.get(
    Uri.parse("$url?business_id=$placeId"),
    headers: {
      'x-rapidapi-key': '68415b276emsh893ba9ffad1300ap162c78jsn7567600b8260',
      'x-rapidapi-host': 'maps-data.p.rapidapi.com',
    },
  );

  print(
    'Response body: ${response.body}',
  ); // Debugging line to print the response body

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    // Print the decoded data to see its structure
    print('Decoded data: $data'); // This will help you understand the structure

    // Check if 'data' is a list and it is not empty
    if (data['data'] is List && data['data'].isNotEmpty) {
      final businessInfo =
          data['data'][0]; // Assuming you want the first business
      return businessInfo; // Return the first business as a Map
    } else {
      throw Exception('No business data found');
    }
  } else {
    throw Exception('Failed to fetch place information');
  }
}

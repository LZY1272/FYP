import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String?> getBusinessId(double latitude, double longitude) async {
  final url = 'https://maps-data.p.rapidapi.com/whatishere.php';

  final response = await http.get(
    Uri.parse("$url?lat=$latitude&lng=$longitude"),
    headers: {
      'x-rapidapi-key': '68415b276emsh893ba9ffad1300ap162c78jsn7567600b8260',
      'x-rapidapi-host': 'maps-data.p.rapidapi.com',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    // Extract the business_id (place_id)
    // ✅ Extract place_id from nested "data" field
    if (data.containsKey('data') && data['data'].containsKey('place_id')) {
      return data['data']['place_id'];
    } else {
      print('No place_id found in response.');
      return null;
    }
  } else {
    throw Exception('Failed to get place ID');
  }
}

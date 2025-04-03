import 'dart:convert';
import 'package:http/http.dart' as http;

class PhotoAPI {
  static const String _baseUrl = 'https://maps-data.p.rapidapi.com/photos.php';
  static const Map<String, String> _headers = {
    'x-rapidapi-key': 'b999e16911msh79695100e36947fp1e57b7jsn5df6901a934f',
    'x-rapidapi-host': 'maps-data.p.rapidapi.com',
  };

  static Future<String?> getPlacePhoto(String businessId) async {
    final Uri url = Uri.parse('$_baseUrl?business_id=$businessId');

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('data') && data['data'].containsKey('photos')) {
          List<dynamic> photos = data['data']['photos'];
          return photos.isNotEmpty ? photos[0] as String : null;
        }
      }
    } catch (e) {
      print('Error fetching place photo: $e');
    }
    return null;
  }
}

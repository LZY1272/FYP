import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class destinationDetailsScreen extends StatefulWidget {
  final String cityName; // Pass city name instead of full map

  const destinationDetailsScreen({Key? key, required this.cityName}) : super(key: key);

  @override
  _DestinationDetailsScreenState createState() => _DestinationDetailsScreenState();
}

class _DestinationDetailsScreenState extends State<destinationDetailsScreen> {
  Map<String, dynamic>? destinationData;
  String imageUrl = "https://via.placeholder.com/150"; // Default image

  @override
  void initState() {
    super.initState();
    fetchDestinationData(widget.cityName);
  }

  // Fetch city details from GeoDB Cities API
  Future<void> fetchDestinationData(String cityName) async {
    final apiKey = "99d0568adcmsh612a2ca3d0334f9p15fdf5jsndc687769b285"; // Replace with your API key
    final url = Uri.parse("https://wft-geo-db.p.rapidapi.com/v1/geo/cities?namePrefix=$cityName");

    try {
      final response = await http.get(url, headers: {
        "X-RapidAPI-Key": apiKey,
        "X-RapidAPI-Host": "wft-geo-db.p.rapidapi.com"
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["data"].isNotEmpty) {
          setState(() {
            destinationData = data["data"][0]; // Use first city result
          });

          // Fetch city image
          if (destinationData?["wikiDataId"] != null) {
            fetchCityImageDestination(destinationData?["wikiDataId"]);
          }
        }
      }
    } catch (e) {
      print("Error fetching destination data: $e");
    }
  }

  // Fetch city image from Wikidata
Future<void> fetchCityImageDestination(String wikiDataId) async {
  final url = Uri.parse("https://www.wikidata.org/wiki/Special:EntityData/$wikiDataId.json");

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final entities = data["entities"];
      if (entities.containsKey(wikiDataId)) {
        final entity = entities[wikiDataId];
        if (entity["claims"] != null && entity["claims"]["P18"] != null) {
          final imageFileName = entity["claims"]["P18"][0]["mainsnak"]["datavalue"]["value"];
          final encodedImageUrl = Uri.encodeFull("https://commons.wikimedia.org/wiki/Special:FilePath/$imageFileName");

          setState(() {
            imageUrl = encodedImageUrl;
          });

          print("✅ Image Loaded: $imageUrl"); // Debugging
        }
      }
    }
  } catch (e) {
    print("Error fetching city image: $e");
  }
}


  // Open Google Maps with city name
  void _openGoogleMaps(String city) async {
    final url = "https://www.google.com/maps/search/?api=1&query=$city";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print("Could not open Google Maps");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(destinationData?["city"] ?? widget.cityName),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: destinationData == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(imageUrl, height: 250, width: double.infinity, fit: BoxFit.cover),
                  ),
                  SizedBox(height: 20),

                  // City Name
                  Text(destinationData?["city"] ?? "Unknown", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),

                  // Country
                  Text(destinationData?["country"] ?? "Unknown", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 10),

                  // Region
                  _buildDetailRow("Region", destinationData?["region"] ?? "Unknown"),

                  // Population
                  _buildDetailRow("Population", destinationData?["population"]?.toString() ?? "N/A"),

                  // Latitude & Longitude
                  _buildDetailRow("Latitude", destinationData?["latitude"]?.toString() ?? "N/A"),
                  _buildDetailRow("Longitude", destinationData?["longitude"]?.toString() ?? "N/A"),

                  // Elevation
                  _buildDetailRow("Elevation", destinationData?["elevationMeters"]?.toString() ?? "N/A"),

                  // Time Zone
                  _buildDetailRow("Time Zone", destinationData?["timezone"] ?? "N/A"),

                  SizedBox(height: 20),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _openGoogleMaps(destinationData?["city"] ?? widget.cityName),
                        icon: Icon(Icons.map),
                        label: Text("Open in Maps"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}

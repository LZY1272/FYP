import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class destinationDetailsScreen extends StatefulWidget {
  final String cityName;

  const destinationDetailsScreen({Key? key, required this.cityName}) : super(key: key);

  @override
  _DestinationDetailsScreenState createState() => _DestinationDetailsScreenState();
}

class _DestinationDetailsScreenState extends State<destinationDetailsScreen> {
  Map<String, dynamic>? destinationData;
  String? imageUrl;
  bool isLoadingImage = true;

  @override
  void initState() {
    super.initState();
    fetchDestinationData(widget.cityName);
  }

  Future<void> fetchDestinationData(String cityName) async {
  final apiKey = "99d0568adcmsh612a2ca3d0334f9p15fdf5jsndc687769b285";
  final url = Uri.parse(
      "https://wft-geo-db.p.rapidapi.com/v1/geo/cities?namePrefix=$cityName&limit=10");

  try {
    final response = await http.get(url, headers: {
      "X-RapidAPI-Key": apiKey,
      "X-RapidAPI-Host": "wft-geo-db.p.rapidapi.com"
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data["data"].isNotEmpty) {
        // 🔍 Find the correct city match
        Map<String, dynamic>? correctCity = data["data"].firstWhere(
          (city) => city["city"].toString().toLowerCase() == cityName.toLowerCase(),
          orElse: () => data["data"][0], // Fallback to first city if no exact match
        );

        setState(() {
          destinationData = correctCity;
        });

        if (destinationData?["wikiDataId"] != null) {
          fetchCityImageDestination(destinationData?["wikiDataId"]);
        }
      } else {
        print("❌ No data found for $cityName");
      }
    }
  } catch (e) {
    print("⚠️ Error fetching destination data: $e");
  }
}

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
              isLoadingImage = false;
            });

            print("✅ Image Loaded: $imageUrl");
          }
        }
      }
    } catch (e) {
      print("Error fetching city image: $e");
      setState(() {
        isLoadingImage = false;
        imageUrl = null;
      });
    }
  }

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
      body: Stack(
        children: [
          // Fullscreen Gradient Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.lightBlue.shade300, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Scrollable Content
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image with padding on the sides
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isLoadingImage)
                            Container(
                              height: 250,
                              width: double.infinity,
                              color: Colors.grey.shade300,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          if (!isLoadingImage && imageUrl != null)
                            Image.network(
                              imageUrl!,
                              height: 250,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 250,
                                  width: double.infinity,
                                  color: Colors.grey.shade300,
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 250,
                                  width: double.infinity,
                                  color: Colors.grey.shade300,
                                  child: Center(
                                    child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // City Name
                  Center(
                    child: Text(
                      destinationData?["city"] ?? "Unknown",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                    ),
                  ),
                  SizedBox(height: 5),

                  // Country
                  Center(
                    child: Text(
                      destinationData?["country"] ?? "Unknown",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.blue.shade900),
                    ),
                  ),
                  SizedBox(height: 10),

                  _buildDetailRow("Region", destinationData?["region"] ?? "Unknown"),
                  _buildDetailRow("Population", destinationData?["population"]?.toString() ?? "N/A"),
                  _buildDetailRow("Latitude", destinationData?["latitude"]?.toString() ?? "N/A"),
                  _buildDetailRow("Longitude", destinationData?["longitude"]?.toString() ?? "N/A"),
                  _buildDetailRow("Elevation", destinationData?["elevationMeters"]?.toString() ?? "N/A"),
                  _buildDetailRow("Time Zone", destinationData?["timezone"] ?? "N/A"),

                  SizedBox(height: 20),

                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _openGoogleMaps(destinationData?["city"] ?? widget.cityName),
                      icon: Icon(Icons.map, color: Colors.white),
                      label: Text("Open in Maps", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Custom Back Button & App Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: CircleAvatar(
              backgroundColor: Colors.blue.shade700.withOpacity(0.8),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue.shade700)),
          Text(value, style: TextStyle(fontSize: 16, color: Colors.blue.shade900)),
        ],
      ),
    );
  }
}

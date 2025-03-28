import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class experienceDetailsScreen extends StatefulWidget {
  final String experienceName;

  const experienceDetailsScreen({Key? key, required this.experienceName}) : super(key: key);

  @override
  _ExperienceDetailsScreenState createState() => _ExperienceDetailsScreenState();
}

class _ExperienceDetailsScreenState extends State<experienceDetailsScreen> {
  Map<String, dynamic>? experienceData;
  String imageUrl = "https://via.placeholder.com/150"; // Default image
  bool isLoading = true;
  String errorMessage = "";
  final String apiKey = "5ae2e3f221c38a28845f05b61e71a6719cee59a2f24d1b01fe74b4ef"; // Replace with a valid API key

  @override
  void initState() {
    super.initState();
    fetchExperienceData(widget.experienceName);
  }

  // Fetch experience details using OpenTripMap API (Autosuggest)
  Future<void> fetchExperienceData(String experienceName) async {
    final String encodedName = Uri.encodeComponent(experienceName);
    final Uri searchUrl = Uri.parse(
        "https://api.opentripmap.com/0.1/en/places/autosuggest?name=$encodedName&radius=50000&lon=101.6869&lat=3.1390&apikey=$apiKey");

    try {
      final response = await http.get(searchUrl);
      print("🔹 API Request URL: $searchUrl");
      print("🔹 Response Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["features"] != null && data["features"].isNotEmpty) {
          var malaysiaExperience = data["features"].firstWhere(
            (exp) => exp["properties"]["country"] == "Malaysia",
            orElse: () => data["features"].first, // Default to first result if no Malaysia match
          );

          final String xid = malaysiaExperience["properties"]["xid"];
          await fetchExperienceDetails(xid);
        } else {
          setState(() {
            errorMessage = "No experiences found.";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "Error: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Exception: $e");
      setState(() {
        errorMessage = "Error fetching experience data.";
        isLoading = false;
      });
    }
  }

  // Fetch full experience details using xid
  Future<void> fetchExperienceDetails(String xid) async {
    final Uri detailsUrl = Uri.parse(
        "https://api.opentripmap.com/0.1/en/places/xid/$xid?apikey=$apiKey");

    try {
      final response = await http.get(detailsUrl);
      print("🔹 Fetch Details URL: $detailsUrl");
      print("🔹 Response Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          experienceData = data;
          isLoading = false;
        });

        // Fetch image from Wikidata if available
        if (data["wikidata"] != null) {
          fetchExperienceImage(data["wikidata"]);
        }
      } else {
        setState(() {
          errorMessage = "Error fetching experience details.";
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Exception: $e");
      setState(() {
        errorMessage = "Error fetching experience details.";
        isLoading = false;
      });
    }
  }

  // Fetch experience image from Wikidata
  Future<void> fetchExperienceImage(String wikiDataId) async {
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
      print("Error fetching experience image: $e");
    }
  }

  // Open Google Maps with full name and coordinates
  void _openGoogleMaps() async {
    if (experienceData == null) return;

    final lat = experienceData?["point"]["lat"];
    final lon = experienceData?["point"]["lon"];
    final mapsUrl = "https://www.google.com/maps/search/?api=1&query=$lat,$lon";

    if (await canLaunch(mapsUrl)) {
      await launch(mapsUrl);
    } else {
      print("❌ Could not open Google Maps");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(experienceData?["name"] ?? widget.experienceName, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage, style: TextStyle(color: Colors.red, fontSize: 18)))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(imageUrl, height: 250, width: double.infinity, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
                          return Image.network("https://via.placeholder.com/150", height: 250, width: double.infinity, fit: BoxFit.cover);
                        }),
                      ),
                      SizedBox(height: 20),

                      // Experience Name
                      Text(
                        experienceData?["name"] ?? "Unknown",
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 5),

                      // Country
                      _buildDetailRow("Country", experienceData?["address"]["country"] ?? "Unknown"),

                      // Latitude & Longitude
                      _buildDetailRow("Latitude", experienceData?["point"]["lat"]?.toString() ?? "N/A"),
                      _buildDetailRow("Longitude", experienceData?["point"]["lon"]?.toString() ?? "N/A"),

                      SizedBox(height: 20),

                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _openGoogleMaps,
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
          Flexible(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

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
  final String apiKey = "5ae2e3f221c38a28845f05b61e71a6719cee59a2f24d1b01fe74b4ef";

  @override
  void initState() {
    super.initState();
    fetchExperienceData(widget.experienceName);
  }

  Future<void> fetchExperienceData(String experienceName) async {
    final String encodedName = Uri.encodeComponent(experienceName);
    final Uri searchUrl = Uri.parse(
        "https://api.opentripmap.com/0.1/en/places/autosuggest?name=$encodedName&radius=50000&lon=101.6869&lat=3.1390&apikey=$apiKey");

    try {
      final response = await http.get(searchUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["features"] != null && data["features"].isNotEmpty) {
          var malaysiaExperience = data["features"].firstWhere(
            (exp) => exp["properties"]["country"] == "Malaysia",
            orElse: () => data["features"].first,
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
      setState(() {
        errorMessage = "Error fetching experience data.";
        isLoading = false;
      });
    }
  }

  Future<void> fetchExperienceDetails(String xid) async {
    final Uri detailsUrl = Uri.parse(
        "https://api.opentripmap.com/0.1/en/places/xid/$xid?apikey=$apiKey");

    try {
      final response = await http.get(detailsUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          experienceData = data;
          isLoading = false;
        });

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
      setState(() {
        errorMessage = "Error fetching experience details.";
        isLoading = false;
      });
    }
  }

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
          }
        }
      }
    } catch (e) {
      print("Error fetching experience image: $e");
    }
  }

  void _openGoogleMaps() async {
    if (experienceData == null) return;

    final lat = experienceData?["point"]["lat"];
    final lon = experienceData?["point"]["lon"];
    final mapsUrl = "https://www.google.com/maps/search/?api=1&query=$lat,$lon";

    if (await canLaunch(mapsUrl)) {
      await launch(mapsUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-Screen Gradient Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.lightBlue.shade200, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Custom Back Button
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.blue.shade700.withOpacity(0.8),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 10),

                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imageUrl,
                    height: 250,
                    width: MediaQuery.of(context).size.width * 0.9,
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
                      return Image.network(
                        "https://via.placeholder.com/150",
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),

                SizedBox(height: 20),

                // Title Centered
                Text(
                  experienceData?["name"] ?? widget.experienceName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),

                SizedBox(height: 20),

                // Details
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow("Country", experienceData?["address"]["country"] ?? "Unknown"),
                        _buildDetailRow("Latitude", experienceData?["point"]["lat"]?.toString() ?? "N/A"),
                        _buildDetailRow("Longitude", experienceData?["point"]["lon"]?.toString() ?? "N/A"),

                        SizedBox(height: 20),

                        // Open in Maps Button
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _openGoogleMaps,
                            icon: Icon(Icons.map, color: Colors.white),
                            label: Text("Open in Maps"),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
          Flexible(child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'destinationsDetails.dart';
import 'experienceDetails.dart';
import 'dart:convert';
import '../services/recommendation_service.dart';

class homePage extends StatefulWidget {
  final String userId;
  const homePage({Key? key, required this.userId}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<homePage> {
  final String geoDbApiKey =
      "99d0568adcmsh612a2ca3d0334f9p15fdf5jsndc687769b285";
  final String wikiApiUrl = "https://www.wikidata.org/wiki/Special:EntityData/";

  bool isLoading = true;
  List<dynamic> topExperiences = [];
  List<dynamic> topDestinations = [];
  final RecommendationService recommendationService = RecommendationService();
  List<String> destinations = [];

  final List<Map<String, String>> famousDestinations = [
    {"city": "Jakarta", "countryCode": "IN", "wikiDataId": "Q3630"},
    {"city": "Tokyo", "countryCode": "JP", "wikiDataId": "Q1490"},
    {"city": "Dubai", "countryCode": "UAE", "wikiDataId": "Q612"},
    {"city": "Sydney", "countryCode": "AUS", "wikiDataId": "Q3130"},
    {"city": "Shanghai", "countryCode": "CN", "wikiDataId": "Q8686"},
  ];

  @override
  void initState() {
    super.initState();
    print("Navigated to HomePage with userId: ${widget.userId}"); // Debug

    fetchTopExperiences();
    fetchTopDestinations();
    _loadRecommendations();
  }

  void _loadRecommendations() async {
    print("Fetching recommendations for userId: ${widget.userId}"); // Debug

    List<String> fetchedDestinations = await recommendationService
        .fetchRecommendations(widget.userId);

    print("API Response (Raw): $fetchedDestinations"); // Debug

    setState(() {
      destinations = fetchedDestinations;
      isLoading = false;
    });

    print("Updated destinations list: $destinations"); // Debug
  }

  Future<void> fetchTopExperiences() async {
    final String apiKey =
        "5ae2e3f221c38a28845f05b61e71a6719cee59a2f24d1b01fe74b4ef";
    final url = Uri.parse(
      "https://api.opentripmap.com/0.1/en/places/radius?radius=100000&lon=101.6869&lat=3.1390&rate=3&limit=10&apikey=$apiKey",
    );

    try {
      final response = await http.get(url);
      print("Experiences API Status Code: ${response.statusCode}");
      print("Experiences API Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          topExperiences = data["features"] ?? [];
        });
      } else {
        print("Failed to load experiences: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching experiences: $e");
    }
  }

  Future<String> fetchCityImageExperience(String wikiDataId) async {
    final url = Uri.parse(
      "https://www.wikidata.org/wiki/Special:EntityData/$wikiDataId.json",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final entities = data["entities"];
        if (entities.containsKey(wikiDataId)) {
          final entity = entities[wikiDataId];
          if (entity["claims"] != null && entity["claims"]["P18"] != null) {
            final imageFileName =
                entity["claims"]["P18"][0]["mainsnak"]["datavalue"]["value"];
            return "https://commons.wikimedia.org/wiki/Special:FilePath/$imageFileName";
          }
        }
      }
    } catch (e) {
      print("Error fetching city image: $e");
    }

    return "https://via.placeholder.com/150"; // Default image
  }

  // Fetch image for each experience
  Future<String> fetchExperienceImage(String xid) async {
    final String apiKey =
        "5ae2e3f221c38a28845f05b61e71a6719cee59a2f24d1b01fe74b4ef";
    final url = Uri.parse(
      "https://api.opentripmap.com/0.1/en/places/xid/$xid?apikey=$apiKey",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data["preview"]?["source"] ?? "https://via.placeholder.com/150";
      }
    } catch (e) {
      print("Error fetching image: $e");
    }
    return "https://via.placeholder.com/150";
  }

  Future<void> fetchTopDestinations() async {
    List<Map<String, dynamic>> destinations = [];

    for (var place in famousDestinations) {
      final city = place["city"] ?? "";
      final countryCode = place["countryCode"] ?? "";
      final wikiDataId = place["wikiDataId"] ?? "";

      final imageUrl = await fetchCityImageDestination(wikiDataId);

      destinations.add({
        "city": city,
        "country": countryCode, // Store country instead of population
        "image": imageUrl,
      });
    }

    setState(() {
      topDestinations = destinations;
    });
  }

  // Fetch city details from GeoDB Cities API (Hardcoded Cities)
  Future<Map<String, dynamic>> fetchCityDetails(
    String city,
    String countryCode,
  ) async {
    final url = Uri.parse(
      "https://wft-geo-db.p.rapidapi.com/v1/geo/cities?namePrefix=$city&countryIds=$countryCode",
    );

    try {
      final response = await http.get(
        url,
        headers: {
          "X-RapidAPI-Key": geoDbApiKey,
          "X-RapidAPI-Host": "wft-geo-db.p.rapidapi.com",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["data"].isNotEmpty) {
          return {
            "population": data["data"][0]["population"],
            "latitude": data["data"][0]["latitude"],
            "longitude": data["data"][0]["longitude"],
          };
        }
      }
    } catch (e) {
      print("Error fetching city details: $e");
    }

    return {};
  }

  // Fetch city images from Wikidata
  Future<String> fetchCityImageDestination(String wikiDataId) async {
    final url = Uri.parse(
      "https://www.wikidata.org/wiki/Special:EntityData/$wikiDataId.json",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final entities = data["entities"];
        if (entities.containsKey(wikiDataId)) {
          final entity = entities[wikiDataId];
          if (entity["claims"] != null && entity["claims"]["P18"] != null) {
            final imageFileName =
                entity["claims"]["P18"][0]["mainsnak"]["datavalue"]["value"];
            return "https://commons.wikimedia.org/wiki/Special:FilePath/$imageFileName";
          }
        }
      }
    } catch (e) {
      print("Error fetching city image: $e");
    }

    return "https://via.placeholder.com/150"; // Default image
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: Icon(Icons.menu, color: Colors.black),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/Logo.png', height: 30),
            SizedBox(width: 8),
            Text(
              "TRAVELMIND",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.black, size: 30),
            onPressed: () {
              Navigator.pushNamed(context, '/userProfile');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                "Menu",
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            _buildDrawerItem(context, "Accommodations", "/accommodations"),
            _buildDrawerItem(context, "Chatbot Rating", "/chatbotRating"),
            _buildDrawerItem(context, "Upcoming Bookings", "/upcomingBookings"),
            _buildDrawerItem(context, "Booking Confirmation", "/bookingConfirmation",),
            _buildDrawerItem(context, "Expenses Tracker", "/expensesList",),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Places to go, things to do, hotels...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Top spots near you", context),
                  _buildExperienceList(topExperiences),
                  _buildSectionTitle("Top destinations for holiday", context),
                  _buildDestinationList(topDestinations, context),
                  _buildRecommendedForYou(), // Add this section
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, String title, String route) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Navigator.pushNamed(context, route);
      },
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceList(List<dynamic> experiences) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: experiences.length,
        itemBuilder: (context, index) {
          final experience = experiences[index]["properties"];
          return _buildExperienceCard(
            experience?["xid"],
            experience?["name"] ?? "Unknown Place",
          );
        },
      ),
    );
  }

  Widget _buildExperienceCard(String? id, String title) {
    return FutureBuilder<String>(
      future: fetchExperienceImage(id ?? ""),
      builder: (context, snapshot) {
        return GestureDetector(
          onTap: () {
            if (id != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          experienceDetailsScreen(experienceName: title),
                ),
              );
            }
          },
          child: Padding(
            padding: EdgeInsets.only(left: 16),
            child: Container(
              width: 150,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      snapshot.data ?? "https://via.placeholder.com/150",
                      height: 100,
                      width: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Updated ListTile to display country instead of population
  Widget _buildDestinationList(
    List<dynamic> destinations,
    BuildContext context,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: destinations.length,
      itemBuilder: (context, index) {
        final destination = destinations[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                destination["image"],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.network(
                    "https://via.placeholder.com/50",
                    width: 50,
                    height: 50,
                  );
                },
              ),
            ),
            title: Text(destination["city"]),
            subtitle: Text(
              "Country: ${destination["country"]}",
            ), // Display country
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => destinationDetailsScreen(
                        cityName: destination["city"],
                      ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRecommendedForYou() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recommended for You",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  // Future enhancement: Open a dedicated recommendations page
                },
                child: Text("See All"),
              ),
            ],
          ),
        ),
        isLoading
            ? Center(
              child: CircularProgressIndicator(),
            ) // Show loader while loading
            : destinations.isEmpty
            ? Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                "No recommendations available. Try exploring new places!",
                style: TextStyle(color: Colors.grey),
              ),
            )
            : SizedBox(
              height: 180, // Adjust height for proper display
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: destinations.length,
                itemBuilder: (context, index) {
                  final destination = destinations[index];
                  return FutureBuilder<String>(
                    future: fetchCityImageDestination(destination),
                    builder: (context, snapshot) {
                      String imageUrl =
                          snapshot.data ??
                          "https://via.placeholder.com/150"; // Default image
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => destinationDetailsScreen(
                                    cityName: destination,
                                  ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Container(
                            width: 140,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 5,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    imageUrl,
                                    width: 140,
                                    height: 180,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.network(
                                        "https://via.placeholder.com/150",
                                        width: 140,
                                        height: 180,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.vertical(
                                        bottom: Radius.circular(10),
                                      ),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withOpacity(0),
                                          Colors.black.withOpacity(0.7),
                                        ],
                                      ),
                                    ),
                                    child: Text(
                                      destination,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
      ],
    );
  }
}

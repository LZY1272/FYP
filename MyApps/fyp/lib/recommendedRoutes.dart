import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'viewRoute.dart'; 

class recommendedRoutesPage extends StatefulWidget {
  final String startingPoint;
  final String transportMode;

  recommendedRoutesPage({
    required this.startingPoint,
    required this.transportMode,
  });

  @override
  _RecommendedRoutesPageState createState() => _RecommendedRoutesPageState();
}

class _RecommendedRoutesPageState extends State<recommendedRoutesPage> {
  String? destination; // Destination from SharedPreferences
  bool isDestinationLoaded = false; // Ensure destination is loaded before fetching routes

  @override
  void initState() {
    super.initState();
    _loadDestination();
  }

  Future<void> _loadDestination() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedDestination = prefs.getString('selected_destination'); // ✅ Corrected key

    if (savedDestination != null && savedDestination.isNotEmpty) {
      print("✔️ Destination loaded: $savedDestination");
      setState(() {
        destination = savedDestination;
        isDestinationLoaded = true; // ✅ Mark as loaded
      });
    } else {
      print("❌ No destination found in SharedPreferences.");
    }
  }

  // ✅ Ensure `_fetchRoutes()` only runs when destination is ready
  Future<List<Map<String, dynamic>>> _fetchRoutes() async {
    if (!isDestinationLoaded || destination == null) {
      print("⏳ Waiting for destination to load...");
      await Future.delayed(Duration(seconds: 1)); // Give some time for loading
      return [];
    }

    print("🔍 Fetching routes from ${widget.startingPoint} to $destination");

    final apiKey = 'bd58db6f-0ba9-4b14-9682-2d19b73a3e5b';

    String? startCoords = await _getCoordinates(widget.startingPoint);
    String? destCoords = await _getCoordinates(destination!);

    if (startCoords == null || destCoords == null) {
      print("❌ Could not fetch coordinates for places.");
      return [];
    }

    final url =
        'https://graphhopper.com/api/1/route?point=$startCoords&point=$destCoords&vehicle=${widget.transportMode}&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    print("📩 API Response: ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.containsKey('paths') && data['paths'].isNotEmpty) {
        return List<Map<String, dynamic>>.from(data['paths']);
      } else {
        print("⚠️ No routes found.");
        return [];
      }
    } else {
      print("❌ API Error: ${response.statusCode}");
      return [];
    }
  }

  Future<String?> _getCoordinates(String place) async {
    print("🔄 Resolving coordinates for: $place");

    String formattedPlace = await _detectCityAndFormat(place);

    // 🔹 Try Nominatim API first
    String? coordinates = await _fetchFromNominatim(formattedPlace);
    if (coordinates != null) return coordinates;

    // 🔹 Try OpenCage API if Nominatim fails
    coordinates = await _fetchFromOpenCage(formattedPlace);
    if (coordinates != null) return coordinates;

    print("❌ Failed to get coordinates for: $place");
    return null;
  }

  Future<String> _detectCityAndFormat(String place) async {
    final openCageApiKey = "20e9087a5faa400a99786f84b9ca3308";
    final encodedPlace = Uri.encodeComponent(place);
    final url = 'https://api.opencagedata.com/geocode/v1/json?q=$encodedPlace&key=$openCageApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'].isNotEmpty) {
          final components = data['results'][0]['components'];
          String city = components['city'] ?? components['town'] ?? components['state'] ?? '';
          String country = components['country'] ?? '';
          if (city.isNotEmpty && country.isNotEmpty) {
            return "$place, $city, $country";
          }
        }
      }
    } catch (e) {
      print("⚠️ Error detecting city: $e");
    }

    return "$place, Malaysia";
  }

  Future<String?> _fetchFromNominatim(String place) async {
    final encodedPlace = Uri.encodeComponent(place);
    final url = 'https://nominatim.openstreetmap.org/search?format=json&q=$encodedPlace';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty) {
          return "${data[0]['lat']},${data[0]['lon']}";
        }
      }
    } catch (e) {
      print("❌ Nominatim failed: $e");
    }
    return null;
  }

  Future<String?> _fetchFromOpenCage(String place) async {
    final openCageApiKey = "20e9087a5faa400a99786f84b9ca3308";
    final encodedPlace = Uri.encodeComponent(place);
    final url = 'https://api.opencagedata.com/geocode/v1/json?q=$encodedPlace&key=$openCageApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry'];
          return "${location['lat']},${location['lng']}";
        }
      }
    } catch (e) {
      print("❌ OpenCage failed: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recommended Routes")),
      body: isDestinationLoaded
          ? FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchRoutes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No routes found or error fetching data"));
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final route = snapshot.data![index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${(route['time'] / 60000).toStringAsFixed(1)} min (${(route['distance'] / 1000).toStringAsFixed(2)} km)",
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const Text(
                                    "Fastest route, usual traffic",
                                    style: TextStyle(fontSize: 14, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => viewRoutePage(routePoints: route['points']),
                                  ),
                                );
                              },
                              child: const Text("View"),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
              },
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

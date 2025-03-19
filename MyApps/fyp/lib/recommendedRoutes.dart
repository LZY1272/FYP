import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'viewRoute.dart'; // Import the new page for viewing full routes

class recommendedRoutesPage extends StatelessWidget {
  final String startingPoint;
  final String destination;
  final String transportMode;

  recommendedRoutesPage({
    required this.startingPoint,
    required this.destination,
    required this.transportMode,
  });

  // Convert place name to latitude/longitude using Nominatim API
  Future<String?> _getCoordinates(String place) async {
  final encodedPlace = Uri.encodeComponent(place); // Fix encoding issue
  final url = 'https://nominatim.openstreetmap.org/search?format=json&q=$encodedPlace';

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data.isNotEmpty) {
        return "${data[0]['lat']},${data[0]['lon']}";
      } else {
        print("Error: No results found for $place.");
      }
    } else {
      print("Error: API responded with status code ${response.statusCode}");
    }
  } catch (e) {
    print("Error: Exception occurred while fetching coordinates: $e");
  }
  
  return null;
}

  // Fetch routes from GraphHopper after converting names to coordinates
  Future<List<Map<String, dynamic>>> _fetchRoutes() async {
    final apiKey = 'bd58db6f-0ba9-4b14-9682-2d19b73a3e5b';

    // Convert place names to coordinates
    String? startCoords = await _getCoordinates(startingPoint);
    String? destCoords = await _getCoordinates(destination);

    if (startCoords == null || destCoords == null) {
      print("Error: Could not fetch coordinates for places.");
      return [];
    }

    final url =
        'https://graphhopper.com/api/1/route?point=$startCoords&point=$destCoords&vehicle=$transportMode&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    print("API Response: ${response.body}"); // Debugging

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.containsKey('paths') && data['paths'].isNotEmpty) {
        return List<Map<String, dynamic>>.from(data['paths']);
      } else {
        print("No routes found.");
        return [];
      }
    } else {
      print("Error: ${response.statusCode}");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recommended Routes")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchRoutes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text("No routes found or error fetching data"));
          } else {
            final routes = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: routes.length,
              itemBuilder: (context, index) {
                final route = routes[index];

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
                              overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}

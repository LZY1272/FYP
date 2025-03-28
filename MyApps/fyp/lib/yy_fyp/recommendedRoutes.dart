import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'viewRoute.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

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
  String? destination;
  bool isDestinationLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadDestination();
  }

  Future<void> _loadDestination() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedDestination = prefs.getString('selected_destination');

    if (savedDestination != null && savedDestination.isNotEmpty) {
      print("✔️ Destination loaded: $savedDestination");
      setState(() {
        destination = savedDestination;
        isDestinationLoaded = true;
      });
    } else {
      print("❌ No destination found in SharedPreferences.");
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRoutes() async {
    if (!isDestinationLoaded || destination == null) {
      print("⏳ Waiting for destination to load...");
      await Future.delayed(Duration(seconds: 1));
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

    List<String> avoidTypes = ["", "motorway", "toll"];
    List<Map<String, dynamic>> allRoutes = [];

    for (String avoid in avoidTypes) {
      final avoidParam = avoid.isNotEmpty ? "&avoid=$avoid" : "";
      final url =
          'https://graphhopper.com/api/1/route?point=$startCoords&point=$destCoords&vehicle=${widget.transportMode}&key=$apiKey$avoidParam';

      final response = await http.get(Uri.parse(url));

      print("📩 API Response (Avoid: $avoid): ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('paths') && data['paths'].isNotEmpty) {
          allRoutes.add(data['paths'][0]);
        }
      } else {
        print("❌ API Error (Avoid: $avoid): ${response.statusCode}");
      }
    }

    return allRoutes;
  }

  Future<String?> _getCoordinates(String place) async {
    print("🔄 Resolving coordinates for: $place");

    String formattedPlace = "$place, Malaysia";
    String? coordinates = await _fetchFromNominatim(formattedPlace);
    return coordinates;
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
                          color: index == 0 ? Colors.blue.shade500 : Colors.blue.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Route ${index + 1}: ${(route['time'] / 60000).toStringAsFixed(1)} min (${(route['distance'] / 1000).toStringAsFixed(2)} km)",
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  Text(
                                    index == 0 ? "Fastest route" : "Alternative route",
                                    style: TextStyle(fontSize: 14, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                  try {
                                    print("🔍 Full Route Data: $route");

                                    // Extract and decode the polyline
                                    String encodedPolyline = route['points']; 
                                    print("🔍 Decoding polyline: $encodedPolyline");

                                    // ✅ Corrected: Use `PointLatLng`
                                    PolylinePoints polylinePoints = PolylinePoints();
                                    List<PointLatLng> decodedPoints = polylinePoints.decodePolyline(encodedPolyline);

                                    // ✅ Convert to List<LatLng>
                                    List<LatLng> routePoints = decodedPoints.map(
                                      (point) => LatLng(point.latitude, point.longitude),
                                    ).toList();

                                    print("✅ Decoded Route Points: $routePoints");

                                    // Navigate to `viewRoutePage` with decoded coordinates
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => viewRoutePage(routePoints: routePoints),
                                      ),
                                    );
                                  } catch (e, stacktrace) {
                                    print("🚨 ERROR: $e");
                                    print("🔍 Stacktrace: $stacktrace");
                                  }
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

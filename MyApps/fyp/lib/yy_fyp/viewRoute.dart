import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart'; // 🌍 Import for launching Google Maps

class viewRoutePage extends StatelessWidget {
  final List<LatLng> routePoints;

  viewRoutePage({required this.routePoints});

  @override
  Widget build(BuildContext context) {
    if (routePoints.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text("Error")),
        body: Center(child: Text("No route points available.")),
      );
    }

    LatLng startPoint = routePoints.first;
    LatLng endPoint = routePoints.last;

    // ✅ Calculate bounds to fit all route points
    var bounds = LatLngBounds.fromPoints(routePoints);

    return Scaffold(
      appBar: AppBar(title: Text("Route Details")),
      body: FlutterMap(
        options: MapOptions(
          bounds: bounds, // ✅ Fit all route points in view
          boundsOptions: FitBoundsOptions(padding: EdgeInsets.all(50)), // ✅ Padding
          interactiveFlags: InteractiveFlag.all,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                strokeWidth: 4.0,
                color: Colors.blue,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: startPoint,
                width: 40,
                height: 40,
                builder: (ctx) => Icon(
                  Icons.location_on,
                  color: Colors.green,
                  size: 40,
                ),
              ),
              Marker(
                point: endPoint,
                width: 40,
                height: 40,
                builder: (ctx) => Icon(
                  Icons.flag,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openGoogleMaps(startPoint, endPoint), // 🌍 Open Google Maps
        backgroundColor: Colors.blue,
        child: Icon(Icons.directions, color: Colors.white),
      ),
    );
  }

  // 🌍 Function to Open Google Maps for Navigation
  void _openGoogleMaps(LatLng start, LatLng end) async {
  final Uri url = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&travelmode=driving");

  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    print("❌ Could not open Google Maps");
  }
}
}

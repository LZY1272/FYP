import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class viewRoutePage extends StatelessWidget {
  final Map<String, dynamic> routePoints;

  viewRoutePage({required this.routePoints});

  @override
  Widget build(BuildContext context) {
    List<LatLng> polylinePoints = [];

    for (var point in routePoints['coordinates']) {
      polylinePoints.add(LatLng(point[1], point[0])); // GraphHopper uses [lng, lat]
    }

    return Scaffold(
      appBar: AppBar(title: Text("Route Details")),
      body: FlutterMap(
        mapController: MapController(),
        options: MapOptions(
          center: polylinePoints.first, // Center map on starting point
          zoom: 12,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: polylinePoints,
                strokeWidth: 4.0,
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

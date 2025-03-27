// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:flutter_cache_manager/flutter_cache_manager.dart';

// class CachedTileProvider extends TileProvider {
//   final BaseCacheManager cacheManager = DefaultCacheManager();

//   @override
//   ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
//     final url =
//         'https://tile.openstreetmap.org/${coordinates.z}/${coordinates.x}/${coordinates.y}.png';
//     return NetworkImage(url);
//   }
// }

// class CachedMapWithItinerary extends StatelessWidget {
//   final List<LatLng> itineraryLocations = [
//     LatLng(3.1390, 101.6869), // Kuala Lumpur
//     LatLng(1.3521, 103.8198), // Singapore
//     LatLng(4.9031, 114.9398), // Brunei
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Offline Cached Map with Itinerary")),
//       body: FlutterMap(
//         options: MapOptions(
//           initialCenter: itineraryLocations[0], // Start at the first location
//           initialZoom: 10,
//         ),
//         children: [
//           TileLayer(tileProvider: CachedTileProvider()),
//           MarkerLayer(
//             markers:
//                 itineraryLocations.map((location) {
//                   return Marker(
//                     point: location,
//                     width: 40,
//                     height: 40,
//                     child: Icon(
//                       Icons.location_pin,
//                       color: Colors.red,
//                       size: 30,
//                     ),
//                   );
//                 }).toList(),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'trafficUpdates.dart';

class RecommendedRoutesPage extends StatelessWidget {
  final String startingPoint;
  final String destination;

  RecommendedRoutesPage({required this.startingPoint, required this.destination});

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> routes = [
      {"time": "17 min", "distance": "12 km", "info": "Fastest route, the usual traffic"},
      {"time": "19 min", "distance": "11 km", "info": "Alternative route, slight traffic"},
      {"time": "19 min", "distance": "15 km", "info": "Scenic route, more distance"},
    ];

    return Scaffold(
      appBar: AppBar(title: Text("Routes")),
      body: ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: routes.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: Icon(Icons.directions_car, color: Colors.blue),
              title: Text("${routes[index]["time"]} (${routes[index]["distance"]})"),
              subtitle: Text(routes[index]["info"]!),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrafficUpdatesPage(
                        startingPoint: startingPoint,
                        destination: destination,
                      ),
                    ),
                  );
                },
                child: Text("View"),
              ),
            ),
          );
        },
      ),
    );
  }
}

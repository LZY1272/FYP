import 'package:flutter/material.dart';

class TrafficUpdatesPage extends StatelessWidget {
  final String startingPoint;
  final String destination;

  TrafficUpdatesPage({required this.startingPoint, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Routes")),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text("From: $startingPoint", style: TextStyle(fontSize: 18)),
                Text("To: $destination", style: TextStyle(fontSize: 18)),
                SizedBox(height: 20),
              ],
            ),
          ),
          Expanded(
            child: Image.asset("assets/map_placeholder.png", fit: BoxFit.cover),
          ),
          SizedBox(height: 15),
          Text("17 min - No tolls", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'recommendedRoutes.dart';

class RoutesPage extends StatefulWidget {
  final String destination;

  RoutesPage({required this.destination});

  @override
  _RoutesPageState createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  String startingPoint = "Choose Starting Point";
  String modeOfTransport = "Car"; // Default transport mode

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Routes")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
  value: startingPoint,
  items: [
    DropdownMenuItem(
      value: "Choose Starting Point",
      child: Text("Choose Starting Point"),
    ),
    DropdownMenuItem(
      value: "TARUMT",
      child: Text("TARUMT"),
    ),
    DropdownMenuItem(
      value: "KLCC",
      child: Text("KLCC"),
    ),
    DropdownMenuItem(
      value: "Subang",
      child: Text("Subang"),
    ),
  ],
  onChanged: (value) {
    setState(() {
      startingPoint = value!;
    });
  },
  decoration: InputDecoration(labelText: "Choose Starting Point"),
),
            SizedBox(height: 15),
            TextFormField(
              initialValue: widget.destination,
              readOnly: true,
              decoration: InputDecoration(labelText: "Destination"),
            ),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecommendedRoutesPage(
                      startingPoint: startingPoint,
                      destination: widget.destination,
                    ),
                  ),
                );
              },
              child: Text("Go"),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'recommendedRoutes.dart';
import 'package:latlong2/latlong.dart';

class routesPage extends StatefulWidget {
  final String destination;

  routesPage({required this.destination});

  @override
  _RoutesPageState createState() => _RoutesPageState();
}

Future<LatLng?> getCoordinates(String location) async {
  final apiKey = "bd58db6f-0ba9-4b14-9682-2d19b73a3e5b";
  final url = "https://graphhopper.com/api/1/geocode?q=$location&limit=1&key=$apiKey";

  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['hits'].isNotEmpty) {
      final lat = data['hits'][0]['point']['lat'];
      final lng = data['hits'][0]['point']['lng'];
      return LatLng(lat, lng);
    }
  }
  return null;
}

class _RoutesPageState extends State<routesPage> {
  TextEditingController _startingPointController = TextEditingController();
  List<String> _suggestions = [];
  String _selectedStartingPoint = '';
  String _selectedTransportMode = 'car'; // Default transport mode

  final List<String> _transportModes = [
    'car',
    'bike',
    'foot',
    // Add other modes as needed
  ];

  Future<void> _fetchSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    final apiKey = 'bd58db6f-0ba9-4b14-9682-2d19b73a3e5b';
    final url =
        'https://graphhopper.com/api/1/geocode?q=$input&locale=en&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<String> newSuggestions = [];

      for (var item in data['hits']) {
        newSuggestions.add(item['name']);
      }

      setState(() {
        _suggestions = newSuggestions;
      });
    } else {
      // Handle error
      setState(() {
        _suggestions = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Routes")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _startingPointController,
              decoration: InputDecoration(labelText: "Choose Starting Point"),
              onChanged: (value) {
                _fetchSuggestions(value);
              },
            ),
            if (_suggestions.isNotEmpty)
              Container(
                height: 100,
                child: ListView.builder(
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_suggestions[index]),
                      onTap: () {
                        setState(() {
                          _selectedStartingPoint = _suggestions[index];
                          _startingPointController.text = _selectedStartingPoint;
                          _suggestions = [];
                        });
                      },
                    );
                  },
                ),
              ),
            SizedBox(height: 15),
            TextFormField(
              initialValue: widget.destination,
              readOnly: true,
              decoration: InputDecoration(labelText: "Destination"),
            ),
            SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _selectedTransportMode,
              items: _transportModes.map((String mode) {
                return DropdownMenuItem<String>(
                  value: mode,
                  child: Text(mode),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedTransportMode = newValue!;
                });
              },
              decoration: InputDecoration(labelText: "Mode of Transport"),
            ),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                if (_selectedStartingPoint.isEmpty) {
                  // Show error or prompt user to select a starting point
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => recommendedRoutesPage(
                      startingPoint: _selectedStartingPoint,
                      transportMode: _selectedTransportMode,
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

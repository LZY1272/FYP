import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'recommendedRoutes.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // 📍 Import Geolocator

class routesPage extends StatefulWidget {
  final String destination;

  routesPage({required this.destination});

  @override
  _RoutesPageState createState() => _RoutesPageState();
}

class _RoutesPageState extends State<routesPage> {
  TextEditingController _startingPointController = TextEditingController();
  List<String> _suggestions = [];
  String _selectedStartingPoint = '';
  String _selectedTransportMode = 'car';
  LatLng? _currentLocation; // 📍 Store current location coordinates

  final List<String> _transportModes = ['car', 'bike', 'foot'];

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _selectedStartingPoint = "📍 Current Location";
        _startingPointController.text = _selectedStartingPoint;
        _suggestions = [];
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  Future<void> _fetchSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() {
        _suggestions = ["📍 Use Current Location"]; // 📍 Ensure option is always there
      });
      return;
    }

    final apiKey = 'bd58db6f-0ba9-4b14-9682-2d19b73a3e5b';
    final url =
        'https://graphhopper.com/api/1/geocode?q=$input&locale=en&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<String> newSuggestions = ["📍 Use Current Location"];

      for (var item in data['hits']) {
        newSuggestions.add(item['name']);
      }

      setState(() {
        _suggestions = newSuggestions;
      });
    } else {
      setState(() {
        _suggestions = ["📍 Use Current Location"];
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
                setState(() {
                  _selectedStartingPoint = value; // ✅ Update user input
                  _currentLocation = null; // ✅ Reset current location if typing
                });
                _fetchSuggestions(value);
              },
              onTap: () {
                _fetchSuggestions(""); // 📍 Show suggestions when tapped
              },
            ),
            if (_suggestions.isNotEmpty)
              Container(
                height: 150,
                child: ListView.builder(
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_suggestions[index]),
                      onTap: () {
                        if (_suggestions[index] == "📍 Use Current Location") {
                          _getCurrentLocation();
                        } else {
                          setState(() {
                            _selectedStartingPoint = _suggestions[index];
                            _startingPointController.text = _selectedStartingPoint;
                            _currentLocation = null; // ✅ Reset current location
                            _suggestions = [];
                          });
                        }
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
                if (_selectedStartingPoint.isEmpty && _currentLocation == null) {
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => recommendedRoutesPage(
                      startingPoint: _currentLocation != null
                          ? "${_currentLocation!.latitude},${_currentLocation!.longitude}"
                          : _selectedStartingPoint, // ✅ Use typed input if available
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

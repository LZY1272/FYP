import 'package:flutter/material.dart';
import 'itinerary_screen.dart'; // The screen to display the itinerary
import '../services/itinerary.dart'; // The itinerary generation logic
import 'package:http/http.dart' as http;
import 'dart:convert';

class TravelForm extends StatefulWidget {
  final String userId; // Add userId parameter

  const TravelForm({Key? key, required this.userId}) : super(key: key);

  @override
  _TravelFormState createState() => _TravelFormState();
}

class _TravelFormState extends State<TravelForm> {
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  late String userId;

  String? _travelType;
  final List<String> _activityPreferences = [];
  final List<String> _interestCategories = [];

  final List<String> _availableActivities = [
    'Adventure',
    'Beach',
    'Culture',
    'Food',
    'Relaxation',
  ];
  final List<String> _availableInterests = [
    'Nature',
    'History',
    'Shopping',
    'Nightlife',
    'Art',
    'Other',
  ];
  @override
  void initState() {
    super.initState();
    userId = widget.userId; // Assign userId
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toLocal().toString().split(' ')[0];
      });
    }
  }

  void _generateItinerary() async {
    if (_destinationController.text.isEmpty ||
        _startDateController.text.isEmpty ||
        _endDateController.text.isEmpty ||
        _travelType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    // Parse start and end dates
    DateTime startDate = DateTime.parse(_startDateController.text);
    DateTime endDate = DateTime.parse(_endDateController.text);

    // Calculate the number of days for the itinerary
    int numberOfDays = endDate.difference(startDate).inDays + 1;
    print(
      "Generate Itinerary button pressed with userId: $userId",
    ); // Debugging

    // Generate itinerary for multiple days
    List<List<Map<String, dynamic>>> itinerary =
        await ItineraryGenerator.generateItinerary(
          widget.userId,
          _destinationController.text,
          numberOfDays,
        );
    print("Itinerary generated: $itinerary"); // Check if data is generated

    // Prepare request body
    var requestBody = {
      "userId": userId, // Include user ID
      "destination": _destinationController.text,
      "startDate": _startDateController.text,
      "endDate": _endDateController.text,
      "travelType": _travelType,
      "itinerary": itinerary,
    };

    // Send to API
    var response = await http.post(
      Uri.parse(
        "http://127.0.0.1:8000/api/itinerary",
      ), // Replace with real API URL
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestBody),
    );

    var jsonResponse = jsonDecode(response.body);
    if (jsonResponse['status']) {
      // Navigate to Itinerary Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ItineraryScreen(itinerary: itinerary),
        ),
      );
    } else {
      print("Failed to save itinerary");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Travel Itinerary Generator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _destinationController,
                decoration: InputDecoration(
                  labelText: 'Destination',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectDate(context, _startDateController),
                child: AbsorbPointer(
                  child: TextField(
                    controller: _startDateController,
                    decoration: InputDecoration(
                      labelText: 'Start Date',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectDate(context, _endDateController),
                child: AbsorbPointer(
                  child: TextField(
                    controller: _endDateController,
                    decoration: InputDecoration(
                      labelText: 'End Date',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Travel Type',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...['Solo', 'Group', 'Family', 'Couple'].map(
                (type) => ListTile(
                  title: Text(type),
                  leading: Radio<String>(
                    value: type,
                    groupValue: _travelType,
                    onChanged: (value) => setState(() => _travelType = value),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Activity Preferences',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._availableActivities.map(
                (activity) => CheckboxListTile(
                  title: Text(activity),
                  value: _activityPreferences.contains(activity),
                  onChanged: (bool? selected) {
                    setState(() {
                      selected == true
                          ? _activityPreferences.add(activity)
                          : _activityPreferences.remove(activity);
                    });
                  },
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Interest Categories',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._availableInterests.map(
                (interest) => CheckboxListTile(
                  title: Text(interest),
                  value: _interestCategories.contains(interest),
                  onChanged: (bool? selected) {
                    setState(() {
                      selected == true
                          ? _interestCategories.add(interest)
                          : _interestCategories.remove(interest);
                    });
                  },
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _generateItinerary,
                child: Text('Generate Itinerary'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

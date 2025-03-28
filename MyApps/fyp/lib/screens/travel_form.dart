import 'package:flutter/material.dart';
import 'itinerary_screen.dart'; // The screen to display the itinerary
import '../services/itinerary.dart'; // The itinerary generation logic
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/config.dart';

class TravelForm extends StatefulWidget {
  final String userId;

  const TravelForm({Key? key, required this.userId}) : super(key: key);

  @override
  _TravelFormState createState() => _TravelFormState();
}

class _TravelFormState extends State<TravelForm> {
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

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

    DateTime startDate = DateTime.parse(_startDateController.text);
    DateTime endDate = DateTime.parse(_endDateController.text);
    int numberOfDays = endDate.difference(startDate).inDays + 1;

    print("🚀 Generating itinerary for User: ${widget.userId}");

    // ✅ Generate itinerary
    List<List<Map<String, dynamic>>> itinerary =
        await ItineraryGenerator.generateItinerary(
          widget.userId,
          _destinationController.text,
          numberOfDays,
        );

    print("📦 Itinerary generated: $itinerary");

    if (itinerary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate itinerary. Try again.')),
      );
      return;
    }

    // ✅ Navigate to ItineraryScreen IMMEDIATELY
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  ItineraryScreen(userId: widget.userId, itinerary: itinerary),
        ),
      );
      print("✅ Navigation to ItineraryScreen triggered!");
    }

    // ✅ Save itinerary in the background (does not block UI)
    Map<String, dynamic> itineraryData = {
      "userId": widget.userId,
      "destination": _destinationController.text,
      "startDate": _startDateController.text,
      "endDate": _endDateController.text,
      "numberOfDays": numberOfDays,
      "travelType": _travelType,
      "activityPreferences": _activityPreferences,
      "interestCategories": _interestCategories,
      "itinerary": itinerary,
      "timestamp": DateTime.now().toIso8601String(),
    };

    _saveItineraryToNodeJS(itineraryData);
  }

  Future<void> _saveItineraryToNodeJS(
    Map<String, dynamic> itineraryData,
  ) async {
    try {
      print("📦 Sending itinerary to Node.js backend...");
      print("📜 Request Body: ${jsonEncode(itineraryData)}");

      final response = await http.post(
        Uri.parse(saveItinerary), // Ensure this URL is correct
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(itineraryData),
      );

      print("🛜 Response Status: ${response.statusCode}");
      print("📜 Response Body: ${response.body}");

      if (response.statusCode == 201) {
        print("✅ Itinerary successfully saved via Node.js!");
      } else {
        print("❌ Failed to save itinerary. Response: ${response.body}");
      }
    } catch (e) {
      print("❌ Error saving itinerary to Node.js: $e");
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

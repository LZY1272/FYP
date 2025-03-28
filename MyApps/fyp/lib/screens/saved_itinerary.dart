import 'package:flutter/material.dart';
import 'package:fyp/services/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../screens/edit_itinerary.dart';

class SavedItineraryScreen extends StatefulWidget {
  final String userId;

  const SavedItineraryScreen({Key? key, required this.userId})
    : super(key: key);

  @override
  _SavedItineraryScreenState createState() => _SavedItineraryScreenState();
}

class _SavedItineraryScreenState extends State<SavedItineraryScreen> {
  late Future<List<dynamic>> itineraries;

  @override
  void initState() {
    super.initState();
    itineraries = fetchItineraries(widget.userId);
  }

  // Function to fetch itineraries
  Future<List<dynamic>> fetchItineraries(String userId) async {
    final response = await http.get(Uri.parse(getItinerary(userId)));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success']; // Replace 'success' with the correct field from your API
    } else {
      throw Exception('Failed to load itineraries');
    }
  }

  // Function to delete itinerary
  Future<void> deleteItinerary(String itineraryId) async {
    final url =
        'http://172.22.7.171:3000/deleteItinerary'; // Your delete endpoint URL
    final response = await http.delete(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'id': itineraryId}),
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      print('Response: $responseBody'); // Print response body for debugging

      if (responseBody['status'] == true) {
        print("Itinerary deleted successfully");
        setState(() {
          itineraries = fetchItineraries(widget.userId); // Refresh itineraries
        });
      } else {
        throw Exception("Failed to delete itinerary");
      }
    } else {
      throw Exception("Failed to delete itinerary");
    }
  }

  // Function to edit itinerary (modify as per your API)
  Future<void> editItinerary(
    String itineraryId,
    Map<String, dynamic> updatedData,
  ) async {
    final response = await http.put(
      Uri.parse(updateItinerary),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'id': itineraryId, 'updatedData': updatedData}),
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      if (responseBody['status'] == true) {
        print("Itinerary updated successfully");
        setState(() {
          itineraries = fetchItineraries(widget.userId); // Refresh itineraries
        });
      } else {
        throw Exception("Failed to update itinerary");
      }
    } else {
      throw Exception("Failed to update itinerary");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Saved Itineraries"),
        backgroundColor: Color(0xFF0CB9CE),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: itineraries,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No itineraries found.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final itinerary = snapshot.data![index];
              return ListTile(
                title: Text(itinerary['destination']),
                subtitle: Text('Start Date: ${itinerary['startDate']}'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder:
                  //         (context) => EditItineraryScreen(
                  //           itineraryId:
                  //               itinerary['_id'], // Make sure _id is passed as the itinerary ID
                  //           initialData: itinerary, // Pass the itinerary data
                  //         ),
                  //   ),
                  // );
                },
                onLongPress: () {
                  // Show a bottom sheet or dialog for edit and delete options
                  _showEditDeleteOptions(context, itinerary);
                },
              );
            },
          );
        },
      ),
    );
  }

  // Show Edit/Delete Options for an itinerary
  void _showEditDeleteOptions(BuildContext context, dynamic itinerary) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit),
                title: Text("Edit Itinerary"),
                onTap: () {
                  Navigator.pop(context);
                  _editItinerary(itinerary); // Call the edit function
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text("Delete Itinerary"),
                onTap: () {
                  Navigator.pop(context);
                  _deleteItinerary(
                    itinerary['_id'],
                  ); // Call the delete function
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Function to show edit itinerary
  void _editItinerary(dynamic itinerary) {
    // You can navigate to an Edit screen or show a dialog to update the itinerary.
    // Here I'm showing a simple example to update the destination and start date.
    final TextEditingController destinationController = TextEditingController(
      text: itinerary['destination'],
    );
    final TextEditingController startDateController = TextEditingController(
      text: itinerary['startDate'],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit Itinerary"),
          content: Column(
            children: [
              TextField(
                controller: destinationController,
                decoration: InputDecoration(labelText: 'Destination'),
              ),
              TextField(
                controller: startDateController,
                decoration: InputDecoration(labelText: 'Start Date'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final updatedData = {
                  'destination': destinationController.text,
                  'startDate': startDateController.text,
                };
                editItinerary(itinerary['_id'], updatedData);
                Navigator.pop(context); // Close the dialog
              },
              child: Text("Save"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  // Function to delete itinerary
  void _deleteItinerary(String itineraryId) {
    deleteItinerary(itineraryId);
  }
}

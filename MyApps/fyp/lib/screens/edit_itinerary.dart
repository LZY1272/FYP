// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../services/config.dart';

// class EditItineraryScreen extends StatefulWidget {
//   final String itineraryId;
//   final Map<String, dynamic> initialData;

//   const EditItineraryScreen({
//     Key? key,
//     required this.itineraryId,
//     required this.initialData,
//   }) : super(key: key);

//   @override
//   _EditItineraryScreenState createState() => _EditItineraryScreenState();
// }

// class _EditItineraryScreenState extends State<EditItineraryScreen> {
//   final _formKey = GlobalKey<FormState>();
//   late TextEditingController _destinationController;
//   late TextEditingController _startDateController;
//   late TextEditingController _endDateController;
//   late List<dynamic> _itinerary; // Holds the list of points of interest

//   @override
//   void initState() {
//     super.initState();
//     _destinationController = TextEditingController(
//       text: widget.initialData['destination'],
//     );
//     _startDateController = TextEditingController(
//       text: widget.initialData['startDate'],
//     );
//     _endDateController = TextEditingController(
//       text: widget.initialData['endDate'],
//     );
//     _itinerary = List.from(
//       widget.initialData['itinerary'],
//     ); // Initialize with existing itinerary data
//   }

//   Future<void> updateItinerary() async {
//     if (_formKey.currentState!.validate()) {
//       final updatedItinerary = {
//         "id": widget.itineraryId,
//         "updatedData": {
//           "destination": _destinationController.text,
//           "startDate": _startDateController.text,
//           "endDate": _endDateController.text,
//           "itinerary": _itinerary.join(
//             ', ',
//           ), // Ensure you're passing a string or the correct data format
//         },
//       };

//       final response = await http.put(
//         Uri.parse("${url}updateItinerary"),
//         body: json.encode(updatedItinerary),
//         headers: {"Content-Type": "application/json"},
//       );

//       if (response.statusCode == 200) {
//         Navigator.pop(context); // Go back to the previous screen
//       } else {
//         throw Exception('Failed to update itinerary');
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Edit Itinerary"),
//         backgroundColor: Color(0xFF0CB9CE),
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // Destination TextField
//               TextFormField(
//                 controller: _destinationController,
//                 decoration: InputDecoration(labelText: "Destination"),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter a destination';
//                   }
//                   return null;
//                 },
//               ),
//               // Start Date TextField
//               TextFormField(
//                 controller: _startDateController,
//                 decoration: InputDecoration(
//                   labelText: "Start Date (YYYY-MM-DD)",
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter a start date';
//                   }
//                   return null;
//                 },
//               ),
//               // End Date TextField
//               TextFormField(
//                 controller: _endDateController,
//                 decoration: InputDecoration(labelText: "End Date (YYYY-MM-DD)"),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter an end date';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 20),
//               Text("Edit Points of Interest:"),
//               // Edit Points of Interest (POIs) dynamically
//               for (var point in _itinerary)
//                 TextFormField(
//                   initialValue: point,
//                   decoration: InputDecoration(labelText: "Point of Interest"),
//                   onChanged: (value) {
//                     // Update the itinerary when a point is changed
//                     setState(() {
//                       _itinerary[_itinerary.indexOf(point)] = value;
//                     });
//                   },
//                 ),
//               SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: updateItinerary,
//                 child: Text("Update Itinerary"),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Color(0xFF0CB9CE), // Correct parameter
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

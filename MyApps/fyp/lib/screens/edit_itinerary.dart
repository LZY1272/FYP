import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../services/search.dart';
import 'dart:async';
// Import your SearchAPI class
// import 'path_to_your_search_api.dart';

class EditItineraryScreen extends StatefulWidget {
  final String itineraryId;
  final Map<String, dynamic> initialData;
  final VoidCallback onUpdate;

  const EditItineraryScreen({
    Key? key,
    required this.itineraryId,
    required this.initialData,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _EditItineraryScreenState createState() => _EditItineraryScreenState();
}

class _EditItineraryScreenState extends State<EditItineraryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _destinationController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  late TextEditingController _numberOfDaysController;
  late TextEditingController _travelTypeController;
  List<List<Map<String, dynamic>>> itineraryPlaces = [];
  TextEditingController _newPlaceController = TextEditingController();
  bool _isLoading = false;
  List<String> _placeSuggestions = [];
  bool _isFetchingSuggestions = false;
  Timer? _debounce;
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];

  @override
  void initState() {
    super.initState();
    _destinationController = TextEditingController(
      text: widget.initialData['destination'],
    );
    _startDateController = TextEditingController(
      text: _formatDate(widget.initialData['startDate']),
    );
    _endDateController = TextEditingController(
      text: _formatDate(widget.initialData['endDate']),
    );
    _numberOfDaysController = TextEditingController(
      text: widget.initialData['numberOfDays'].toString(),
    );
    _travelTypeController = TextEditingController(
      text: widget.initialData['travelType'],
    );

    // Initialize itinerary places correctly
    if (widget.initialData.containsKey('itinerary') &&
        widget.initialData['itinerary'] is List) {
      try {
        itineraryPlaces = List<List<Map<String, dynamic>>>.from(
          (widget.initialData['itinerary'] as List).map(
            (day) => List<Map<String, dynamic>>.from(
              (day as List).map((place) {
                // Make sure all places are properly converted to Map<String, dynamic>
                if (place is Map) {
                  return Map<String, dynamic>.from(place);
                }
                return {'place': 'Unknown Place'};
              }),
            ),
          ),
        );

        // Debugging the data structure
        print("Loaded itinerary places:");
        for (int i = 0; i < itineraryPlaces.length; i++) {
          print("Day ${i + 1}:");
          for (int j = 0; j < itineraryPlaces[i].length; j++) {
            print("  Place ${j + 1}: ${itineraryPlaces[i][j]}");
          }
        }

        // Add empty days if needed
        int numberOfDays = int.parse(_numberOfDaysController.text);
        while (itineraryPlaces.length < numberOfDays) {
          itineraryPlaces.add([]);
        }
      } catch (e) {
        print("Error parsing itinerary data: $e");
        // Initialize with empty days
        int numberOfDays = int.parse(_numberOfDaysController.text);
        itineraryPlaces = List.generate(numberOfDays, (index) => []);
      }
    } else {
      // Initialize with empty days
      int numberOfDays = int.parse(_numberOfDaysController.text);
      itineraryPlaces = List.generate(numberOfDays, (index) => []);
    }

    // Set up listener for place suggestions
    _newPlaceController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_newPlaceController.text.length >= 2) {
        _fetchPlaceSuggestions(_newPlaceController.text);
      } else {
        setState(() {
          _placeSuggestions = [];
        });
      }
    });
  }

  Future<void> _fetchPlaceSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _placeSuggestions = [];
        _isFetchingSuggestions = false;
      });
      return;
    }

    setState(() {
      _isFetchingSuggestions = true;
    });

    try {
      final suggestions = await SearchAPI.getPlaceSuggestions(query);

      setState(() {
        _placeSuggestions = suggestions;
        _isFetchingSuggestions = false;
      });
    } catch (e) {
      print("Error fetching suggestions: $e");
      setState(() {
        _isFetchingSuggestions = false;
      });
    }
  }

  // Helper method to format date from MongoDB format
  String _formatDate(dynamic date) {
    if (date == null) return '';

    try {
      // If date is a DateTime object directly
      if (date is DateTime) {
        return DateFormat('yyyy-MM-dd').format(date);
      }

      // If date is a string in ISO format
      if (date is String) {
        return DateFormat('yyyy-MM-dd').format(DateTime.parse(date));
      }

      // If date is in MongoDB format
      if (date is Map && date.containsKey('\$date')) {
        return DateFormat('yyyy-MM-dd').format(DateTime.parse(date['\$date']));
      }

      return '';
    } catch (e) {
      print("Error formatting date: $e");
      return '';
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    DateTime initialDate;
    try {
      initialDate = DateFormat('yyyy-MM-dd').parse(controller.text);
    } catch (e) {
      initialDate = DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);

        // If start date is changed, update end date and number of days
        if (controller == _startDateController) {
          try {
            final endDate = DateFormat(
              'yyyy-MM-dd',
            ).parse(_endDateController.text);
            if (picked.isAfter(endDate)) {
              _endDateController.text = DateFormat('yyyy-MM-dd').format(picked);
            }
            _updateNumberOfDays();
          } catch (e) {
            // Invalid end date, ignore
          }
        } else if (controller == _endDateController) {
          _updateNumberOfDays();
        }
      });
    }
  }

  void _updateNumberOfDays() {
    try {
      final startDate = DateFormat(
        'yyyy-MM-dd',
      ).parse(_startDateController.text);
      final endDate = DateFormat('yyyy-MM-dd').parse(_endDateController.text);
      final difference = endDate.difference(startDate).inDays + 1;
      _numberOfDaysController.text = difference.toString();

      // Update itinerary days if needed
      if (difference > itineraryPlaces.length) {
        setState(() {
          while (itineraryPlaces.length < difference) {
            itineraryPlaces.add([]);
          }
        });
      }
    } catch (e) {
      // Invalid dates, ignore
    }
  }

  Future<void> addPlace(int dayIndex) async {
    if (_newPlaceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a place name')));
      return;
    }

    if (dayIndex >= 0 && dayIndex < itineraryPlaces.length) {
      // Try to get place details if available
      setState(() {
        _isLoading = true;
      });

      try {
        final placeDetails = await SearchAPI.getPlaceDetails(
          _newPlaceController.text.trim(),
        );

        setState(() {
          _isLoading = false;

          if (placeDetails != null) {
            // Successfully got place details
            itineraryPlaces[dayIndex].add(placeDetails);
            print("Added place with details: $placeDetails");
          } else {
            // Fallback to just using the name
            itineraryPlaces[dayIndex].add({
              'name': _newPlaceController.text.trim(),
              'place':
                  _newPlaceController.text
                      .trim(), // Add this for backward compatibility
            });
            print(
              "Added place with name only: ${_newPlaceController.text.trim()}",
            );
          }

          _newPlaceController.clear();
          _placeSuggestions = [];
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          // Fallback to just using the name
          itineraryPlaces[dayIndex].add({
            'name': _newPlaceController.text.trim(),
            'place':
                _newPlaceController.text
                    .trim(), // Add this for backward compatibility
          });
        });
        print("Error getting place details: $e");
      }
    }
  }

  void editPlace(int dayIndex, int placeIndex) {
    if (dayIndex >= 0 &&
        dayIndex < itineraryPlaces.length &&
        placeIndex >= 0 &&
        placeIndex < itineraryPlaces[dayIndex].length) {
      final placeData = itineraryPlaces[dayIndex][placeIndex];
      final String placeName =
          placeData['name'] ?? placeData['place'] ?? "Unknown Place";

      TextEditingController placeNameController = TextEditingController(
        text: placeName,
      );
      TextEditingController notesController = TextEditingController(
        text: placeData['notes'] ?? '',
      );
      TextEditingController timeController = TextEditingController(
        text: placeData['time'] ?? '',
      );

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Edit Place'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: placeNameController,
                      decoration: InputDecoration(
                        labelText: 'Place Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: timeController,
                      decoration: InputDecoration(
                        labelText: 'Time (optional)',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., 09:00 AM - 12:00 PM',
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (placeNameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Place name cannot be empty')),
                      );
                      return;
                    }

                    setState(() {
                      // Preserve existing data and update only what changed
                      Map<String, dynamic> updatedPlace = Map.from(placeData);
                      updatedPlace['name'] = placeNameController.text.trim();
                      updatedPlace['place'] =
                          placeNameController.text
                              .trim(); // Keep both for compatibility
                      updatedPlace['notes'] = notesController.text;
                      updatedPlace['time'] = timeController.text;

                      itineraryPlaces[dayIndex][placeIndex] = updatedPlace;
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Save'),
                ),
              ],
            ),
      );
    }
  }

  void removePlace(int dayIndex, int placeIndex) {
    if (dayIndex >= 0 &&
        dayIndex < itineraryPlaces.length &&
        placeIndex >= 0 &&
        placeIndex < itineraryPlaces[dayIndex].length) {
      final placeName =
          itineraryPlaces[dayIndex][placeIndex]['name'] ??
          itineraryPlaces[dayIndex][placeIndex]['place'] ??
          "this place";

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Remove Place'),
              content: Text('Are you sure you want to remove "$placeName"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () {
                    setState(() {
                      itineraryPlaces[dayIndex].removeAt(placeIndex);
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Remove'),
                ),
              ],
            ),
      );
    }
  }

  void reorderPlaces(int dayIndex, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final movedItem = itineraryPlaces[dayIndex].removeAt(oldIndex);
      itineraryPlaces[dayIndex].insert(newIndex, movedItem);
    });
  }

  Future<void> updateItinerary() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = 'http://172.20.10.3:3000/updateItinerary';

      // Create a client with timeout settings
      final client = http.Client();
      final request = http.Request('PUT', Uri.parse(url));
      request.headers['Content-Type'] = 'application/json';
      request.body = json.encode({
        'id': widget.itineraryId,
        'updatedData': {
          'destination': _destinationController.text,
          'startDate': _startDateController.text,
          'endDate': _endDateController.text,
          'numberOfDays': int.parse(_numberOfDaysController.text),
          'travelType': _travelTypeController.text,
          'itinerary': itineraryPlaces,
        },
      });

      // Set a timeout for the request
      final response = await client
          .send(request)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Connection timed out');
            },
          );

      final responseString = await response.stream.bytesToString();

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final responseBody = json.decode(responseString);
        if (responseBody['status'] == true) {
          // Just notify the parent and close immediately
          widget.onUpdate();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Itinerary updated successfully')),
          );
        } else {
          throw Exception(
            responseBody['message'] ?? "Failed to update itinerary",
          );
        }
      } else {
        throw Exception(
          "Failed to update itinerary. Status: ${response.statusCode}",
        );
      }
    } on TimeoutException catch (_) {
      setState(() {
        _isLoading = false;
      });

      // Handle timeout specifically - go back and show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Server took too long to respond. Your changes might still be saved.',
          ),
          duration: Duration(seconds: 5),
        ),
      );

      // Still call onUpdate and close the screen
      widget.onUpdate();
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Itinerary"),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: shareItinerary,
            tooltip: 'Share Itinerary',
          ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isLoading ? null : updateItinerary,
            tooltip: 'Save Itinerary',
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          elevation: 2,
                          margin: EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Trip Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 16),
                                TextFormField(
                                  controller: _destinationController,
                                  decoration: InputDecoration(
                                    labelText: "Destination",
                                    prefixIcon: Icon(Icons.location_on),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter a destination';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _startDateController,
                                        decoration: InputDecoration(
                                          labelText: "Start Date",
                                          prefixIcon: Icon(
                                            Icons.calendar_today,
                                          ),
                                          border: OutlineInputBorder(),
                                        ),
                                        readOnly: true,
                                        onTap:
                                            () => _selectDate(
                                              context,
                                              _startDateController,
                                            ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please select start date';
                                          }
                                          try {
                                            DateFormat(
                                              'yyyy-MM-dd',
                                            ).parse(value);
                                          } catch (e) {
                                            return 'Invalid date format';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _endDateController,
                                        decoration: InputDecoration(
                                          labelText: "End Date",
                                          prefixIcon: Icon(
                                            Icons.calendar_today,
                                          ),
                                          border: OutlineInputBorder(),
                                        ),
                                        readOnly: true,
                                        onTap:
                                            () => _selectDate(
                                              context,
                                              _endDateController,
                                            ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please select end date';
                                          }
                                          try {
                                            final endDate = DateFormat(
                                              'yyyy-MM-dd',
                                            ).parse(value);
                                            final startDate = DateFormat(
                                              'yyyy-MM-dd',
                                            ).parse(_startDateController.text);
                                            if (endDate.isBefore(startDate)) {
                                              return 'End date cannot be before start date';
                                            }
                                          } catch (e) {
                                            return 'Invalid date format';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _numberOfDaysController,
                                        decoration: InputDecoration(
                                          labelText: "Number of Days",
                                          prefixIcon: Icon(Icons.date_range),
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        readOnly:
                                            true, // Calculated automatically
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Required';
                                          }
                                          if (int.tryParse(value) == null ||
                                              int.parse(value) <= 0) {
                                            return 'Invalid number';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _travelTypeController,
                                        decoration: InputDecoration(
                                          labelText: "Travel Type",
                                          prefixIcon: Icon(
                                            Icons.airplanemode_active,
                                          ),
                                          border: OutlineInputBorder(),
                                          hintText: "e.g., Family, Business",
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Please enter travel type';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: itineraryPlaces.length,
                          itemBuilder: (context, dayIndex) {
                            return Card(
                              elevation: 2,
                              margin: EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Day ${dayIndex + 1} - ${_getDayDate(dayIndex)}",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "${itineraryPlaces[dayIndex].length} Places",
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  itineraryPlaces[dayIndex].isEmpty
                                      ? Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          "No places added for this day. Add your first place below.",
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      )
                                      : ReorderableListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount:
                                            itineraryPlaces[dayIndex].length,
                                        onReorder:
                                            (oldIndex, newIndex) =>
                                                reorderPlaces(
                                                  dayIndex,
                                                  oldIndex,
                                                  newIndex,
                                                ),
                                        itemBuilder: (context, placeIndex) {
                                          final placeItem =
                                              itineraryPlaces[dayIndex][placeIndex];

                                          // Try to get place name from multiple possible keys
                                          final placeName =
                                              placeItem['name'] ??
                                              placeItem['place'] ??
                                              "Unknown Place";

                                          // Display for debugging
                                          print(
                                            "Place item at Day ${dayIndex + 1}, Place ${placeIndex + 1}: $placeItem",
                                          );
                                          print("Using placeName: $placeName");

                                          return Card(
                                            key: ValueKey(
                                              "place_${dayIndex}_${placeIndex}",
                                            ),
                                            margin: EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 4,
                                            ),
                                            color: Colors.grey[50],
                                            child: ListTile(
                                              leading: CircleAvatar(
                                                child: Text(
                                                  "${placeIndex + 1}",
                                                ),
                                                backgroundColor:
                                                    Theme.of(
                                                      context,
                                                    ).primaryColor,
                                                foregroundColor: Colors.white,
                                              ),
                                              title: Text(
                                                placeName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              subtitle:
                                                  placeItem['time'] != null &&
                                                          placeItem['time']
                                                              .isNotEmpty
                                                      ? Text(placeItem['time'])
                                                      : null,
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.edit,
                                                      color: Colors.blue,
                                                    ),
                                                    onPressed:
                                                        () => editPlace(
                                                          dayIndex,
                                                          placeIndex,
                                                        ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    onPressed:
                                                        () => removePlace(
                                                          dayIndex,
                                                          placeIndex,
                                                        ),
                                                  ),
                                                  Icon(Icons.drag_handle),
                                                ],
                                              ),
                                              onTap:
                                                  () => editPlace(
                                                    dayIndex,
                                                    placeIndex,
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                  Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // Text field with suggestions
                                        TextField(
                                          controller: _newPlaceController,
                                          decoration: InputDecoration(
                                            labelText:
                                                "Add new place for Day ${dayIndex + 1}",
                                            border: OutlineInputBorder(),
                                            hintText: "Enter place name",
                                            suffixIcon:
                                                _isFetchingSuggestions
                                                    ? Container(
                                                      height: 20,
                                                      width: 20,
                                                      padding: EdgeInsets.all(
                                                        8,
                                                      ),
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                    )
                                                    : Icon(Icons.search),
                                          ),
                                          onSubmitted:
                                              (_) => addPlace(dayIndex),
                                        ),

                                        // Suggestions list
                                        if (_placeSuggestions.isNotEmpty)
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  NeverScrollableScrollPhysics(),
                                              itemCount:
                                                  _placeSuggestions.length > 5
                                                      ? 5
                                                      : _placeSuggestions
                                                          .length,
                                              itemBuilder: (context, index) {
                                                return ListTile(
                                                  title: Text(
                                                    _placeSuggestions[index],
                                                  ),
                                                  onTap: () {
                                                    setState(() {
                                                      _newPlaceController.text =
                                                          _placeSuggestions[index];
                                                      _placeSuggestions = [];
                                                    });
                                                  },
                                                );
                                              },
                                            ),
                                          ),

                                        SizedBox(height: 8),

                                        // Add button
                                        ElevatedButton.icon(
                                          icon: Icon(Icons.add),
                                          label: Text("Add Place"),
                                          onPressed: () => addPlace(dayIndex),
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: Icon(Icons.save),
                          label: Text("Save Itinerary"),
                          onPressed: _isLoading ? null : updateItinerary,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  String _getDayDate(int dayIndex) {
    try {
      final startDate = DateFormat(
        'yyyy-MM-dd',
      ).parse(_startDateController.text);
      final dayDate = startDate.add(Duration(days: dayIndex));
      return DateFormat('MMM d').format(dayDate); // Format as "Jan 1"
    } catch (e) {
      return "";
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _numberOfDaysController.dispose();
    _travelTypeController.dispose();
    _newPlaceController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void shareItinerary() {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text('Share Itinerary'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          labelText: 'Search users by email or username',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                          suffixIcon:
                              isSearching
                                  ? Container(
                                    height: 20,
                                    width: 20,
                                    padding: EdgeInsets.all(8),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : null,
                        ),
                        onSubmitted: (value) {
                          _searchUsers(value, setState);
                        },
                      ),
                      SizedBox(height: 10),
                      if (searchResults.isNotEmpty)
                        Container(
                          height: 200,
                          width: double.maxFinite,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(
                                  searchResults[index]['username'] ?? 'Unknown',
                                ),
                                subtitle: Text(
                                  searchResults[index]['email'] ?? '',
                                ),
                                trailing: ElevatedButton(
                                  child: Text('Invite'),
                                  onPressed: () {
                                    _addCollaborator(
                                      searchResults[index]['_id'],
                                    );
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (searchController.text.isNotEmpty) {
                          _searchUsers(searchController.text, setState);
                        }
                      },
                      child: Text('Search'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _searchUsers(String query, StateSetter setState) async {
    if (query.isEmpty) return;

    setState(() {
      isSearching = true;
    });

    try {
      final response = await http
          .get(Uri.parse('http://172.20.10.3:3000/searchUsers?query=$query'))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Connection timed out');
            },
          );

      setState(() {
        isSearching = false;
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          searchResults = List<Map<String, dynamic>>.from(data['users']);
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to search users')));
      }
    } catch (e) {
      setState(() {
        isSearching = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _addCollaborator(String collaboratorId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url =
          'http://172.20.10.3:3000/addCollaborator/${widget.itineraryId}';
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'collaboratorId': collaboratorId}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Connection timed out');
            },
          );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Collaborator added successfully')),
          );
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to add collaborator',
          );
        }
      } else {
        throw Exception('Failed to add collaborator');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/config.dart';
import '../yy_fyp/homePage.dart';

class UserPreferencesPage extends StatefulWidget {
  final String userId;
  const UserPreferencesPage({Key? key, required this.userId}) : super(key: key);

  @override
  _UserPreferencesPageState createState() => _UserPreferencesPageState();
}

class _UserPreferencesPageState extends State<UserPreferencesPage> {
  List<String> selectedActivities = [];
  List<String> selectedInterests = [];

  final List<String> allActivities = [
    "Hiking",
    "Shopping",
    "Food Tour",
    "Museum Visit",
    "Beach",
    "Nightlife",
  ];

  final List<String> allInterests = [
    "Adventure",
    "History",
    "Nature",
    "Culture",
    "Relaxation",
    "Foodie",
  ];

  bool isLoading = false;

  void savePreferences() async {
    setState(() => isLoading = true);

    var body = {
      "userId": widget.userId,
      "activityPreferences": selectedActivities,
      "interestCategories": selectedInterests,
    };

    try {
      var response = await http.post(
        Uri.parse(updatePreferences),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      var jsonResponse = jsonDecode(response.body);

      if (jsonResponse['status']) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => homePage(userId: widget.userId),
          ),
        );
      } else {
        _showSnackbar("Failed to save preferences.");
      }
    } catch (e) {
      _showSnackbar("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Choose Your Preferences",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    SizedBox(height: 20),

                    // Activities Section
                    _buildPreferencesSection(
                      "Select Activities:",
                      allActivities,
                      selectedActivities,
                    ),

                    SizedBox(height: 20),

                    // Interests Section
                    _buildPreferencesSection(
                      "Select Interests:",
                      allInterests,
                      selectedInterests,
                    ),

                    SizedBox(height: 30),
                    isLoading
                        ? CircularProgressIndicator()
                        : AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: LinearGradient(
                              colors: [Colors.orange, Colors.deepOrange],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: savePreferences,
                            child: Text(
                              "Save & Continue",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesSection(
    String title,
    List<String> options,
    List<String> selected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
        SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              options.map((option) {
                bool isSelected = selected.contains(option);
                return ChoiceChip(
                  label: Text(
                    option,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Colors.orange,
                  onSelected: (isSelected) {
                    setState(() {
                      if (isSelected) {
                        selected.add(option); // ✅ Add to the list if selected
                      } else {
                        selected.remove(
                          option,
                        ); // ✅ Remove from the list if deselected
                      }
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(
                      color: Colors.orange,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  backgroundColor: Colors.white,
                );
              }).toList(),
        ),
      ],
    );
  }
}

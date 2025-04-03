import 'package:flutter/material.dart';
import '../services/search.dart'; // Import SearchAPI

class AddPlaceScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onPlaceAdded;

  const AddPlaceScreen({Key? key, required this.onPlaceAdded})
    : super(key: key);

  @override
  _AddPlaceScreenState createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _suggestions = [];
  bool _isLoading = false;

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    List<String> results = await SearchAPI.getPlaceSuggestions(query);
    setState(() {
      _suggestions = results;
    });
  }

  void _onPlaceSelected(String placeName) async {
    setState(() => _isLoading = true);

    Map<String, dynamic>? placeDetails = await SearchAPI.getPlaceDetails(
      placeName,
    );

    setState(() => _isLoading = false);

    if (placeDetails != null) {
      widget.onPlaceAdded(placeDetails);
      Navigator.pop(context); // Close screen after adding
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to get place details")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Search Place"),
        backgroundColor: Color(0xFF0CB9CE),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Search for a place",
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _suggestions = [];
                            });
                          },
                        )
                        : null,
              ),
              onChanged: _onSearchChanged,
            ),
            if (_isLoading) CircularProgressIndicator(),
            Expanded(
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_suggestions[index]),
                    onTap: () => _onPlaceSelected(_suggestions[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class ItineraryScreen extends StatelessWidget {
  final List<List<Map<String, dynamic>>> itinerary;

  const ItineraryScreen({super.key, required this.itinerary});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Generated Itinerary")),
      body:
          itinerary.isEmpty
              ? Center(child: Text("No itinerary available"))
              : ListView.builder(
                itemCount: itinerary.length,
                itemBuilder: (context, dayIndex) {
                  return Card(
                    margin: EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Text(
                          "Day ${dayIndex + 1}",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Column(
                          children:
                              itinerary[dayIndex]
                                  .map(
                                    (place) => ListTile(
                                      title: Text(place['name']),
                                      subtitle: Text(
                                        "Rating: ${place['rating']}",
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}

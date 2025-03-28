import 'package:flutter/material.dart';

class ItineraryScreen extends StatelessWidget {
  final String userId;
  final List<List<Map<String, dynamic>>> itinerary; // ✅ Accept itinerary

  const ItineraryScreen({
    Key? key,
    required this.userId,
    required this.itinerary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your Itinerary')),
      body:
          itinerary.isEmpty
              ? Center(
                child: Text(
                  'No itinerary found. Please generate one!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              )
              : ListView.builder(
                itemCount: itinerary.length,
                itemBuilder: (context, dayIndex) {
                  return Card(
                    margin: EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      title: Text(
                        'Day ${dayIndex + 1}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children:
                          itinerary[dayIndex].map((place) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    place['photoUrl'] != null
                                        ? NetworkImage(place['photoUrl'])
                                        : AssetImage('assets/no_image.png')
                                            as ImageProvider,
                              ),
                              title: Text(
                                place['name'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Rating: ${place['rating'] ?? "N/A"}',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }).toList(),
                    ),
                  );
                },
              ),
    );
  }
}

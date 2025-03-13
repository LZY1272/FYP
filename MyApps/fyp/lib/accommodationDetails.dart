import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'routes.dart';

class accommodationDetails extends StatelessWidget {
  final String name;
  final String image;
  final int stars;
  final String address;
  final String contact;
  final double price;
  final String selectedDateRange;
  final int selectedBeds;
  final int selectedGuests;

  accommodationDetails({
    required this.name,
    required this.image,
    required this.stars,
    required this.address,
    required this.contact,
    required this.price,
    required this.selectedDateRange,
    required this.selectedBeds,
    required this.selectedGuests,
  });

  // 🔹 Function to open Booking.com link
  void _launchBookingSite() async {
    final Uri url = Uri.parse("https://www.booking.com/searchresults.html?ss=$name");
    if (!await launchUrl(url)) {
      throw 'Could not open $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Accommodations")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Hotel Name
            Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),

            // 🔹 Stars
            Row(
              children: List.generate(stars, (index) => Icon(Icons.star, color: Colors.amber, size: 18)),
            ),
            SizedBox(height: 8),

            // 🔹 Address & Contact
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue),
                SizedBox(width: 5),
                Expanded(child: Text(address, style: TextStyle(fontSize: 16))),
              ],
            ),
            SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.phone, color: Colors.blue),
                SizedBox(width: 5),
                Text(contact, style: TextStyle(fontSize: 16, color: Colors.blue)),
              ],
            ),
            SizedBox(height: 10),

            // 🔹 Hotel Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                image,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset("assets/no_image.png", width: double.infinity, height: 200);
                },
              ),
            ),
            SizedBox(height: 15),

            // 🔹 Travel Details
            Text("View prices for your travel dates", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            // 🔹 Date Container
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, color: Colors.blue),
                  SizedBox(width: 5),
                  Text(selectedDateRange, style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            SizedBox(height: 10),

            // 🔹 Bed & Guest Count
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bed, color: Colors.blue),
                        SizedBox(width: 5),
                        Text("$selectedBeds Beds", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people, color: Colors.blue),
                        SizedBox(width: 5),
                        Text("$selectedGuests Guests", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),

            // 🔹 Price
            Text("RM $price", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),

            // 🔹 Buttons (View Routes & View Deals)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoutesPage(destination: name),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: Text("View Routes", style: TextStyle(fontSize: 18)),
                ),
                ElevatedButton(
                  onPressed: _launchBookingSite,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: Text("View Deals", style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

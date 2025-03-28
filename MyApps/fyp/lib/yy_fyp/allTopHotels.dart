import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class seeAllHotels extends StatefulWidget {
  seeAllHotels();

  @override
  _SeeAllHotelsState createState() => _SeeAllHotelsState();
}

class _SeeAllHotelsState extends State<seeAllHotels> {
  List<Map<String, dynamic>> hotels = [];
  bool isLoading = true;
  static const String kualaLumpurDestId = "-2403010"; // ✅ Always use KL

  @override
  void initState() {
    super.initState();
    fetchAllHotels();
  }

  // 🔹 Function to open Booking.com link
  void _launchBookingSite(String hotelName) async {
    final Uri url = Uri.parse("https://www.booking.com/searchresults.html?ss=${Uri.encodeComponent(hotelName)}");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      print('❌ Could not open $url');
    }
  }

  Future<void> fetchAllHotels() async {
    final String apiUrl =
        "https://booking-com.p.rapidapi.com/v1/hotels/search"
        "?dest_id=$kualaLumpurDestId"
        "&dest_type=city"
        "&checkin_date=2026-06-01"
        "&checkout_date=2026-06-05"
        "&adults_number=2"
        "&room_number=1"
        "&order_by=popularity"
        "&locale=en-gb"
        "&filter_by_currency=MYR"
        "&units=metric"; // ✅ Ensure required params are included

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          "X-RapidAPI-Key": "99d0568adcmsh612a2ca3d0334f9p15fdf5jsndc687769b285", // Replace with your API key
          "X-RapidAPI-Host": "booking-com.p.rapidapi.com",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["result"] is List) {
          setState(() {
            hotels = List<Map<String, dynamic>>.from(data["result"].map((hotel) => {
              "name": hotel["hotel_name"] ?? "No Name",
              "price": double.tryParse(hotel["price_breakdown"]?["gross_price"]?.toString() ?? "0")?.toInt() ?? 0, // ✅ Convert safely
              "stars": (hotel["class"] ?? 0).toInt(), // ✅ Ensure stars are int
              "image": hotel["main_photo_url"] ?? "assets/no_image.png",
              "url": hotel["url"] ?? "#",
            }));
            isLoading = false;
          });
        }
      } else {
        print("❌ API Error (See All Hotels): ${response.statusCode}");
        print("📩 Raw API Response: ${response.body}");
      }
    } catch (e) {
      print("🚨 Exception: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("All Top Hotels in Kuala Lumpur")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : hotels.isEmpty
              ? Center(child: Text("No hotels found"))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: hotels.length,
                  itemBuilder: (context, index) {
                    final hotel = hotels[index];
                    return _buildHotelCard(hotel);
                  },
                ),
    );
  }

  Widget _buildHotelCard(Map<String, dynamic> hotel) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 4,
      child: ListTile(
        contentPadding: EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            hotel["image"],
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset("assets/no_image.png", width: 80, height: 80);
            },
          ),
        ),
        title: Text(hotel["name"], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("RM ${hotel["price"]}", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            Row(
              children: List.generate(hotel["stars"], (index) => Icon(Icons.star, color: Colors.amber, size: 16)),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.open_in_new),
          onPressed: () => _launchBookingSite(hotel["name"]),
        ),
      ),
    );
  }
}

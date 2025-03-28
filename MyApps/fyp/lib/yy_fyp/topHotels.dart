import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'allTopHotels.dart'; // Import the See All page
import 'package:url_launcher/url_launcher.dart';

class topHotels extends StatefulWidget {
  final String destination;
  topHotels({required this.destination}); // ✅ Ensure destination is required

  @override
  _TopHotelsState createState() => _TopHotelsState();
}

class _TopHotelsState extends State<topHotels> {
  List<Map<String, dynamic>> topHotels = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTopHotels();
  }

  // 🔹 Function to open Booking.com link
  void _launchBookingSite(String hotelName) async {
    final Uri url = Uri.parse("https://www.booking.com/searchresults.html?ss=${Uri.encodeComponent(hotelName)}");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      print('❌ Could not open $url');
    }
  }

  // 🔹 Fetch Destination ID before getting top hotels
  Future<String> getDestinationId() async {
  // ✅ Always return Kuala Lumpur's destination ID
  return "-2403010"; 
}

  // 🔹 Fetch Top Hotels
  Future<void> fetchTopHotels() async {
  String destId = "-2403010"; // ✅ Hardcoded Kuala Lumpur destination ID

  final String apiUrl = "https://booking-com.p.rapidapi.com/v1/hotels/search";

  try {
    final response = await http.get(
      Uri.parse("$apiUrl?dest_id=$destId&dest_type=city&checkin_date=2026-06-01&checkout_date=2026-06-05&adults_number=2&room_number=1&order_by=popularity&locale=en-gb&filter_by_currency=MYR&units=metric"),
      headers: {
        //"X-RapidAPI-Key": "99d0568adcmsh612a2ca3d0334f9p15fdf5jsndc687769b285",
        "X-RapidAPI-Host": "booking-com.p.rapidapi.com"
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["result"] is List) {
        setState(() {
          topHotels = List<Map<String, dynamic>>.from(data["result"].take(5).map((hotel) => {
            "name": hotel["hotel_name"] ?? "No Name",
            "price": double.tryParse(hotel["price_breakdown"]?["gross_price"]?.toString() ?? "0")?.toInt() ?? 0, // ✅ Handle null
            "stars": (hotel["class"] ?? 0).toInt(),
            "image": hotel["main_photo_url"] ?? "assets/no_image.png",
            "bookingUrl": hotel["url"] ?? "#"
          }));
          isLoading = false;
        });
      } else {
        print("❌ Unexpected API Response: ${data["result"]}");
      }
    } else {
      print("❌ API Error (Top Hotels): ${response.statusCode}");
      print("📩 Raw API Response: ${response.body}");
    }
  } catch (e) {
    print("🚨 Error fetching top hotels: $e");
  }

  setState(() => isLoading = false);
}


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSectionTitle("Top Hotels", context),
        isLoading
            ? Center(child: CircularProgressIndicator())
            : topHotels.isEmpty
                ? Center(child: Text("No hotels found"))
                : _buildHorizontalList(topHotels),
      ],
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => seeAllHotels(),
              ));
            },
            child: Text("See all"),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalList(List<Map<String, dynamic>> hotels) {
    return SizedBox(
      height: 400,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hotels.length,
        itemBuilder: (context, index) {
          return _buildHotelCard(hotels[index]);
        },
      ),
    );
  }

  Widget _buildHotelCard(Map<String, dynamic> hotel) {
    return GestureDetector(
      onTap: () => _launchBookingSite(hotel["name"]),
      child: Padding(
        padding: EdgeInsets.only(left: 16),
        child: Container(
          width: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: hotel["image"] != null && hotel["image"]!.isNotEmpty
                    ? Image.network(hotel["image"], height: 100, width: 150, fit: BoxFit.cover)
                    : Container(
                        height: 100,
                        width: 150,
                        color: Colors.grey[300],
                        child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
                      ),
              ),
              SizedBox(height: 5),
              Text(hotel["name"], style: TextStyle(fontWeight: FontWeight.bold)),
              Text("RM ${hotel["price"]}", style: TextStyle(color: Colors.green)),
              Row(
                children: List.generate(
                  hotel["stars"], 
                  (index) => Icon(Icons.star, color: Colors.amber, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

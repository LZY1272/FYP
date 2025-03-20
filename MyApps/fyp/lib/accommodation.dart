import 'package:flutter/material.dart';
import 'package:fyp/homePage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // For date formatting
import 'accommodationList.dart';
import 'topHotels.dart'; // ✅ Import Top Hotels section
import 'allTopHotels.dart'; // ✅ Import See All Hotels page
import 'package:shared_preferences/shared_preferences.dart';

class accommodationsPage extends StatefulWidget {
  @override
  _AccommodationsPageState createState() => _AccommodationsPageState();
}

class _AccommodationsPageState extends State<accommodationsPage> {
  final TextEditingController destinationController = TextEditingController();
  DateTime? checkInDate;
  DateTime? checkOutDate;
  int selectedBeds = 1;
  int selectedGuests = 1;
  bool isLoading = false;
  List<String> suggestions = [];
  OverlayEntry? overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool isLoadingSuggestions = false;

  // 🔹 Fetch Destination Suggestions from API
  Future<void> fetchDestinationSuggestions(String query) async {
    if (query.isEmpty) return;

    print("🔍 Fetching destinations for query: $query");

    setState(() {
      isLoadingSuggestions = true;
    });

    final String apiUrl =
        "https://booking-com.p.rapidapi.com/v1/hotels/locations?name=$query&locale=en-gb";
    
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          "X-RapidAPI-Key": "da6baaaa31msh2a7ee36c4be592fp177311jsnfe3b9cc43c04",  // 🔹 Replace with your API key
          "X-RapidAPI-Host": "booking-com.p.rapidapi.com"
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          suggestions = data
              .map<String>((item) => item["name"].toString()) // Extract city names
              .toList();
          isLoading = false;
        });
      } else {
        print("❌ API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("🚨 Exception: $e");
    }
  }

  // 🔹 Fetch hotels from the backend
  Future<List<Map<String, dynamic>>> fetchHotels(String destination) async {
    if (checkInDate == null || checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select check-in and check-out dates"))
      );
      return [];
    }

    final String formattedCheckIn = DateFormat('yyyy-MM-dd').format(checkInDate!);
    final String formattedCheckOut = DateFormat('yyyy-MM-dd').format(checkOutDate!);

    final String apiUrl =
        "http://10.0.2.2:8000/hotels?destination=$destination&checkin=$formattedCheckIn&checkout=$formattedCheckOut&guests=$selectedGuests&rooms=$selectedBeds";

    try {
      print("🔍 Fetching hotels from backend: $apiUrl");
      final response = await http.get(Uri.parse(apiUrl)).timeout(Duration(seconds: 20));

      print("📩 Response: ${response.body}"); // Debugging log

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["hotels"] is List) {
          return List<Map<String, dynamic>>.from(data["hotels"]);
        } else {
          print("❌ Unexpected data format: ${data["hotels"]}");
          return [];
        }
      } else {
        print("❌ API Error: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("🚨 Exception: $e");
      return [];
    }
  }

  void findHotels() async {
    String destination = destinationController.text;
    if (destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a destination"))
      );
      return;
    }

    // ✅ Store city destination in SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_destination', destination);
    print("✔️ Destination saved: $destination");  // Debugging

    setState(() {
      isLoading = true;
    });

    List<Map<String, dynamic>> hotels = (await fetchHotels(destination)).map((hotel) => {
      "name": hotel["hotel_name"] ?? "No Name",
      "price": hotel["price_breakdown"]?["gross_price"]?.toString() ?? "N/A",
      "stars": hotel["class"] ?? 0,
      "image": hotel["main_photo_url"] ?? "assets/no_image.png",
      "address": hotel["address"] ?? "Unknown",
      "contact": hotel["contact"] ?? "N/A",
      "bookingUrl": hotel["url"] ?? "#"
    }).toList();


    setState(() {
      
      isLoading = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => accommodationList(
          destination: destination,
          selectedDateRange: "${DateFormat('MMM dd').format(checkInDate!)} - ${DateFormat('MMM dd').format(checkOutDate!)}",
          selectedBeds: selectedBeds,
          selectedGuests: selectedGuests,
          hotels: hotels, 
        ),
      ),
    );
  }

  // 🔹 Show Date Picker
  Future<void> selectDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        checkInDate = picked.start;
        checkOutDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Accommodations")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            CompositedTransformTarget(
              link: _layerLink,
              child: Column(
                children: [
                TextField(
                controller: destinationController,
                decoration: InputDecoration(
                  labelText: "Destination",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: fetchDestinationSuggestions,
              ),
              // 🔹 Show Suggestions Dropdown
                  if (suggestions.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(8.0),
                      color: Colors.white,
                      child: Column(
                        children: suggestions.map((suggestion) {
                          return ListTile(
                            title: Text(suggestion),
                            onTap: () {
                              destinationController.text = suggestion;
                              setState(() {
                                suggestions = [];
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ), 
            SizedBox(height: 12),

            // 🔹 Date Picker
            GestureDetector(
              onTap: selectDateRange,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.calendar_today, color: Colors.blue),
                    Text(
                      checkInDate == null || checkOutDate == null
                          ? "Enter Dates"
                          : "${DateFormat('MMM dd').format(checkInDate!)} - ${DateFormat('MMM dd').format(checkOutDate!)}",
                      style: TextStyle(fontSize: 16),
                    ),
                    Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),

            // 🔹 Beds & Guests Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Beds
                Column(
                  children: [
                    Text("Beds", style: TextStyle(fontSize: 16)),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            if (selectedBeds > 1) {
                              setState(() {
                                selectedBeds--;
                              });
                            }
                          },
                        ),
                        Text("$selectedBeds", style: TextStyle(fontSize: 16)),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              selectedBeds++;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                // Guests
                Column(
                  children: [
                    Text("Guests", style: TextStyle(fontSize: 16)),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            if (selectedGuests > 1) {
                              setState(() {
                                selectedGuests--;
                              });
                            }
                          },
                        ),
                        Text("$selectedGuests", style: TextStyle(fontSize: 16)),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              selectedGuests++;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),

            // 🔹 Find Hotels Button
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: findHotels,
                    child: Text("Find Hotels", style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                  // ✅ TOP HOTELS SECTION BELOW
              SizedBox(height: 20),
              topHotels(destination: destinationController.text), // ✅ Display Top Hotels section here
          ],
        ),
      ),
    );
  }
}
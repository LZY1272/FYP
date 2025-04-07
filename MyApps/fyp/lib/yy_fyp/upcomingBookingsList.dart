import 'package:flutter/material.dart';
import 'package:fyp/yy_fyp/upcomingBookings.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../screens/currentUser.dart'; // Import Currentuser

class UpcomingBookingsList extends StatefulWidget {
  @override
  _UpcomingBookingsListState createState() => _UpcomingBookingsListState();
}

class _UpcomingBookingsListState extends State<UpcomingBookingsList> {
  List<Map<String, dynamic>> paidBookings = [];
  bool isLoading = true;
  String _sortBy = "date_recent"; // Default sort option
  String? errorMessage;
  String? userId; // Store userId

  @override
  void initState() {
    super.initState();
    userId = Currentuser.getUserId(); // Retrieve stored userId
    if (userId == null) {
      setState(() {
        errorMessage = "⚠️ User not logged in.";
        isLoading = false;
      });
    } else {
      fetchPaidBookings();
    }
  }

  Future<void> fetchPaidBookings() async {
    try {
      print("Fetching paid bookings for userId: $userId");

      final response = await http.get(
        Uri.parse(
          'http://172.20.10.3:3000/paid?userId=${Uri.encodeComponent(userId!)}',
        ),
      );

      if (response.statusCode == 200) {
        print("API response received: ${response.body}");

        // Parse the response which has a different structure
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Check if data field exists and is a list
        if (responseData.containsKey('data') && responseData['data'] is List) {
          setState(() {
            paidBookings = List<Map<String, dynamic>>.from(
              responseData['data'],
            );
            isLoading = false;
          });
          _sortBookings();
        } else {
          setState(() {
            errorMessage = 'Invalid data format in response';
            isLoading = false;
          });
        }
      } else {
        print("API error: ${response.statusCode} - ${response.body}");
        setState(() {
          errorMessage = 'Failed to load paid bookings: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      print("Exception occurred: $e");
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  void _sortBookings() {
    setState(() {
      if (_sortBy == "price_low") {
        paidBookings.sort((a, b) {
          num priceA = 0.0;
          num priceB = 0.0;
          try {
            priceA =
                a["price"] is num
                    ? a["price"]
                    : double.tryParse(a["price"].toString()) ?? 0.0;
            priceB =
                b["price"] is num
                    ? b["price"]
                    : double.tryParse(b["price"].toString()) ?? 0.0;
          } catch (e) {
            print("Error parsing price: $e");
          }
          return priceA.compareTo(priceB);
        });
      } else if (_sortBy == "price_high") {
        paidBookings.sort((a, b) {
          num priceA = 0.0;
          num priceB = 0.0;
          try {
            priceA =
                a["price"] is num
                    ? a["price"]
                    : double.tryParse(a["price"].toString()) ?? 0.0;
            priceB =
                b["price"] is num
                    ? b["price"]
                    : double.tryParse(b["price"].toString()) ?? 0.0;
          } catch (e) {
            print("Error parsing price: $e");
          }
          return priceB.compareTo(priceA);
        });
      } else if (_sortBy == "date_recent") {
        // Sort by paymentDate if available, otherwise use dateRange
        paidBookings.sort((a, b) {
          String dateA =
              a["paymentDate"]?.toString() ?? a["dateRange"]?.toString() ?? "";
          String dateB =
              b["paymentDate"]?.toString() ?? b["dateRange"]?.toString() ?? "";
          return dateB.compareTo(dateA);
        });
      } else if (_sortBy == "date_oldest") {
        paidBookings.sort((a, b) {
          String dateA =
              a["paymentDate"]?.toString() ?? a["dateRange"]?.toString() ?? "";
          String dateB =
              b["paymentDate"]?.toString() ?? b["dateRange"]?.toString() ?? "";
          return dateA.compareTo(dateB);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Upcoming Bookings")),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : Column(
                children: [
                  // 🔹 Sort By Dropdown
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text("Sort by: ", style: TextStyle(fontSize: 16)),
                        DropdownButton<String>(
                          value: _sortBy,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _sortBy = newValue;
                                _sortBookings();
                              });
                            }
                          },
                          items: [
                            DropdownMenuItem(
                              value: "date_recent",
                              child: Text("Date (Recent First)"),
                            ),
                            DropdownMenuItem(
                              value: "date_oldest",
                              child: Text("Date (Oldest First)"),
                            ),
                            DropdownMenuItem(
                              value: "price_low",
                              child: Text("Price (Low to High)"),
                            ),
                            DropdownMenuItem(
                              value: "price_high",
                              child: Text("Price (High to Low)"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 🔹 Paid Bookings List
                  Expanded(
                    child:
                        paidBookings.isEmpty
                            ? Center(child: Text("No upcoming bookings found"))
                            : ListView.builder(
                              padding: EdgeInsets.all(16),
                              itemCount: paidBookings.length,
                              itemBuilder: (context, index) {
                                final booking = paidBookings[index];

                                return Card(
                                  margin: EdgeInsets.only(bottom: 12),
                                  elevation: 4,
                                  child: ListTile(
                                    contentPadding: EdgeInsets.all(10),
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        booking["image"] ??
                                            "https://placeholder.com/80x80",
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Image.asset(
                                            "assets/no_image.png",
                                            width: 80,
                                            height: 80,
                                          );
                                        },
                                      ),
                                    ),
                                    title: Text(
                                      booking["hotelName"] ?? "Unknown Hotel",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "RM ${booking["price"]?.toString() ?? '0.00'}",
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "Date: ${booking["dateRange"] ?? 'N/A'}",
                                        ),
                                        Text(
                                          "Guests: ${booking["guests"]?.toString() ?? '1'} | Rooms: ${booking["rooms"]?.toString() ?? '1'}",
                                        ),
                                        Text(
                                          "Payment: ${booking["paymentMethod"] ?? 'Credit/Debit Card'}",
                                        ),
                                        if (booking["status"] != null)
                                          Text(
                                            "Status: ${booking["status"]}",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  booking["status"] ==
                                                          "Confirmed"
                                                      ? Colors.green
                                                      : Colors.orange,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => UpcomingBookings(
                                                  booking:
                                                      booking, // Pass the entire booking object
                                                ),
                                          ),
                                        );
                                      },
                                      child: Text("View Details"),
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}

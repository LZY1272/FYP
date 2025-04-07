import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'bookingConfirmation.dart';
import '../screens/currentUser.dart'; // Import Currentuser

class bookingConfirmationList extends StatefulWidget {
  @override
  _bookingConfirmationListState createState() =>
      _bookingConfirmationListState();
}

class _bookingConfirmationListState extends State<bookingConfirmationList> {
  List<Map<String, dynamic>> bookings = [];
  bool isLoading = true;
  String _sortBy = "date_recent"; // Default sort option
  String? errorMessage;
  String? userId; // Store userId

  void _navigateToBookingConfirmation(Map<String, dynamic> booking) async {
    // Navigate and wait for result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => bookingConfirmation(
              hotelName: booking["hotelName"] ?? "Unknown Hotel",
              image: booking["image"] ?? "assets/no_image.png",
              dateRange: booking["dateRange"] ?? "N/A",
              guests: booking["guests"] ?? 1,
              rooms: booking["rooms"] ?? 1,
              price: booking["price"] ?? 0.0,
            ),
      ),
    );

    // If payment was successful, refresh the booking list
    if (result == 'paid') {
      fetchBookings();
    }
  }

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
      fetchBookings();
    }
  }

  Future<void> filterOutPaidBookings() async {
    try {
      // Fetch the list of paid bookings for this user
      final paidResponse = await http.get(
        Uri.parse(
          'http://172.20.10.3:3000/paid?userId=${Uri.encodeComponent(userId!)}',
        ),
      );

      if (paidResponse.statusCode == 200) {
        // Check the structure of the response
        final responseData = json.decode(paidResponse.body);
        List<dynamic> paidData;

        // Handle different response formats
        if (responseData is List) {
          // If it's already a list
          paidData = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          // If it's an object with a data field containing the array
          paidData = responseData['data'];
        } else {
          // Fallback - try to extract any useful data
          print("Unexpected response format: ${paidResponse.body}");
          return;
        }

        // Debug
        print("Paid bookings data: $paidData");

        final List<String> paidHotelDates = [];

        // Create unique identifiers for paid bookings
        for (var item in paidData) {
          if (item is Map) {
            String hotelName = item['hotelName']?.toString() ?? '';
            String dateRange = item['dateRange']?.toString() ?? '';
            if (hotelName.isNotEmpty && dateRange.isNotEmpty) {
              paidHotelDates.add("${hotelName}_${dateRange}");
            }
          }
        }

        print("Paid hotel dates: $paidHotelDates");

        // Filter out bookings that match our paid bookings
        setState(() {
          bookings =
              bookings.where((booking) {
                String bookingId =
                    "${booking['hotelName']}_${booking['dateRange']}";
                return !paidHotelDates.contains(bookingId);
              }).toList();
        });
      }
    } catch (e) {
      print("Error filtering paid bookings: $e");
      // Print more details about the error
      print(e.toString());
    }
  }

  Future<void> fetchBookings() async {
    try {
      print("Fetching bookings for userId: $userId");

      final response = await http.get(
        Uri.parse(
          'http://172.20.10.3:3000/bookings?userId=${Uri.encodeComponent(userId!)}',
        ),
      );

      if (response.statusCode == 200) {
        print("API response received: ${response.body}");
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          bookings = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
        _sortBookings();

        await filterOutPaidBookings();
      } else {
        print("API error: ${response.statusCode} - ${response.body}");
        setState(() {
          errorMessage = 'Failed to load bookings: ${response.statusCode}';
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
        bookings.sort((a, b) {
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
        bookings.sort((a, b) {
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
        // Safely compare date strings
        bookings.sort((a, b) {
          String dateA = a["dateRange"]?.toString() ?? "";
          String dateB = b["dateRange"]?.toString() ?? "";
          return dateB.compareTo(dateA);
        });
      } else if (_sortBy == "date_oldest") {
        bookings.sort((a, b) {
          String dateA = a["dateRange"]?.toString() ?? "";
          String dateB = b["dateRange"]?.toString() ?? "";
          return dateA.compareTo(dateB);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Bookings")),
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

                  // 🔹 Bookings List
                  Expanded(
                    child:
                        bookings.isEmpty
                            ? Center(child: Text("No bookings found"))
                            : ListView.builder(
                              padding: EdgeInsets.all(16),
                              itemCount: bookings.length,
                              itemBuilder: (context, index) {
                                final booking = bookings[index];

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
                                      ],
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: () {
                                        _navigateToBookingConfirmation(booking);
                                      },
                                      child: Text("Confirm"),
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

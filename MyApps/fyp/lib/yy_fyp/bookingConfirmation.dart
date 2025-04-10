import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fyp/screens/currentUser.dart';
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class bookingConfirmation extends StatefulWidget {
  final String hotelName;
  final String image;
  final String dateRange;
  final dynamic guests;
  final dynamic rooms;
  final dynamic price;

  bookingConfirmation({
    required this.hotelName,
    required this.image,
    required this.dateRange,
    required this.guests,
    required this.rooms,
    required this.price,
  });

  @override
  _BookingConfirmationState createState() => _BookingConfirmationState();
}

class _BookingConfirmationState extends State<bookingConfirmation> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isPaid = false;

  // Safely convert dynamic values to appropriate types
  late int guestsInt;
  late int roomsInt;
  late double priceDouble;

  @override
  void initState() {
    super.initState();
    _convertValues();
    _initializeNotifications().then((_) {
    print("Notifications initialized successfully");
  }).catchError((error) {
    print("Failed to initialize notifications: $error");
  });
  }

  Future<void> _initializeNotifications() async {
  tz_data.initializeTimeZones();
  
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
      // Handle notification tapped logic here if needed
    },
  );
}

Future<void> _scheduleUpcomingBookingNotification() async {
  try {
    // Parse the date range to get start date
    final dateRangeParts = widget.dateRange.split(" - ");
    final startDateStr = dateRangeParts[0];
    
    print("Date Range: ${widget.dateRange}");
    print("Start Date String: $startDateStr");
    
    // Parse the start date (format "MMM dd")
    final now = DateTime.now();
    print("Current date and time: $now");
    
    // More robust date parsing
    RegExp dateRegex = RegExp(r'(\w+)\s+(\d+)');
    var match = dateRegex.firstMatch(startDateStr);
    
    if (match == null) {
      print("Failed to parse date string: $startDateStr");
      // Show notification anyway as a fallback
      await _showUpcomingBookingNotification();
      return;
    }
    
    final monthStr = match.group(1);
    final dayStr = match.group(2);
    
    print("Extracted month: $monthStr, day: $dayStr");
    
    final month = _getMonthNumber(monthStr!);
    final day = int.parse(dayStr!);
    
    print("Parsed month number: $month, day: $day");
    
    // Create date for booking (assuming current year)
    final bookingDate = DateTime(now.year, month, day);
    print("Initial booking date: $bookingDate");
    
    // Create date-only version of now for proper comparison (without time component)
    final nowDateOnly = DateTime(now.year, now.month, now.day);
    
    // If date has passed for this year, assume it's for next year
    // Compare only date portions, not time
    final adjustedBookingDate = bookingDate.isBefore(nowDateOnly) 
        ? DateTime(now.year + 1, month, day)
        : bookingDate;
    
    print("Adjusted booking date: $adjustedBookingDate");
    
    // Calculate time difference
    final difference = adjustedBookingDate.difference(now);
    print("Hours until booking: ${difference.inHours}");
    
    // Show notification immediately if booking is less than 24 hours away
    if (difference.inHours < 24) {
      print("Booking is less than 24 hours away, showing notification");
      await _showUpcomingBookingNotification();
    } else {
      print("Booking is more than 24 hours away, no notification needed");
    }
  } catch (e) {
    print("Error in scheduling notification: $e");
    // Show notification anyway as a fallback
    await _showUpcomingBookingNotification();
  }
}

int _getMonthNumber(String monthAbbr) {
  const months = {
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,
    'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8, 
    'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
  };
  return months[monthAbbr] ?? 1;
}

Future<void> _showUpcomingBookingNotification() async {
  try {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'hotel_booking_channel',
      'Hotel Booking Notifications',
      channelDescription: 'Notifications for upcoming hotel bookings',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await flutterLocalNotificationsPlugin.show(
      0,
      'Upcoming Booking Reminder',
      'Your stay at ${widget.hotelName} is coming up in less than 24 hours!',
      platformChannelSpecifics,
    );
    print("Notification triggered successfully");
  } catch (e) {
    print("Error showing notification: $e");
  }
}

  void _convertValues() {
    guestsInt = 1;
    roomsInt = 1;
    priceDouble = 0.0;

    try {
      if (widget.guests is int) {
        guestsInt = widget.guests;
      } else if (widget.guests is String) {
        guestsInt = int.tryParse(widget.guests) ?? 1;
      } else if (widget.guests is double) {
        guestsInt = widget.guests.toInt();
      }

      if (widget.rooms is int) {
        roomsInt = widget.rooms;
      } else if (widget.rooms is String) {
        roomsInt = int.tryParse(widget.rooms) ?? 1;
      } else if (widget.rooms is double) {
        roomsInt = widget.rooms.toInt();
      }

      if (widget.price is double) {
        priceDouble = widget.price;
      } else if (widget.price is int) {
        priceDouble = widget.price.toDouble();
      } else if (widget.price is String) {
        priceDouble = double.tryParse(widget.price) ?? 0.0;
      }
    } catch (e) {
      print("Error converting values: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Booking Confirmation"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hotel Image
            Container(
              width: double.infinity,
              height: 200,
              child: Image.network(
                widget.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset("assets/no_image.png", fit: BoxFit.cover);
                },
              ),
            ),

            // Booking Details
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hotel Name
                  Text(
                    widget.hotelName,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),

                  // Booking Info Card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Booking Header
                          Container(
                            padding: EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isPaid ? Icons.check_circle : Icons.pending,
                                  color: _isPaid ? Colors.green : Colors.orange,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  _isPaid
                                      ? "Confirmed & Paid"
                                      : "Confirmed - Payment Pending",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),

                          // Stay dates
                          _buildInfoRow(
                            Icons.calendar_today,
                            "Stay Dates",
                            widget.dateRange,
                          ),

                          // Guests & Rooms
                          _buildInfoRow(
                            Icons.people,
                            "Guests",
                            "$guestsInt guest${guestsInt > 1 ? 's' : ''}",
                          ),
                          _buildInfoRow(
                            Icons.hotel,
                            "Rooms",
                            "$roomsInt room${roomsInt > 1 ? 's' : ''}",
                          ),

                          // Price
                          _buildInfoRow(
                            Icons.monetization_on,
                            "Total Price",
                            "RM ${priceDouble.toStringAsFixed(2)}",
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Payment Button
                  if (!_isPaid)
                    Container(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.payment),
                        label: Text("Pay Now"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          _showPaymentOptions();
                        },
                      ),
                    ),

                  if (!_isPaid) SizedBox(height: 12),

                  // Cancel Booking Button
                  Container(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.cancel, color: Colors.red),
                      label: Text(
                        "Cancel Booking",
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.red),
                      ),
                      onPressed: () {
                        // Implement booking cancellation
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Cancel Booking"),
                              content: Text(
                                "Are you sure you want to cancel this booking?",
                              ),
                              actions: [
                                TextButton(
                                  child: Text("No"),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                TextButton(
                                  child: Text(
                                    "Yes",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Cancellation feature not implemented yet",
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.45,
          decoration: BoxDecoration(
            color: Colors.teal[100],
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Payment Options:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              // Touch & Go eWallet
              _buildPaymentOption(
                icon: 'assets/tng_icon.png', // Add this asset or use an icon
                title: "Touch & Go eWallet",
                isSelected: true,
                onTap: () {
                  Navigator.pop(context);
                  _showTouchNGoPayment();
                },
              ),

              // Online Banking
              _buildPaymentOption(
                icon: null, // Replace with online banking icon
                iconData: Icons.account_balance,
                title: "Online Banking",
                isSelected: false,
                onTap: () {
                  Navigator.pop(context);
                  _showOnlineBankingOptions();
                },
              ),

              // Credit/Debit Card
              _buildPaymentOption(
                icon: null, // Replace with card icon
                iconData: Icons.credit_card,
                title: "Visa / MasterCard",
                isSelected: false,
                onTap: () {
                  Navigator.pop(context);
                  _showCardPayment();
                },
              ),

              Spacer(),

              // Confirm Button
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: ElevatedButton(
                  child: Text("Confirm"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _authenticateAndPay();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentOption({
    String? icon,
    IconData? iconData,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              child:
                  icon != null
                      ? Image.asset(
                        icon,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                Icon(Icons.payment, color: Colors.blue),
                      )
                      : Icon(iconData ?? Icons.payment, color: Colors.blue),
            ),
            SizedBox(width: 16),

            // Title
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              ),
            ),

            // Selection indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.teal : Colors.grey,
                  width: 2,
                ),
              ),
              child:
                  isSelected
                      ? Center(
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.teal,
                          ),
                        ),
                      )
                      : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _saveBookingToDatabase() async {
    try {
      // Generate a unique booking reference
      final String bookingReference =
          'BK-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1000)}';

      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/paid'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'hotelName': widget.hotelName,
          'image': widget.image,
          'dateRange': widget.dateRange,
          'guests': guestsInt,
          'rooms': roomsInt,
          'price': priceDouble,
          'userId': Currentuser.getUserId(),
          'paymentMethod': 'Credit/Debit Card',
          'bookingReference': bookingReference, // Add this line
          'status': 'Confirmed', // Add status
          'paymentDate': DateTime.now().toIso8601String(), // Add payment date
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Booking saved successfully: ${responseData['data']}');
        return true;
      } else {
        try {
          final errorData = jsonDecode(response.body);
          print('Failed to save booking: ${errorData['message']}');
        } catch (e) {
          print('Failed to save booking: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      print('Error saving booking to database: $e');
      return false;
    }
  }

  // Biometric Authentication
  Future<void> _authenticateAndPay() async {
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;

    if (canAuthenticateWithBiometrics) {
      try {
        final bool didAuthenticate = await _auth.authenticate(
          localizedReason: 'Please authenticate to complete payment',
          options: const AuthenticationOptions(biometricOnly: true),
        );

        if (didAuthenticate) {
          _showFakePaymentProcessing();
        }
      } catch (e) {
        print('Authentication error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Biometric authentication failed. Try another payment method.",
            ),
          ),
        );
      }
    } else {
      // Fallback if biometrics not available
      _showFakePaymentProcessing();
    }
  }

  // Touch & Go eWallet Payment
  void _showTouchNGoPayment() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    size: 40,
                    color: Colors.teal,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Touch & Go eWallet",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  "Payment Amount",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 4),
                Text(
                  "RM ${priceDouble.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: Text("Pay with Touch & Go"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _authenticateAndPay();
                    },
                  ),
                ),
                SizedBox(height: 8),
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Online Banking Options
  void _showOnlineBankingOptions() {
    List<Map<String, dynamic>> banks = [
      {'name': 'Maybank', 'icon': Icons.account_balance},
      {'name': 'CIMB Bank', 'icon': Icons.account_balance},
      {'name': 'Public Bank', 'icon': Icons.account_balance},
      {'name': 'RHB Bank', 'icon': Icons.account_balance},
      {'name': 'Bank Islam', 'icon': Icons.account_balance},
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Select Your Bank",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Container(
                  height: 200,
                  child: ListView.builder(
                    itemCount: banks.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Icon(banks[index]['icon']),
                        title: Text(banks[index]['name']),
                        onTap: () {
                          Navigator.pop(context);
                          _showFakeBankLogin(banks[index]['name']);
                        },
                      );
                    },
                  ),
                ),
                SizedBox(height: 8),
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Fake Bank Login
  void _showFakeBankLogin(String bankName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$bankName Online",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Username",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Payment Amount: RM ${priceDouble.toStringAsFixed(2)}",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: Text("Login & Pay"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _authenticateAndPay();
                    },
                  ),
                ),
                SizedBox(height: 8),
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Credit/Debit Card Payment
  void _showCardPayment() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.credit_card, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      "Card Payment",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Card Number",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: "Expiry (MM/YY)",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: "CVV",
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Cardholder Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Payment Amount: RM ${priceDouble.toStringAsFixed(2)}",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: Text("Pay Now"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _authenticateAndPay();
                    },
                  ),
                ),
                SizedBox(height: 8),
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Fake Payment Processing
  void _showFakePaymentProcessing() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text("Processing Payment..."),
              ],
            ),
          ),
        );
      },
    );

    // Simulate payment processing
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pop(context);
      _showPaymentSuccess();
    });
  }

  // Payment Success
  void _showPaymentSuccess() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ... existing code ...
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  child: Text("Done"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    bool saved = await _saveBookingToDatabase();
                    if (saved) {
                      setState(() {
                        _isPaid = true;
                      });
                      
                      // Schedule notification for upcoming booking
                      await _scheduleUpcomingBookingNotification();
                      
                      // Pop with result to indicate payment was successful
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context, 'paid'); // Return to booking list with result
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Booking saved successfully")),
                      );
                    } else {
                      Navigator.pop(context); // Close dialog only
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to save booking details")),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
}

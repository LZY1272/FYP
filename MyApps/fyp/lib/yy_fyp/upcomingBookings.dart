import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

// Notification service setup
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Initialize notification settings
Future<void> initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  final DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
      // Handle notification taps here
    },
  );
  
  // Initialize timezone data
  tz_data.initializeTimeZones();
}

class UpcomingBookings extends StatefulWidget {
  final Map<String, dynamic> booking;

  const UpcomingBookings({Key? key, required this.booking}) : super(key: key);

  @override
  State<UpcomingBookings> createState() => _UpcomingBookingsState();
}

class _UpcomingBookingsState extends State<UpcomingBookings> {
  bool isLoading = false;
  String error = '';
  Map<String, dynamic> bookingDetails = {};

  @override
  void initState() {
    super.initState();
    // Initialize with passed booking data
    bookingDetails = widget.booking;
    // Initialize notifications
    initNotifications().then((_) {
      // Optionally fetch fresh details from the server
      fetchBookingDetails().then((_) {
        // Check if booking is within 24 hours and show notification if needed
        checkAndShowNotification();
      });
    });
  }

  // Check if booking date is within 24 hours and show notification if needed
  void checkAndShowNotification() {
    if (bookingDetails['dateRange'] != null) {
      try {
        // Extract check-in date from dateRange
        // Example format: "Apr 03 - Apr 04"
        final String dateRange = bookingDetails['dateRange'];
        final String checkInDateStr = dateRange.split(' - ')[0]; // "Apr 03"
        
        // Parse the check-in date
        final DateFormat dateFormat = DateFormat('MMM dd');
        DateTime checkInDate = dateFormat.parse(checkInDateStr);
        
        // Add current year since the date string doesn't include year
        checkInDate = DateTime(
          DateTime.now().year,
          checkInDate.month,
          checkInDate.day,
        );
        
        // If the date has already passed this year, it might be for next year
        if (checkInDate.isBefore(DateTime.now()) && 
            checkInDate.difference(DateTime.now()).inDays < -30) {
          checkInDate = DateTime(
            DateTime.now().year + 1,
            checkInDate.month,
            checkInDate.day,
          );
        }
        
        // Check if the booking is within the next 24 hours
        final DateTime now = DateTime.now();
        final Duration difference = checkInDate.difference(now);
        
        print('Check-in date: $checkInDate');
        print('Current time: $now');
        print('Hours until check-in: ${difference.inHours}');
        
        if (difference.inHours <= 24 && difference.inHours > 0) {
          // Booking is within 24 hours
          showUpcomingBookingNotification(
            bookingDetails['hotelName'] ?? 'Your Hotel',
            'Your booking at ${bookingDetails['hotelName']} is coming up in ${difference.inHours} hours'
          );
        } else if (difference.inHours <= 0 && difference.inHours > -24) {
          // Check-in is today or already started
          showUpcomingBookingNotification(
            bookingDetails['hotelName'] ?? 'Your Hotel',
            'Your stay at ${bookingDetails['hotelName']} is today!'
          );
        }
      } catch (e) {
        print('Error processing date for notification: $e');
      }
    }
  }

  // Show notification for upcoming booking
  Future<void> showUpcomingBookingNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'booking_channel',
      'Booking Notifications',
      channelDescription: 'Notifications for upcoming hotel bookings',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      styleInformation: BigTextStyleInformation(''),
    );
    
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    // Get a unique ID for this notification based on booking ID
    final int notificationId = bookingDetails['_id'].hashCode % 1000000;
    
    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  // Schedule a notification for a specific time
  Future<void> scheduleBookingReminder(DateTime notificationTime, String title, String body) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'booking_reminder_channel',
      'Booking Reminders',
      channelDescription: 'Reminders for upcoming hotel bookings',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();
    
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    // Get a unique ID for this notification based on booking ID
    final int notificationId = bookingDetails['_id'].hashCode % 1000000;
    
    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(notificationTime, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> fetchBookingDetails() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final String bookingId = widget.booking['_id'];
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/paid/$bookingId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          bookingDetails = data['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load booking details';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract data from bookingDetails with fallbacks
    final String hotelName = bookingDetails['hotelName'] ?? 'Unknown Hotel';
    final String dateRange = bookingDetails['dateRange'] ?? 'Not specified';
    final int guests = bookingDetails['guests'] ?? 0;
    final int rooms = bookingDetails['rooms'] ?? 0;
    final double price = bookingDetails['price']?.toDouble() ?? 0.0;
    final String status = bookingDetails['status'] ?? 'Confirmed';
    final String bookingReference = bookingDetails['bookingReference'] ?? 'Not available';
    
    // Format payment date if available
    String paymentDate = 'Not available';
    if (bookingDetails['paymentDate'] != null) {
      try {
        final DateTime date = DateTime.parse(bookingDetails['paymentDate']);
        paymentDate = DateFormat('MMM d, yyyy - h:mm a').format(date);
      } catch (e) {
        paymentDate = 'Invalid date';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error, style: TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hotel Image
                      if (bookingDetails['image'] != null && bookingDetails['image'].isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            bookingDetails['image'],
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                width: double.infinity,
                                color: Colors.grey[300],
                                child: const Icon(Icons.error, size: 50),
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: const Icon(Icons.hotel, size: 50),
                        ),
                      const SizedBox(height: 20),
                      
                      // Booking Reference
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.confirmation_number, color: Colors.blue),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Booking Reference',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  Text(
                                    bookingReference,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Hotel Name
                      const Text(
                        'Hotel',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        hotelName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Status
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: status == 'Confirmed'
                                  ? Colors.green.shade100
                                  : status == 'Cancelled'
                                      ? Colors.red.shade100
                                      : Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: status == 'Confirmed'
                                    ? Colors.green.shade800
                                    : status == 'Cancelled'
                                        ? Colors.red.shade800
                                        : Colors.blue.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Booking Details
                      _buildDetailCard(
                        title: 'Booking Details',
                        children: [
                          _buildDetailRow('Date', dateRange),
                          _buildDetailRow('Guests', '$guests person(s)'),
                          _buildDetailRow('Rooms', '$rooms room(s)'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Payment Details
                      _buildDetailCard(
                        title: 'Payment Details',
                        children: [
                          _buildDetailRow('Payment Date', paymentDate),
                          _buildDetailRow('Amount Paid', 'RM ${price.toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 30),
                      
                      // Cancellation Policy
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Cancellation Policy',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Free cancellation up to 24 hours before check-in. Cancellations after this time or no-shows may incur charges.',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
      bottomNavigationBar: status != 'Cancelled'
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  _showCancellationDialog();
                },
                child: const Text(
                  'Cancel Booking',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildDetailCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 15,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCancellationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to cancel this booking?'),
                SizedBox(height: 10),
                Text(
                  'This action cannot be undone.',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No, Keep Booking'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes, Cancel Booking'),
              onPressed: () {
                Navigator.of(context).pop();
                _cancelBooking();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelBooking() async {
    setState(() {
      isLoading = true;
    });

    try {
      final String bookingId = widget.booking['_id'];
      final response = await http.patch(
        Uri.parse('http://10.0.2.2:3000/paid/$bookingId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': 'Cancelled'}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          bookingDetails = data['data'];
          isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          error = 'Failed to cancel booking';
          isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to cancel booking'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
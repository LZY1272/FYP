import 'package:flutter/material.dart';
import 'package:fyp/chatScreen.dart';
import 'package:fyp/chatbotRating.dart';
import 'package:fyp/upcomingBookings.dart';
import 'homePage.dart';
import 'accommodation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); 
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => homePage(),
        '/accommodations': (context) => accommodationsPage(),
        '/chatbotRating': (context) => chatbotRating(),
        '/upcomingBookings': (context) => upcomingBookings(),
        '/chatbot': (context) => chatScreen(),
      },
    );
  }
}

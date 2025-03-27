import 'package:flutter/material.dart';
import 'package:fyp/chatScreen.dart';
import 'package:fyp/chatbotRating.dart';
import 'package:fyp/screens/login_register.dart';
import 'package:fyp/upcomingBookings.dart';
import 'homePage.dart';
import 'accommodation.dart';
import '../screens/travel_form.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login', // Set initial route to Login Page
      routes: {
        '/login': (context) => LoginPage(), // Define the route
        '/home': (context) {
          final userId = ModalRoute.of(context)!.settings.arguments as String;
          return homePage(userId: userId);
        },
        '/accommodations': (context) => accommodationsPage(),
        '/chatbotRating': (context) => chatbotRating(),
        '/upcomingBookings': (context) => upcomingBookings(),
        '/chatbot': (context) => chatScreen(),
        '/itinerary': (context) {
          final userId = ModalRoute.of(context)!.settings.arguments as String;
          return TravelForm(userId: userId); // Pass userId here
        },
      },
    );
  }
}

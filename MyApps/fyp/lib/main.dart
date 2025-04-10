import 'package:flutter/material.dart';
import 'package:fyp/yy_fyp/bookingConfirmationList.dart';
import 'package:fyp/yy_fyp/chatbotScreen.dart';
import 'package:fyp/yy_fyp/chatbotRating.dart';
import 'package:fyp/screens/login_register.dart';
import 'package:fyp/yy_fyp/upcomingBookingsList.dart';
import 'yy_fyp/accommodation.dart';
import 'yy_fyp/salomonBottomBar.dart';
import 'screens/travel_form.dart';
import 'screens/profile_screen.dart';
import 'package:fyp/yy_fyp/expensesList.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login', // Set initial route to Home Page
      routes: {
        '/login': (context) => LoginPage(),
        '/salomonBottomBar': (context) {
          // Safely get userId with a fallback value
          final args = ModalRoute.of(context)?.settings.arguments;
          final userId = args != null ? args as String : "defaultUser";
          return salomonBottomBar(userId: userId);
        },
        '/accommodations': (context) => accommodationsPage(),
        '/chatbotRating': (context) => chatbotRating(),
        '/upcomingBookings': (context) => UpcomingBookingsList(),
        '/chatbot': (context) {
          // Safely get userId with a fallback value
          final args = ModalRoute.of(context)?.settings.arguments;
          final userId = args != null ? args as String : "defaultUser";
          return chatbotScreen(userId: userId);
        },
        '/itinerary': (context) {
          // Safely get userId with a fallback value
          final args = ModalRoute.of(context)?.settings.arguments;
          final userId = args != null ? args as String : "defaultUser";
          return TravelForm(userId: userId);
        },
        '/profile': (context) {
          // Safely get userId with a fallback value
          final args = ModalRoute.of(context)?.settings.arguments;
          final userId = args != null ? args as String : "defaultUser";
          return ProfilePage(userId: userId);
        },
        '/bookingConfirmation': (context) => bookingConfirmationList(),
        '/expensesList': (context) {
          // Safely get userId with a fallback value
          final args = ModalRoute.of(context)?.settings.arguments;
          final userId = args != null ? args as String : "defaultUser";
          return ExpensesList(userId: userId);
        },
        '/userActivityReport': (context) => UserActivityReport(),
      },
    );
  }
}

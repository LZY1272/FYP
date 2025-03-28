// import 'package:flutter/material.dart';
// import 'package:fyp/yy_fyp/chatScreen.dart';
// import 'package:fyp/yy_fyp/chatbotRating.dart';
// import 'package:fyp/screens/login_register.dart';
// import 'package:fyp/yy_fyp/upcomingBookings.dart';
// import 'yy_fyp/homePage.dart';
// import 'yy_fyp/accommodation.dart';
// import 'screens/travel_form.dart';

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       initialRoute: '/login', // Set initial route to Login Page
//       routes: {
//         '/login': (context) => LoginPage(), // Define the route
//         '/home': (context) {
//           final userId = ModalRoute.of(context)!.settings.arguments as String;
//           return homePage(userId: userId);
//         },
//         '/accommodations': (context) => accommodationsPage(),
//         '/chatbotRating': (context) => chatbotRating(),
//         '/upcomingBookings': (context) => upcomingBookings(),
//         '/chatbot': (context) => chatScreen(),
//         '/itinerary': (context) {
//           final userId = ModalRoute.of(context)!.settings.arguments as String;
//           return TravelForm(userId: userId); // Pass userId here
//         },
//       },
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:fyp/yy_fyp/chatScreen.dart';
import 'package:fyp/yy_fyp/chatbotRating.dart';
import 'package:fyp/screens/login_register.dart';
import 'package:fyp/yy_fyp/upcomingBookings.dart';
import 'yy_fyp/homePage.dart';
import 'yy_fyp/accommodation.dart';
import 'screens/travel_form.dart';
import 'screens/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/home', // Set initial route to Home Page
      routes: {
        '/login': (context) => LoginPage(),
        '/home': (context) {
          final userId =
              ModalRoute.of(context)?.settings.arguments as String? ??
              'defaultUser';
          return homePage(userId: userId);
        },
        '/accommodations': (context) => accommodationsPage(),
        '/chatbotRating': (context) => chatbotRating(),
        '/upcomingBookings': (context) => upcomingBookings(),
        '/chatbot': (context) => chatScreen(),
        '/itinerary': (context) {
          final userId =
              ModalRoute.of(context)?.settings.arguments as String? ??
              'defaultUser';
          return TravelForm(userId: userId);
        },
        '/profile': (context) {
          final userId =
              ModalRoute.of(context)?.settings.arguments as String? ??
              'defaultUser';
          return ProfilePage(userId: userId);
        },
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'homePage.dart';
import 'chatScreen.dart';
import '../screens/travel_form.dart';
import '../screens/profile_screen.dart';

class salomonBottomBar extends StatefulWidget {
  final String userId;

  const salomonBottomBar({Key? key, required this.userId}) : super(key: key);

  @override
  _SalomonBottomBarWidgetState createState() => _SalomonBottomBarWidgetState();
}

class _SalomonBottomBarWidgetState extends State<salomonBottomBar> {
  int _currentIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      homePage(userId: widget.userId),
      TravelForm(userId: widget.userId), // Itinerary
      chatScreen(userId: widget.userId),
      ProfilePage(userId: widget.userId),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SalomonBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Simply update index, no navigation needed
          });
        },
        items: [
          SalomonBottomBarItem(icon: Icon(Icons.home), title: Text("Home"), selectedColor: Colors.blue),
          SalomonBottomBarItem(icon: Icon(Icons.event), title: Text("Itinerary"), selectedColor: Colors.blue),
          SalomonBottomBarItem(icon: Icon(Icons.chat), title: Text("Chatbot"), selectedColor: Colors.blue),
          SalomonBottomBarItem(icon: Icon(Icons.person), title: Text("Profile"), selectedColor: Colors.blue),
        ],
      ),
    );
  }
}

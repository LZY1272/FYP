import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class homePage extends StatefulWidget {
  final String userId;

  const homePage({Key? key, required this.userId}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<homePage> {
  List<dynamic> topExperiences = [];
  List<dynamic> topDestinations = [];

  @override
  void initState() {
    super.initState();
    print("Navigated to HomePage with userId: ${widget.userId}"); // Debug

    fetchTopExperiences();
    fetchTopDestinations();
  }

  Future<void> fetchTopExperiences() async {
    final String apiKey =
        "5ae2e3f221c38a28845f05b61e71a6719cee59a2f24d1b01fe74b4ef";
    final url = Uri.parse(
      "https://api.opentripmap.com/0.1/en/places/radius?radius=10000&lon=2.3415407&lat=48.8719556&rate=3&limit=5&apikey=$apiKey",
    );

    try {
      final response = await http.get(url);

      print("Experiences API Status Code: ${response.statusCode}");
      print("Experiences API Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          topExperiences = data["features"] ?? [];
        });
      } else {
        print("Failed to load experiences: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching experiences: $e");
    }
  }

  Future<void> fetchTopDestinations() async {
    final String apiKey = "99d0568adcmsh612a2ca3d0334f9p15fdf5jsndc687769b285";
    final url = Uri.parse(
      "https://wft-geo-db.p.rapidapi.com/v1/geo/cities?limit=5&sort=-population",
    );

    try {
      final response = await http.get(
        url,
        headers: {
          "X-RapidAPI-Key": apiKey,
          "X-RapidAPI-Host": "wft-geo-db.p.rapidapi.com",
        },
      );

      print("Destinations API Status Code: ${response.statusCode}");
      print("Destinations API Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          topDestinations = data["data"] ?? [];
        });
      } else {
        print("Failed to load destinations: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching destinations: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: Icon(Icons.menu, color: Colors.black),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/Logo.png', height: 30),
            SizedBox(width: 8),
            Text(
              "TRAVELMIND",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.black, size: 30),
            onPressed: () {
              Navigator.pushNamed(context, '/userProfile');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                "Menu",
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            _buildDrawerItem(context, "Accommodations", "/accommodations"),
            _buildDrawerItem(context, "Expense Summary", "/expenseSummary"),
            _buildDrawerItem(context, "Chatbot Rating", "/chatbotRating"),
            _buildDrawerItem(context, "Upcoming Bookings", "/upcomingBookings"),
            _buildDrawerItem(
              context,
              "Booking Confirmation",
              "/bookingConfirmation",
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Places to go, things to do, hotels...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Top experiences", context),
                  _buildExperienceList(topExperiences),
                  _buildSectionTitle(
                    "Top destinations for your next holiday",
                    context,
                  ),
                  _buildDestinationList(topDestinations),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/home', arguments: widget.userId);
              break;
            case 1:
              Navigator.pushNamed(
                context,
                '/itinerary',
                arguments: widget.userId,
              );
              break;
            case 2:
              Navigator.pushNamed(context, '/chatbot');
              break;
            case 3:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: "Itinerary"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chatbot"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, String title, String route) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Navigator.pushNamed(context, route);
      },
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton(onPressed: () {}, child: Text("See all")),
        ],
      ),
    );
  }

  Widget _buildExperienceList(List<dynamic> experiences) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: experiences.length,
        itemBuilder: (context, index) {
          final experience = experiences[index]["properties"];
          return _buildExperienceCard(
            experience?["xid"],
            experience?["name"] ?? "Unknown Place",
          );
        },
      ),
    );
  }

  Widget _buildExperienceCard(String? id, String title) {
    return Padding(
      padding: EdgeInsets.only(left: 16),
      child: Container(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                "https://via.placeholder.com/150",
                height: 100,
                width: 150,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 5),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationList(List<dynamic> destinations) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: destinations.length,
        itemBuilder: (context, index) {
          final destination = destinations[index];
          return _buildDestinationCard(destination["city"]);
        },
      ),
    );
  }

  Widget _buildDestinationCard(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 16),
      child: Container(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                "https://via.placeholder.com/150",
                height: 100,
                width: 150,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 5),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

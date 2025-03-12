import 'package:flutter/material.dart'; 

class homePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/Logo.png', height: 30), // Your app logo
            SizedBox(width: 8),
            Text(
              "TRAVELMIND",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
              child: Text("Menu", style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            _buildDrawerItem(context, "Accommodations", "/accommodations"),
            _buildDrawerItem(context, "Expense Summary", "/expenseSummary"),
            _buildDrawerItem(context, "Chatbot Rating", "/chatbotRating"),
            _buildDrawerItem(context, "Upcoming Bookings", "/upcomingBookings"),
            _buildDrawerItem(context, "Booking Confirmation", "/bookingConfirmation"),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Top experiences", context),
                  _buildHorizontalList(_topExperiences()),
                  _buildSectionTitle("Top destinations for your next holiday", context),
                  _buildHorizontalList(_topDestinations()),
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
              Navigator.pushNamed(context, '/home');
              break;
            case 1:
              Navigator.pushNamed(context, '/itinerary');
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
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () {},
            child: Text("See all"),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalList(List<Map<String, String>> items) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _buildExperienceCard(items[index]);
        },
      ),
    );
  }

  Widget _buildExperienceCard(Map<String, String> data) {
  return Padding(
    padding: EdgeInsets.only(left: 16),
    child: Container(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: data["image"] != null && data["image"]!.isNotEmpty
                ? Image.asset(data["image"]!, height: 100, width: 150, fit: BoxFit.cover)
                : Container(
                    height: 100,
                    width: 150,
                    color: Colors.grey[300], // Placeholder if image is missing
                    child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
                  ),
          ),
          SizedBox(height: 5),
          Text(data["title"]!, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );
}

  List<Map<String, String>> _topExperiences() {
    return [
      {
        "image": "assets/train_market.png",
        "title": "Half-Day Railway Market and Floating Market Tour in Thailand",
        "price": "From RM 135 per adult",
      },
      {
        "image": "assets/ocean_road.png",
        "title": "Great Ocean Road Small-Group Ecotour from Melbourne",
        "price": "From RM 416 per adult",
      },
    ];
  }

  List<Map<String, String>> _topDestinations() {
    return [
      {
        "image": "assets/bangkok.png",
        "title": "Bangkok, Thailand",
      },
      {
        "image": "assets/singapore.png",
        "title": "Singapore, Singapore",
      },
    ];
  }
}
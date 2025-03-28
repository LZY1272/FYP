import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:local_auth/local_auth.dart'; // Import for biometric authentication
import 'saved_itinerary.dart'; // Import Itinerary screen

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = "Loading...";
  String profilePic = "assets/profile_placeholder.png"; // Default image
  late Future<List<dynamic>> itineraries;
  final LocalAuthentication _auth = LocalAuthentication(); // LocalAuth instance

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    var db = await mongo.Db.create(
      "mongodb+srv://LZY1272:Ling_1272@cluster0.pqdov.mongodb.net",
    );
    await db.open();
    var collection = db.collection("users");

    var user = await collection.findOne(mongo.where.eq("_id", widget.userId));
    if (user != null) {
      setState(() {
        userName = user["name"] ?? "Unknown User";
        profilePic = user["profilePic"] ?? "assets/profile_placeholder.png";
      });
    }
    await db.close();
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId'); // Clear session
    Navigator.pushReplacementNamed(context, '/login'); // Redirect to login
  }

  Future<void> _authenticateAndNavigate() async {
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    if (canAuthenticateWithBiometrics) {
      try {
        final bool didAuthenticate = await _auth.authenticate(
          localizedReason: 'Please authenticate to view Upcoming Bookings',
          options: const AuthenticationOptions(biometricOnly: true),
        );

        if (didAuthenticate) {
          // Navigate to Upcoming Bookings if authenticated
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UpcomingBookingsScreen()),
          );
        }
      } catch (e) {
        print('Authentication error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        backgroundColor: Color(0xFF0CB9CE),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _logout, // Logout function
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 20),
            color: Color(0xFF0CB9CE),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(profilePic), // Load profile pic
                ),
                SizedBox(height: 10),
                Text(
                  userName, // Display actual user name
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 5),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement Edit Profile
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF0CB9CE),
                  ),
                  child: Text("Edit Profile"),
                ),
              ],
            ),
          ),

          // Menu Options
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                _buildProfileOption(Icons.card_travel, "Itineraries", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              SavedItineraryScreen(userId: widget.userId),
                    ),
                  );
                }),
                _buildProfileOption(Icons.bookmark, "Upcoming Bookings", () {
                  _authenticateAndNavigate(); // Authenticate before navigating
                }),
                _buildProfileOption(Icons.rate_review, "Reviews", () {
                  // TODO: Navigate to Reviews
                }),
                _buildProfileOption(Icons.settings, "Settings", () {
                  // TODO: Navigate to Settings
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Color(0xFF0CB9CE)),
              SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class UpcomingBookingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upcoming Bookings')),
      body: Center(child: Text('This is the Upcoming Bookings screen.')),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:local_auth/local_auth.dart'; // Import for biometric authentication
import 'saved_itinerary.dart'; // Import Itinerary screen
import 'review_screen.dart';
import 'user_preferences.dart'; // Import the UserPreferencesPage

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = ""; // Initially empty, will be replaced with email
  String profilePic = "assets/profile_placeholder.png"; // Default image
  late Future<List<dynamic>> itineraries;
  final LocalAuthentication _auth = LocalAuthentication(); // LocalAuth instance

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      var db = await mongo.Db.create(
        "mongodb+srv://LZY1272:Ling_1272@cluster0.pqdov.mongodb.net",
      );
      await db.open();
      var collection = db.collection("users");

      // Check if the userId is an ObjectId (MongoDB default) or String
      var user;
      if (widget.userId.length == 24) {
        // Assume it's an ObjectId if length is 24 (Mongo default _id)
        user = await collection.findOne(
          mongo.where.eq("_id", mongo.ObjectId.fromHexString(widget.userId)),
        );
      } else {
        // Otherwise, it's treated as a String userId in your collection
        user = await collection.findOne(
          mongo.where.eq("userId", widget.userId),
        );
      }

      if (user != null) {
        setState(() {
          userName =
              user["email"] ??
              "Unknown Email"; // Fetch email from the 'email' field
          profilePic = user["profilePic"] ?? "assets/profile_placeholder.png";
        });
      } else {
        setState(() {
          userName = "No user found"; // In case no user data is found
        });
      }
      await db.close();
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        userName = "Error loading data"; // Error handling
      });
    }
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
                  userName.isEmpty
                      ? "Loading..."
                      : userName, // Display email or loading text
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReviewScreen(userId: widget.userId),
                    ),
                  );
                }),
                _buildProfileOption(Icons.settings, "Settings", () {
                  // Navigate to UserPreferencesPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              UserPreferencesPage(userId: widget.userId),
                    ),
                  );
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

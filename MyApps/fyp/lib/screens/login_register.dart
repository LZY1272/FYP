import 'package:flutter/material.dart';
import 'package:fyp/screens/currentUser.dart';
import 'package:fyp/yy_fyp/salomonBottomBar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/config.dart';
import '../yy_fyp/homePage.dart';
import 'user_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void loginUser() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (!_isValidEmail(email)) {
      _showSnackbar("⚠️ Please enter a valid email.");
      return;
    }
    if (!_isValidPassword(password)) {
      _showSnackbar("⚠️ Password must be at least 6 characters.");
      return;
    }

    var regBody = {"email": email, "password": password};

    try {
      var response = await http.post(
        Uri.parse(login),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(regBody),
      );

      var jsonResponse = jsonDecode(response.body);
      print("📝 API Response: $jsonResponse");

      if (jsonResponse['status'] && jsonResponse['token'] != null) {
        String myToken = jsonResponse['token'];
        Map<String, dynamic> decodedToken = JwtDecoder.decode(myToken);
        String? userId = decodedToken['_id'];

        if (userId == null || userId.isEmpty) {
          _showSnackbar("Login failed. User ID not found.");
          return;
        }
        print("✅ Login Successful, User ID: $userId");
        Currentuser.setUserId(userId);
        // ✅ Check user preferences and navigate accordingly
        _redirectUserBasedOnPreferences(userId);
      } else {
        _showSnackbar("Login failed. Check your credentials.");
      }
    } catch (e) {
      _showSnackbar("Login failed. Server error.");
    }
  }

  void _redirectUserBasedOnPreferences(String userId) async {
    bool hasPreferences = await checkUserPreferences(userId);

    print("🔍 User Preferences Check: $hasPreferences"); // Debugging log

    // ✅ Auto-redirect based on preference
    if (hasPreferences) {
      print("✅ Redirecting to HomePage...");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => salomonBottomBar(userId: userId),
          ),
        );
      }
    } else {
      print("🆕 Redirecting to Preferences Setup...");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserPreferencesPage(userId: userId),
          ),
        );
      }
    }
  }

  Future<bool> checkUserPreferences(String userId) async {
    try {
      var response = await http.get(
        Uri.parse(getUserPreferences(userId)),
        headers: {"Content-Type": "application/json"},
      );

      print(
        "🔍 API Response (User Preferences): ${response.body}",
      ); // Debugging

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        // ✅ Check if user preferences are NOT empty
        if (jsonResponse['status'] == true && jsonResponse['data'] != null) {
          List activityPreferences =
              jsonResponse['data']['activityPreferences'];
          List interestCategories = jsonResponse['data']['interestCategories'];

          return activityPreferences.isNotEmpty ||
              interestCategories.isNotEmpty;
        }
      }
    } catch (e) {
      print("❌ Error fetching user preferences: $e");
    }
    return false; // Default to false if there's an error
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isValidEmail(String email) {
    String emailPattern = r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$';
    return RegExp(emailPattern).hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return password.length >= 6;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: loginUser, child: Text("Login")),
            TextButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterPage()),
                  ),
              child: Text("Don't have an account? Register"),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  void registerUser() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (name.isEmpty) {
      _showSnackbar("⚠️ Name cannot be empty.");
      return;
    }
    if (!_isValidEmail(email)) {
      _showSnackbar("⚠️ Please enter a valid email.");
      return;
    }
    if (!_isValidPassword(password)) {
      _showSnackbar("⚠️ Password must be at least 6 characters.");
      return;
    }

    var regBody = {"name": name, "email": email, "password": password};

    try {
      var response = await http.post(
        Uri.parse(registration),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(regBody),
      );

      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status']) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        _showSnackbar("Registration failed. Try again.");
      }
    } catch (e) {
      _showSnackbar("Registration failed. Server error.");
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isValidEmail(String email) {
    String emailPattern = r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$';
    return RegExp(emailPattern).hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return password.length >= 6;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: registerUser, child: Text("Register")),
          ],
        ),
      ),
    );
  }
}

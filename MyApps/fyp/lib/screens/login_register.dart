import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/config.dart';
import '../yy_fyp/homePage.dart';

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

    if (email.isEmpty || password.isEmpty) {
      _showSnackbar("⚠️ Please fill in all fields.");
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
      print("📝 API Response: $jsonResponse"); // Debugging

      if (jsonResponse['status'] && jsonResponse['token'] != null) {
        String myToken = jsonResponse['token'];

        // Decode token to extract userId
        Map<String, dynamic> decodedToken = JwtDecoder.decode(myToken);
        String? userId =
            decodedToken['_id']; // Ensure backend uses "_id" for user ID

        if (userId == null || userId.isEmpty) {
          print("⚠️ User ID is missing in the token.");
          _showSnackbar("Login failed. User ID not found.");
          return;
        }

        print("✅ Login Successful, User ID: $userId");

        // Navigate to homePage with userId
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => homePage(userId: userId)),
        );
      } else {
        print('❌ Login failed: Invalid credentials or server issue.');
        _showSnackbar("Login failed. Please check your credentials.");
      }
    } catch (e) {
      print("❌ Error logging in: $e");
      _showSnackbar("Login failed. Server error.");
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackbar("⚠️ Please fill in all fields.");
      return;
    }

    var regBody = {"email": email, "password": password};

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
      print("❌ Error registering: $e");
      _showSnackbar("Registration failed. Server error.");
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

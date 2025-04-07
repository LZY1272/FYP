import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class chatScreen extends StatefulWidget {
  final String userId;

  const chatScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<chatScreen> {
  TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [];

  Future<String> getChatbotResponse(String userMessage) async {
    final String apiUrl = "http://172.20.10.3:8000/chat/"; 

  try{
    var response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"message": userMessage}),
    );

    print("Response Status: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      Map<String, dynamic> responseData = jsonDecode(response.body);
      return responseData["response"];
    } else {
      return "Error: ${response.statusCode} - ${response.body}";
    }
  }catch (e) {
    print("Exception: $e");
    return "Error: Failed to connect to chatbot.";
  }
}

  void sendMessage() async {
    String userMessage = _controller.text;
    if (userMessage.isEmpty) return;

    setState(() {
      messages.add({"sender": "user", "text": userMessage});
      _controller.clear();
    });

    String botResponse = await getChatbotResponse(userMessage);

    setState(() {
      messages.add({"sender": "bot", "text": botResponse});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("TRAVELMIND Chatbot")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                bool isUser = message["sender"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      message["text"]!,
                      style: TextStyle(color: isUser ? Colors.white : Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: "Type a message..."),
                  ),
                ),
                IconButton(icon: Icon(Icons.send), onPressed: sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

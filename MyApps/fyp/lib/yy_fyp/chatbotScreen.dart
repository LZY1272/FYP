// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// class chatScreen extends StatefulWidget {
//   final String userId;

//   const chatScreen({Key? key, required this.userId}) : super(key: key);

//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<chatScreen> {
//   TextEditingController _controller = TextEditingController();
//   List<Map<String, String>> messages = [];

//   Future<String> getChatbotResponse(String userMessage) async {
//     final String apiUrl = "http://10.0.2.2:8000/chat/"; 

//     try {
//       var response = await http.post(
//         Uri.parse(apiUrl),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({"message": userMessage}),
//       );

//       print("Response Status: ${response.statusCode}");
//       print("Response Body: ${response.body}");

//       if (response.statusCode == 200) {
//         Map<String, dynamic> responseData = jsonDecode(response.body);
//         return responseData["response"];
//       } else {
//         return "Error: ${response.statusCode} - ${response.body}";
//       }
//     } catch (e) {
//       print("Exception: $e");
//       return "Error: Failed to connect to chatbot.";
//     }
//   }

//   void sendMessage() async {
//     String userMessage = _controller.text;
//     if (userMessage.isEmpty) return;

//     setState(() {
//       messages.add({"sender": "user", "text": userMessage});
//       _controller.clear();
//     });

//     String botResponse = await getChatbotResponse(userMessage);

//     setState(() {
//       messages.add({"sender": "bot", "text": botResponse});
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("TRAVELMIND Chatbot")),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               itemCount: messages.length,
//               itemBuilder: (context, index) {
//                 final message = messages[index];
//                 bool isUser = message["sender"] == "user";
//                 return Align(
//                   alignment:
//                       isUser ? Alignment.centerRight : Alignment.centerLeft,
//                   child: Container(
//                     margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//                     padding: EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: isUser ? Colors.blue : Colors.grey[300],
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Text(
//                       message["text"]!,
//                       style: TextStyle(
//                         color: isUser ? Colors.white : Colors.black,
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           Padding(
//             padding: EdgeInsets.all(8),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     decoration: InputDecoration(hintText: "Type a message..."),
//                   ),
//                 ),
//                 IconButton(icon: Icon(Icons.send), onPressed: sendMessage),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class chatbotScreen extends StatefulWidget {
  final String userId;

  const chatbotScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<chatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> messages = [];
  bool isLoading = false;

  Future<String> getChatbotResponse(String userMessage) async {
    setState(() {
      isLoading = true;
    });

    try {
      var response = await http.post(
        Uri.parse("http://10.0.2.2:8000/chat/"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"message": userMessage}),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData["response"];
      } else {
        return "Error: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      print("Exception: $e");
      return "Error: Failed to connect to chatbot. Make sure the server is running.";
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void sendMessage() async {
    String userMessage = _controller.text;
    if (userMessage.isEmpty) return;

    setState(() {
      messages.add({
        "sender": "user", 
        "text": userMessage,
        "time": DateTime.now().toString()
      });
      _controller.clear();
    });

    String botResponse = await getChatbotResponse(userMessage);

    setState(() {
      messages.add({
        "sender": "bot", 
        "text": botResponse,
        "time": DateTime.now().toString()
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("TRAVELMIND Chatbot"),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.travel_explore, size: 64, color: Colors.blue[300]),
                            SizedBox(height: 16),
                            Text(
                              "Start chatting with TravelMind!",
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Ask about destinations, travel tips, itineraries, and more.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[500], fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: messages.length,
                        padding: EdgeInsets.all(10),
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          bool isUser = message["sender"] == "user";
                          return MessageBubble(
                            message: message["text"]!,
                            isUser: isUser,
                            timestamp: message["time"]!,
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
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        minLines: 1,
                        maxLines: 5,
                        onSubmitted: (_) => sendMessage(),
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.send, color: Colors.blue),
                      onPressed: sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final String timestamp;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isUser,
    required this.timestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 4),
            Text(
              DateTime.parse(timestamp).toLocal().toString().substring(11, 16),
              style: TextStyle(
                color: isUser ? Colors.white70 : Colors.black54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
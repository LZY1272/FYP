import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  final String baseUrl;

  ChatService({required this.baseUrl});

  // Get all itineraries for a user
  Future<Map<String, dynamic>> getUserItineraries(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/getUserItineraries/$userId'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user itineraries');
    }
  }

  // Get chat by itinerary ID
  Future<Map<String, dynamic>> getChatByItineraryId(String itineraryId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/getChatByItineraryId/$itineraryId'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('Chat not found');
    } else {
      throw Exception('Failed to load chat');
    }
  }

  Future<Map<String, dynamic>> createChat(String itineraryId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/createChat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'itineraryId': itineraryId}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create chat: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating chat: ${e.toString()}');
    }
  }

  // Get messages for a chat
  Future<List<dynamic>> getMessages(String chatId) async {
    final response = await http.get(Uri.parse('$baseUrl/getMessages/$chatId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == true && data['success'] != null) {
        return data['success'];
      }
      return [];
    } else {
      throw Exception('Failed to load messages');
    }
  }

  // Add a message to a chat
  Future<Map<String, dynamic>> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/addMessage'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'chatId': chatId, 'senderId': senderId, 'text': text}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to send message');
    }
  }

  // Get or create chat
  Future<Map<String, dynamic>> getOrCreateChat(String itineraryId) async {
    try {
      // Try to get existing chat
      final chatData = await getChatByItineraryId(itineraryId);
      return chatData;
    } catch (e) {
      if (e.toString().contains('Chat not found')) {
        // If no chat exists, create a new one
        return await createChat(itineraryId);
      } else {
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>> getUserChats(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/getUserChats/$userId'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user chats: ${response.statusCode}');
    }
  }

  // Optional: Add this method to get chat details for a specific trip
  Future<Map<String, dynamic>> getTripChatDetails(String itineraryId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/getTripChatDetails/$itineraryId'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load trip chat details');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  final String userId;
  final String baseUrl;
  final VoidCallback? onNavigateToTrips;

  const ChatListScreen({
    Key? key,
    required this.userId,
    required this.baseUrl,
    this.onNavigateToTrips,
  }) : super(key: key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class ChatPreview {
  final String itineraryId;
  final String? chatId;
  final String destination;
  final String? latestMessage;
  final String? senderName;
  final DateTime? timestamp;
  final List<String> collaborators;
  final String ownerId; // Added this field to track the owner

  ChatPreview({
    required this.itineraryId,
    this.chatId,
    required this.destination,
    this.latestMessage,
    this.senderName,
    this.timestamp,
    required this.collaborators,
    required this.ownerId, // Required field
  });

  factory ChatPreview.fromJson(Map<String, dynamic> json) {
    return ChatPreview(
      itineraryId: json['itineraryId'],
      chatId: json['chatId'],
      destination: json['destination'],
      latestMessage: json['latestMessage'],
      senderName: json['senderName'],
      timestamp:
          json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
      collaborators:
          json['collaborators'] != null
              ? List<String>.from(json['collaborators'])
              : [],
      ownerId: json['ownerId'] ?? '',
    );
  }
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<ChatPreview> _chatPreviews = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  Future<void> _fetchChats() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/getUserChats/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['chats'] != null) {
          setState(() {
            _chatPreviews = List<ChatPreview>.from(
              data['chats'].map((chat) => ChatPreview.fromJson(chat)),
            );
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _hasError = false; // Not an error, just no chats
            _chatPreviews = [];
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Trip Chats'), elevation: 1),
      body: RefreshIndicator(onRefresh: _fetchChats, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchChats, child: Text('Retry')),
          ],
        ),
      );
    }

    if (_chatPreviews.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: _chatPreviews.length,
      itemBuilder: (context, index) {
        final chatPreview = _chatPreviews[index];
        return _buildChatPreviewTile(chatPreview);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No shared trips yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Share your trips with friends to start chatting',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.share),
            label: Text('Go to Trips'),
            onPressed: () {
              // Use the callback to navigate to trips
              if (widget.onNavigateToTrips != null) {
                widget.onNavigateToTrips!();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatPreviewTile(ChatPreview chatPreview) {
    final hasMessage = chatPreview.latestMessage != null;
    final formattedTime =
        chatPreview.timestamp != null
            ? _formatTimestamp(chatPreview.timestamp!)
            : '';

    // Get number of collaborators
    final collaboratorCount = chatPreview.collaborators.length;

    // Check if current user is the owner of this itinerary
    final isOwner = chatPreview.ownerId == widget.userId;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Icon(Icons.group, color: Colors.white),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                chatPreview.destination,
                style: TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$collaboratorCount ${collaboratorCount == 1 ? 'member' : 'members'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        subtitle:
            hasMessage
                ? RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TextStyle(color: Colors.black54),
                    children: [
                      if (chatPreview.senderName != null)
                        TextSpan(
                          text: '${chatPreview.senderName}: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      TextSpan(text: chatPreview.latestMessage),
                    ],
                  ),
                )
                : Text(
                  'No messages yet',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
        trailing:
            hasMessage
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formattedTime,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                )
                : null,
        onTap: () async {
          // Handle the case where there's no chat yet
          if (chatPreview.chatId == null) {
            // Show loading indicator
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => Center(child: CircularProgressIndicator()),
            );

            try {
              // Create a new chat for this itinerary
              final response = await http.post(
                Uri.parse('${widget.baseUrl}/createChat'),
                headers: {'Content-Type': 'application/json'},
                body: json.encode({'itineraryId': chatPreview.itineraryId}),
              );

              // Dismiss loading indicator
              Navigator.pop(context);

              if (response.statusCode == 200) {
                final responseData = json.decode(response.body);
                if (responseData['status'] == true &&
                    responseData['chatId'] != null) {
                  // Navigate to chat screen with new chatId
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ChatScreen(
                            itineraryId: chatPreview.itineraryId,
                            chatId: responseData['chatId'],
                            userId: widget.userId,
                            isOwner: isOwner, // Pass if user is owner
                          ),
                    ),
                  ).then((_) => _fetchChats());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create chat')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to create chat: Server error'),
                  ),
                );
              }
            } catch (e) {
              // Dismiss loading indicator if still showing
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error creating chat: $e')),
              );
            }
          } else {
            // Navigate to existing chat
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ChatScreen(
                      itineraryId: chatPreview.itineraryId,
                      chatId: chatPreview.chatId!,
                      userId: widget.userId,
                      isOwner: isOwner, // Pass if user is owner
                    ),
              ),
            ).then((_) => _fetchChats()); // Refresh the list when returning
          }
        },
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      // For messages older than a day, show the date
      return DateFormat('MMM d').format(timestamp);
    } else if (difference.inHours > 0) {
      // For messages from today, show the time
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

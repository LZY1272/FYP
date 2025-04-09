import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Message {
  final String senderId;
  final String text;
  final DateTime timestamp;

  Message({
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      senderId: json['sender_id'],
      text: json['text'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String itineraryId;
  final String chatId;
  final String userId;
  final bool isOwner;

  const ChatScreen({
    Key? key,
    required this.itineraryId,
    required this.chatId,
    required this.userId,
    this.isOwner = false,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _leaveChat() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Leave Chat'),
            content: Text(
              'Are you sure you want to leave this chat? You will be removed as a collaborator from this trip.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('LEAVE', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.post(
        Uri.parse('http://172.20.10.3:3000/leaveChat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'chatId': widget.chatId, 'userId': widget.userId}),
      );

      // Dismiss loading
      Navigator.pop(context);

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        // Show success message
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('You have left the chat')));
        // Navigate back to chat list
        Navigator.pop(context);
      } else {
        // Handle specific error cases
        String errorMessage = data['message'] ?? 'Failed to leave chat';

        // Check if it's the "owner cannot leave" error
        if (errorMessage.contains('owner cannot leave')) {
          errorMessage = 'As the trip owner, you cannot leave this chat';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), duration: Duration(seconds: 3)),
        );
      }
    } catch (e) {
      // Dismiss loading if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Extract meaningful error message if possible
      String errorMessage = e.toString();
      if (errorMessage.contains('owner cannot leave')) {
        errorMessage = 'As the trip owner, you cannot leave this chat';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), duration: Duration(seconds: 3)),
      );
    }
  }

  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://172.20.10.3:3000/getMessages/${widget.chatId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['success'] != null) {
          setState(() {
            _messages = List<Message>.from(
              data['success'].map((msg) => Message.fromJson(msg)),
            );
            _isLoading = false;
          });

          // Scroll to bottom after messages load
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load messages')));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text;
    _messageController.clear();

    // Optimistically add message to UI
    final newMessage = Message(
      senderId: widget.userId,
      text: messageText,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(newMessage);
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      final response = await http.post(
        Uri.parse('http://172.20.10.3:3000/addMessage'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'chatId': widget.chatId,
          'senderId': widget.userId,
          'text': messageText,
        }),
      );

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message')));
        // Refetch messages in case of error
        _fetchMessages();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      // Refetch messages in case of error
      _fetchMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trip Chat'),
        elevation: 1,
        actions: [
          if (!widget.isOwner)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'leave') {
                  _leaveChat();
                }
              },
              itemBuilder:
                  (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'leave',
                      child: ListTile(
                        leading: Icon(Icons.exit_to_app, color: Colors.red),
                        title: Text(
                          'Leave Chat',
                          style: TextStyle(color: Colors.red),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
            ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child:
                        _messages.isEmpty
                            ? Center(
                              child: Text(
                                'No messages yet. Start the conversation!',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                            : ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.all(10),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                final isMyMessage =
                                    message.senderId == widget.userId;

                                return _buildMessageBubble(
                                  message,
                                  isMyMessage,
                                );
                              },
                            ),
                  ),
                  _buildMessageInput(),
                ],
              ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMyMessage) {
    final dateFormat = DateFormat.jm(); // Format for time (e.g., 2:30 PM)
    final timeString = dateFormat.format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMyMessage)
            CircleAvatar(
              radius: 16,
              child: Text(message.senderId.substring(0, 1).toUpperCase()),
            ),
          SizedBox(width: isMyMessage ? 0 : 8),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMyMessage ? Colors.blue[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment:
                    isMyMessage
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  SizedBox(height: 4),
                  Text(
                    timeString,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: isMyMessage ? 8 : 0),
          if (isMyMessage)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Text(
                widget.userId.substring(0, 1).toUpperCase(),
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, -1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColor,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

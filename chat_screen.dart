// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scheduler_app/models/message.dart'; // Import Message model
import 'package:scheduler_app/providers/chat_provider.dart'; // Import ChatProvider
import 'package:scheduler_app/providers/user_provider.dart'; // Import UserProvider for current user ID

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // For auto-scrolling

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load messages for a mock conversation, using current user's ID
      final currentUser = Provider.of<UserProvider>(context, listen: false).currentUser;
      if (currentUser != null) {
        Provider.of<ChatProvider>(context, listen: false).loadMessages(currentUser.id);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(ChatProvider chatProvider, String currentUserId) {
    if (_messageController.text.trim().isNotEmpty) {
      chatProvider.sendMessage(currentUserId, 'friend1', _messageController.text.trim()); // Mock receiver as 'friend1'
      _messageController.clear();
      // Scroll to the bottom after sending a message
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final messages = chatProvider.messages;
        final isLoadingMessages = chatProvider.isLoadingMessages;
        final currentUserId = Provider.of<UserProvider>(context).currentUser?.id; // Get current user ID

        if (currentUserId == null) {
          return const Center(child: Text('Please log in to use chat.'));
        }

        if (isLoadingMessages) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        return Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? const Center(
                      child: Text(
                        'No messages yet. Start a conversation!',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController, // Attach scroll controller
                      padding: const EdgeInsets.all(8.0),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId == currentUserId;
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isMe ? Theme.of(context).primaryColor.withOpacity(0.8) : Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.content,
                                  style: TextStyle(color: isMe ? Colors.white : Colors.black),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: isMe ? Colors.white70 : Colors.grey[600],
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onSubmitted: (_) => _sendMessage(chatProvider, currentUserId),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: () => _sendMessage(chatProvider, currentUserId),
                    mini: true,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
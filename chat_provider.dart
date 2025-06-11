// lib/providers/chat_provider.dart

import 'package:flutter/material.dart';
import 'package:scheduler_app/data/chat_repository.dart'; // Import ChatRepository
import 'package:scheduler_app/models/message.dart'; // Import Message model
import 'package:firebase_analytics/firebase_analytics.dart'; // New import for analytics
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // New import for crashlytics

/// ChatProvider: Manages the state and logic for chat messages.
class ChatProvider extends ChangeNotifier {
  final ChatRepository _chatRepository; // Dependency on ChatRepository
  final List<Message> _messages = []; // List of messages for current chat
  bool _isLoadingMessages = false;

  List<Message> get messages => _messages;
  bool get isLoadingMessages => _isLoadingMessages;

  ChatProvider(this._chatRepository); // Constructor: takes ChatRepository

  /// Loads messages for a specific conversation.
  Future<void> loadMessages(String userId, {String? conversationId}) async {
    _isLoadingMessages = true;
    notifyListeners();

    try {
      final fetchedMessages = await _chatRepository.getMessages(userId, conversationId: conversationId);
      _messages.clear(); // Clear previous messages
      _messages.addAll(fetchedMessages);
    } catch (e, s) {
      print('Failed to load messages: $e');
      FirebaseCrashlytics.instance.recordError(e, s, reason: 'Failed to load messages in ChatProvider');
      // Handle error
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  /// Sends a new message.
  Future<void> sendMessage(String senderId, String receiverId, String content) async {
    try {
      final newMessage = await _chatRepository.sendMessage(senderId, receiverId, content);
      _messages.add(newMessage); // Add to local list
      FirebaseAnalytics.instance.logEvent( // Analytics event
        name: 'chat_message_sent',
        parameters: {
          'sender_id': senderId,
          'receiver_id': receiverId,
          'message_length': content.length,
        },
      );
      print('Analytics: Logged chat_message_sent');
      notifyListeners(); // Notify listeners for real-time update
    } catch (e, s) {
      print('Failed to send message: $e');
      FirebaseCrashlytics.instance.recordError(e, s, reason: 'Failed to send message in ChatProvider');
      // Handle error
    }
  }
}
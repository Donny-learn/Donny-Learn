// lib/data/chat_repository.dart

import 'package:scheduler_app/models/message.dart'; // Import Message model

/// Mock ChatRepository: Simulates API calls for chat messages.
/// In a real app, this would use WebSockets or a real-time database.
class ChatRepository {
  // Mock messages for demonstration
  final List<Message> _mockMessages = [
    Message(id: 'm1', senderId: 'friend1', receiverId: 'mock_uid_1', content: 'Hey, planning a meet up tomorrow?', timestamp: DateTime.now().subtract(const Duration(minutes: 5))),
    Message(id: 'm2', senderId: 'mock_uid_1', receiverId: 'friend1', content: 'Sounds good! What time?', timestamp: DateTime.now().subtract(const Duration(minutes: 3))),
    Message(id: 'm3', senderId: 'friend2', receiverId: 'mock_uid_1', content: 'Are you available next Monday?', timestamp: DateTime.now().subtract(const Duration(minutes: 10))),
  ];

  /// Simulates fetching messages for a given user/conversation.
  Future<List<Message>> getMessages(String userId, {String? conversationId}) async {
    print('Simulating API call: getMessages for $userId');
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
    // In a real app, you'd filter by userId or conversationId
    return List.from(_mockMessages);
  }

  /// Simulates sending a new message.
  Future<Message> sendMessage(String senderId, String receiverId, String content) async {
    print('Simulating API call: sendMessage from $senderId to $receiverId: "$content"');
    await Future.delayed(const Duration(seconds: 1));
    final newMessage = Message(
      id: 'm${_mockMessages.length + 1}',
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      timestamp: DateTime.now(),
    );
    _mockMessages.add(newMessage);
    return newMessage;
  }
}
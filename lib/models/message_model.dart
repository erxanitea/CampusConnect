import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};

    // Safely handle the timestamp
    DateTime parseTimestamp() {
      final timestamp = d['createdAt'];
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is DateTime) {
        return timestamp;
      } else {
        // Default to current time if timestamp is null or invalid
        return DateTime.now();
      }
    }

    return Message(
      id: doc.id,
      conversationId: d['conversationId'] as String? ?? '',
      senderId: d['senderId'] as String? ?? '',
      senderName: d['senderName'] as String? ?? 'User',
      content: d['content'] as String? ?? '',
      createdAt: parseTimestamp(),
    );
  }

  Map<String, dynamic> toMap() {
      return {
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
      };
  }
}

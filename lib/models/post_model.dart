import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhoto;
  final bool isAnonymous;
  final String content;
  final String category;
  final String emoji;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  final String? organizationId;
  final String? organizationName;
  
  Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhoto,
    required this.isAnonymous,
    required this.content,
    required this.category,
    required this.emoji,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.createdAt,
    required this.updatedAt,

    this.organizationId,
    this.organizationName,
  });
  
  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Anonymous',
      authorPhoto: data['authorPhoto'],
      isAnonymous: data['isAnonymous'] ?? false,
      content: data['content'] ?? '',
      category: data['category'] ?? 'Thought',
      emoji: data['emoji'] ?? '💬',
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      sharesCount: data['sharesCount'] ?? 0,
      organizationId: data['organizationId'],
      organizationName: data['organizationName'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorPhoto': authorPhoto,
      'isAnonymous': isAnonymous,
      'content': content,
      'category': category,
      'emoji': emoji,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),

      if (organizationId != null) 'organizationId': organizationId,
      if (organizationName != null) 'organizationName': organizationName,
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String organizationId;
  final String title;
  final String description;
  final String createdBy;
  final String createdByName;
  final String? createdByPhotoUrl;
  final DateTime createdAt;
  final int likes;
  final int comments;
  final List<String> likedBy;

  Announcement({
    required this.id,
    required this.organizationId,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.createdByName,
    this.createdByPhotoUrl,
    required this.createdAt,
    required this.likes,
    required this.comments,
    required this.likedBy,
  });

  factory Announcement.fromMap(Map<String, dynamic> map, String docId) {
    return Announcement(
      id: docId,
      organizationId: map['organizationId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? 'Unknown',
      createdByPhotoUrl: map['createdByPhotoUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
    );
  }

  factory Announcement.fromSnapshot(DocumentSnapshot snapshot) {
    return Announcement.fromMap(
      snapshot.data() as Map<String, dynamic>,
      snapshot.id,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'organizationId': organizationId,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdByPhotoUrl': createdByPhotoUrl,
      'createdAt': createdAt,
      'likes': likes,
      'comments': comments,
      'likedBy': likedBy,
    };
  }

  Announcement copyWith({
    String? id,
    String? organizationId,
    String? title,
    String? description,
    String? createdBy,
    String? createdByName,
    String? createdByPhotoUrl,
    DateTime? createdAt,
    int? likes,
    int? comments,
    List<String>? likedBy,
  }) {
    return Announcement(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdByPhotoUrl: createdByPhotoUrl ?? this.createdByPhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      likedBy: likedBy ?? this.likedBy,
    );
  }
}

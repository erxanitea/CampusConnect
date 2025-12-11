import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final int campusPoints;
  final int totalPosts;
  final int totalLikes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.campusPoints,
    required this.totalPosts,
    required this.totalLikes,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      campusPoints: data['campusPoints'] ?? 0,
      totalPosts: data['totalPosts'] ?? 0,
      totalLikes: data['totalLikes'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class Organization {
  final String id;
  final String name;
  final String email;
  final String location;
  final String category;
  final String status;
  final String? description;
  final String? logoUrl;
  final int memberCount;
  final int postCount;
  final double engagementRate;
  final String? foundedDate;
  final int weeklyPosts;
  final int avgReactions;
  final List<String> memberIds;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Organization({
    required this.id,
    required this.name,
    required this.email,
    required this.location,
    required this.category,
    required this.status,
    this.description,
    this.logoUrl,
    required this.memberCount,
    required this.postCount,
    required this.engagementRate,
    this.foundedDate,
    required this.weeklyPosts,
    required this.avgReactions,
    required this.memberIds,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Organization.fromMap(Map<String, dynamic> map, String docId) {
    return Organization(
      id: docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      location: map['location'] ?? '',
      category: map['category'] ?? 'Academic',
      status: map['status'] ?? 'active',
      description: map['description'],
      logoUrl: map['logoUrl'],
      memberCount: map['members'] ?? map['memberCount'] ?? 0,
      postCount: map['posts'] ?? map['postCount'] ?? 0,
      engagementRate: (map['engagement'] ?? map['engagementRate'] ?? 0).toDouble(),
      foundedDate: map['founded'] ?? map['foundedDate'],
      weeklyPosts: map['weeklyPosts'] ?? 0,
      avgReactions: map['avgReactions'] ?? 0,
      memberIds: List<String>.from(map['memberIds'] ?? []),
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory Organization.fromSnapshot(DocumentSnapshot snapshot) {
    return Organization.fromMap(
      snapshot.data() as Map<String, dynamic>,
      snapshot.id,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'location': location,
      'category': category,
      'status': status,
      'description': description,
      'logoUrl': logoUrl,
      'memberCount': memberCount,
      'postCount': postCount,
      'engagementRate': engagementRate,
      'foundedDate': foundedDate,
      'weeklyPosts': weeklyPosts,
      'avgReactions': avgReactions,
      'memberIds': memberIds,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Organization copyWith({
    String? id,
    String? name,
    String? email,
    String? location,
    String? category,
    String? status,
    String? description,
    String? logoUrl,
    int? memberCount,
    int? postCount,
    double? engagementRate,
    String? foundedDate,
    int? weeklyPosts,
    int? avgReactions,
    List<String>? memberIds,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      location: location ?? this.location,
      category: category ?? this.category,
      status: status ?? this.status,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      memberCount: memberCount ?? this.memberCount,
      postCount: postCount ?? this.postCount,
      engagementRate: engagementRate ?? this.engagementRate,
      foundedDate: foundedDate ?? this.foundedDate,
      weeklyPosts: weeklyPosts ?? this.weeklyPosts,
      avgReactions: avgReactions ?? this.avgReactions,
      memberIds: memberIds ?? this.memberIds,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

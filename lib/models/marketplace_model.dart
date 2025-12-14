import 'package:cloud_firestore/cloud_firestore.dart';

class MarketplaceItem {
  final String id;
  final String authorId;
  final String authorName;
  final String title;
  final String description;
  final String category;
  final String condition;
  final double price;
  final String location;
  final String photoUrls;
  final bool urgent;
  final DateTime createdAt;

  MarketplaceItem({
    this.id = '',
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.description,
    required this.category,
    required this.condition,
    required this.price,
    required this.location,
    required this.photoUrls,
    this.urgent = false,
    required this.createdAt,
  });

  factory MarketplaceItem.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    return MarketplaceItem(
      id: doc.id,
      authorId: d['authorId'] ?? '',
      authorName: d['authorName'] ?? '',
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      category: d['category'] ?? '',
      condition: d['condition'] ?? '',
      price: (d['price'] ?? 0).toDouble(),
      location: d['location'] ?? '',
      photoUrls: d['photoUrls'] ?? '',
      urgent: d['urgent'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'title': title,
      'description': description,
      'category': category,
      'condition': condition,
      'price': price,
      'location': location,
      'photoUrls': photoUrls,
      'urgent': urgent,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

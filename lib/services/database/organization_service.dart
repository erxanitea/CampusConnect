import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:stateful_widget/models/organization_model.dart';
import 'dart:io';

class OrganizationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _organizationsCollection = 'organizations';
  static const String _orgMembersCollection = 'organization_members';

  Future<String> uploadOrganizationLogo(String organizationId, File imageFile) async {
    try {
      final fileName = 'org_${organizationId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('organization_logos').child(fileName);
      
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading logo: $e');
      rethrow;
    }
  }

  Future<String> createOrganization({
    required String name,
    required String email,
    required String location,
    required String category,
    String? description,
    String? logoUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      final userId = user?.uid ?? 'admin_${DateTime.now().millisecondsSinceEpoch}';

      final orgRef = await _firestore.collection(_organizationsCollection).add({
        'name': name,
        'email': email,
        'location': location,
        'category': category,
        'status': 'active',
        'description': description,
        'logoUrl': logoUrl,
        'memberCount': 1,
        'postCount': 0,
        'engagementRate': 0.0,
        'foundedDate': DateTime.now().toString().split(' ')[0],
        'weeklyPosts': 0,
        'avgReactions': 0,
        'memberIds': [userId],
        'createdBy': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (user != null) {
        await _addOrganizationMember(orgRef.id, user.uid, 'admin');
      }

      return orgRef.id;
    } catch (e) {
      print('Error creating organization: $e');
      rethrow;
    }
  }

  Future<Organization> getOrganization(String organizationId) async {
    try {
      final doc = await _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .get();

      if (!doc.exists) throw 'Organization not found';

      return Organization.fromSnapshot(doc);
    } catch (e) {
      print('Error getting organization: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getOrganizationsStream({
    int limit = 50,
    String? category,
    String? status,
  }) {
    Query query = _firestore
        .collection(_organizationsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots();
  }

  Stream<List<Organization>> getOrganizationsByUser(String userId) {
    return _firestore
        .collection(_organizationsCollection)
        .where('memberIds', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Organization.fromSnapshot(doc)).toList());
  }

  Future<void> updateOrganization(
    String organizationId, {
    String? name,
    String? email,
    String? location,
    String? category,
    String? status,
    String? description,
    String? logoUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email;
      if (location != null) updates['location'] = location;
      if (category != null) updates['category'] = category;
      if (status != null) updates['status'] = status;
      if (description != null) updates['description'] = description;
      if (logoUrl != null) updates['logoUrl'] = logoUrl;

      await _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .update(updates);
    } catch (e) {
      print('Error updating organization: $e');
      rethrow;
    }
  }

  Future<void> deleteOrganization(String organizationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'User not authenticated';

      final org = await getOrganization(organizationId);
      if (org.createdBy != user.uid) {
        throw 'Only organization creator can delete it';
      }

      await _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .delete();

      await _firestore
          .collectionGroup(_orgMembersCollection)
          .where('organizationId', isEqualTo: organizationId)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });
    } catch (e) {
      print('Error deleting organization: $e');
      rethrow;
    }
  }

  Future<void> _addOrganizationMember(
    String organizationId,
    String userId,
    String role,
  ) async {
    try {
      await _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .collection(_orgMembersCollection)
          .doc(userId)
          .set({
        'userId': userId,
        'organizationId': organizationId,
        'role': role,
        'joinedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding organization member: $e');
      rethrow;
    }
  }

  Future<void> addMemberToOrganization(
    String organizationId,
    String userId,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'User not authenticated';

      final org = await getOrganization(organizationId);

      if (org.memberIds.contains(userId)) {
        throw 'User is already a member';
      }

      await _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .update({
        'memberIds': FieldValue.arrayUnion([userId]),
        'memberCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _addOrganizationMember(organizationId, userId, 'member');
    } catch (e) {
      print('Error adding member to organization: $e');
      rethrow;
    }
  }

  Future<void> removeMemberFromOrganization(
    String organizationId,
    String userId,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'User not authenticated';

      final org = await getOrganization(organizationId);

      if (org.createdBy != user.uid && user.uid != userId) {
        throw 'Not authorized to remove member';
      }

      await _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .update({
        'memberIds': FieldValue.arrayRemove([userId]),
        'memberCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .collection(_orgMembersCollection)
          .doc(userId)
          .delete();
    } catch (e) {
      print('Error removing member from organization: $e');
      rethrow;
    }
  }

  Future<void> updateOrganizationStats(
    String organizationId, {
    int? posts,
    int? reactions,
    int? weeklyPosts,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (posts != null) {
        updates['postCount'] = FieldValue.increment(posts);
      }

      if (reactions != null) {
        updates['avgReactions'] = FieldValue.increment(reactions);
      }

      if (weeklyPosts != null) {
        updates['weeklyPosts'] = weeklyPosts;
      }

      await _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .update(updates);
    } catch (e) {
      print('Error updating organization stats: $e');
      rethrow;
    }
  }

  Future<void> updateEngagementRate(
    String organizationId,
    double engagementRate,
  ) async {
    try {
      await _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .update({
        'engagementRate': engagementRate,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating engagement rate: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getOrganizationMembers(String organizationId) {
    return _firestore
        .collection(_organizationsCollection)
        .doc(organizationId)
        .collection(_orgMembersCollection)
        .orderBy('joinedAt', descending: true)
        .snapshots();
  }

  Future<List<Organization>> searchOrganizations(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_organizationsCollection)
          .where('status', isEqualTo: 'active')
          .get();

      final results = snapshot.docs
          .map((doc) => Organization.fromSnapshot(doc))
          .where((org) =>
              org.name.toLowerCase().contains(query.toLowerCase()) ||
              org.category.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return results;
    } catch (e) {
      print('Error searching organizations: $e');
      rethrow;
    }
  }

  Future<int> getOrganizationMemberCount(String organizationId) async {
    try {
      final snapshot = await _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .collection(_orgMembersCollection)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting member count: $e');
      rethrow;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:stateful_widget/models/organization_model.dart';
import 'package:stateful_widget/models/announcement_model.dart';
import 'package:stateful_widget/models/user_model.dart';
import 'dart:io';

class OrganizationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _organizationsCollection = 'organizations';
  static const String _orgMembersCollection = 'organization_members';
  static const String _announcementsCollection = 'announcements';
  static const String _usersCollection = 'users';

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
      // Validate inputs
      if (organizationId.isEmpty) {
        throw 'Organization ID cannot be empty';
      }
      if (userId.isEmpty) {
        throw 'User ID cannot be empty';
      }
      
      print('_addOrganizationMember: Adding $userId to org $organizationId with role $role');
      
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
      
      print('_addOrganizationMember: Successfully added $userId to org $organizationId');
    } catch (e) {
      print('Error adding organization member: $e');
      rethrow;
    }
  }

  Future<void> addMemberToOrganization(
    String organizationId,
    String userId, {
    String role = 'member',
  }) async {
    try {
      print('Step 1: Checking if user exists...');
      try {
        final userDoc = await _firestore.collection(_usersCollection).doc(userId).get();
        if (!userDoc.exists) {
          throw 'User does not exist';
        }
        print('Step 1: User exists - ${userDoc['displayName']}');
      } catch (e) {
        print('Step 1 ERROR: $e');
        rethrow;
      }

      print('Step 2: Getting organization...');
      try {
        final org = await getOrganization(organizationId);
        print('Step 2: Organization found - ${org.name}');
        
        // Check if user already exists in organization_members subcollection
        final memberDoc = await _firestore
            .collection(_organizationsCollection)
            .doc(organizationId)
            .collection(_orgMembersCollection)
            .doc(userId)
            .get();
        
        if (memberDoc.exists) {
          final existingRole = memberDoc['role'] ?? 'member';
          print('Step 2: User already exists in organization_members subcollection with role: $existingRole');
          // If they already have the same role, reject the addition
          if (existingRole == role) {
            throw 'User is already a member of this organization';
          }
          // If they have a different role, we'll update it in Step 4
          print('Step 2: User exists with different role ($existingRole vs $role), will update');
        }
      } catch (e) {
        print('Step 2 ERROR: $e');
        rethrow;
      }

      print('Step 3: Updating organization memberIds...');
      try {
        await _firestore
            .collection(_organizationsCollection)
            .doc(organizationId)
            .update({
          'memberIds': FieldValue.arrayUnion([userId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('Step 3: Organization updated successfully');
      } catch (e) {
        print('Step 3 ERROR: $e');
        rethrow;
      }

      print('Step 4: Adding organization member with "$role" role...');
      try {
        await _addOrganizationMember(organizationId, userId, role);
        print('Step 4: Organization member added successfully with role "$role"');
      } catch (e) {
        print('Step 4 ERROR: $e');
        rethrow;
      }

      print('Step 5: Syncing member count...');
      try {
        print('Step 5a: Getting organization members...');
        final membersSnapshot = await _firestore
            .collection(_organizationsCollection)
            .doc(organizationId)
            .collection(_orgMembersCollection)
            .get();
        
        // Count all members (including admins)
        final actualMemberCount = membersSnapshot.docs.length;
        print('Step 5b: Found ${membersSnapshot.docs.length} total members in subcollection');
        
        print('Step 5c: Updating memberCount field...');
        await _firestore
            .collection(_organizationsCollection)
            .doc(organizationId)
            .update({
          'memberCount': actualMemberCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('Step 5: Member count synced successfully to $actualMemberCount total members');
      } catch (e) {
        print('Step 5 ERROR: $e');
        // Don't rethrow - member count sync failure shouldn't block member addition
      }
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
      await _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .update({
        'memberIds': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Sync member count after removal
      await syncOrganizationMemberCount(organizationId);

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

  Future<String> postAnnouncement({
    required String organizationId,
    required String title,
    required String description,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'User not authenticated';

      final userDoc = await _firestore.collection(_usersCollection).doc(user.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      
      final announcementRef = await _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .collection(_announcementsCollection)
          .add({
        'organizationId': organizationId,
        'title': title,
        'description': description,
        'createdBy': user.uid,
        'createdByName': userData?['displayName'] ?? user.email ?? 'Unknown',
        'createdByPhotoUrl': userData?['photoURL'],
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'comments': 0,
        'likedBy': [],
      });

      try {
        await updateOrganizationStats(organizationId, posts: 1);
      } catch (e) {
        print('Warning: Could not update organization stats: $e');
      }

      return announcementRef.id;
    } catch (e) {
      print('Error posting announcement: $e');
      rethrow;
    }
  }

  Stream<List<Announcement>> getOrganizationAnnouncements(String organizationId) {
    return _firestore
        .collection(_organizationsCollection)
        .doc(organizationId)
        .collection(_announcementsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Announcement.fromSnapshot(doc)).toList());
  }

  Future<void> likeAnnouncement(
    String organizationId,
    String announcementId,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'User not authenticated';

      final announcementRef = _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .collection(_announcementsCollection)
          .doc(announcementId);

      final announcementDoc = await announcementRef.get();
      final announcement = Announcement.fromSnapshot(announcementDoc);

      if (!announcement.likedBy.contains(user.uid)) {
        await announcementRef.update({
          'likedBy': FieldValue.arrayUnion([user.uid]),
          'likes': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print('Error liking announcement: $e');
      rethrow;
    }
  }

  Future<void> unlikeAnnouncement(
    String organizationId,
    String announcementId,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'User not authenticated';

      final announcementRef = _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .collection(_announcementsCollection)
          .doc(announcementId);

      await announcementRef.update({
        'likedBy': FieldValue.arrayRemove([user.uid]),
        'likes': FieldValue.increment(-1),
      });
    } catch (e) {
      print('Error unliking announcement: $e');
      rethrow;
    }
  }

  Future<List<AppUser>> searchUsersForMembership(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .get();

      final results = snapshot.docs
          .map((doc) => AppUser.fromFirestore(doc))
          .where((user) =>
              user.displayName?.toLowerCase().contains(query.toLowerCase()) ?? false ||
              user.email.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return results;
    } catch (e) {
      print('Error searching users: $e');
      rethrow;
    }
  }

  Future<List<AppUser>> getOrganizationMembersDetails(String organizationId) async {
    try {
      final membersSnapshot = await _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .collection(_orgMembersCollection)
          .get();

      if (membersSnapshot.docs.isEmpty) {
        await _initializeOrganizationMembers(organizationId);
        return await getOrganizationMembersDetails(organizationId);
      }

      final members = <AppUser>[];
      for (final memberDoc in membersSnapshot.docs) {
        final userId = memberDoc.id;
        print('DEBUG getOrganizationMembersDetails: Fetching user data for userId: $userId');
        final userDoc = await _firestore.collection(_usersCollection).doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>?;
          print('DEBUG: User document exists for $userId: ${userData?['displayName']}');
          members.add(AppUser.fromFirestore(userDoc));
        } else {
          print('DEBUG: User document NOT FOUND for userId: $userId');
        }
      }

      print('DEBUG: Loaded ${members.length} members for organization $organizationId');
      for (final member in members) {
        print('DEBUG: Member - ${member.displayName} (${member.uid})');
      }

      return members;
    } catch (e) {
      print('Error getting organization members details: $e');
      return [];
    }
  }

  Future<void> _initializeOrganizationMembers(String organizationId) async {
    try {
      final orgDoc = await _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .get();

      if (!orgDoc.exists) return;

      final data = orgDoc.data() as Map<String, dynamic>?;
      if (data == null) return;

      final memberIds = data['memberIds'];
      final createdBy = data['createdBy'];
      final createdByRole = data['createdByRole'] ?? 'admin';

      if (memberIds is List) {
        for (final memberId in memberIds) {
          if (memberId is String) {
            // Check if member already exists in subcollection
            final existingMember = await _firestore
                .collection(_organizationsCollection)
                .doc(organizationId)
                .collection(_orgMembersCollection)
                .doc(memberId)
                .get();
            
            // Only add if doesn't exist; preserve existing role
            if (!existingMember.exists) {
              // Determine role: creator is admin, others are members
              final role = memberId == createdBy ? createdByRole : 'member';
              await _addOrganizationMember(organizationId, memberId, role);
            }
          }
        }
      } else if (createdBy is String) {
        final existingMember = await _firestore
            .collection(_organizationsCollection)
            .doc(organizationId)
            .collection(_orgMembersCollection)
            .doc(createdBy)
            .get();
        
        if (!existingMember.exists) {
          await _addOrganizationMember(organizationId, createdBy, createdByRole);
        }
      }
    } catch (e) {
      print('Error initializing organization members: $e');
    }
  }

  Future<void> assignAdminsToOrganization(
    String organizationId,
    List<String> adminUserIds,
  ) async {
    try {
      for (final userId in adminUserIds) {
        final userDoc = await _firestore.collection(_usersCollection).doc(userId).get();
        if (!userDoc.exists) {
          throw 'User $userId does not exist';
        }

        // Add admin to organization_members subcollection with admin role
        await _addOrganizationMember(organizationId, userId, 'admin');
        
        // Also add admin to memberIds array so they appear in user's organizations
        await _firestore
            .collection(_organizationsCollection)
            .doc(organizationId)
            .update({
          'memberIds': FieldValue.arrayUnion([userId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        print('Added $userId as admin to organization $organizationId');
      }
      
      // Sync member count after adding admins
      await syncOrganizationMemberCount(organizationId);
    } catch (e) {
      print('Error assigning admins to organization: $e');
      rethrow;
    }
  }

  Future<void> syncOrganizationMemberCount(String organizationId) async {
    try {
      print('Syncing member count for organization: $organizationId');
      
      final membersSnapshot = await _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .collection(_orgMembersCollection)
          .get();

      // Count all members (including admins)
      final actualMemberCount = membersSnapshot.docs.length;
      final actualMemberIds = membersSnapshot.docs.map((doc) => doc.id).toList();
      
      print('Found ${membersSnapshot.docs.length} total members in subcollection for $organizationId');

      final orgDoc = await _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .get();
      
      if (!orgDoc.exists) {
        print('Organization $organizationId does not exist');
        return;
      }

      final currentCount = orgDoc['memberCount'] ?? 0;
      final currentMemberIds = List<String>.from(orgDoc['memberIds'] ?? []);
      print('Current memberCount in document: $currentCount, actual: $actualMemberCount');
      print('Current memberIds: $currentMemberIds, actual: $actualMemberIds');

      // Update both memberCount (all members) and memberIds (all members)
      await _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .update({
        'memberCount': actualMemberCount,
        'memberIds': actualMemberIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✓ Synced member count and memberIds for organization $organizationId: $actualMemberCount total members');
    } catch (e) {
      print('✗ Error syncing member count for $organizationId: $e');
      rethrow;
    }
  }

  Future<String> getOrganizationMemberRole(String organizationId, String userId) async {
    try {
      final memberDoc = await _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .collection(_orgMembersCollection)
          .doc(userId)
          .get();
      
      if (!memberDoc.exists) {
        return 'member'; // Default to member if not found
      }
      
      return memberDoc['role'] ?? 'member';
    } catch (e) {
      print('Error getting member role: $e');
      return 'member';
    }
  }

  Future<void> updateMemberRole(String organizationId, String userId, String newRole) async {
    try {
      if (organizationId.isEmpty) {
        throw 'Organization ID cannot be empty';
      }
      if (userId.isEmpty) {
        throw 'User ID cannot be empty';
      }
      if (newRole != 'admin' && newRole != 'member') {
        throw 'Invalid role: $newRole';
      }

      print('Updating member $userId role to $newRole in organization $organizationId');

      await _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .collection(_orgMembersCollection)
          .doc(userId)
          .update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✓ Successfully updated member role to $newRole');
    } catch (e) {
      print('✗ Error updating member role: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getOrganizationMembersStream(String organizationId) {
    return _firestore
        .collection(_organizationsCollection)
        .doc(organizationId)
        .collection(_orgMembersCollection)
        .orderBy('joinedAt', descending: true)
        .snapshots();
  }

  Future<void> cleanupDuplicateMembers(String organizationId) async {
    try {
      print('Cleaning up duplicate members for organization: $organizationId');
      
      final membersSnapshot = await _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .collection(_orgMembersCollection)
          .get();
      
      // Group members by userId to find duplicates
      final membersByUserId = <String, List<DocumentSnapshot>>{};
      for (final doc in membersSnapshot.docs) {
        final userId = doc.id;
        if (!membersByUserId.containsKey(userId)) {
          membersByUserId[userId] = [];
        }
        membersByUserId[userId]!.add(doc);
      }
      
      // Remove duplicates, keeping the admin role if it exists
      for (final entry in membersByUserId.entries) {
        final userId = entry.key;
        final docs = entry.value;
        
        if (docs.length > 1) {
          print('Found ${docs.length} entries for user $userId, cleaning up...');
          
          // Sort by role - admin first, then member
          docs.sort((a, b) {
            final roleA = a['role'] ?? 'member';
            final roleB = b['role'] ?? 'member';
            if (roleA == 'admin') return -1;
            if (roleB == 'admin') return 1;
            return 0;
          });
          
          // Keep the first one (admin if exists, otherwise member)
          final keepDoc = docs[0];
          print('Keeping entry with role: ${keepDoc['role']}');
          
          // Delete the rest
          for (int i = 1; i < docs.length; i++) {
            print('Deleting duplicate entry with role: ${docs[i]['role']}');
            await docs[i].reference.delete();
          }
        }
      }
      
      print('✓ Cleanup completed for organization $organizationId');
    } catch (e) {
      print('✗ Error cleaning up duplicates for $organizationId: $e');
      rethrow;
    }
  }

  Future<void> syncAllOrganizationMemberCounts() async {
    try {
      print('Starting to sync all organization member counts...');
      final orgsSnapshot = await _firestore
          .collection(_organizationsCollection)
          .get();

      print('Found ${orgsSnapshot.docs.length} organizations to sync');

      for (final orgDoc in orgsSnapshot.docs) {
        final orgId = orgDoc.id;
        print('Syncing member count for organization: $orgId');
        
        try {
          // First clean up any duplicates
          await cleanupDuplicateMembers(orgId);
          // Then sync the count
          await syncOrganizationMemberCount(orgId);
        } catch (e) {
          print('Error syncing organization $orgId: $e');
        }
      }

      print('Finished syncing all organization member counts');
    } catch (e) {
      print('Error syncing all organizations: $e');
      rethrow;
    }
  }

  Future<void> fixMemberRoles(String organizationId, String userId, String correctRole) async {
    try {
      print('Fixing role for user $userId in organization $organizationId to $correctRole');
      
      await _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .collection(_orgMembersCollection)
          .doc(userId)
          .update({
        'role': correctRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✓ Fixed role for user $userId to $correctRole');
    } catch (e) {
      print('✗ Error fixing member role: $e');
      rethrow;
    }
  }

  Future<void> fixAllAdminRoles(String organizationId, List<String> adminUserIds) async {
    try {
      print('Fixing admin roles for organization $organizationId');
      print('Admin IDs to fix: $adminUserIds');
      
      for (final userId in adminUserIds) {
        await _firestore
            .collection(_organizationsCollection)
            .doc(organizationId)
            .collection(_orgMembersCollection)
            .doc(userId)
            .update({
          'role': 'admin',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✓ Fixed $userId to admin role');
      }
      
      print('✓ All admin roles fixed');
    } catch (e) {
      print('✗ Error fixing admin roles: $e');
      rethrow;
    }
  }

  Future<void> diagnoseOrganizationData(String organizationId) async {
    try {
      print('\n╔════════════════════════════════════════════════════════════╗');
      print('║     FIRESTORE DATABASE STRUCTURE DIAGNOSIS                 ║');
      print('╚════════════════════════════════════════════════════════════╝\n');

      final orgDoc = await _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .get();

      if (!orgDoc.exists) {
        print('❌ Organization $organizationId does not exist');
        return;
      }

      final orgData = orgDoc.data() as Map<String, dynamic>;
      
      print('📦 ORGANIZATION DOCUMENT:');
      print('   ID: $organizationId');
      print('   Name: ${orgData['name']}');
      print('   memberIds array: ${orgData['memberIds']}');
      print('   memberCount field: ${orgData['memberCount']}');
      print('   createdBy: ${orgData['createdBy']}');
      print('   status: ${orgData['status']}\n');

      // Get organization_members subcollection
      final membersSnapshot = await _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .collection(_orgMembersCollection)
          .get();

      print('📋 ORGANIZATION_MEMBERS SUBCOLLECTION:');
      print('   Total documents: ${membersSnapshot.docs.length}\n');

      for (final memberDoc in membersSnapshot.docs) {
        final memberData = memberDoc.data() as Map<String, dynamic>;
        print('   ├─ User ID: ${memberDoc.id}');
        print('   │  ├─ role: ${memberData['role']}');
        print('   │  ├─ userId: ${memberData['userId']}');
        print('   │  ├─ organizationId: ${memberData['organizationId']}');
        print('   │  └─ joinedAt: ${memberData['joinedAt']}');
      }

      print('\n🔍 DATA CONSISTENCY ANALYSIS:');
      
      final memberIdsArray = List<String>.from(orgData['memberIds'] ?? []);
      final subcollectionIds = membersSnapshot.docs.map((d) => d.id).toSet();

      print('   memberIds array count: ${memberIdsArray.length}');
      print('   Subcollection docs count: ${membersSnapshot.docs.length}');

      final orphaned = memberIdsArray.where((id) => !subcollectionIds.contains(id)).toList();
      final missing = subcollectionIds.where((id) => !memberIdsArray.contains(id)).toList();

      if (orphaned.isNotEmpty) {
        print('\n   ⚠️  ORPHANED IDs (in memberIds but NOT in subcollection):');
        for (final id in orphaned) {
          print('       - $id');
        }
      }

      if (missing.isNotEmpty) {
        print('\n   ⚠️  MISSING IDs (in subcollection but NOT in memberIds):');
        for (final id in missing) {
          print('       - $id');
        }
      }

      // Role analysis
      print('\n📊 ROLE DISTRIBUTION:');
      final adminMembers = membersSnapshot.docs
          .where((doc) => (doc['role'] ?? 'member') == 'admin')
          .toList();
      final regularMembers = membersSnapshot.docs
          .where((doc) => (doc['role'] ?? 'member') == 'member')
          .toList();

      print('   Admin members: ${adminMembers.length}');
      for (final admin in adminMembers) {
        print('       - ${admin.id}');
      }

      print('   Regular members: ${regularMembers.length}');
      for (final member in regularMembers) {
        print('       - ${member.id}');
      }

      print('\n📈 MEMBER COUNT VERIFICATION:');
      print('   Stored memberCount: ${orgData['memberCount']}');
      print('   Actual non-admin count: ${regularMembers.length}');
      print('   Actual admin count: ${adminMembers.length}');
      print('   Total in subcollection: ${membersSnapshot.docs.length}');

      if (orgData['memberCount'] != regularMembers.length) {
        print('   ❌ MISMATCH: memberCount should be ${regularMembers.length}');
      } else {
        print('   ✅ memberCount is correct');
      }

      if (orphaned.isEmpty && missing.isEmpty) {
        print('\n   ✅ memberIds array is in sync with subcollection');
      } else {
        print('\n   ❌ memberIds array is OUT OF SYNC with subcollection');
      }

      print('\n╚════════════════════════════════════════════════════════════╝\n');
    } catch (e) {
      print('Error diagnosing organization data: $e');
      rethrow;
    }
  }

  Future<void> syncOrganizationData(String organizationId) async {
    try {
      print('=== Starting full organization data sync for $organizationId ===');
      
      final orgDoc = await _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .get();
      
      if (!orgDoc.exists) {
        print('Organization does not exist');
        return;
      }

      final data = orgDoc.data() as Map<String, dynamic>;
      final memberIds = List<String>.from(data['memberIds'] ?? []);
      
      print('Organization memberIds from document: $memberIds');

      // Get all members from subcollection
      final membersSnapshot = await _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .collection(_orgMembersCollection)
          .get();

      print('Members in subcollection: ${membersSnapshot.docs.map((d) => '${d.id}(${d['role']})').toList()}');

      // Fix: Remove from memberIds any users not in subcollection
      final subcollectionIds = membersSnapshot.docs.map((d) => d.id).toSet();
      final orphanedIds = memberIds.where((id) => !subcollectionIds.contains(id)).toList();
      
      if (orphanedIds.isNotEmpty) {
        print('Found orphaned memberIds not in subcollection: $orphanedIds');
        await _firestore
            .collection(_organizationsCollection)
            .doc(organizationId)
            .update({
          'memberIds': FieldValue.arrayRemove(orphanedIds),
        });
        print('Removed orphaned memberIds');
      }

      // Fix: Add to memberIds any users in subcollection but not in memberIds
      final missingIds = subcollectionIds.where((id) => !memberIds.contains(id)).toList();
      if (missingIds.isNotEmpty) {
        print('Found members in subcollection not in memberIds: $missingIds');
        await _firestore
            .collection(_organizationsCollection)
            .doc(organizationId)
            .update({
          'memberIds': FieldValue.arrayUnion(missingIds.toList()),
        });
        print('Added missing memberIds');
      }

      // Sync member count (non-admin only)
      final nonAdminMembers = membersSnapshot.docs
          .where((doc) => (doc['role'] ?? 'member') != 'admin')
          .toList();
      final memberCount = nonAdminMembers.length;
      
      print('Total members in subcollection: ${membersSnapshot.docs.length}');
      print('Non-admin members: $memberCount');
      print('Admin members: ${membersSnapshot.docs.length - memberCount}');

      await _firestore
          .collection(_organizationsCollection)
          .doc(organizationId)
          .update({
        'memberCount': memberCount,
        'memberIds': subcollectionIds.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✓ Synced memberCount to $memberCount non-admin members');
      print('✓ Synced memberIds to match subcollection');
      print('=== Organization data sync completed ===');
    } catch (e) {
      print('✗ Error syncing organization data: $e');
      rethrow;
    }
  }
}

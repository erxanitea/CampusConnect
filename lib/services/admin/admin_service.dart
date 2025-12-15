import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Singleton instance
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();
  
  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return false;
    
    return await isAdminByEmail(user.email!);
  }
  
  // Check if email is in admin_emails collection
  Future<bool> isAdminByEmail(String email) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      
      final snapshot = await _firestore
          .collection('admin_emails')
          .where('email', isEqualTo: cleanEmail)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }
  
  // Get all admin emails
  Future<List<String>> getAllAdminEmails() async {
    try {
      final snapshot = await _firestore
          .collection('admin_emails')
          .where('isActive', isEqualTo: true)
          .get();
      
      return snapshot.docs
          .map((doc) => doc.data()['email'] as String)
          .toList();
    } catch (e) {
      print('Error getting admin emails: $e');
      return [];
    }
  }
  
  // Add new admin email
  Future<bool> addAdminEmail(String email, {String? addedBy}) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      
      // Check if already exists
      final existing = await _firestore
          .collection('admin_emails')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();
      
      if (existing.docs.isNotEmpty) {
        // Update existing to active
        await existing.docs.first.reference.update({
          'isActive': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
      
      // Create new
      await _firestore.collection('admin_emails').add({
        'email': cleanEmail,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': addedBy ?? 'system',
        'permissions': ['all'], // Default all permissions
      });
      
      return true;
    } catch (e) {
      print('Error adding admin email: $e');
      return false;
    }
  }
  
  // Remove/disable admin email
  Future<bool> removeAdminEmail(String email) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      
      final snapshot = await _firestore
          .collection('admin_emails')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return false;
      
      // Soft delete (set inactive)
      await snapshot.docs.first.reference.update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('Error removing admin email: $e');
      return false;
    }
  }
  
  // Log admin action
  Future<void> logAdminAction({
    required String action,
    String? targetId,
    Map<String, dynamic>? details,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      await _firestore.collection('admin_logs').add({
        'adminId': user.uid,
        'adminEmail': user.email,
        'action': action,
        'targetId': targetId,
        'details': details ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        // Note: Firebase doesn't have IP in client SDK
        // You'd need a cloud function or different approach for IP
      });
    } catch (e) {
      print('Error logging admin action: $e');
    }
  }
  
  // Get system configuration
  Future<Map<String, dynamic>> getSystemConfig() async {
    try {
      final doc = await _firestore
          .collection('system_config')
          .doc('admin_settings')
          .get();
      
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      
      // Return defaults if not exists
      return {
        'requireAdminApproval': false,
        'maxReportAge': 7,
        'autoArchiveOldOrgs': true,
        'orgArchiveDays': 30,
      };
    } catch (e) {
      print('Error getting system config: $e');
      return {};
    }
  }
  
  // Update system configuration
  Future<bool> updateSystemConfig(Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection('system_config')
          .doc('admin_settings')
          .set({
            ...updates,
            'lastConfigUpdate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      
      return true;
    } catch (e) {
      print('Error updating system config: $e');
      return false;
    }
  }
  
  // Get admin statistics
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      // Get counts from various collections
      final usersCount = await _getCollectionCount('users');
      final postsCount = await _getCollectionCount('posts');
      final reportsCount = await _getCollectionCount('reports');
      final orgsCount = await _getCollectionCount('organizations');
      
      return {
        'totalUsers': usersCount,
        'totalPosts': postsCount,
        'pendingReports': reportsCount,
        'totalOrganizations': orgsCount,
        'timestamp': FieldValue.serverTimestamp(),
      };
    } catch (e) {
      print('Error getting admin stats: $e');
      return {};
    }
  }
  
  // Helper to get collection count
  Future<int> _getCollectionCount(String collectionName) async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .count()
          .get();
      final count = snapshot.count;
      if (count == null) {
        return 0;
      }
      return count;
    } catch (e) {
      print('Error counting $collectionName: $e');
      return 0;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> inspectFirestoreStructure() async {
  final firestore = FirebaseFirestore.instance;

  print('=== FIRESTORE DATABASE STRUCTURE INSPECTION ===\n');

  try {
    // Get all organizations
    print('📦 ORGANIZATIONS COLLECTION:');
    final orgsSnapshot = await firestore.collection('organizations').get();
    print('Total organizations: ${orgsSnapshot.docs.length}\n');

    for (final orgDoc in orgsSnapshot.docs) {
      final orgData = orgDoc.data();
      print('Organization ID: ${orgDoc.id}');
      print('Name: ${orgData['name']}');
      print('memberIds: ${orgData['memberIds']}');
      print('memberCount: ${orgData['memberCount']}');
      print('Status: ${orgData['status']}');

      // Get organization_members subcollection
      print('\n  📋 ORGANIZATION_MEMBERS SUBCOLLECTION:');
      final membersSnapshot = await firestore
          .collection('organizations')
          .doc(orgDoc.id)
          .collection('organization_members')
          .get();

      print('  Total members in subcollection: ${membersSnapshot.docs.length}');

      for (final memberDoc in membersSnapshot.docs) {
        final memberData = memberDoc.data();
        print('  - User ID: ${memberDoc.id}');
        print('    Role: ${memberData['role']}');
        print('    Joined At: ${memberData['joinedAt']}');
      }

      // Check for data inconsistencies
      print('\n  🔍 DATA CONSISTENCY CHECK:');
      final subcollectionIds =
          membersSnapshot.docs.map((d) => d.id).toSet();
      final memberIdsArray =
          List<String>.from(orgData['memberIds'] ?? []);

      final orphaned =
          memberIdsArray.where((id) => !subcollectionIds.contains(id)).toList();
      final missing =
          subcollectionIds.where((id) => !memberIdsArray.contains(id)).toList();

      if (orphaned.isNotEmpty) {
        print('  ⚠️  ORPHANED IDs (in memberIds but not in subcollection): $orphaned');
      }
      if (missing.isNotEmpty) {
        print('  ⚠️  MISSING IDs (in subcollection but not in memberIds): $missing');
      }

      // Check member count accuracy
      final nonAdminCount = membersSnapshot.docs
          .where((doc) => (doc['role'] ?? 'member') != 'admin')
          .length;
      final adminCount = membersSnapshot.docs.length - nonAdminCount;

      print('  Members in subcollection: ${membersSnapshot.docs.length}');
      print('  Non-admin members: $nonAdminCount');
      print('  Admin members: $adminCount');
      print('  Stored memberCount: ${orgData['memberCount']}');

      if (orgData['memberCount'] != nonAdminCount) {
        print(
            '  ❌ MISMATCH: memberCount (${orgData['memberCount']}) != actual non-admin count ($nonAdminCount)');
      } else {
        print('  ✅ memberCount is correct');
      }

      print('\n' + '=' * 60 + '\n');
    }

    print('=== END OF INSPECTION ===');
  } catch (e) {
    print('Error inspecting Firestore: $e');
  }
}

void main() async {
  await inspectFirestoreStructure();
}

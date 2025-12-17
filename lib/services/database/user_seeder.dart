import 'package:cloud_firestore/cloud_firestore.dart';

class UserSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  static Future<void> seedUsers() async {
    try {
      print('UserSeeder.seedUsers() called');
      print('Firestore instance: $_firestore');
      
      final users = [
        {
          'displayName': 'MARIA SANTOS',
          'email': 'maria.santos@umindanao.edu.ph',
          'photoURL': null,
          'campusPoints': 200,
          'totalPosts': 8,
          'totalLikes': 45,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'displayName': 'JUAN DELA CRUZ',
          'email': 'juan.delacruz@umindanao.edu.ph',
          'photoURL': null,
          'campusPoints': 175,
          'totalPosts': 6,
          'totalLikes': 32,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'displayName': 'ROSA GARCIA',
          'email': 'rosa.garcia@umindanao.edu.ph',
          'photoURL': null,
          'campusPoints': 220,
          'totalPosts': 10,
          'totalLikes': 55,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'displayName': 'CARLOS REYES',
          'email': 'carlos.reyes@umindanao.edu.ph',
          'photoURL': null,
          'campusPoints': 190,
          'totalPosts': 7,
          'totalLikes': 38,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'displayName': 'ANNA LOPEZ',
          'email': 'anna.lopez@umindanao.edu.ph',
          'photoURL': null,
          'campusPoints': 240,
          'totalPosts': 11,
          'totalLikes': 62,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'displayName': 'MIGUEL TORRES',
          'email': 'miguel.torres@umindanao.edu.ph',
          'photoURL': null,
          'campusPoints': 160,
          'totalPosts': 4,
          'totalLikes': 20,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'displayName': 'SOFIA MORALES',
          'email': 'sofia.morales@umindanao.edu.ph',
          'photoURL': null,
          'campusPoints': 210,
          'totalPosts': 9,
          'totalLikes': 50,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'displayName': 'LUIS FERNANDEZ',
          'email': 'luis.fernandez@umindanao.edu.ph',
          'photoURL': null,
          'campusPoints': 185,
          'totalPosts': 6,
          'totalLikes': 35,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      int addedCount = 0;
      print('Starting to seed ${users.length} users');
      
      for (final userData in users) {
        final displayName = userData['displayName'] as String;
        print('Processing user: $displayName');
        
        try {
          print('Adding new user: $displayName');
          final docRef = await _firestore.collection(_usersCollection).add(userData);
          addedCount++;
          print('✓ Added user: $displayName (ID: ${docRef.id})');
        } catch (e) {
          print('✗ Error adding user $displayName: $e');
        }
      }

      print('=== Seeding complete. Added $addedCount new users. ===');
    } catch (e) {
      print('Error seeding users: $e');
      rethrow;
    }
  }

  static Future<void> clearAllUsers() async {
    try {
      final snapshot = await _firestore.collection(_usersCollection).get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      print('All users cleared.');
    } catch (e) {
      print('Error clearing users: $e');
      rethrow;
    }
  }
}

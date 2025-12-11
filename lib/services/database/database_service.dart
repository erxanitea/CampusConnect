import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stateful_widget/models/post_model.dart';
import 'package:stateful_widget/models/message_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createUserProfile(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'campusPoints': 0,
        'totalPosts': 0,
        'totalLikes': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }

  Future<DocumentSnapshot> getUserProfile(String userId) async {
    return await _firestore.collection('users').doc(userId).get();
  }

  Future<void> updateUserStats(String userId, {int? posts, int? likes}) async {
    final userRef = _firestore.collection('users').doc(userId);
    final updates = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};

    if (posts != null) {
      updates['totalPosts'] = FieldValue.increment(posts);

      if (posts > 0) {
        updates['campusPoints'] = FieldValue.increment(posts * 10); //10 points per posts
      }
    }

    if (likes != null) {
      updates['totalLikes'] = FieldValue.increment(likes);
      if (likes > 0) {
        updates['campusPoints'] = FieldValue.increment(likes * 2); //2 poinst per likes
      }
    }

    await userRef.update(updates);
  }


  Future<String> createPost({
    required String content,
    required bool isAnonymous,
    required String category,
    String emoji = '💬',
  }) async {
      try {
        final user = _auth.currentUser;
        if (user == null) throw 'User not authenticated';

        final postRef = await _firestore.collection('posts').add({
          'authorId': user.uid,
          'authorName': isAnonymous ? 'Anonymous' : user.displayName,
          'authorPhoto': isAnonymous ? null : user.photoURL,
          'isAnonymous' : isAnonymous,
          'content': content,
          'category': category,
          'emoji': emoji,
          'likesCount': 0,
          'commentsCount': 0,
          'sharesCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await updateUserStats(user.uid, posts: 1);

        return postRef.id;
      } catch (e) {
        print('Error creating post: $e');
        rethrow;
      }
  }

  Stream<QuerySnapshot> getPostsStream({int limit = 20}) {
    return _firestore 
      .collection('posts')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots();
  }

  Future<void> deletePost(String postId, String authorId) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != authorId) {
      throw 'Not authorized to delete this post';
    }

    await _firestore.collection('posts').doc(postId).delete();
    await updateUserStats(user.uid, posts: -1);
  }

  Future<bool> toggleLike(String postId, String authorId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated';
    
    final likeRef = _firestore
      .collection('likes')
      .where('postId', isEqualTo: postId)
      .where('userId', isEqualTo: user.uid)
      .limit(1);

    final likeSnapshot = await likeRef.get();

    if (likeSnapshot.docs.isNotEmpty) {
      await likeSnapshot.docs.first.reference.delete();
      await _firestore.collection('posts').doc(postId).update({
        'likesCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await updateUserStats(authorId, likes: -1);
      return false;
    } else {
      await _firestore.collection('likes').add({
        'postId': postId,
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('posts').doc(postId).update({
        'likesCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await updateUserStats(authorId, likes: 1);
      return true;
    }
  }

  Future<bool> checkIfLiked(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final likeSnapshot = await _firestore
      .collection('likes')
      .where('postId', isEqualTo: postId)
      .where('userId', isEqualTo: user.uid)
      .limit(1)
      .get();

    return likeSnapshot.docs.isNotEmpty;
  }

  Future<void> addComment({
    required String postId,
    required String content,
    bool isAnonymous = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated';

    final authorName = isAnonymous ? 'Anonymous' : (user.displayName ?? 'User');

    await _firestore.collection('comments').add({
      'postId': postId,
      'userId': user.uid,
      'authorName': authorName,
      'content': content,
      'isAnonymous': isAnonymous,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('posts').doc(postId).update({
      'commentsCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteComment(String commentId, String postId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated';

    final commentDoc = await _firestore.collection('comments').doc(commentId).get();
    if (!commentDoc.exists) throw 'Commment not found';

    final commentData = commentDoc.data() as Map<String, dynamic>;
    if (commentData['userId'] != user.uid) {
      throw 'Not authorized to delete this comment';
    }

    await _firestore.collection('comments').doc(commentId).delete();

    await _firestore.collection('posts').doc(postId).update({
      'commentsCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> incrementShareCount(String postId) async {
    await _firestore.collection('posts').doc(postId).update({
      'sharesCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getCommentsStream(String postId) {
    return _firestore
      .collection('comments')
      .where('postId', isEqualTo: postId)
      .orderBy('createdAt', descending: false)
      .snapshots();
  }

  Future<void> sendShareToConversation({
    required String conversationId, 
    required Post post,
  }) async {
   
    final user = _auth.currentUser;
    if (user == null) throw 'Not signed in';

    final msg = Message(
      id: '',
      conversationId: conversationId,
      senderId: user.uid,
      senderName: user.displayName ?? 'User',
      content: ' **${post.category}** | ${post.content}\n'
        '(shared from CampusConnect)',
      createdAt: DateTime.now(),
    );

    await _firestore
      .collection('conversations')
      .doc(conversationId)
      .collection('messages')
      .add(msg.toMap());

    await _firestore.collection('posts').doc(post.id).update({
      'sharesCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getConversationsForPicker() {
    final user = _auth.currentUser!;

    return _firestore
      .collection('conversations')
      .where('memberIds', arrayContains: user.uid)
      .orderBy('lastMessageAt', descending: true)
      .snapshots();
  }

  static String formatTime(DateTime t) {
    final now = DateTime.now();
    final d = now.difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inHours < 1) return '${d.inMinutes}m';
    if (d.inDays < 1) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    return '${t.month}/${t.day}';
  }
}

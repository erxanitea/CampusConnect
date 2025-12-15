import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stateful_widget/models/post_model.dart';
import 'package:stateful_widget/models/message_model.dart';
import 'package:stateful_widget/models/marketplace_model.dart';
import 'package:flutter/material.dart';

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
      
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      String postContent = '';
      if (postDoc.exists) {
        final postData = postDoc.data() as Map<String, dynamic>;
        postContent = postData['content'] as String? ?? '';
      }

      await createNotification(
        userId: authorId,
        type: 'like',
        title: '${user.displayName ?? "Someone"} liked your post',
        body: postContent.length > 50
          ? '${postContent.substring(0, 50)}...'
          : postContent,
        senderId: user.uid,
        senderName: user.displayName ?? 'User',
        extraData: {
          'postId': postId,
        }
      );
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

  Future<String> addComment({
    required String postId,
    required String content,
    bool isAnonymous = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated';

    final authorName = isAnonymous ? 'Anonymous' : (user.displayName ?? 'User');

    final commentRef = await _firestore.collection('comments').add({
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

    // After creating comment, get post author ID first
    // You need to fetch the post to get authorId
    final postDoc = await _firestore.collection('posts').doc(postId).get();
    if (postDoc.exists) {
      final postData = postDoc.data() as Map<String, dynamic>;
      final postAuthorId = postData['authorId'];
      
      await createNotification(
        userId: postAuthorId,
        type: 'comment',
        title: '${authorName} commented on your post',
        body: content.length > 50 ? '${content.substring(0, 50)}...' : content,
        senderId: user.uid,
        senderName: authorName,
        extraData: {
          'postId': postId,
          'commentId': commentRef.id,
        },
      );
    }
    return commentRef.id;
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

  // MARKETPLACE
  Stream<QuerySnapshot<Map<String, dynamic>>> getMarketplaceItemsStream({int limit = 50}) {
    return _firestore
      .collection('marketplaceItems')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots();
  }

  Future<String> createMarketplaceItem(MarketplaceItem item) async {
    final doc = await _firestore.collection('marketplaceItems').add(item.toMap());
    return doc.id;
  }

  Future<void> updateMarketplaceItem(MarketplaceItem item) async {
    await _firestore.collection('marketplaceItems').doc(item.id).update(item.toMap());
  }

  Future<void> deleteMarketplaceItem(String itemId) async {
    await _firestore.collection('marketplaceItems').doc(itemId).delete();
  }

  Future<String> getOrCreateDirectConversation(String otherUserId) async {
    final user = _auth.currentUser!;
    final ids = [user.uid, otherUserId]..sort();
    final convId = '${ids[0]}_${ids[1]}';

    final snap = await _firestore.collection('conversations').doc(convId).get();
    if (!snap.exists) {
      //create
      await _firestore.collection('conversations').doc(convId).set({
        'memberIds': ids,
        'type': 'direct',
        'name': 'Chat',
        'emoji': '💬',
        'avatarColor': const Color(0xFFE0F2FF).value,
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    }
    return convId;
  }

  Future<void> sendMessage({
    required String convId,
    required String text,
  }) async {

    final user = _auth.currentUser!;
    final msg = Message(
      id: '',
      conversationId: convId,
      senderId: user.uid,
      senderName: user.displayName ?? 'User',
      content: text.trim(),
      createdAt: DateTime.now(),
    );

    //write message
    await _firestore
      .collection('conversations')
      .doc(convId)
      .collection('messages')
      .add(msg.toMap());

    // update conversation meta
    await _firestore.collection('conversations').doc(convId).update({
      'lastMessage': msg.content,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    // After sending message, notify the other user
    final convDoc = await _firestore.collection('conversations').doc(convId).get();
    if (convDoc.exists) {
      final convData = convDoc.data() as Map<String, dynamic>;
      final memberIds = List<String>.from(convData['memberIds'] ?? []);
      
      // Find the other user ID
      for (final memberId in memberIds) {
        if (memberId != user.uid) {
          await createNotification(
            userId: memberId,
            type: 'message',
            title: 'New message from ${user.displayName ?? "User"}',
            body: text.trim().length > 50 
              ? '${text.trim().substring(0, 50)}...' 
              : text.trim(),
            senderId: user.uid,
            senderName: user.displayName ?? 'User',
            extraData: {
              'conversationId': convId,
            },
          );
          break;
        }
      }
    }
  }

  // Listen to messages in a conversation 
  Stream<QuerySnapshot> getMessagesStream(String convId) {
    return _firestore
      .collection('conversations')
      .doc(convId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .snapshots();
  }

  // listen to converstaion that current user belongs to
  Stream<QuerySnapshot> getConversationsStream() {
    final user = _auth.currentUser!;
    return _firestore
      .collection('conversations')
      .where('memberIds', arrayContains: user.uid)
      .orderBy('lastMessageAt', descending: true)
      .snapshots();
  }

  // get user doc snapshot at once 
  Future<DocumentSnapshot> getUser(String uid) => _firestore.collection('users').doc(uid).get();

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'displayName': data['displayName'],
          'email': data['email'] ?? '',
          'photoURL': data['photoURL'],
        };
      }
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  // ============ NOTIFICATION METHODS ============

  /// Create a notification
  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    required String senderId,
    required String senderName,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'senderId': senderId,
        'senderName': senderName,
      };
      
      if (extraData != null) {
        data.addAll(extraData);
      }
      
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': type,
        'title': title,
        'body': body,
        'isRead': false,
        'data': data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Notification created for user: $userId, type: $type');
    } catch (e) {
      print('❌ Error creating notification: $e');
    }
  }

  /// Get real-time stream of user notifications
  Stream<QuerySnapshot> getUserNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Mark a single notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Get unread notification count
  Stream<int> getUnreadNotificationCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}

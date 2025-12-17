import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stateful_widget/services/database/database_service.dart';
import 'package:stateful_widget/widgets/campus_bottom_nav.dart';
//import 'package:intl/intl.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  int _navIndex = 3;
  final DatabaseService _db = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      _loadNotifications();
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _currentUserId != null && _notifications.isEmpty && !_isLoading) {
          // Double-check by querying Firestore
          _checkIfHasNotifications();
        }
      });
    }
  }

  void _checkIfHasNotifications() async {
    if (_currentUserId == null) return;
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: _currentUserId!)
          .limit(1)
          .get();
          
      if (snapshot.docs.isEmpty && mounted) {
        // Only seed demo notifications if truly empty
        await _seedDemoNotifications();
      }
    } catch (e) {
      print('Error checking notifications: $e');
    }
  }

  void _loadNotifications() {
    if (_currentUserId == null) return;

    _db.getUserNotificationsStream(_currentUserId!).listen((snapshot) {
      if (!mounted) return;

      final List<Map<String, dynamic>> notifications = [];
      int unread = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final notificationId = doc.id;
        final isRead = data['isRead'] ?? false;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final type = data['type'] as String? ?? 'general';
        final notificationData = data['data'] as Map<String, dynamic>? ?? {};
        
        if (!isRead) unread++;

        // Build notification UI data
        final uiData = _buildNotificationUI(
          type: type,
          data: data,
          notificationData: notificationData,
          createdAt: createdAt,
        );

        notifications.add({
          'id': notificationId,
          'title': uiData['title'],
          'body': uiData['body'],
          'time': uiData['time'],
          'type': type,
          'accent': uiData['accent'],
          'icon': uiData['icon'],
          'isNew': !isRead,
          'data': notificationData,
          'isRead': isRead,
        });
      }

      setState(() {
        _notifications = notifications;
        _unreadCount = unread;
        _isLoading = false;
      });
    }, onError: (error) {
      print('Error loading notifications: $error');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  Map<String, dynamic> _buildNotificationUI({
    required String type,
    required Map<String, dynamic> data,
    required Map<String, dynamic> notificationData,
    required DateTime createdAt,
  }) {
    final title = data['title'] as String? ?? 'Notification';
    final body = data['body'] as String? ?? '';
    final time = _formatTime(createdAt);
    
    IconData icon;
    Color accent;

    switch (type) {
      case 'like':
        icon = Icons.favorite_border;
        accent = const Color(0xFFE85D5D);
        break;
      case 'comment':
        icon = Icons.chat_bubble_outline;
        accent = const Color(0xFF4B74C6);
        break;
      case 'message':
        icon = Icons.message_outlined;
        accent = const Color(0xFF0EA3B4);
        break;
      case 'announcement':
        icon = Icons.campaign_outlined;
        accent = const Color(0xFF1B7FBF);
        break;
      case 'marketplace':
        icon = Icons.shopping_bag_outlined;
        accent = const Color(0xFFD98E27);
        break;
      default:
        icon = Icons.notifications_none;
        accent = const Color(0xFF8D0B15);
    }

    return {
      'title': title,
      'body': body,
      'time': time,
      'icon': icon,
      'accent': accent,
    };
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    //return DateFormat('MMM d').format(time);
    return '${time.month}/${time.day}';
  }

  Future<void> _markAsRead(String notificationId) async {
    await _db.markNotificationAsRead(notificationId);
  }

  Future<void> _markAllAsRead() async {
    if (_currentUserId == null) return;
    await _db.markAllNotificationsAsRead(_currentUserId!);
  }

  Future<void> _seedDemoNotifications() async {
    if(_currentUserId == null) return;

    final user = _auth.currentUser!;
    final demoNotifications = [
      {
        'type': 'like',
        'title': 'Alex Chen liked your post',
        'body': 'Your post about campus events got a like!',
        'senderId': 'demo_user_1',
        'senderName': 'Alex Chen',
        'extraData': {'postId': 'demo_post_1'},
      },
      {
        'type': 'message',
        'title': 'New message from Study Group',
        'body': 'Meeting moved to 3 PM tomorrow in the library',
        'senderId': 'demo_group_1',
        'senderName': 'Study Group',
        'extraData': {'conversationId': 'demo_conv_1'},
      },
      {
        'type': 'announcement',
        'title': 'Campus Event: Career Fair Tomorrow',
        'body': 'Don\'t forget the annual career fair in the main hall',
        'senderId': 'campus_admin',
        'senderName': 'Campus Administration',
        'extraData': {'organizationId': 'campus_admin'},
      },
      {
        'type': 'marketplace',
        'title': 'Your textbook listing got interest',
        'body': 'Someone is interested in your "Calculus 101" textbook',
        'senderId': 'demo_user_3',
        'senderName': 'Sam Wilson',
        'extraData': {'itemId': 'demo_item_1'},
      },
    ];

    for (final notif in demoNotifications) {
      await _db.createNotification(
        userId: _currentUserId!,
        type: notif['type'] as String,
        title: notif['title'] as String,
        body: notif['body'] as String,
        senderId: notif['senderId'] as String,
        senderName: notif['senderName'] as String,
        extraData: notif['extraData'] as Map<String, dynamic>,
      );
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demo notifications'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clearAllNotifications() async {
    if (_currentUserId == null) return;
    
    try {
      // Get all notifications for the user
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: _currentUserId!)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Clear local state
      setState(() {
        _notifications = [];
        _unreadCount = 0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications cleared'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error clearing notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) async {
    final type = notification['type'] as String;
    final data = notification['data'] as Map<String, dynamic>;
    final isRead = notification['isRead'] as bool;
    final notificationId = notification['id'] as String;

    // Mark as read if unread
    if (!isRead) {
      await _markAsRead(notificationId);
      setState(() {
        notification['isNew'] = false;
        notification['isRead'] = true;
        _unreadCount--;
      });
    }

    // Navigate based on type
    switch (type) {
      case 'like':
      case 'comment':
        final postId = data['postId'] as String?;
        if (postId != null) {
          // TODO: Navigate to post detail
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening post: $postId')),
          );
        }
        break;
      case 'message':
        final conversationId = data['conversationId'] as String?;
        if (conversationId != null) {
          // TODO: Navigate to chat
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening conversation')),
          );
        }
        break;
      case 'announcement':
        final organizationId = data['organizationId'] as String?;
        if (organizationId != null) {
          // TODO: Navigate to organization
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening announcement')),
          );
        }
        break;
      case 'marketplace':
        final itemId = data['itemId'] as String?;
        if (itemId != null) {
          // TODO: Navigate to marketplace item
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening marketplace item')),
          );
        }
        break;
    }
  }

  void _handleNavTap(int index) {
    if (_navIndex == index) return;
    setState(() => _navIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/marketplace');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/wall');
        break;
      case 3:
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F2),
      bottomNavigationBar: CampusBottomNav(
        currentIndex: _navIndex,
        onItemTapped: _handleNavTap,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _notifications.isEmpty
                      ? _buildEmptyState()
                      : _buildNotificationList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF921126), Color(0xFFD4372A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Notifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Stay updated with campus life',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  if (_unreadCount > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _unreadCount > 9 ? '9+' : '$_unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildNotificationList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              if (_unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    '$_unreadCount new notification${_unreadCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Spacer(),
              if (_unreadCount > 0)
                TextButton(
                  onPressed: _markAllAsRead,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: const Color(0xFF8D0B15),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Mark all as read'),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            itemCount: _notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = _notifications[index];
              return _NotificationCard(
                notification: notification,
                onTap: () => _handleNotificationTap(notification),
                onDismiss: () => _markAsRead(notification['id'] as String),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: OutlinedButton.icon(
            onPressed: _seedDemoNotifications,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF8D0B15)),
              foregroundColor: const Color(0xFF8D0B15),
            ),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Add More Demos'),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading notifications...',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 60,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your notifications will appear here',
            style: TextStyle(
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final Color accentColor = notification['accent'] as Color;
    final IconData icon = notification['icon'] as IconData;
    final bool isNew = notification['isNew'] as bool;

    return Dismissible(
      key: Key(notification['id'] as String),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.check, color: Colors.white, size: 30),
      ),
      onDismissed: (_) => onDismiss(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: isNew
                  ? const Border(
                      left: BorderSide(color: Color(0xFFD7263D), width: 5),
                    )
                  : Border.all(color: const Color(0xFFF1E4DE)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  offset: Offset(0, 6),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NotificationAvatar(
                  accentColor: accentColor,
                  icon: icon,
                  isNew: isNew,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification['title'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF461919),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            notification['time'] as String,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification['body'] as String,
                        style: const TextStyle(
                          color: Color(0xFF6C4D4D),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getTypeLabel(notification['type'] as String),
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'like':
        return 'Like';
      case 'comment':
        return 'Comment';
      case 'message':
        return 'Message';
      case 'announcement':
        return 'Announcement';
      case 'marketplace':
        return 'Marketplace';
      default:
        return 'Notification';
    }
  }
}

class _NotificationAvatar extends StatelessWidget {
  const _NotificationAvatar({
    required this.accentColor,
    required this.icon,
    this.isNew = false,
  });

  final Color accentColor;
  final IconData icon;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        icon,
        color: accentColor,
        size: 26,
      ),
    );

    if (!isNew) {
      return avatar;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          top: -2,
          right: -2,
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFFD7263D),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

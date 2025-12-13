import 'package:flutter/material.dart';
import 'package:stateful_widget/widgets/campus_bottom_nav.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  int _navIndex = 3;

  static const List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Campus Emergency Alert',
      'body': 'Campus WiFi maintenance tonight 11PM-2AM. Save your work!',
      'time': '5m ago',
      'tag': 'Alert',
      'tagColor': Color(0xFFD7263D),
      'accent': Color(0xFFD7263D),
      'icon': Icons.warning_rounded,
      'isNew': true,
    },
    {
      'title': 'Computer Science Club',
      'body': 'Hackathon registration closes in 24 hours!',
      'time': '1h ago',
      'accent': Color(0xFF0EA3B4),
      'icon': Icons.groups_2_rounded,
      'isNew': true,
    },
    {
      'title': 'Sarah M. liked your post',
      'body': '"Looking for a study buddy for finals..."',
      'time': '2h ago',
      'tag': 'Profile',
      'tagColor': Color(0xFFD7263D),
      'accent': Color(0xFFE9A34E),
      'asset': 'assets/images/captain_america.jpg',
    },
    {
      'title': 'New comment on your post',
      'body': 'Alex: "I\'m interested! Let\'s connect."',
      'time': '3h ago',
      'tag': 'Profile',
      'tagColor': Color(0xFFD7263D),
      'accent': Color(0xFF4B74C6),
      'icon': Icons.chat_bubble_rounded,
    },
    {
      'title': 'Your item got a new offer',
      'body': 'Someone is interested in your Calculus textbook',
      'time': '5h ago',
      'tag': 'Profile',
      'tagColor': Color(0xFFD7263D),
      'accent': Color(0xFFD98E27),
      'icon': Icons.menu_book_rounded,
    },
    {
      'title': 'Student Council',
      'body': 'New poll: Should we extend library hours?',
      'time': '1d ago',
      'accent': Color(0xFF1B7FBF),
      'icon': Icons.campaign_rounded,
    },
  ];

  void _handleNavTap(int index, BuildContext context) {
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
        onItemTapped: (index) => _handleNavTap(index, context),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                children: [
                  _buildSummaryRow(),
                  const SizedBox(height: 10),
                  ...List.generate(_notifications.length, (index) {
                    final data = _notifications[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == _notifications.length - 1 ? 0 : 4,
                      ),
                      child: _NotificationCard(data: data),
                    );
                  }),
                ],
              ),
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
              const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 28,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Text(
            '3 new notifications',
            style: TextStyle(
              color: Color(0xFF666666),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () {},
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
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final Color accentColor = data['accent'] as Color? ?? const Color(0xFF8D0B15);
    final IconData? icon = data['icon'] as IconData?;
    final String? asset = data['asset'] as String?;
    final String? tag = data['tag'] as String?;
    final Color tagColor = data['tagColor'] as Color? ?? accentColor;
    final bool isNew = data['isNew'] as bool? ?? false;

    return Container(
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
            assetPath: asset,
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
                        data['title'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF461919),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      data['time'] as String,
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
                  data['body'] as String,
                  style: const TextStyle(
                    color: Color(0xFF6C4D4D),
                    height: 1.4,
                  ),
                ),
                if (tag != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: tagColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: tagColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationAvatar extends StatelessWidget {
  const _NotificationAvatar({
    required this.accentColor,
    this.icon,
    this.assetPath,
    this.isNew = false,
  });

  final Color accentColor;
  final IconData? icon;
  final String? assetPath;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    Widget avatar;
    
    if (assetPath != null && assetPath!.isNotEmpty) {
      avatar = CircleAvatar(
        radius: 26,
        backgroundColor: accentColor.withOpacity(0.15),
        backgroundImage: AssetImage(assetPath!),
      );
    } else {
      avatar = Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          icon ?? Icons.notifications,
          color: accentColor,
          size: 26,
        ),
      );
    }

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

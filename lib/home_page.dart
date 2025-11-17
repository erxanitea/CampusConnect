import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> _filters = const ['All', 'Orgs', 'Trending'];
  int _selectedFilter = 0;
  int _navIndex = 0;

  static const _recentMessages = [
    {
      'name': 'CS Club Group',
      'preview': "Don't forget the hackathon tomorrow!",
      'badge': 3,
      'color': Color(0xFFE0F2FF),
      'emoji': '💬',
    },
    {
      'name': 'Sarah M.',
      'preview': 'Is the textbook still available?',
      'badge': 1,
      'color': Color(0xFFFFE9E2),
      'emoji': '👩🏻',
    },
    {
      'name': 'Anonymous',
      'preview': 'Thanks for your advice!',
      'badge': 0,
      'color': Color(0xFFF5F5F5),
      'emoji': '❓',
    },
  ];

  static const _announcements = [
    {
      'title': 'Computer Science Club',
      'time': '2h ago',
      'body':
          '🎉 Hackathon 2025 Registration Open! Join us for 48 hours of coding, prizes, and networking. Register by Friday!',
      'pinned': true,
      'reactions': {'likes': 45, 'comments': 8, 'shares': 3},
    },
    {
      'title': 'Student Council',
      'time': '5h ago',
      'body':
          '📢 Campus WiFi maintenance scheduled for this weekend. Please save your work!',
      'pinned': false,
      'reactions': {'likes': 45, 'comments': 8, 'shares': 6},
    },
    {
      'title': 'Alex Chen',
      'time': '1d ago',
      'body': 'Just finished my final project! Feeling relieved 😅 #StudentLife',
      'pinned': false,
      'reactions': {'likes': 23, 'comments': 5, 'shares': 2},
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: _buildFloatingChatButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNavigation(theme),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            children: [
              _buildHeroHeader(context),
              _buildFilterChips(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildRecentMessagesCard(theme),
                    const SizedBox(height: 18),
                    ..._announcements
                        .map((post) => Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: _buildAnnouncementCard(post, theme),
                            ))
                        .toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C000F), Color(0xFFC63528)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'CampusConnect',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.white, width: 1),
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/');
                },
                icon: const Icon(Icons.logout, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Your campus community hub',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      transform: Matrix4.translationValues(0, -26, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_filters.length, (index) {
            final bool active = index == _selectedFilter;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFFEDD6D1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _filters[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: active
                          ? const Color(0xFF7C000F)
                          : Colors.grey[600],
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildRecentMessagesCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF9F5), Color(0xFFFFF0EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border(
          left: BorderSide(
            color: const Color(0xFFB01F1F),
            width: 5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline,
                      color: const Color(0xFF7C000F)),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Messages',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF7C000F),
                    ),
                  ),
                ],
              ),
              Text(
                'View All',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: const Color(0xFFBD2C1A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ..._recentMessages.map((message) {
            final bool hasBadge = message['badge'] as int > 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: message['color'] as Color,
                    child: Text(
                      message['emoji'] as String,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['name'] as String,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          message['preview'] as String,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasBadge)
                    _buildBadge(message['badge'] as int,
                        color: const Color(0xFFBD2C1A)),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> post, ThemeData theme) {
    final bool isPinned = post['pinned'] as bool;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isPinned ? const Color(0xFFCC3C2E) : const Color(0xFFEDE4E1),
          width: isPinned ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFE0F2FF),
                child: Text(
                  post['title']!.toString()[0],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D47A1),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            post['title'] as String,
                            style:
                                theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isPinned)
                          _buildChip('Pinned', Icons.push_pin, true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildChip('Official Org', Icons.verified, false),
                        const SizedBox(width: 8),
                        Text(
                          post['time'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            post['body'] as String,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF4E2A2A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(
            color: Color(0xFFEBD9D4),
            thickness: 0.8,
            height: 0,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _reactionItem(Icons.thumb_up_alt_outlined,
                  post['reactions']['likes'] as int),
              _reactionItem(Icons.chat_bubble_outline,
                  post['reactions']['comments'] as int),
              _reactionItem(Icons.share_outlined,
                  post['reactions']['shares'] as int),
              const Icon(Icons.thumb_up, color: Color(0xFF7C000F)),
              const Icon(Icons.emoji_emotions_outlined,
                  color: Color(0xFF7C000F)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reactionItem(IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFB54B3A), size: 20),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: const TextStyle(
            color: Color(0xFF5B0B0C),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, IconData icon, bool filled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? const Color(0xFF8D0B15) : const Color(0xFFF5E6E1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: filled ? Colors.white : const Color(0xFF8D0B15)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: filled ? Colors.white : const Color(0xFF8D0B15),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(int count, {Color color = const Color(0xFF8D0B15)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$count',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildFloatingChatButton() {
    return SizedBox(
      height: 68,
      width: 68,
      child: FloatingActionButton(
        heroTag: 'messagesFab',
        backgroundColor: const Color(0xFF8D0B15),
        foregroundColor: Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(34),
        ),
        onPressed: () {},
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 26),
            Positioned(
              top: -25,
              right: -20,
              child: _buildBadge(4, color: const Color(0xFFE53935)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(ThemeData theme) {
    const navIcons = [
      Icons.home_outlined,
      Icons.storefront_outlined,
      Icons.article_outlined,
      Icons.notifications_none_rounded,
      Icons.person_outline,
    ];

    const navActiveIcons = [
      Icons.home_rounded,
      Icons.storefront,
      Icons.article,
      Icons.notifications_active_outlined,
      Icons.person,
    ];

    const labels = ['Home', 'Market', 'Wall', 'Alerts', 'Profile'];

    return BottomNavigationBar(
      currentIndex: _navIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF8D0B15),
      unselectedItemColor: Colors.grey[500],
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      onTap: (index) => setState(() => _navIndex = index),
      items: List.generate(labels.length, (index) {
        final badge = index == 3 ? 2 : 0;
        final isActive = index == _navIndex;
        return BottomNavigationBarItem(
          icon: _buildNavIcon(
            navIcons[index],
            navActiveIcons[index],
            isActive,
            badgeCount: badge,
          ),
          label: labels[index],
        );
      }),
    );
  }

  Widget _buildNavIcon(
    IconData icon,
    IconData activeIcon,
    bool active, {
    int badgeCount = 0,
  }) {
    final iconWidget = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: EdgeInsets.symmetric(
        horizontal: active ? 14 : 10,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFFE7DF) : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(
        active ? activeIcon : icon,
        color: active ? const Color(0xFF8D0B15) : Colors.grey[500],
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        iconWidget,
        if (badgeCount > 0)
          Positioned(
            right: -6,
            top: -2,
            child: _buildBadge(badgeCount,
                color: const Color(0xFFBD2C1A)),
          ),
      ],
    );
  }
}

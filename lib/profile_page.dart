import 'package:flutter/material.dart';
import 'package:stateful_widget/widgets/campus_bottom_nav.dart';
import 'package:stateful_widget/widgets/floating_messages_button.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const _badgeLabels = ['Active Owl', 'CS Club', 'Student Council'];

  static const _achievementCards = [
    {
      'label': 'Active Owl',
      'emoji': '🦉',
      'color': Color(0xFFF5F1ED),
    },
    {
      'label': 'Market Pro',
      'emoji': '🛍️',
      'color': Color(0xFFF5F1ED),
    },
    {
      'label': 'Chatter',
      'emoji': '💬',
      'color': Color(0xFFF5F1ED),
    },
  ];

  static const _organizations = [
    {
      'name': 'Computer Science Club',
      'members': '45 members',
      'role': 'Admin',
      'accent': Color(0xFF0EA89B),
    },
    {
      'name': 'Student Council',
      'members': '23 members',
      'role': 'Member',
      'accent': Color(0xFF2B50AF),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingMessagesButton(
        badgeCount: 4,
        onPressed: () {},
        heroTag: 'profileMessagesFab',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: CampusBottomNav(
        currentIndex: 4,
        onItemTapped: (index) => _handleNavTap(context, index),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 30),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeroSection(theme),
                  const SizedBox(height: 35),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildUserInfoCard(theme),
                        const SizedBox(height: 20),
                        _buildCampusPointsCard(theme),
                        const SizedBox(height: 20),
                        _buildOrganizationsCard(theme),
                        const SizedBox(height: 20),
                        _buildSignOutButton(theme),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 5,
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 52,
                      backgroundColor: Color(0xFFFADBD2),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: Color(0xFFFADBD2),
                        child: Text(
                          'JD',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF7C0010),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _handleNavTap(BuildContext context, int index) {
    if (index == 4) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Widget _buildHeroSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C0010), Color(0xFFC53529)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(ThemeData theme) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'John Doe',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF4A1C1C),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.settings_outlined, size: 22, color: Color(0xFFB74D3A)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Computer Science • Class of 2025',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: _badgeLabels
                .map(
                  (label) => _buildChip(
                    label,
                    background: const Color(0xFFF6E8E2),
                    foreground: const Color(0xFF8D0B15),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFF0E3DF), height: 1),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _StatItem(label: 'Posts', value: '342'),
              _StatItem(label: 'Likes', value: '1.2k'),
              _StatItem(label: 'Items Sold', value: '89'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    String label, {
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCampusPointsCard(ThemeData theme) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_outlined, color: Color(0xFFB74D3A)),
              const SizedBox(width: 8),
              Text(
                'Campus Points',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF4A1C1C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Level 7',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF4A1C1C),
            ),
          ),
          const SizedBox(height: 8),
          _buildProgressBar(progress: 2847 / 3000),
          const SizedBox(height: 6),
          Text(
            '2,847 / 3,000 points',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFFB74D3A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '153 points to next level',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _achievementCards
                .asMap()
                .entries
                .map((entry) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: entry.key < _achievementCards.length - 1 ? 12 : 0,
                        ),
                        child: _AchievementPill(
                          label: entry.value['label'] as String,
                          emoji: entry.value['emoji'] as String,
                          color: entry.value['color'] as Color,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar({required double progress}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 12,
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: const Color(0xFFF5DAD3),
          valueColor: const AlwaysStoppedAnimation(Color(0xFFBD2B21)),
        ),
      ),
    );
  }

  Widget _buildOrganizationsCard(ThemeData theme) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_outlined, color: Color(0xFFB74D3A)),
              const SizedBox(width: 8),
              Text(
                'My Organizations',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF4A1C1C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ..._organizations
              .map(
                (org) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _OrganizationTile(
                    name: org['name'] as String,
                    members: org['members'] as String,
                    role: org['role'] as String,
                    accentColor: org['accent'] as Color,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: const Color(0xFFE84535),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 6,
          shadowColor: const Color(0xFFE84535).withValues(alpha: 0.3),
        ),
        onPressed: () {},
        icon: const Icon(Icons.logout),
        label: Text(
          'Sign Out',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFE8DDD8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Color(0xFF8D0B15),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _AchievementPill extends StatelessWidget {
  const _AchievementPill({
    required this.label,
    required this.emoji,
    required this.color,
  });

  final String label;
  final String emoji;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 36),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF4A1C1C),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrganizationTile extends StatelessWidget {
  const _OrganizationTile({
    required this.name,
    required this.members,
    required this.role,
    required this.accentColor,
  });

  final String name;
  final String members;
  final String role;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role.toLowerCase() == 'admin';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1E4DE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.category_rounded, color: accentColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4A1C1C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  members,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.end,
                children: [
                  _buildOrgBadge(role),
                  if (isAdmin)
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8D0B15),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Manage',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrgBadge(String role) {
    final isAdmin = role.toLowerCase() == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAdmin ? const Color(0xFFF0DDDC) : const Color(0xFFF0DDDC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:stateful_widget/widgets/campus_bottom_nav.dart';
import 'package:stateful_widget/widgets/floating_messages_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stateful_widget/services/auth/google_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stateful_widget/services/database/database_service.dart';
import 'package:stateful_widget/models/user_model.dart';
import 'package:stateful_widget/models/post_model.dart';
import 'package:stateful_widget/pages/organization_manage_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _navIndex = 3;

  void _handleNavTap(int index, BuildContext context) {
    setState(() {
      _navIndex = index;
    });

     switch (index) {
      case 0:
        if (ModalRoute.of(context)?.settings.name != '/home') {
          Navigator.pushReplacementNamed(context, '/home');
        }
        break;
      case 1:
        if (ModalRoute.of(context)?.settings.name != '/wall') {
          Navigator.pushReplacementNamed(context, '/wall');
        }
        break;
      case 2:
        if (ModalRoute.of(context)?.settings.name != '/marketplace') {
          Navigator.pushReplacementNamed(context, '/marketplace');
        }
        break;
      case 3:
        if (ModalRoute.of(context)?.settings.name != '/alerts') {
          Navigator.pushReplacementNamed(context, '/alerts');
        }
        break;
      case 4:
        if (ModalRoute.of(context)?.settings.name != '/profile') {
          Navigator.pushReplacementNamed(context, '/profile');
        }
        break;
    }
  }


  final List<String> _filters = const ['All', 'Orgs', 'Confessions'];
  int _selectedFilter = 0;
  final DatabaseService _databaseService = DatabaseService();

  List<Post> _confessions = [];
  List<Post> _allPosts = [];
  bool _isLoading = true;
  StreamSubscription<QuerySnapshot>? _postsSubscription;

  AppUser? _currentAppUser;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  static const _achievementCards = [
    {
      'label': 'Active Owl',
      'emoji': '🦉',
      'color': Color(0xFFF5F1ED),
      'points': 100,
    },
    {
      'label': 'Market Pro',
      'emoji': '🛍️',
      'color': Color(0xFFF5F1ED),
      'points': 50,
    },
    {
      'label': 'Chatter',
      'emoji': '💬',
      'color': Color(0xFFF5F1ED),
      'points': 25,
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
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final userDoc = await _databaseService.getUserProfile(user.uid);
      if (userDoc.exists) {
        if (mounted) {
          setState(() {
            _currentAppUser = AppUser.fromFirestore(userDoc);
            _isLoading = false;
          });
        }
      } else {
        await _databaseService.createUserProfile(user);
        final newUserDoc = await _databaseService.getUserProfile(user.uid);
        if (mounted) {
          setState(() {
            _currentAppUser = AppUser.fromFirestore(newUserDoc);
            _isLoading = false;
          });
        }
      }

      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && mounted) {
          setState(() {
            _currentAppUser = AppUser.fromFirestore(snapshot);
          });
        }
      });
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  String get _userInitials {
    if (_currentUser?.displayName != null && _currentUser!.displayName!.isNotEmpty) {
      final names = _currentUser!.displayName!
          .trim()
          .split(' ')
          .where((name) => name.isNotEmpty)
          .toList();

      if (names.isEmpty) return 'UN';

      try {
        if (names.length == 1) {
          return _getFirstValidCharacter(names[0]);
        } else {
          final firstInitial = _getFirstValidCharacter(names[0]);
          final lastInitial = _getFirstValidCharacter(names[names.length - 1]);
          return '$firstInitial$lastInitial';
        }
      } catch (e) {
        return 'UN';
      }
    }
    return 'UN';
  }

  String _getFirstValidCharacter(String name) {
    final normalizedName = _removeDiacritics(name);
    for (int i = 0; i < normalizedName.length; i++) {
      final char = normalizedName[i];
      if (RegExp(r'[A-Za-z]').hasMatch(char)) {
        return char.toUpperCase();
      }
    }
    return normalizedName.isNotEmpty ? normalizedName[0].toUpperCase() : '?';
  }

  String _removeDiacritics(String text) {
    return text
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('ü', 'u')
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Ñ', 'N')
        .replaceAll('Ü', 'U');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingMessagesButton(
        badgeCount: 4,
        onPressed: () {},
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: CampusBottomNav(
        currentIndex: _navIndex,
        onItemTapped: (index) => _handleNavTap(index, context),
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
                  if (_isLoading)
                    _buildLoadingState()
                  else
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
                          _buildSignOutButton(context),
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
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: const Color(0xFFFADBD2),
                      child: _currentUser?.photoURL != null
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: _currentUser!.photoURL!,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => _buildInitialsFallback(),
                                placeholder: (context, url) => _buildLoadingIndicator(),
                              ),
                            )
                          : _buildInitialsFallback(),
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

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 100),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Loading profile...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsFallback() {
    return CircleAvatar(
      radius: 48,
      backgroundColor: const Color(0xFFFADBD2),
      child: Text(
        _userInitials,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: Color(0xFF7C0010),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return CircleAvatar(
      radius: 48,
      backgroundColor: const Color(0xFFFADBD2),
      child: const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(Color(0xFF7C0010)),
      ),
    );
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
    final badges = _getUserBadges();

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _currentAppUser?.displayName ?? _currentUser?.displayName ?? 'User Name',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF4A1C1C),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings coming soon!')),
                  );
                },
                icon: const Icon(Icons.settings_outlined, size: 22, color: Color(0xFFB74D3A)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _currentAppUser?.email ?? _currentUser?.email ?? 'user@email.com',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          if (badges.isNotEmpty)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: badges
                  .map(
                    (label) => _buildChip(
                      label,
                      background: const Color(0xFFF6E8E2),
                      foreground: const Color(0xFF8D0B15),
                    ),
                  )
                  .toList(),
            )
          else
            Text(
              'No badges yet',
              style: TextStyle(
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFF0E3DF), height: 1),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(
                label: 'Posts',
                value: '${_currentAppUser?.totalPosts ?? 0}',
              ),
              _StatItem(
                label: 'Likes Received',
                value: '${_currentAppUser?.totalLikes ?? 0}',
              ),
              _StatItem(
                label: 'Campus Points',
                value: '${_currentAppUser?.campusPoints ?? 0}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _getUserBadges() {
    final badges = <String>[];
    if (_currentAppUser == null) return badges;

    if (_currentAppUser!.campusPoints >= 100) badges.add('Active Owl');
    if (_currentAppUser!.totalPosts >= 10) badges.add('Market Pro');
    if (_currentAppUser!.totalLikes >= 50) badges.add('Popular');
    if (_currentAppUser!.campusPoints > 0) badges.add('Member');

    return badges;
  }

  Widget _buildChip(String label, {required Color background, required Color foreground}) {
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
    final userPoints = _currentAppUser?.campusPoints ?? 0;
    final progress = userPoints / 3000;
    final nextLevelPoints = 3000 - userPoints;

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
            _getUserLevel(userPoints),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF4A1C1C),
            ),
          ),
          const SizedBox(height: 8),
          _buildProgressBar(progress: progress.clamp(0.0, 1.0)),
          const SizedBox(height: 6),
          Text(
            '$userPoints / 3,000 points',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFFB74D3A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            nextLevelPoints > 0
                ? '$nextLevelPoints points to next level'
                : 'Max level reached!',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 22),
          Row(
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
                          unlocked: _hasUnlockedAchievement(entry.value['points'] as int),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  String _getUserLevel(int points) {
    if (points < 100) return 'Level 1 - Newcomer';
    if (points < 300) return 'Level 2 - Explorer';
    if (points < 600) return 'Level 3 - Contributor';
    if (points < 1000) return 'Level 4 - Influencer';
    if (points < 1500) return 'Level 5 - Leader';
    if (points < 2100) return 'Level 6 - Champion';
    if (points < 2800) return 'Level 7 - Legend';
    return 'Level 8 - Campus Icon';
  }

  bool _hasUnlockedAchievement(int requiredPoints) {
    return (_currentAppUser?.campusPoints ?? 0) >= requiredPoints;
  }

  Widget _buildProgressBar({required double progress}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 12,
        child: LinearProgressIndicator(
          value: progress,
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
          if (_organizations.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Not a member of any organizations yet',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
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
                )
                .toList(),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    final theme = Theme.of(context);
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
          shadowColor: const Color(0xFFE84535).withOpacity(0.3),
        ),
        onPressed: () async {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          );

          try {
            await GoogleAuth().signOut();

            if (context.mounted) {
              Navigator.of(context).pop();
            }

            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              );
            }
          } catch (e) {
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sign out failed: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
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
            color: Colors.black.withOpacity(0.05),
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
    required this.unlocked,
  });

  final String label;
  final String emoji;
  final Color color;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: unlocked ? color : color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: unlocked ? const Color(0xFFE8DDD8) : Colors.grey[300]!,
        ),
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
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: unlocked ? const Color(0xFF4A1C1C) : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 4),
          if (!unlocked)
            Text(
              'Locked',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
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
              color: accentColor.withOpacity(0.15),
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrganizationManagePage(
                                organizationName: name,
                              ),
                            ),
                          );
                        },
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
        color: const Color(0xFFF0DDDC),
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

import 'package:flutter/material.dart';
import 'package:stateful_widget/admin/admin_analytics.dart';
import 'package:stateful_widget/admin/admin_reports.dart';
import 'package:stateful_widget/admin/admin_organizations.dart';
import 'package:stateful_widget/widgets/admin_bottom_nav.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _navIndex = 0;

  static const _dashboardStats = [
    {
      'title': 'Total Users',
      'value': '520',
      'subtitle': '+12% from last month',
      'icon': Icons.people_outlined,
      'color': Color(0xFFFFE9E2),
      'iconColor': Color(0xFF8D0B15),
    },
    {
      'title': 'Organizations',
      'value': '38',
      'subtitle': '+3 new this month',
      'icon': Icons.apartment_outlined,
      'color': Color(0xFFFFE9E2),
      'iconColor': Color(0xFF8D0B15),
    },
    {
      'title': 'Marketplace',
      'value': '156',
      'subtitle': '+24 active listings',
      'icon': Icons.shopping_bag_outlined,
      'color': Color(0xFFFFE9E2),
      'iconColor': Color(0xFF8D0B15),
    },
    {
      'title': 'Reports',
      'value': '8',
      'subtitle': 'Requires attention',
      'icon': Icons.warning_outlined,
      'color': Color(0xFFFFE9E2),
      'iconColor': Color(0xFF8D0B15),
    },
  ];

  static const _quickActions = [
    {
      'title': 'Review Pending Reports',
      'icon': Icons.assignment_outlined,
    },
    {
      'title': 'View Analytics',
      'icon': Icons.bar_chart_outlined,
    },
    {
      'title': 'Manage Organizations',
      'icon': Icons.apartment_outlined,
    },
  ];


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: _buildBottomNav(),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 30),
            child: Column(
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      ..._dashboardStats.map((stat) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildStatCard(stat, theme),
                        );
                      }),
                      const SizedBox(height: 24),
                      _buildQuickActionsSection(theme),
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


  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C000F), Color(0xFFC63528)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Admin Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'CampusConnect Overview',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              // Handle logout
            },
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat['title'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  stat['value'] as String,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  stat['subtitle'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: stat['color'] as Color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              stat['icon'] as IconData,
              color: stat['iconColor'] as Color,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        ..._quickActions.map((action) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildActionButton(action),
          );
        }),
      ],
    );
  }

  Widget _buildActionButton(Map<String, dynamic> action) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F1ED),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              action['icon'] as IconData,
              color: const Color(0xFF8D0B15),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            action['title'] as String,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey[400],
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return AdminBottomNav(
      currentIndex: _navIndex,
      onItemTapped: (index) {
        setState(() {
          _navIndex = index;
        });
        _handleNavTap(index);
      },
    );
  }

  void _handleNavTap(int index) {
    switch (index) {
      case 0:
        // Dashboard - already on it
        break;
      case 1:
        // Analytics
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminAnalytics()),
        ).then((result) {
          // Reset nav index when returning from Analytics
          setState(() {
            _navIndex = 0;
          });
        });
        break;
      case 2:
        // Reports
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminReports()),
        ).then((result) {
          // Reset nav index when returning from Reports
          setState(() {
            _navIndex = 0;
          });
        });
        break;
      case 3:
        // Organizations
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminOrganizations()),
        ).then((result) {
          // Reset nav index when returning from Organizations
          setState(() {
            _navIndex = 0;
          });
        });
        break;
    }
  }
}

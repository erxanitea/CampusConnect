import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stateful_widget/widgets/campus_bottom_nav.dart';
import 'package:stateful_widget/models/organization_model.dart';
import 'tabs/organization_members_tab.dart';
import 'tabs/organization_posts_tab.dart';
import 'tabs/organization_marketplace_tab.dart';
import 'tabs/organization_messages_tab.dart';

class OrganizationManagePage extends StatefulWidget {
  final String organizationName;
  final String organizationId;

  const OrganizationManagePage({
    super.key,
    required this.organizationName,
    required this.organizationId,
  });

  @override
  State<OrganizationManagePage> createState() => _OrganizationManagePageState();
}

class _OrganizationManagePageState extends State<OrganizationManagePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _navIndex = 3;
  Organization? _organization;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('DEBUG: OrganizationManagePage initState - organizationId: "${widget.organizationId}", organizationName: "${widget.organizationName}"');
    _tabController = TabController(length: 4, vsync: this);
    _loadOrganizationData();
  }

  Future<void> _loadOrganizationData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(widget.organizationId)
          .get();
      
      if (doc.exists) {
        setState(() {
          _organization = Organization.fromSnapshot(doc);
          _isLoading = false;
        });
      } else {
        print('Organization document not found: ${widget.organizationId}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading organization data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: CampusBottomNav(
        currentIndex: _navIndex,
        onItemTapped: (index) => _handleNavTap(index, context),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        OrganizationMembersTab(
                          organizationName: widget.organizationName,
                          organizationId: widget.organizationId,
                        ),
                        OrganizationPostsTab(
                          organizationName: widget.organizationName,
                          organizationId: widget.organizationId,
                        ),
                        _organization != null
                            ? OrganizationMarketplaceTab(organization: _organization!)
                            : _buildErrorTab('Organization data not available'),
                        OrganizationMessagesTab(organizationName: widget.organizationName),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorTab(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C000F), Color(0xFFC53529)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.category_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.organizationName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Manage Organization',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF6F1ED),
          borderRadius: BorderRadius.circular(28),
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4A1C1C),
          unselectedLabelColor: const Color(0xFF9B7A73),
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          tabs: [
            const Tab(text: 'Members'),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.campaign_outlined, size: 16),
                  SizedBox(width: 3),
                  Text('Posts'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.shopping_bag_outlined, size: 16),
                  SizedBox(width: 3),
                  Text('Market'),
                ],
              ),
            ),
            const Tab(text: 'Message'),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class CampusBottomNav extends StatelessWidget {
  const CampusBottomNav({
    super.key,
    required this.currentIndex,
    required this.onItemTapped,
  });

  final int currentIndex;
  final ValueChanged<int> onItemTapped;

  static const _navIcons = [
    Icons.home_outlined,
    Icons.storefront_outlined,
    Icons.article_outlined,
    Icons.notifications_none_rounded,
    Icons.person_outline,
  ];

  static const _navActiveIcons = [
    Icons.home_rounded,
    Icons.storefront,
    Icons.article,
    Icons.notifications_active_outlined,
    Icons.person,
  ];

  static const _labels = ['Home', 'Market', 'Wall', 'Alerts', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 1,
          color: Colors.grey[200],
        ),
        BottomNavigationBar(
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF8D0B15),
          unselectedItemColor: Colors.grey[500],
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          onTap: onItemTapped,
          items: List.generate(_labels.length, (index) {
            final badge = index == 3 ? 2 : 0;
            final isActive = index == currentIndex;
            return BottomNavigationBarItem(
              icon: _NavIcon(
                icon: _navIcons[index],
                activeIcon: _navActiveIcons[index],
                active: isActive,
                badgeCount: badge,
              ),
              label: _labels[index],
            );
          }),
        ),
      ],
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.activeIcon,
    required this.active,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final bool active;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          active ? activeIcon : icon,
          color: active ? const Color(0xFF8D0B15) : Colors.grey[500],
          size: 24,
        ),
        if (badgeCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: _Badge(count: badgeCount),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: Color(0xFFBD2C1A),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

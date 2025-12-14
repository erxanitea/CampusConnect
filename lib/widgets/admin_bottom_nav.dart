import 'package:flutter/material.dart';

class AdminBottomNav extends StatelessWidget {
  const AdminBottomNav({
    super.key,
    required this.currentIndex,
    required this.onItemTapped,
  });

  final int currentIndex;
  final ValueChanged<int> onItemTapped;

  static const _navIcons = [
    Icons.dashboard_outlined,
    Icons.bar_chart_outlined,
    Icons.assignment_outlined,
    Icons.apartment_outlined,
  ];

  static const _navActiveIcons = [
    Icons.dashboard,
    Icons.bar_chart,
    Icons.assignment,
    Icons.apartment,
  ];

  static const _labels = ['Dashboard', 'Analytics', 'Reports', 'Organizations'];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF8D0B15),
      unselectedItemColor: Colors.grey[500],
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      onTap: onItemTapped,
      items: List.generate(_labels.length, (index) {
        final isActive = index == currentIndex;
        return BottomNavigationBarItem(
          icon: Icon(isActive ? _navActiveIcons[index] : _navIcons[index]),
          label: _labels[index],
        );
      }),
    );
  }
}

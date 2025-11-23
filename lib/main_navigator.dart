import 'package:flutter/material.dart';
import 'package:stateful_widget/home_page.dart';
import 'package:stateful_widget/marketplace_page.dart';
import 'package:stateful_widget/profile_page.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _currentIndex,
      children: [
        _buildPage(0, const HomePage()),
        _buildPage(1, const MarketplacePage()),
        _buildPage(2, Container()),
        _buildPage(3, Container()),
        _buildPage(4, const ProfilePage()),
      ],
    );
  }

  Widget _buildPage(int index, Widget page) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: page,
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_tab.dart';
import 'search_tab.dart';
import 'cart_screen.dart';
import 'profile_tab.dart';
import '../../core/theme/app_colors.dart';

class UserMainScreen extends StatefulWidget {
  final int initialTabIndex;
  final bool restorePersistedTab;

  const UserMainScreen({
    super.key,
    this.initialTabIndex = 0,
    this.restorePersistedTab = true,
  });

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  static const String _tabIndexKey = 'user_main_selected_tab';
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex.clamp(0, 3);
    _screens = [
      const HomeTab(),
      const SearchTab(),
      CartScreen(onStartShopping: () => _onItemTapped(0)),
      const ProfileTab(),
    ];
    if (widget.restorePersistedTab) {
      unawaited(_restoreTabIndex());
    }
  }

  Future<void> _restoreTabIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_tabIndexKey) ?? 0;
    final normalized = saved.clamp(0, _screens.length - 1);
    if (!mounted) return;
    setState(() => _selectedIndex = normalized);
  }

  Future<void> _persistTabIndex(int index) async {
    if (!widget.restorePersistedTab) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tabIndexKey, index);
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
    unawaited(_persistTabIndex(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomAppBarTheme.color ??
              Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            animationDuration: const Duration(milliseconds: 220),
            height: 66,
            labelBehavior:
                NavigationDestinationLabelBehavior.onlyShowSelected,
            indicatorColor: AppColors.electricPurple.withValues(alpha: 0.18),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.shopping_cart_outlined),
                selectedIcon: Icon(Icons.shopping_cart),
                label: 'Cart',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

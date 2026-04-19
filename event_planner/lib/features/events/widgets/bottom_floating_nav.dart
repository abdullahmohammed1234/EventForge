import 'package:flutter/material.dart';

/// Bottom floating navigation bar with rounded container
class BottomFloatingNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final Color? accentColor;
  final bool isFavorited;

  const BottomFloatingNav({
    super.key,
    required this.currentIndex,
    this.onTap,
    this.accentColor,
    this.isFavorited = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60, // Fixed height for compact nav
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              index: 0,
              label: 'Home',
            ),
            _buildNavItem(
              icon: Icons.search_outlined,
              activeIcon: Icons.search,
              index: 1,
              label: 'Search',
            ),
            _buildNavItem(
              icon: Icons.add_circle_outline,
              activeIcon: Icons.add_circle,
              index: 2,
              label: 'Create',
            ),
            _buildNavItem(
              icon: isFavorited ? Icons.favorite : Icons.favorite_outline,
              activeIcon: Icons.favorite,
              index: 3,
              label: 'Saved',
              isFavorite: true,
            ),
            _buildNavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              index: 4,
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required int index,
    required String label,
    bool isFavorite = false,
  }) {
    final isActive = currentIndex == index;
    final Color iconColor;

    if (isFavorite && isFavorited && accentColor != null) {
      iconColor = accentColor!;
    } else {
      iconColor = isActive
          ? (accentColor ?? Colors.white)
          : Colors.white.withOpacity(0.6);
    }

    return GestureDetector(
      onTap: () => onTap?.call(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: iconColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

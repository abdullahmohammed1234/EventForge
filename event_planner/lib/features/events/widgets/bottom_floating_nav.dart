import 'package:flutter/material.dart';
import 'dart:ui';

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
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
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

            // CENTER CREATE BUTTON
            InkWell(
              onTap: () => onTap?.call(2),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accentColor ?? const Color(0xFFFF6BBA),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (accentColor ?? const Color(0xFFFF6BBA))
                          .withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),

            _buildNavItem(
              icon: isFavorited ? Icons.bookmark : Icons.bookmark_border,
              activeIcon: Icons.bookmark,
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
      iconColor =
          isActive ? (accentColor ?? const Color(0xFFFF6BBA)) : Colors.grey;
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
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: iconColor,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
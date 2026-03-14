import 'package:flutter/material.dart';

/// A custom header widget for the Discover page.
///
/// Replaces the traditional AppBar with a modern navigation row.
/// Contains:
/// - Left: Location selector ("Near Me ▼")
/// - Center: "Discover Events" (navigates to Discover page)
/// - Right: "Your Groups" (navigates to Groups page)
class DiscoverHeader extends StatelessWidget {
  /// Callback when "Near Me" is tapped - opens location selector
  final VoidCallback? onLocationTap;

  /// Callback when "Discover Events" is tapped
  final VoidCallback? onDiscoverEventsTap;

  /// Callback when "Your Groups" is tapped
  final VoidCallback? onYourGroupsTap;

  /// Current selected index: 0 = Discover Events, 1 = Your Groups
  final int selectedIndex;

  const DiscoverHeader({
    super.key,
    this.onLocationTap,
    this.onDiscoverEventsTap,
    this.onYourGroupsTap,
    this.selectedIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTopNavigationRow(context),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
          ],
        ),
      ),
    );
  }

  /// Builds the main navigation row with three sections
  Widget _buildTopNavigationRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Location selector
          Expanded(
            child: _buildLocationSelector(context),
          ),
          // Center: Discover Events
          Expanded(
            flex: 2,
            child: _buildDiscoverEvents(context),
          ),
          // Right: Your Groups
          Expanded(
            child: _buildYourGroups(context),
          ),
        ],
      ),
    );
  }

  /// Left element - Location selector
  Widget _buildLocationSelector(BuildContext context) {
    return GestureDetector(
      onTap: onLocationTap ??
          () {
            // Placeholder callback - opens future location selector
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location selector coming soon!'),
                duration: Duration(seconds: 1),
              ),
            );
          },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Near Me',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: Colors.grey[800],
          ),
        ],
      ),
    );
  }

  /// Center element - Discover Events
  Widget _buildDiscoverEvents(BuildContext context) {
    final isSelected = selectedIndex == 0;
    return GestureDetector(
      onTap: onDiscoverEventsTap,
      child: Text(
        'Discover Events',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.black : Colors.grey[500],
        ),
      ),
    );
  }

  /// Right element - Your Groups
  Widget _buildYourGroups(BuildContext context) {
    final isSelected = selectedIndex == 1;
    return GestureDetector(
      onTap: onYourGroupsTap,
      child: Text(
        'Your Groups',
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.black : Colors.grey[800],
        ),
      ),
    );
  }
}

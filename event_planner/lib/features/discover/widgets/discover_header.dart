import 'package:flutter/material.dart';

/// A custom header widget for the Discover page.
///
/// Replaces the traditional AppBar with a modern navigation row.
/// Contains:
/// - Left: Location selector ("Near Me ▼")
/// - Center: "Discover Events" (navigates to Discover page)
/// - Right: "Your Groups" (navigates to Groups page)
class DiscoverHeader extends StatelessWidget {
  final String? title;

  /// Callback when "Near Me" is tapped - opens location selector
  final VoidCallback? onLocationTap;

  /// Callback when "Discover Events" is tapped
  final VoidCallback? onDiscoverEventsTap;

  /// Callback when "Your Groups" is tapped
  final VoidCallback? onYourGroupsTap;

  /// Callback when "Hidden Gems" is tapped
  final VoidCallback? onHiddenGemsTap;

  /// Callback when "Underground" is tapped
  final VoidCallback? onUndergroundTap;

  /// Current selected index: 0 = Discover, 1 = Your Groups, 2 = Hidden Gems, 3 = Underground
  final int selectedIndex;

  const DiscoverHeader(
      {super.key,
      this.onLocationTap,
      this.onDiscoverEventsTap,
      this.onYourGroupsTap,
      this.onHiddenGemsTap,
      this.onUndergroundTap,
      this.selectedIndex = 0,
      this.title});

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
            _buildDiscoveryTabs(context),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveryTabs(BuildContext context) {
    // Only show Discover tab - removed Hidden Gems and Underground tabs
    return const SizedBox.shrink();
  }

  Widget _buildTabChip(BuildContext context, String label, bool isSelected,
      VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
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
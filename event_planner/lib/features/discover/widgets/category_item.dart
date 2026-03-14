import 'package:flutter/material.dart';

/// A reusable category item widget for the Discover page.
///
/// Used to display category pills/chips for filtering events.
class CategoryItem extends StatelessWidget {
  /// The label text to display
  final String label;

  /// Whether this category is currently selected
  final bool isSelected;

  /// Callback when the category is tapped
  final VoidCallback? onTap;

  /// Optional icon to display alongside the label
  final IconData? icon;

  const CategoryItem({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A horizontal scrollable list of category items.
class CategoryList extends StatelessWidget {
  /// List of category data to display
  final List<CategoryData> categories;

  /// Index of the currently selected category
  final int selectedIndex;

  /// Callback when a category is selected
  final ValueChanged<int>? onCategorySelected;

  const CategoryList({
    super.key,
    required this.categories,
    this.selectedIndex = 0,
    this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          return CategoryItem(
            label: category.label,
            icon: category.icon,
            isSelected: index == selectedIndex,
            onTap: () => onCategorySelected?.call(index),
          );
        },
      ),
    );
  }
}

/// Data class for category information
class CategoryData {
  /// The label text
  final String label;

  /// Optional icon
  final IconData? icon;

  const CategoryData({
    required this.label,
    this.icon,
  });
}

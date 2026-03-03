import 'package:flutter/material.dart';

/// Category pill widget that displays the event category
/// with dynamic background color based on extracted palette
class CategoryPill extends StatelessWidget {
  final String category;
  final Color backgroundColor;
  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;

  const CategoryPill({
    super.key,
    required this.category,
    required this.backgroundColor,
    this.horizontalPadding = 16,
    this.verticalPadding = 6,
    this.borderRadius = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        category.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

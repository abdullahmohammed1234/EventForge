import 'package:flutter/material.dart';

/// Overlapping avatars widget for displaying event attendees
/// Uses negative horizontal offsets to create overlapping effect
class OverlappingAvatars extends StatelessWidget {
  final List<String> avatarUrls;
  final int maxVisible;
  final int totalCount;
  final double avatarSize;
  final double overlapOffset;
  final Color? borderColor;

  const OverlappingAvatars({
    super.key,
    required this.avatarUrls,
    this.maxVisible = 4,
    this.totalCount = 0,
    this.avatarSize = 32,
    this.overlapOffset = 18,
    this.borderColor,
  });

  double _calculateTotalWidth() {
    // If no avatar URLs but we have attendees, we show placeholders
    final visibleCount = avatarUrls.isEmpty && totalCount > 0 
        ? totalCount.clamp(0, maxVisible) 
        : avatarUrls.length.clamp(0, maxVisible);
    final totalAvatars = visibleCount + (totalCount > maxVisible ? 1 : 0);
    if (totalAvatars == 0) return avatarSize;
    return (totalAvatars - 1) * overlapOffset + avatarSize;
  }

  @override
  Widget build(BuildContext context) {
    final visibleAvatars = avatarUrls.take(maxVisible).toList();
    final remainingCount = totalCount > maxVisible ? totalCount - maxVisible : 0;

    // If no avatar URLs but we have attendees, show placeholder avatars
    final showPlaceholders = visibleAvatars.isEmpty && totalCount > 0;

    return SizedBox(
      height: avatarSize,
      width: _calculateTotalWidth(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (showPlaceholders)
            // Show placeholder circles when no real avatars available
            ...List.generate(totalCount.clamp(0, maxVisible), (index) {
              return Positioned(
                left: index * overlapOffset,
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: borderColor ?? Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _buildPlaceholder(),
                  ),
                ),
              );
            }).toList()
          else
            ...visibleAvatars.asMap().entries.map((entry) {
            final index = entry.key;
            final url = entry.value;
            
            return Positioned(
              left: index * overlapOffset,
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor ?? Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _buildAvatarImage(url),
                ),
              ),
            );
          }).toList(),
          
          // Render "+N" indicator if there are remaining
          if (remainingCount > 0)
            Positioned(
              left: visibleAvatars.length * overlapOffset,
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: borderColor ?? Colors.white,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '+$remainingCount',
                    style: TextStyle(
                      color: borderColor != null 
                          ? _getContrastColor(borderColor!)
                          : Colors.grey[700],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage(String url) {
    // Check if it's a valid URL or base64 image
    if (url.startsWith('data:image') || url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder();
        },
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: avatarSize * 0.6,
        color: Colors.grey[600],
      ),
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

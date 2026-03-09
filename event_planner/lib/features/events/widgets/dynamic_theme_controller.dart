import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

/// Dynamic theme controller that extracts colors from event images
class DynamicThemeController extends ChangeNotifier {
  Color _dominantColor = const Color(0xFF6366F1); // Default accent
  Color _mutedColor = const Color(0xFF818CF8);
  Color _darkVibrantColor = const Color(0xFF4F46E5);
  Color _lightVibrantColor = const Color(0xFFA5B4FC);
  bool _isLoading = true;
  bool _hasError = false;
  PaletteGenerator? _paletteGenerator;

  // Getters
  Color get dominantColor => _dominantColor;
  Color get mutedColor => _mutedColor;
  Color get darkVibrantColor => _darkVibrantColor;
  Color get lightVibrantColor => _lightVibrantColor;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  PaletteGenerator? get paletteGenerator => _paletteGenerator;

  /// Default fallback color
  static const Color defaultAccent = Color(0xFF6366F1);

  /// Extract colors from image provider
  Future<void> extractColorsFromImage(ImageProvider imageProvider) async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      _paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 20,
        timeout: const Duration(seconds: 10),
      );

      // Extract dominant color (with fallback)
      _dominantColor = _paletteGenerator?.dominantColor?.color ?? defaultAccent;

      // Extract muted color (with fallback)
      _mutedColor = _paletteGenerator?.mutedColor?.color ??
          Color.lerp(_dominantColor, Colors.white, 0.5) ??
          defaultAccent;

      // Extract dark vibrant color (with fallback)
      _darkVibrantColor = _paletteGenerator?.darkVibrantColor?.color ??
          Color.lerp(_dominantColor, Colors.black, 0.3) ??
          defaultAccent;

      // Extract light vibrant color (with fallback)
      _lightVibrantColor = _paletteGenerator?.lightVibrantColor?.color ??
          Color.lerp(_dominantColor, Colors.white, 0.3) ??
          defaultAccent;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _hasError = true;
      _isLoading = false;
      // Use defaults on error
      _dominantColor = defaultAccent;
      _mutedColor = const Color(0xFF818CF8);
      _darkVibrantColor = const Color(0xFF4F46E5);
      _lightVibrantColor = const Color(0xFFA5B4FC);
      notifyListeners();
    }
  }

  /// Get tinted surface color for bottom sheet
  Color getTintedSurfaceColor() {
    return Color.lerp(_dominantColor, Colors.white, 0.85) ?? Colors.white;
  }

  /// Get soft shadow color with low opacity
  Color getShadowColor() {
    return _dominantColor.withOpacity(0.15);
  }

  /// Get accent color for CTA button
  Color get accentColor => _dominantColor;

  /// Get active icon highlight color
  Color get activeIconColor => _dominantColor;

  /// Reset to default colors
  void reset() {
    _dominantColor = defaultAccent;
    _mutedColor = const Color(0xFF818CF8);
    _darkVibrantColor = const Color(0xFF4F46E5);
    _lightVibrantColor = const Color(0xFFA5B4FC);
    _isLoading = true;
    _hasError = false;
    _paletteGenerator = null;
    notifyListeners();
  }

  /// Extract colors from a gradient color (category-based)
  void extractColorsFromGradient(Color baseColor) {
    _dominantColor = baseColor;
    _mutedColor = Color.lerp(baseColor, Colors.white, 0.5) ?? baseColor;
    _darkVibrantColor = Color.lerp(baseColor, Colors.black, 0.3) ?? baseColor;
    _lightVibrantColor = Color.lerp(baseColor, Colors.white, 0.3) ?? baseColor;
    _isLoading = false;
    _hasError = false;
    notifyListeners();
  }
}

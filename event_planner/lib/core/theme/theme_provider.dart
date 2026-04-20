import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.light;
  double _textScaleFactor = 1.0;
  bool _highContrast = false;

  ThemeMode get themeMode => _themeMode;
  double get textScaleFactor => _textScaleFactor;
  bool get highContrast => _highContrast;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey) ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _textScaleFactor = prefs.getDouble('text_scale_factor') ?? 1.0;
    _highContrast = prefs.getBool('high_contrast') ?? false;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, mode == ThemeMode.dark);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _themeMode == ThemeMode.dark);
    notifyListeners();
  }

  Future<void> setTextScaleFactor(double factor) async {
    _textScaleFactor = factor.clamp(0.8, 2.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('text_scale_factor', _textScaleFactor);
    notifyListeners();
  }

  Future<void> setHighContrast(bool enabled) async {
    _highContrast = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('high_contrast', enabled);
    notifyListeners();
  }

  ThemeData get lightTheme {
    return _buildTheme(Brightness.light);
  }

  ThemeData get darkTheme {
    return _buildTheme(Brightness.dark);
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final primaryColor =
        isDark ? const Color(0xFF6C63FF) : const Color(0xFF2196F3);
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.white;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final errorColor =
        isDark ? const Color(0xFFCF6679) : const Color(0xFFB00020);

    final textTheme = _buildTextTheme(brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primaryColor,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: isDark ? const Color(0xFFBB86FC) : const Color(0xFF03DAC6),
        onSecondary: isDark ? Colors.black : Colors.white,
        error: errorColor,
        onError: Colors.white,
        surface: surfaceColor,
        onSurface: isDark ? Colors.white : Colors.black87,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: isDark ? 2 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _highContrast
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? const Color(0xFF3C3C3C) : Colors.grey[300]!),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: isDark ? Colors.grey[400] : Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200]!,
        selectedColor: primaryColor.withOpacity(0.2),
        labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black87),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF3C3C3C) : Colors.grey[300],
        thickness: 1,
      ),
      textTheme: textTheme.apply(
        bodyColor: isDark ? Colors.white : Colors.black87,
        displayColor: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  TextTheme _buildTextTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final baseTextTheme = isDark
        ? Typography.material2021().white
        : Typography.material2021().black;

    return baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontSize: 32 * _textScaleFactor,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontSize: 28 * _textScaleFactor,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontSize: 24 * _textScaleFactor,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontSize: 22 * _textScaleFactor,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontSize: 20 * _textScaleFactor,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontSize: 18 * _textScaleFactor,
        fontWeight: FontWeight.w500,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: 18 * _textScaleFactor,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: 16 * _textScaleFactor,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontSize: 14 * _textScaleFactor,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: 16 * _textScaleFactor,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 14 * _textScaleFactor,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: 12 * _textScaleFactor,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 14 * _textScaleFactor,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 12 * _textScaleFactor,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontSize: 10 * _textScaleFactor,
      ),
    );
  }
}

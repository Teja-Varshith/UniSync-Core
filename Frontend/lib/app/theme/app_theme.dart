import 'package:flutter/material.dart';

class AppTheme {
  // ==================== COLOR PALETTE ====================
  
  // Primary Colors
  static const Color primaryPurple = Color(0xFF6C5CE7);
  static const Color primaryBlack = Color(0xFF0F0F0F);
  static const Color cardDark = Color(0xFF222222);
  static const Color cardDarker = Color(0xFF1A1A1A);
  
  // Neutral Colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);
  
  // Text Colors
  static const Color textLight = Color(0xFFB3B3B3);
  static const Color textDark = Color(0xFF2C2C2C);
  
  // ==================== LIGHT THEME ====================
  
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Poppins',
    
    scaffoldBackgroundColor: white,
    
    colorScheme: const ColorScheme.light(
      primary: primaryPurple,
      secondary: primaryPurple,
      surface: white,
      error: Colors.red,
      onPrimary: white,
      onSecondary: white,
      onSurface: textDark,
      onError: white,
    ),
    
    cardColor: white,
    
    appBarTheme: const AppBarTheme(
      backgroundColor: white,
      foregroundColor: textDark,
      elevation: 0,
      centerTitle: true,
    ),
    
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: textDark),
      displayMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.w600, color: textDark),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: textDark),
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textDark),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: textDark),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: textDark),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textDark),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textDark),
      titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textDark),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: textDark),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: textDark),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w300, color: grey700),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textDark),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: grey600),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: black,
        foregroundColor: white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: black,
        side: const BorderSide(color: black, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: grey100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
    ),
    
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: white,
      selectedItemColor: primaryPurple,
      unselectedItemColor: grey400,
      type: BottomNavigationBarType.fixed,
    ),
  );
  
  // ==================== DARK THEME ====================
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Poppins',
    
    scaffoldBackgroundColor: primaryBlack,
    
    colorScheme: const ColorScheme.dark(
      primary: primaryPurple,
      secondary: primaryPurple,
      surface: cardDark,
      error: Colors.red,
      onPrimary: white,
      onSecondary: white,
      onSurface: white,
      onError: white,
    ),
    
    cardColor: cardDark,
    
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryBlack,
      foregroundColor: white,
      elevation: 0,
      centerTitle: true,
    ),
    
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: white),
      displayMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.w600, color: white),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: white),
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: white),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: white),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: white),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: white),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: white),
      titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: white),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: white),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: white),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w300, color: textLight),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: white),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: white),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: textLight),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: black,
        foregroundColor: white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: white,
        side: const BorderSide(color: white, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: grey100,
      hintStyle: TextStyle(color: grey600),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
    ),
    
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: cardDark,
      selectedItemColor: primaryPurple,
      unselectedItemColor: grey400,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

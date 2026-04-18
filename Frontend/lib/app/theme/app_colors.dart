import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF1DB954);
  static const primaryLight = Color(0xFFF4C542);
  static const secondary = Color(0xFF3D5AF1);
  static const tertiary = Color(0xFFFF4ECD);

  static const success = Color(0xFF3ECF8E);
  static const info = Color(0xFF67B7FF);
  static const danger = Color(0xFFE05252);

  static const darkBg = Color(0xFF0D0D0D);
  static const darkSurface = Color(0xFF141414);
  static const darkCard = Color(0xFF1A1A1A);
  static const darkCardAlt = Color(0xFF1E1E1E);
  static const darkNavBar = Color(0xFF111111);

  static const lightBg = Color(0xFFF5F6FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightCardAlt = Color(0xFFF0F1F5);
  static const lightNavBar = Color(0xFFFFFFFF);

  static const darkAuthCard = Color(0xFF121212);
  static const lightAuthCard = Color(0xFFFAFAFA);

  static const purple = primary;
  static const purpleLight = primaryLight;
  static const pink = tertiary;
  static const blue = secondary;
  static const teal = Color(0xFF2EC4B6);

  static const neoYellow = Color(0xFFFFEB34);
  static const neoPlunk = Color(0xFFB8A600);
  static const neoGreen = Color(0xFF8DD04A);
  static const neoBorderGreen = Color(0xFF8DD04A);

  static const income = Color(0xFF38EF7D);
  static const expense = Color(0xFFFF4E6A);
  static const warning = Color(0xFFFFC107);
  static const badgeRed = Color(0xFFFF3B30);

  static const darkTextPrimary = Color(0xFFF5F5F5);
  static const darkTextSecondary = Color(0xFF8A8A9A);
  static const darkTextMuted = Color(0xFF4A4A5A);

  static const lightTextPrimary = Color(0xFF1A1A2E);
  static const lightTextSecondary = Color(0xFF5A5A7A);
  static const lightTextMuted = Color(0xFFAAAAAA);

  static const primaryGradient = [
    Color(0xFF1DB954),
    Color(0xFFF4C542),
  ];

  static const balanceCardGradient = [
    Color(0xFF1DB954),
    Color(0xFF2EC4B6),
  ];

  static const incomeGradient = [
    Color(0xFF11998E),
    Color(0xFF38EF7D),
  ];

  static const expenseGradient = [
    Color(0xFFEB3349),
    Color(0xFFFF4E6A),
  ];

  static const darkShimmerGradient = [
    Color(0xFF1A1A1A),
    Color(0xFF2A2A3A),
    Color(0xFF1A1A1A),
  ];

  static const donutGradient = [
    Color(0xFF1DB954),
    Color(0xFF3D5AF1),
    Color(0xFF38EF7D),
    Color(0xFFFFC107),
  ];

  static const catFood = Color(0xFFFF6B6B);
  static const catTransport = Color(0xFF4ECDC4);
  static const catShopping = Color(0xFFFFE66D);
  static const catHealth = Color(0xFF6BCB77);
  static const catEntertain = Color(0xFFF4C542);
  static const catBills = Color(0xFFFF9A3C);
  static const catEducation = Color(0xFF45B7D1);
  static const catSalary = Color(0xFF38EF7D);
  static const catFreelance = Color(0xFF3D5AF1);
  static const catInvestment = Color(0xFF00C9A7);
  static const catGift = Color(0xFFFF85A2);
  static const catOther = Color(0xFF8A8A9A);

  static const darkBorder = Color(0xFF2A2A3A);
  static const lightBorder = Color(0xFFE0E0E0);

  static const darkFab = Color(0xFF1E1E1E);
  static const lightFab = Color(0xFF1DB954);

  static Color categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return catFood;
      case 'transport':
        return catTransport;
      case 'shopping':
        return catShopping;
      case 'health':
        return catHealth;
      case 'entertainment':
        return catEntertain;
      case 'bills':
        return catBills;
      case 'education':
        return catEducation;
      case 'salary':
        return catSalary;
      case 'freelance':
        return catFreelance;
      case 'investment':
        return catInvestment;
      case 'gift':
        return catGift;
      default:
        return catOther;
    }
  }

  static List<Color> balanceGradient(double balance) {
    if (balance < 0) return expenseGradient;
    if (balance < 1000) return [Color(0xFFFFC107), Color(0xFFFF9A3C)];
    return balanceCardGradient;
  }
}

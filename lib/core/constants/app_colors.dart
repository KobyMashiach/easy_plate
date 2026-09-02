import 'package:flutter/material.dart';

/// Warm, paper-and-leather palette for the skeuomorphic cookbook UI.
abstract class AppColors {
  static const parchment = Color(0xFFF7EEDD);
  static const parchmentDark = Color(0xFFEADFC7);
  static const leather = Color(0xFF7A4B32);
  static const leatherDark = Color(0xFF5A3623);
  static const ink = Color(0xFF3A2A1F);
  static const accent = Color(0xFFC85C2E);
  static const accentSoft = Color(0xFFE8A26B);
  static const success = Color(0xFF4C8C4A);
  static const error = Color(0xFFB3412C);
  static const divider = Color(0xFFD8C7A5);

  static const dietaryChipColors = <String, Color>{
    'meat': Color(0xFFB3412C),
    'dairy': Color(0xFF3E7CB1),
    'vegetarian': Color(0xFF4C8C4A),
    'vegan': Color(0xFF2E7D4F),
    'kosher': Color(0xFF7A4B32),
    'glutenFree': Color(0xFFC08A2E),
    'allergy': Color(0xFF8E44AD),
  };
}

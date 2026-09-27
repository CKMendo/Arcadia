import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Lake Michigan Coastal Links Palette
  static const Color lakeCyan = Color(0xFF00B4D8);
  static const Color cyanLight = Color(0xFF38BDF8);
  static const Color cyanGlow = Color(0xFF7DD3FC);
  static const Color lakeDeep = Color(0xFF0284C7);
  static const Color oceanicNavy = Color(0xFF0F253E);

  // Arcadia Dune & Driftwood Accents
  static const Color duneSand = Color(0xFFDFC19E);
  static const Color duneLight = Color(0xFFF3E5D4);
  static const Color driftwood = Color(0xFF9E8F7D);
  static const Color coastalAmber = Color(0xFFF59E0B);

  // Surfaces & Backgrounds
  static const Color backgroundDark = Color(0xFF0A1118);
  static const Color surfaceDark = Color(0xFF111E2E);
  static const Color surfaceElevated = Color(0xFF16273B);
  static const Color cardDark = Color(0xFF111E2E);
  static const Color cardBorder = Color(0xFF1E334A);
  static const Color cardSelected = Color(0xFF183B5E);
  static const Color appBarDark = Color(0xFF0C1622);

  // Text & Content
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Aliases for unified consistency across codebase
  static const Color gold = duneSand;
  static const Color goldLight = duneLight;
  static const Color primaryGreen = lakeCyan;
  static const Color darkGreen = appBarDark;
  static const Color deepForest = backgroundDark;
  static const Color sageGreen = lakeDeep;
  static const Color lightGreen = Color(0xFFE0F2FE);
  static const Color warmSand = duneSand;
  static const Color amber = coastalAmber;

  // Scoring Markers (High contrast daylight readable)
  static const Color scoreEagle = Color(0xFFF59E0B); // Amber / Sunrise
  static const Color scoreBirdie = Color(0xFFEF4444); // Vibrant Coral Red
  static const Color scorePar = Color(0xFF06B6D4); // Crisp Lake Cyan
  static const Color scoreBogey = Color(0xFF64748B); // Coastal Slate
  static const Color scoreDouble = Color(0xFF1E293B); // Deep Abyssal Slate

  // Teams (Coastal Cup: Team Lake vs Team Bluff)
  static const Color teamA = Color(0xFF0EA5E9); // Lake Azure
  static const Color teamB = Color(0xFFF97316); // Bluff Sunset Tangerine
}

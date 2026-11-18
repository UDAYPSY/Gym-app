import 'package:flutter/material.dart';

class AppColors {
  // Energetic Dark Fitness Theme Palette
  static const Color primary = Color(0xFF10B981); // High-voltage Emerald Green
  static const Color primaryDark = Color(0xFF059669);
  static const Color primaryLight = Color(0xFF34D399);

  static const Color accent = Color(0xFFF59E0B); // Amber / Gold for VIP & Dues
  static const Color accentDark = Color(0xFFD97706);

  static const Color background = Color(0xFF0B1120); // Deep Obsidian Blue
  static const Color surface = Color(0xFF1E293B); // Slate 800 Surface Card
  static const Color surfaceElevated = Color(0xFF334155); // Slate 700

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Status Colors
  static const Color statusActive = Color(0xFF10B981); // Green
  static const Color statusExpired = Color(0xFFEF4444); // Red
  static const Color statusDues = Color(0xFFF59E0B); // Amber
  static const Color statusFrozen = Color(0xFF3B82F6); // Blue
  static const Color statusMaintenance = Color(0xFF6B7280); // Gray

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF047857)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class ShiftConstants {
  static const String morning = "Morning (6:00 AM – 10:00 AM)";
  static const String general = "General Day (10:00 AM – 5:00 PM)";
  static const String evening = "Evening Peak (5:00 PM – 10:00 PM)";
  static const String fullDay = "All-Access Full Day (24/7)";

  static const List<String> allShifts = [
    morning,
    general,
    evening,
    fullDay,
  ];
}

class MuscleGroups {
  static const String chest = "Chest";
  static const String back = "Back";
  static const String shoulders = "Shoulders";
  static const String biceps = "Biceps";
  static const String triceps = "Triceps";
  static const String legs = "Legs (Quads/Hamstrings/Calves)";
  static const String core = "Core & Abs";
  static const String cardio = "Cardio & Stamina";

  static const List<String> all = [
    chest,
    back,
    shoulders,
    biceps,
    triceps,
    legs,
    core,
    cardio,
  ];
}

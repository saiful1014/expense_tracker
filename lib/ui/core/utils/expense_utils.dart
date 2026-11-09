import 'package:flutter/material.dart';

class ExpenseUtils {
  // Dedicated palette for custom categories — completely distinct from all built-in colors!
  // None of these colors overlap with Food (Amber), Transport (Sky Blue), Shopping (Purple),
  // Bills (Crimson), Entertainment (Magenta), Health (Emerald), or Others (Slate Grey).
  static const List<Color> _customCategoryColors = [
    Color(0xFF0D9488), // 0: Deep Vibrant Teal
    Color(0xFF4338CA), // 1: Royal Deep Indigo
    Color(0xFFEA580C), // 2: Burnt Flame Orange
    Color(0xFF84CC16), // 3: Electric Lime Green
    Color(0xFF06B6D4), // 4: Vibrant Cyan / Turquoise
    Color(0xFF7E22CE), // 5: Deep Royal Plum
    Color(0xFFB45309), // 6: Warm Amber Brown / Bronze
    Color(0xFF1D4ED8), // 7: Royal Cobalt Blue
    Color(0xFFF43F5E), // 8: Coral Watermelon
    Color(0xFF059669), // 9: Dark Jade
    Color(0xFF9F1239), // 10: Deep Wine / Burgundy
    Color(0xFF6D28D9), // 11: Electric Violet
    Color(0xFF2DD4BF), // 12: Bright Mint
    Color(0xFFC026D3), // 13: Orchid Fuchsia
    Color(0xFF78350F), // 14: Warm Rust Wood
    Color(0xFF0284C7), // 15: Deep Ocean Blue
  ];

  static List<String> _cachedCustomCategories = [];

  static void setCustomCategories(List<String> categories) {
    _cachedCustomCategories = List.from(categories);
  }

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFF59E0B); // Amber
      case 'transport':
        return const Color(0xFF0EA5E9); // Sky Blue
      case 'shopping':
        return const Color(0xFF8B5CF6); // Purple-Amethyst
      case 'bills':
        return const Color(0xFFEF4444); // Rose-Crimson
      case 'entertainment':
        return const Color(0xFFEC4899); // Magenta-Rose
      case 'health':
        return const Color(0xFF10B981); // Emerald
      case 'others':
        return const Color(0xFF64748B); // Slate-Grey
      default:
        // Use sequential slot from dedicated custom palette if known, else deterministic hash
        final cachedIndex = _cachedCustomCategories.indexOf(category);
        if (cachedIndex != -1) {
          return _customCategoryColors[cachedIndex % _customCategoryColors.length];
        }
        final hashIndex = category.trim().toLowerCase().hashCode.abs() % _customCategoryColors.length;
        return _customCategoryColors[hashIndex];
    }
  }

  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'bills':
        return Icons.receipt;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.local_hospital;
      case 'others':
        return Icons.category;
      default:
        return Icons.label;
    }
  }

  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

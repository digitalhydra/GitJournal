/*
 * SPDX-FileCopyrightText: 2019-2021 Vishesh Handa <me@vhanda.in>
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';

import 'settings/settings.dart';

class Themes {
  // DEFAULT THEMES
  static final _light = ThemeData(
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.green,
    ).copyWith(
      primary: const Color(0xFF66bb6a),
      secondary: const Color(0xff6d4c41),
      onPrimary: Colors.black,
    ),
    brightness: Brightness.light,
    primaryColor: const Color(0xFF66bb6a),
    primaryColorLight: const Color(0xFF98ee99),
    primaryColorDark: const Color(0xFF338a3e),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: const Color(0xFF338a3e),
      selectionHandleColor: const Color(0xFF66bb6a),
      selectionColor: Colors.grey[400],
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
    }),
    useMaterial3: false,
  );

  static final _dark = ThemeData(
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.grey,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xff212121),
      secondary: const Color(0xff689f38),
    ),
    brightness: Brightness.dark,
    primaryColor: const Color(0xff212121),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Color(0xFF66bb6a),
      selectionHandleColor: Color(0xFF66bb6a),
      selectionColor: Color(0xff689f38),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
    }),
    checkboxTheme: CheckboxThemeData(
      fillColor:
          WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF66bb6a);
        }
        return null;
      }),
    ),
    radioTheme: RadioThemeData(
      fillColor:
          WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF66bb6a);
        }
        return null;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor:
          WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF66bb6a);
        }
        return null;
      }),
      trackColor:
          WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF66bb6a);
        }
        return null;
      }),
    ),
    useMaterial3: false,
  );

  // CUTE THEME 1: Strawberry Cream (Soft pink & cream)
  // Perfect for a cozy, feminine recipe app
  static final _strawberryCream = ThemeData(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFFFB7B2),        // Soft strawberry pink
      secondary: Color(0xFFB5EAD7),      // Mint green accent
      surface: Color(0xFFFFF8F0),        // Cream white
      background: Color(0xFFFFF8F0),     // Cream white
      error: Color(0xFFFF6B6B),          // Soft red
      onPrimary: Color(0xFF2D2D2D),      // Dark text on pink
      onSecondary: Color(0xFF2D2D2D),    // Dark text on mint
      onSurface: Color(0xFF2D2D2D),      // Dark text on cream
      onBackground: Color(0xFF2D2D2D),   // Dark text
      onError: Color(0xFFFFFFFF),        // White on error
    ),
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFFF8F0),
    primaryColor: const Color(0xFFFFB7B2),
    primaryColorLight: const Color(0xFFFFE5E5),
    primaryColorDark: const Color(0xFFFF9A94),
    hintColor: const Color(0xFFFFDAC1), // Peach accent
    highlightColor: const Color(0xFFFFE5E5),
    dividerColor: const Color(0xFFFFE5E5),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Color(0xFFFFB7B2),
      selectionHandleColor: Color(0xFFFFB7B2),
      selectionColor: Color(0xFFFFE5E5),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFFFFFFFF),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFF8F0),
      foregroundColor: Color(0xFF2D2D2D),
      elevation: 0,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
    }),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFFFFB7B2);
        }
        return const Color(0xFFFFE5E5);
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFFFFB7B2);
        }
        return const Color(0xFFFFFFFF);
      }),
      trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFFFFB7B2).withOpacity(0.5);
        }
        return const Color(0xFFCCCCCC);
      }),
    ),
    useMaterial3: false,
  );

  // CUTE THEME 2: Sage & Blush (Dusty rose & sage green)
  // Modern, calming, nature-inspired
  static final _sageAndBlush = ThemeData(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFD4A5A5),        // Dusty rose
      secondary: Color(0xFF9CAF88),      // Sage green
      surface: Color(0xFFF9F7F2),        // Warm ivory
      background: Color(0xFFF9F7F2),     // Warm ivory
      error: Color(0xFFE8927C),          // Terracotta
      onPrimary: Color(0xFF2D2D2D),      // Dark text
      onSecondary: Color(0xFF2D2D2D),    // Dark text
      onSurface: Color(0xFF4A4A4A),      // Warm gray
      onBackground: Color(0xFF4A4A4A),   // Warm gray
      onError: Color(0xFFFFFFFF),        // White on error
    ),
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF9F7F2),
    primaryColor: const Color(0xFFD4A5A5),
    primaryColorLight: const Color(0xFFE8D4D4),
    primaryColorDark: const Color(0xFFB88A8A),
    hintColor: const Color(0xFFE8927C), // Terracotta accent
    highlightColor: const Color(0xFFE8D4D4),
    dividerColor: const Color(0xFFE8D4D4),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Color(0xFFD4A5A5),
      selectionHandleColor: Color(0xFFD4A5A5),
      selectionColor: Color(0xFFE8D4D4),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFFFFFFFF),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF9F7F2),
      foregroundColor: Color(0xFF4A4A4A),
      elevation: 0,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
    }),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFFD4A5A5);
        }
        return const Color(0xFFE8D4D4);
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFFD4A5A5);
        }
        return const Color(0xFFFFFFFF);
      }),
      trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFFD4A5A5).withOpacity(0.5);
        }
        return const Color(0xFFCCCCCC);
      }),
    ),
    useMaterial3: false,
  );

  static ThemeData fromName(String name) {
    switch (name) {
      case DEFAULT_LIGHT_THEME_NAME:
        return _light;
      case DEFAULT_DARK_THEME_NAME:
        return _dark;
      case STRAWBERRY_CREAM_THEME_NAME:
        return _strawberryCream;
      case SAGE_AND_BLUSH_THEME_NAME:
        return _sageAndBlush;
      default:
        throw Exception("Theme not found - $name");
    }
  }
}

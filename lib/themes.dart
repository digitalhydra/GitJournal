/*
 * SPDX-FileCopyrightText: 2019-2021 Vishesh Handa <me@vhanda.in>
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';

import 'settings/settings.dart';

class Themes {
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

  // CYBERPUNK THEME 1: Neon (Navy background + Cyan text)
  static final _cyberpunkNeon = ThemeData(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF0abdc6), // Cyan
      secondary: Color(0xFFd300c4), // Magenta
      surface: Color(0xFF000b1e), // Deep Navy
      background: Color(0xFF000b1e), // Deep Navy
      error: Color(0xFFff0000), // Red
      onPrimary: Color(0xFF000b1e), // Dark on cyan
      onSecondary: Color(0xFFFFFFFF), // White on magenta
      onSurface: Color(0xFF0abdc6), // Cyan on dark
      onBackground: Color(0xFFd7d7d5), // Off-white
      onError: Color(0xFFFFFFFF),
    ),
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF000b1e),
    primaryColor: const Color(0xFF0abdc6),
    primaryColorLight: const Color(0xFF00ffc8),
    primaryColorDark: const Color(0xFF123e7c),
    hintColor: const Color(0xFF711c91),
    highlightColor: const Color(0xFF123e7c), // Dark blue for selected items (contrasts with magenta text)
    dividerColor: const Color(0xFF123e7c),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Color(0xFF0abdc6),
      selectionHandleColor: Color(0xFFd300c4),
      selectionColor: Color(0xFF123e7c),
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
          return const Color(0xFF0abdc6);
        }
        return null;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF0abdc6);
        }
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF123e7c);
        }
        return null;
      }),
    ),
    useMaterial3: false,
  );

  // CYBERPUNK THEME 2: Scarlet (Purple background + Green text)
  static final _cyberpunkScarlet = ThemeData(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00ff9c), // Neon Green
      secondary: Color(0xFFff004c), // Hot Pink
      surface: Color(0xFF261D45), // Deep Purple
      background: Color(0xFF261D45), // Deep Purple
      error: Color(0xFFff004c), // Pink/Red
      onPrimary: Color(0xFF000000), // Black on green
      onSecondary: Color(0xFFFFFFFF), // White on pink
      onSurface: Color(0xFF00ff9c), // Green on purple
      onBackground: Color(0xFFffffff), // White
      onError: Color(0xFFFFFFFF),
    ),
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF261D45),
    primaryColor: const Color(0xFF00ff9c),
    primaryColorLight: const Color(0xFF9dff00),
    primaryColorDark: const Color(0xFF1D1833),
    hintColor: const Color(0xFFc592ff),
    highlightColor: const Color(0xFF1D1833), // Dark purple for selected items (contrasts with pink text)
    dividerColor: const Color(0xFF1D1833),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Color(0xFF00ff9c),
      selectionHandleColor: Color(0xFFff004c),
      selectionColor: Color(0xFF003cff),
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
          return const Color(0xFF00ff9c);
        }
        return null;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF00ff9c);
        }
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF1D1833);
        }
        return null;
      }),
    ),
    useMaterial3: false,
  );

  // CYBERPUNK THEME 3: Umbra (Dark purple-black + Balanced accents)
  static final _cyberpunkUmbra = ThemeData(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00ffc8), // Bright Cyan
      secondary: Color(0xFFff0080), // Hot Pink
      surface: Color(0xFF0d0221), // Very Dark Purple-Black
      background: Color(0xFF0d0221), // Very Dark Purple-Black
      error: Color(0xFFff004c), // Bright Red
      onPrimary: Color(0xFF000000), // Black on cyan
      onSecondary: Color(0xFF000000), // Black on pink
      onSurface: Color(0xFFe0e0e0), // Light gray
      onBackground: Color(0xFFe0e0e0), // Light gray
      onError: Color(0xFFFFFFFF),
    ),
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0d0221),
    primaryColor: const Color(0xFF00ffc8),
    primaryColorLight: const Color(0xFF39ff14),
    primaryColorDark: const Color(0xFF1a0b2e),
    hintColor: const Color(0xFFbf00ff),
    highlightColor: const Color(0xFF1a0b2e), // Dark purple for selected items (contrasts with pink text)
    dividerColor: const Color(0xFF1a0b2e),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Color(0xFF00ffc8),
      selectionHandleColor: Color(0xFFff0080),
      selectionColor: Color(0xFF1a0b2e),
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
          return const Color(0xFF00ffc8);
        }
        return null;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF00ffc8);
        }
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF1a0b2e);
        }
        return null;
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
      case CYBERPUNK_NEON_THEME_NAME:
        return _cyberpunkNeon;
      case CYBERPUNK_SCARLET_THEME_NAME:
        return _cyberpunkScarlet;
      case CYBERPUNK_UMBRA_THEME_NAME:
        return _cyberpunkUmbra;
      default:
        throw Exception("Theme not found - $name");
    }
  }
}

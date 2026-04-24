/*
 * SPDX-FileCopyrightText: 2019-2021 Vishesh Handa <me@vhanda.in>
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gitjournal/l10n.dart';
import 'package:gitjournal/settings/settings.dart';
import 'package:gitjournal/settings/settings_bottom_menu_bar.dart';
import 'package:gitjournal/settings/settings_display_images.dart';
import 'package:gitjournal/settings/settings_misc.dart';
import 'package:gitjournal/settings/settings_screen.dart';
import 'package:gitjournal/settings/settings_theme.dart';
import 'package:gitjournal/settings/widgets/language_selector.dart';
import 'package:gitjournal/settings/widgets/settings_header.dart';
import 'package:gitjournal/settings/widgets/settings_list_preference.dart';
import 'package:gitjournal/widgets/pro_overlay.dart';
import 'package:provider/provider.dart';

const feature_themes = false;

class SettingsUIScreen extends StatelessWidget {
  static const routePath = '/settings/ui';

  const SettingsUIScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var settings = context.watch<Settings>();

    var list = ListView(
      children: [
        SettingsHeader(context.loc.settingsDisplayTitle),
        ListPreference(
          title: context.loc.settingsDisplayTheme,
          currentOption: settings.theme.toPublicString(context),
          options: SettingsTheme.options
              .map((f) => f.toPublicString(context))
              .toList(),
          onChange: (String publicStr) {
            var s = SettingsTheme.fromPublicString(context, publicStr);
            settings.theme = s;
            settings.save();
          },
        ),
        if (feature_themes)
          SettingsTile(
            title: context.loc.settingsThemeLight,
            iconData: FontAwesomeIcons.sun,
            onTap: () {
              var route = MaterialPageRoute(
                builder: (context) =>
                    const SettingsThemeScreen(Brightness.light),
                settings:
                    const RouteSettings(name: SettingsThemeScreen.routePath),
              );
              Navigator.push(context, route);
            },
          ),
        if (feature_themes)
          SettingsTile(
            title: context.loc.settingsThemeDark,
            iconData: FontAwesomeIcons.solidMoon,
            onTap: () {
              var route = MaterialPageRoute(
                builder: (context) =>
                    const SettingsThemeScreen(Brightness.dark),
                settings:
                    const RouteSettings(name: SettingsThemeScreen.routePath),
              );
              Navigator.push(context, route);
            },
          ),
        const LanguageSelector(),
        ListTile(
          title: Text(context.loc.settingsDisplayImagesTitle),
          subtitle: Text(context.loc.settingsDisplayImagesSubtitle),
          onTap: () {
            var route = MaterialPageRoute(
              builder: (context) => SettingsDisplayImagesScreen(),
              settings: const RouteSettings(
                name: SettingsDisplayImagesScreen.routePath,
              ),
            );
            Navigator.push(context, route);
          },
        ),
        ProOverlay(
          child: ListPreference(
            title: context.loc.settingsDisplayHomeScreen,
            currentOption: settings.homeScreen.toPublicString(context),
            options: SettingsHomeScreen.options
                .map((f) => f.toPublicString(context))
                .toList(),
            onChange: (String publicStr) {
              var s = SettingsHomeScreen.fromPublicString(context, publicStr);
              settings.homeScreen = s;
              settings.save();
            },
          ),
        ),
        ProOverlay(
          child: ListTile(
            title: Text(context.loc.settingsBottomMenuBarTitle),
            subtitle: Text(context.loc.settingsBottomMenuBarSubtitle),
            onTap: () {
              var route = MaterialPageRoute(
                builder: (context) => BottomMenuBarSettings(),
                settings:
                    const RouteSettings(name: BottomMenuBarSettings.routePath),
              );
              Navigator.push(context, route);
            },
          ),
        ),
        ListTile(
          title: Text(context.loc.settingsMiscTitle),
          onTap: () {
            var route = MaterialPageRoute(
              builder: (context) => SettingsMisc(),
              settings: const RouteSettings(name: SettingsMisc.routePath),
            );
            Navigator.push(context, route);
          },
        ),
        const Divider(),
        const SettingsHeader("Text Size"),
        ListTile(
          title: const Text("Text Scale"),
          subtitle: Text("${(settings.textScale * 100).toInt()}%"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: settings.textScale > 0.5
                    ? () {
                        settings.textScale =
                            (settings.textScale - settings.textScaleStep)
                                .clamp(0.5, 3.0);
                        settings.save();
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: settings.textScale < 3.0
                    ? () {
                        settings.textScale =
                            (settings.textScale + settings.textScaleStep)
                                .clamp(0.5, 3.0);
                        settings.save();
                      }
                    : null,
              ),
            ],
          ),
        ),
        ListTile(
          title: const Text("Increment Step"),
          subtitle: Text("${(settings.textScaleStep * 100).toInt()}%"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: settings.textScaleStep > 0.1
                    ? () {
                        settings.textScaleStep =
                            (settings.textScaleStep - 0.05).clamp(0.1, 0.5);
                        settings.save();
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: settings.textScaleStep < 0.5
                    ? () {
                        settings.textScaleStep =
                            (settings.textScaleStep + 0.05).clamp(0.1, 0.5);
                        settings.save();
                      }
                    : null,
              ),
            ],
          ),
        ),
        SwitchListTile(
          title: const Text("Fixed Max Width"),
          subtitle: const Text("Limit text width for better readability"),
          value: settings.useFixedMaxWidth,
          onChanged: (bool newVal) {
            settings.useFixedMaxWidth = newVal;
            settings.save();
          },
        ),
        const Divider(),
        const SettingsHeader("Color Theme"),
        ListTile(
          title: const Text("Light Theme"),
          subtitle: Text(_getThemeDisplayName(settings.lightTheme)),
          onTap: () => _showThemePicker(context, settings, true),
        ),
        ListTile(
          title: const Text("Dark Theme"),
          subtitle: Text(_getThemeDisplayName(settings.darkTheme)),
          onTap: () => _showThemePicker(context, settings, false),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc.settingsListUserInterfaceTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: list,
    );
  }

  String _getThemeDisplayName(String themeName) {
    switch (themeName) {
      case DEFAULT_LIGHT_THEME_NAME:
        return "Light Default";
      case DEFAULT_DARK_THEME_NAME:
        return "Dark Default";
      case STRAWBERRY_CREAM_THEME_NAME:
        return "Strawberry Cream (Pink/Mint)";
      case SAGE_AND_BLUSH_THEME_NAME:
        return "Sage & Blush (Rose/Green)";
      default:
        return themeName;
    }
  }

  void _showThemePicker(BuildContext context, Settings settings, bool isLight) {
    final themes = [
      DEFAULT_LIGHT_THEME_NAME,
      DEFAULT_DARK_THEME_NAME,
      STRAWBERRY_CREAM_THEME_NAME,
      SAGE_AND_BLUSH_THEME_NAME,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isLight ? "Select Light Theme" : "Select Dark Theme"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: themes.length,
            itemBuilder: (context, index) {
              final theme = themes[index];
              final isSelected = isLight
                  ? settings.lightTheme == theme
                  : settings.darkTheme == theme;
              return ListTile(
                title: Text(_getThemeDisplayName(theme)),
                trailing: isSelected ? const Icon(Icons.check) : null,
                onTap: () {
                  if (isLight) {
                    settings.lightTheme = theme;
                  } else {
                    settings.darkTheme = theme;
                  }
                  settings.save();
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }
}

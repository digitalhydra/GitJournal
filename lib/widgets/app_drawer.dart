/*
 * SPDX-FileCopyrightText: 2019-2021 Vishesh Handa <me@vhanda.in>
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:git_setup/screens.dart';
// HIDDEN - Login feature disabled
// import 'package:gitjournal/account/login_screen.dart';
import 'package:gitjournal/analytics/analytics.dart';

// UNLOCKED BUILD - Purchase removed
// import 'package:gitjournal/iap/purchase_screen.dart';
import 'package:gitjournal/l10n.dart';
import 'package:gitjournal/logger/logger.dart';
import 'package:gitjournal/repository_manager.dart';
import 'package:gitjournal/screens/error_screen.dart';
import 'package:gitjournal/screens/home_screen.dart';
import 'package:gitjournal/screens/categories/categories_screen.dart';
import 'package:gitjournal/screens/categories/recipe_list_screen.dart';
import 'package:gitjournal/screens/search/recipe_search_screen.dart';
import 'package:gitjournal/core/recipe/recipe_category.dart';
import 'package:gitjournal/screens/menu/weekly_menu_list_screen.dart';
import 'package:gitjournal/screens/menu/grocery_list_quick_screen.dart';
import 'package:gitjournal/screens/editor/recipe_editor_screen.dart';

// HIDDEN - Bug report, Feedback removed
// import 'package:gitjournal/settings/bug_report.dart';
import 'package:gitjournal/settings/settings.dart';
import 'package:gitjournal/settings/settings_screen.dart';
import 'package:gitjournal/widgets/app_drawer_header.dart';
import 'package:gitjournal/widgets/pro_overlay.dart';
// HIDDEN - Rate us removed
// import 'package:launch_app_store/launch_app_store.dart';
import 'package:provider/provider.dart';
// HIDDEN - Share removed
// import 'package:share_plus/share_plus.dart';
import 'package:time/time.dart';
// HIDDEN - Platform check for Rate removed
// import 'package:universal_io/io.dart' show Platform;

class AppDrawer extends StatefulWidget {
  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController animController;

  late Animation<double> sizeAnimation;
  late Animation<Offset> slideAnimation;

  @override
  void initState() {
    super.initState();

    animController =
        AnimationController(duration: 250.milliseconds, vsync: this);

    slideAnimation = Tween(begin: const Offset(0.0, -0.5), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: animController,
      curve: Easing.legacy,
    ));
    sizeAnimation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: animController,
      curve: Easing.legacy,
    ));
  }

  @override
  void dispose() {
    animController.dispose();
    super.dispose();
  }

  Widget _buildRepoList() {
    var divider = const Row(children: <Widget>[Expanded(child: Divider())]);
    var repoManager = context.watch<RepositoryManager>();
    var repoIds = repoManager.repoIds;

    Widget w = Column(
      children: <Widget>[
        const SizedBox(height: 8),
        for (var id in repoIds) RepoTile(id),
        ProOverlay(
          child: _buildDrawerTile(
            context,
            icon: Icons.add,
            title: context.loc.drawerAddRepo,
            onTap: () {
              repoManager.addRepoAndSwitch();
              Navigator.pop(context);
            },
            selected: false,
          ),
        ),
        divider,
      ],
    );

    w = SlideTransition(
      position: slideAnimation,
      transformHitTests: false,
      child: w,
    );

    return SizeTransition(
      sizeFactor: sizeAnimation,
      child: w,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget? setupGitButton;
    var repoManager = context.watch<RepositoryManager>();
    var repo = repoManager.currentRepo;
    var settings = context.watch<Settings>();
    var textStyle = Theme.of(context).textTheme.bodyLarge;
    var currentRoute = ModalRoute.of(context)!.settings.name;

    // Clean up favorites - remove folders that no longer exist
    if (repo != null) {
      _cleanupFavorites(settings, repo);
    }

    if (repo?.remoteGitRepoConfigured == false) {
      setupGitButton = ListTile(
        leading: Icon(Icons.sync, color: textStyle!.color),
        title: Text(context.loc.drawerSetup, style: textStyle),
        trailing: const Icon(
          Icons.info,
          color: Colors.red,
        ),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, GitHostSetupScreen.routePath);

          logEvent(Event.DrawerSetupGitHost);
        },
      );
    }

    var divider = const Row(children: <Widget>[Expanded(child: Divider())]);

    return Drawer(
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: <Widget>[
          AppDrawerHeader(
            repoListToggled: () {
              if (animController.isCompleted) {
                animController.reverse(from: 1.0);
              } else {
                animController.forward(from: 0.0);
              }
            },
          ),
          // If they are multiple show the current one which a tick mark
          _buildRepoList(),
          if (setupGitButton != null) ...[setupGitButton, divider],
          // UNLOCKED BUILD - Purchase button removed
          // if (!appConfig.proMode)
          //   _buildDrawerTile(
          //     context,
          //     icon: Icons.power,
          //     title: context.loc.drawerPro,
          //     onTap: () {
          //       Navigator.pop(context);
          //       Navigator.pushNamed(context, PurchaseScreen.routePath);
          //
          //       logEvent(
          //         Event.PurchaseScreenOpen,
          //         parameters: {"from": "drawer"},
          //       );
          //     },
          //   ),
          // HIDDEN - Login feature disabled
          // if (appConfig.experimentalAccounts)
          //   _buildDrawerTile(
          //     context,
          //     icon: Icons.account_circle,
          //     title: context.loc.drawerLogin,
          //     onTap: () => _navTopLevel(context, LoginPage.routePath),
          //     selected: currentRoute == LoginPage.routePath,
          //   ),
          // UNLOCKED BUILD - Divider removed
          // if (!appConfig.proMode) divider,
          // 📍 Main Navigation
          if (repo != null) ...[
            _buildSectionHeader(context, "Navegación Principal"),
            _buildDrawerTile(
              context,
              icon: Icons.home,
              title: "Inicio",
              onTap: () => _navTopLevel(context, CategoriesScreen.routePath),
              selected: currentRoute == CategoriesScreen.routePath,
            ),
            _buildDrawerTile(
              context,
              icon: Icons.search,
              title: "Buscar Recetas",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RecipeSearchScreen(),
                  ),
                );
              },
              selected: false,
            ),
            _buildDrawerTile(
              context,
              icon: Icons.favorite,
              title: "Favoritos",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecipeListScreen(
                      category: RecipeCategory(
                        id: 'favoritos',
                        name: 'Favoritos',
                        icon: '❤️',
                        tags: ['favoritos', 'favorite'],
                      ),
                    ),
                  ),
                );
              },
              selected: false,
            ),
            _buildDrawerTile(
              context,
              icon: Icons.calendar_view_week,
              title: "Menús Semanales",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WeeklyMenuListScreen(),
                  ),
                );
              },
              selected: false,
            ),
            _buildDrawerTile(
              context,
              icon: Icons.shopping_cart,
              title: "Lista de Compras",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GroceryListQuickScreen(),
                  ),
                );
              },
              selected: false,
            ),
          ],
          // 📂 Organization Section
          if (repo != null) ...[
            _buildSectionHeader(context, "Organización"),
            _buildCategoriesExpansionTile(context),
            _buildDrawerTile(
              context,
              icon: Icons.format_list_bulleted,
              title: "Todas las Recetas",
              onTap: () => _navTopLevel(context, HomeScreen.routePath),
              selected: currentRoute == HomeScreen.routePath,
            ),
          ],
          divider,
          // ⚡ Quick Actions
          if (repo != null) ...[
            _buildSectionHeader(context, "Acciones Rápidas"),
            _buildDrawerTile(
              context,
              icon: Icons.add_circle,
              title: "Nueva Receta",
              onTap: () {
                Navigator.pop(context);
                final repoManager = context.read<RepositoryManager>();
                final repo = repoManager.currentRepo;
                if (repo != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecipeEditorScreen(
                        repoPath: repo.repoPath,
                      ),
                    ),
                  );
                }
              },
              selected: false,
            ),
          ],
          divider,
          // HIDDEN - Share, Rate, Feedback, Bug Report removed
          // _buildDrawerTile(
          //   context,
          //   icon: Icons.share,
          //   title: context.loc.drawerShare,
          //   onTap: () {
          //     Navigator.pop(context);
          //     Share.share('Checkout GitJournal https://gitjournal.io/');
          //
          //     logEvent(Event.DrawerShare);
          //   },
          // ),
          // if (Platform.isAndroid || Platform.isIOS)
          //   _buildDrawerTile(
          //     context,
          //     icon: Icons.feedback,
          //     title: context.loc.drawerRate,
          //     onTap: () {
          //       LaunchReview.launch(
          //         androidAppId: "io.gitjournal.gitjournal",
          //         iOSAppId: "1466519634",
          //       );
          //
          //       Navigator.pop(context);
          //       logEvent(Event.DrawerRate);
          //     },
          //   ),
          // _buildDrawerTile(
          //   context,
          //   icon: Icons.rate_review,
          //   title: context.loc.drawerFeedback,
          //   onTap: () async {
          //     await createFeedback(context);
          //     Navigator.pop(context);
          //   },
          // ),
          // _buildDrawerTile(
          //   context,
          //   icon: Icons.bug_report,
          //   title: context.loc.drawerBug,
          //   onTap: () async {
          //     await createBugReport(context);
          //     Navigator.pop(context);
          //   },
          // ),
          if (repo != null)
            _buildDrawerTile(
              context,
              icon: Icons.settings,
              title: context.loc.settingsTitle,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, SettingsScreen.routePath);

                logEvent(Event.DrawerSettings);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCategoriesExpansionTile(BuildContext context) {
    final iconMap = <String, IconData>{
      'desayuno': Icons.wb_sunny,
      'almuerzo': Icons.wb_cloudy,
      'cena': Icons.nights_stay,
      'postres': Icons.cake,
      'panaderia': Icons.bakery_dining,
      'bebidas': Icons.local_cafe,
      'snacks': Icons.fastfood,
      'sopas': Icons.soup_kitchen,
      'ensaladas': Icons.eco,
      'aperitivos': Icons.tapas,
    };

    return ExpansionTile(
      leading: const Icon(Icons.category),
      title: const Text("Categorías"),
      children: defaultCategories.map((cat) {
        return ListTile(
          leading: Icon(iconMap[cat.id] ?? Icons.restaurant_menu),
          title: Text(cat.name),
          dense: true,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecipeListScreen(
                  category: cat,
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildDrawerTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required void Function() onTap,
    bool isFontAwesome = false,
    bool selected = false,
  }) {
    var theme = Theme.of(context);
    var listTileTheme = ListTileTheme.of(context);
    var textStyle = theme.textTheme.bodyLarge!.copyWith(
      color: selected ? theme.colorScheme.secondary : listTileTheme.textColor,
    );

    var iconW = !isFontAwesome
        ? Icon(icon, color: textStyle.color)
        : FaIcon(icon, color: textStyle.color);

    var tile = ListTile(
      leading: iconW,
      title: Text(title, style: textStyle),
      onTap: onTap,
      selected: selected,
    );
    return Container(
      color: selected ? theme.highlightColor : theme.scaffoldBackgroundColor,
      child: tile,
    );
  }

  void _cleanupFavorites(Settings settings, dynamic repo) {
    // Remove favorites that no longer exist
    var validFavorites = <String>[];
    var changed = false;

    for (var folderPath in settings.favoriteFolders) {
      var folder = repo.rootFolder.getFolderWithSpec(folderPath);
      if (folder != null) {
        validFavorites.add(folderPath);
      } else {
        changed = true;
      }
    }

    if (changed) {
      settings.favoriteFolders = validFavorites;
      settings.save();
    }
  }
}

class RepoTile extends StatelessWidget {
  const RepoTile(
    this.id, {
    super.key,
  });

  final String id;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var listTileTheme = ListTileTheme.of(context);
    var repoManager = context.watch<RepositoryManager>();

    var selected = repoManager.currentId == id;
    var textStyle = theme.textTheme.bodyLarge!.copyWith(
      color: selected ? theme.colorScheme.secondary : listTileTheme.textColor,
    );

    var icon = FaIcon(FontAwesomeIcons.book, color: textStyle.color);

    var tile = ListTile(
      leading: icon,
      title: Text(repoManager.repoFolderName(id), style: textStyle),
      onTap: () async {
        Navigator.pop(context);

        try {
          await repoManager.setCurrentRepo(id);
        } catch (ex) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            ErrorScreen.routePath,
            (r) => true,
          );
          return;
        }

        Navigator.of(context).pushNamedAndRemoveUntil(
          CategoriesScreen.routePath,
          (r) => true,
        );
      },
    );

    return Container(
      color: selected ? theme.highlightColor : theme.scaffoldBackgroundColor,
      child: tile,
    );
  }
}



void _navTopLevel(BuildContext context, String toRoute) {
  var fromRoute = ModalRoute.of(context)!.settings.name;
  Log.i("Routing from $fromRoute -> $toRoute");

  // Always first pop the AppBar
  Navigator.pop(context);

  if (fromRoute == toRoute) {
    return;
  }

  var wasParent = false;
  Navigator.popUntil(
    context,
    (route) {
      if (route.isFirst) {
        return true;
      }
      wasParent = route.settings.name == toRoute;
      if (wasParent) {
        Log.i("Router popping ${route.settings.name}");
      }
      return wasParent;
    },
  );
  if (!wasParent) {
    Navigator.pushNamed(context, toRoute);
  }
}

/*
 * SPDX-FileCopyrightText: 2019-2021 Vishesh Handa <me@vhanda.in>
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';
import 'package:function_types/function_types.dart';
import 'package:gitjournal/folder_listing/model/folder_listing_model.dart';
import 'package:gitjournal/l10n.dart';
import 'package:gitjournal/settings/settings.dart';
import 'package:provider/provider.dart';

typedef FolderSelectedCallback = void Function(FolderListingFolder folder);

class FolderTreeView extends StatelessWidget {
  final FolderListingFolder rootFolder;
  final String? selectedPath;

  final FolderSelectedCallback onFolderSelected;
  final Func0<void> onFolderUnselected;
  final FolderSelectedCallback onFolderEntered;

  const FolderTreeView({
    super.key,
    required this.rootFolder,
    required this.selectedPath,
    required this.onFolderEntered,
    required this.onFolderSelected,
    required this.onFolderUnselected,
  });

  @override
  Widget build(BuildContext context) {
    var tile = FolderTile(
      folder: rootFolder,
      onTap: (FolderListingFolder folder) {
        if (selectedPath == null) {
          onFolderEntered(folder);
        } else {
          onFolderUnselected();
        }
      },
      onLongPress: (folder) {
        onFolderSelected(folder);
      },
      selectedPath: selectedPath,
    );

    return ListView(
      children: <Widget>[tile],
    );
  }
}

class FolderTile extends StatefulWidget {
  final FolderListingFolder folder;
  final FolderSelectedCallback onTap;
  final FolderSelectedCallback onLongPress;
  final String? selectedPath;

  const FolderTile({
    required this.folder,
    required this.onTap,
    required this.onLongPress,
    required this.selectedPath,
  });

  @override
  FolderTileState createState() => FolderTileState();
}

class FolderTileState extends State<FolderTile> {
  final MainAxisSize mainAxisSize = MainAxisSize.min;
  final CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start;
  final MainAxisAlignment mainAxisAlignment = MainAxisAlignment.center;

  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      children: <Widget>[
        GestureDetector(
          child: _buildFolderTile(),
          onTap: () => widget.onTap(widget.folder),
          onLongPress: () => _showFolderMenu(context),
        ),
        _getChild(),
      ],
    );
  }

  void _showFolderMenu(BuildContext context) {
    final settings = context.read<Settings>();
    final folder = widget.folder;
    
    // Don't show menu for root folder
    if (folder.path.isEmpty) return;
    
    var isFavorite = settings.favoriteFolders.contains(folder.path);
    var canAddMore = settings.favoriteFolders.length < 10;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(folder.publicName),
            subtitle: Text(folder.path),
            leading: const Icon(Icons.folder),
          ),
          const Divider(),
          if (isFavorite)
            ListTile(
              leading: const Icon(Icons.star_border),
              title: const Text("Remove from favorites"),
              onTap: () {
                settings.favoriteFolders.remove(folder.path);
                settings.save();
                Navigator.pop(context);
              },
            )
          else if (canAddMore)
            ListTile(
              leading: Icon(Icons.star, color: Theme.of(context).colorScheme.primary),
              title: const Text("Add to favorites"),
              onTap: () {
                settings.favoriteFolders.add(folder.path);
                settings.save();
                Navigator.pop(context);
              },
            )
          else
            const ListTile(
              leading: Icon(Icons.star, color: Colors.grey),
              title: Text("Favorites limit reached (10 max)"),
              enabled: false,
            ),
          ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: const Text("Select folder"),
            onTap: () {
              Navigator.pop(context);
              widget.onLongPress(folder);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFolderTile() {
    var folder = widget.folder;
    var ic = _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down;
    
    final subtitle = context.loc
        .widgetsFolderTreeViewNotesCount(folder.noteCount.toString());

    final theme = Theme.of(context);
    final settings = context.watch<Settings>();
    
    var isFavorite = settings.favoriteFolders.contains(folder.path);
    
    // Build trailing widgets
    var trailingWidgets = <Widget>[];
    
    // Star icon for favorites
    if (isFavorite) {
      trailingWidgets.add(
        Icon(
          Icons.star,
          color: theme.colorScheme.primary,
        ),
      );
    }
    
    // Expand/collapse button
    if (folder.hasSubFolders) {
      trailingWidgets.add(
        IconButton(
          icon: Icon(ic),
          onPressed: expand,
        ),
      );
    }

    var selected = widget.selectedPath == widget.folder.path;
    return Card(
      color: selected ? theme.highlightColor : theme.cardColor,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            Icons.folder,
            size: 36,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(folder.publicName.isEmpty ? "Root Folder" : folder.publicName),
            ),
          ],
        ),
        subtitle: Text(subtitle),
        trailing: trailingWidgets.isNotEmpty 
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: trailingWidgets,
              )
            : null,
        selected: selected,
      ),
    );
  }

  void expand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  Widget _getChild() {
    if (!_isExpanded) return Container();

    var children = <FolderTile>[];
    for (var folder in widget.folder.subFolders) {
      children.add(FolderTile(
        folder: folder,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        selectedPath: widget.selectedPath,
      ));
    }

    return Container(
      margin: const EdgeInsets.only(left: 16.0),
      child: Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: children,
      ),
    );
  }
}

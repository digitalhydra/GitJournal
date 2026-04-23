/*
 * SPDX-FileCopyrightText: 2019-2021 Vishesh Handa <me@vhanda.in>
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';
import 'package:gitjournal/core/folder/notes_folder.dart';
import 'package:gitjournal/core/folder/notes_folder_fs.dart';
import 'package:gitjournal/core/note.dart';
import 'package:gitjournal/core/notes/note.dart';
import 'package:gitjournal/core/org_links_handler.dart';
import 'package:gitjournal/core/views/note_links_view.dart';
import 'package:gitjournal/editors/editor_scroll_view.dart';
import 'package:gitjournal/folder_views/common.dart';
import 'package:gitjournal/logger/logger.dart';
import 'package:gitjournal/markdown/markdown_renderer.dart';
import 'package:gitjournal/settings/settings.dart';
import 'package:gitjournal/widgets/notes_backlinks.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:provider/provider.dart';

class NoteViewer extends StatefulWidget {
  final Note note;
  final NotesFolder parentFolder;
  const NoteViewer({
    super.key,
    required this.note,
    required this.parentFolder,
  });

  @override
  State<NoteViewer> createState() => _NoteViewerState();
}

class _NoteViewerState extends State<NoteViewer> {
  double _initialScale = 1.0;

  @override
  Widget build(BuildContext context) {
    if (widget.note.fileFormat == NoteFileFormat.OrgMode) {
      var handler = OrgLinkHandler(context, widget.note);

      return GestureDetector(
        onScaleStart: (details) {
          _initialScale = context.read<Settings>().textScale;
        },
        onScaleUpdate: (details) {
          var settings = context.read<Settings>();
          var newScale = (_initialScale * details.scale).clamp(0.5, 3.0);
          if ((newScale - settings.textScale).abs() > 0.05) {
            settings.textScale = newScale;
            settings.save();
            setState(() {});
          }
        },
        child: Org(
          widget.note.body,
          onLinkTap: (link) => handler.launchUrl(link.location),
          onLocalSectionLinkTap: (OrgTree tree) {
            Log.d("local tree link: $tree");
          },
          onSectionLongPress: (OrgSection section) {
            Log.d('local section long-press: ${section.headline.rawTitle!}');
          },
        ),
      );
    }

    final rootFolder = context.watch<NotesFolderFS>();
    var view = EditorScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          NoteTitleHeader(widget.note.title ?? ""),
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: MarkdownRenderer(
              note: widget.note,
              onNoteTapped: (note) =>
                  openNoteEditor(context, note, widget.parentFolder),
            ),
          ),
          const SizedBox(height: 16.0),
          NoteBacklinkRenderer(
            note: widget.note,
            rootFolder: rootFolder,
            parentFolder: widget.parentFolder,
            linksView: NoteLinksProvider.of(context),
          ),
          // _buildFooter(context),
        ],
      ),
    );

    // Add pinch zoom support
    return GestureDetector(
      onScaleStart: (details) {
        _initialScale = context.read<Settings>().textScale;
      },
      onScaleUpdate: (details) {
        var settings = context.read<Settings>();
        var newScale = (_initialScale * details.scale).clamp(0.5, 3.0);
        if ((newScale - settings.textScale).abs() > 0.05) {
          settings.textScale = newScale;
          settings.save();
          setState(() {});
        }
      },
      child: view,
    );
  }

  /*
  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.arrow_left),
            tooltip: 'Previous Entry',
            onPressed: showPrevNoteFunc,
          ),
          Expanded(
            flex: 10,
            child: Text(''),
          ),
          IconButton(
            icon: Icon(Icons.arrow_right),
            tooltip: 'Next Entry',
            onPressed: showNextNoteFunc,
          ),
        ],
      ),
    );
  }
  */
}

class NoteTitleHeader extends StatelessWidget {
  final String header;
  const NoteTitleHeader(this.header);

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    var settings = context.watch<Settings>();
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Text(
        header,
        style: textTheme.titleLarge?.copyWith(
          fontSize: (textTheme.titleLarge?.fontSize ?? 20.0) * settings.textScale,
        ),
      ),
    );
  }
}

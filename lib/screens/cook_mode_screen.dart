/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../core/recipe/recipe.dart';

/// Full-screen cooking mode for hands-free recipe viewing
/// Features:
/// - Large text, dark background for kitchen visibility
/// - Keeps screen on (wake lock)
/// - Ingredients always visible
/// - Scrollable parsed markdown instructions
/// - Auto-detected timers with one-tap buttons
/// - Landscape: split view (ingredients left, instructions right)
class CookModeScreen extends StatefulWidget {
  final Recipe recipe;

  const CookModeScreen({
    super.key,
    required this.recipe,
  });

  @override
  State<CookModeScreen> createState() => _CookModeScreenState();
}

class _CookModeScreenState extends State<CookModeScreen> {
  Timer? _activeTimer;
  int? _timerSeconds;
  bool _isLandscape = false;

  @override
  void initState() {
    super.initState();
    // Keep screen on during cooking
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
    _updateOrientation();
  }

  @override
  void dispose() {
    // Restore system UI when leaving
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    _activeTimer?.cancel();
    super.dispose();
  }

  void _updateOrientation() {
    final size = MediaQuery.of(context).size;
    setState(() {
      _isLandscape = size.width > size.height;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateOrientation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            return _isLandscape 
                ? _buildLandscapeView() 
                : _buildPortraitView();
          },
        ),
      ),
    );
  }

  /// Portrait: Ingredients on top, instructions below (scrollable)
  Widget _buildPortraitView() {
    return Column(
      children: [
        // Header with title and exit
        _buildHeader(),
        
        // Ingredients section (compact)
        _buildIngredientsSection(isCompact: true),
        
        const Divider(color: Colors.white24, height: 1),
        
        // Instructions (scrollable markdown)
        Expanded(
          child: _buildInstructionsSection(),
        ),
        
        // Active timer banner (if any)
        if (_activeTimer != null) _buildTimerBanner(),
      ],
    );
  }

  /// Landscape: Split view - ingredients left, instructions right
  Widget _buildLandscapeView() {
    return Row(
      children: [
        // Left: Ingredients
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildIngredientsSection(isCompact: false),
              ),
            ],
          ),
        ),
        
        const VerticalDivider(color: Colors.white24, width: 1),
        
        // Right: Instructions
        Expanded(
          flex: 3,
          child: Column(
            children: [
              // Sub-header for instructions
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Instrucciones',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Instructions
              Expanded(
                child: _buildInstructionsSection(),
              ),
              // Timer banner
              if (_activeTimer != null) _buildTimerBanner(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.recipe.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Salir',
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection({required bool isCompact}) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          if (!isCompact) ...[
            const Text(
              'Ingredientes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: widget.recipe.ingredients.isEmpty
                ? const Text(
                    'No hay ingredientes',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: isCompact,
                    physics: isCompact 
                        ? const NeverScrollableScrollPhysics() 
                        : const AlwaysScrollableScrollPhysics(),
                    itemCount: widget.recipe.ingredients.length,
                    itemBuilder: (context, index) {
                      final ingredient = widget.recipe.ingredients[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                ingredient.displayText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: widget.recipe.body.isEmpty
          ? const Center(
              child: Text(
                'No hay instrucciones',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          : SingleChildScrollView(
              child: _buildMarkdownWithTimers(widget.recipe.body),
            ),
    );
  }

  /// Builds markdown with auto-detected timer buttons
  Widget _buildMarkdownWithTimers(String body) {
    // Find all time patterns and split text
    final timePattern = RegExp(
      r'(\d+)\s*(minutos?|mins?|minutes?|min|horas?|hours?|hrs?)',
      caseSensitive: false,
    );
    
    final matches = timePattern.allMatches(body).toList();
    
    if (matches.isEmpty) {
      // No timers found, just show markdown
      return MarkdownBody(
        data: body,
        styleSheet: _cookModeMarkdownStyle(),
      );
    }
    
    // Build widget with timer buttons inserted
    final List<Widget> widgets = [];
    int lastEnd = 0;
    
    for (final match in matches) {
      // Add text before this match
      if (match.start > lastEnd) {
        final beforeText = body.substring(lastEnd, match.start);
        widgets.add(
          MarkdownBody(
            data: beforeText,
            styleSheet: _cookModeMarkdownStyle(),
          ),
        );
      }
      
      // Add the matched text with timer button
      final timeText = match.group(0)!;
      final minutes = int.parse(match.group(1)!);
      
      widgets.add(
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              timeText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                height: 1.6,
              ),
            ),
            const SizedBox(width: 8),
            _buildTimerButton(minutes),
          ],
        ),
      );
      
      lastEnd = match.end;
    }
    
    // Add remaining text
    if (lastEnd < body.length) {
      widgets.add(
        MarkdownBody(
          data: body.substring(lastEnd),
          styleSheet: _cookModeMarkdownStyle(),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildTimerButton(int minutes) {
    return GestureDetector(
      onTap: () => _startTimer(minutes * 60),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.timer,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              '$minutes min',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerBanner() {
    final minutes = _timerSeconds! ~/ 60;
    final seconds = _timerSeconds! % 60;
    
    return Container(
      color: Colors.orange,
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Row(
          children: [
            const Icon(Icons.timer, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.stop, color: Colors.white, size: 32),
              onPressed: _stopTimer,
            ),
          ],
        ),
      ),
    );
  }

  MarkdownStyleSheet _cookModeMarkdownStyle() {
    return MarkdownStyleSheet(
      p: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        height: 1.6,
      ),
      h1: const TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),
      h2: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),
      h3: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),
      listBullet: const TextStyle(
        color: Colors.white70,
        fontSize: 20,
      ),
      strong: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      em: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  void _startTimer(int seconds) {
    _activeTimer?.cancel();
    setState(() {
      _timerSeconds = seconds;
    });
    
    _activeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timerSeconds! > 0) {
          _timerSeconds = _timerSeconds! - 1;
        } else {
          _activeTimer?.cancel();
          _activeTimer = null;
          // TODO: Play alarm sound
        }
      });
    });
  }

  void _stopTimer() {
    _activeTimer?.cancel();
    setState(() {
      _activeTimer = null;
      _timerSeconds = null;
    });
  }
}

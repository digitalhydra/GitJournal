/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../core/ingredients/ingredient.dart';
import '../../core/recipe/recipe.dart';
import '../../core/recipe/recipe_category.dart';
import '../../core/recipe/recipe_repository_service.dart';

/// Screen for creating or editing recipes
/// Uses tabs: Info (title, photo, ingredients) and Instructions (markdown editor)
class RecipeEditorScreen extends StatefulWidget {
  final Recipe? recipe;
  final String repoPath;

  const RecipeEditorScreen({
    super.key,
    this.recipe,
    required this.repoPath,
  });

  @override
  State<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends State<RecipeEditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  final _servingsController = TextEditingController();
  
  // Markdown controller with toolbar
  final _bodyController = TextEditingController();
  final _scrollController = ScrollController();
  
  final List<Ingredient> _ingredients = [];
  final List<String> _selectedTags = [];
  bool _isLoading = false;

  // Ingredient input
  final _ingredientNameController = TextEditingController();
  final _ingredientAmountController = TextEditingController();
  String _selectedUnit = 'g';
  bool _useCustomUnit = false;

  // Image handling
  File? _selectedImage;
  String? _existingImagePath;
  final _imagePicker = ImagePicker();

  // Markdown formatting buttons
  final List<_MarkdownButton> _markdownButtons = const [
    _MarkdownButton(icon: Icons.format_bold, text: '**', label: 'Bold'),
    _MarkdownButton(icon: Icons.format_italic, text: '_', label: 'Italic'),
    _MarkdownButton(icon: Icons.format_strikethrough, text: '~~', label: 'Strike'),
    _MarkdownButton(icon: Icons.title, text: '# ', label: 'Heading'),
    _MarkdownButton(icon: Icons.format_list_bulleted, text: '- ', label: 'List'),
    _MarkdownButton(icon: Icons.format_list_numbered, text: '1. ', label: 'Numbered'),
    _MarkdownButton(icon: Icons.check_box, text: '- [ ] ', label: 'Checkbox'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.recipe != null) {
      _loadRecipeData();
    }
  }

  void _loadRecipeData() {
    final recipe = widget.recipe!;
    _titleController.text = recipe.title;
    _prepTimeController.text = recipe.prepTime?.toString() ?? '';
    _cookTimeController.text = recipe.cookTime?.toString() ?? '';
    _servingsController.text = recipe.servings?.toString() ?? '';
    _bodyController.text = recipe.body;
    _ingredients.addAll(recipe.ingredients);
    _selectedTags.addAll(recipe.tags);
    _existingImagePath = recipe.imagePath;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();
    _bodyController.dispose();
    _ingredientNameController.dispose();
    _ingredientAmountController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.recipe != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Receta' : 'Nueva Receta'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Info', icon: Icon(Icons.info_outline)),
            Tab(text: 'Instrucciones', icon: Icon(Icons.edit_note)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveRecipe,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar'),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildInstructionsTab(),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Título',
              hintText: 'Ej: Pasta Carbonara',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El título es obligatorio';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Image section
          _buildImageSection(),
          const SizedBox(height: 24),

          // Time and servings row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _prepTimeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Prep (min)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.timer, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _cookTimeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cocción (min)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_fire_department, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _servingsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Porciones',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Categories
          Text(
            'Categorías',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: defaultCategories.map((cat) {
              final isSelected = _selectedTags.contains(cat.id);
              return FilterChip(
                label: Text(cat.name),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(cat.id);
                    } else {
                      _selectedTags.remove(cat.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Ingredients section
          Text(
            'Ingredientes',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Ingredients list
          if (_ingredients.isNotEmpty) ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _ingredients.length,
              itemBuilder: (context, index) {
                final ingredient = _ingredients[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.fiber_manual_record, size: 8),
                  title: Text(ingredient.displayText),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () {
                      setState(() {
                        _ingredients.removeAt(index);
                      });
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],

          // Add ingredient form
          _buildIngredientForm(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildIngredientForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _ingredientNameController,
                decoration: const InputDecoration(
                  hintText: 'Nombre (ej: harina)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _ingredientAmountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: 'Cant',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _useCustomUnit
                  ? TextField(
                      controller: TextEditingController(),
                      decoration: const InputDecoration(
                        hintText: 'Otra unidad',
                        border: OutlineInputBorder(),
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      initialValue: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unidad',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'g', child: Text('g')),
                        DropdownMenuItem(value: 'kg', child: Text('kg')),
                        DropdownMenuItem(value: 'ml', child: Text('ml')),
                        DropdownMenuItem(value: 'l', child: Text('l')),
                        DropdownMenuItem(value: 'taza', child: Text('taza')),
                        DropdownMenuItem(value: 'cda', child: Text('cda')),
                        DropdownMenuItem(value: 'cdta', child: Text('cdta')),
                        DropdownMenuItem(value: 'pieza', child: Text('pieza')),
                        DropdownMenuItem(value: 'huevo', child: Text('huevo')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedUnit = value ?? 'g';
                        });
                      },
                    ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle, size: 32),
              onPressed: _addIngredient,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInstructionsTab() {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Markdown toolbar
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _markdownButtons.length,
            itemBuilder: (context, index) {
              final btn = _markdownButtons[index];
              return IconButton(
                icon: Icon(btn.icon),
                tooltip: btn.label,
                onPressed: () => _insertMarkdown(btn.text),
              );
            },
          ),
        ),
        
        // Instructions editor
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _bodyController,
              scrollController: _scrollController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: '''# Título de la Receta

## Ingredientes
- 500g de...
- 2 taza(s) de...

## Preparación

1. Primer paso
2. Segundo paso

## Notas
 Cualquier nota adicional...''',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _insertMarkdown(String marker) {
    final text = _bodyController.text;
    final selection = _bodyController.selection;
    
    String newText;
    int newCursor;
    
    if (selection.isValid && selection.start != selection.end) {
      // Wrap selected text
      final selectedText = text.substring(selection.start, selection.end);
      newText = text.replaceRange(
        selection.start,
        selection.end,
        '$marker$selectedText$marker',
      );
      newCursor = selection.end + marker.length * 2;
    } else {
      // Insert at cursor
      newText = text.substring(0, selection.start) +
          marker +
          text.substring(selection.start);
      newCursor = selection.start + marker.length;
    }
    
    _bodyController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }

  void _addIngredient() {
    final name = _ingredientNameController.text.trim();
    final amountText = _ingredientAmountController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre del ingrediente es obligatorio')),
      );
      return;
    }

    final amount = double.tryParse(amountText) ?? 1;

    setState(() {
      _ingredients.add(Ingredient(
        name: name,
        amount: amount,
        unit: _selectedUnit,
      ));
    });

    _ingredientNameController.clear();
    _ingredientAmountController.clear();
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Handle image saving
      String? imagePath;
      if (_selectedImage != null) {
        imagePath = await _saveImageToRepo(_selectedImage!);
      } else if (_existingImagePath != null) {
        imagePath = _existingImagePath;
      }

      final recipe = Recipe(
        id: widget.recipe?.id,
        title: _titleController.text.trim(),
        ingredients: _ingredients,
        body: _bodyController.text.trim(),
        tags: _selectedTags,
        prepTime: int.tryParse(_prepTimeController.text),
        cookTime: int.tryParse(_cookTimeController.text),
        servings: int.tryParse(_servingsController.text),
        imagePath: imagePath,
      );

      final service = RecipeRepositoryService(repoPath: widget.repoPath);

      // If editing, delete old file first
      if (widget.recipe != null) {
        await service.deleteRecipe(widget.recipe!);
      }

      await service.saveRecipe(recipe);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.recipe != null
              ? 'Receta actualizada'
              : 'Receta guardada'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Widget _buildImageSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto de la Receta',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedImage != null)
          _buildSelectedImage()
        else if (_existingImagePath != null)
          _buildExistingImage()
        else
          _buildImagePlaceholder(),
      ],
    );
  }

  Widget _buildSelectedImage() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            _selectedImage!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              _buildImageActionButton(
                icon: Icons.edit,
                onTap: _pickImage,
              ),
              const SizedBox(width: 8),
              _buildImageActionButton(
                icon: Icons.delete,
                onTap: () {
                  setState(() {
                    _selectedImage = null;
                    _existingImagePath = null;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExistingImage() {
    final fullPath = p.join(widget.repoPath, _existingImagePath!);
    final file = File(fullPath);

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildImagePlaceholder();
            },
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              _buildImageActionButton(
                icon: Icons.edit,
                onTap: _pickImage,
              ),
              const SizedBox(width: 8),
              _buildImageActionButton(
                icon: Icons.delete,
                onTap: () {
                  setState(() {
                    _selectedImage = null;
                    _existingImagePath = null;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[400]!,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 12),
            Text(
              'Agregar foto',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
        iconSize: 20,
      ),
    );
  }

  Future<void> _pickImage() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Seleccionar de galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _saveImageToRepo(File imageFile) async {
    final compressedBytes = await FlutterImageCompress.compressWithFile(
      imageFile.path,
      minWidth: 512,
      minHeight: 512,
      quality: 85,
      format: CompressFormat.webp,
    );

    if (compressedBytes == null) {
      throw Exception('Failed to compress image');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'recipe_$timestamp.webp';
    final imageDir = Directory(p.join(widget.repoPath, 'images'));

    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    final targetPath = p.join(imageDir.path, fileName);
    await File(targetPath).writeAsBytes(compressedBytes);

    return p.join('images', fileName);
  }
}

class _MarkdownButton {
  final IconData icon;
  final String text;
  final String label;

  const _MarkdownButton({
    required this.icon,
    required this.text,
    required this.label,
  });
}
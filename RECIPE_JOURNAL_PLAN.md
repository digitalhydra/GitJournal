# RecipeJournal Implementation Plan

## Project Context

**Base**: GitJournal - Flutter note-taking app with Git sync
**Conversion**: Recipe management app with Git persistence
**Branch**: `recipes` (branched from `master`)

### Why GitJournal?
- Offline-first sync via Git (perfect for recipes)
- Cross-platform (Android, iOS, Linux, macOS)
- Markdown + YAML frontmatter format
- Existing auth (GitHub/GitLab), settings, file storage

---

## Completed Work

### ✅ Image Optimization (Both Branches)
**Files**: `lib/core/image_processor.dart`, `lib/core/image.dart`
**Commit**: `f36466a3` (recipes), `5d064f19` (master)

**What it does**:
- All images resized to 512x512
- Center-cropped to square
- Converted to WebP (85% quality)
- ~50-100KB per image vs 2-5MB original

**Usage**:
```dart
Image.copyIntoFs(parent, filePath, process: true) // Auto-processes
```

---

## Core Architecture

### Data Persistence
- **Format**: Markdown files with YAML frontmatter
- **Storage**: Git repository (offline-first)
- **Cache**: Hive for local performance
- **Images**: Stored in repo, referenced by path

### Recipe File Format
```markdown
---
title: "Carbonara"
created: 2024-01-15
tags: [italian, pasta, dinner]
prep_time: 15
cook_time: 20
servings: 4
difficulty: medium
cuisine: italian
ingredients:
  - name: "Spaghetti"
    amount: 400
    unit: g
    ml: 400  # Internal conversion
  - name: "Eggs"
    amount: 3
    unit: large
instructions:
  - "Cook pasta al dente"
  - "Mix eggs and cheese"
  - "Combine off heat"
image: "./media/a1b2c3.webp"
---

# Notes
Freeform markdown here
```

---

## Feature Specifications

### 1. Smart Web Importer (Clipper)

**Purpose**: Import recipes from web sources

**Input Types**:
1. **URL** - Any recipe website
   - Parse schema.org JSON-LD
   - Fallback to HTML heuristics
   - Extract: title, ingredients, instructions, times, yield

2. **TikTok URL** - Recipe videos
   - Use WebView to load page
   - Extract caption from meta tags
   - Parse caption for ingredients/steps
   - Rate limit: 2 second delay between requests
   - Mark missing fields for manual edit

3. **Markdown** - Text files
   - Parse YAML frontmatter (structured)
   - Parse headers + lists (unstructured)
   - "Ingredients" header → ingredient list
   - "Instructions" header → step list

**Output**: `ImportResult`
```dart
class ImportResult {
  String? title;
  List<Ingredient> ingredients;
  List<String> instructions;
  int? prepTime;
  int? cookTime;
  int? servings;
  String sourceUrl;
  List<String> missingFields;  // What couldn't be parsed
  bool isPartial;
}
```

**UI Flow**:
```
Share → Detect type → Parse → Import Review Screen
                                    ↓
                          [Save Draft] [Edit Full]
                          (partial)    (complete)
```

**Files**:
- `lib/importers/recipe_importer.dart` (interface)
- `lib/importers/url_importer.dart`
- `lib/importers/tiktok_importer.dart`
- `lib/importers/markdown_importer.dart`
- `lib/importers/schema_org_parser.dart`
- `lib/importers/heuristic_parser.dart`
- `lib/importers/rate_limiter.dart`
- `lib/screens/import_review_screen.dart`

---

### 2. Unit Conversion System

**Requirement**: Display original measurement + ml conversion inline

**Example Display**:
```
2 cups flour (500ml)
1 tbsp oil (15ml)
250ml milk (250ml)
3 eggs
```

**Implementation**:

**A. Conversion Tables** (Metric Standard)

Liquids (direct volume):
| Unit | ml |
|------|-----|
| metric cup | 250 |
| tbsp | 15 |
| tsp | 5 |
| fl oz | 29.57 |
| pint | 473 |
| liter | 1000 |

Dry Goods (density-based):
| Ingredient | g/cup | ml/cup |
|------------|-------|--------|
| flour | 125 | 208 |
| sugar (granulated) | 200 | 250 |
| sugar (brown) | 220 | 275 |
| rice (uncooked) | 185 | 231 |
| oats | 90 | 150 |
| butter | 227 | 237 |
| oil | 218 | 250 |

**B. Data Model**:
```dart
class Ingredient {
  String rawText;      // "2 cups flour" - display as-is
  double? amount;      // 2.0
  String? unit;        // "cups"
  String? name;        // "flour"
  double? milliliters; // 500.0 - internal calculations
  bool isConverted;    // true if we could parse & convert
}
```

**C. Parser**:
```dart
class IngredientParser {
  // Input: "2 1/2 cups all-purpose flour"
  // Output: Ingredient with amount, unit, name, ml
}
```

**D. Scaling Engine**:
```dart
class ScalingEngine {
  // Scale recipe to target servings
  // Calculate in ml internally
  // Display in friendly units + ml
}
```

**Files**:
- `lib/core/ingredients/unit_converter.dart`
- `lib/core/ingredients/density_table.dart`
- `lib/core/ingredients/ingredient_parser.dart`
- `lib/core/ingredients/ingredient.dart`
- `lib/core/ingredients/scaling_engine.dart`

---

### 3. Cook Mode

**Purpose**: Full-screen cooking interface

**Features**:
- Wake lock (keep screen on)
- High contrast, large text
- Interactive checklists (tap to strike ingredients)
- Step-by-step navigation (Next/Back buttons)
- Voice commands (optional)
- Timer detection: "20 minutes" → one-tap timer
- Ingredient cross-out tracking

**UI**:
```
┌─────────────────────────────┐
│  🍝 Carbonara          ⏱️   │
│                             │
│  Ingredients          [5/6] │
│  ☑️ 2 cups flour (500ml)    │
│  ☑️ 1 tbsp oil (15ml)       │
│  ☐ 3 eggs                   │
│                             │
│  ─────────────────────────  │
│                             │
│  Step 2 of 4                │
│                             │
│  Mix eggs and cheese        │
│  together in bowl.          │
│                             │
│  [⏱️ Set Timer: 5 min]      │
│                             │
│  [← Back]    [Next →]       │
└─────────────────────────────┘
```

**Files**:
- `lib/screens/cook_mode_screen.dart`
- `lib/widgets/cook_mode_checklist.dart`
- `lib/widgets/step_navigation.dart`
- `lib/widgets/ingredient_timer.dart`

---

### 4. Grocery List & Pantry

**Features**:
- Generate list from planned recipes
- Aggregate ingredients (2 eggs + 2 eggs = 4 eggs)
- Aisle sorting (Produce, Baking, Meat, etc.)
- Pantry cross-check (hide items user has)
- Checkbox tracking

**Aggregation Logic** (using ml):
```dart
// Recipe 1: 2 cups flour (500ml)
// Recipe 2: 1 cup flour (250ml)
// Total: 750ml flour
```

**Files**:
- `lib/core/grocery/grocery_list.dart`
- `lib/core/grocery/aisle_classifier.dart`
- `lib/core/pantry/pantry_manager.dart`
- `lib/screens/grocery_list_screen.dart`

---

### 5. Recipe Model & Screens

**Data Model**:
```dart
class Recipe {
  String title;
  String? description;
  List<Ingredient> ingredients;
  List<String> instructions;
  int? prepTime;
  int? cookTime;
  int? servings;
  String? difficulty;
  String? cuisine;
  List<String> tags;
  String? imagePath;
  DateTime created;
  DateTime modified;
  
  // Methods
  List<Ingredient> scaleTo(int targetServings);
  String toMarkdown();  // Serialize to file
  static Recipe fromMarkdown(String content);
}
```

**Screens**:
- `lib/screens/recipe_list_screen.dart` - Grid with filters
- `lib/screens/recipe_detail_screen.dart` - Full recipe view
- `lib/screens/recipe_editor_screen.dart` - Create/edit
- `lib/widgets/recipe_card.dart` - List item widget

---

## Implementation Phases

### Phase 1: Foundation
- [x] Image optimization (512x512 WebP)
- [ ] Recipe data model (`Recipe`, `Ingredient`)
- [ ] Recipe serializer (YAML frontmatter)
- [ ] Unit converter + density tables
- [ ] Ingredient parser

### Phase 2: Import
- [ ] Importer interface
- [ ] URL importer (schema.org + heuristics)
- [ ] Rate limiter
- [ ] TikTok importer (WebView)
- [ ] Markdown importer
- [ ] Import review screen
- [ ] Share intent handler

### Phase 3: UI
- [ ] Recipe list screen (grid)
- [ ] Recipe detail screen
- [ ] Recipe editor
- [ ] Cook mode
- [ ] Scaling UI

### Phase 4: Smart Features
- [ ] Grocery list generator
- [ ] Aisle sorting
- [ ] Pantry manager
- [ ] Timer detection
- [ ] Voice commands (optional)

### Phase 5: Polish
- [ ] Search/filter
- [ ] Theming
- [ ] Backup/export
- [ ] Settings

---

## Dependencies to Add

```yaml
dependencies:
  # Already present
  flutter_image_compress: ^2.3.0
  image_picker: ^0.8.4+1
  path_provider: ^2.0.11
  
  # For importers
  flutter_inappwebview: ^6.0.0
  http: ^0.13.6
  html: ^0.15.4
  
  # For OCR (future)
  # google_mlkit_text_recognition: ^0.13.0
```

---

## Key Decisions

1. **Git Persistence**: Keep all data in Git repo as markdown files
   - Human-readable
   - Version control
   - No backend needed

2. **Image Storage**: Store in repo with recipe
   - 512x512 WebP keeps repo size manageable
   - ~100KB per image
   - Referenced by relative path

3. **Unit Conversion**: Dual storage
   - Original: "2 cups flour"
   - Internal: 500ml
   - Display: "2 cups flour (500ml)"
   - Calculate in ml, show both

4. **Import Strategy**: Partial imports allowed
   - Save drafts with missing fields
   - User can complete manually
   - Mark uncertain extractions

5. **Offline-First**: Git = offline by default
   - Sync when online
   - All features work offline
   - Background sync optional

---

## Testing Strategy

- Unit tests for parsers (ingredient, URL, markdown)
- Unit tests for unit conversions
- Widget tests for screens
- Integration tests for import flow
- Manual QA for TikTok scraping (rate limits change)

---

## Next Steps

Decide which Phase 1 component to build first:

1. **Recipe Model** - Foundation everything builds on
2. **Unit Converter** - Standalone, testable
3. **Ingredient Parser** - Depends on converter
4. **URL Importer** - Can test independently

Recommended: Start with **Unit Converter** → **Ingredient Parser** → **Recipe Model**

---

## Notes

- **License**: Keep AGPL-3.0 for Vishesh Handa's code, Apache-2.0 for new code
- **REUSE**: Run `reuse addheader` on new files
- **Flutter Version**: >=3.41.5, Dart >=3.3.0
- **Flavor**: Always use `--flavor dev` for running

## Current Branch

```bash
git branch  # Should show: * recipes
git log --oneline -5  # Latest: f36466a3 - feat: Add 512x512 WebP image optimization
```

---

**Document Version**: 1.0  
**Last Updated**: 2024-01-24  
**Branch**: recipes

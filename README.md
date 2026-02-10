# Mean-Variance Flutter Operator - Mock Implementation

A Tercen operator for visualizing and analyzing measurement variability through mean-variance plots. Supports multiple plot types: CV (Coefficient of Variation), SNR (Signal-to-Noise Ratio), and SD (Standard Deviation) with two-component error model fitting.

## Current Status

**Mock Implementation** - UI/UX prototype with placeholder data

This is a visual mock demonstrating the complete UI design following the Tercen design system. The statistical computation and real data integration will be implemented in the next phase.

## Features Implemented

### UI Components
✅ Complete Tercen app frame structure
✅ Context detection (taskId parameter)
✅ Conditional top bar (fullscreen mode only)
✅ Left panel with 5 sections:
  - **DISPLAY**: Chart title, plot type selector, model fit toggle, combine groups toggle
  - **AXES**: Log scale, X/Y axis limits with auto checkboxes
  - **MODEL FITTING**: High/low signal threshold sliders
  - **EXPORT**: PNG and PDF export buttons (placeholders)
  - **INFO**: GitHub version link
✅ Main content area with horizontal split layout
✅ Chart title display (when provided)
✅ Mock scatter plot visualization (4 panes in faceted view)
✅ Fit results table panel (collapsible)
✅ Light/dark theme with teal primary (Feb 2026 Tercen design)
✅ Theme persistence with SharedPreferences

### Design System
- Tercen design tokens (Feb 2026 update)
- Light theme: Blue primary (#1E40AF)
- Dark theme: Teal primary (#14B8A6), Blue links (#60A5FA)
- Material 3 component theming
- Responsive layout
- 4px base spacing unit
- Complete typography system

## Getting Started

### Prerequisites

- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher

### Installation

```bash
# Get dependencies
flutter pub get

# Run in Chrome (recommended for web apps)
flutter run -d chrome

# Run in Edge
flutter run -d edge

# Build for web
flutter build web
```

### Development Mode

The app detects whether it's running embedded in Tercen or standalone:

- **Standalone** (no `taskId` parameter): Shows top bar with "FULL SCREEN MODE" badge
- **Embedded** (`?taskId=xxx` in URL): Hides top bar (normal Tercen workflow mode)

To test embedded mode locally:
```
http://localhost:XXXX/?taskId=test123
```

## Project Structure

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart          # Light theme colors
│   │   ├── app_colors_dark.dart     # Dark theme colors (teal primary)
│   │   ├── app_spacing.dart         # Spacing constants
│   │   ├── app_text_styles.dart     # Typography
│   │   └── app_theme.dart           # Material 3 theme configuration
│   └── utils/
│       └── context_detector.dart    # taskId detection
├── presentation/
│   ├── providers/
│   │   └── theme_provider.dart      # Theme state with persistence
│   ├── screens/
│   │   └── mean_and_cv_screen.dart  # Main screen
│   └── widgets/
│       ├── left_panel.dart          # Left panel with 5 sections
│       ├── main_content.dart        # Chart area + table
│       └── top_bar.dart             # Conditional top bar
└── main.dart                         # Entry point
```

## Mock Data

The current implementation uses placeholder data:
- **4 mock panes**: Group1.Control, Group1.Treatment, Group2.Control, Group2.Treatment
- **Mock scatter plots**: Procedurally generated points with fit curves
- **Mock fit results**: Hardcoded σ₀, CV₁, and SNR values

## Controls (Interactive)

All controls are fully interactive in the mock:

✅ Theme toggle (light/dark)
✅ Panel collapse/expand
✅ Chart title input
✅ Plot type selector (CV/SNR/SD)
✅ Show model fit toggle
✅ Combine all groups toggle
✅ Log x-axis checkbox
✅ Axis limit inputs with auto checkboxes
✅ High/low signal threshold sliders
✅ Export buttons (show placeholder messages)
✅ Fit results table collapse

Charts update visually based on:
- Plot type selection (shows different y-axis label)
- Show model fit toggle (shows/hides red fit line)
- Combine groups toggle (single chart vs 2x2 grid)
- Table shows/hides based on model fit toggle

## Next Steps

### Phase 2: Data Integration
1. Integrate with Tercen data model (`.ri`, `.ci`, `.y` projections)
2. Implement replicate grouping and statistics computation
3. Add real scatter plot rendering with fl_chart library
4. Implement two-component error model fitting algorithm

### Phase 3: Advanced Features
1. Real PNG/PDF export functionality
2. Chart interactivity (zoom, pan, tooltips)
3. Legend click-to-highlight
4. Table row click to highlight corresponding pane
5. Panel resize with drag handle

## References

- Functional Specification: `functional_specification.md`
- Tercen Design System: `_local/tercen-style/`
- Original R/Shiny Implementation: `_local/mean_and_cv_shiny_operator/`

## License

Copyright © Tercen
For Tercen platform use only

# Mean and CV Flutter Operator

##### Description

The `mean_and_cv_flutter_operator` is a Flutter web app used for creating CV plots, and fitting the variation as a function of intensity to the Two Component Error Model. This is the Flutter/WASM replacement for the original [mean_and_cv_shiny_operator](https://github.com/tercen/mean_and_cv_shiny_operator).

##### Usage

Input projection|.
---|---
`row`   | represents the variables (e.g. ID)
`col`   | represents the category (e.g. barcode, Sample Name)
`y-axis`| measurement value
`color`	| color (e.g. barcode, Sample Name)

Output relations|.
---|---
`Operator view` | view of the Flutter web application

##### Details

The operator creates CV (Coefficient of Variation), SNR (Signal-to-Noise Ratio), and SD (Standard Deviation) plots. It fits the Two Component Error Model to the data and displays the fit curve overlaid on the scatter plot.

The crosstab grid is laid out as follows:
- **Rows** (supergroups): determined by the `color` projection
- **Columns** (test conditions): determined by the `col` projection
- Each pane shows a scatter plot of the selected metric (CV, SNR, or SD) against mean intensity
- The "Combine Groups" toggle collapses all panes into a single combined view with per-pane coloring

**Two Component Error Model**: `variance = σ₀² + CV₁² × mean²`

The model is fitted iteratively using quantile-based thresholds to classify points as low-signal (used to estimate σ₀) and high-signal (used to estimate CV₁ from log-variance). SNR is reported in dB as `-10 × log₁₀(CV₁)`.

##### Controls

- **Display**: Chart title, plot type (CV/SNR/SD), model fit toggle, combine groups toggle
- **Axes**: Log x-axis, manual X/Y axis limits with auto checkboxes
- **Model Fitting**: High and low signal quantile threshold sliders (0.0–1.0)
- **Export**: PNG and PDF download with per-pane size controls (width × height in pixels)

##### Context Detection

The app detects whether it is running embedded in Tercen or standalone:
- **Embedded** (`?taskId=xxx` in URL): connects to the Tercen API to load real crosstab data
- **Standalone** (no `taskId`): falls back to bundled CSV example data and shows a top bar with "FULL SCREEN MODE" badge

##### Building

```bash
# Get dependencies
flutter pub get

# Build for Tercen deployment (WASM)
flutter build web --wasm --release

# Run locally in Chrome
flutter run -d chrome
```

The built output is served from `build/web` as configured in `operator.json`.

##### See Also

[mean_and_cv_shiny_operator](https://github.com/tercen/mean_and_cv_shiny_operator)
[mean_operator](https://github.com/tercen/mean_operator)
[mean_sd_operator](https://github.com/tercen/mean_sd_operator)

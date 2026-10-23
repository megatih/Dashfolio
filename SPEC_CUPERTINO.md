# Dashfolio: Cupertino Skin Specification

Status: **implemented; HIG revamp applied (see §17 and §18)** · Target: Claude Code implementation · Project root: `dashfolio/`
Companion to `SPEC.md` (read §10, §11, §12, §13 and §18 first). Where this file and `SPEC.md` disagree about skins or the design system, this file wins. Everything else in `SPEC.md` still applies.

## 1. Summary

Add a second UI "skin" built on Flutter's `cupertino` library. On iOS and macOS the user can choose between the existing **Neumorphic** skin and the new **Cupertino** skin in Settings ▸ Appearance. The choice applies live, with no restart.

**There is one screen tree.** Every screen is written once, against a skin-neutral widget facade (`App*`). The facade renders either the Neumorphic kit or the Cupertino kit. A UI change (new field, new section, new action) is made once, in one screen file, and appears in both skins. The two kits are separate, self-contained implementations behind the facade; they never appear in screen code.

### Decisions (fixed; do not re-litigate)

| Topic | Decision |
|---|---|
| Architecture | One screen tree on a skin-neutral `App*` facade; two kits behind it (Neumorphic, Cupertino) |
| Idiomatic layouts | Achieved by layout-level facade primitives (`AppPage`, `AppSection`, `AppRow`, `AppFormSheet`, …) that render idiomatically per skin, not by duplicating screens |
| Per-screen overrides | Rare, small, local, via `SkinBuilder`, and each must be listed in the override registry (§8). A test enforces the registry |
| Root widget | `CupertinoApp.router` for Cupertino, `MaterialApp.router` for Neumorphic |
| macOS | Cupertino widgets plus macOS adjustments (sidebar at every width, no bottom tab bar, denser controls) |
| Switching | Live; router location preserved; user remains on Settings |
| Default | Cupertino on fresh iOS/macOS installs; existing installs keep Neumorphic |
| Design generation | The current Apple HIG (iOS 26 / macOS 26) structure, type ramp, spacing, lists, sidebar, toolbars and controls, with the 26-era touches Flutter does well (translucent blurred bars, rounder grouped corners, capsule buttons, pull-down menus). **No simulated Liquid Glass** (no fake refraction or floating glass bars) |
| Typography and icons | System font (SF Pro) in the Cupertino skin with Apple's own text styles per platform (iOS Large Dynamic Type sizes, macOS built-in sizes; no scaling between them), and `CupertinoIcons`; Inter and Material icons stay in the Neumorphic skin, both selected through the facade (`AppIcons`) |
| Tint | `CupertinoColors.systemBlue`; gains `systemGreen`, losses `systemRed` |
| Navigation | iPhone: translucent tab bar (5 tabs). iPad (≥ 600) and macOS: a sidebar that is either shown or hidden (never a narrow icon rail), toggled from the sidebar header or the page toolbar, plus a content pane |
| Coverage | Every route at parity before the toggle is exposed in release builds (parity is structural: same screens) |
| Charts | Same `fl_chart` widgets, parameterised by a palette supplied by the active skin |
| Availability | Release: iOS and macOS only. Debug: all platforms |
| Testing | Existing suite parameterised by skin, facade catalogue goldens in both skins, registry and import-rule tests |

## 2. Goals and non-goals

**Goals**
- Full feature parity by construction: there is only one set of screens.
- A UI change is made once. Adding or changing a screen never requires a skin-specific edit unless it needs a registered override.
- No visible change to the Neumorphic skin. Existing goldens and tests stay green throughout the migration.
- A live, safe skin switch that never loses data or lock state.

**Non-goals**
- An Android or Material 3 skin; the `macos_ui` package; any change to `domain/` or `data/` (apart from one new settings key).
- Any change to the Luno invariants in `CLAUDE.md` and `SPEC.md` §7A/§7B: read-only by construction, secrets only in `LunoCredentialStore`, never in settings, backups, logs or provider state. Facade widgets must not log or retain field contents.
- Changes to calculations, caching, or request scheduling.

## 3. Skin model

### 3.1 Types and setting
- `enum AppSkin { neumorphic, cupertino }` in `lib/app/app_settings.dart`, with `AppSettings.skinName(AppSkin)` mirroring `themeModeName`.
- `SettingKeys.uiSkin = 'ui_skin'` in `lib/domain/repositories/settings_repository.dart`. Stored values: `'neumorphic'`, `'cupertino'`. Unknown or missing values parse to `null` (unset).
- `AppSettings` gains `final AppSkin? skin;` (null means "never chosen") parsed in `fromMap`.
- The key is exported and restored by `lib/data/backup/backup_service.dart` automatically (everything except `_excludedSettings`). Do not add it to the exclusion list.

### 3.2 Availability
- `cupertinoSkinAvailableProvider` (`Provider<bool>`, in `lib/app/providers.dart`), modelled on `lunoSupportedProvider` so tests can override it:
  `kDebugMode || (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS))`.
- Use `defaultTargetPlatform`, never `dart:io` `Platform`, so it is testable and web-safe.

### 3.3 Effective skin
`effectiveSkinProvider` (`Provider<AppSkin>`) resolves as follows:
1. If Cupertino is not available → `neumorphic`. A backup restored on Windows, Linux or web that contains `cupertino` is ignored; the stored value is kept untouched so a later restore on iOS still works.
2. Else if `settings.skin != null` → that value.
3. Else (unset): `cupertino` if `!settings.disclaimerAccepted` (fresh install), otherwise `neumorphic` (an install that predates this feature).

`WelcomeScreen` persists the effective skin to `ui_skin` when the disclaimer is accepted, so the choice becomes explicit and stable.

### 3.4 Live switching
- Writing `ui_skin` goes through `settingsRepo.set(SettingKeys.uiSkin, ...)`, like other settings.
- `DashfolioApp` rebuilds, swapping `MaterialApp.router` ↔ `CupertinoApp.router`. Both receive the **same** `routerProvider` `GoRouter`, so the current location (for example `/settings`) is preserved. Screens are the same classes in both skins, so route builders do not change.
- Per-branch navigation stacks inside the `StatefulShellRoute` may reset on a switch; this is acceptable. The user must end up on Settings in the new skin.
- Before the write, the settings screen closes any open dialog or sheet it owns, using the dialog's own `BuildContext` (dialogs live on `rootNavigatorKey`; see `CLAUDE.md`).
- Dialogs that own a `TextEditingController` keep disposing it in their own `State`; facade dialog helpers must not dispose caller-owned controllers.
- Lock state, `AppLifecycleListener` and `PrivacyCover` behaviour are identical in both skins. The lifecycle listener stays in `_DashfolioAppState`, above the skin switch, so it is not recreated.
- Theme mode (System/Light/Dark) applies to both skins.

## 4. App root and theming

### 4.1 `lib/app/app.dart`
- `DashfolioApp` remains the single root. `build` switches on `effectiveSkinProvider` and wraps the app in `AppSkinScope(skin: ...)` (see §7.2).
- Neumorphic branch: unchanged (`MaterialApp.router` with `buildTheme`).
- Cupertino branch: `CupertinoApp.router` with the same `routerConfig`, `theme: buildCupertinoTheme(brightness)`, and `localizationsDelegates` including `DefaultCupertinoLocalizations.delegate`, `DefaultMaterialLocalizations.delegate` and `DefaultWidgetsLocalizations.delegate` (so the license page and the documented Material exceptions work).
- Brightness resolves from `settings.themeMode` (`light`, `dark`) or `MediaQuery.platformBrightnessOf` for `system`.
- Same `builder` logic in both branches: show the splash (`AppSplash`, a facade widget) until `ready`; overlay `PrivacyCover` when `!_inForeground && settings.lockEnabled`.
- No `debugShowCheckedModeBanner`.

### 4.2 `lib/design_system/cupertino/cupertino_theme.dart`
- `CupertinoThemeData buildCupertinoTheme(Brightness b)`: `primaryColor: CupertinoColors.systemBlue`, `brightness: b`, default SF text theme (no bundled font; Inter is not applied).
- `CupertinoPalette`: immutable token class of resolved system colors: `label`, `secondaryLabel`, `tertiaryLabel`, `separator`, `background`, `groupedBackground`, `secondaryGroupedBackground`, `fill`, `secondaryFill`, `quaternaryFill`, `barBackground` (translucent, blurred behind), `sidebarBackground`, `accent`, `onAccent`, `gain`, `loss`, `warning`, `chartSeries` (eight system colors).
- `CupertinoTypography` (`CupertinoTypography.of(context)`): Apple's text styles on the system font, one table per platform, no multiplier between them. The platform text scaler still applies on top (Dynamic Type).

  | Style (Apple name) | iOS / iPadOS | macOS | `context.text` slot |
  |---|---|---|---|
  | largeTitle | 34 bold | 26 bold | displayLarge |
  | title1 | 28 bold | 22 bold | displayMedium |
  | title2 | 22 bold | 17 bold | headlineMedium |
  | title3 | 20 semibold | 15 semibold | headlineSmall, titleLarge |
  | headline | 17 bold | 13 bold | titleMedium |
  | rowTitle (emphasised row title) | 15 semibold | 13 semibold | titleSmall |
  | body | 17 | 13 | bodyLarge, bodyMedium |
  | callout | 16 | 13 | labelLarge (semibold) |
  | subheadline (secondary colour) | 15 | 13 | not exposed |
  | footnote (secondary colour) | 13 | 11 | bodySmall |
  | caption1 | 12 medium | 11 medium | labelMedium (semibold) |
  | caption2 (secondary colour) | 11 medium | 10 medium | labelSmall |

  Floors: 11 pt on iOS, 10 pt on macOS. Figures are tabular.
- `CupertinoMetrics.current` (by `defaultTargetPlatform`, so tests can override it): row height 44 / 28, minimum hit size 44 / 24, group radius 12 / 10, control height 34 / 22 (large 50 / 28), navigation icon 22 / 16, in-row icon 18 / 14, switch scale 1 / 0.8, sidebar width 260 on touch devices and a 160 pt minimum on macOS (where the sidebar sizes to its content), progress 4 pt. Static: page margin 16 compact / 20 regular, section gap 24, readable width 720.
- `CupertinoRoot` wraps the app content with the transparent Material host the documented exceptions need.
- These are used **only** inside the Cupertino kit and the facade (§7), never in screens.
- **Rule (enforced by `test/design_system/cupertino_tokens_test.dart`):** the kit has no `fontSize:` or `TextStyle(` literals outside `cupertino_theme.dart`. Every kit widget reads `CupertinoTypography` and `CupertinoMetrics`.

## 5. Routing

Keep **one** `GoRouter`, the existing route tree, paths, redirects and `appRedirect` untouched (`lib/routing/router.dart`, `lib/routing/routes.dart`). Route builders keep returning the same screen classes; screens are skin-neutral.

The only routing changes:
- `errorBuilder` and `SplashScreen` are rewritten with facade widgets (`AppPage`, `AppButton`, `AppSplash`) instead of Material `Scaffold`/`AppBar`/`TextButton`.
- The debug `/gallery` route (`DesignGallery`) shows the facade catalogue and a skin selector (§7.6).
- `StatefulShellRoute.indexedStack` builder still returns `AppShell(navigationShell: shell)`; the shell is skin-neutral (§6).

## 6. Navigation shell

`lib/features/shell/app_shell.dart` stays a single widget. It no longer references `NeuNavBar`/`NeuSideNav` directly; it uses facade navigation primitives (`AppTabBar`, `AppSideNav`, `AppSidebarScope`, `AppScaffold`).

| Context | Neumorphic render | Cupertino render |
|---|---|---|
| width < 600 | `NeuNavBar` (bottom) | `CupertinoTabBar` (translucent, blurred), 5 items |
| 600–1199, iOS | `NeuSideNav` (rail) | Source-list sidebar (260 pt), shown unless hidden |
| ≥ 1200 | `NeuSideNav` (sidebar, collapsible) | Source-list sidebar (260 pt on iOS; on macOS as wide as its widest row, at least 160 pt), shown unless hidden |
| macOS, any width | Same as the width rules above | Sidebar always (never a bottom bar), inline toolbar page header |

- The `ScreenSize` breakpoints in `lib/features/common/breakpoints.dart` are reused. The macOS rule is a Cupertino-kit rule (`appUsesBottomBar`).
- Tab items map to `StatefulNavigationShell` branches in order: Dashboard, Portfolios, Markets, Income, Settings. Cupertino icons: `chart_pie`, `briefcase`, `graph_square`, `money_dollar_circle`, `gear`. Selecting the current tab pops to its root (`goBranch(index, initialLocation: true)`).
- **Cupertino sidebar:** on macOS the width is computed from the content (`IntrinsicWidth`, the widest of the nav labels and the header, minimum 160 pt), so nothing is clipped or overlaps at any text size (`test/app/macos_sidebar_test.dart`). Rows are body-sized (17 pt, 44 pt tall on iOS; 13 pt, 32 pt on macOS) with accent-coloured symbols. The selection is a rounded fill (accent wash on iPadOS, neutral fill on macOS) and hover and keyboard focus are shown on macOS. The header carries the logo, the app name and the hide-sidebar button. When hidden, the sidebar occupies no space and the page toolbar shows a show-sidebar button (`AppSidebarScope` hands the hidden state and toggle to pages). The Neumorphic skin ignores the scope and keeps its own rail/sidebar.
- Collapse state persists in `SettingKeys.sidebarCollapsed`, shared by both skins. In the Cupertino skin it means "sidebar hidden" at every width.
- Existing Cmd/Ctrl shortcuts and the search palette stay in `AppShell`.
- Page chrome is `AppPage` (§7.3). `PageScaffold` and `SectionTitle` in `lib/features/common/page_scaffold.dart` are thin wrappers over `AppPage`/`AppSectionHeader` so existing call sites keep working.

## 7. Facade architecture

### 7.1 Layers and folders

```
lib/design_system/
  app/            facade: skin-neutral widgets + barrel app_ui.dart   <- the ONLY design-system import in screens
  neu/            Neumorphic kit (the existing neu_*.dart, tokens, theme, inset shadow, contrast; moved here)
  cupertino/      Cupertino kit (new)
  design_system.dart   deprecated barrel, removed at the end of P2
```

- Screens in `lib/features/`, `lib/app/` and `lib/routing/` import **only** `design_system/app/app_ui.dart` (plus domain/data/providers). They must not import `neu/` or `cupertino/`.
- The kits import nothing from each other. The facade imports both kits.
- Neumorphic tokens (`NeuTheme`, `context.neu`) are an implementation detail of the Neu kit and the Neumorphic chart palette; screens use `AppTheme` accessors (§7.5) instead.
- Moving `neu_*.dart` into `neu/` is a mechanical rename done in P2; behaviour and goldens must not change.

### 7.2 Skin plumbing
- `AppSkinScope` is an `InheritedWidget` holding the `AppSkin`, set by the root. `AppSkin.of(context)` is read **only** by facade widgets and `SkinBuilder`; screens never read it.
- `SkinBuilder({required neumorphic, required cupertino})` is the sole sanctioned way for screen code to diverge (§8).
- Facade widgets are plain widgets (`StatelessWidget`/`StatefulWidget`) that build the matching kit widget. Imperative helpers (`showAppDialog`, `showAppConfirm`, `showAppSheet`, `showAppMenu`, `showAppDatePicker`, `showAppToast`) read the skin from the passed `BuildContext` and dispatch to the kit.

### 7.3 Facade catalogue

API rule: each facade widget exposes the **union** of what screens need, in neutral terms (labels, callbacks, `AppIcon` identifiers, enums). Neither kit's types (`Widget` subclasses, `CupertinoIcons`, `Icons`, Neu enums) leak into the API.

Layout-level primitives carry the idiomatic differences, so screens stay identical:

| Facade | Neumorphic render | Cupertino render |
|---|---|---|
| `AppPage` (title, actions, `onRefresh`, `status`, `width`, scrollable body) | `PageScaffold` (title row, `UpdatedChip`, `RefreshIndicator`) | iOS: `CupertinoSliverNavigationBar` (large title, translucent blurred bar, hairline only once scrolled), status under the title, `CupertinoSliverRefreshControl`; the refresh button is omitted when pull-to-refresh is available. macOS: no large title; a 52 pt inline toolbar (title and status on the left, actions on the right, show-sidebar button when hidden, hairline on scroll). `width: readable` keeps forms to 720 pt (Neumorphic ignores it) |
| `AppSection` (title, footer, trailing, children, `bare`) | `NeuCard` with `SectionTitle` (`bare`: no card, a muted label and evenly spaced children, for forms inside a sheet) | Inset-grouped section: header above the box (footnote on iOS, headline on macOS), `groupRadius` box, hairline-separated rows, footer below. `AppButtonGroup` children become action rows; `AppGap`/`AppSectionItem` spacing is dropped. Provides `CuSectionScope` so fields, selects and inset surfaces render as inline rows |
| `AppFormRow` (label, description, control, `wide`) | Label and control side by side, stacked below 520 pt | Label (body) and optional description (footnote) with the control trailing; a `wide` control (segmented) stacks under the label below 520 pt |
| `AppField` (label, child, errorText) | Muted label above the child | Row with the label on the left inside a section; footnote label above outside one |
| `AppButtonGroup` (buttons) | `Wrap` of buttons | One accent action row per button inside a section (red for danger); a `Wrap` of capsule buttons elsewhere |
| `AppSheetScaffold` (title, children, confirm/destructive actions, footer) | Title row with a close button, evenly spaced children, full-width confirm button | Sheet bar (Cancel, title, bold one-word confirm via `shortConfirmLabel`, spinner while busy) over grouped sections; the destructive action is its own red row |
| `AppRow` (title, subtitle, leading, trailing, onTap) | Row inside `NeuCard`/`NeuPressable` | Row with body and footnote text and a chevron when tappable |
| `AppCard` (free-form content block, e.g. chart or summary) | `NeuCard` | Grouped-background rounded container (no shadow) |
| `AppButton` (`kind`: normal, primary, danger) / `AppIconButton` | `NeuButton` / `NeuIconButton` | Capsule `CupertinoButton`: filled (primary), tinted (normal; neutral gray on macOS) or red-tinted (danger; never a solid red fill). Inside an alert (`CuActionScope`) buttons render as edge-to-edge alert actions (primary bold, danger red) |
| `AppTextField` / `AppFormRow` | `NeuTextField` | `CupertinoTextField` / `CupertinoTextFormFieldRow` |
| `AppSelect<T>` (replaces `NeuDropdown`; `width` is Neumorphic-only) | `NeuDropdown` | Pop-up button (value and up/down chevrons) opening a `CupertinoMenuAnchor` pull-down menu anchored to it, with a check on the current value; inside a section a plain trailing value. More than 12 options on touch devices (currencies) open a wheel picker |
| `showAppDatePicker` | Material `showDatePicker` styled by theme | `CupertinoDatePicker` in a bottom popup (touch) or a centred popup (macOS), with Cancel / Done |
| `AppSegmented<T>` | `NeuSegmentedControl` | `CupertinoSlidingSegmentedControl` with one fixed label size. When the segments do not fit, or there are more than five on a phone, it becomes a pull-down pop-up button showing the current value, so every option stays reachable |
| `AppSwitch` | `NeuSwitch` | `CupertinoSwitch` (scaled to 0.8 on macOS) |
| `AppProgress` (linear), `AppSpinner` | `NeuProgress`, `CircularProgressIndicator` | 4 pt progress bar, `CupertinoActivityIndicator` |
| `AppChip` | `NeuChip` | Capsule with a caption1 label |
| `showAppConfirm`, `showAppDialog`, `AppDialog` | `confirmNeu`, `showNeuDialog`, `NeuDialog` | `showAppConfirm`: `CupertinoAlertDialog`. `AppDialog`: an alert surface (`CupertinoPopupSurface`) with a centred headline, the content, then hairline-separated alert actions (side by side when two, stacked otherwise); width 270–520 on iOS, up to 420 on macOS |
| `showAppMenu`, `AppMenuButton` (replaces `PopupMenuButton`, `showMenu`) | Material popup menu styled by theme | `CupertinoMenuAnchor` pull-down menu (anchored to the button, or opened at a pointer or long-press position); destructive items are red and separated. The overflow icon is `ellipsis.circle`. Action sheets are used only to confirm destructive actions |
| `showAppSheet`, `AppSheetScaffold` (replaces `showAdaptiveSheet`) | Dialog when wide (`kSheetDialogBreakpoint = 600`), bottom sheet when compact | `CupertinoSheetRoute` on iPhone (the previous page peeks above it), a centred form sheet (≤ 560 wide, ≤ 88% high) on iPad/macOS; both host the sheet bar scaffold |
| `showAppToast` (replaces `SnackBar`) | `SnackBar` through `ScaffoldMessenger` | Compact blurred capsule HUD (top on iOS, bottom on macOS; auto-dismiss, `Semantics(liveRegion: true)`) |
| `AppEmptyState`, `AppErrorRetry`, `AppSkeleton`, `AppCardSkeleton`, `AppSplash` | `neu_states.dart` | Content-unavailable layout: secondary-coloured symbol, title2 title, subheadline message, filled button; redacted-fill skeletons |
| `AppMoneyText`, `AppChangeBadge` | `MoneyText`, `ChangeBadge` | Same formatting, `CupertinoPalette` gain/loss colors |
| `AppTable<T>` (columns, rows, onRowTap) | `NeuDataTable` | Aligned-column list with a caption1 sortable header, 56 pt rows (32 pt on macOS) and a quaternary-fill hover |
| `AppReorderableList` | `ReorderableListView` | `ReorderableListView` in `Material(type: transparency)` with Cupertino drag handles (documented exception, §7.7) |
| `AppSearchField` | `NeuTextField` with search icon | `CupertinoSearchTextField` |
| `AppTooltip` | Material `Tooltip` | `Semantics` label only (plus long-press context menu where an action exists) |
| `AppTabBar`, `AppSideNav`, `AppSidebarScope` | `NeuNavBar`, `NeuSideNav` | Translucent `CupertinoTabBar`, source-list sidebar (§6) |
| `AppIcon` (enum) and `AppIcons.of(...)` | Material `Icons.*` | `CupertinoIcons.*` |
| `AppDivider`, `AppSectionHeader` | Divider, `SectionTitle` | Hairline separator, section header |

### 7.4 Replacing direct Material use in screens
All of these are removed from `lib/features/` and `lib/routing/` and replaced by facade equivalents: `showDialog`, `showModalBottomSheet`, `PopupMenuButton`/`showMenu`, `showDatePicker`, `SnackBar`/`ScaffoldMessenger`, `ListTile`, `RefreshIndicator`, `Tooltip`, `Scaffold`/`AppBar`, `TextButton`, `Divider`, `CircularProgressIndicator`, `ReorderableListView`, `Icons.*`. The one pass that does this is P2 (§13).

### 7.5 Theme access for screens
- `context.neu` / `context.text` are replaced in screens by `AppTheme.of(context)`, a small skin-neutral accessor exposing spacing constants, semantic colors (`gain`, `loss`, `muted`, `surface`, `accent`), text styles and the `ChartPalette` (§10). Each kit supplies its own values.
- Spacing constants (`NeuTheme.s4`, `radiusM`, …) get neutral aliases on `AppTheme` (`AppSpace.s4`, …) with identical values in both skins unless a kit overrides them (for example macOS density).

### 7.6 Gallery
`DesignGallery` (`lib/design_system/gallery.dart`, debug `/gallery`) renders every facade widget, with a toggle to render the whole catalogue in either skin. It is the visual baseline for the golden tests (§12).

### 7.7 Rules
1. Screens import only `design_system/app/app_ui.dart`.
2. Screens never read `AppSkinScope`, check the platform for styling, or branch on the skin. The only exception is a registered `SkinBuilder` (§8).
3. Facade APIs are skin-neutral. A facade widget that cannot express a screen's need is extended (new neutral parameter) rather than bypassed.
4. Cupertino kit and facade-Cupertino branches use no `Neu*` identifiers. Neu kit code uses no Cupertino identifiers.
5. The Cupertino kit uses no Material widgets except these documented exceptions: `ReorderableListView` (wrapped in `Material(type: MaterialType.transparency)` with Cupertino drag handles), the license page (pushed inside a Material `Theme` wrapper), and `fl_chart` internals.
6. Minimum interactive size 44 × 44 pt on iOS; 28 pt pointer targets allowed on macOS if keyboard reachable.
7. Dialogs and sheets are shown on the root navigator.
8. Every new facade widget must be added to the gallery and golden catalogue in both skins before it is used in a screen (`AppCatalogue`; the grouped-form primitives are in `AppFormCatalogue` so the original catalogue goldens stay unchanged).
9. Kit text sizes and dimensions come only from `CupertinoTypography` and `CupertinoMetrics` (enforced by test).
10. Grouped content is written once as `AppSection` / `AppFormRow` / `AppField` / `AppButtonGroup`. Spacers between section children use `AppGap` / `AppSectionItem` so the Cupertino skin can drop them. Do not build a card with a heading and hand-made label/control rows in a screen.
11. A destructive action is red text or a red tint, never a solid red fill. Alerts follow the alert-action layout through `CuActionScope`.
12. Pull-down menus anchor to their control; action sheets confirm destructive actions only.

## 8. Override policy and registry

A screen may diverge by skin only through `SkinBuilder(neumorphic: ..., cupertino: ...)`, only when no neutral facade parameter can express the need, and only with a small, local widget. Each use must be recorded here.

| ID | Location | Why a facade primitive does not suffice |
|---|---|---|
| O1 | `features/lock/lock_screen.dart`: PIN pad | iOS-style round keypad vs neumorphic keys; content is data-driven (digits, callbacks) and tiny |
| O2 | `features/holdings/holdings_table.dart`, `features/import_export/import_screen.dart` preview | Only if `AppTable` cannot express the columns; otherwise remove this entry |
| O3 | `features/settings/settings_screen.dart`: license page launch | Material `Theme` wrapper only needed in the Cupertino skin |

Rules:
- Adding an override requires adding a row to this table in the same change.
- `test/design_system/skin_registry_test.dart` scans `lib/features/`, `lib/app/` and `lib/routing/` for `SkinBuilder(` and `AppSkinScope`/`AppSkin.of` usages and fails when the set of files differs from the registry above (parsed from a `skin_registry.dart` constant list that mirrors this table).
- Prefer extending the facade over adding an override. Review any new override as a smell.

## 9. Screen migration

Every screen is migrated **in place** from `Neu*`/Material to `App*`. There are no new screen files and no `cupertino/` screen folders. Settings ▸ Appearance is edited once.

| Route / area | File(s) (existing) | Migration notes |
|---|---|---|
| App root, splash, error | `app/app.dart`, `routing/router.dart` | §4, §5 |
| Shell | `features/shell/app_shell.dart`, `search_palette.dart` | Facade nav (§6); search palette uses `AppDialog` + `AppSearchField` |
| `/dashboard` | `features/dashboard/dashboard_screen.dart`, `dashboard_widgets.dart`, `dashboard_cards.dart` | `AppPage`, `AppSection`/`AppCard`, `AppSegmented`, `AppChangeBadge`, `AppMoneyText`; charts via palette |
| `/portfolios` | `features/portfolios/portfolios_screen.dart` | `AppSection`/`AppRow` with swipe/context actions via `AppRow` parameters, `AppReorderableList`, `AppMenuButton`, `showAppConfirm` |
| `/portfolios/:id` | `features/portfolios/portfolio_detail_screen.dart` | `AppSegmented` as tabs, `AppRow` replaces `ListTile` |
| `/portfolios/:id/holdings/:symbol` | `features/holdings/holding_detail_screen.dart`, `holdings_table.dart` | `AppTable`; menu via `showAppMenu`; O2 if needed |
| Portfolio form (sheet) | `features/portfolios/portfolio_form.dart` | `showAppSheet`/`AppFormSheet`, `AppFormRow`, `AppSelect`, `AppButton` |
| Transaction form (sheet) and list | `features/transactions/transaction_form.dart`, `transactions_list.dart` | `AppFormSheet`, `AppFormRow`, `AppSelect`, `AppDateField` (replaces `showDatePicker`), `AppChip`, `showAppConfirm` |
| `/markets`, `/markets/watchlists/:id` | `features/markets/markets_screen.dart` | `AppSearchField`, `AppReorderableList`, `AppMenuButton`, `AppDialog`, `showAppConfirm` |
| `/markets/quote/:symbol` | `features/markets/quote_screen.dart`, `quote_chart_card.dart` | `AppSegmented`, `AppSkeleton`, palette charts |
| `/income` | `features/income/income_screen.dart` | `AppSection`/`AppRow`, `AppProgress`; bar chart via palette |
| `/settings` | `features/settings/settings_screen.dart` | `AppSection`/`AppRow` with `AppSwitch`/`AppSelect`/`AppSegmented`/`AppButton`; **Interface style** row (§9.1); O3 |
| `/settings/import` | `features/import_export/import_screen.dart` | `AppSelect` ×5, `AppTable`, `AppSwitch`, `AppTextField`, `AppChip`; O2 if needed |
| `/settings/luno`, `/connect`, `/:id` | `features/luno/luno_connections_screen.dart`, `luno_connection_screen.dart`, `luno_connect_screen.dart`, `luno_actions.dart`, `luno_widgets.dart`, `synced_transaction_sheet.dart` | Facade only; same native-only gating (`lunoSupportedProvider`); credential fields use `AppTextField(obscure: true)` and no facade code logs or retains values |
| `/welcome` | `features/settings/welcome_screen.dart` | `AppPage`, `AppSelect`, `AppButton`; persists the effective skin (§3.3) |
| `/lock` | `features/lock/lock_screen.dart` | `AppTextField`, `AppButton`, `AppDialog`; O1; `PrivacyCover` via `AppSplash`-style cover |
| Shared helpers | `features/common/page_scaffold.dart`, `symbol_search.dart`, `refresh_widgets.dart`, `small_widgets.dart` | Facade replacements; `SnackBar` → `showAppToast` |
| `/gallery` (debug) | `design_system/gallery.dart` | §7.6 |

Migration pattern (applied to Settings, the portfolio and transaction sheets): a hand-built `section()` or card header with label/control rows becomes `AppSection` + `AppFormRow` (`wide: true` for a segmented control) + `AppButtonGroup`; a sheet's header and footer become `AppSheetScaffold` with `AppSection(bare: true)` children and a `shortConfirmLabel`. Charts, summaries and wizard steps stay `AppCard`. The Neumorphic composition of each primitive is the code it replaced, so that skin is unchanged.

### 9.1 Settings ▸ Appearance: "Interface style"
- One row in the single Settings screen, next to the Theme control: `AppSegmented<AppSkin>` with **Neumorphic** and **Cupertino**.
- Visible only when `cupertinoSkinAvailableProvider` is true. The control reflects `effectiveSkinProvider`.
- Caption: "Choose the look of the app. Applies immediately."
- Selecting an option follows §3.4.

## 10. Charts

Charts under `lib/features/charts/` (`value_history_chart.dart`, `price_chart.dart`, `allocation_donut.dart`, `chart_utils.dart`) and the bar chart in `income_screen.dart` stop reading `context.neu` directly.

- `ChartPalette` (plain Dart: `series`, `grid`, `axisLabel`, `gain`, `loss`, `tooltipBackground`, `tooltipText`, `labelStyle`) in `lib/features/charts/chart_palette.dart`.
- Each kit supplies one (`ChartPalette.neumorphic(NeuTheme)`, `ChartPalette.cupertino(CupertinoPalette)`); screens and charts read it through `AppTheme.of(context).chartPalette`.
- Neumorphic output must be pixel-identical (existing goldens and `dashboard_chart_test.dart` stay green).
- Chart containers are `AppCard`/`AppSection`, so the Cupertino skin shows no neumorphic backgrounds. Interaction is unchanged.

## 11. Accessibility

- Text scale: layouts hold up at 1.5× in both skins (`test/app/responsive_test.dart`). The Cupertino skin honours the platform text scaler on top of the Apple text styles and never goes below 11 pt (iOS) or 10 pt (macOS).
- VoiceOver: every icon-only `AppIconButton` requires a `semanticLabel` parameter (enforced by the facade signature); toasts use live regions; sections expose headers; order follows visual order.
- Gain/loss are never conveyed by color alone (`AppChangeBadge` keeps sign and arrow).
- Hit targets: 44 pt on iOS; 24–32 pt pointer targets on macOS (keyboard reachable, with hover and focus states).
- macOS: full keyboard navigation and visible focus, sidebar reachable by keyboard.
- Reduced motion: respect `MediaQuery.disableAnimations` for the skin switch and chart animations.
- `AppTooltip` must always provide a semantic label so the Cupertino fallback loses nothing for assistive tech.

## 12. Testing

### 12.1 Harness
- `test/support/app_harness.dart`: `AppHarness.create` gains `AppSkin skin = AppSkin.neumorphic`, overriding `cupertinoSkinAvailableProvider` (true) and the stored `ui_skin`. The default stays Neumorphic so existing tests are unchanged.
- Load fonts as today with `loadAppFonts()`. Cupertino goldens use the test engine's system-font stand-in; record this in the golden README and keep goldens macOS-generated.

### 12.2 Tests
- **Responsive** (`test/app/responsive_test.dart`): every route × phone/tablet/desktop × light/dark × **skin**, same screens; no overflow or exceptions; 1.5× text scale for both skins.
- **Flow tests in both skins**: `transaction_flow_test.dart`, `import_settings_test.dart`, `app_flow_test.dart`, lock flow, `luno_ui_test.dart` parameterised by skin over the same test body. Because screens are shared, one test body covers both skins.
- **Finders**: tests find widgets by `Key` or by `App*` type, never by `Neu*` or `Cupertino*` type. The five existing tests that find `NeuSideNav`, `NeuNavBar`, `NeuButton`, `NeuSwitch` or `NeuSurface` are updated in P2 to use `AppSideNav`, `AppTabBar`, `AppButton`, `AppSwitch` and keys.
- **Skin model** (`test/app/skin_test.dart`): parsing; availability matrix across platforms and `kIsWeb`; effective-skin resolution (fresh install → Cupertino; install with the disclaimer accepted and no key → Neumorphic; explicit choice wins; unavailable → Neumorphic with the stored value untouched).
- **Skin toggle** (`test/app/skin_toggle_test.dart`): from Settings, switching to Cupertino swaps the root to `CupertinoApp`, the location remains `/settings`, the setting persists, switching back works, and the row is hidden when unavailable.
- **Welcome persistence**: accepting the disclaimer writes the effective skin.
- **Backup**: export then restore round-trips `ui_skin`; restoring `cupertino` where unavailable yields Neumorphic without deleting the value.
- **Facade contract** (`test/design_system/app_facade_test.dart`): each facade widget builds and behaves equivalently (same callbacks, same semantics labels, same disabled/error states) in both skins.
- **Import rules** (`test/design_system/import_rules_test.dart`): files under `lib/features/`, `lib/app/` and `lib/routing/` must not import `design_system/neu/` or `design_system/cupertino/`, must not use `Neu*` identifiers, and must not use the Material widgets listed in §7.4. `neu/` must not import `cupertino/` and vice versa. Allow-list: the root files that construct `MaterialApp`/`CupertinoApp` and `buildTheme`/`buildCupertinoTheme`.
- **Override registry** (`test/design_system/skin_registry_test.dart`): see §8.
- **Tokens** (`test/design_system/cupertino_tokens_test.dart`): the iOS and macOS type tables, the platform floors, the row and hit metrics, and a source scan that fails on `fontSize:` / `TextStyle(` literals in the Cupertino kit.
- **Form primitives** (`test/design_system/app_form_test.dart`, both skins): `AppSection` rows, footer and button group; `AppSegmented` with seven options stays fully reachable on a phone (pop-up menu in Cupertino); `AppSelect` picks a value; `AppSheetScaffold` confirm, destructive action and footer note.
- **Luno safety**: `test/data/luno/luno_write_guard_test.dart` keeps passing. Credential fields in the facade must not appear in logs; add a test that `AppTextField(obscure: true)` never reveals its text in semantics.
- **Goldens** (tag `golden`, macOS-generated, light and dark): the facade catalogue (gallery) in **both skins**; plus a few key screens in the Cupertino skin (shell on phone and desktop, Settings, Dashboard, Transaction form, Lock). Existing Neumorphic goldens must remain byte-identical after the P2 migration. Cupertino goldens use a `cupertino_` prefix in `test/design_system/goldens/`. Screen goldens (`test/app/cupertino_screens_golden_test.dart`) cover Dashboard, Portfolios and Settings on phone, tablet-width and macOS, light and dark; sheet and dialog goldens (`test/app/cupertino_sheets_golden_test.dart`) cover the transaction and portfolio sheets and an alert on phone and macOS; `form_catalogue_*` covers the grouped-form primitives. Tests that tap a sheet's confirm button use `byConfirm` (the Cupertino bar shows "Add", "Save", "Create"), and `byAction('Close')` also matches the Cupertino "Cancel".

### 12.3 Gates
`flutter analyze` at zero issues (CI uses `--fatal-infos`), `dart format` at page width 140, `flutter test --exclude-tags golden` green, goldens green on macOS CI, coverage gates unchanged (domain 90%, overall 70%).

## 13. Implementation phases

Each phase ends with a green build (analyze, format, tests). The Neumorphic skin must look and behave identically at the end of every phase.

| Phase | Scope | Exit criteria |
|---|---|---|
| P1 | Skin model and providers (§3), `AppSkinScope`, `SkinBuilder`, `CupertinoApp` root with placeholder content, Cupertino theme/palette (§4); the Interface style row appears only when `kDebugMode` | Switching works in debug; Neumorphic untouched |
| P2 | Create the facade (`design_system/app/`) with only the Neumorphic backend; move `neu_*` into `neu/`; migrate **every** screen to `App*` (§7.4, §9); replace direct Material calls; update finders in tests | Existing tests and goldens green and unchanged; import-rule test passes |
| P3 | Cupertino kit and facade Cupertino branches; gallery in both skins; facade contract test | Catalogue renders in both skins, light and dark |
| P4 | Shell and navigation primitives (§6), `AppPage` Cupertino render with refresh | Tab bar, sidebar, pull-to-refresh work |
| P5 | Registered overrides (§8), `ChartPalette` (§10), `AppTable` Cupertino render | Registry test passes; Neumorphic charts pixel-identical |
| P6 | Full skin-parameterised test matrix and goldens (§12) | CI green |
| P7 | Remove the `kDebugMode` gate so the row follows §3.2; update `SPEC.md` §11/§18 and `README.md`; delete the deprecated `design_system.dart` barrel | Acceptance checklist (§14) complete |

P2 is the largest and riskiest step because it touches every screen, but it is skin-agnostic, behaviour-preserving, and fully covered by the existing tests and goldens.

## 14. Acceptance criteria

- [ ] There is exactly one set of screens; no `cupertino/` screen folders; no screen file imports `design_system/neu/` or `design_system/cupertino/`.
- [ ] No screen branches on the skin except the registered overrides in §8 (enforced by test).
- [ ] Every route in `lib/routing/router.dart` renders in both skins with no layout overflow, in light and dark, at phone, tablet and desktop sizes, and at 1.5× text scale.
- [ ] On iOS and macOS release builds, Settings ▸ Appearance shows Interface style; on Windows, Linux and web release builds it does not.
- [ ] Switching skin is live, keeps `/settings`, persists across launches, and never affects lock state, data or Luno connections.
- [ ] Fresh iOS/macOS install starts in Cupertino; an install that already accepted the disclaimer stays Neumorphic until changed.
- [ ] iPhone uses the tab bar; iPad and macOS use the sidebar; macOS never shows a bottom tab bar.
- [ ] The Cupertino skin uses system fonts, `CupertinoIcons`, `systemBlue` tint and system gain/loss colors.
- [ ] Neumorphic skin behaviour and existing goldens are unchanged.
- [ ] Luno remains read-only and credential-safe; `luno_write_guard_test.dart` passes.
- [ ] Facade catalogue goldens exist in both skins; analyze has zero issues; coverage gates are met.
- [ ] `SPEC.md` §11 and §18 and `README.md` describe the facade and the skin.

## 15. Risks and open items

- **Migration size (P2)**: roughly 300 `Neu*` call sites across about 30 files, plus the direct Material calls in §7.4. Mitigation: mechanical, behaviour-preserving, protected by the existing tests and goldens, and done before any Cupertino work.
- **Lowest-common-denominator facade**: a facade can force both skins into the same shape. Mitigation: facade primitives are layout-level (`AppPage`, `AppSection`, `AppRow`, `AppFormSheet`, `AppTable`) and carry the idiomatic differences; the Cupertino kit may render a very different structure from the same neutral input.
- **Facade API creep**: every screen need becomes a facade parameter. Mitigation: parameters stay neutral and semantic, are shown in the gallery, and the facade contract test covers both skins.
- **Overrides erode the single tree**: mitigated by the registry test and the review rule in §8.
- **Tables**: Cupertino has no data table; `AppTable` renders grouped rows on iPhone and an aligned-column list on iPad and macOS. If it cannot express holdings or the import preview, register O2.
- **Toasts**: `CupertinoApp` has no `ScaffoldMessenger`; `showAppToast` covers both skins.
- **Branch stack reset on skin switch**: accepted. Revisit only if the router location is lost.
- **Golden fidelity**: SF fonts are unavailable to the test engine; Cupertino goldens guard layout, not typography.
- **macOS look**: Flutter's `cupertino` library with density adjustments, not native AppKit controls. It reads as iOS-styled on macOS by design.
- **Reorder exception**: `ReorderableListView` is the only sanctioned Material widget in the Cupertino kit besides the license page and `fl_chart`.

## 16. File and folder summary

New:
```
lib/design_system/app/                       facade widgets (incl. `app_form.dart`: AppSection, AppFormRow, AppField, AppButtonGroup, AppSheetScaffold), AppTheme, AppIcons, SkinBuilder, AppSkinScope, barrel app_ui.dart
lib/design_system/cupertino/                 Cupertino kit: theme (palette, `CupertinoTypography`, `CupertinoMetrics`), buttons, controls, inputs, menus (`cu_menu.dart`), sections and form rows (`cu_section.dart`), navigation and page chrome, overlays and sheet scaffold, states, table
lib/design_system/neu/                       existing neu_* files moved here (no behaviour change)
lib/app/skin.dart                            effectiveSkinProvider, cupertinoSkinAvailableProvider helpers
lib/features/charts/chart_palette.dart
test/app/skin_test.dart, skin_toggle_test.dart
test/design_system/app_form_test.dart, cupertino_tokens_test.dart, import_rules_test.dart, skin_registry_test.dart, cupertino goldens (screens, sheets, form catalogue)
```

Modified:
```
lib/app/app.dart, app_settings.dart, providers.dart
lib/domain/repositories/settings_repository.dart    SettingKeys.uiSkin
lib/routing/router.dart                             facade error/splash only
lib/features/**                                     Neu*/Material -> App* (same files, no new screens)
lib/features/charts/*.dart, income_screen.dart      palette via AppTheme
lib/design_system/gallery.dart                      facade catalogue + skin toggle
test/support/app_harness.dart, test/app/responsive_test.dart and flow tests
SPEC.md (§11, §18), README.md
```

## 17. Implementation status and deviations

The HIG revamp described in §18 is built and tested (tokens, kit, new facade primitives, Settings and form-sheet migration, macOS goldens; `flutter test integration_test/app_flow_test.dart -d macos` passes in both skins). Original build: skin model and providers, the `App*` facade with both kits, every screen migrated in place, the live toggle in Settings, Cupertino shell (tab bar, sidebar), page chrome, dialogs, sheets, menus, toasts, tables. The responsive matrix, skin toggle, default-skin and registry/import-rule tests pass in both skins; flow tests run in both skins.

Deviations from the text above:
- **O3 dropped:** the licences page is a facade call (`showAppLicenses`), so no override is needed. The registry (`kSkinOverrides`) is currently empty.
- **Select threshold:** `AppSelect` opens an anchored pull-down menu; on touch devices a list of more than 12 options (currencies) opens a wheel picker instead (on macOS the menu scrolls). The Luno currency-change flow test drives the wheel by dragging.
- **No debug gate phase:** the Interface style row follows `cupertinoSkinAvailableProvider` directly.
- **Test fonts:** `.SF Pro` families are stood in by Inter in tests (`test/support/fonts.dart`).
- **Type scale:** superseded by the HIG revamp (§4.2, §18): the Cupertino skin uses Apple's own text styles per platform instead of the Neumorphic scale.

Also done since: the macOS sidebar-at-every-width rule (`appUsesBottomBar`), charts read the skin's series colors (`AppTheme.chartSeries`), the `ui_skin` backup round-trip test, `AppCatalogue` (every facade widget) with goldens in both skins and both themes, the O1 PIN-pad override (registered in `kSkinOverrides`), full-screen Cupertino goldens (Dashboard, Portfolios, Settings; phone and desktop; light and dark; `test/app/cupertino_screens_golden_test.dart`), and the Luno currency-change flow test now runs in both skins (the wheel picker is driven by a drag). `flutter build macos --debug` succeeds.

Chart styling: series colors and tooltip colors come from `AppTheme` (`chartSeries`, `tooltipBackground`, `tooltipForeground`), text from the skin's text scale, so charts render with system colors and the system font in the Cupertino skin. Chart geometry and interaction are shared by both skins by design.

Run for real (`integration_test/app_flow_test.dart`): on the macOS app, the iPhone 17 simulator and the iPad Pro 13" simulator, both skins complete onboarding, adding a purchase and seeing the valued holding; a fresh install starts in Cupertino and navigates every tab without layout exceptions; the live interface-style toggle works. On devices the harness keeps the real view (`AppHarness.pump(size: null)`): overriding the view size and pixel ratio detaches the app from the real screen, which had made the form fields untappable in earlier phone runs (a harness artifact, not an app bug).

Not exercised: a physical iPhone/iPad (skipped on request; run `flutter test integration_test/app_flow_test.dart -d <device>` once signing is set up), and manual use by a person beyond the automated runs.

## 18. HIG compliance audit and revamp

The Cupertino skin was audited against the current Apple Human Interface Guidelines (iOS / iPadOS / macOS 26) and reworked. Each finding, its resolution and what remains:

| # | Finding | Resolution |
|---|---|---|
| 1 | The macOS type ramp was the iOS ramp multiplied by 13/17 (captions fell to 8–9 pt) and kit widgets hard-coded 11–17 pt literals, so sizes disagreed between widgets | `CupertinoTypography` (§4.2): one table per platform, no multiplier, floors of 11 / 10 pt; the kit has no size literals (test-enforced) |
| 2 | Settings, Luno and forms were cards containing a heading, label-over-control rows and filled gray selects | `AppSection` / `AppFormRow` / `AppField` / `AppButtonGroup`: inset-grouped sections, trailing controls and pop-up values, action rows. Settings and both sheets migrated; wizard steps and charts remain cards |
| 3 | The seven-option range selector was clipped on iPhone and `FittedBox` shrank segment labels unevenly | One fixed segment label size; segments that do not fit (or more than five on a phone) become a pull-down pop-up button |
| 4 | macOS got iOS chrome: large-title bars, an icon rail, bottom action sheets and popups | Inline 52 pt toolbar, shown/hidden sidebar with neutral selection and hover, 24–32 pt controls, switch at 0.8, anchored menus, toast at the bottom |
| 5 | Menus and selects were action sheets; the overflow icon was vertical dots | `CupertinoMenuAnchor` pull-down menus anchored to the control; `ellipsis.circle`; action sheets only confirm destructive actions |
| 6 | Sheets were a hand-made popup with an X button and a bottom button | `CupertinoSheetRoute` / centred form sheet with a sheet bar (Cancel, title, bold confirm, busy spinner) over grouped sections; destructive action as a red row |
| 7 | Dialogs used a custom `Wrap` of filled buttons | Alert layout: centred headline, hairline-separated alert actions (default bold, destructive red) |
| 8 | Buttons were radius-8 and danger was solid red | Capsule buttons; tinted normal, filled primary, red-tinted danger; heights from the platform metrics |
| 9 | Opaque navigation bar, duplicated refresh button, accent-coloured empty-state icon, 6 pt progress, heavy toast, 1360 pt wide forms, accent-wash sidebar labels | Translucent blurred bars with a hairline on scroll, refresh button only without pull-to-refresh, secondary-coloured symbols, 4 pt progress, capsule HUD toast, `AppPage.width: readable` (720 pt) for Settings, neutral sidebar selection on macOS |

Remaining deviations (by design):
- **No Liquid Glass.** Bars are translucent and blurred, but there is no refraction, floating glass tab bar or morphing toolbar.
- **Flutter `cupertino` widgets, not AppKit controls.** macOS reads as iOS-styled with macOS density, toolbars and sidebars; no native vibrancy, no `NSToolbar`.
- **Date picker on macOS** is a centred popup with the wheel-style `CupertinoDatePicker`, not an anchored calendar popover.
- **Dialog bodies are left-aligned** when a screen passes a start-aligned column; the headline and actions follow the alert layout.
- **iPad width 600–1199** shows the 260 pt sidebar by default (hide it from the toolbar) rather than starting hidden in portrait.
- **Wizard and summary cards** (import, Luno connect, dashboard) stay `AppCard` blocks; they use the shared type tokens but are not grouped lists.
- Simulated Dynamic Type beyond the platform text scaler is not provided. The responsive test checks 1.5× text.

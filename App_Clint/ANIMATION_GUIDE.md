# Flutter Animate Animation Guide

This guide documents the animation pattern used throughout the app for consistent, polished UI animations.

## Package

We use the `flutter_animate` package for declarative animations:

```yaml
dependencies:
  flutter_animate: ^4.5.0
```

## Import

```dart
import 'package:flutter_animate/flutter_animate.dart';
```

## Animation Parameters

### Standard Configuration

- **Duration**: `280.ms` (280 milliseconds)
- **Curve**: `Curves.easeOutCubic`
- **Delay Pattern**: Staggered delays starting from 0ms, incrementing by 30-50ms per item

### Duration Extension

The package provides a `.ms` extension for easy duration specification:
- `280.ms` = `Duration(milliseconds: 280)`
- `50.ms` = `Duration(milliseconds: 50)`

## Animation Effects

### 1. Fade In (Basic)

Simple fade-in animation for any widget:

```dart
Widget
  .animate()
  .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
```

### 2. Fade In with Delay

Fade-in with a delay for sequential animations:

```dart
Widget
  .animate(delay: 50.ms)
  .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
```

### 3. Fade In + Scale

Combined fade and scale for emphasis:

```dart
Widget
  .animate()
  .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
  .scale(duration: 280.ms, curve: Curves.easeOutCubic)
```

### 4. Fade In + Slide

Fade with vertical slide (useful for headers):

```dart
Widget
  .animate()
  .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
  .slideY(
    begin: -0.03,
    end: 0,
    duration: 280.ms,
    curve: Curves.easeOutCubic,
  )
```

## Common Patterns

### Pattern 1: Hero Section / Main Content

For prominent sections that appear first:

```dart
_buildHeroSection(context)
  .animate()
  .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
  .scale(duration: 280.ms, curve: Curves.easeOutCubic)
```

### Pattern 2: Sequential Content Sections

For content that appears in order:

```dart
Column(
  children: [
    _buildSection1(context)
      .animate(delay: 50.ms)
      .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
    
    _buildSection2(context)
      .animate(delay: 100.ms)
      .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
    
    _buildSection3(context)
      .animate(delay: 150.ms)
      .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
  ],
)
```

### Pattern 3: List Items with Staggered Animation

For grid/list items that appear one after another:

```dart
GridView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ItemCard(item: items[index])
      .animate(delay: (100 + index * 30).ms)
      .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
      .scale(duration: 280.ms, curve: Curves.easeOutCubic);
  },
)
```

**Delay Formula**: `(baseDelay + index * increment).ms`
- `baseDelay`: Starting delay (usually 100-200ms)
- `increment`: Delay between items (30ms for fast, 50ms for slower)

### Pattern 4: Empty State

For empty states with multiple elements:

```dart
Column(
  children: [
    Icon(Icons.empty)
      .animate(delay: 50.ms)
      .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
      .scale(duration: 280.ms, curve: Curves.easeOutCubic),
    
    Text('No items')
      .animate(delay: 100.ms)
      .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
    
    Text('Description')
      .animate(delay: 150.ms)
      .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
    
    ElevatedButton(...)
      .animate(delay: 200.ms)
      .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
      .scale(duration: 280.ms, curve: Curves.easeOutCubic),
  ],
)
```

### Pattern 5: Search/Filter Sections

For search bars and filter sections:

```dart
Container(
  child: _buildSearchField(),
)
  .animate()
  .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)

// Active filters appear after search
if (hasFilters)
  _buildActiveFilters(context)
    .animate(delay: 30.ms)
    .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)

// Results header
_buildResultsHeader(context)
  .animate(delay: 50.ms)
  .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
```

## Delay Guidelines

### Recommended Delays

| Element Type | Delay | Reason |
|-------------|-------|--------|
| Hero/Main Content | 0ms | Appears first |
| Secondary Content | 50ms | Quick follow-up |
| Tertiary Content | 100ms | After secondary |
| List Items | 100ms + (index × 30ms) | Staggered effect |
| Empty State Elements | 50ms increments | Sequential reveal |
| Buttons/Actions | 100-200ms | After content loads |

### Delay Increments

- **Fast Stagger**: 30ms between items (for many items)
- **Medium Stagger**: 50ms between items (standard)
- **Slow Stagger**: 100ms between items (for emphasis)

## Complete Example

Here's a complete example showing a typical screen with animations:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ExampleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section - No delay, fade + scale
            _buildHeroSection(context)
              .animate()
              .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
              .scale(duration: 280.ms, curve: Curves.easeOutCubic),
            
            const SizedBox(height: 24),
            
            // Content Section 1 - 50ms delay
            _buildSection1(context)
              .animate(delay: 50.ms)
              .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
            
            const SizedBox(height: 24),
            
            // Content Section 2 - 100ms delay
            _buildSection2(context)
              .animate(delay: 100.ms)
              .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic),
            
            const SizedBox(height: 24),
            
            // List Items - Staggered animation
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ItemCard(item: items[index])
                  .animate(delay: (150 + index * 30).ms)
                  .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
                  .scale(duration: 280.ms, curve: Curves.easeOutCubic);
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

## Best Practices

1. **Consistency**: Use the same duration (280ms) and curve (easeOutCubic) throughout
2. **Staggering**: Always stagger list items for a polished feel
3. **Delays**: Start with 0ms for hero content, increment by 30-50ms for sequential items
4. **Scale**: Use scale sparingly, mainly for hero sections and important cards
5. **Performance**: Avoid animating too many items at once (limit to ~20 visible items)
6. **Accessibility**: Animations respect system accessibility settings automatically

## Animation Timing Reference

```
0ms    - Hero/Main content appears
50ms   - Secondary content
100ms  - Tertiary content / First list item
150ms  - Additional sections
200ms  - Buttons/Actions
+30ms  - Each subsequent list item
```

## Troubleshooting

### Animation not working?
- Ensure `flutter_animate` is added to `pubspec.yaml`
- Check that the import is present: `import 'package:flutter_animate/flutter_animate.dart';`
- Verify the widget is being rebuilt (not cached)

### Too fast/slow?
- Adjust duration: `280.ms` → `400.ms` (slower) or `200.ms` (faster)
- Adjust delay increments: `30.ms` → `50.ms` (slower stagger)

### Too many animations?
- Reduce the number of animated items
- Increase delay increments to spread animations over time
- Consider animating only visible items (use `ListView.builder` with viewport)

## Summary

**Standard Animation Pattern:**
```dart
Widget
  .animate(delay: X.ms)
  .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
  .scale(duration: 280.ms, curve: Curves.easeOutCubic) // Optional
```

**Key Values:**
- Duration: `280.ms`
- Curve: `Curves.easeOutCubic`
- Base Delay: `0-100ms` for first items
- Increment: `30-50ms` for staggered items

This pattern creates smooth, professional animations that enhance UX without being distracting.



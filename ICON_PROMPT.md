# MypiCuadre — App Icon Prompt

## Brand Context

**MypiCuadre** is an offline-first retail management app for small shops: inventory, sales, cash register (cuadres), and employee shifts. Users are shop owners and employees in Latin America. The app is Spanish-only.

**Visual personality:** Professional, trustworthy, approachable. Premium but not luxury. Built for small business owners who take their work seriously.

## Color Palette

| Token | Light | Dark |
|-------|-------|------|
| Primary | `#1A237E` Deep indigo navy | `#5C6BC0` Indigo 400 |
| Accent (info) | `#C75B39` Warm copper | `#E87A5A` Brighter copper |
| Surface | `#FFFFFF` | `#1A1C2E` Navy-undertone |
| Background | `#F5F6FA` Cool off-white | `#0F1120` Deep navy |
| Ink | `#1C1C1E` Near-black | `#F5F5F5` |

The indigo conveys authority and reliability; the copper adds warmth and approachability, echoing the color tension of classic brand pairings (Triumph, Ducati) without being motorcycle-specific.

---

## 🎯 Icon Concept: Modern Storefront

A clean, minimal storefront icon representing a small retail shop. Not a home or generic building — a shop with an open door, awning, or display window signals "business" and "commerce."

### Design Guidelines

- **Shape:** Flat, simple storefront silhouette — awning over a shop window + door
- **Silhouette:** One or two clean geometric shop elements
- **Colors:** Deep indigo navy (`#1A237E`) as primary shape, copper accent (`#C75B39`) on the awning or door element, negative space for the window
- **Style:** Flat vector, 2D, no gradients, crisp straight lines with subtle rounded corners
- **Background:** Transparent or solid white circle (for iOS App Store guidelines)
- **Complexity:** Recognizable at 32×32, detailed but not cluttered at 1024×1024
- **NO text, NO gradients, NO photorealistic elements, NO 3D**

### Why a Storefront

- A shop icon is universally understood across Latin America
- Represents any retail business, not motorcycle-specific
- Feels approachable to non-technical shop owners
- Distinct from generic "clipboard" or "box" inventory app icons
- The open door/doorway subtly suggests "open for business" — matches the shift and sales workflow

---

## Prompts for AI Image Generators

### Midjourney

```
Minimalist storefront app icon, flat vector design, clean geometry, small shop with awning over window and entry door, deep indigo navy (#1A237E) primary color, warm copper/terracotta (#C75B39) accent, white background, simple shapes, crisp lines, slightly rounded corners, 2D flat art, no text, no gradients, no shadows, professional small business identity, centered composition, app icon style --ar 1:1 --style raw --v 6
```

### DALL-E 3

```
A minimalist app icon featuring a clean storefront design for a retail management app. Flat 2D vector style. A small shop facade with a striped awning, a display window, and an entry door. Deep navy blue (#1A237E) as the primary color for walls and outlines, warm copper/terracotta (#C75B39) for the awning and door. White negative space for the window. Pure white background. No text. No gradients. No shadows. Crisp straight lines with subtle rounded corners. Centered. Recognizable at small sizes. Professional and approachable.
```

### Stable Diffusion

```
Minimalist flat vector app icon, storefront shop design, simple geometric shapes, deep indigo navy and warm copper terracotta color scheme, 2D flat art, clean lines, rounded corners, no text, no gradients, white background, centered composition, professional small business aesthetic, app icon
Negative prompt: text, letters, words, gradient, 3D, photorealistic, complex, cluttered, motorcycle, dirt, grunge, shadow
```

---

## Output Requirements

1. **Master size:** 1024×1024 px PNG (App Store requirement)
2. **Background:** Solid white circle or transparent (prefer white circle for iOS)
3. **Format:** PNG with transparency

## After Generation

Once the icon is generated, it needs to be resized into:

### iOS — `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

| Size | Filename |
|------|----------|
| 20×20 @1x | `Icon-App-20x20@1x.png` |
| 20×20 @2x | `Icon-App-20x20@2x.png` |
| 20×20 @3x | `Icon-App-20x20@3x.png` |
| 29×29 @1x | `Icon-App-29x29@1x.png` |
| 29×29 @2x | `Icon-App-29x29@2x.png` |
| 29×29 @3x | `Icon-App-29x29@3x.png` |
| 40×40 @1x | `Icon-App-40x40@1x.png` |
| 40×40 @2x | `Icon-App-40x40@2x.png` |
| 40×40 @3x | `Icon-App-40x40@3x.png` |
| 60×60 @2x | `Icon-App-60x60@2x.png` |
| 60×60 @3x | `Icon-App-60x60@3x.png` |
| 76×76 @1x | `Icon-App-76x76@1x.png` |
| 76×76 @2x | `Icon-App-76x76@2x.png` |
| 83.5×83.5 @2x | `Icon-App-83.5x83.5@2x.png` |
| 1024×1024 @1x | `Icon-App-1024x1024@1x.png` |

### Android — `android/app/src/main/res/`

| Density | Size | Path |
|---------|------|------|
| mdpi | 48×48 | `mipmap-mdpi/ic_launcher.png` |
| hdpi | 72×72 | `mipmap-hdpi/ic_launcher.png` |
| xhdpi | 96×96 | `mipmap-xhdpi/ic_launcher.png` |
| xxhdpi | 144×144 | `mipmap-xxhdpi/ic_launcher.png` |
| xxxhdpi | 192×192 | `mipmap-xxxhdpi/ic_launcher.png` |

### Update Splash Screen

Replace the generic `Icons.inventory_2` in `lib/app.dart:_SplashOverlay.build()` with the new icon asset:

```dart
// Before:
Icon(Icons.inventory_2, size: 92, color: colors.primary)

// After:
Image.asset('assets/images/mypicuadre-icon.png', width: 92, height: 92)
```

Also update the app title in `lib/app.dart` from `'Inventario App'` to `'MypiCuadre'` and the login screen heading from `'Gestión de\nInventario'` to `'MypiCuadre'`.

---
description: Adaptar interfaz para diferentes dispositivos y tamannos de pantalla
---

Load the impeccable skill using the skill tool (name: "impeccable"), then adapt the target for responsive behavior.

Steps:
1. Run: `node "C:\Users\Ruslan MC\.agents\skills\impeccable\scripts\context.mjs"`
2. Load reference/adapt.md (or reference/adapt.native.md for iOS/Android) from the skill
3. Inspect the current implementation at multiple viewport sizes
4. Identify responsive issues:
   - Fixed widths that break on mobile
   - Touch targets < 44x44px
   - Horizontal scroll on narrow viewports
   - Text scaling breaks
   - Missing breakpoints
5. Fix systematically:
   - Use fluid typography with clamp()
   - Ensure touch targets are adequate
   - Add/fix breakpoints for mobile/tablet/desktop
   - Test text scaling to 200%
   - Use logical properties for RTL support
6. Verify across all supported viewports
7. Apply craft-floor checks after changes

Target: $ARGUMENTS (the component or page to adapt)

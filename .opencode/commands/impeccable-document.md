---
description: Generar DESIGN.md desde el codigo existente del proyecto
---

Load the impeccable skill using the skill tool (name: "impeccable"), then generate DESIGN.md.

Steps:
1. Run: `node "C:\Users\Ruslan MC\.agents\skills\impeccable\scripts\context.mjs"`
2. Load reference/document.md from the skill
3. Decide path:
   - If code exists with tokens/components: use Scan mode (default)
   - If pre-implementation: use Seed mode (needs PRODUCT.md first)
4. Scan mode:
   - Step 1: Find design assets (CSS custom properties, Tailwind config, CSS-in-JS, tokens, components)
   - Step 2: Auto-extract tokens into structured draft
   - Step 2b: Stage YAML frontmatter (colors, typography, rounded, spacing, components)
   - Step 3: Ask user for qualitative language (Creative North Star, voice, color character, elevation, component philosophy)
   - Step 4: Write DESIGN.md with canonical 8 sections + .impeccable/design.json sidecar
   - Step 5: Confirm and refine
5. If DESIGN.md already exists, do NOT overwrite silently - ask user first

Target: $ARGUMENTS (optional target path or route to focus extraction on)

---
description: Capturar contexto del producto en PRODUCT.md mediante entrevista
---

Load the impeccable skill using the skill tool (name: "impeccable"), then run the init flow to capture durable product truth.

Steps:
1. Run: `node "C:\Users\Ruslan MC\.agents\skills\impeccable\scripts\context.mjs"`
2. Load reference/init.md from the skill
3. Follow the init flow exactly:
   - Step 1: Load current state (check if PRODUCT.md exists)
   - Step 2: Explore the project (scan package.json, routes, components, config)
   - Step 3: Interview for product truth (ask 2-3 focused questions per round, max 3 rounds)
   - Step 4: Write PRODUCT.md at the project root
   - Step 5: Configure live mode if useful
   - Step 6: Wrap up and recommend next actions
4. Never ask for visual/aesthetic direction during init - only product truth
5. Write only confirmed facts; mark undecided facts explicitly

Target: $ARGUMENTS (if provided, use as the project path or route to focus on)

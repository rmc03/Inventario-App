---
description: Impeccable design skill - menu contextual y recomendaciones
---

Load the impeccable skill using the skill tool (name: "impeccable"), then run context setup and present a context-aware menu.

Steps:
1. Run: `node "C:\Users\Ruslan MC\.agents\skills\impeccable\scripts\context.mjs"`
2. Run: `node "C:\Users\Ruslan MC\.agents\skills\impeccable\scripts\context-signals.mjs"` (if the file exists)
3. Read reference/routing.md from the skill to understand the context-aware menu logic
4. Analyze the project state:
   - Does PRODUCT.md exist? Does DESIGN.md exist?
   - Are there any prior critiques in .impeccable/critique/?
   - Are there git changes to UI files?
   - Is a dev server running?
5. Present the 2-3 highest-value next commands with one-line reasons, then the full command list grouped by category
6. Never auto-run a command; the recommendation is a suggestion the user confirms

If the user provided arguments ($ARGUMENTS), treat the request as general design work and follow the routing logic from routing.md.

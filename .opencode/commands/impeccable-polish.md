---
description: Pase de calidad final antes de publicar - refina sin redisenar
---

Load the impeccable skill using the skill tool (name: "impeccable"), then run a polish pass.

Steps:
1. Run: `node "C:\Users\Ruslan MC\.agents\skills\impeccable\scripts\context.mjs"`
2. Load reference/polish.md and reference/craft-floor.md from the skill
3. Establish the system: read DESIGN.md, tokens, shared components, neighboring flows
4. Gather evidence: use the feature at desktop and mobile sizes, check functional completeness
5. If a prior critique exists, read it: `node "C:\Users\Ruslan MC\.agents\skills\impeccable\scripts\critique-storage.mjs latest "<target>"`
6. Triage and fix in order:
   - Broken/blocked tasks, data loss, inaccessible paths
   - Missing states (loading, empty, error, success, disabled)
   - Flow, hierarchy, responsive, design-system drift
   - Visual and motion inconsistencies
   - Code and asset cleanup
7. Apply craft-floor checks: contrast, depth, spacing, type, motion, states, copy, coverage
8. Verify with mouse, keyboard, and touch across all viewports
9. Clean up: remove accidental churn, orphaned code, redundant values

Target: $ARGUMENTS (the feature or surface to polish)

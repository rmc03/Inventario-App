---
description: Revision de diseno con scoring heuristico Nielsen y detector de antipatrones
---

Load the impeccable skill using the skill tool (name: "impeccable"), then run a full design critique.

Steps:
1. Run: `node "C:\Users\Ruslan MC\.agents\skills\impeccable\scripts\context.mjs"`
2. Load reference/critique.md from the skill - follow it exactly
3. Resolve the target to a concrete file path or URL
4. Run the slug confirmation: `node "C:\Users\Ruslan MC\.agents\skills\impeccable\scripts\critique-storage.mjs slug "<target>"`
5. Run Assessment A (Design Review) and Assessment B (Detector + Browser Evidence) as two isolated sub-agents if possible
6. Assessment B must run: `node "C:\Users\Ruslan MC\.agents\skills\impeccable\scripts\detect.mjs" --json <target>`
7. Synthesize both assessments into a single report with:
   - Design Health Score (Nielsen's 10 heuristics, 0-4 each)
   - Design Specificity Verdict
   - Overall Impression, What's Working, Priority Issues (P0-P3)
   - Persona Red Flags (2-3 relevant personas)
   - Minor Observations and Questions
8. Persist the snapshot to .impeccable/critique/
9. Ask the user targeted questions about priorities, then present recommended actions

Target: $ARGUMENTS (file path, route, or "the homepage", "the settings page", etc.)

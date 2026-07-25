---
description: Detectar antipatrones de diseno genéricos de AI en archivos UI
---

Load the impeccable skill using the skill tool (name: "impeccable"), then run the design detector.

Steps:
1. Run: `node "C:\Users\Ruslan MC\.agents\skills\impeccable\scripts\context.mjs"`
2. Run the detector: `node "C:\Users\Ruslan MC\.agents\skills\impeccable\scripts\detect.mjs" --json $ARGUMENTS`
3. If no target specified, scan the project source directories
4. Parse the JSON output and present findings organized by:
   - Rule category (gradient text, glass/blur, borders, eyebrows, sparklines, monospace costume, etc.)
   - File location and line number
   - Severity and suggested fix
5. Summarize total findings count and top issues
6. Suggest the appropriate Impeccable command to address each category of findings

Target: $ARGUMENTS (file, directory, or URL to scan - skips CLI for URLs)

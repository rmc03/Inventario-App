---
description: Verificar y reparar drift entre artefactos Impeccable y el codigo actual
---

Load the impeccable skill using the skill tool (name: "impeccable"), then run the doctor diagnostic.

Steps:
1. Run: `node "C:\Users\Ruslan MC\.agents\skills\impeccable\scripts\context.mjs"`
2. Load reference/doctor.md from the skill
3. Run the doctor pass: `node "C:\Users\Ruslan MC\.agents\skills\impeccable\scripts\doctor.mjs" --json`
4. If the user provided a target, add `--target <path>` to the command
5. Act by severity:
   - `auto`: run `node "C:\Users\Ruslan MC\.agents\skills\impeccable\scripts\doctor.mjs" --fix` to apply automatic repairs, report in one line
   - `mention`: state each finding with its offered fix
   - `route`: name the specific command needed (init, document, etc.)
6. Report deprecated fields as binding - treat them as absent
7. Do not overclaim on truth drift - a commit count is not a contradiction
8. For monorepos, show workspace context resolution table

Target: $ARGUMENTS (optional workspace or file path)

---
description: Iteracion visual en tiempo real - seleccionar elementos y generar variantes
---

Load the impeccable skill using the skill tool (name: "impeccable"), then start a live iteration session.

IMPORTANT: This command requires a running dev server with hot module replacement (Vite, Next.js, Bun, etc.).

Steps:
1. Run: `node "C:\Users\Ruslan MC\.agents\skills\impeccable\scripts\live.mjs"` (with --target if $ARGUMENTS provided)
2. Read the output JSON: ok, serverPort, serverToken, pageFiles, product, design
3. Open the app URL that serves the pageFiles (NOT the helper serverPort)
4. Start the poll loop: `node "C:\Users\Ruslan MC\.agents\skills\impeccable\scripts\live-poll.mjs"`
5. On "generate" events: plan 3 variants within the existing identity, deliver HTML+CSS, reply done
6. On "steer" events: read the message and make edits or reply
7. On "accept"/"discard": handle cleanup via live-accept.mjs or live-complete.mjs
8. On interruptions: use live-status.mjs or live-resume.mjs to recover

Load reference/live.md for the full contract and variant generation flow.
Follow harness policy: run poll as background task, handle events in main thread.

Target: $ARGUMENTS (optional file, route, or app path inside a monorepo)

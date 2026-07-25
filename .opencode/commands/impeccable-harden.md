---
description: Endurecer interfaz para produccion - errores, i18n, edge cases, estados extremos
---

Load the impeccable skill using the skill tool (name: "impeccable"), then harden the target for production.

Steps:
1. Run: `node "C:\Users\Ruslan MC\.agents\skills\impeccable\scripts\context.mjs"`
2. Load reference/harden.md from the skill
3. Assess hardening needs by testing with extreme inputs:
   - Very long text (100+ chars), very short text, empty states
   - Special characters (emoji, RTL, accents, CJK)
   - Large numbers (millions, billions)
   - Many items (1000+ list items)
4. Test error scenarios:
   - Network failures (offline, slow, timeout)
   - API errors (400, 401, 403, 404, 500, 429)
   - Validation errors, permission errors
5. Test internationalization:
   - Text expansion (German 30% longer than English)
   - RTL languages (Arabic, Hebrew)
   - Date/time/number/currency formats
6. Implement fixes:
   - Text overflow handling (truncate, line-clamp, wrap)
   - Error states with clear messages and recovery
   - Empty states with clear next actions
   - Loading states with progress
   - Input validation and sanitization
   - Keyboard navigation and screen reader support
7. Verify with edge cases: long text, emoji, RTL, CJK, offline, 1000+ items, rapid clicks

Target: $ARGUMENTS (the feature or component to harden)

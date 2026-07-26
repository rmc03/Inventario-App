# Color Personality Guide
**Inventario App — Mypime Motos**  
**Delight Thesis:** "Warmth in reliability"  
**Palette:** Azure Blue + Copper Accent

---

## The Palette

### Azure Blue (Primary)
**Light:** `#0F62FE` | **Dark:** `#4589FF`

**Character:** Modern, trustworthy, energetic, professional  
**Use for:** Navigation, primary actions, headers, system structure

The azure blue is vibrant yet reliable — it conveys professionalism with energy. More approachable than navy, more trustworthy than bright blue. It's the color of "this system is modern and works."

---

### Copper Accent (Info) 🔥
**Light:** `#E8743B` | **Dark:** `#FF9E6D`

**Character:** Warmth, completion, human moments, personality  
**Use for:** Success states, milestones, inventory additions, unit counts, sync confirmations

This is the app's **signature**. The copper accent creates memorable moments in an operational interface. It creates visual tension against the cool azure blue — warm vs cool, personal vs structural.

**Emotional mapping:**
- When a sale completes successfully
- When offline data syncs to the cloud
- When the cash register balances perfectly (cuadre)
- When inventory arrives and stock increases
- When milestones are reached (100th sale, etc.)
- Unit counts and quantity metrics

---

## Strategic Color Usage

### 1. **Sale Completions**
When a sale is confirmed and saved:
- Confirmation icon in copper
- Success message background: `copper.withValues(alpha: 0.15)`
- Checkmark animation with copper glow

**Current implementation:** Primarily uses primary indigo  
**Delight opportunity:** Shift to copper for "sale saved" confirmation

---

### 2. **Inventory Additions**
When stock is added (reposición, nueva entrada):
- Movement card accent in copper
- Icon badge in copper
- Unit count pill: copper background + white text

**Current implementation:** ✅ Already using copper (`colors.info`)  
**Status:** Good — preserve this

---

### 3. **Sync Success**
When offline data syncs to Supabase:
- Sync icon pulses copper
- "Sincronizado" badge in copper
- Success toast with copper accent

**Current implementation:** Not yet implemented  
**Delight opportunity:** Add sync feedback with copper personality

---

### 4. **Daily Close (Cuadre)**
When cash register balances perfectly:
- Balance confirmation card with copper border
- "Cuadre correcto" badge in copper
- Celebratory copper accent on total

**Current implementation:** Uses primary indigo  
**Delight opportunity:** Copper = moment of relief and success

---

### 5. **Unit Metrics**
Anywhere quantity/units appear:
- Inventory counts
- Units sold
- Stock level indicators

**Current implementation:** ✅ Already using copper in several places  
**Status:** Expand this pattern consistently

---

### 6. **Milestone Celebrations**
When operational goals are reached:
- 100th sale of the month
- First sync after offline period
- Perfect week with no stock-outs

**Current implementation:** Not yet implemented  
**Delight opportunity:** Micro-celebrations with copper confetti/badges

---

## Color Contrast & Accessibility

### Light Mode Copper (`#E8743B`)
- **On white background:** 3.00:1 (✅ WCAG AA for large text 18pt+, icons 16px+)
- **On surfaceSecondary (`#F4F7FB`):** ~2.8:1 (⚠️ Large elements only)
- **For body text:** Use ink (`#161616`) instead; copper is accent only
- **Recommended usage:** Icons 16px+, badges, headings 18pt+, interactive elements
- **Rule:** Never use for paragraph text or small labels under 16px

### Dark Mode Copper (`#FF9E6D`)
- **On dark background (`#121418`):** 9.10:1 (✅ WCAG AAA — exceptional)
- **On surface (`#1C1F26`):** ~8.2:1 (✅ WCAG AAA — excellent)
- **Luminous warmth:** Glows beautifully against deep blue-gray surfaces
- **Recommended usage:** All sizes including body text; contrast is exceptional

### General Rules
1. **Never use copper for error states** — that's `danger` red
2. **Never use copper for warnings** — that's `warning` deep orange
3. **Copper = positive, warm, complete** — guard this emotional mapping
4. **On colored backgrounds:** Tint from copper itself, never gray

---

## Implementation Patterns

### Copper Badge
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(
    color: context.colors.info.withValues(alpha: 0.10),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.check_circle_rounded, size: 14, color: context.colors.info),
      SizedBox(width: 6),
      Text(
        'Sincronizado',
        style: TextStyle(
          color: context.colors.info,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    ],
  ),
)
```

### Copper Icon Accent
```dart
Container(
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: context.colors.info.withValues(alpha: 0.12),
    shape: BoxShape.circle,
  ),
  child: Icon(
    Icons.inventory_2_outlined,
    color: context.colors.info,
    size: 24,
  ),
)
```

### Copper Border Highlight
```dart
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: context.colors.info.withValues(alpha: 0.3),
      width: 2,
    ),
  ),
  child: // content
)
```

### Copper Text Accent
```dart
Text(
  '${units} unidades',
  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
    color: context.colors.info,
    fontWeight: FontWeight.w600,
  ),
)
```

---

## Where NOT to Use Copper

❌ **Primary navigation structure** — stick to indigo  
❌ **Error messages** — use `danger` red  
❌ **Caution/warnings** — use `warning` orange  
❌ **Neutral operational elements** — use `ink` or `muted`  
❌ **Buttons for destructive actions** — use outlined style with ink/muted  
❌ **Every card border** — overuse kills personality

---

## Expanding Copper Usage

### Quick Wins
1. **Sale confirmation screen:** Switch success icon to copper
2. **Sync feedback:** Add copper sync badge when online
3. **Cuadre success:** Copper border + badge for balanced register
4. **Unit count pills:** Consistently use copper across all screens

### Future Delight Moments
1. **First sale celebration:** Copper confetti animation
2. **Sync recovery:** "Volvemos a estar conectados" with copper pulse
3. **Milestone badges:** 10th/100th/1000th sale with copper accent
4. **Empty state CTAs:** Copper accent on "Añadir primer producto"

---

## Testing Dark Mode

Copper must remain **luminous and warm** in dark mode without becoming harsh. Test on:
- OLED screens (navy backgrounds should feel intentional, not accidental)
- Low ambient light (copper should glow softly, not burn)
- Accessibility: Ensure contrast remains AAA for all uses

---

## Motorcycle Heritage

The indigo + copper pairing references classic motorcycle brand color tension:
- **Triumph:** Navy + racing orange
- **Ducati:** Red + black with warm undertones
- **Vintage racing:** Cool structure + warm speed

This isn't decoration — it's operational craft with personality rooted in the product's domain.

---

**Version:** 1.0  
**Last Updated:** 2026-07-25  
**Maintained by:** Impeccable Design System

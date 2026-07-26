# Copper Delight Examples — Implementation Patterns

## Example 1: Sale Completion Success Badge

### Before (Generic)
```dart
SnackBar(
  content: Text('Venta guardada exitosamente'),
  backgroundColor: Colors.green,
)
```

### After (Copper Personality) ✨
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    backgroundColor: context.colors.info.withValues(alpha: 0.95),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    content: Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Venta guardada',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                'Total: ${Formatters.currency(total)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    duration: Duration(seconds: 3),
  ),
);
```

**Why copper:** This is a moment of completion and relief — the sale is safe. Copper signals warmth and success beyond operational green.

---

## Example 2: Sync Success Badge

### Implementation
```dart
// Show when offline data syncs successfully
AnimatedContainer(
  duration: Duration(milliseconds: 300),
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  decoration: BoxDecoration(
    color: context.colors.info.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: context.colors.info.withValues(alpha: 0.3),
      width: 1,
    ),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Pulsing sync icon
      TweenAnimationBuilder(
        duration: Duration(milliseconds: 1000),
        tween: Tween<double>(begin: 0.8, end: 1.0),
        builder: (context, double scale, child) {
          return Transform.scale(
            scale: scale,
            child: Icon(
              Icons.cloud_done_rounded,
              size: 16,
              color: context.colors.info,
            ),
          );
        },
      ),
      SizedBox(width: 8),
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

**Why copper:** Sync success in an offline-first app is a moment worth celebrating. Copper = "we're connected again."

---

## Example 3: Cash Register Balance (Cuadre Perfecto)

### Implementation
```dart
// When cash register balances perfectly at end of day
Container(
  padding: EdgeInsets.all(20),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        context.colors.info.withValues(alpha: 0.15),
        context.colors.info.withValues(alpha: 0.05),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: context.colors.info.withValues(alpha: 0.4),
      width: 2,
    ),
  ),
  child: Column(
    children: [
      // Copper success icon
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.info.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.account_balance_wallet_rounded,
          color: context.colors.info,
          size: 32,
        ),
      ),
      SizedBox(height: 16),
      Text(
        'Cuadre perfecto',
        style: TextStyle(
          color: context.colors.info,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      SizedBox(height: 4),
      Text(
        'El efectivo coincide exactamente',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: context.colors.muted,
        ),
      ),
    ],
  ),
)
```

**Why copper:** A balanced register at end of day is a moment of professional satisfaction. Copper = warmth and completion.

---

## Example 4: Inventory Addition Confirmation

### Current Implementation (Already Good) ✅
```dart
// Movimiento card for inventory additions
Container(
  decoration: BoxDecoration(
    color: context.colors.info.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: context.colors.info.withValues(alpha: 0.2),
      width: 1,
    ),
  ),
  child: ListTile(
    leading: Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.colors.info.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.add_box_outlined,
        color: context.colors.info,
        size: 20,
      ),
    ),
    title: Text(
      'Nueva entrada',
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: context.colors.ink,
      ),
    ),
    subtitle: Text(
      'Añadidas ${cantidad} unidades de ${productoNombre}',
      style: TextStyle(color: context.colors.muted),
    ),
    trailing: Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.info.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '+${cantidad}',
        style: TextStyle(
          color: context.colors.info,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    ),
  ),
)
```

**Status:** Already using copper effectively — preserve this pattern.

---

## Example 5: Unit Count Pills (Consistent Pattern)

### Implementation
```dart
// Use this pattern anywhere quantities/units appear
Container(
  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(
    color: context.colors.info.withValues(alpha: 0.10),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.inventory_2_outlined,
        size: 14,
        color: context.colors.info,
      ),
      SizedBox(width: 6),
      Text(
        '$unidades ${unidades == 1 ? 'ud' : 'uds'}',
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

**Why copper:** Units and quantities are the app's core metric. Copper makes them memorable and distinct.

---

## Example 6: Milestone Badge (Future Enhancement)

### Implementation
```dart
// Show when reaching sales milestones (100th sale, etc.)
showDialog(
  context: context,
  builder: (context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Copper confetti animation (optional)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  context.colors.info,
                  context.colors.info.withValues(alpha: 0.6),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          SizedBox(height: 20),
          Text(
            '¡Venta #100!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: context.colors.info,
              letterSpacing: -0.8,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Has alcanzado las 100 ventas este mes',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.info,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 50),
            ),
            child: Text('Continuar'),
          ),
        ],
      ),
    ),
  ),
);
```

**Why copper:** Milestones deserve celebration. Copper = achievement and warmth.

---

## General Principles

### Alpha Values for Copper Backgrounds
- `0.05` — Very subtle tint
- `0.08-0.10` — Card backgrounds (current standard)
- `0.12-0.15` — Badges, pills, icon containers
- `0.90-0.95` — SnackBars, toasts (with white text)

### Border Treatments
- `0.2` — Subtle accent borders
- `0.3-0.4` — Emphasized borders (success states)

### Text & Icons
- Full opacity copper for text and icons on light backgrounds
- Test in dark mode — `#FF9A6C` is more luminous

---

## Where Copper Lives Today ✅

**Already implemented well:**
1. Inventory addition movement cards (`movimientos_screen.dart`)
2. Unit count pills in dashboard (`resumen_screen.dart`)
3. Progress bars for second-ranked products

**Opportunities to expand:**
1. Sale completion confirmations
2. Sync success feedback
3. Cash register balance success
4. Milestone celebrations
5. First-time experiences ("Añade tu primer producto")

---

**Delight Thesis:** "Warmth in reliability"  
Copper appears when the system confirms your work is safe, complete, or successful.

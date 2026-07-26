# Iconos 3D Fluent - Microsoft

## 🎨 Iconos Descargados (Cash App Style)

Estos iconos son de **Microsoft Fluent Emojis** - código abierto y gratuitos.
Estilo: 3D coloridos con gradientes, similar a Cash App, Notion, etc.

### 💰 Finanzas & Ventas
- `money_bag.png` - Bolsa de dinero (ventas totales, ingresos)
- `money_with_wings.png` - Dinero volando (gastos, salidas)
- `dollar_banknote.png` - Billete de dólar (efectivo, pagos)
- `briefcase.png` - Maletín (negocio, admin)
- `receipt.png` - Recibo (transacciones, facturas)

### 📊 Estadísticas & Reportes
- `chart_increasing.png` - Gráfica creciente (ventas, tendencias)
- `bar_chart.png` - Gráfica de barras (estadísticas)

### 📦 Inventario & Productos
- `package.png` - Paquete (inventario, stock)
- `shopping_bags.png` - Bolsas de compras (productos vendidos)

### ✅ Estado & Acciones
- `check_mark.png` - Checkmark (stock OK, completado)
- `clipboard.png` - Portapapeles (cuadres, listas)

### 🏪 General
- `department_store.png` - Tienda (mypime, negocio)
- `calendar.png` - Calendario (fechas, períodos)
- `alarm_clock.png` - Reloj (turnos, horarios)

## 📝 Licencia
**MIT License** - Microsoft Fluent Emoji
- Uso comercial: ✅ Permitido
- Modificación: ✅ Permitido
- Atribución: ✅ Recomendada (no obligatoria)

Fuente: https://github.com/microsoft/fluentui-emoji
Pack usado: https://github.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis

## 🎯 Cómo Usar en Flutter

```dart
// En una card o widget
Image.asset(
  'assets/images/money_bag.png',
  width: 64,
  height: 64,
)

// Con padding y decoración
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
  ),
  child: Image.asset(
    'assets/images/chart_increasing.png',
    width: 80,
    height: 80,
  ),
)
```

## 💡 Recomendaciones de Diseño

1. **Tamaño:** 48-80px para hero cards, 32-40px para items de lista
2. **Padding:** 12-16px alrededor del icono dentro de su container
3. **Background:** Blanco o gris muy claro para que resalten
4. **Border Radius:** 16-20px para el container (Cash App style)
5. **Spacing:** Mínimo 16px entre icono y texto

## 🎨 Sugerencias de Uso

### Pantalla Resumen
- `money_bag.png` → Ventas totales
- `shopping_bags.png` → Unidades vendidas
- `chart_increasing.png` → Tendencias
- `check_mark.png` → Stock OK

### Pantalla Inventario
- `package.png` → Productos en stock
- `shopping_bags.png` → Productos activos

### Pantalla Movimientos
- `receipt.png` → Lista de transacciones
- `money_with_wings.png` → Gastos
- `dollar_banknote.png` → Ingresos

### Pantalla Cuadres
- `clipboard.png` → Cuadre del día
- `briefcase.png` → Historial de cuadres
- `calendar.png` → Cuadres por fecha

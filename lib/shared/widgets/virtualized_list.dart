// Widgets de lista optimizados para datasets grandes (virtualización).
//
// Usa ListView.builder con cacheExtent y itemExtent fijos cuando sea posible
// para renderizar solo los items visibles + buffer, mejorando performance
// significativamente con 1000+ items.

import 'package:flutter/material.dart';

/// Configuración para listas virtualizadas grandes
class VirtualizedListConfig {
  const VirtualizedListConfig({
    this.scrollCacheExtent = 500,
    this.addAutomaticKeepAlives = false,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
  });

  /// Extensión del cache en píxeles (items fuera de vista que se mantienen)
  final double scrollCacheExtent;

  /// Si mantener items vivos (útil para formularios complejos)
  final bool addAutomaticKeepAlives;

  /// Si agregar RepaintBoundary a cada item (reduce repaints)
  final bool addRepaintBoundaries;

  /// Si agregar índices semánticos (accesibilidad)
  final bool addSemanticIndexes;
}

/// ListView virtualizado optimizado para datasets grandes.
///
/// Uso:
/// ```dart
/// VirtualizedListView<Producto>(
///   items: productos,
///   config: VirtualizedListConfig(itemExtent: 80),
///   itemBuilder: (context, producto, index) => ProductoTile(producto: producto),
/// )
/// ```
class VirtualizedListView<T> extends StatelessWidget {
  const VirtualizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.config = const VirtualizedListConfig(),
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.primary,
    this.emptyWidget,
    this.separatorBuilder,
  });

  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final VirtualizedListConfig config;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final bool? primary;
  final Widget? emptyWidget;
  final Widget Function(BuildContext, int)? separatorBuilder;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return emptyWidget ?? const SizedBox.shrink();
    }

    return ListView.separated(
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      primary: primary,
      // ignore: deprecated_member_use
      cacheExtent: config.scrollCacheExtent,
      itemCount: items.length,
      addAutomaticKeepAlives: config.addAutomaticKeepAlives,
      addRepaintBoundaries: config.addRepaintBoundaries,
      addSemanticIndexes: config.addSemanticIndexes,
      itemBuilder: (context, index) => itemBuilder(context, items[index], index),
      separatorBuilder: separatorBuilder ??
          (context, index) => const SizedBox.shrink(),
    );
  }
}

/// Sliver virtualizado para uso en CustomScrollView.
class VirtualizedSliverList<T> extends StatelessWidget {
  const VirtualizedSliverList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.config = const VirtualizedListConfig(),
    this.padding,
    this.emptyWidget,
    this.separatorBuilder,
  });

  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final VirtualizedListConfig config;
  final EdgeInsetsGeometry? padding;
  final Widget? emptyWidget;
  final Widget Function(BuildContext, int)? separatorBuilder;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return SliverToBoxAdapter(child: emptyWidget ?? const SizedBox.shrink());
    }

    return SliverPadding(
      padding: padding ?? EdgeInsets.zero,
      sliver: SliverList.separated(
        itemCount: items.length,
        itemBuilder: (context, index) => itemBuilder(context, items[index], index),
        separatorBuilder: separatorBuilder ??
            (context, index) => const SizedBox.shrink(),
      ),
    );
  }
}

/// Helper genérico para crear lista virtualizada con config predeterminada
Widget buildVirtualizedList<T>({
  required List<T> items,
  required Widget Function(BuildContext, T, int) itemBuilder,
  VirtualizedListConfig config = const VirtualizedListConfig(),
  EdgeInsetsGeometry? padding,
  Widget? emptyWidget,
  Widget Function(BuildContext, int)? separatorBuilder,
}) {
  return VirtualizedListView<T>(
    items: items,
    config: config,
    padding: padding,
    itemBuilder: itemBuilder,
    emptyWidget: emptyWidget,
    separatorBuilder: separatorBuilder,
  );
}
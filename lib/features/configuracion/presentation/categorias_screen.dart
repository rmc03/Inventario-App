import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/models/categoria.dart';
import '../../../shared/widgets/category_name_dialog.dart';
import '../../inventario/providers/inventario_provider.dart';

class CategoriasScreen extends ConsumerWidget {
  const CategoriasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categorias = ref.watch(
      inventarioControllerProvider.select((s) => s.categorias),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
        actions: [
          IconButton(
            onPressed: () => _showCategoryDialog(context, ref),
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Nueva categoría',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.category_rounded,
                        size: 20,
                        color: context.colors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${categorias.length} ${categorias.length == 1 ? 'categoría' : 'categorías'}',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              color: context.colors.muted,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ],
                  ),
                ),
                categorias.isEmpty
                    ? const _EmptyCategorias()
                    : Column(
                        children: [
                          for (int i = 0; i < categorias.length; i++) ...[
                            _CategoryCard(
                              key: ValueKey(categorias[i].id),
                              categoria: categorias[i],
                              index: i + 1,
                              onEdit: () => _showCategoryDialog(
                                context,
                                ref,
                                categoria: categorias[i],
                              ),
                              onDelete: () => _confirmDeleteCategoria(
                                context,
                                ref,
                                categorias[i],
                              ),
                            ),
                            if (i < categorias.length - 1)
                              const SizedBox(height: AppSpacing.sm),
                          ],
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    Categoria? categoria,
  }) async {
    final isEdit = categoria != null;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => CategoryNameDialog(
        title: isEdit ? 'Editar categoría' : 'Crear categoría',
        initialName: isEdit ? categoria.nombre : null,
        categoryExists: (value) => ref
            .read(inventarioControllerProvider.notifier)
            .existsCategoriaConNombre(
              value,
              excludeId: isEdit ? categoria.id : null,
            ),
      ),
    );

    if (name != null && name.isNotEmpty) {
      ref
          .read(inventarioControllerProvider.notifier)
          .upsertCategoria(
            Categoria(
              id: isEdit ? categoria.id : const Uuid().v4(),
              nombre: name,
              createdAt: isEdit ? categoria.createdAt : DateTime.now(),
            ),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit
                ? 'Categoría actualizada'
                : 'Categoría creada correctamente'),
            backgroundColor: context.colors.success,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteCategoria(
    BuildContext context,
    WidgetRef ref,
    Categoria categoria,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.danger.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: context.colors.danger,
              size: 32,
            ),
          ),
          title: const Text('¿Eliminar categoría?'),
          content: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                const TextSpan(
                  text: 'Esta acción no se puede deshacer. ¿Deseas eliminar la categoría ',
                ),
                TextSpan(
                  text: '"${categoria.nombre}"',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: '?'),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Haptics.warning(context);
                Navigator.of(context).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.danger,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed ?? false) {
      ref
          .read(inventarioControllerProvider.notifier)
          .deleteCategoria(categoria.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Categoría eliminada'),
            backgroundColor: context.colors.danger,
          ),
        );
      }
    }
  }
}

// ─── Category Card ──────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    super.key,
    required this.categoria,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  final Categoria categoria;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.line,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.ink.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.colors.primary.withValues(alpha: 0.15),
                      context.colors.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoria.nombre,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Creada ${_formatDate(categoria.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.colors.muted,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Editar',
                style: IconButton.styleFrom(
                  foregroundColor: context.colors.primary,
                  backgroundColor: context.colors.primary.withValues(alpha: 0.1),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                tooltip: 'Eliminar',
                style: IconButton.styleFrom(
                  foregroundColor: context.colors.danger,
                  backgroundColor: context.colors.danger.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final diff = today.difference(dateOnly).inDays;

    if (diff == 0) return 'hoy';
    if (diff == 1) return 'ayer';
    if (diff < 7) return 'hace $diff días';
    if (diff < 30) return 'hace ${(diff / 7).floor()} semanas';
    if (diff < 365) return 'hace ${(diff / 30).floor()} meses';
    return 'hace ${(diff / 365).floor()} años';
  }
}

// ─── Empty State ────────────────────────────────────────────────────────────

class _EmptyCategorias extends StatelessWidget {
  const _EmptyCategorias();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.category_outlined,
                size: 48,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No hay categorías',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Crea tu primera categoría desde el botón superior',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.muted,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

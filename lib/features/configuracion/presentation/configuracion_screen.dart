import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/categoria.dart';
import '../../auth/providers/auth_provider.dart';
import '../../inventario/providers/inventario_provider.dart';

class ConfiguracionScreen extends ConsumerWidget {
  const ConfiguracionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final inventario = ref.watch(inventarioControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      child: Icon(Icons.admin_panel_settings_outlined),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.nombre ?? 'Admin',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(user?.email ?? 'admin@inventario.local'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Usuarios', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_add_alt_1_outlined),
                title: const Text('Crear dependiente'),
                subtitle: const Text('Alta rápida para usuarios internos'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {},
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Categorías',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => _showCategoryDialog(context, ref),
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'Crear categoría',
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final categoria in inventario.categorias) ...[
              Card(
                child: ListTile(
                  title: Text(categoria.nombre),
                  leading: const Icon(Icons.category_outlined),
                  trailing: IconButton(
                    onPressed: () => ref
                        .read(inventarioControllerProvider.notifier)
                        .deleteCategoria(categoria.id),
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: AppColors.danger,
                    tooltip: 'Eliminar',
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showCategoryDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Crear categoría'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      errorText: errorText,
                    ),
                    onChanged: (_) {
                      if (errorText != null) {
                        setDialogState(() => errorText = null);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final value = controller.text.trim();
                    if (value.isEmpty) {
                      setDialogState(
                        () => errorText = 'El nombre es obligatorio',
                      );
                      return;
                    }
                    final isDuplicate = ref
                        .read(inventarioControllerProvider.notifier)
                        .existsCategoriaConNombre(value);
                    if (isDuplicate) {
                      setDialogState(
                        () => errorText =
                            'Ya existe una categoría con este nombre',
                      );
                      return;
                    }
                    Navigator.of(context).pop(value);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();

    if (name != null && name.isNotEmpty) {
      ref
          .read(inventarioControllerProvider.notifier)
          .upsertCategoria(
            Categoria(
              id: const Uuid().v4(),
              nombre: name,
              createdAt: DateTime.now(),
            ),
          );
    }
  }
}

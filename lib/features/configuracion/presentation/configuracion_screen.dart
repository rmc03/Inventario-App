// ignore_for_file: unused_element_parameter
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import '../../../core/local_db/local_database.dart';
import '../../../shared/models/usuario.dart';
import '../../../shared/models/categoria.dart';
import '../../auth/providers/auth_provider.dart';
import '../../inventario/providers/inventario_provider.dart';

class ConfiguracionScreen extends ConsumerWidget {
  const ConfiguracionScreen({super.key, this.isAdmin = true});

  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider.select((s) => s.user));
    final categorias = ref.watch(
      inventarioControllerProvider.select((s) => s.categorias),
    );

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
                    _ProfileAvatar(user: user),
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
                    if (!isAdmin)
                      IconButton(
                        onPressed: () => _showEditProfileDialog(context, ref, user),
                        icon: const Icon(Icons.edit_rounded),
                        tooltip: 'Editar perfil',
                      ),
                  ],
                ),
              ),
            ),
            if (!isAdmin) ...[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Cambiar contraseña'),
                  subtitle: const Text('Cambia tu contraseña de acceso (simulado)'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showChangePasswordDialog(context),
                ),
              ),
            ],
            if (isAdmin) ...[
              const SizedBox(height: 18),
              Text('USUARIOS', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.muted, letterSpacing: 0.5)),
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
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'CATEGORÍAS',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.muted, letterSpacing: 0.5),
                  ),
                ),
                if (isAdmin)
                  IconButton.filledTonal(
                    onPressed: () => _showCategoryDialog(context, ref),
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'Crear categoría',
                  ),
              ],
            ),
            const SizedBox(height: 10),
            for (final categoria in categorias) ...[
              Card(
                key: ValueKey(categoria.id),
                child: ListTile(
                  title: Text(categoria.nombre),
                  leading: const Icon(Icons.category_outlined),
                  trailing: isAdmin
                      ? IconButton(
                          onPressed: () => _confirmDeleteCategoria(
                            context,
                            ref,
                            categoria,
                          ),
                          icon: const Icon(Icons.delete_outline_rounded),
                          color: AppColors.danger,
                          tooltip: 'Eliminar',
                        )
                      : null,
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

  Future<void> _confirmDeleteCategoria(
    BuildContext context,
    WidgetRef ref,
    Categoria categoria,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.danger,
            size: 42,
          ),
          title: const Text('¿Eliminar categoría?'),
          content: Text(
            'Esta acción no se puede deshacer. ¿Deseas eliminar la categoría "${categoria.nombre}"?',
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
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
    }
  }

  Future<void> _showEditProfileDialog(BuildContext context, WidgetRef ref, Usuario? user) async {
    if (user == null) return;
    final nameCtrl = TextEditingController(text: user.nombre);
    final emailCtrl = TextEditingController(text: user.email);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar perfil'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailCtrl,
                    decoration: InputDecoration(labelText: 'Email', errorText: errorText),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
              actions: [
                OutlinedButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                ElevatedButton(onPressed: () {
                  final newName = nameCtrl.text.trim();
                  final newEmail = emailCtrl.text.trim();
                  if (newName.isEmpty || newEmail.isEmpty || !newEmail.contains('@')) {
                    setState(() => errorText = 'Introduce un nombre y un email válidos');
                    return;
                  }
                  final updated = user.copyWith(nombre: newName, email: newEmail);
                  ref.read(authControllerProvider.notifier).updateUser(updated);
                  Navigator.of(context).pop(true);
                }, child: const Text('Guardar')),
              ],
            );
          },
        );
      },
    );
    nameCtrl.dispose();
    emailCtrl.dispose();
    if (result ?? false) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
    }
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Cambiar contraseña'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Old password kept for UX only; not validated in local demo
                  TextField(controller: oldCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña actual')),
                  const SizedBox(height: 8),
                  TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Nueva contraseña')),
                  const SizedBox(height: 8),
                  TextField(controller: confirmCtrl, obscureText: true, decoration: InputDecoration(labelText: 'Confirmar', errorText: errorText)),
                ],
              ),
              actions: [
                OutlinedButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                ElevatedButton(onPressed: () {
                  final n = newCtrl.text;
                  final c = confirmCtrl.text;
                  if (n.isEmpty || n != c) {
                    setState(() => errorText = 'Las contraseñas no coinciden');
                    return;
                  }
                  Navigator.of(context).pop(true);
                }, child: const Text('Cambiar')),
              ],
            );
          },
        );
      },
    );
    oldCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
    if (result ?? false) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cambio simulado: integra con Supabase para guardar contraseña')));
    }
  }
}

class _ProfileAvatar extends ConsumerStatefulWidget {
  const _ProfileAvatar({this.user, super.key});

  final Usuario? user;

  @override
  ConsumerState<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends ConsumerState<_ProfileAvatar> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndSave() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xfile == null) return;

    final appDir = await LocalDatabase.instance.appDocsDir;
    final filename = 'user_${widget.user?.id ?? const Uuid().v4()}${p.extension(xfile.path)}';
    final dest = File(p.join(appDir.path, filename));
    await File(xfile.path).copy(dest.path);

    final updated = widget.user?.copyWith(fotoUrl: dest.path) ??
        Usuario(
          id: const Uuid().v4(),
          email: 'unknown',
          nombre: 'Usuario',
          rol: UserRole.dependiente,
          createdAt: DateTime.now(),
          fotoUrl: dest.path,
        );

    await ref.read(authControllerProvider.notifier).updateUser(updated);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.user?.fotoUrl;
    Widget avatar;
    if (url == null) {
      avatar = const CircleAvatar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        child: Icon(Icons.person),
      );
    } else if (url.startsWith('http')) {
      avatar = CircleAvatar(
        backgroundImage: NetworkImage(url),
      );
    } else {
      avatar = CircleAvatar(
        backgroundImage: FileImage(File(url)),
      );
    }

    return GestureDetector(
      onTap: _pickAndSave,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          avatar,
          const CircleAvatar(
            radius: 10,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.camera_alt_rounded,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }
}

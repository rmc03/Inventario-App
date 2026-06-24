// ignore_for_file: unused_element_parameter
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/local_db/local_database.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/usuario.dart';
import '../../../shared/models/categoria.dart';
import '../../../shared/widgets/category_name_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../../inventario/providers/inventario_provider.dart';
import '../../usuarios/providers/usuario_provider.dart';

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
                        onPressed: () =>
                            _showEditProfileDialog(context, ref, user),
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
                  subtitle: const Text(
                    'Cambia tu contraseña de acceso (simulado)',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showChangePasswordDialog(context),
                ),
              ),
            ],
            if (isAdmin) ...[
              const SizedBox(height: 18),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: const Text('Gestionar dependientes'),
                  subtitle: const Text('Administrar usuarios internos'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showUserManagement(context, ref),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Gestionar categorías'),
                  subtitle: const Text('Crear, editar y eliminar categorías'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showCategoryManagement(context, ref),
                ),
              ),
            ],
            if (!isAdmin) ...[
              const SizedBox(height: 18),
              Text(
                'CATEGORÍAS',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              for (final categoria in categorias) ...[
                Card(
                  key: ValueKey(categoria.id),
                  child: ListTile(
                    title: Text(categoria.nombre),
                    leading: const Icon(Icons.category_outlined),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _showCategoryManagement(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (ctx) => _CategoryManagementSheet(),
    );
  }

  void _showUserManagement(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (ctx) => _UserManagementSheet(),
    );
  }

  Future<void> _showEditProfileDialog(
    BuildContext context,
    WidgetRef ref,
    Usuario? user,
  ) async {
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
                    decoration: InputDecoration(
                      labelText: 'Email',
                      errorText: errorText,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newName = nameCtrl.text.trim();
                    final newEmail = emailCtrl.text.trim();
                    if (newName.isEmpty ||
                        newEmail.isEmpty ||
                        !newEmail.contains('@')) {
                      setState(
                        () => errorText =
                            'Introduce un nombre y un email válidos',
                      );
                      return;
                    }
                    final updated = user.copyWith(
                      nombre: newName,
                      email: newEmail,
                    );
                    ref
                        .read(authControllerProvider.notifier)
                        .updateUser(updated);
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
    nameCtrl.dispose();
    emailCtrl.dispose();
    if (result ?? false) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
      }
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
                  TextField(
                    controller: oldCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña actual',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: newCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nueva contraseña',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirmar',
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final n = newCtrl.text;
                    final c = confirmCtrl.text;
                    if (n.isEmpty || n != c) {
                      setState(
                        () => errorText = 'Las contraseñas no coinciden',
                      );
                      return;
                    }
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Cambiar'),
                ),
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cambio simulado: integra con Supabase para guardar contraseña',
            ),
          ),
        );
      }
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
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (xfile == null) return;

    final appDir = await LocalDatabase.instance.appDocsDir;
    final filename =
        'user_${widget.user?.id ?? const Uuid().v4()}${p.extension(xfile.path)}';
    final dest = File(p.join(appDir.path, filename));
    await File(xfile.path).copy(dest.path);

    final updated =
        widget.user?.copyWith(fotoUrl: dest.path) ??
        Usuario(
          id: const Uuid().v4(),
          email: 'unknown',
          nombre: 'Usuario',
          rol: UserRole.dependiente,
          createdAt: DateTime.now(),
          fotoUrl: dest.path,
        );

    await ref.read(authControllerProvider.notifier).updateUser(updated);
    if (mounted) setState(() {});
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
      avatar = CircleAvatar(backgroundImage: NetworkImage(url));
    } else {
      avatar = CircleAvatar(backgroundImage: FileImage(File(url)));
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
            child: Icon(Icons.camera_alt_rounded, size: 14),
          ),
        ],
      ),
    );
  }
}

// ─── Category management sheet ─────────────────────────────────────────────

class _CategoryManagementSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CategoryManagementSheet> createState() =>
      _CategoryManagementSheetState();
}

class _CategoryManagementSheetState
    extends ConsumerState<_CategoryManagementSheet> {
  final _sheetController = DraggableScrollableController();
  bool _isDragging = false;

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categorias = ref.watch(
      inventarioControllerProvider.select((s) => s.categorias),
    );

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            children: [
              GestureDetector(
                onVerticalDragStart: (_) =>
                    setState(() => _isDragging = true),
                onVerticalDragUpdate: (details) {
                  final delta = -details.primaryDelta! /
                      MediaQuery.of(context).size.height;
                  _sheetController.jumpTo(
                    (_sheetController.size + delta).clamp(0.4, 0.95),
                  );
                },
                onVerticalDragEnd: (_) =>
                    setState(() => _isDragging = false),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _isDragging
                            ? AppColors.primary
                            : AppColors.muted,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Categorías',
                        style:
                            Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () =>
                          _showCategoryDialog(context, ref),
                      icon: const Icon(Icons.add_rounded),
                      tooltip: 'Crear categoría',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  children: [
                    for (final categoria in categorias) ...[
                      Card(
                        key: ValueKey(categoria.id),
                        child: ListTile(
                          title: Text(categoria.nombre),
                          leading: const Icon(Icons.category_outlined),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Editar',
                                onPressed: () => _showCategoryDialog(
                                  context,
                                  ref,
                                  categoria: categoria,
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    _confirmDeleteCategoria(
                                  context,
                                  ref,
                                  categoria,
                                ),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                ),
                                color: AppColors.danger,
                                tooltip: 'Eliminar',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
}

// ─── User management sheet ─────────────────────────────────────────────────

class _UserManagementSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_UserManagementSheet> createState() =>
      _UserManagementSheetState();
}

class _UserManagementSheetState
    extends ConsumerState<_UserManagementSheet> {
  final _sheetController = DraggableScrollableController();
  bool _isDragging = false;

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usuariosControllerProvider);

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            children: [
              GestureDetector(
                onVerticalDragStart: (_) =>
                    setState(() => _isDragging = true),
                onVerticalDragUpdate: (details) {
                  final delta = -details.primaryDelta! /
                      MediaQuery.of(context).size.height;
                  _sheetController.jumpTo(
                    (_sheetController.size + delta).clamp(0.4, 0.95),
                  );
                },
                onVerticalDragEnd: (_) =>
                    setState(() => _isDragging = false),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _isDragging
                            ? AppColors.primary
                            : AppColors.muted,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Dependientes',
                        style:
                            Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () =>
                          _showUserDialog(context, ref),
                      icon: const Icon(Icons.add_rounded),
                      tooltip: 'Crear dependiente',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.usuarios.isEmpty
                        ? const _EmptyUsuarios()
                        : ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                            ),
                            children: [
                              for (final usuario in state.usuarios) ...[
                                Card(
                                  key: ValueKey(usuario.id),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          usuario.rol == UserRole.admin
                                              ? AppColors.primary
                                              : AppColors.warning,
                                      foregroundColor: AppColors.surface,
                                      child: Text(
                                        usuario.nombre.isNotEmpty
                                            ? usuario.nombre[0]
                                                .toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    title: Text(usuario.nombre),
                                    subtitle: Text(usuario.email),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                          ),
                                          tooltip: 'Editar',
                                          onPressed: () =>
                                              _showUserDialog(
                                            context,
                                            ref,
                                            usuario: usuario,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              _confirmDeleteUser(
                                            context,
                                            ref,
                                            usuario,
                                          ),
                                          icon: const Icon(
                                            Icons
                                                .delete_outline_rounded,
                                          ),
                                          color: AppColors.danger,
                                          tooltip: 'Eliminar',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                              ],
                            ],
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showUserDialog(
    BuildContext context,
    WidgetRef ref, {
    Usuario? usuario,
  }) async {
    final isEdit = usuario != null;
    final result = await showDialog<({String nombre, String email})>(
      context: context,
      builder: (_) => _UserDialog(
        title: isEdit ? 'Editar dependiente' : 'Crear dependiente',
        initialName: isEdit ? usuario.nombre : null,
        initialEmail: isEdit ? usuario.email : null,
      ),
    );

    if (result == null) return;

    final nombre = result.nombre.trim();
    final email = result.email.trim().toLowerCase();

    final repo = ref.read(usuarioRepositoryProvider);
    final exists = await repo.existsEmail(
      email,
      excludeId: isEdit ? usuario.id : null,
    );
    if (exists) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya existe un usuario con este email'),
          ),
        );
      }
      return;
    }

    if (isEdit) {
      await ref
          .read(usuariosControllerProvider.notifier)
          .actualizarUsuario(usuario.copyWith(
            nombre: nombre,
            email: email,
          ));
    } else {
      await ref
          .read(usuariosControllerProvider.notifier)
          .crearUsuario(
            nombre: nombre,
            email: email,
            rol: UserRole.dependiente,
          );
    }
  }

  Future<void> _confirmDeleteUser(
    BuildContext context,
    WidgetRef ref,
    Usuario usuario,
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
          title: const Text('¿Eliminar dependiente?'),
          content: Text(
            'Se desactivará el acceso de "${usuario.nombre}". ¿Deseas continuar?',
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
      await ref
          .read(usuariosControllerProvider.notifier)
          .eliminarUsuario(usuario.id);
    }
  }
}

// ─── Empty usuarios ────────────────────────────────────────────────────────

class _EmptyUsuarios extends StatelessWidget {
  const _EmptyUsuarios();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.people_outline,
            size: 48,
            color: AppColors.muted,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No hay dependientes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Crea un dependiente desde el botón +',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// ─── User dialog ───────────────────────────────────────────────────────────

class _UserDialog extends StatefulWidget {
  const _UserDialog({
    required this.title,
    this.initialName,
    this.initialEmail,
  });

  final String title;
  final String? initialName;
  final String? initialEmail;

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _emailCtrl;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.initialName ?? '');
    _emailCtrl = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nombreCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              prefixIcon: Icon(Icons.person_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined),
              errorText: _errorText,
            ),
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
            final nombre = _nombreCtrl.text.trim();
            final email = _emailCtrl.text.trim();
            if (nombre.isEmpty) {
              setState(() => _errorText = 'El nombre es obligatorio');
              return;
            }
            if (email.isEmpty || !email.contains('@')) {
              setState(() => _errorText = 'Introduce un email válido');
              return;
            }
            Navigator.of(context).pop((nombre: nombre, email: email));
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

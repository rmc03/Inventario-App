// ignore_for_file: unused_element_parameter
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/local_db/local_database.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/models/usuario.dart';
import '../../auth/providers/auth_provider.dart';


class ConfiguracionScreen extends ConsumerWidget {
  const ConfiguracionScreen({super.key, this.isAdmin = true});

  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider.select((s) => s.user));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                // ── PERFIL ──
                const _SectionHeader(
                  icon: Icons.person_rounded,
                  label: 'Perfil',
                ),
                if (user != null)
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
                                  user.nombre,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(user.email),
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
                const SizedBox(height: 18),

                // ── APARIENCIA ──
                const _SectionHeader(
                  icon: Icons.brightness_6_rounded,
                  label: 'Apariencia',
                ),
                const _AparienciaExpandable(),
                const SizedBox(height: 18),

                // ── ACCESIBILIDAD ──
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.accessibility_new_rounded),
                    title: const Text('Accesibilidad'),
                    subtitle: const Text('Tamaño de texto, contraste y más'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(
                      isAdmin
                          ? '/admin/configuracion/accesibilidad'
                          : '/dependiente/configuracion/accesibilidad',
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // ── CUADRES (solo dependiente) ──
                if (!isAdmin) ...[
                  const _SectionHeader(
                    icon: Icons.receipt_long_rounded,
                    label: 'Cuadres',
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.history_rounded),
                      title: const Text('Historial de cuadres'),
                      subtitle: const Text('Ver mis cuadres anteriores'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () =>
                          context.push('/dependiente/cuadres/historial'),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // ── GESTIÓN (solo admin) ──
                if (isAdmin) ...[
                  const _SectionHeader(
                    icon: Icons.settings_rounded,
                    label: 'Gestión',
                  ),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.people_outline),
                          title: const Text('Equipo'),
                          subtitle:
                              const Text('Administrar miembros del equipo'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push(
                            '/admin/configuracion/equipo',
                          ),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          leading: const Icon(Icons.category_outlined),
                          title: const Text('Categorías'),
                          subtitle: const Text('Organizar productos'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push(
                            '/admin/configuracion/categorias',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
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
                    decoration:
                        const InputDecoration(labelText: 'Nombre'),
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
                    Haptics.confirm(context);
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado')),
        );
      }
    }
  }
}

// ─── Section Header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.colors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: context.colors.muted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Apariencia Expandable ──────────────────────────────────────────────────

class _AparienciaExpandable extends StatefulWidget {
  const _AparienciaExpandable();

  @override
  State<_AparienciaExpandable> createState() => _AparienciaExpandableState();
}

class _AparienciaExpandableState extends State<_AparienciaExpandable> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.brightness_6_rounded),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Apariencia',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Consumer(
                          builder: (context, ref, _) {
                            final mode = ref.watch(themeModeProvider);
                            return Text(
                              _getThemeModeLabel(mode),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: context.colors.muted),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: context.colors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.palette_rounded),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text('Tema de apariencia'),
                      ),
                      const _ThemeModeSelector(),
                    ],
                  ),
                  const Divider(height: 1),
                  Consumer(
                    builder: (context, ref, _) {
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.vibration_rounded),
                        title: const Text('Vibración en botones'),
                        subtitle: const Text(
                          'Feedback táctil en acciones importantes',
                        ),
                        value: ref.watch(hapticsEnabledProvider),
                        onChanged: (v) {
                          ref
                              .read(hapticsEnabledProvider.notifier)
                              .setEnabled(v);
                          if (v) Haptics.tap(context);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}

// ─── Profile Avatar ─────────────────────────────────────────────────────────

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
      avatar = CircleAvatar(
        backgroundColor: context.colors.primary,
        foregroundColor: context.colors.surface,
        child: const Icon(Icons.person),
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
          CircleAvatar(
            radius: 10,
            backgroundColor: context.colors.surface,
            child: const Icon(Icons.camera_alt_rounded, size: 14),
          ),
        ],
      ),
    );
  }
}

// ─── Theme Mode Helpers ─────────────────────────────────────────────────────

String _getThemeModeLabel(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'Modo claro';
    case ThemeMode.dark:
      return 'Modo oscuro';
    case ThemeMode.system:
      return 'Automático (sistema)';
  }
}

// ─── Theme Mode Selector ────────────────────────────────────────────────────

class _ThemeModeSelector extends ConsumerWidget {
  const _ThemeModeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeProvider);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThemeModeButton(
            icon: Icons.light_mode_rounded,
            isSelected: currentMode == ThemeMode.light,
            onTap: () {
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(ThemeMode.light);
              Haptics.tap(context);
            },
            tooltip: 'Claro',
          ),
          const SizedBox(width: 2),
          _ThemeModeButton(
            icon: Icons.dark_mode_rounded,
            isSelected: currentMode == ThemeMode.dark,
            onTap: () {
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(ThemeMode.dark);
              Haptics.tap(context);
            },
            tooltip: 'Oscuro',
          ),
          const SizedBox(width: 2),
          _ThemeModeButton(
            icon: Icons.brightness_auto_rounded,
            isSelected: currentMode == ThemeMode.system,
            onTap: () {
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(ThemeMode.system);
              Haptics.tap(context);
            },
            tooltip: 'Auto',
          ),
        ],
      ),
    );
  }
}

class _ThemeModeButton extends StatelessWidget {
  const _ThemeModeButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

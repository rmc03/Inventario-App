// ignore_for_file: unused_element_parameter
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/local_db/local_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/models/usuario.dart';
import '../../auth/providers/auth_provider.dart';
import '../../qr_pagos/presentation/gestionar_qrs_screen.dart';

const _kEntranceDuration = Duration(milliseconds: 400);
const _kStaggerInterval = Duration(milliseconds: 80);
const _kSectionCount = 5; // Incrementado para incluir sección de QRs
const _kSlideOffset = Offset(0, 0.02);

class ConfiguracionScreen extends ConsumerStatefulWidget {
  const ConfiguracionScreen({super.key, this.isAdmin = true});

  final bool isAdmin;

  @override
  ConsumerState<ConfiguracionScreen> createState() =>
      _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends ConsumerState<ConfiguracionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final List<Animation<double>> _sectionFades;
  late final List<Animation<Offset>> _sectionSlides;

  @override
  void initState() {
    super.initState();
    
    // Inicializar controller con valor 0, luego animar
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: _kEntranceDuration + _kStaggerInterval * (_kSectionCount - 1),
    );
    
    _sectionFades = List.generate(_kSectionCount, (i) {
      final start = i * (_kStaggerInterval.inMilliseconds /
          _entranceCtrl.duration!.inMilliseconds);
      final end = (start + _kEntranceDuration.inMilliseconds /
              _entranceCtrl.duration!.inMilliseconds)
          .clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });
    _sectionSlides = List.generate(_kSectionCount, (i) {
      final start = i * (_kStaggerInterval.inMilliseconds /
          _entranceCtrl.duration!.inMilliseconds);
      final end = (start + _kEntranceDuration.inMilliseconds /
              _entranceCtrl.duration!.inMilliseconds)
          .clamp(0.0, 1.0);
      return Tween<Offset>(begin: _kSlideOffset, end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entranceCtrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });
    
    // Iniciar animación después de que el frame esté construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final reduceMotion =
            MediaQuery.of(context).disableAnimations;
        if (reduceMotion) {
          _entranceCtrl.value = 1;
        } else {
          _entranceCtrl.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  Widget _staggeredSection(int index, Widget child) {
    return AnimatedBuilder(
      animation: Listenable.merge([_sectionFades[index], _sectionSlides[index]]),
      builder: (context, _) => FadeTransition(
        opacity: _sectionFades[index],
        child: SlideTransition(
          position: _sectionSlides[index],
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            child: Builder(
              builder: (context) {
                final sections = <Widget>[
                  _staggeredSection(
                    0,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.nombre,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        Text(user.email),
                                      ],
                                    ),
                                  ),
                                  if (!widget.isAdmin)
                                    IconButton(
                                      onPressed: () => _showEditProfileDialog(
                                          context, ref, user),
                                      icon: const Icon(Icons.edit_rounded),
                                      tooltip: 'Editar perfil',
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _staggeredSection(
                    1,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHeader(
                          icon: Icons.brightness_6_rounded,
                          label: 'Personalización',
                        ),
                        Card(
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.palette_rounded),
                                title: const Text('Temas'),
                                subtitle:
                                    const Text('Esquema de colores y modo de brillo'),
                                trailing:
                                    const Icon(Icons.chevron_right_rounded),
                                onTap: () => context.push(
                                  widget.isAdmin
                                      ? '/admin/configuracion/temas'
                                      : '/dependiente/configuracion/temas',
                                ),
                              ),
                              const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16),
                              Consumer(
                                builder: (context, ref, _) {
                                  return SwitchListTile(
                                    secondary:
                                        const Icon(Icons.vibration_rounded),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _staggeredSection(
                    2,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          child: ListTile(
                            leading:
                                const Icon(Icons.accessibility_new_rounded),
                            title: const Text('Accesibilidad'),
                            subtitle:
                                const Text('Tamaño de texto, contraste y más'),
                            trailing:
                                const Icon(Icons.chevron_right_rounded),
                            onTap: () => context.push(
                              widget.isAdmin
                                  ? '/admin/configuracion/accesibilidad'
                                  : '/dependiente/configuracion/accesibilidad',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _staggeredSection(
                    3,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHeader(
                          icon: Icons.qr_code_2_rounded,
                          label: 'Pagos',
                        ),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.qr_code_scanner_rounded),
                            title: const Text('Mis QRs de pago'),
                            subtitle: const Text('Gestiona tus códigos QR para transferencias'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const GestionarQrsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ];
                if (!widget.isAdmin) {
                  sections.addAll([
                    _staggeredSection(
                      4,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionHeader(
                            icon: Icons.receipt_long_rounded,
                            label: 'Cuadres',
                          ),
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.history_rounded),
                              title: const Text('Historial de cuadres'),
                              subtitle:
                                  const Text('Ver mis cuadres anteriores'),
                              trailing:
                                  const Icon(Icons.chevron_right_rounded),
                              onTap: () => context
                                  .push('/dependiente/cuadres/historial'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]);
                }
                if (widget.isAdmin) {
                  sections.addAll([
                    _staggeredSection(
                      4,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionHeader(
                            icon: Icons.settings_rounded,
                            label: 'Gestión',
                          ),
                          Card(
                            child: Column(
                              children: [
                                ListTile(
                                  leading:
                                      const Icon(Icons.people_outline),
                                  title: const Text('Equipo'),
                                  subtitle: const Text(
                                      'Administrar miembros del equipo'),
                                  trailing: const Icon(
                                      Icons.chevron_right_rounded),
                                  onTap: () => context.push(
                                    '/admin/configuracion/equipo',
                                  ),
                                ),
                                const Divider(
                                    height: 1,
                                    indent: 16,
                                    endIndent: 16),
                                ListTile(
                                  leading: const Icon(
                                      Icons.category_outlined),
                                  title: const Text('Categorías'),
                                  subtitle:
                                      const Text('Organizar productos'),
                                  trailing: const Icon(
                                      Icons.chevron_right_rounded),
                                  onTap: () => context.push(
                                    '/admin/configuracion/categorias',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]);
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: sections.length,
                  itemBuilder: (_, i) => sections[i],
                );
              },
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

// ─── Profile Avatar ─────────────────────────────────────────────────────────

class _ProfileAvatar extends ConsumerStatefulWidget {
  const _ProfileAvatar({this.user, super.key});

  final Usuario? user;

  @override
  ConsumerState<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends ConsumerState<_ProfileAvatar>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  late final AnimationController _tapCtrl;
  late final Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _tapScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 0.92), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1), weight: 50),
    ]).animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndSave() async {
    _tapCtrl.forward(from: 0);
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
      child: ScaleTransition(
        scale: _tapScale,
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
      ),
    );
  }
}
